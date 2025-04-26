# train_grpo_gpt2_rtx3080.py
#
# Adapted for GPT-2 on RTX 3080 10GB VRAM
# See https://github.com/willccbb/verifiers for original developments
#
import re
import torch
from datasets import load_dataset, Dataset
from transformers import AutoTokenizer, AutoModelForCausalLM, TrainingArguments # Added TrainingArguments for clarity
from peft import LoraConfig
from trl import GRPOConfig, GRPOTrainer
import os # For environment variable

# Mitigate potential tokenizers parallelism issues
os.environ["TOKENIZERS_PARALLELISM"] = "false"

# --- Dataset Loading and Preprocessing (Mostly Unchanged) ---

SYSTEM_PROMPT = """
Respond in the following format:

<reasoning>
...
</reasoning>
<answer>
...
</answer>
"""

XML_COT_FORMAT = """\
<reasoning>
{reasoning}
</reasoning>
<answer>
{answer}
</answer>
"""

def extract_xml_answer(text: str) -> str:
    # Make extraction more robust in case of missing tags or extra content
    answer_parts = text.split("<answer>")
    if len(answer_parts) > 1:
        answer = answer_parts[-1].split("</answer>")[0]
        return answer.strip()
    return "" # Return empty string if tag not found

def extract_hash_answer(text: str) -> str | None:
    if "####" not in text:
        return None
    return text.split("####")[1].strip().replace(",", "").replace("$", "")

def get_gsm8k_questions(split = "train") -> Dataset:
    data = load_dataset('openai/gsm8k', 'main', split=split)
    data = data.map(lambda x: {
        'prompt': [
            # Note: Base GPT-2 might struggle with system prompts and complex formatting.
            # Consider simplifying if results are poor.
            {'role': 'system', 'content': SYSTEM_PROMPT},
            {'role': 'user', 'content': x['question']}
        ],
        'answer': extract_hash_answer(x['answer'])
    })
    # Filter out examples where answer extraction failed (optional but good practice)
    data = data.filter(lambda x: x['answer'] is not None)
    return data

print("Loading dataset...")
dataset = get_gsm8k_questions()
print(f"Dataset loaded with {len(dataset)} examples.")

# --- Reward Functions (Unchanged Logic, Added Robustness) ---

def correctness_reward_func(prompts, completions, answer, **kwargs) -> list[float]:
    responses = [completion[0]['content'] for completion in completions]
    q = prompts[0][-1]['content'] if prompts and prompts[0] else "Unknown Question"
    extracted_responses = [extract_xml_answer(r) for r in responses]
    # Handle potential None answers from dataset preprocessing if filtering wasn't done
    valid_answers = [a for a in answer if a is not None]
    if not valid_answers: return [0.0] * len(extracted_responses) # Or handle as error

    # Simple print, avoid overwhelming console if num_generations is high
    if len(responses) > 0:
         print('-'*20, f"\nQ: {q[:100]}...", f"\nA: {valid_answers[0]}", f"\nR: {responses[0][:150]}...", f"\nExtracted: {extracted_responses[0]}")

    # Ensure comparison happens correctly, handle cases where extraction fails
    rewards = []
    for r_extr, a_true in zip(extracted_responses, valid_answers):
        if r_extr == a_true:
            rewards.append(2.0)
        # Optional: Penalize empty extraction slightly less than wrong answer?
        # elif r_extr == "":
        #     rewards.append(-0.1) # Example penalty
        else:
            rewards.append(0.0) # Or a negative reward, e.g., -0.5
    return rewards

def int_reward_func(completions, **kwargs) -> list[float]:
    responses = [completion[0]['content'] for completion in completions]
    extracted_responses = [extract_xml_answer(r) for r in responses]
    # Check if extracted string consists ONLY of digits (potentially with a sign)
    return [0.5 if r and r.lstrip('-').isdigit() else 0.0 for r in extracted_responses]

def strict_format_reward_func(completions, **kwargs) -> list[float]:
    pattern = r"^<reasoning>\s*.*?\s*</reasoning>\s*<answer>\s*.*?\s*</answer>\s*$" # Allow more whitespace flexibility
    responses = [completion[0]["content"] for completion in completions]
    matches = [re.match(pattern, r, flags=re.DOTALL) for r in responses]
    return [0.5 if match else 0.0 for match in matches]

def soft_format_reward_func(completions, **kwargs) -> list[float]:
    pattern = r"<reasoning>.*?</reasoning>\s*<answer>.*?</answer>"
    responses = [completion[0]["content"] for completion in completions]
    # Use re.search to find the pattern anywhere, not just at the start
    matches = [re.search(pattern, r, flags=re.DOTALL) for r in responses]
    return [0.5 if match else 0.0 for match in matches]

def count_xml(text) -> float:
    count = 0.0
    reasoning_open = text.count("<reasoning>")
    reasoning_close = text.count("</reasoning>")
    answer_open = text.count("<answer>")
    answer_close = text.count("</answer>")

    if reasoning_open == 1: count += 0.125
    if reasoning_close == 1: count += 0.125
    if answer_open == 1: count += 0.125
    if answer_close == 1: count += 0.125

    # Penalize content outside the final answer tag slightly
    if answer_close == 1:
        trailing_content = text.split("</answer>")[-1].strip()
        count -= len(trailing_content) * 0.001

    return max(0.0, count) # Ensure reward is not negative

