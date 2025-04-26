"""Minimal working PPO example with TRL 0.16.1 + transformers 4.52.0.dev0.
This trains GPT‑2 with a constant reward (always 1.0) on a 100‑sample IMDB
subset. The script patches all mismatches between TRL’s current PPOTrainer
and the value‑head wrapper so it runs end‑to‑end.
"""

import torch
import torch.nn as nn
from datasets import load_dataset
from transformers import (
    AutoTokenizer,
    AutoModelForCausalLM,
    GenerationConfig,
)
from trl import AutoModelForCausalLMWithValueHead, PPOConfig, PPOTrainer
from trl.trainer.utils import SIMPLE_CHAT_TEMPLATE

# ---------------------------------------------------------------------------
# Device & model name
# ---------------------------------------------------------------------------

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model_name = "gpt2"

# ---------------------------------------------------------------------------
# Helper modules to satisfy PPOTrainer / get_reward()
# ---------------------------------------------------------------------------

class ZeroBackbone(nn.Module):
    """Stub LM: accepts HF CausalLM kwargs and returns dummy hidden‑states."""

    def forward(self, input_ids=None, attention_mask=None, **kwargs):
        b, s = input_ids.shape
        h = torch.zeros(b, s, 1, device=input_ids.device)
        return type("Output", (), {"hidden_states": [h]})


class ConstantReward(nn.Module):
    """Reward model that always outputs 1.0 (broadcasted)."""

    base_model_prefix = "pretrained_model"

    def __init__(self, value: float = 1.0):
        super().__init__()
        self.register_buffer("const", torch.tensor(float(value)))
        # Backbone that get_reward() will try to call.
        self.pretrained_model = ZeroBackbone()

    def score(self, hidden_states):
        b, s, _ = hidden_states.shape
        return self.const.expand(b, s, 1)

    def forward(self, *args, **kwargs):  # never used
        raise RuntimeError("ConstantReward is not meant to be called directly")


class GPT2WithValueHead(AutoModelForCausalLMWithValueHead):
    """Adds the hooks PPOTrainer expects (base_model_prefix + score)."""

    base_model_prefix = "pretrained_model"

    def score(self, hidden_states):
        return self.v_head(hidden_states).squeeze(-1).unsqueeze(-1)


# ---------------------------------------------------------------------------
# Tokenizer
# ---------------------------------------------------------------------------

tok = AutoTokenizer.from_pretrained(model_name, padding_side="left")
tok.add_special_tokens({"pad_token": "[PAD]"})
if getattr(tok, "chat_template", None) is None:
    tok.chat_template = SIMPLE_CHAT_TEMPLATE

# ---------------------------------------------------------------------------
# Models: policy (actor), value (critic), ref (KL baseline)
# ---------------------------------------------------------------------------

policy = AutoModelForCausalLM.from_pretrained(model_name).to(device)  # plain LM
value  = GPT2WithValueHead.from_pretrained(model_name).to(device)
ref    = AutoModelForCausalLM.from_pretrained(model_name).to(device)

# attach GenerationConfig to each model that might generate
_gen_cfg = GenerationConfig.from_pretrained(model_name)
for m in (policy, value, ref):
    m.generation_config = _gen_cfg

# ---------------------------------------------------------------------------
# Reward model (constant 1.0) — kept frozen
# ---------------------------------------------------------------------------

reward = ConstantReward().to(device)
for p in reward.parameters():
    p.requires_grad = False

# freeze reference model
for p in ref.parameters():
    p.requires_grad = False

# ---------------------------------------------------------------------------
# Dataset (tiny IMDB subset)
# ---------------------------------------------------------------------------

ds = load_dataset("imdb", split="train[:100]").map(
    lambda x: tok(x["text"], truncation=True, max_length=128),
    batched=True,
    remove_columns=["text"],
)

# ---------------------------------------------------------------------------
# PPO configuration
# ---------------------------------------------------------------------------

ppo_cfg = PPOConfig(
    batch_size=1,
    mini_batch_size=1,
    total_episodes=100,
)

# ---------------------------------------------------------------------------
# Trainer and training loop
# ---------------------------------------------------------------------------

trainer = PPOTrainer(
    args=ppo_cfg,
    processing_class=tok,  # tokenizer instance
    model=policy,
    value_model=value,
    ref_model=ref,
    reward_model=reward,
    train_dataset=ds,
    eval_dataset = ds.select(range(10))
)

print("===training policy===")
trainer.train()
print("Done ✔")
