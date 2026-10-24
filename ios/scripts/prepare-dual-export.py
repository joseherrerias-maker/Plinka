"""Select installed Pluki profiles and prepare two exports from one archive."""
import datetime
import os
from pathlib import Path
import plistlib
import subprocess

BUNDLE = "com.joseherrerias.plinka"
build = Path(os.environ["CM_BUILD_DIR"]) / "build"
build.mkdir(exist_ok=True)
profiles = {"store": [], "adhoc": []}
for root in (Path.home() / "Library/MobileDevice/Provisioning Profiles",
             Path.home() / "Library/Developer/Xcode/UserData/Provisioning Profiles"):
    for path in root.glob("*.mobileprovision"):
        result = subprocess.run(["security", "cms", "-D", "-i", str(path)], capture_output=True)
        if result.returncode:
            continue
        profile = plistlib.loads(result.stdout)
        ent = profile.get("Entitlements", {})
        team = profile.get("TeamIdentifier", [""])[0]
        if ent.get("application-identifier") != team + "." + BUNDLE:
            continue
        if ent.get("get-task-allow") or profile.get("ProvisionsAllDevices"):
            continue
        if profile.get("ExpirationDate", datetime.datetime.min) <= datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None):
            continue
        kind = "adhoc" if profile.get("ProvisionedDevices") else "store"
        profiles[kind].append(profile)
if not all(profiles.values()):
    raise SystemExit("Missing valid Pluki App Store or Ad Hoc profile. See ios/VERSION-3.md.")
store = max(profiles["store"], key=lambda p: p["ExpirationDate"])
adhoc = max(profiles["adhoc"], key=lambda p: p["ExpirationDate"])
if store["TeamIdentifier"] != adhoc["TeamIdentifier"]:
    raise SystemExit("Pluki profiles must belong to the same Apple team.")
for name, method, profile in (("TestFlight", "app-store-connect", store),
                              ("AdHoc", "release-testing", adhoc)):
    options = dict(method=method, signingStyle="manual",
                   signingCertificate="Apple Distribution",
                   teamID=profile["TeamIdentifier"][0],
                   provisioningProfiles={BUNDLE: profile["UUID"]},
                   manageAppVersionAndBuildNumber=False)
    if name == "TestFlight":
        options["testFlightInternalTestingOnly"] = True
    (build / (name + "Export.plist")).write_bytes(plistlib.dumps(options))
# Only non-secret identifiers; use files rather than shell evaluation.
(build / "signing-team.txt").write_text(store["TeamIdentifier"][0])
(build / "signing-profile.txt").write_text(store["UUID"])
print("Prepared Pluki App Store and Ad Hoc export settings.")