def xmlcount_reward_func(completions, **kwargs) -> list[float]:
    contents = [completion[0]["content"] for completion in completions]
    return [count_xml(c) for c in contents]


# --- Model and Training Configuration ---

model_name = "gpt2" # Start with the smallest GPT-2 variant
# model_name = "gpt2-medium" # Try if gpt2 trains successfully and you have VRAM headroom

output_dir = f"outputs/{model_name.replace('/', '-')}-GRPO-gsm8k-rtx3080"
run_name = f"{model_name.replace('/', '-')}-GRPO-gsm8k-rtx3080"

# GPT-2 context window is 1024 tokens
MAX_CONTEXT_LEN = 1024
MAX_PROMPT_LEN = 512 # Increased prompt length slightly, adjust if needed
MAX_COMPLETION_LEN = MAX_CONTEXT_LEN - MAX_PROMPT_LEN # Max 512 tokens for completion

training_args = GRPOConfig(
    output_dir=output_dir,
    run_name=run_name,
    learning_rate=5e-5, # Might need adjustment for GPT-2 (often higher than for larger models)
    adam_beta1 = 0.9,
    adam_beta2 = 0.99,
    weight_decay = 0.01, # More standard weight decay
    warmup_ratio = 0.1,
    lr_scheduler_type='cosine',
    logging_steps=10, # Log less frequently to reduce overhead
    fp16=False, # Disable fp16 for stability
    bf16=False, # Disable bf16 for stability
    per_device_train_batch_size=2, # Updated batch size
    gradient_accumulation_steps=1, # Updated accumulation steps
    gradient_checkpointing=True, # CRITICAL for saving memory
    num_generations=2, # Keep this in config
    max_prompt_length=MAX_PROMPT_LEN,
    max_completion_length=MAX_COMPLETION_LEN,
    num_train_epochs=1, # Start with 1 epoch
    save_steps=200, # Save less frequently
    max_grad_norm=1.0, # More standard grad norm clipping
    report_to="wandb", # or "tensorboard" or "none"
    log_on_each_node=False,
    remove_unused_columns=False, # Important for GRPO which needs extra columns like 'answer'
    optim="adamw_torch", # Standard optimizer
)

# LoRA configuration for GPT-2
peft_config = LoraConfig(
    r=16,
    lora_alpha=32, # Often alpha = 2*r
    # Target modules for GPT-2 are typically 'c_attn', 'c_proj', 'c_fc'
    # Verify these names by inspecting model.named_modules() if needed
    target_modules=["c_attn", "c_proj"], # Start with attention, add 'c_fc' if VRAM allows
    task_type="CAUSAL_LM",
    lora_dropout=0.05,
    bias="none", # Usually set to 'none' or 'lora_only' for LoRA
)

print("Loading model and tokenizer...")
model = AutoModelForCausalLM.from_pretrained(
    model_name,
    torch_dtype=torch.float32, # Use float16 to match fp16=True
    # attn_implementation="sdpa", # Use Scaled Dot Product Attention if available (PyTorch >= 2.0)
    # remove flash_attention_2 as it's not standard for GPT-2
    device_map=None # Load entire model to CUDA:0 specified later
).to("cuda")

tokenizer = AutoTokenizer.from_pretrained(model_name)

# Set padding token for GPT-2
if tokenizer.pad_token is None:
    tokenizer.pad_token = tokenizer.eos_token
    print("Set pad_token to eos_token")

# Resize token embeddings if pad token was added (important!)
model.resize_token_embeddings(len(tokenizer))

if not hasattr(tokenizer, "chat_template") or tokenizer.chat_template is None:
    # Minimal template: just concatenate user and system messages
    tokenizer.chat_template = (
        "{% for message in messages %}"
        "{% if message['role'] == 'system' %}System: {{ message['content'] }}\n"
        "{% elif message['role'] == 'user' %}User: {{ message['content'] }}\n"
        "{% elif message['role'] == 'assistant' %}Assistant: {{ message['content'] }}\n"
        "{% endif %}"
        "{% endfor %}"
    )

print("Model VRAM Footprint (approximate):")
print(f"{model.get_memory_footprint() / 1e9:.2f} GB")
print(f"DEBUG: Initializing GRPOTrainer with num_generations = {training_args.num_generations}")
print(f"DEBUG: per_device_train_batch_size = {training_args.per_device_train_batch_size}")


# --- Trainer Initialization and Training ---

print("Initializing GRPOTrainer...")
trainer = GRPOTrainer(
    model=model,
    processing_class=tokenizer,
    reward_funcs=[
        xmlcount_reward_func,
        soft_format_reward_func,
        strict_format_reward_func,
        int_reward_func,
        correctness_reward_func],
    args=training_args,
    train_dataset=dataset,
    #peft_config=peft_config # Enable PEFT/LoRA
)

print("Starting training...")
trainer.train()

print("Training finished. Saving model...")
trainer.save_model(output_dir)
tokenizer.save_pretrained(output_dir)
print(f"Model and tokenizer saved to {output_dir}")

with torch.no_grad():
    outputs = model(input_ids)
    if torch.isnan(outputs.logits).any():
        print("NaN detected in logits!")