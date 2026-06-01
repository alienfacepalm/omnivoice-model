---
name: omnivoice-inference
description: >-
  Runs OmniVoice TTS inference via Python API or CLI for voice cloning, voice
  design, and auto voice. Use when synthesizing speech, configuring generation
  parameters, running omnivoice-demo/infer/infer-batch, or debugging audio output.
---

# OmniVoice Inference

## Three generation modes

| Mode | Inputs | Stability |
|------|--------|-----------|
| Voice cloning | `ref_audio`, optional `ref_text` | Best |
| Voice design | `instruct` (comma-separated attributes) | EN/ZH trained |
| Auto voice | `text` only | Random voice |

Do not combine conflicting `ref_audio` and `instruct` — reference audio wins on conflict.

## Python API

```python
import torch
import soundfile as sf
from omnivoice import OmniVoice

model = OmniVoice.from_pretrained(
    "k2-fsa/OmniVoice",
    device_map="cuda:0",  # mps | xpu | cpu
    dtype=torch.float16,
)

# Voice cloning (3–10 s ref clip, same language preferred)
audio = model.generate(
    text="Hello, zero-shot voice cloning.",
    ref_audio="ref.wav",
    ref_text="Reference transcript.",  # omit for Whisper auto-transcribe
)

# Voice design
audio = model.generate(
    text="Hello, voice design test.",
    instruct="female, low pitch, british accent",
)

sf.write("out.wav", audio[0], 24000)  # 24 kHz mono
```

## CLI

```bash
# Demo UI
omnivoice-demo --ip 0.0.0.0 --port 8001

# Single file
omnivoice-infer --model k2-fsa/OmniVoice \
  --text "Hello world" --ref_audio ref.wav --output out.wav

# Batch (JSONL: id + text required)
omnivoice-infer-batch --model k2-fsa/OmniVoice \
  --test_list test.jsonl --res_dir results/
```

Run `--help` on any CLI for full flags.

## Key generation parameters

| Param | Default | Notes |
|-------|---------|-------|
| `num_step` | 32 | Use 16 for faster inference |
| `guidance_scale` | 2.0 | CFG scale |
| `duration` | None | Fixed seconds; overrides `speed` |
| `speed` | 1.0 | >1 faster, <1 slower |
| `postprocess_output` | True | Set False if exact `duration` needed |

Pass via kwargs or `OmniVoiceGenerationConfig`.

## Text controls

- Non-verbal tags: `[laughter]`, `[sigh]`, etc.
- Chinese pinyin: `打ZHE2`, `SHE2`
- English CMU phonemes: `[B EY1 S]`, `[B AE1 S]`

## Tips

- Normalize Arabic numerals to words for better pronunciation.
- Short clips (1–2 s) without ref audio may be unreliable — provide `ref_audio`.
- Min Nan (Hokkien): Tai-lo romanization only, not Chinese characters.

## Reference

- [docs/generation-parameters.md](../../docs/generation-parameters.md)
- [docs/voice-design.md](../../docs/voice-design.md)
- [docs/tips.md](../../docs/tips.md)
- CLI source: `omnivoice/cli/infer.py`, `infer_batch.py`, `demo.py`
