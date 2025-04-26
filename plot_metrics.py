import json
import argparse
import os

import pandas as pd
import matplotlib.pyplot as plt


def load_metrics(log_path):
    """Load JSONL metrics into a pandas DataFrame."""
    records = []
    with open(log_path, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                rec = json.loads(line)
                records.append(rec)
            except json.JSONDecodeError:
                continue
    return pd.DataFrame(records)


def plot_metric(df, x, y, ax, label=None):
    ax.plot(df[x], df[y], marker='o', label=label or y)
    ax.set_xlabel(x)
    ax.set_ylabel(y)
    ax.grid(True)


def main():
    parser = argparse.ArgumentParser(description="Plot PPO training metrics from JSONL logs.")
    parser.add_argument("--log-file", type=str, default="logs_500_v2/metrics.jsonl", help="Path to metrics.jsonl file")
    parser.add_argument("--output-dir", type=str, default="logs_500_v2/plots", help="Directory to save plots")
    args = parser.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)
    df = load_metrics(args.log_file)

    # Ensure sorted by episode or epoch
    df = df.sort_values(by=['episode', 'epoch'])

    # Rename some columns to simpler names
    df.rename(columns={
        'objective/rlhf_reward': 'rlhf_reward',
        'objective/kl': 'kl',
        'objective/entropy': 'entropy',
        'loss/policy_avg': 'policy_loss',
        'loss/value_avg': 'value_loss'
    }, inplace=True)

    # Map display names to DataFrame columns
    plots = [
        ('RLHF Reward', 'rlhf_reward'),
        ('Yap Score', 'yap_score'),
        ('Raw Reward', 'raw_reward'),
        ('KL Divergence', 'kl'),
        ('Entropy', 'entropy'),
        ('Policy Loss', 'policy_loss'),
        ('Value Loss', 'value_loss'),
    ]

    # Create subplots
    n = len(plots)
    fig, axes = plt.subplots(n, 1, figsize=(8, 3*n), sharex=True)

    for ax, (label, col) in zip(axes, plots):
        if col not in df.columns:
            print(f"Warning: column '{col}' not found; skipping {label}")
            continue
        plot_metric(df, 'episode', col, ax, label=label)
        ax.legend()

    plt.tight_layout()
    out_path = os.path.join(args.output_dir, "ppo_metrics.png")
    fig.savefig(out_path)
    print(f"Saved plots to {out_path}")


if __name__ == '__main__':
    main() 