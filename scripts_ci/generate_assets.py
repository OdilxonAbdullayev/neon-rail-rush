"""Original procedural soundtrack, FX and icon (no stock/copyrighted game assets)."""
from pathlib import Path
import math, random, wave
from PIL import Image, ImageDraw, ImageFilter
import numpy as np

HERE = Path(__file__).resolve().parents[1]
AUDIO = HERE / 'audio'
AUDIO.mkdir(exist_ok=True)
FS = 22050

def emit(name, signal):
    sig = np.asarray(signal, dtype=np.float64)
    sig = np.nan_to_num(sig)
    peak = max(1.0, float(np.max(np.abs(sig))) * 1.04)
    sig = np.clip(sig / peak, -1, 1)
    fade = min(400, len(sig)//10)
    if fade:
        sig[:fade] *= np.linspace(0, 1, fade)
        sig[-fade:] *= np.linspace(1, 0, fade)
    with wave.open(str(AUDIO/f'{name}.wav'), 'wb') as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(FS)
        f.writeframes((sig * 31000).astype('<i2').tobytes())

def tone(freq, sec, decay=4, waveform='sine'):
    t = np.arange(int(FS * sec)) / FS
    phase = np.cumsum(np.maximum(freq if np.isscalar(freq) else np.asarray(freq), 10)) * (2*math.pi/FS)
    if waveform=='saw':
        wave_=2*((phase/(2*math.pi))%1)-1
    elif waveform=='triangle':
        wave_=2*np.abs(2*((phase/(2*math.pi))%1)-1)-1
    else:
        wave_=np.sin(phase)
    return wave_ * np.exp(-decay*t/max(.0001,sec))

# 16 second original loop, 120 BPM, synthwave-ish.
random.seed(1607)
length=16
out=np.zeros(FS*length, dtype=np.float64)

def add(start, arr, level):
    at=int(start*FS)
    count=min(len(arr), len(out)-at)
    if at>=0 and count>0:
        out[at:at+count] += arr[:count]*level

bass_notes=[55,55,65.41,65.41,73.42,73.42,49,49, 55,55,65.41,65.41,73.42,73.42,82.41,49]
melody=[220,0,261.63,329.63,392,329.63,261.63,0,
        246.94,0,293.66,369.99,440,369.99,293.66,0,
        261.63,0,329.63,392,523.25,392,329.63,0,
        220,0,246.94,293.66,369.99,293.66,246.94,0]
for i in range(32):
    start=i*.5
    bass=tone(bass_notes[i//2],.42,3.5,'triangle')
    add(start,bass,.24)
    f=melody[i]
    if f:
        lead=tone(f,.27,3.7,'sine')
        add(start+.03,lead,.19)
        add(start+.25, tone(f*1.5,.12,5),.055)
    # synthetic kick on beats
    if i%2==0:
        t=np.arange(int(FS*.22))/FS
        freq=55+75*np.exp(-28*t)
        ph=np.cumsum(freq)*2*math.pi/FS
        kick=np.sin(ph)*np.exp(-28*t)
        add(start,kick,.22)
    # offbeat synthesized hihat
    noise=np.random.default_rng(i).standard_normal(int(FS*.06))
    t=np.arange(len(noise))/FS
    hats=np.concatenate(([0],np.diff(noise)))*np.exp(-85*t)
    add(start+.25,hats,.055)
# less than max amplitude and looping seam
out*=.75
emit('neon_loop',out)

for name,data in {
    'coin': (880, .14,6, 'sine'),
    'jump': (520,.22,4,'triangle'),
    'slide': (190,.17,4,'triangle'),
    'power': (740,.4,2.4,'sine'),
    'start': (330,.55,2.0,'triangle'),
    'hit': (100,.42,3,'triangle')
}.items():
    freq,sec,dec,shape=data
    n=int(sec*FS)
    if name=='coin': freqs=np.linspace(freq,freq*1.6,n)
    elif name=='jump': freqs=np.linspace(freq*.7,freq*1.3,n)
    elif name=='slide': freqs=np.linspace(freq*1.5,freq*.65,n)
    elif name=='power': freqs=np.linspace(freq*.5,freq*1.25,n)
    elif name=='start': freqs=np.linspace(freq,freq*1.5,n)
    else: freqs=np.linspace(freq*1.4,freq*.45,n)
    sound=tone(freqs,sec,dec,shape)
    if name=='hit':
        sound=sound*.7 + np.random.default_rng(444).normal(size=n)*np.exp(-np.arange(n)/FS*18)*.08
    emit(name,sound)

# Neon branded application icon made from vector-like geometric drawing.
N=512
im=Image.new('RGBA',(N,N),(12,18,43,255))
draw=ImageDraw.Draw(im)
for y in range(N):
    a=y/(N-1)
    draw.line((0,y,N,y),fill=(int(12+20*a),int(18+5*a),int(43+34*a),255))
# glow layer
blur=Image.new('RGBA',(N,N),(0,0,0,0))
g=ImageDraw.Draw(blur)
for j,x in enumerate([134,256,378]):
    g.line([(x+75,450),(x-25,115)], fill=(30,245,242,200) if j%2 else (246,70,160,200), width=25)
blur=blur.filter(ImageFilter.GaussianBlur(29))
im=Image.alpha_composite(im,blur)
d=ImageDraw.Draw(im)
d.rounded_rectangle((38,38,474,474),radius=105,outline=(107,231,235,110),width=7)
# perspective tracks
for x,col in zip([126,256,386],[(54,239,235,255),(255,90,168,255),(54,239,235,255)]):
    d.line([(x+57,453),(x-18,175)],fill=col,width=17)
    d.line([(x-4,453),(x-35,175)],fill=(202,213,255,240),width=9)
for y in [230,293,358,431]:
    d.line([(100+int((431-y)/7),y),(414-int((431-y)/7),y)],fill=(74,115,186,150),width=9)
# runner
x,y=260,285
d.ellipse((x-40,y-96,x+40,y-18),fill=(233,196,179,255))
d.rounded_rectangle((x-56,y-30,x+56,y+85),radius=28,fill=(116,87,242,255))
d.line((x-39,y+71,x-52,y+151),fill=(246,246,255,255),width=23)
d.line((x+37,y+72,x+52,y+148),fill=(246,246,255,255),width=23)
d.rounded_rectangle((x-47,y-105,x+47,y-70),radius=12,fill=(10,15,35,255))
d.polygon([(x-48,y-82),(x+47,y-82),(x+65,y-62),(x-50,y-60)],fill=(255,85,171,255))
im.convert('RGB').save(HERE/'assets/icon.png',optimize=True)
print('Generated 7 WAV sounds and icon.png')
