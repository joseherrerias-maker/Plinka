#!/usr/bin/env python3
"""Check that the app ships the offline recordings its audio engine requires."""
from pathlib import Path
import sys
import wave
import array
import hashlib
import json

root = Path(sys.argv[1]) / "Sounds"
for name in ("puppy", "chicken", "pig", "cow", "frog"):
    with wave.open(str(root / f"{name}.wav")) as sound:
        assert sound.getnchannels() == 1, name
        assert sound.getframerate() == 44100, name
        assert sound.getsampwidth() == 2, name
        assert 0 < sound.getnframes() <= 44100 * 3, name
        samples = array.array("h", sound.readframes(sound.getnframes()))
        assert max(abs(v) for v in samples) > 1000, f"Silent recording: {name}"
        assert max(abs(v) for v in samples) < 32767, f"Clipped recording: {name}"
credits = (root / "CREDITS.txt").read_text()
assert "CC BY-SA" not in credits and "CC BY 3.0" not in credits
for source in json.loads((Path(__file__).resolve().parents[1] / "SOUND-SOURCES-16.json").read_text()):
    assert source["license"] == "CC0-1.0"
    assert source["source_url"] in credits
    data = (root / (source["instrument"] + ".wav")).read_bytes()
    assert hashlib.sha256(data).hexdigest() == source["bundled_sha256"], source["instrument"]
assert credits.count("CC0 1.0.") >= 5
print("All five offline animal recordings and their credits are bundled.")
