# OmniVoice — Agent Guide

This file orients AI coding agents working in [k2-fsa/OmniVoice](https://github.com/k2-fsa/OmniVoice).

## Project summary

OmniVoice is a multilingual zero-shot TTS model (600+ languages) built on a diffusion language model architecture. It supports **voice cloning**, **voice design**, and **auto voice** generation at 24 kHz.

| Area | Location |
|------|----------|
| Public API | `omnivoice/models/omnivoice.py` — `OmniVoice`, `OmniVoiceConfig`, `OmniVoiceGenerationConfig` |
| CLI entry points | `omnivoice/cli/` — `demo.py`, `infer.py`, `infer_batch.py` |
| Training | `omnivoice/cli/train.py`, `omnivoice/training/` |
| Data pipeline | `omnivoice/data/`, `omnivoice/scripts/` |
| Evaluation | `omnivoice/eval/` |
| Example configs & scripts | `examples/` |
| User docs | `docs/`, `README.md` |

## Before you change code

1. Read the relevant doc in `docs/` (see index below).
2. Match existing patterns in neighboring modules (Apache 2.0 header, argparse CLIs, JSON configs).
3. Prefer minimal diffs; do not refactor unrelated code.
4. Test inference changes with `omnivoice-infer` or a short Python snippet before training-scale changes.

## Documentation index

| Topic | Doc |
|-------|-----|
| Local setup & env | [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) |
| Inference tips | [docs/tips.md](docs/tips.md) |
| Generation params | [docs/generation-parameters.md](docs/generation-parameters.md) |
| Voice design attributes | [docs/voice-design.md](docs/voice-design.md) |
| Supported languages | [docs/languages.md](docs/languages.md) |
| Training | [docs/training.md](docs/training.md) |
| Data prep | [docs/data_preparation.md](docs/data_preparation.md) |
| Evaluation | [docs/evaluation.md](docs/evaluation.md) |
| Examples pipeline | [examples/README.md](examples/README.md) |

## Cursor skills & rules

Project-specific agent guidance lives in:

- **Skills** (`.cursor/skills/`) — workflows for setup, inference, and training
- **Rules** (`.cursor/rules/`) — coding conventions and config patterns

Use the setup skill before installing dependencies; use inference or training skills when implementing those workflows.

## Quick commands

```bash
# Editable dev install (after PyTorch)
pip install -e .

# Web demo
omnivoice-demo --ip 0.0.0.0 --port 8001

# Single inference
omnivoice-infer --model k2-fsa/OmniVoice --text "Hello" --output out.wav

# Training (multi-GPU)
accelerate launch -m omnivoice.cli.train \
  --train_config examples/config/train_config_finetune.json \
  --data_config examples/config/data_config_finetune.json \
  --output_dir exp/omnivoice_finetune
```

## Hugging Face

- Model: `k2-fsa/OmniVoice`
- Space: [k2-fsa/OmniVoice](https://huggingface.co/spaces/k2-fsa/OmniVoice)

If Hugging Face downloads fail, set `HF_ENDPOINT=https://hf-mirror.com` (mirror) before running.

## Ethics

Do not add features or examples that facilitate unauthorized voice cloning, impersonation, or fraud. See the disclaimer in `README.md`.
