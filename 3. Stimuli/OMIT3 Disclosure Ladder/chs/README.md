# OMIT3 — Children Helping Science build

Four-trial disclosure study (sad vs happy · sad vs fact · happy vs fact · preference vs fact), run
asynchronously on CHS as a jsPsych study. The task runs *inside* the CHS protocol, so every click is
in the CHS response data and the webcam recording covers the "Why?" answers. Design and counterbalancing
follow `../OMIT3_counterbalance_spec.md` and `../OMIT3_versions.csv`.

## What is in here

| path | what |
|---|---|
| `dist/chs_protocol.js` | **Paste this into the CHS study editor** (jsPsych study type). Self-contained: design table, scenes, custom plugin, consent, instructions, exit survey, debrief. |
| `dist/omit3_task.bundle.js` | The task alone (design + scenes + plugin), used by `index.html`. |
| `index.html` | Standalone test runner. Open from a web server (or GitHub Pages) with `?version=V3`, `&why=0` to skip Why?, `&dl=1` to download the CSV at the end. |
| `assets/` | Images: `characters/`, `icons/`, `bg/`, `frames/`, `layers/` (cloud, balloon, no-symbol), `narrator/` (6 mouth/eye frames). |
| `audio/` | Narration mp3s, one per narration unit (91 files). **Currently placeholder TTS**; `audio/narration_script.csv` is the recording script. |
| `design.json` | Generated: contents, trials, versions, narration texts. |
| `src/` | Sources: `omit3_task.js` (scenes + plugin + timeline), `chs_protocol_template.js`, `index_template.html`. |
| `build/` | `design.py` (single source of truth; reads `../OMIT3_versions.csv`), `build.py`, `make_audio.py`. |
| `test/` | `run_test.js`: headless Playwright run of one version, writes `test/out/data_Vn.csv` + screenshots. |

## Hosting

CHS loads stimuli from a public https URL. The protocol is built with
`BASE_URL = https://raw.githubusercontent.com/ashleyjthomas/OMIT3-CHS/main/`, so: create a public repo
`OMIT3-CHS` under the lab GitHub, push the contents of this folder (`assets/`, `audio/`, `dist/`, `index.html`
are what the study needs), and paste `dist/chs_protocol.js` into CHS. To host elsewhere, run
`python3 build/build.py https://your.host/path/` and re-paste. Enabling GitHub Pages on the repo also
gives a live test link (`https://ashleyjthomas.github.io/OMIT3-CHS/?version=V1`).

CHS plugins the protocol expects to be enabled for the study: `jsPsychFullscreen`, `jsPsychPreload`,
`jsPsychHtmlButtonResponse`, `jsPsychSurveyText`, `chsRecord` (VideoConfig, VideoConsent, StartRecord,
StopRecord), `chsSurvey` (ExitSurvey). The task's own plugin (`omit3-scene`) is defined inline.

## Session flow

fullscreen → video config → video consent → payment email → preload → two instruction pages → **start recording** →
welcome → practice (Sam; Quinn = best friend, Rowan = friend: ball → juice box with one straw → cookies) → "Let's get started" →
4 trials in the version's order, each: intro → two establishing pages → classmate 1 (told, then not told) → classmate 2 (told, then not told) →
memory check (higher-rung content) → memory check (lower-rung) → better friends with? (+Why) → single ice cream cone (+Why) → candy (+Why) →
"All done" → **stop recording** → exit survey → debrief.

Story pages play their narration and advance on their own (~0.9 s after the audio ends); a "hear again"
button replays, and a Next button appears only if audio fails. Choice pages make the two characters
clickable when the narration ends; the chosen one is highlighted; on Why? pages the parent clicks Next
after the child answers. The ball item gives corrective feedback up to 3 attempts.

A narrator character (bottom-right) lip-flaps with the audio level (Web Audio analyser; falls back to
random flapping if the browser blocks analysis) and blinks; it grins briefly after each choice.

## Versions

One of V1–V8 is drawn at random per session (`version` is stamped on every row). Per version, from the CSV:
trial order (Williams square), which classmate gets the higher-rung content per trial (pattern P/Q →
`recording` A/B), SH emotion order and scene (sad at lunch vs recess), PF animal roles (owl vs rabbit as the
favourite; the other is the fact — note the owl fact "owls can turn their heads almost all the way around"
is new and needs sign-off), practice best-friend side and ball holder.

Recorded per choice row: `block, position, trial, item, protagonist, left, right, hi_content, lo_content,
hi_told_to, hi_classmate, recording, choice (left/right), choice_name, chose_hi (1 = picked the classmate told the
higher-rung content), correct (memory checks and ball), rt (ms from when clicking was enabled), attempts,
audio_ok`, plus practice fields `best_side, chose_best`. Story rows carry the same context with `choice = null`.

## Audio to record

`audio/narration_script.csv` lists every file and its text (91 lines; the encounter lines come in A and B
variants because the classmate named changes). Record each as its own file, save as mp3 with the listed name,
and drop them over the placeholders — nothing else changes. Keep ~0.3 s of silence at the end of each clip.

## Rebuilding

```
python3 build/build.py            # design.json, dist/, index.html   (edit src/ and build/design.py, not dist/)
python3 build/make_audio.py       # placeholder TTS for any missing audio key (needs ../tts/*.onnx + piper)
node test/run_test.js V3 shots    # headless run (needs test/node_modules; see test/package.json)
```

## Known gaps / decisions still open

- Consent, purpose, payment and debrief texts are adapted from the Relationship Detective protocol and need to match the IRB amendment.
- Narration is placeholder TTS.
- Adult version (Qualtrics/Prolific) not built; the same `assets/` and `design.json` can drive it.
- No server-side balancing of versions (random draw); check the version counts as data come in and, if needed, restrict `Object.keys(D.versions)` in `buildTimeline` to the under-sampled ones.
