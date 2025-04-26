import torch
from transformers import AutoModelForCausalLM, AutoTokenizer, BitsAndBytesConfig
import time
import threading
import sys
import random
import re
import os

# --- Quantization Config ---
try:
    quantization_config = BitsAndBytesConfig(
        load_in_4bit=True,
        bnb_4bit_compute_dtype=torch.float16,
        bnb_4bit_quant_type="nf4",
        bnb_4bit_use_double_quant=True,
    )
except ImportError:
    print("Error: bitsandbytes library not found. Please install it: pip install bitsandbytes accelerate")
    sys.exit(1)
except Exception as e:
    print(f"Error creating BitsAndBytesConfig: {e}")
    sys.exit(1)

# --- Configuration ---
MODEL_NAME = "microsoft/phi-3-mini-128k-instruct"
MAX_HISTORY_TURNS = 5
PROACTIVE_DELAY_SECONDS = 15
PROACTIVE_MESSAGES = [
    "Is there anything else I can help you with?",
    "What's on your mind?",
    "Shall we continue?",
    "Do you have any other questions?",
    "Just checking if you needed anything else.",
]
SYSTEM_PROMPT = "You are Phi, a helpful and friendly AI assistant. Answer the user concisely and directly. Avoid rambling." # Added avoid rambling instruction


# --- Load Model and Tokenizer ---
print(f"Loading model ({MODEL_NAME}) and tokenizer with 4-bit quantization...")
try:
    tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME, trust_remote_code=False) # Keep trust_remote_code=False

    model = AutoModelForCausalLM.from_pretrained(
        MODEL_NAME,
        quantization_config=quantization_config,
        torch_dtype=torch.float16,
        device_map="auto",
        trust_remote_code=False, # Keep this False
        # attn_implementation="eager", # Can try adding this back if needed
    )

    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token
        print(f"Set pad_token to eos_token: {tokenizer.pad_token}")

    if getattr(tokenizer, 'chat_template', None) is None:
        print("Warning: No chat template found on tokenizer. Using a generic one.")
        # ... (generic template if needed) ...
    else:
        print("Using existing chat template from tokenizer.")

    model.eval()
    print(f"Model loaded successfully with 4-bit quantization using device_map.")

except ImportError as e:
     print(f"ImportError: {e}. Libraries missing/outdated.")
     print("Please run: pip install --upgrade torch transformers accelerate bitsandbytes")
     sys.exit(1)
except Exception as e:
    print(f"Error loading model: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)


# --- Global variables ---
user_input_buffer = ""
input_available = threading.Event()
program_running = True

# --- Input function ---
def get_input():
    global user_input_buffer, input_available, program_running
    while program_running:
        try:
            user_input_buffer = input()
            if not program_running: break
            input_available.set()
        except EOFError:
            print("Input stream closed.")
            program_running = False
            input_available.set()
            break
        # time.sleep(0.1) # Usually not needed

# --- Main Chat Function ---
def chat():
    global user_input_buffer, input_available, program_running
    conversation_history = [{"role": "system", "content": SYSTEM_PROMPT}]
    last_interaction_time = time.time()
    # ai_was_last_speaker = False # We don't strictly need this flag with the new logic

    input_thread = threading.Thread(target=get_input, daemon=True)
    input_thread.start()

    print(f"\nChatbot initialized with {MODEL_NAME}. Type your first message (or 'quit' to exit).")

    while program_running:
        current_time = time.time()
        user_input = None
        processed_input_this_cycle = False # Flag to track if user input was handled

        # --- Check for and Process User Input FIRST ---
        if input_available.wait(timeout=0.1): # Check if input is ready
            if not program_running and user_input_buffer == "": break
            user_input = user_input_buffer
            user_input_buffer = ""
            input_available.clear()
            last_interaction_time = current_time # Reset timer on any user input
            processed_input_this_cycle = True # Mark that we processed input

            if user_input.lower() == 'quit':
                print("Goodbye!")
                program_running = False
                break

            print(f"\nYou: {user_input}")
            conversation_history.append({"role": "user", "content": user_input})

            # --- Generate AI Response Following User Input ---
            try:
                prompt_dict_list = [conversation_history[0]] + conversation_history[-(MAX_HISTORY_TURNS*2):]
                if len(prompt_dict_list) > 1 and prompt_dict_list[1]['role'] == 'system':
                     prompt_dict_list.pop(0)

                templated_output = tokenizer.apply_chat_template(
                    prompt_dict_list, add_generation_prompt=True, return_tensors="pt"
                )

                if isinstance(templated_output, dict):
                    input_ids = templated_output['input_ids']
                    attention_mask = templated_output.get('attention_mask', torch.ones_like(input_ids))
                elif isinstance(templated_output, torch.Tensor):
                    input_ids = templated_output
                    attention_mask = torch.ones_like(input_ids)
                else:
                    print("Error: Unexpected output type from apply_chat_template")
                    continue

                try:
                    input_device = next(model.parameters()).device
                except StopIteration:
                    input_device = torch.device("cpu") # Fallback

                input_ids = input_ids.to(input_device)
                attention_mask = attention_mask.to(input_device)

                with torch.no_grad():
                    output_sequences = model.generate(
                        input_ids=input_ids,
                        attention_mask=attention_mask,
                        max_new_tokens=200,  # Slightly increased, adjust as needed
                        pad_token_id=tokenizer.pad_token_id,
                        eos_token_id=tokenizer.eos_token_id,
                        # --- Adjusted Generation Parameters ---
                        do_sample=True,
                        temperature=0.6,     # Lowered temperature
                        top_p=0.85,          # Slightly stricter top_p
                        repetition_penalty=1.2 # Increased penalty
                    )

                response_ids = output_sequences[0][input_ids.shape[-1]:]
                generated_text = tokenizer.decode(response_ids, skip_special_tokens=True)
                generated_text = generated_text.strip()
                generated_text = re.sub(r'<\|.*?\|>', '', generated_text)
                generated_text = generated_text.replace("<|end|>", "").strip()

                if not generated_text: generated_text = "..."

                print(f"AI: {generated_text}")
                conversation_history.append({"role": "assistant", "content": generated_text})
                last_interaction_time = current_time # Reset timer AFTER AI speaks too

            except Exception as e:
                print(f"\nError during generation: {e}")
                traceback.print_exc()
                conversation_history.append({"role": "assistant", "content": "[Error generating response]"})
                last_interaction_time = current_time # Reset timer even on error


        # --- Handle Proactive AI Turn ---
        # Only check if NO user input was processed this cycle AND enough time has passed
        elif not processed_input_this_cycle and (current_time - last_interaction_time > PROACTIVE_DELAY_SECONDS):
             # Check if history exists and last speaker was AI to avoid infinite loop if model fails first response
             if conversation_history and conversation_history[-1]['role'] == 'assistant':
                proactive_message = random.choice(PROACTIVE_MESSAGES)
                print(f"AI (proactive): {proactive_message}")
                conversation_history.append({"role": "assistant", "content": proactive_message})
                last_interaction_time = current_time # Reset timer after proactive message

    print("Exiting program.")
    program_running = False


# --- Run the chat ---
if __name__ == "__main__":
    try:
        import accelerate
        import bitsandbytes
    except ImportError as e:
        print(f"Missing required library: {e}")
        print("Please install required libraries: pip install --upgrade torch transformers accelerate bitsandbytes")
        sys.exit(1)

    chat()