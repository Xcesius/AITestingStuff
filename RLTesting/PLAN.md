# PLAN.md

This document outlines the step-by-step plan to refactor `ppo_yapperv1.py` into a clean, modular, CLI-driven tool.

## 1. Add CLI Argument Parsing
- Use `argparse` to expose key parameters:
  - `--model-name` (default: `gpt2`)
  - `--batch-size`, `--mini-batch-size`, `--episodes`
  - `--output-dir` for saving models and tokenizer
  - `--device` (cpu/cuda)
  - (optional) `--log-dir` for TensorBoard or W&B

## 2. Wrap Script Logic in `main(args)`
- Create a `main(args)` function that contains:
  1. **Environment setup** (device, seed)
  2. **Tokenizer initialization**
  3. **Model loading** (policy, value, reference)
  4. **Dataset loading & tokenization**
  5. **Reward function & reward model init**
  6. **PPOConfig & PPOTrainer instantiation**
  7. **trainer.train()** call
  8. **Saving models & tokenizer**

## 3. Update `if __name__ == "__main__"` Block
- Call `parse_args()` to get CLI args
- Invoke `main(args)`
- Handle exceptions or interrupts gracefully

## 4. Integrate Logging (optional)
- Add hooks for:
  - TensorBoard (`SummaryWriter`)
  - Weights & Biases (`wandb.init`) 
- Log key metrics: reward, KL, loss, learning rate

## 5. Test and Validate
- Run small smoke test with 1–2 episodes
- Verify that CLI flags are respected
- Confirm models & tokenizer are saved to `--output-dir`

## 6. Iterate and Extend
- Add additional flags: different reward functions, datasets
- Refactor reward functions into separate modules
- Add unit tests for helper functions
- (Future) Build simple UI wrapper for interactive chat 