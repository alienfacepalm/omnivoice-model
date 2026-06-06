#!/usr/bin/env python3
# Copyright    2026  Xiaomi Corp.        (authors:  Han Zhu)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Launch omnivoice-demo in a child process with full teardown on SIGINT/SIGTERM."""

from __future__ import annotations

import argparse
import gc
import os
import shutil
import signal
import subprocess
import sys
import time
from pathlib import Path
from typing import Optional

_SCRIPTS_DIR = Path(__file__).resolve().parent
if str(_SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPTS_DIR))

from ffmpeg_env import configure_ffmpeg  # noqa: E402

_proc: Optional[subprocess.Popen] = None
_shutdown_requested = False
_gradio_temp_dir: Optional[Path] = None


def _repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def _kill_process_tree(pid: int) -> None:
    if sys.platform == "win32":
        subprocess.run(
            ["taskkill", "/F", "/T", "/PID", str(pid)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        return

    try:
        pgid = os.getpgid(pid)
    except ProcessLookupError:
        return

    for sig in (signal.SIGTERM, signal.SIGKILL):
        try:
            os.killpg(pgid, sig)
        except ProcessLookupError:
            break
        if sig == signal.SIGTERM:
            time.sleep(1.0)


def _release_gpu_memory() -> None:
    try:
        import torch

        if torch.cuda.is_available():
            torch.cuda.empty_cache()
            torch.cuda.synchronize()
    except Exception:
        pass
    gc.collect()


def _cleanup_gradio_temp() -> None:
    if _gradio_temp_dir is None or not _gradio_temp_dir.exists():
        return
    try:
        shutil.rmtree(_gradio_temp_dir, ignore_errors=True)
    except OSError:
        pass


def _shutdown(force: bool = False) -> None:
    global _shutdown_requested

    if _proc is not None and _proc.poll() is None:
        print("[demo_runner] Stopping omnivoice-demo...", flush=True)
        _kill_process_tree(_proc.pid)
        try:
            _proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            if force:
                _kill_process_tree(_proc.pid)

    _release_gpu_memory()
    _cleanup_gradio_temp()
    print("[demo_runner] Teardown complete.", flush=True)


def _handle_signal(signum: int, _frame) -> None:
    global _shutdown_requested

    if _shutdown_requested:
        print("\n[demo_runner] Force exit.", flush=True)
        _shutdown(force=True)
        raise SystemExit(128 + signum)

    _shutdown_requested = True
    print(
        f"\n[demo_runner] Received signal {signum}; shutting down "
        "(press Ctrl+C again to force)...",
        flush=True,
    )
    _shutdown(force=False)
    raise SystemExit(128 + signum)


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Run omnivoice-demo with clean SIGINT/SIGTERM teardown.",
    )
    parser.add_argument(
        "--gradio-temp",
        default=None,
        help="Directory for Gradio uploads/temp files (removed on exit).",
    )
    parser.add_argument(
        "demo_args",
        nargs=argparse.REMAINDER,
        help="Arguments forwarded to omnivoice-demo (prefix with --).",
    )
    return parser


def main(argv: Optional[list[str]] = None) -> int:
    global _proc, _gradio_temp_dir

    args = _build_parser().parse_args(argv)
    demo_argv = list(args.demo_args)
    if demo_argv and demo_argv[0] == "--":
        demo_argv = demo_argv[1:]

    gradio_temp = Path(args.gradio_temp) if args.gradio_temp else _repo_root() / ".cache" / "gradio-temp"
    gradio_temp.mkdir(parents=True, exist_ok=True)
    _gradio_temp_dir = gradio_temp
    os.environ["GRADIO_TEMP_DIR"] = str(gradio_temp)

    ffmpeg_exe = configure_ffmpeg()
    if ffmpeg_exe:
        print(f"[demo_runner] ffmpeg={ffmpeg_exe}", flush=True)
    else:
        print(
            "[demo_runner] WARNING: ffmpeg not found; MP3 uploads may fail. "
            "Re-run .\\scripts\\setup-env.ps1",
            flush=True,
        )

    signal.signal(signal.SIGINT, _handle_signal)
    signal.signal(signal.SIGTERM, _handle_signal)

    cmd = [sys.executable, "-m", "omnivoice.cli.demo", *demo_argv]
    print(f"[demo_runner] Starting: {' '.join(cmd)}", flush=True)
    print(f"[demo_runner] GRADIO_TEMP_DIR={gradio_temp}", flush=True)

    popen_kwargs: dict = {"env": os.environ.copy()}
    if sys.platform == "win32":
        popen_kwargs["creationflags"] = subprocess.CREATE_NEW_PROCESS_GROUP
    else:
        popen_kwargs["preexec_fn"] = os.setsid

    _proc = subprocess.Popen(cmd, **popen_kwargs)

    try:
        return _proc.wait()
    except KeyboardInterrupt:
        _handle_signal(signal.SIGINT, None)
        return 130
    finally:
        if not _shutdown_requested:
            _shutdown(force=False)


if __name__ == "__main__":
    raise SystemExit(main())
