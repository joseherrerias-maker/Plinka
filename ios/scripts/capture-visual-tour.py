#!/usr/bin/env python3
"""Capture real simulator screens with an app/host handshake, never private user data."""
import json, subprocess, sys, time
from pathlib import Path

def run(*args):
    return subprocess.check_output(args, text=True).strip()

app, device_name, output = sys.argv[1:]
out = Path(output); out.mkdir(parents=True, exist_ok=True)
types = json.loads(run('xcrun', 'simctl', 'list', 'devicetypes', '-j'))['devicetypes']
kind = next((d['identifier'] for d in types if d['name'] == device_name), None)
if not kind:
    raise SystemExit(f'Required device unavailable: {device_name}; no silent substitution')
runtimes = json.loads(run('xcrun', 'simctl', 'list', 'runtimes', '-j'))['runtimes']
runtime = next(r['identifier'] for r in sorted(runtimes, key=lambda r: tuple(int(v) for v in r['version'].split('.')), reverse=True) if r['isAvailable'] and r['name'].startswith('iOS'))
uid = run('xcrun', 'simctl', 'create', 'Pluki Visual Review', kind, runtime)
try:
    subprocess.run(['defaults', 'write', 'com.apple.iphonesimulator', 'ConnectHardwareKeyboard', '-bool', 'NO'], check=True)
    run('xcrun', 'simctl', 'boot', uid)
    run('xcrun', 'simctl', 'bootstatus', uid, '-b')
    run('xcrun', 'simctl', 'status_bar', uid, 'override', '--time', '9:41', '--batteryState', 'charged', '--batteryLevel', '100')
    for key in ['DidShowContinuousPathIntroduction', 'UIKeyboardDidShowInternationalInfoIntroduction']:
        run('xcrun', 'simctl', 'spawn', uid, 'defaults', 'write', 'com.apple.keyboard.preferences', key, '-bool', 'YES')
    run('xcrun', 'simctl', 'install', uid, app)
    folder = Path(run('xcrun', 'simctl', 'get_app_container', uid, 'com.joseherrerias.plinka', 'data')) / 'Documents'
    run('xcrun', 'simctl', 'launch', uid, 'com.joseherrerias.plinka', '--visual-tour')
    seen = set(); deadline = time.monotonic() + 300
    while time.monotonic() < deadline:
        result = folder / 'visual-result.txt'
        if result.exists():
            message = result.read_text()
            (out / 'result.txt').write_text(message)
            if not message.startswith('PASS:') or len(seen) != 16:
                raise RuntimeError(f'{message}; captured {len(seen)}/16')
            break
        ready = folder / 'visual-ready.txt'
        if ready.exists():
            name = ready.read_text()
            if name and name not in seen:
                run('xcrun', 'simctl', 'io', uid, 'screenshot', str(out / (name + '.png')))
                seen.add(name)
                (folder / 'visual-ack.txt').write_text(name)
                print(f'{device_name}: {name}', flush=True)
        time.sleep(.3)
    else:
        raise TimeoutError('Visual tour timed out')
    (out / 'device.json').write_text(json.dumps({'device':device_name, 'runtime':runtime, 'screens':sorted(seen)}, indent=2))
finally:
    subprocess.run(['xcrun','simctl','shutdown',uid], check=False)
    subprocess.run(['xcrun','simctl','delete',uid], check=False)
