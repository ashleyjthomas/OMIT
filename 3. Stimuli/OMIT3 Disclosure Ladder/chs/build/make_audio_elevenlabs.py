"""Record every narration line with ElevenLabs into audio/<key>.mp3 (same names the task uses).

Run on your own machine from the chs/ folder:
    pip install requests
    export ELEVEN_API_KEY=...          # from elevenlabs.io -> Profile -> API keys
    export ELEVEN_VOICE_ID=...         # the voice's ID (Voices -> the voice -> "ID" / copy voice ID)
    python3 build/make_audio_elevenlabs.py            # all lines (skips ones already recorded with this voice)
    python3 build/make_audio_elevenlabs.py --force    # re-record everything
    python3 build/make_audio_elevenlabs.py SH_intro why   # just these keys

Reads the lines from audio/narration_script.csv (regenerate it with build/make_audio.py or build/build.py if the
design changed). Keeps a stamp in audio/.voice so a voice change re-records automatically.
"""
import os, sys, csv, time, json
import requests

HERE = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.dirname(HERE)
AUDIO = os.path.join(ROOT, 'audio')
KEY = os.environ.get('ELEVEN_API_KEY'); VOICE = os.environ.get('ELEVEN_VOICE_ID')
if not KEY or not VOICE:
    sys.exit('Set ELEVEN_API_KEY and ELEVEN_VOICE_ID in the environment first (see the top of this file).')
MODEL = os.environ.get('ELEVEN_MODEL', 'eleven_multilingual_v2')
SETTINGS = {'stability': 0.5, 'similarity_boost': 0.8, 'style': 0.25, 'use_speaker_boost': True}

args = [a for a in sys.argv[1:] if not a.startswith('--')]; force = '--force' in sys.argv
stamp = os.path.join(AUDIO, '.voice'); prev = open(stamp).read().strip() if os.path.exists(stamp) else ''
if prev != VOICE: force = True
lines = list(csv.DictReader(open(os.path.join(AUDIO, 'narration_script.csv'))))
todo = [l for l in lines if (not args or l['file'][:-4] in args)]
print(f'{len(todo)} lines, voice {VOICE}, model {MODEL}')
for i, l in enumerate(todo, 1):
    out = os.path.join(AUDIO, l['file'])
    if os.path.exists(out) and not force and not args:
        continue
    r = requests.post(f'https://api.elevenlabs.io/v1/text-to-speech/{VOICE}',
                      headers={'xi-api-key': KEY, 'accept': 'audio/mpeg', 'content-type': 'application/json'},
                      json={'text': l['text'], 'model_id': MODEL, 'voice_settings': SETTINGS,
                            'output_format': 'mp3_44100_64'}, timeout=120)
    if r.status_code != 200:
        print('FAILED', l['file'], r.status_code, r.text[:200]); continue
    open(out, 'wb').write(r.content)
    print(f'[{i}/{len(todo)}] {l["file"]}  {len(r.content)//1024} KB')
    time.sleep(0.3)
open(stamp, 'w').write(VOICE)
print('done. Commit and push audio/ so CHS picks the new clips up.')
