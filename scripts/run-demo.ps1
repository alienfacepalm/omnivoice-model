# Run the OmniVoice Gradio demo with setup and SIGINT teardown.
#
# Usage:
#   .\scripts\run-demo.ps1
#   .\scripts\run-demo.ps1 -Port 8001 -Share
#   .\scripts\run-demo.ps1 -SkipSetup
#
# Ctrl+C stops the demo, kills child processes, frees GPU memory, and
# removes Gradio temp uploads under .cache/gradio-temp.

[CmdletBinding()]
param(
    [string]$Ip = "127.0.0.1",
    [int]$Port = 8001,
    [string]$Model = "k2-fsa/OmniVoice",
    [switch]$Share,
    [switch]$NoAsr,
    [switch]$SkipSetup,
    [string]$HfEndpoint = ""
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$VenvPython = Join-Path $RepoRoot ".venv\Scripts\python.exe"
$Runner = Join-Path $RepoRoot "scripts\demo_runner.py"
$GradioTemp = Join-Path $RepoRoot ".cache\gradio-temp"
$CacheRoot = Join-Path $RepoRoot ".cache"

if (-not $SkipSetup -and -not (Test-Path $VenvPython)) {
    Write-Host "Virtual environment not found; running setup first..."
    & (Join-Path $RepoRoot "scripts\setup-env.ps1")
}

if (-not (Test-Path $VenvPython)) {
    throw "Python not found at $VenvPython. Run .\scripts\setup-env.ps1 first."
}

New-Item -ItemType Directory -Force -Path $CacheRoot | Out-Null
New-Item -ItemType Directory -Force -Path $GradioTemp | Out-Null

if ($HfEndpoint) {
    $env:HF_ENDPOINT = $HfEndpoint
}

$ScriptsDir = Join-Path $RepoRoot "scripts"
$env:PYTHONPATH = if ($env:PYTHONPATH) { "$ScriptsDir;$env:PYTHONPATH" } else { $ScriptsDir }

$DemoArgs = @(
    "--gradio-temp", $GradioTemp,
    "--",
    "--model", $Model,
    "--ip", $Ip,
    "--port", "$Port"
)

if ($Share) {
    $DemoArgs += "--share"
}
if ($NoAsr) {
    $DemoArgs += "--no-asr"
}

Write-Host ""
Write-Host "OmniVoice demo" -ForegroundColor Cyan
Write-Host "  URL:   http://${Ip}:${Port}/"
Write-Host "  Model: $Model"
Write-Host "  Temp:  $GradioTemp"
Write-Host ""
Write-Host "Press Ctrl+C to stop and tear down." -ForegroundColor Yellow
Write-Host ""

try {
    & $VenvPython $Runner @DemoArgs
    exit $LASTEXITCODE
} catch {
    if ($_.Exception -is [System.Management.Automation.PipelineStoppedException]) {
        exit 130
    }
    throw
}
