"""Minimal working PPO example with TRL 0.16.1 + transformers 4.52.0.dev0.
This trains openai-community/gpt2-medium with a reward function that encourages yapping — long, opinionated, and question-asking responses.
"""
from transformers import GPT2Tokenizer, GPT2Model
import torch
import torch.nn as nn
from datasets import Dataset
from transformers import (
    AutoTokenizer,
    AutoModelForCausalLM,
    GenerationConfig,
    DataCollatorWithPadding,
)
from trl import AutoModelForCausalLMWithValueHead, PPOConfig, PPOTrainer
from trl.trainer.utils import SIMPLE_CHAT_TEMPLATE
import inspect
import argparse
import os
import json
from transformers.trainer_callback import TrainerCallback
import math
import re
from collections import Counter
import spacy

# ---------------------------------------------------------------------------
# Device & model name
# ---------------------------------------------------------------------------
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
# Default model name for both training and inference
model_name = "gpt2"

# ---------------------------------------------------------------------------
# Helper modules to satisfy PPOTrainer / get_reward()
# ---------------------------------------------------------------------------

# PolicyAndValueWrapper is defined internally in TRL 0.16.1 PPOTrainer
# Remove our custom definition

class ZeroBackbone(nn.Module):
    def forward(self, input_ids=None, attention_mask=None, **kwargs):
        # Pass through input_ids as hidden_states for decoding
        h = input_ids.unsqueeze(-1)
        return type("Output", (), {"hidden_states": [h]})


class RewardFromFunction(nn.Module):
    base_model_prefix = "pretrained_model"

    def __init__(self, fn, tok):
        super().__init__()
        self.score_fn = fn
        self.tok = tok # Need tokenizer for decoding
        self.pretrained_model = ZeroBackbone()
        # store last decoded texts for debugging in score()
        self._last_texts = None

    def score(self, hidden_states):
        # Decode token IDs from hidden_states to get actual sequences
        b, s, _ = hidden_states.shape
        # hidden_states stores input_ids via backbone; extract and decode
        input_ids = hidden_states.squeeze(-1).long()
        decoded_texts = self.tok.batch_decode(input_ids, skip_special_tokens=True)
        # debug: print each decoded text snippet and word count
        for txt in decoded_texts:
            snippet = ' '.join(txt.split()[:20])
            print(f"[ScoreDebug] text_snippet='{snippet}...', word_count={len(txt.split())}", flush=True)
        # Compute raw sequence scores
        raw_scores = [float(self.score_fn(text)) for text in decoded_texts]
        # debug: print raw sequence scores
        print(f"[ScoreDebug] raw_scores={raw_scores}", flush=True)
        # Build per-position scores by repeating each sequence score s times
        scores_matrix = [[score] * s for score in raw_scores]
        scores = torch.tensor(scores_matrix, dtype=torch.bfloat16, device=hidden_states.device)
        return scores.unsqueeze(-1)

    def forward(self, input_ids=None, attention_mask=None, **kwargs):
        # Decode input_ids to text, handling padding
        decoded_texts = self.tok.batch_decode(input_ids, skip_special_tokens=True)
        # store decoded texts for score() debugging
        self._last_texts = decoded_texts
        # ignore incoming attention_mask to avoid indexing issues
        attention_mask = None
        # Calculate scalar scores for each sequence
        scores_list = [float(self.score_fn(text)) for text in decoded_texts]
        # debug: print raw rewards for each decoded text
        for txt, scr in zip(decoded_texts, scores_list):
            print(f"[RewardDebug] score={scr:.4f} | text={txt}", flush=True)
        scores_tensor = torch.tensor(scores_list, dtype=torch.bfloat16, device=input_ids.device)
        # Build full reward tensor of shape (batch_size, seq_len, 1)
        batch_size, seq_len = input_ids.shape
        # always place reward at last token position to avoid mask-based indexing
        final_scores = torch.zeros(batch_size, seq_len, 1, dtype=torch.bfloat16, device=input_ids.device)
        last_token_indices = torch.full((batch_size,), seq_len - 1, dtype=torch.long, device=input_ids.device)
        final_scores[torch.arange(batch_size, device=input_ids.device), last_token_indices, 0] = scores_tensor
        # Return reward_logits, score tensor, and sequence lengths
        return final_scores, scores_tensor, last_token_indices


class GPT2WithValueHead(AutoModelForCausalLMWithValueHead):
    base_model_prefix = "pretrained_model"

    def score(self, hidden_states):
        return self.v_head(hidden_states).squeeze(-1).unsqueeze(-1)


