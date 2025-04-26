import torch
from transformers import AutoModelForCausalLM, AutoTokenizer, BitsAndBytesConfig
import time
import threading
import sys
import random
import re # Import re for cleanup later

# --- Create Quantization Config FIRST ---
# Ensure bitsandbytes is installed: pip install bitsandbytes accelerate
try:
    quantization_config = BitsAndBytesConfig(
        load_in_4bit=True,
        bnb_4bit_compute_dtype=torch.float16, # Use float16 for RTX 3080
        bnb_4bit_quant_type="nf4",
        bnb_4bit_use_double_quant=True,
    )
except ImportError:
    print("Error: bitsandbytes library not found. Please install it: pip install bitsandbytes")
    sys.exit(1)
except Exception as e:
    print(f"Error creating BitsAndBytesConfig: {e}")
    sys.exit(1)


# --- Configuration ---
MODEL_NAME = "microsoft/phi-3-mini-128k-instruct" # Using instruct version
# DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu") # Not needed with device_map="auto"
MAX_HISTORY_TURNS = 5 # Be mindful of history length with large context models
PROACTIVE_DELAY_SECONDS = 15 # Slightly longer delay maybe
PROACTIVE_MESSAGES = [
    "Anything else I can help with?",
    "What are you thinking about?",
    "Shall we talk about something else?",
    "Is there anything on your mind?",
    "Just checking in...",
]
SYSTEM_PROMPT = "You are a friendly and helpful conversational AI assistant named Phi. Respond clearly and concisely to the user." # Give it a name maybe


# --- Load Model and Tokenizer ---
print(f"Loading model ({MODEL_NAME}) and tokenizer with 4-bit quantization...")
try:
    tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME, trust_remote_code=True) # Added trust_remote_code=True sometimes needed for Phi

    # Load model using quantization config and device_map
    model = AutoModelForCausalLM.from_pretrained(
        MODEL_NAME,
        quantization_config=quantization_config, # Pass the config HERE
        torch_dtype=torch.float16,             # Specify compute dtype HERE
        device_map="auto",                     # Let accelerate handle device placement
        trust_remote_code=True               # Added trust_remote_code=True
        # low_cpu_mem_usage=True,              # Optional: Might help if CPU RAM is also limited during loading
    )

    # Setup tokenizer padding and chat template AFTER loading tokenizer
    if tokenizer.pad_token is None:
        # Some models like Phi might use EOS as pad, or need a specific unk token etc.
        # Setting it to EOS is usually safe but check model card if issues arise.
        tokenizer.pad_token = tokenizer.eos_token
        print(f"Set pad_token to eos_token: {tokenizer.pad_token}")

    # Phi-3 usually has a chat template, but good practice to check/set a default
    if tokenizer.chat_template is None:
         # Template might differ for Phi-3, check its model card on Hugging Face Hub
         # This is a generic example
        template = "{% for message in messages %}"
        template += "{{'<|' + message['role'] + '|>\n' + message['content'] + '<|end|>\n'}}"
        template += "{% endfor %}"
        template += "{% if add_generation_prompt %}"
        template += "<|assistant|>\n"
        template += "{% endif %}"
        tokenizer.chat_template = template
        print("Applied a basic chat template.")
    else:
        print("Using existing chat template from tokenizer.")


    # No need to resize embeddings after quantization usually
    # No need for model.to(DEVICE) because of device_map="auto"
    model.eval()
    print(f"Model loaded successfully with 4-bit quantization using device_map.")

except ImportError:
     print("Accelerate library not found. Please install it: pip install accelerate")
     sys.exit(1)
except Exception as e:
    print(f"Error loading model: {e}")
    print("Check model name, internet connection, and ensure libraries (torch, transformers, bitsandbytes, accelerate) are installed correctly.")
    sys.exit(1)


# --- Global variables ---
user_input_buffer = ""
input_available = threading.Event()
program_running = True

# --- Input function (no changes needed) ---
def get_input():
    global user_input_buffer, input_available, program_running
    # ... (keep the input function as it was) ...
    while program_running:
        try:
            user_input_buffer = input()
            if not program_running: break
            input_available.set()
        except EOFError:
            program_running = False
            input_available.set()
            break
        time.sleep(0.1)

