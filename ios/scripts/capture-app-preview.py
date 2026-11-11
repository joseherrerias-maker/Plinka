#!/usr/bin/env python3
"""Record genuine Pluki simulator gameplay for App Store Preview editing.

Works only with the DEBUG --app-preview-tour script. No signed app, device user
data, credentials, marketing HTML, or output is bundled with a public build.
"""
import json
import signal
import subprocess
import sys
import time
from pathlib import Path

app = Path(sys.argv[1])
out = Path(sys.argv[2])
out.mkdir(parents=True, exist_ok=True)
device_name = "iPhone 16"

def call(*command):
    return subprocess.check_output(command, text=True).strip()

types = json.loads(call("xcrun", "simctl", "list", "devicetypes", "-j"))["devicetypes"]
matches = [item["identifier"] for item in types if item["name"] == device_name]
if len(matches) != 1:
    raise SystemExit("Required iPhone 16 simulator is unavailable")
runtimes = json.loads(call("xcrun", "simctl", "list", "runtimes", "-j"))["runtimes"]
available = [r for r in runtimes if r.get("isAvailable") and r["name"].startswith("iOS")]
if not available:
    raise SystemExit("No available iOS runtime")
runtime = max(available, key=lambda r: tuple(int(x) for x in r["version"].split(".")))
uid = call("xcrun", "simctl", "create", "Pluki Preview Capture", matches[0], runtime["identifier"])
recorder = None
completed = False
try:
    call("xcrun", "simctl", "boot", uid)
    call("xcrun", "simctl", "bootstatus", uid, "-b")
    call("xcrun", "simctl", "status_bar", uid, "override",
         "--time", "9:41", "--batteryState", "charged", "--batteryLevel", "100")
    call("xcrun", "simctl", "install", uid, str(app))
    home = Path(call("xcrun", "simctl", "get_app_container", uid,
                     "com.joseherrerias.plinka", "data")) / "Documents"
    output = out / "Pluki_iPhone16_NativeScreenRecording.mp4"
    with (out / "recording.log").open("w") as log:
        recorder = subprocess.Popen(
            ["xcrun", "simctl", "io", uid, "recordVideo", "--codec=h264",
             "--mask=ignored", "--force", str(output)],
            stdout=log, stderr=subprocess.STDOUT)
        time.sleep(1.2)
        call("xcrun", "simctl", "launch", uid,
             "com.joseherrerias.plinka", "--app-preview-tour")
        deadline = time.monotonic() + 90
        while time.monotonic() < deadline:
            done = home / "app-preview-finished.txt"
            if done.exists() and done.read_text().strip() == "PASS":
                completed = True
                break
            if recorder.poll() is not None:
                raise RuntimeError("Simulator recording ended before preview tour finished")
            time.sleep(0.6)
        if not completed:
            raise TimeoutError("Native preview tour did not complete in 90s")
        time.sleep(0.7)
        recorder.send_signal(signal.SIGINT)
        try:
            recorder.wait(timeout=25)
        except subprocess.TimeoutExpired:
            recorder.terminate()
            recorder.wait(timeout=10)
            raise RuntimeError("Screen recorder failed to finalize in 25s")
    if not output.is_file() or output.stat().st_size < 25000:
        raise RuntimeError("No valid simulator video file was produced")
    (out / "capture-metadata.json").write_text(json.dumps({
        "app": "Pluki", "source": "Build 31 unsigned DEBUG app",
        "device": device_name, "runtime": runtime["name"],
        "native_screen_recording": output.name,
        "bytes": output.stat().st_size, "completed": completed,
        "tour_result": (home / "app-preview-stage.txt").read_text()
    }, indent=2))
    call("xcrun", "simctl", "io", uid, "screenshot", str(out / "final-home.png"))
    print("PASS: captured native Pluki iPhone 16 gameplay as actual simulator video")
finally:
    if recorder and recorder.poll() is None:
        recorder.send_signal(signal.SIGINT)
        try:
            recorder.wait(timeout=10)
        except subprocess.TimeoutExpired:
            recorder.kill()
    subprocess.run(["xcrun", "simctl", "shutdown", uid], check=False)
    subprocess.run(["xcrun", "simctl", "delete", uid], check=False)
