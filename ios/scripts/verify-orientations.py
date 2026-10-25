#!/usr/bin/env python3
"""Fail a build locally if Apple's required iPhone/iPad orientations are missing.

Usage:
  python3 ios/scripts/verify-orientations.py <path/to/Plinka.app/Info.plist>
  python3 ios/scripts/verify-orientations.py <path/to/Plinka.ipa>

Use this after compiling/packaging and BEFORE Codemagic publishing.
"""
import plistlib
import re
import sys
import zipfile
from pathlib import Path

IPHONE = {
    "UIInterfaceOrientationPortrait",
    "UIInterfaceOrientationLandscapeLeft",
    "UIInterfaceOrientationLandscapeRight",
}
IPAD = IPHONE | {"UIInterfaceOrientationPortraitUpsideDown"}


def load_info(path):
    if path.suffix.lower() == ".ipa":
        with zipfile.ZipFile(path) as archive:
            names = [
                name for name in archive.namelist()
                if name.startswith("Payload/")
                and name.count("/") == 2
                and name.endswith(".app/Info.plist")
            ]
            if len(names) != 1:
                raise ValueError(f"Expected one app Info.plist inside the IPA, found: {names}")
            return plistlib.loads(archive.read(names[0]))
    with path.open("rb") as handle:
        return plistlib.load(handle)


def main():
    if len(sys.argv) != 2:
        print("Usage: verify-orientations.py <Info.plist or IPA>", file=sys.stderr)
        return 2
    path = Path(sys.argv[1])
    if not path.is_file():
        print(f"Missing file: {path}", file=sys.stderr)
        return 2
    try:
        info = load_info(path)
        project = Path(__file__).resolve().parents[1] / "Plinka.xcodeproj/project.pbxproj"
        releases = set(re.findall(r"PLUKI_RELEASE_BUILD = (\d+);", project.read_text()))
        if len(releases) != 1:
            raise ValueError("Debug and Release must declare the same release build number.")
        expected_build = releases.pop()
        release_build = info.get("PlukiReleaseBuild")
        if not isinstance(release_build, str) or release_build != expected_build:
            raise ValueError(f"Missing or incorrect release label: {release_build!r}; expected Build {expected_build}.")
        print(f"Verified settings label: Build {release_build}")
        supported = info.get("UISupportedInterfaceOrientations")
        ipad = next(
            (value for key, value in info.items()
             if key.lower() == "uisupportedinterfaceorientations~ipad"),
            None,
        )
        iphone = next(
            (value for key, value in info.items()
             if key.lower() == "uisupportedinterfaceorientations~iphone"),
            None,
        )
        print("Declared default orientations:", supported)
        print("Declared iPhone orientations:", iphone)
        print("Declared iPad orientations:", ipad)
        if not isinstance(supported, list) or not IPHONE.issubset(set(supported)):
            raise ValueError("Missing the default portrait + landscape orientations.")
        if not isinstance(ipad, list) or not IPAD.issubset(set(ipad)):
            raise ValueError("Missing the four required iPad orientations (Apple 90474).")
        if iphone is not None and (
            not isinstance(iphone, list) or not IPHONE.issubset(set(iphone))
        ):
            raise ValueError("Incomplete iPhone orientation override.")
    except (OSError, ValueError, KeyError, zipfile.BadZipFile) as error:
        print(f"Orientation validation failed: {error}", file=sys.stderr)
        return 1
    print("Pluki orientation validation passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
