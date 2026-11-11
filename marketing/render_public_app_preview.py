#!/usr/bin/env python3
"""Render an App Store video from native Pluki simulator footage, not mock gameplay.
Output lives only on the isolated marketing branch, never in app resources.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import numpy as np
import subprocess, math, wave, json, sys

RAW=Path(sys.argv[1])
OUT=Path(sys.argv[2]); OUT.mkdir(parents=True, exist_ok=True)
W,H=886,1920
DURATION=22.55
START=109.9
FONTPATH="/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
CAPTIONS=[
    ("Make music, one note at a time", "#30c878",0.8,4.1),
    ("Mix playful instruments", "#ffb258",4.3,7.4),
    ("Watch your melody come alive", "#9f80e9",7.7,15.7),
    ("Explore editable sample tunes", "#4fc3ea",15.8,17.9),
    ("Create your own music video", "#fb98aa",18.9,20.7),
]
def run(args):
    subprocess.run(args,check=True)

def caption(text, color, idx):
    canvas=Image.new("RGBA",(W,H),(0,0,0,0))
    d=ImageDraw.Draw(canvas)
    d.rounded_rectangle((42,1448,844,1584),radius=35,fill=(27,47,70,235))
    d.rounded_rectangle((65,1475,147,1556),radius=18,fill=color)
    f=ImageFont.truetype(FONTPATH,48)
    while d.textbbox((0,0),text,font=f)[2] > 659:
        f=ImageFont.truetype(FONTPATH,f.size-2)
    d.text((88,1482),"♪",font=ImageFont.truetype(FONTPATH,47),fill="white")
    d.text((171,1491),text,font=f,fill="white")
    dst=OUT/f"caption-{idx}.png";canvas.save(dst)
    return dst

def melodic_audio():
    # Original Pluki Theme (C major; 132 BPM) from Song.swift, instrument-only.
    phrases=[[72,76,77,76,72,74,76,72,69,72],
             [74,76,77,76,74,72,74,76,72,74],
             [76,77,76,74,72,76,74,71,69,72]]
    rhythms=[[2,1,1,2,2,1,1,2,2,2],
             [1,1,2,2,1,1,2,2,2,2],
             [2,1,1,2,1,1,2,2,2,2]]
    sr=44100
    sound=np.zeros(int(DURATION*sr),dtype=np.float64)
    step_seconds=30.0/132.0
    for repetition in range(3):
        for k,(notes,beats) in enumerate(zip(phrases,rhythms)):
            offset=(repetition*48+k*16)
            beat=0
            for pitch,space in zip(notes,beats):
                when=(offset+beat)*step_seconds
                beat+=space
                if when>=DURATION: continue
                length=min(0.40,DURATION-when)
                t=np.arange(int(length*sr))/sr
                freq=440*2**((pitch-69)/12)
                env=np.minimum(1,t/0.010)*np.exp(-t*6.2)
                pluck=(np.sin(2*np.pi*freq*t)+0.18*np.sin(4*np.pi*freq*t))*env
                i=int(when*sr);sound[i:i+len(t)]+=pluck*0.26
        for off in [0,8,16,24,32,40]:
            when=(repetition*48+off)*step_seconds
            if when>=DURATION:continue
            t=np.arange(int(min(.27,DURATION-when)*sr))/sr
            freq=440*2**(((72 if off%16==0 else 69)-69)/12)
            env=np.minimum(1,t/.006)*np.exp(-t*10)
            p=(np.sin(2*np.pi*freq*t)+.22*np.sin(2*np.pi*freq*3*t))*env
            i=int(when*sr);sound[i:i+len(t)]+=p*.075
    fadein=np.minimum(1,np.arange(len(sound))/(.25*sr))
    fadeout=np.minimum(1,np.arange(len(sound)-1,-1,-1)/(.70*sr))
    sound=np.clip(sound*fadein*fadeout,-.85,.85)
    out=OUT/"Pluki_Theme_for_preview.wav"
    pcm=(np.column_stack([sound,sound])*32767).astype("<i2")
    with wave.open(str(out),"wb") as f:
        f.setnchannels(2);f.setsampwidth(2);f.setframerate(sr)
        f.writeframes(pcm.tobytes())
    return out

assert RAW.exists(), f"Native app recording missing: {RAW}"
caps=[caption(text,color,i) for i,(text,color,_,_) in enumerate(CAPTIONS)]
wav=melodic_audio()
filters=[f"[0:v]trim=start={START}:duration={DURATION},setpts=PTS-STARTPTS,fps=30,scale={W}:{H}:force_original_aspect_ratio=increase:flags=lanczos,crop={W}:{H},format=yuv420p[v0]"]
for i,(_,_,t1,t2) in enumerate(CAPTIONS):
    filters.append(f"[v{i}][{i+2}:v]overlay=0:0:enable='between(t,{t1},{t2})':format=auto[v{i+1}]")
dst=OUT/"Pluki_App_Store_Preview_iPhone_31.mp4"
cmd=["ffmpeg","-hide_banner","-y","-loglevel","warning","-i",str(RAW),"-i",str(wav)]
for pic in caps:cmd+=["-loop","1","-i",str(pic)]
cmd+=["-filter_complex",";".join(filters),"-map",f"[v{len(caps)}]","-map","1:a:0",
      "-t",str(DURATION),"-c:v","libx264","-preset","fast","-crf","23",
      "-profile:v","high","-level","4.0","-pix_fmt","yuv420p","-r","30",
      "-c:a","aac","-b:a","160k","-ac","2","-ar","44100",
      "-movflags","+faststart",str(dst)]
run(cmd)
run(["ffmpeg","-hide_banner","-y","-loglevel","error","-ss","8.0","-i",str(dst),"-frames:v","1",str(OUT/"Pluki_Preview_Poster.jpg")])
probe=subprocess.check_output(["ffprobe","-v","error","-show_entries","format=duration,size:stream=codec_name,width,height","-of","json",str(dst)],text=True)
meta=json.loads(probe)
assert 15<=float(meta["format"]["duration"])<=30,meta
assert dst.stat().st_size>150000
(OUT/"README.txt").write_text("Pluki Build 31 native simulator App Store Preview. Full gameplay is a real captured iOS Debug app. Overlaid captions and original synthesized Pluki Theme accompany the footage. Marketing asset only; no App Store submission made.\n")
print(json.dumps({"video":str(dst),"bytes":dst.stat().st_size,"probe":meta},indent=2))