# ---------------------------------------------------------------------------
# Tokenizer
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Models: policy (actor), value (critic), ref (KL baseline)
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Yapper training prompts
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# PPO configuration
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Callback to save training logs to a JSONL file
class SaveMetricsCallback(TrainerCallback):
    """Callback to save PPOTrainer logs to `log_dir/metrics.jsonl`."""
    def __init__(self, output_dir):
        super().__init__()
        self.log_file = os.path.join(output_dir, "metrics.jsonl")
        # Clear previous log
        with open(self.log_file, "w") as f:
            pass

    def on_log(self, args, state, control, logs=None, **kwargs):
        if logs is None:
            return
        # Duplicate reward metrics under clearer keys
        logs = logs.copy()
        if "objective/non_score_reward" in logs:
            logs["raw_reward"] = logs["objective/non_score_reward"]
        if "objective/scores" in logs:
            logs["yap_score"] = logs["objective/scores"]
        # Append logs as JSON line
        with open(self.log_file, "a") as f:
            f.write(json.dumps(logs) + "\n")

# ---------------------------------------------------------------------------
# Trainer and training loop
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Yapper: Self-Chat Interface
# ---------------------------------------------------------------------------

class Yapper:
    def __init__(self, model_path: str, device=None):
        self.device = device or torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.tokenizer = AutoTokenizer.from_pretrained(model_path, padding_side="left")
        # Attempt to load GPT2WithValueHead; fallback to AutoModelForCausalLM on failure
        try:
            self.model = GPT2WithValueHead.from_pretrained(model_path).to(self.device)
        except Exception as e:
            print(f"[Yapper Warning] GPT2WithValueHead load failed: {e}. Falling back to AutoModelForCausalLM.", flush=True)
            self.model = AutoModelForCausalLM.from_pretrained(model_path, trust_remote_code=True).to(self.device)
        # load generation config from the model path for inference
        try:
            self.gen_cfg = GenerationConfig.from_pretrained(model_path)
        except Exception as e:
            print(f"[Yapper Warning] GenerationConfig load failed: {e}. Using default GenerationConfig.", flush=True)
            self.gen_cfg = GenerationConfig()
        self.model.generation_config = self.gen_cfg
        self.model.eval()

    def chat(self, prompt: str, max_length: int = None, min_length: int = None, do_sample: bool = None, temperature: float = None, top_p: float = None, top_k: int = None):
        inputs = self.tokenizer(prompt, return_tensors="pt").to(self.device)
        # build generation parameters respecting length constraints
        gen_kwargs = {"pad_token_id": self.tokenizer.eos_token_id}
        if max_length is not None:
            gen_kwargs["max_new_tokens"] = max_length
        if min_length is not None:
            gen_kwargs["min_new_tokens"] = min_length
        # sampling params: override generation_config defaults if provided
        sample = do_sample if do_sample is not None else getattr(self.model.generation_config, "do_sample", False)
        gen_kwargs["do_sample"] = sample
        if temperature is not None:
            gen_kwargs["temperature"] = temperature
        elif hasattr(self.model.generation_config, "temperature"):
            gen_kwargs["temperature"] = self.model.generation_config.temperature
        if top_p is not None:
            gen_kwargs["top_p"] = top_p
        elif hasattr(self.model.generation_config, "top_p"):
            gen_kwargs["top_p"] = self.model.generation_config.top_p
        if top_k is not None:
            gen_kwargs["top_k"] = top_k
        elif hasattr(self.model.generation_config, "top_k"):
            gen_kwargs["top_k"] = self.model.generation_config.top_k
        outputs = self.model.generate(
            **inputs,
            **gen_kwargs,
        )
        return self.tokenizer.decode(outputs[0], skip_special_tokens=True)


def parse_args():
    parser = argparse.ArgumentParser(description="Train Yapper PPO with GPT-2")
    parser.add_argument("--model-name", type=str, default="openai-community/gpt2", help="Pretrained model name")
    parser.add_argument("--batch-size", type=int, default=2, help="PPO batch size")
    parser.add_argument("--mini-batch-size", type=int, default=1, help="PPO mini-batch size")
    parser.add_argument("--episodes", type=int, default=100, help="Total PPO episodes")
    parser.add_argument("--output-dir", type=str, default="yapbot-ppo", help="Directory to save model and tokenizer")
    parser.add_argument("--device", type=str, default="cuda", help="Device for training (e.g. 'cuda', 'cuda:0' or 'cpu')")
    parser.add_argument("--log-dir", type=str, default=None, help="Directory to save training metrics JSONL")
    parser.add_argument("--gen-max-new-tokens", type=int, default=100, help="Max new tokens during PPO generation")
    parser.add_argument("--gen-min-new-tokens", type=int, default=0, help="Min new tokens during PPO generation")
    parser.add_argument("--gen-temperature", type=float, default=1.0, help="Temperature for PPO generation")
    parser.add_argument("--gen-top-p", type=float, default=0.9, help="Top-p (nucleus) sampling cutoff")
    parser.add_argument("--gen-top-k", type=int, default=50, help="Top-k sampling cutoff")
    parser.add_argument("--demo", action="store_true", help="Run a demo chat and exit")
    parser.add_argument("--prompt", type=str, default="Hello, how are you?", help="Prompt to use in demo mode")
    return parser.parse_args()

