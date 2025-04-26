"""Minimal working PPO example with TRL 0.16.1 + transformers 4.52.0.dev0.
Optimised for a single 10 GB RTX 3080: *only two GPT‑2 models* live on the GPU –
(1) an **actor‑critic** with a shared backbone and value head, and (2) a frozen
reference model in half‑precision.  Total VRAM footprint ~6 GB during training.
"""

import argparse
import json
import math
import os
import re
from collections import Counter

import torch
import torch.nn as nn
import spacy
from datasets import Dataset
from transformers import (
    AutoModelForCausalLM,
    AutoTokenizer,
    DataCollatorWithPadding,
    GenerationConfig,
)
from transformers.trainer_callback import TrainerCallback
from trl import PPOConfig, PPOTrainer, AutoModelForCausalLMWithValueHead
from trl.trainer.utils import SIMPLE_CHAT_TEMPLATE

# ---------------------------------------------------------------------------
# Device & model name -------------------------------------------------------
# ---------------------------------------------------------------------------

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
MODEL_NAME = "gpt2"  # 124 M‑param – fits easily on a 10 GB GPU in fp16

# ---------------------------------------------------------------------------
# Reward wrapper ------------------------------------------------------------
# ---------------------------------------------------------------------------

class RewardFunction(nn.Module):
    """Wrap a python callable so PPOTrainer can consume it."""

    def __init__(self, fn, tok):
        super().__init__()
        self.fn = fn
        self.tok = tok

    def forward(self, input_ids=None, attention_mask=None, **_):
        texts = self.tok.batch_decode(input_ids, skip_special_tokens=True)
        rs = torch.tensor([self.fn(t) for t in texts], dtype=input_ids.dtype, device=input_ids.device)
        B, S = input_ids.shape
        rewards = torch.zeros(B, S, 1, dtype=input_ids.dtype, device=input_ids.device)
        rewards[:, -1, 0] = rs  # place at final token
        return rewards, rs, torch.full((B,), S - 1, dtype=torch.long, device=input_ids.device)


# ---------------------------------------------------------------------------
# Yapper reward heuristic ---------------------------------------------------
# ---------------------------------------------------------------------------

_nlp = spacy.load("en_core_web_sm", disable=["parser", "ner"])
_nlp.add_pipe("sentencizer", first=True)
_lm = _lm_tok = None  # lazy‑filled later


def _sigmoid(x, slope=1.0, width=1.0):
    return width / (1 + math.exp(-slope * (x - 0.5)))


def yap_score(text: str, weights=None, kl_ref_logits=None):
    weights = weights or {
        "length": 0.35,
        "questions": 0.15,
        "reflection": 0.10,
        "fillers": 0.10,
        "diversity": 0.10,
        "repetition": 0.10,
        "sentiment": 0.05,
        "kl_weird": 0.05,  # lighter weight; PPO already has its own KL term
    }
    if _lm is None:
        weights["kl_weird"] = 0.0

    doc = _nlp(text)
    toks = [t.text for t in doc if not t.is_space]
    T = len(toks) or 1

    len_score = _sigmoid(min(T, 60) / 60, slope=12)
    q_score = text.count("?") / max(1, len(list(doc.sents)))
    refl = {t.lower_ for t in doc if t.lower_ in {
        "think", "feel", "know", "guess", "maybe", "suppose", "wonder",
        "honestly", "personally", "kinda", "sorta",
    }}
    refl_score = min(len(refl) / 4, 1.0)
    fillers_score = min(len(re.findall(r"\b(?:uh+|umm+|erm+)\b|\.{2,}|--", text)) / 3, 1.0)
    div_score = _sigmoid(len(set(toks)) / T, slope=10)
    repeats = sum(v for v in Counter(zip(toks, toks[1:])).values() if v > 1)
    rep_score = math.exp(-repeats / 5)
    polarity = getattr(doc._, "polarity", 0.0)
    sent_score = max(0.0, 1 - abs(polarity - 0.4))

    kl_score = 0.0
    if weights.get("kl_weird", 0) > 0:
        with torch.no_grad():
            ids = _lm_tok(text, return_tensors="pt").input_ids.to(_lm.device)
            logits = _lm(ids).logits[0, :-1]
            ref = kl_ref_logits if kl_ref_logits is not None else logits.detach()
            kl_div = torch.nn.functional.kl_div(logits.log_softmax(-1), ref.log_softmax(-1), log_target=True, reduction="batchmean")
            kl_score = _sigmoid(min(kl_div.item(), 3) / 3, slope=8)

    raw = (
        weights["length"] * len_score + weights["questions"] * q_score + weights["reflection"] * refl_score +
        weights["fillers"] * fillers_score + weights["diversity"] * div_score + weights["repetition"] * rep_score +
        weights["sentiment"] * sent_score + weights["kl_weird"] * kl_score
    )
    return max(0.0, min(raw / sum(weights.values()), 1.0))


