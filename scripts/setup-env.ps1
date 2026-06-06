# Setup OmniVoice local environment (venv + PyTorch + editable install).
# Usage: .\scripts\setup-env.ps1 [-CudaIndex cu128] [-Force]

[CmdletBinding()]
param(
    [ValidateSet("", "cu128", "cu126", "cpu")]
    [string]$CudaIndex = "",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$VenvPath = Join-Path $RepoRoot ".venv"
$Python = Join-Path $VenvPath "Scripts\python.exe"
$Pip = Join-Path $VenvPath "Scripts\pip.exe"

function Test-NvidiaGpu {
    try {
        $null = Get-Command nvidia-smi -ErrorAction Stop
        & nvidia-smi 1>$null 2>$null
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

function Test-Ffmpeg {
    try {
        $null = Get-Command ffmpeg -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

Write-Host "==> OmniVoice setup" -ForegroundColor Cyan
Write-Host "    Repo: $RepoRoot"

if (-not (Test-Path $Python)) {
    Write-Host "==> Creating virtual environment at $VenvPath"
    & python -m venv $VenvPath
}

& $Python -m pip install --upgrade pip wheel setuptools

if (-not $CudaIndex) {
    if (Test-NvidiaGpu) {
        $CudaIndex = "cu128"
        Write-Host "==> NVIDIA GPU detected; using CUDA $CudaIndex wheels"
    } else {
        $CudaIndex = "cpu"
        Write-Host "==> No NVIDIA GPU detected; installing CPU PyTorch"
    }
}

$TorchArgs = @()
switch ($CudaIndex) {
    "cu128" {
        $TorchArgs = @(
            "torch==2.8.0+cu128",
            "torchaudio==2.8.0+cu128",
            "torchvision==0.23.0+cu128",
            "--extra-index-url", "https://download.pytorch.org/whl/cu128"
        )
    }
    "cu126" {
        $TorchArgs = @(
            "torch==2.8.0+cu126",
            "torchaudio==2.8.0+cu126",
            "torchvision==0.23.0+cu126",
            "--extra-index-url", "https://download.pytorch.org/whl/cu126"
        )
    }
    "cpu" {
        $TorchArgs = @(
            "torch==2.8.0",
            "torchaudio==2.8.0",
            "torchvision==0.23.0"
        )
    }
}

if ($Force) {
    Write-Host "==> Reinstalling PyTorch ($CudaIndex)"
    & $Pip install @TorchArgs --force-reinstall
} else {
    Write-Host "==> Installing PyTorch ($CudaIndex)"
    & $Pip install @TorchArgs
}

Write-Host "==> Installing OmniVoice (editable)"
& $Pip install -e $RepoRoot

Write-Host "==> Installing bundled ffmpeg for MP3 support"
& $Pip install imageio-ffmpeg

Write-Host "==> Verifying installation"
& $Python -c @"
import torch, torchvision, omnivoice
print('torch', torch.__version__)
print('torchvision', torchvision.__version__)
print('omnivoice', omnivoice.__version__)
print('cuda', torch.cuda.is_available())
"@

& $Python -c @"
import sys
sys.path.insert(0, r'$RepoRoot\scripts')
from ffmpeg_env import configure_ffmpeg
exe = configure_ffmpeg()
print('ffmpeg', exe or 'NOT FOUND')
"@

if (-not (Test-Ffmpeg)) {
    Write-Host ""
    Write-Host "System ffmpeg not on PATH; using bundled imageio-ffmpeg." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Setup complete. Run the demo with:" -ForegroundColor Green
Write-Host "  .\scripts\run-demo.ps1"