# ---------------------------------------------------------------------------
# Reward function
def _sigmoid(x, slope=1.0, width=1.0):
    return width / (1 + math.exp(-slope * (x - 0.5)))

def yap_score(text: str,
              weights = {
                  'length'      : 0.35,
                  'questions'   : 0.15,
                  'reflection'  : 0.10,
                  'fillers'     : 0.10,
                  'diversity'   : 0.10,
                  'repetition'  : 0.10,
                  'sentiment'   : 0.05,
                  'kl_weird'    : 0.15,
              },
              kl_ref_logits: torch.Tensor | None = None
):
    """
    Advanced reward for Yapper‑style rambling using multiple linguistic features and optional KL weirdness.
    """
    # disable KL-weird if no reference LM loaded
    if weights.get('kl_weird', 0) > 0 and _lm is None:
        weights['kl_weird'] = 0.0

    doc = _nlp(text)
    tokens = [t.text for t in doc if not t.is_space]
    T = len(tokens) or 1

    # 1. Length (continuous, saturates at 60 tokens)
    length_score = _sigmoid(min(T, 60)/60, slope=12)

    # 2. Questions (rate per sentence)
    qmarks = text.count("?")
    question_rate = qmarks / max(1, len(list(doc.sents)))
    question_score = min(question_rate, 1.0)

    # 3. Reflection words: unique hits
    refl_words = {"think","feel","know","guess","maybe","suppose","wonder",
                  "honestly","personally","kinda","sorta"}
    refl_hits = [tok_.text.lower() for tok_ in doc if tok_.text.lower() in refl_words]
    reflect_score = min(len(set(refl_hits))/4, 1.0)

    # 4. Fillers (uh, um, ellipses, dashes)
    filler_regex = re.compile(r"\b(?:uh+|umm+|erm+)\b|\.{2,}|--")
    fillers_score = min(len(filler_regex.findall(text)) / 3, 1.0)

    # 5. Lexical diversity (type/token ratio)
    ttr = len(set(tokens)) / T
    diversity_score = _sigmoid(ttr, slope=10)

    # 6. Repetition penalty (bigram repeats)
    bigrams = list(zip(tokens, tokens[1:]))
    # Count how many bigrams repeat more than once
    repeats = sum(freq for freq in Counter(bigrams).values() if freq > 1)
    repetition_score = math.exp(-repeats / 5)

    # 7. Sentiment (mild subjectivity)
    blob = doc._.polarity if hasattr(doc._, "polarity") else 0.0
    sentiment_score = max(0, 1 - abs(blob - 0.4))

    # 8. Optional KL-weirdness from reference LM
    kl_weird_score = 0.0
    if weights.get('kl_weird', 0) > 0:
        with torch.no_grad():
            ids = _lm_tok(text, return_tensors="pt").input_ids.to(_lm.device)
            logits = _lm(ids).logits[0, :-1]
            ref_logits = kl_ref_logits if kl_ref_logits is not None else logits.detach()
            p = logits.log_softmax(-1)
            q = ref_logits.log_softmax(-1)
            kl_div = torch.nn.functional.kl_div(p, q, log_target=True, reduction='batchmean')
            kl_weird_score = _sigmoid(min(kl_div.item(),3)/3, slope=8)

    raw = (
        weights['length']    * length_score +
        weights['questions'] * question_score +
        weights['reflection']* reflect_score +
        weights['fillers']   * fillers_score +
        weights['diversity'] * diversity_score +
        weights['repetition']* repetition_score +
        weights['sentiment'] * sentiment_score +
        weights.get('kl_weird',0) * kl_weird_score
    )
    norm = sum(weights.values()) or 1.0
    return max(0.0, min(raw / norm, 1.0))

# ---------------------------------------------------------------------------
# setup spaCy for advanced scoring
_nlp = spacy.load("en_core_web_sm", disable=["parser","ner"])
_nlp.add_pipe("sentencizer")  # enable sentence boundaries for doc.sents
_tokenizer = _nlp.tokenizer
# placeholders for reference LM and tokenizer for KL-weirdness
_lm = None
_lm_tok = None

