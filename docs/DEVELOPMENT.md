# Development Guide

Guide for local development, environment setup, and contributing to OmniVoice.

## Prerequisites

- Python **3.10+**
- NVIDIA GPU recommended for inference/training (CUDA 12.x wheels)
- Git

## Environment setup

Use an isolated virtual environment to avoid conflicts with other ML stacks (e.g. vLLM pins older PyTorch).

### Option A: pip (recommended on Windows)

**Step 1 — PyTorch** (match CUDA to your driver; cu128 example):

```bash
pip install torch==2.8.0+cu128 torchaudio==2.8.0+cu128 torchvision==0.23.0+cu128 \
  --extra-index-url https://download.pytorch.org/whl/cu128
```

> **Important:** Install `torchvision` alongside `torch` at the same version family. Mismatched torchvision (e.g. 0.20.x with torch 2.8) causes import errors via `transformers`.

**Step 2 — OmniVoice (editable)**

```bash
git clone https://github.com/k2-fsa/OmniVoice.git
cd OmniVoice
pip install -e .
```

**Optional — evaluation extras:**

```bash
pip install -e ".[eval]"
```

### Option B: uv

```bash
git clone https://github.com/k2-fsa/OmniVoice.git
cd OmniVoice
uv sync
```

PyTorch CUDA wheels are configured in `pyproject.toml` under `[tool.uv]`.

## Verify installation

```bash
python -c "import torch, torchvision, omnivoice; print(torch.__version__, torchvision.__version__, omnivoice.__version__)"
python -c "import torch; print('cuda:', torch.cuda.is_available())"
```

## Device selection

| Platform | `device_map` in API | Notes |
|----------|---------------------|-------|
| NVIDIA CUDA | `"cuda:0"` | Default for GPU inference |
| Apple Silicon | `"mps"` | CPU fallback if MPS unavailable |
| Intel Arc (XPU) | `"xpu"` | No `flash_attn`; uses SDPA |

CLI tools auto-detect via `omnivoice.utils.common.get_best_device()`.

## Project layout

```
omnivoice/
├── models/          # OmniVoice model & generation logic
├── cli/             # omnivoice-demo, omnivoice-infer, train entry points
├── training/        # Trainer, configs, checkpoints
├── data/            # Dataset, collator, batching
├── scripts/         # Audio tokenization, WebDataset conversion
├── eval/            # WER, speaker similarity, UTMOS
└── utils/           # Audio, text, duration, voice design helpers

examples/
├── config/          # JSON train/data configs
├── run_emilia.sh    # Train from scratch pipeline
├── run_finetune.sh  # Fine-tune pipeline
└── run_eval.sh      # Evaluation pipeline

docs/                # User & developer documentation
```

## Running locally

```bash
# Gradio demo
omnivoice-demo --ip 127.0.0.1 --port 8001

# Quick inference test
omnivoice-infer \
  --model k2-fsa/OmniVoice \
  --text "Hello, development test." \
  --output /tmp/test.wav
```

First run downloads weights from Hugging Face (~several GB).

## Development workflow

1. Create a branch from `master`.
2. Install editable: `pip install -e .`
3. Make focused changes; follow patterns in `.cursor/rules/`.
4. Smoke-test inference after model/API changes.
5. For training changes, use a small JSONL subset and `train_config_finetune_sdpa.json` if `flex_attention` is unavailable.

## Training data paths

Training scripts expect data outside the repo (gitignored):

- `data/` — JSONL manifests and tokenized shards
- `download/` — raw datasets (e.g. Emilia)
- `exp/` — checkpoints and logs

See [data_preparation.md](data_preparation.md) and [examples/README.md](../examples/README.md).

## Common issues

| Issue | Fix |
|-------|-----|
| `torchvision::nms does not exist` | Reinstall matching `torchvision` for your `torch` version |
| Hugging Face timeout | `export HF_ENDPOINT=https://hf-mirror.com` |
| OOM during inference | Use `dtype=torch.float16`, shorter text, or `num_step=16` |
| `flex_attention` not supported | Use `train_config_finetune_sdpa.json` (`attn_implementation: sdpa`) |
| vLLM / other packages conflict | Use a dedicated venv for OmniVoice |

## Packaging

- Build backend: Hatchling (`pyproject.toml`)
- Version: `[project].version`
- CLI scripts: `[project.scripts]`

Release flow is maintained upstream; bump version in `pyproject.toml` only when preparing a release.

## Links

- [README](../README.md) — user-facing install & API
- [AGENTS.md](../AGENTS.md) — AI agent orientation
- [GitHub Issues](https://github.com/k2-fsa/OmniVoice/issues)
