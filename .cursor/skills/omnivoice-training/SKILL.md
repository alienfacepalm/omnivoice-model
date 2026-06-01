---
name: omnivoice-training
description: >-
  Prepares data, tokenizes audio, and trains or fine-tunes OmniVoice with
  accelerate. Use when working with JSONL manifests, WebDataset shards, train
  configs, run_emilia/finetune/eval scripts, or omnivoice.cli.train.
---

# OmniVoice Training

## Pipeline overview

```
JSONL manifest → audio tokenization → WebDataset shards → accelerate train → checkpoints
```

Example shell scripts in `examples/`:

| Script | Purpose |
|--------|---------|
| `run_emilia.sh` | Train from scratch on Emilia |
| `run_finetune.sh` | Fine-tune from `k2-fsa/OmniVoice` |
| `run_eval.sh` | WER, speaker similarity, UTMOS |

## JSONL format (fine-tune / inference batch)

```json
{"id": "001", "audio_path": "/path/001.wav", "text": "Hello", "language_id": "en"}
```

Mandatory: `id`, `audio_path` (training) or `text` (inference batch), `text`.

## Launch training

```bash
accelerate launch \
  --gpu_ids "0,1" \
  --num_processes 2 \
  -m omnivoice.cli.train \
  --train_config examples/config/train_config_finetune.json \
  --data_config examples/config/data_config_finetune.json \
  --output_dir exp/omnivoice_finetune
```

## Config files

- **Train config** — LR, steps, `attn_implementation`, `init_from_checkpoint`
- **Data config** — shard paths, sampling weights

Located in `examples/config/`. Key finetune vs scratch differences:

| Field | Scratch (Emilia) | Fine-tune |
|-------|------------------|-----------|
| `init_from_checkpoint` | `null` | `"k2-fsa/OmniVoice"` |
| `steps` | 300000 | 5000 |
| `learning_rate` | 1e-4 | 5e-5 |

## Attention backend

| Value | When to use |
|-------|-------------|
| `flex_attention` | Ampere+ GPU, PyTorch ≥ 2.5 (default) |
| `sdpa` | Broader hardware; use `train_config_finetune_sdpa.json` |

SDPA adds `max_sample_tokens`, `min_sample_tokens`, `max_batch_size` limits.

## Data prep scripts

| Script | Role |
|--------|------|
| `omnivoice/scripts/extract_audio_tokens.py` | Tokenize audio to shards |
| `omnivoice/scripts/jsonl_to_webdataset.py` | JSONL → WebDataset |

See [docs/data_preparation.md](../../docs/data_preparation.md).

## Evaluation

```bash
pip install -e ".[eval]"
bash examples/run_eval.sh
```

Test sets: `librispeech_pc`, `seedtts_en`, `seedtts_zh`, `fleurs`, `minimax`.

## Resume training

Set `resume_from_checkpoint` in train config to checkpoint path.

Monitor with TensorBoard logs under `output_dir`.

## Reference

- [docs/training.md](../../docs/training.md)
- [docs/evaluation.md](../../docs/evaluation.md)
- [examples/README.md](../../examples/README.md)
- Trainer: `omnivoice/training/trainer.py`