def main(args):
    # 1. Environment setup: force using the specified device
    device = torch.device(args.device)
    print(f"Using device: {device}")

    model_name = args.model_name

    # Quick demo mode: chat with the model and exit
    if args.demo:
        yapper = Yapper(model_name, device)
        print(yapper.chat(
            args.prompt,
            max_length=args.gen_max_new_tokens,
            min_length=args.gen_min_new_tokens,
            do_sample=True,
            temperature=args.gen_temperature,
            top_p=args.gen_top_p,
            top_k=args.gen_top_k,
        ))
        return

    # 2. Tokenizer initialization
    tok = AutoTokenizer.from_pretrained(model_name, padding_side="left")
    tok.add_special_tokens({"pad_token": "[PAD]"})
    if getattr(tok, "chat_template", None) is None:
        tok.chat_template = SIMPLE_CHAT_TEMPLATE

    # 3. Model loading (policy, value, ref)
    policy = AutoModelForCausalLM.from_pretrained(model_name).to(device)
    policy.resize_token_embeddings(len(tok))
    value = GPT2WithValueHead.from_pretrained(model_name).to(device)
    ref = AutoModelForCausalLM.from_pretrained(model_name).to(device)
    value.pretrained_model.resize_token_embeddings(len(tok))
    ref.resize_token_embeddings(len(tok))
    # setup reference LM and tokenizer for KL-weirdness
    global _lm, _lm_tok
    _lm = ref
    _lm_tok = tok
    gen_cfg = GenerationConfig.from_pretrained(model_name)
    gen_cfg.max_new_tokens = args.gen_max_new_tokens
    # enforce a minimum generation length if specified
    if args.gen_min_new_tokens and args.gen_min_new_tokens > 0:
        gen_cfg.min_new_tokens = args.gen_min_new_tokens
    gen_cfg.temperature = args.gen_temperature
    gen_cfg.top_p = args.gen_top_p
    gen_cfg.top_k = args.gen_top_k
    gen_cfg.do_sample = True
    for m in (policy, value, ref):
        m.generation_config = gen_cfg

    # 4. Dataset loading & tokenization
    yap_prompts = [
        "Hey, what's on your mind today?",
        "What do you think about AI art?",
        "Tell me something weird you believe.",
        "How would you start an argument about pineapple on pizza?",
        "Say something totally unhinged but kinda true.",
    ]
    ds = Dataset.from_dict({"prompt": yap_prompts * 20})
    def tokenize_fn(examples):
        return tok(examples["prompt"], truncation=True)
    ds = ds.map(tokenize_fn, batched=True, remove_columns=["prompt"])

    # 5. Reward function & reward model init
    reward_model = RewardFromFunction(yap_score, tok).to(device)
    for p in reward_model.parameters():
        p.requires_grad = False
    for p in ref.parameters():  # freeze reference model
        p.requires_grad = False

    # Debug: quick reward_model test on a sample generation
    print("=== Reward model debug test ===")
    test_prompt = "Say something unhinged but kind of true."
    test_inputs = tok(test_prompt, return_tensors="pt").to(device)
    test_out_ids = policy.generate(
        **test_inputs,
        max_new_tokens=10,
        do_sample=True,
        temperature=1.0,
        top_p=0.9,
        top_k=50,
        pad_token_id=tok.eos_token_id,
    )
    test_texts = tok.batch_decode(test_out_ids, skip_special_tokens=True)
    print(f"Generated for reward test: {test_texts}")
    _, test_scores, _ = reward_model(input_ids=test_out_ids, attention_mask=None)
    print(f"Reward model returned scores: {test_scores.tolist()}")

    # 6. PPOConfig & PPOTrainer instantiation
    ppo_config = PPOConfig(
        batch_size=args.batch_size,
        mini_batch_size=args.mini_batch_size,
        total_episodes=args.episodes,
    )
    # Prepare callbacks for logging
    callbacks = []
    if args.log_dir:
        os.makedirs(args.log_dir, exist_ok=True)
        callbacks.append(SaveMetricsCallback(args.log_dir))
    data_collator = DataCollatorWithPadding(tok)
    trainer = PPOTrainer(
        args=ppo_config,
        processing_class=tok,
        model=policy,
        ref_model=ref,
        value_model=value,
        reward_model=reward_model,
        train_dataset=ds,
        eval_dataset=ds.select(range(10)),
        data_collator=data_collator,
        callbacks=callbacks,
    )

    # 7. Training loop
    print("===training yapper===")
    trainer.train()
    print("===done training===")

    # 8. Saving models & tokenizer
    os.makedirs(args.output_dir, exist_ok=True)
    # Save the fine-tuned policy model
    policy.save_pretrained(args.output_dir)
    tok.save_pretrained(args.output_dir)
    print(f"Saved model and tokenizer to {args.output_dir}")

if __name__ == "__main__":
    args = parse_args()
    main(args)