# --- Main Chat Function ---
def chat():
    global user_input_buffer, input_available, program_running
    conversation_history = [{"role": "system", "content": SYSTEM_PROMPT}]
    last_interaction_time = time.time()
    ai_was_last_speaker = False

    input_thread = threading.Thread(target=get_input, daemon=True)
    input_thread.start()

    print("\nChatbot initialized. Type your first message (or 'quit' to exit).")

    while program_running:
        current_time = time.time()
        user_input = None

        if input_available.wait(timeout=0.1):
            if not program_running and user_input_buffer == "": break
            user_input = user_input_buffer
            user_input_buffer = ""
            input_available.clear()
            last_interaction_time = current_time
            ai_was_last_speaker = False

            if user_input.lower() == 'quit':
                print("Goodbye!")
                program_running = False
                break

            print(f"\nYou: {user_input}")
            # Use standard roles for Phi-3 template ('user', 'assistant')
            conversation_history.append({"role": "user", "content": user_input})

            # --- Generate AI Response ---
            try:
                # Limit history, keeping system prompt
                # Be careful with Phi-3's large context - might need more sophisticated history management for long chats
                prompt_dict_list = [conversation_history[0]] + conversation_history[-(MAX_HISTORY_TURNS*2):]
                if len(prompt_dict_list) > 1 and prompt_dict_list[1]['role'] == 'system':
                     prompt_dict_list.pop(0)

                # Apply the chat template correctly
                # Note: Phi-3 template might require specific handling, check tokenizer.apply_chat_template documentation or model card
                inputs = tokenizer.apply_chat_template(
                    prompt_dict_list,
                    add_generation_prompt=True,
                    return_tensors="pt"
                ) # .to(DEVICE) is not needed with device_map

                # device_map places tensors automatically, but check if inputs ended up on CPU
                if inputs.device.type == 'cpu' and torch.cuda.is_available():
                     # If inputs are on CPU but model parts are on GPU, move inputs to GPU
                     # This can happen depending on how accelerate splits the model
                     inputs = inputs.to("cuda")


                # Generate with recommended parameters for Phi-3 if available, otherwise use generic ones
                with torch.no_grad():
                    output_sequences = model.generate(
                        input_ids=inputs,
                        # attention_mask=attention_mask, # generate usually handles mask creation from input_ids if pad_token_id is set
                        max_new_tokens=150, # Allow longer responses for better models
                        num_return_sequences=1,
                        pad_token_id=tokenizer.pad_token_id, # Ensure pad token is used
                        eos_token_id=tokenizer.eos_token_id, # Ensure EOS token is used
                        do_sample=True,
                        temperature=0.7,
                        top_p=0.9,
                        repetition_penalty=1.1 # Phi-3 might need less penalty than gpt2
                    )

                # Decode response, excluding the input tokens
                response_ids = output_sequences[0][inputs.shape[-1]:]
                # Handle potential leading special tokens if skip_special_tokens=False is needed
                generated_text = tokenizer.decode(response_ids, skip_special_tokens=True)
                generated_text = generated_text.strip()

                # Cleanup specific to Phi-3 might be needed if it adds artifacts
                # Example: remove potential instruction remnants if any appear
                # generated_text = generated_text.split("<|end|>")[0] # Example if EOS token string appears

                if not generated_text:
                     generated_text = "I'm not sure how to respond to that."

                print(f"AI: {generated_text}")
                conversation_history.append({"role": "assistant", "content": generated_text})
                last_interaction_time = current_time
                ai_was_last_speaker = True

            except Exception as e:
                print(f"\nError during generation: {e}")
                # Add specific error handling if needed (e.g., for OOM during generation)
                conversation_history.append({"role": "assistant", "content": "[Error generating response]"})
                last_interaction_time = current_time
                ai_was_last_speaker = True

        # --- Handle Proactive AI Turn ---
        elif ai_was_last_speaker and (current_time - last_interaction_time > PROACTIVE_DELAY_SECONDS):
            proactive_message = random.choice(PROACTIVE_MESSAGES)
            print(f"AI (proactive): {proactive_message}")
            conversation_history.append({"role": "assistant", "content": proactive_message})
            last_interaction_time = current_time
            # ai_was_last_speaker remains True

    print("Exiting program.")
    # Ensure thread stops if loop exits unexpectedly
    program_running = False


# --- Run the chat ---
if __name__ == "__main__":
    chat()