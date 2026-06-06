"""Expose a bundled ffmpeg binary on PATH for MP3/M4A loading."""

from __future__ import annotations

import os
import shutil
import sys
from pathlib import Path
from typing import Optional


def bundled_ffmpeg_exe() -> Optional[str]:
    try:
        import imageio_ffmpeg
    except ImportError:
        return None

    try:
        return imageio_ffmpeg.get_ffmpeg_exe()
    except Exception:
        return None


def configure_ffmpeg() -> Optional[str]:
    """Put bundled ffmpeg on PATH when system ffmpeg is missing."""
    if shutil.which("ffmpeg"):
        return shutil.which("ffmpeg")

    ffmpeg_exe = bundled_ffmpeg_exe()
    if not ffmpeg_exe:
        return None

    ffmpeg_dir = str(Path(ffmpeg_exe).parent)
    path = os.environ.get("PATH", "")
    if ffmpeg_dir not in path.split(os.pathsep):
        os.environ["PATH"] = ffmpeg_dir + os.pathsep + path

    os.environ["FFMPEG_BINARY"] = ffmpeg_exe

    if sys.platform == "win32":
        os.environ.setdefault("AUDIOREAD_FFMPEG_PATH", ffmpeg_exe)

    try:
        from pydub import AudioSegment

        AudioSegment.converter = ffmpeg_exe
    except Exception:
        pass

    return ffmpeg_exe
