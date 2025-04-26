from ppo_yapperv1 import Yapper

if __name__ == '__main__':
    # Initialize Yapper with the new base model
    model_path = 'openai-community/gpt2-medium'
    y = Yapper(model_path)

    # Choose a prompt and generation constraints
    prompt = "Hey, what's on your mind today?"
    response = y.chat(prompt, max_length=8000, min_length=600)

    # Output the result and word count
    print("Prompt:", prompt)
    print("Generated response:\n", response)
    print("Word count:", len(response.split())) 