#!/usr/bin/env python3
"""Check that the app ships the offline recordings its audio engine requires."""
from pathlib import Path
import sys
import wave

root = Path(sys.argv[1]) / "Sounds"
for name in ("puppy", "chicken", "pig", "cow", "frog"):
    with wave.open(str(root / f"{name}.wav")) as sound:
        assert sound.getnchannels() == 1, name
        assert sound.getframerate() == 44100, name
        assert sound.getsampwidth() == 2, name
        assert 0 < sound.getnframes() <= 44100 * 3, name
assert "CC BY-SA 3.0" in (root / "CREDITS.txt").read_text()
print("All five offline animal recordings and their credits are bundled.")
