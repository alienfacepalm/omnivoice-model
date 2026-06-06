#!/usr/bin/env bash
# Run the OmniVoice Gradio demo with setup and SIGINT teardown.
#
# Usage:
#   ./scripts/run-demo.sh
#   ./scripts/run-demo.sh --port 8001 --share
#   ./scripts/run-demo.sh --skip-setup
#
# Ctrl+C stops the demo, kills child processes, frees GPU memory, and
# removes Gradio temp uploads under .cache/gradio-temp.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_PYTHON="${REPO_ROOT}/.venv/bin/python"
RUNNER="${REPO_ROOT}/scripts/demo_runner.py"
GRADIO_TEMP="${REPO_ROOT}/.cache/gradio-temp"

IP="127.0.0.1"
PORT="8001"
MODEL="k2-fsa/OmniVoice"
SHARE=0
NO_ASR=0
SKIP_SETUP=0
HF_ENDPOINT=""

usage() {
    cat <<'EOF'
Usage: ./scripts/run-demo.sh [options]

Options:
  --ip IP           Bind address (default: 127.0.0.1)
  --port PORT       Server port (default: 8001)
  --model MODEL     HuggingFace id or local checkpoint path
  --share           Create a public Gradio link
  --no-asr          Skip loading Whisper for ref-text auto-transcription
  --skip-setup      Do not auto-run setup-env.sh when .venv is missing
  --hf-endpoint URL Set HF_ENDPOINT (e.g. https://hf-mirror.com)
  -h, --help        Show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --ip)
            IP="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --model)
            MODEL="$2"
            shift 2
            ;;
        --share)
            SHARE=1
            shift
            ;;
        --no-asr)
            NO_ASR=1
            shift
            ;;
        --skip-setup)
            SKIP_SETUP=1
            shift
            ;;
        --hf-endpoint)
            HF_ENDPOINT="$2"
            shift 2
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

if [[ "${SKIP_SETUP}" -eq 0 && ! -x "${VENV_PYTHON}" ]]; then
    echo "Virtual environment not found; running setup first..."
    "${REPO_ROOT}/scripts/setup-env.sh"
fi

if [[ ! -x "${VENV_PYTHON}" ]]; then
    echo "Python not found at ${VENV_PYTHON}. Run ./scripts/setup-env.sh first." >&2
    exit 1
fi

mkdir -p "${REPO_ROOT}/.cache" "${GRADIO_TEMP}"

export PYTHONPATH="${REPO_ROOT}/scripts${PYTHONPATH:+:${PYTHONPATH}}"

if [[ -n "${HF_ENDPOINT}" ]]; then
    export HF_ENDPOINT="${HF_ENDPOINT}"
fi

DEMO_ARGS=(
    --gradio-temp "${GRADIO_TEMP}"
    --
    --model "${MODEL}"
    --ip "${IP}"
    --port "${PORT}"
)

if [[ "${SHARE}" -eq 1 ]]; then
    DEMO_ARGS+=(--share)
fi
if [[ "${NO_ASR}" -eq 1 ]]; then
    DEMO_ARGS+=(--no-asr)
fi

echo ""
echo "OmniVoice demo"
echo "  URL:   http://${IP}:${PORT}/"
echo "  Model: ${MODEL}"
echo "  Temp:  ${GRADIO_TEMP}"
echo ""
echo "Press Ctrl+C to stop and tear down."
echo ""

exec "${VENV_PYTHON}" "${RUNNER}" "${DEMO_ARGS[@]}"
