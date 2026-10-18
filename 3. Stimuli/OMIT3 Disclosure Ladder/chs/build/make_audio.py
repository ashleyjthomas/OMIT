"""Placeholder narration: synthesize every narration key with Piper TTS -> audio/<key>.mp3.
Megan's recordings replace these file-for-file (same names). Writes audio/narration_script.csv."""
import os, sys, csv, wave, subprocess, io
sys.path.insert(0, os.path.dirname(__file__))
from design import N
from piper import PiperVoice

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'audio'); os.makedirs(OUT, exist_ok=True)
VOICE = os.path.join(ROOT, '..', 'tts', 'en-us-lessac-medium.onnx')
voice = PiperVoice.load(VOICE)
only = set(sys.argv[1:])
for key, text in N.items():
    if only and key not in only: continue
    mp3 = os.path.join(OUT, key + '.mp3')
    if os.path.exists(mp3) and not only: continue
    buf = io.BytesIO()
    with wave.open(buf, 'wb') as w:
        voice.synthesize_wav(text.replace('"', ''), w)
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', 'pipe:0', '-af', 'apad=pad_dur=0.25', '-b:a', '64k', mp3],
                   input=buf.getvalue(), check=True)
with open(os.path.join(OUT, 'narration_script.csv'), 'w', newline='') as f:
    w = csv.writer(f); w.writerow(['file', 'text'])
    for key, text in N.items(): w.writerow([key + '.mp3', text])
print('audio files:', len([f for f in os.listdir(OUT) if f.endswith('.mp3')]))
