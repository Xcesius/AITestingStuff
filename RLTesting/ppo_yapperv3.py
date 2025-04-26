"""Minimal working PPO example with TRL 0.16.1 + transformers 4.52.0.dev0.
Optimised for a 10 GB RTX 3080: we keep just two GPT‑2 models in VRAM —
(1) a shared‑backbone **actor‑critic** (`AutoModelForCausalLMWithValueHead`) and
(2) a frozen reference model.  Peak footprint ≈ 6 GB.
"""

import argparse
import json
import math
import os
import re
from collections import Counter
from typing import List
import torch
import torch.nn as nn
import spacy
from datasets import Dataset
from transformers import (
    AutoModelForCausalLM,
    AutoTokenizer,
    DataCollatorWithPadding,
    GenerationConfig,
    Trainer,
)
from transformers.trainer_callback import TrainerCallback
from trl import (
    AutoModelForCausalLMWithValueHead,
    PPOConfig,
    PPOTrainer,
)
import trl.trainer.ppo_trainer as ppo_mod
from trl.trainer.utils import SIMPLE_CHAT_TEMPLATE
from trl.trainer.ppo_trainer import PolicyAndValueWrapper
from transformers.modeling_outputs import CausalLMOutput

# ---------------------------------------------------------------------------
# Helpers ------------------------------------------------------------------
# ---------------------------------------------------------------------------

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
# Use float32 for all operations to avoid float16 issues causing NaNs
DTYPE = torch.float32
MODEL_NAME = "gpt2"

def _resize_embeddings(model, new_len: int):
    """Resize token embeddings for vanilla LMs *or* Value‑Head wrappers."""
    if hasattr(model, "resize_token_embeddings"):
        model.resize_token_embeddings(new_len)
    elif hasattr(model, "pretrained_model") and hasattr(model.pretrained_model, "resize_token_embeddings"):
        model.pretrained_model.resize_token_embeddings(new_len)
    else:
        raise AttributeError("Model lacks resize_token_embeddings")

# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# Reward function (simple callable for TRL) --------------------------------
# ---------------------------------------------------------------------------

def reward_fn(samples, **kwargs):
    """Return scalar rewards (list[float]) for generated strings."""
    scores = []
    for txt in samples:
        score = yap_score(txt)
        print(f"[REWARD DEBUG] Sample: {repr(txt)} | Score: {score}")
        scores.append(score)
    return scores

# ---------------------------------------------------------------------------
# Yapper heuristic --------------------------------------------------------- ---------------------------------------------------------
# ---------------------------------------------------------------------------

_nlp = spacy.load("en_core_web_sm", disable=["parser", "ner"])
_nlp.add_pipe("sentencizer", first=True)
_lm = _lm_tok = None  # to be set later

def _sigmoid(x, slope=1.0):
    return 1 / (1 + math.exp(-slope * (x - 0.5)))