# ---------------------------------------------------------------------------
# Self‑chat helper ----------------------------------------------------------
# ---------------------------------------------------------------------------

class Yapper:
    def __init__(self, path: str, device=device):
        self.tok = AutoTokenizer.from_pretrained(path, padding_side="left")
        self.model = AutoModelForCausalLMWithValueHead.from_pretrained(path).to(device)
        self.model.eval()

    def chat(self, prompt: str, **kw):
        ids = self.tok(prompt, return_tensors="pt").to(device)
        out = self.model.generate(**ids, pad_token_id=self.tok.eos_token_id, **kw)
        return self.tok.decode(out[0], skip_special_tokens=True)


# ---------------------------------------------------------------------------
# Callback for logging ------------------------------------------------------
# ---------------------------------------------------------------------------

class SaveMetricsCallback(TrainerCallback):
    def __init__(self, path: str):
        self.fname = os.path.join(path, "metrics.jsonl")
        os.makedirs(path, exist_ok=True)
        open(self.fname, "w").close()

    def on_log(self, args, state, control, logs=None, **_):
        if not logs:
            return
        with open(self.fname, "a") as f:
            f.write(json.dumps(logs) + "\n")


# ---------------------------------------------------------------------------
# Main ----------------------------------------------------------------------
# ---------------------------------------------------------------------------

def parse_args():
    p = argparse.ArgumentParser("Yapper PPO (3080‑friendly)")
    p.add_argument("--batch", type=int, default=4)
    p.add_argument("--mini", type=int, default=2)
    p.add_argument("--steps", type=int, default=100)
    p.add_argument("--out", type=str, default="yapbot‑ppo")
    p.add_argument("--log", type=str)
    p.add_argument("--demo", action="store_true")
    p.add_argument("--prompt", type=str, default="Say something unhinged but true.")
    return p.parse_args()


def main():
    args = parse_args()
    global _lm, _lm_tok

    if args.demo:
        print(Yapper(MODEL_NAME).chat(args.prompt, max_new_tokens=120, temperature=1.1, top_p=0.9))
        return

    tok = AutoTokenizer.from_pretrained(MODEL_NAME, padding_side="left")
    tok.add_special_tokens({"pad_token": "[PAD]"})
    if tok.chat_template is None:
        tok.chat_template = SIMPLE_CHAT_TEMPLATE

    # single actor‑critic with value head (saves ~1 GB)
    actor_critic = AutoModelForCausalLMWithValueHead.from_pretrained(
        MODEL_NAME, torch_dtype=torch.float16
    ).to(device)

    # frozen reference in fp16
    ref = AutoModelForCausalLM.from_pretrained(MODEL_NAME, torch_dtype=torch.float16).to(device)
    for p in ref.parameters():
        p.requires_grad = False

    for m in (actor_critic, ref):
        m.resize_token_embeddings(len(tok))

    _lm, _lm_tok = ref, tok  # for KL‑probe

    gen_cfg = GenerationConfig(
        max_new_tokens=100,
        temperature=1.0,
        top_p=0.9,
        top_k=50,
        do_sample=True,
    )
    for m in (actor_critic, ref):
        m.generation_config = gen_cfg

    # dataset ---------------------------------------------------------------
    prompts = [
        "Hey, what's on your mind today?",
        "What do you think about AI art?",
        "Tell me something weird you believe.",
        "How would you start an argument about pineapple on pizza?",
        "Say something totally unhinged but kinda true.",
    ] * 20
    ds = Dataset.from_dict({"prompt": prompts})
    ds = ds.map(lambda e: tok(e["prompt"], truncation=True), batched=True, remove_columns=["prompt"])

    reward_model = RewardFunction(yap_score, tok).to(device)

    ppo_cfg = PPOConfig(batch_size=args.batch, mini_batch_size=args.mini, total_episodes=args.steps)

    print("per_device_train_batch_size:", ppo_cfg.per_device_train_batch_size)
    print("gradient_accumulation_steps:", ppo_cfg.gradient_accumulation_steps)
    print("num_generations:", ppo_cfg.num_generations)

    trainer = PPOTrainer(
        args=ppo_cfg,
        model=actor_critic,
        ref_model=ref,
        tokenizer=tok,
        reward_model=reward_model,
        train_dataset=ds,
        data_collator=DataCollatorWithPadding(tok),
        callbacks=[SaveMetricsCallback(args.log)] if args.log else None,
        num_generations=1,
    )

    print("Training …")
    trainer.train()

    os.makedirs(args.out, exist_ok=True)
    trainer.save_pretrained(args.out)
    tok.save_pretrained(args.out)
    print(f"Saved to {args.out}")


if __name__ == "__main__":
    main()
