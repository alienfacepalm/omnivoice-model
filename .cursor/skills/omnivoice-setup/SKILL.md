---
name: omnivoice-setup
description: >-
  Sets up OmniVoice development and runtime environments with correct PyTorch,
  CUDA, and dependency versions. Use when installing OmniVoice, fixing import
  errors, configuring GPU/CUDA/MPS/XPU, creating venvs, or running pip/uv sync.
---

# OmniVoice Setup

## Quick checklist

```
- [ ] Isolated venv (avoid vLLM/other torch pins)
- [ ] PyTorch + torchaudio + torchvision (same version family)
- [ ] omnivoice installed (pip or editable)
- [ ] CUDA/MPS/XPU verified
- [ ] HF access or mirror configured
```

## Install order

Always install PyTorch **before** OmniVoice.

### NVIDIA GPU (CUDA 12.8 example)

```bash
pip install torch==2.8.0+cu128 torchaudio==2.8.0+cu128 torchvision==0.23.0+cu128 \
  --extra-index-url https://download.pytorch.org/whl/cu128
```

### Apple Silicon

```bash
pip install torch==2.8.0 torchaudio==2.8.0 torchvision
```

### OmniVoice

```bash
# Stable
pip install omnivoice

# Latest GitHub
pip install git+https://github.com/k2-fsa/OmniVoice.git

# Development (from repo root)
pip install -e .
pip install -e ".[eval]"   # optional: WER, MOS eval
```

### uv (from cloned repo)

```bash
uv sync
uv sync --extra eval
```

## Verify

```bash
python -c "
import torch, torchvision, omnivoice
print('torch', torch.__version__)
print('torchvision', torchvision.__version__)
print('omnivoice', omnivoice.__version__)
print('cuda', torch.cuda.is_available())
"
```

## Hugging Face mirror

If model download fails:

```bash
# Linux/macOS
export HF_ENDPOINT=https://hf-mirror.com

# Windows PowerShell
$env:HF_ENDPOINT = "https://hf-mirror.com"
```

## Common fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `torchvision::nms does not exist` | torch/torchvision mismatch | Reinstall paired versions from PyTorch index |
| `Could not import HiggsAudioV2TokenizerModel` | Often torchvision issue | Same as above |
| torch downgraded unexpectedly | Old torchvision pulled torch 2.5 | Pin all three: torch, torchaudio, torchvision |
| Package conflicts (vLLM, etc.) | Shared global env | New dedicated venv |

## Reference

- Full dev guide: [docs/DEVELOPMENT.md](../../docs/DEVELOPMENT.md)
- Upstream README: [README.md](../../README.md)
