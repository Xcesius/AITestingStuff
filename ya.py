import torch
from transformers import GPT2LMHeadModel, GPT2Tokenizer
from datetime import datetime
import os
import time
from termcolor import colored

# -----------------------------
# Config
# -----------------------------
MODEL_NAME = "gpt2"
MAX_TURNS = 10
MAX_HISTORY = 3
AGENT_A_TAG = "[sarcastic bot]"
AGENT_B_TAG = "[paranoid bot]"

# Logging setup
timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
log_dir = "logs"
os.makedirs(log_dir, exist_ok=True)
log_file = os.path.join(log_dir, f"yapbot_duet_{timestamp}.txt")

# -----------------------------
# Load model/tokenizer
# -----------------------------
tokenizer = GPT2Tokenizer.from_pretrained(MODEL_NAME)
model = GPT2LMHeadModel.from_pretrained(MODEL_NAME)
model.eval()

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model.to(device)

# -----------------------------
# Core functions
# -----------------------------
def log_turn(turn, speaker, prompt, reply, reward):
    with open(log_file, "a", encoding="utf-8") as f:
        f.write(f"--- Turn {turn} | {speaker} | {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} ---\n")
        f.write(f"Prompt: {prompt}\n")
        f.write(f"Reply: {reply}\n")
        f.write(f"Reward: {reward:.2f}\n\n")

def score_response(response):
    length_score = min(len(response.split()), 30) / 30
    question_bonus = 0.3 if "?" in response else 0
    repetition_penalty = -0.3 if response.lower().count("i’m") > 2 else 0
    return length_score + question_bonus + repetition_penalty

def generate_reply(prompt, max_length=50):
    input_ids = tokenizer.encode(prompt, return_tensors="pt").to(device)
    output = model.generate(input_ids, max_length=len(input_ids[0]) + max_length, do_sample=True, top_k=50)
    decoded = tokenizer.decode(output[0], skip_special_tokens=True)
    return decoded[len(prompt):].strip()

# -----------------------------
# Initial seed
# -----------------------------
agent_a_history = [f"{AGENT_A_TAG} So what’s your deal?"]
agent_b_history = [f"{AGENT_B_TAG} Why are you even asking me that?"]

# -----------------------------
# Main loop
# -----------------------------
for turn in range(1, MAX_TURNS + 1):
    # Agent A speaks
    prompt_a = " ".join(agent_b_history[-MAX_HISTORY:])
    full_prompt_a = f"{AGENT_A_TAG} {prompt_a}"
    reply_a = generate_reply(full_prompt_a)
    reward_a = score_response(reply_a)

    print(colored(f"\nA [{AGENT_A_TAG}]: {reply_a}", "cyan"))
    print(colored(f"[Reward A]: {reward_a:.2f}", "yellow"))
    log_turn(turn, "Agent A", full_prompt_a, reply_a, reward_a)
    agent_a_history.append(reply_a)

    time.sleep(0.5)

    # Agent B speaks
    prompt_b = " ".join(agent_a_history[-MAX_HISTORY:])
    full_prompt_b = f"{AGENT_B_TAG} {prompt_b}"
    reply_b = generate_reply(full_prompt_b)
    reward_b = score_response(reply_b)

    print(colored(f"\nB [{AGENT_B_TAG}]: {reply_b}", "magenta"))
    print(colored(f"[Reward B]: {reward_b:.2f}", "yellow"))
    log_turn(turn, "Agent B", full_prompt_b, reply_b, reward_b)
    agent_b_history.append(reply_b)

    time.sleep(0.5)
