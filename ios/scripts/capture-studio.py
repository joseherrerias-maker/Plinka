#!/usr/bin/env python3
"""Capture native Build 31 screens in fresh simulators; preserve raw PNG/video."""
import os, json, signal, subprocess, sys, time, shutil, hashlib
from pathlib import Path
app, device, output = sys.argv[1:]
out=Path(output);out.mkdir(parents=True,exist_ok=True)
def run(*args): return subprocess.check_output(args,text=True).strip()
types=json.loads(run('xcrun','simctl','list','devicetypes','-j'))['devicetypes']
kind=next((d['identifier'] for d in types if d['name']==device),None)
if not kind: raise SystemExit(f'Required device unavailable: {device}')
runtimes=json.loads(run('xcrun','simctl','list','runtimes','-j'))['runtimes']
runtime=max((r for r in runtimes if r['isAvailable'] and r['name'].startswith('iOS')),key=lambda r:tuple(map(int,r['version'].split('.'))))
uid=run('xcrun','simctl','create','Pluki Little Music Studio',kind,runtime['identifier'])
recorder=driver=None
try:
 run('xcrun','simctl','boot',uid);run('xcrun','simctl','bootstatus',uid,'-b')
 run('xcrun','simctl','ui',uid,'appearance','light')
 run('xcrun','simctl','status_bar',uid,'override','--time','9:41','--batteryState','charged','--batteryLevel','100')
 run('xcrun','simctl','install',uid,app)
 folder=Path(run('xcrun','simctl','get_app_container',uid,'com.joseherrerias.plinka','data'))/'Documents'
 driverlog=(out/'driver.log').open('w')
 driver=subprocess.Popen(['xcodebuild','test','-project','ios/VisualDriver/VisualDriver.xcodeproj','-scheme','VisualDriver','-destination',f'id={uid}','-parallel-testing-enabled','NO','-only-testing:VisualDriver/VisualDriver','CODE_SIGNING_ALLOWED=NO'],stdout=driverlog,stderr=subprocess.STDOUT)
 seen=set();deadline=time.monotonic()+600
 while time.monotonic()<deadline:
  if driver.poll() is not None and driver.returncode!=0: raise RuntimeError('Native driver failed; see driver.log')
  result=folder/'studio-result.txt'
  if result.exists():
   message=result.read_text();(out/'result.txt').write_text(message)
   if not message.startswith('PASS:') or len(seen)!=6: raise RuntimeError(f'{message}; captured {len(seen)}/6')
   break
  if recorder is None and (folder/'studio-record-ready.txt').exists():
   rec_log=(out/'recording.log').open('w')
   recorder=subprocess.Popen(['xcrun','simctl','io',uid,'recordVideo','--codec=h264','--mask=ignored','--force',str(out/'Native_Studio_Footage.mp4')],stdout=rec_log,stderr=subprocess.STDOUT)
  ready=folder/'studio-ready.txt'
  if ready.exists():
   name=ready.read_text()
   if name and name not in seen:
    run('xcrun','simctl','io',uid,'screenshot',str(out/(name+'.png')))
    seen.add(name)
    (folder/'studio-ack.txt').write_text(name)
    print(f'{device}: {name}',flush=True)
  time.sleep(.15)
 else: raise TimeoutError('Studio tour exceeded 600 seconds')
 if driver.wait(timeout=60)!=0: raise RuntimeError('Native driver failed after captures')
 if recorder:
  recorder.send_signal(signal.SIGINT);recorder.wait(timeout=30);recorder=None
 for pattern in ['*.pluki','Little_Sunrise_Export.mp4']:
  for p in folder.glob(pattern): shutil.copy2(p,out/p.name)
 pngs={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in out.glob('*.png')}
 (out/'capture.json').write_text(json.dumps({'device':device,'runtime':runtime['name'],'base_release_commit':'b0e83b918ff4d6d8ddba8b59b7851e7f588bc272','capture_commit':os.environ.get('GITHUB_SHA'),'app_version':'1.1','build':'31','source':'Native SwiftUI app, unsigned Debug simulator; capture-only code excluded from Release','screens':sorted(seen),'sha256':pngs,'recording_audio':'simctl footage is silent; real song audio is present in Little_Sunrise_Export.mp4','physical_device_verified':False},indent=2))
finally:
 if recorder and recorder.poll() is None:
  recorder.send_signal(signal.SIGINT)
  try: recorder.wait(timeout=20)
  except subprocess.TimeoutExpired: recorder.kill()
 if driver and driver.poll() is None: driver.terminate()
 subprocess.run(['xcrun','simctl','shutdown',uid],check=False)
 subprocess.run(['xcrun','simctl','delete',uid],check=False)
