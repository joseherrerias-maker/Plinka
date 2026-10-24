"""Validate an exported Ad Hoc IPA before creating the downloadable ZIP."""
from pathlib import Path
import datetime
import plistlib
import subprocess
import sys
import tempfile
import zipfile

ipa, destination = map(Path, sys.argv[1:])
with zipfile.ZipFile(ipa) as archive:
    profiles = [n for n in archive.namelist()
                if n.startswith("Payload/") and n.count("/") == 2
                and n.endswith(".app/embedded.mobileprovision")]
    if len(profiles) != 1:
        raise SystemExit("Expected one embedded app provisioning profile.")
    with tempfile.TemporaryDirectory() as temp:
        path = Path(temp) / "profile.mobileprovision"
        path.write_bytes(archive.read(profiles[0]))
        decoded = subprocess.check_output(["security", "cms", "-D", "-i", str(path)])
    profile = plistlib.loads(decoded)
    ent = profile.get("Entitlements", {})
    team = profile.get("TeamIdentifier", [""])[0]
    if ent.get("application-identifier") != team + ".com.joseherrerias.plinka":
        raise SystemExit("Wrong app identifier in iPad export.")
    if not profile.get("ProvisionedDevices") or ent.get("get-task-allow") or profile.get("ProvisionsAllDevices"):
        raise SystemExit("Expected an Ad Hoc distribution profile with registered devices.")
    if profile["ExpirationDate"] <= datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None):
        raise SystemExit("The Ad Hoc profile has expired.")
destination.parent.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(destination, "w", zipfile.ZIP_DEFLATED) as archive:
    archive.write(ipa, "Pluki-iPad-AdHoc.ipa")
print("Verified Ad Hoc export and created " + destination.name)
