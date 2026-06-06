#!/usr/bin/env bash
# Setup OmniVoice local environment (venv + PyTorch + editable install).
# Usage: ./scripts/setup-env.sh [--cuda cu128|cu126|cpu] [--force]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_PATH="${REPO_ROOT}/.venv"
PYTHON="${VENV_PATH}/bin/python"
PIP="${VENV_PATH}/bin/pip"

CUDA_INDEX=""
FORCE=0

usage() {
    cat <<'EOF'
Usage: ./scripts/setup-env.sh [--cuda cu128|cu126|cpu] [--force]

  --cuda   PyTorch wheel index (default: auto-detect GPU)
  --force  Reinstall PyTorch even if already present
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --cuda)
            CUDA_INDEX="$2"
            shift 2
            ;;
        --force)
            FORCE=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            exit 1
            ;;
    esac
done

has_nvidia_gpu() {
    command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1
}

echo "==> OmniVoice setup"
echo "    Repo: ${REPO_ROOT}"

if [[ ! -x "${PYTHON}" ]]; then
    echo "==> Creating virtual environment at ${VENV_PATH}"
    python3 -m venv "${VENV_PATH}"
fi

"${PYTHON}" -m pip install --upgrade pip wheel setuptools

if [[ -z "${CUDA_INDEX}" ]]; then
    if has_nvidia_gpu; then
        CUDA_INDEX="cu128"
        echo "==> NVIDIA GPU detected; using CUDA ${CUDA_INDEX} wheels"
    else
        CUDA_INDEX="cpu"
        echo "==> No NVIDIA GPU detected; installing CPU PyTorch"
    fi
fi

TORCH_ARGS=()
case "${CUDA_INDEX}" in
    cu128)
        TORCH_ARGS=(
            torch==2.8.0+cu128
            torchaudio==2.8.0+cu128
            torchvision==0.23.0+cu128
            --extra-index-url
            https://download.pytorch.org/whl/cu128
        )
        ;;
    cu126)
        TORCH_ARGS=(
            torch==2.8.0+cu126
            torchaudio==2.8.0+cu126
            torchvision==0.23.0+cu126
            --extra-index-url
            https://download.pytorch.org/whl/cu126
        )
        ;;
    cpu)
        TORCH_ARGS=(
            torch==2.8.0
            torchaudio==2.8.0
            torchvision==0.23.0
        )
        ;;
    *)
        echo "Unsupported --cuda value: ${CUDA_INDEX}" >&2
        exit 1
        ;;
esac

if [[ "${FORCE}" -eq 1 ]]; then
    echo "==> Reinstalling PyTorch (${CUDA_INDEX})"
    "${PIP}" install "${TORCH_ARGS[@]}" --force-reinstall
else
    echo "==> Installing PyTorch (${CUDA_INDEX})"
    "${PIP}" install "${TORCH_ARGS[@]}"
fi

echo "==> Installing OmniVoice (editable)"
"${PIP}" install -e "${REPO_ROOT}"

echo "==> Installing bundled ffmpeg for MP3 support"
"${PIP}" install imageio-ffmpeg

echo "==> Verifying installation"
"${PYTHON}" -c "
import torch, torchvision, omnivoice
print('torch', torch.__version__)
print('torchvision', torchvision.__version__)
print('omnivoice', omnivoice.__version__)
print('cuda', torch.cuda.is_available())
"

FFMPEG_CHECK=$("${PYTHON}" -c "
import sys
sys.path.insert(0, '${REPO_ROOT}/scripts')
from ffmpeg_env import configure_ffmpeg
print(configure_ffmpeg() or 'NOT FOUND')
")
echo "ffmpeg ${FFMPEG_CHECK}"

if ! command -v ffmpeg >/dev/null 2>&1; then
    echo ""
    echo "System ffmpeg not on PATH; using bundled imageio-ffmpeg."
fi

echo ""
echo "Setup complete. Run the demo with:"
echo "  ./scripts/run-demo.sh"