def yap_score(text: str, weights=None, kl_ref_logits=None):
    weights = weights or {
        "length": 0.35,
        "questions": 0.15,
        "reflection": 0.10,
        "fillers": 0.10,
        "diversity": 0.10,
        "repetition": 0.10,
        "sentiment": 0.05,
        "kl_weird": 0.05,
    }

    if _lm is None:
        weights["kl_weird"] = 0.0

    doc = _nlp(text)
    toks = [t.text for t in doc if not t.is_space]
    T = len(toks) or 1

    length = _sigmoid(min(T, 60) / 60, slope=12)
    if math.isnan(length):
        print('Warning: NaN in length calculation')
        length = 0.0  # Fallback value

    questions = text.count("?") / max(1, len(list(doc.sents)))
    if math.isnan(questions):
        print('Warning: NaN in questions calculation')
        questions = 0.0

    refl_set = {t.lower_ for t in doc if t.lower_ in {"think", "feel", "know", "guess", "maybe", "suppose", "wonder", "honestly", "personally", "kinda", "sorta"}}
    reflection = min(len(refl_set) / 4, 1.0)
    fillers = min(len(re.findall(r"\b(?:uh+|umm+|erm+)\b|\.{2,}|--", text)) / 3, 1.0)
    diversity = _sigmoid(len(set(toks)) / T, slope=10)
    if math.isnan(diversity):
        print('Warning: NaN in diversity calculation')
        diversity = 0.0
    repeats = sum(v for v in Counter(zip(toks, toks[1:])).values() if v > 1)
    repetition = math.exp(-repeats / 5)
    sentiment = max(0.0, 1 - abs(getattr(doc._, "polarity", 0.0) - 0.4))

    kl_weird = 0.0
    if weights.get("kl_weird", 0) > 0:
        try:
            with torch.no_grad():
                ids = _lm_tok(text, return_tensors="pt").input_ids.to(_lm.device)
                logits = _lm(ids).logits[0, :-1]
                if torch.isnan(logits).any():
                    print('Warning: NaNs in logits; skipping KL divergence')
                    kl_weird = 0.0  # Zero out if NaNs detected
                else:
                    ref = kl_ref_logits if kl_ref_logits is not None else logits.detach()
                    if torch.isnan(ref).any():
                        print('Warning: NaNs in reference logits; skipping KL divergence')
                        kl_weird = 0.0
                    else:
                        kl_div = torch.nn.functional.kl_div(logits.log_softmax(-1), ref.log_softmax(-1), log_target=True, reduction="batchmean")
                        if torch.isnan(kl_div):
                            print('Warning: NaN in KL divergence; setting to 0')
                            kl_div = 0.0
                        kl_weird = _sigmoid(min(kl_div.item(), 3), slope=8)
        except Exception as e:
            print(f'Error in KL divergence: {e}; skipping and setting kl_weird to 0')
            kl_weird = 0.0  # Fallback to zero on any error

    total = (
        weights["length"] * length + weights["questions"] * questions + weights["reflection"] * reflection +
        weights["fillers"] * fillers + weights["diversity"] * diversity + weights["repetition"] * repetition +
        weights["sentiment"] * sentiment + weights["kl_weird"] * kl_weird
    ) / sum(weights.values())
    return max(0.0, min(total, 1.0))

# ---------------------------------------------------------------------------
# Chat wrapper -------------------------------------------------------------
# ---------------------------------------------------------------------------

class Yapper:
    def __init__(self, path: str, device=device):
        self.tok = AutoTokenizer.from_pretrained(path, padding_side="left")
        self.model = AutoModelForCausalLMWithValueHead.from_pretrained(path).to(device)
        self.model.eval()

    def chat(self, prompt: str, **gkw):
        ids = self.tok(prompt, return_tensors="pt", truncation=True).to(device)
        out = self.model.generate(**ids, pad_token_id=self.tok.eos_token_id, **gkw)
        return self.tok.decode(out[0], skip_special_tokens=True)

# ---------------------------------------------------------------------------
# Logging callback ---------------------------------------------------------
# ---------------------------------------------------------------------------

class SaveMetricsCallback(TrainerCallback):
    def __init__(self, path: str):
        self.fname = os.path.join(path, "metrics.jsonl")
        os.makedirs(path, exist_ok=True)
        open(self.fname, "w").close()

    def on_log(self, args, state, control, logs=None, **_):
        if logs:
            with open(self.fname, "a") as f:
                f.write(json.dumps(logs) + "\n")

# ---------------------------------------------------------------------------
# CLI ----------------------------------------------------------------------
# ---------------------------------------------------------------------------

def parse_args():
    p = argparse.ArgumentParser("Train Yapper via PPO (3080‑friendly)")
    p.add_argument("--batch", type=int, default=4)
    p.add_argument("--mini", type=int, default=2)
    p.add_argument("--steps", type=int, default=100)
    p.add_argument("--out", type=str, default="yapbot‑ppo")
    p.add_argument("--log", type=str)
    p.add_argument("--demo", action="store_true")
    p.add_argument("--prompt", type=str, default="Say something unhinged but true.")
    return p.parse_args()

# ---------------------------------------------------------------------------
# Main ---------------------------------------------------------------------
# ---------------------------------------------------------------------------

