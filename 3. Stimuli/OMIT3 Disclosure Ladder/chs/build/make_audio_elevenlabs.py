"""Record every narration line with ElevenLabs into audio/<key>.mp3 (same names the task uses).

Run on your own machine from the chs/ folder:
    pip install requests
    export ELEVEN_API_KEY=...          # from elevenlabs.io -> Profile -> API keys
    export ELEVEN_VOICE_ID=...         # the voice's ID (Voices -> the voice -> "ID" / copy voice ID)
    #   or, if you only know the name:  export ELEVEN_VOICE_NAME="Sparkles for Kids"
    #   (the voice must be in My Voices: in the Voice Library click "Add to my voices" first)
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
KEY = os.environ.get('ELEVEN_API_KEY'); VOICE = os.environ.get('ELEVEN_VOICE_ID'); NAME = os.environ.get('ELEVEN_VOICE_NAME')
if not KEY or not (VOICE or NAME):
    sys.exit('Set ELEVEN_API_KEY and either ELEVEN_VOICE_ID or ELEVEN_VOICE_NAME first (see the top of this file).')
if not VOICE:   # look the voice up by name among the voices in this account
    r = requests.get('https://api.elevenlabs.io/v1/voices', headers={'xi-api-key': KEY}, timeout=60); r.raise_for_status()
    voices = r.json().get('voices', [])
    hits = [v for v in voices if v['name'].strip().lower() == NAME.strip().lower()] or [v for v in voices if NAME.strip().lower() in v['name'].lower()]
    if not hits:
        sys.exit(f'No voice named "{NAME}" in My Voices. Available: ' + ', '.join(v['name'] for v in voices) +
                 '\nIn the Voice Library, open the voice and click "Add to my voices", then run again.')
    VOICE = hits[0]['voice_id']; print(f'voice "{hits[0]["name"]}" -> {VOICE}')
MODEL = os.environ.get('ELEVEN_MODEL', 'eleven_multilingual_v2')
SETTINGS = {'stability': 0.5, 'similarity_boost': 0.8, 'style': 0.25, 'use_speaker_boost': True}

args = [a for a in sys.argv[1:] if not a.startswith('--')]; force = '--force' in sys.argv
stamp = os.path.join(AUDIO, '.voice'); prev = open(stamp).read().strip() if os.path.exists(stamp) else ''
if prev != VOICE: force = True
# the text each existing mp3 was recorded from. A clip whose line has changed since is
# re-recorded even without --force: otherwise an edited line silently keeps its old audio.
texts_path = os.path.join(AUDIO, '.texts.json')
rec_text = json.load(open(texts_path)) if os.path.exists(texts_path) else {}
lines = list(csv.DictReader(open(os.path.join(AUDIO, 'narration_script.csv'))))
todo = [l for l in lines if (not args or l['file'][:-4] in args)]
print(f'{len(todo)} lines, voice {VOICE}, model {MODEL}')
failed = 0; done = 0
for i, l in enumerate(todo, 1):
    out = os.path.join(AUDIO, l['file'])
    key = l['file'][:-4]
    if os.path.exists(out) and not force and not args and rec_text.get(key) == l['text']:
        continue
    if os.path.exists(out) and rec_text.get(key) not in (None, l['text']):
        print(f'  text changed since recording -> re-recording {l["file"]}')
    r = requests.post(f'https://api.elevenlabs.io/v1/text-to-speech/{VOICE}',
                      headers={'xi-api-key': KEY, 'accept': 'audio/mpeg', 'content-type': 'application/json'},
                      json={'text': l['text'], 'model_id': MODEL, 'voice_settings': SETTINGS,
                            'output_format': 'mp3_44100_64'}, timeout=120)
    if r.status_code != 200:
        print('FAILED', l['file'], r.status_code, r.text[:200]); failed += 1; continue
    open(out, 'wb').write(r.content); rec_text[key] = l['text']
    print(f'[{i}/{len(todo)}] {l["file"]}  {len(r.content)//1024} KB'); done += 1
    time.sleep(0.3)
json.dump(rec_text, open(texts_path, 'w'), indent=0, sort_keys=True)
if failed == 0 and (done or not todo):
    open(stamp, 'w').write(VOICE)
print(f'done: {done} recorded, {failed} failed, {len(todo) - done - failed} already had this voice (use --force to redo). Commit and push audio/ so CHS picks the new clips up.')
