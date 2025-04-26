from ppo_yapperv1 import Yapper


def main():
    # Load the fine-tuned model
    model_path = "quick_test"
    y = Yapper(model_path)
    # Generate a response with up to 500 new tokens
    text = y.chat("Hey, what's on your mind today?", max_length=500)
    print("Generated text:\n", text)
    print("Word count:", len(text.split()))


if __name__ == '__main__':
    main() 