def main():
    print("=== MAIN FUNCTION STARTED ===")
    args = parse_args()
    global _lm, _lm_tok

    # Demo mode ------------------------------------------------------------
    if args.demo:
        print(Yapper(MODEL_NAME).chat(args.prompt, max_new_tokens=120, temperature=1.1, top_p=0.9))
        return

    # Tokenizer ------------------------------------------------------------
    tok = AutoTokenizer.from_pretrained(MODEL_NAME, padding_side="left")
    tok.add_special_tokens({"pad_token": "[PAD]"})
    if tok.chat_template is None:
        tok.chat_template = SIMPLE_CHAT_TEMPLATE

    # Models ---------------------------------------------------------------
    actor_critic = AutoModelForCausalLMWithValueHead.from_pretrained(MODEL_NAME, torch_dtype=torch.float32).to(device)
    actor_critic.base_model_prefix = "pretrained_model"
    if not hasattr(actor_critic, "score"):
        def _score(self, hidden_states):
            return self.v_head(hidden_states).squeeze(-1).unsqueeze(-1)
        import types
        actor_critic.score = types.MethodType(_score, actor_critic)

    # PATCH FORWARD HERE, BEFORE PPOTrainer
    orig_forward = actor_critic.forward
    def safe_forward(*args, **kwargs):
        out = orig_forward(*args, **kwargs)
        if isinstance(out, tuple):
            logits = out[0] if len(out) > 0 else None
            return CausalLMOutput(logits=logits)
        return out
    actor_critic.forward = safe_forward

    ref = AutoModelForCausalLM.from_pretrained(MODEL_NAME, torch_dtype=torch.float32).to(device)
    ref.requires_grad_(False)

    # Resize after adding new token
    for m in (actor_critic, ref):
        _resize_embeddings(m, len(tok))

    # Wire reference for KL probe
    _lm, _lm_tok = ref, tok

    # Use greedy decoding (no sampling) to avoid CUDA errors in torch.multinomial
    gen_cfg = GenerationConfig(max_new_tokens=100, temperature=1.0, do_sample=False)
    for m in (actor_critic, ref):
        m.generation_config = gen_cfg

    # Dataset -------------------------------------------------------------- --------------------------------------------------------------
    prompts = [
        "Hey, what's on your mind today?",
        "What do you think about AI art?",
        "Tell me something weird you believe.",
        "How would you start an argument about pineapple on pizza?",
        "Say something totally unhinged but kinda true.",
    ] * 20
    ds = Dataset.from_dict({"prompt": prompts}).map(lambda e: tok(e["prompt"], truncation=True), batched=True, remove_columns=["prompt"])

    
    training_args = PPOConfig(
        output_dir=args.out,
        per_device_train_batch_size=args.batch,
        per_device_eval_batch_size=args.batch,
        learning_rate=3e-6,
        total_episodes=100,
        missing_eos_penalty=1.0,
        num_ppo_epochs=args.steps,
    )
    callbacks = [SaveMetricsCallback(args.log)] if args.log else []
    
    trainer = PPOTrainer(
        model=actor_critic,
        args=training_args,
        train_dataset=ds,
        eval_dataset=ds,
        processing_class=tok,
        ref_model=ref,
        reward_model=actor_critic,
        value_model=actor_critic,
        callbacks=callbacks,
    )

    # Patch PPOTrainer to always use PyTorch format for all saves
    def patched_save_model(self, output_dir: str = None, _internal_call: bool = False):
        # Save using PyTorch format to avoid safetensors shared tensor error
        self.model.save_pretrained(output_dir, safe_serialization=False)
        if getattr(self, "processing_class", None) is not None:
            self.processing_class.save_pretrained(output_dir)
        # Save config if exists
        if hasattr(self.model, "config") and self.model.config is not None:
            self.model.config.save_pretrained(output_dir)

    Trainer.save_model = patched_save_model

    print("About to start training...")
    trainer.train()
    print("Training finished.")

    os.makedirs(args.out, exist_ok=True)
    actor_critic.save_pretrained(args.out, safe_serialization=False)
    tok.save_pretrained(args.out, safe_serialization=True)
    print(f"✔ Saved fine‑tuned model to {args.out}")

if __name__ == "__main__":
    print("=== SCRIPT STARTED ===")
    main()
