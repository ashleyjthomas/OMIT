# OMIT3 — disclosure ladder stimuli

A six-trial child deck built **by editing `OMIT Stim A.pptx`**, not by rebuilding it. Every
slide is one of your own slides, duplicated: the layouts, the thought and speech bubbles, the
prohibition sign, the question-mark slides, the "Who do you think is a better friend?" text
and all the click animations are yours, untouched. Only three things change per trial — which
images the picture frames point at, the picture frames' sizes (so a replacement isn't
stretched), and the speaker notes.

**Deck:** `OMIT3 Disclosure Ladder A.pptx` — 73 slides. Validated; opens clean.

## The design

Four disclosure contents, six pairwise trials, one pair per trial, a new protagonist each time.

| Code | Content | Shown as |
|---|---|---|
| **IF** | impersonal fact | the animal alone |
| **PF** | personal preference (favourite animal) | the protagonist *beside* the animal |
| **HE** | happy emotion | the protagonist with the grin |
| **SE** | sad emotion | the protagonist with the tear |

Predicted order of diagnosticity for closeness: **IF < PF < HE < SE**.

| Trial | Pair | Protagonist | Classmates | Animals | Isolates |
|---|---|---|---|---|---|
| 1 | SE–HE | Casey (magenta) | Blake (mint), Morgan (navy) | — | valence, content type constant |
| 2 | SE–PF | Rowan (blue) | Jesse (lavender), Kai (dark green) | rabbit | vulnerability beyond inner life |
| 3 | SE–IF | Percy (purple) | Avery (periwinkle), Orin (orange) | fox | your original Study 1, sad |
| 4 | HE–PF | Devon (olive) | Harper (light blue), Quinn (brown) | owl | content type, valence constant |
| 5 | HE–IF | Kendall (teal) | Riley (yellow-green), Cameron (peach) | elephant | your original Study 1, happy |
| 6 | PF–IF | Jamie (slate) | Elliot (orange), Parker (dark brown) | owl, rabbit | own mind vs. the world |

Trials 3 and 5 reuse your existing characters, names and animals exactly, so they remain
direct replications. Trials 1, 2, 4 and 6 are new. All 18 characters are distinct colours; the
two classmates in a trial are never close in hue or lightness, and neither is close to the
protagonist. Every name is gender-neutral and the figures carry no gender cues, so protagonist
gender needs no counterbalancing.

Ice cream and candy follow **every** trial, so the physical-intimacy measure is available for
all six content pairs rather than only the two critical ones. Preregister the cone-versus-candy
contrast this time rather than recovering it afterwards. The cost is session length: 12 food
questions on top of 6 memory checks and 6 better-friend judgments.

## Where each thing happens

The establishment scene is chosen by what is being established, so location tracks content type:

| Content | Scene |
|---|---|
| **SE** — feeling sad | the lunch room |
| **HE** — feeling happy | the playground |
| **IF / PF** — a fact learned, a favourite animal found out | the classroom (chalkboard + desk, as in the original decks) |

The desk is suppressed on the lunch-room and playground slides — a transparent placeholder
replaces it rather than the shape being deleted, so the inherited click animations keep their
targets and nothing in PowerPoint breaks.

**Scene geometry comes from the hand-resized Trial 1 slides**, not from a fitting rule. The
lunch room is 7.93″ × 4.25″ at (0.18″, 0.25″) and the playground 6.77″ × 4.24″ at (0.29″,
0.15″), each with its own aspect preserved, and each sent to the back of the shape tree so the
protagonist and the thought bubble stand in front of the scene rather than behind a picture of
it. Those numbers live in `SCENE_GEOM` in the generator, so every trial and every future
counterbalance version inherits them. To change the framing, resize one slide per scene in
PowerPoint, save, and the values can be read back out and re-propagated.

The classroom establishments are untouched — still your original small chalkboard plus desk.
Whether those should also become a full-width classroom scene, for consistency with the other
two, is an open question rather than an oversight.

## Slide sequence per trial

1. This is *X*
2. establishment of content A (thought bubble)
3. establishment of content B (thought bubble)
4. meets classmate 1, tells them content B
5. does not tell classmate 1 content A
6. meets classmate 2, does not tell them content B
7. tells classmate 2 content A
8. memory check
9. **who is a better friend** — primary DV
10–11. ice cream, candy

## Two decisions worth knowing about

**Every trial is built on the happy-block template, not the sad block.** Your sad block
establishes sadness with a visible tear laid over the figure; your happy block establishes
happiness through narration alone, with no overlay. That asymmetry was invisible in the
original design because sad and happy never met. Trial 1 compares them head-on, so both
contents are now shown the same way — as bubble images — and neither valence gets a visual
advantage.

**Expressions are derived from one base figure.** Your decks hold three separate drawings per
character (neutral, tear, grin) at different head-to-body proportions. Trial 1 puts sad and
happy in one story, where a proportion change would read as the character changing size. So
all three expressions are composited onto the *same* neutral figure, using your own teardrop
and your own grin (cropped from `magenta_happy` and scaled by eye separation). The sad
convention is unchanged: tear only, no mouth.

**No affective marker on the preference item.** A heart would say "loves owls" — the emotion
reading that "favourite animal" exists to avoid. Instead the set uses a distinction already
implicit in your decks: content about the world shows the thing, content about oneself shows
oneself. So the fact bubble holds the animal alone and the preference bubble holds the
protagonist beside it. This relies on the bubble picture indexing the topic rather than the
proposition, which is how your system already works — the fox picture never depicted "moves
without making any sound" either.

**A fix to your original bubble art.** `image10` (Percy with the tear) and `image21` (Kendall
with the grin) carry an opaque white background. That was invisible in the original decks but
showed as a white rectangle once those figures sat inside a thought-bubble cloud. The white is
now keyed out by flood-filling inward from the image border only, so the figures' own white
heads are untouched — the drawings themselves are unchanged.

## Folders

| Folder | Files | What |
|---|---|---|
| `characters_derived/` | 54 | 18 colours × {neutral, sad, happy}, all on one registered base |
| `newmedia/` | 20 | exactly the images swapped into the deck for trials 1, 2, 4, 6 |
| `props/` | 17 | animals, ice cream, candy, school, bus, desk, chalkboard, banners |
| `icons_final/`, `bubbles/` | — | pre-composited bubble art from an earlier standalone build; the deck does not use these |

## Still to do

- **Counterbalance versions — next job.** This is version A. The generator already isolates
  everything that needs to vary, so each version is a parameter change rather than new work:
  which classmate receives which content (exchange the `A` and `B` media for a trial), which
  animal plays fact versus favourite, and trial order. Deciding the version scheme before
  generating is worth doing, since it also fixes what the analysis has to code.
- **Narration.** The speaker notes are the script, ready for ElevenLabs if you want recorded
  audio. If you do, generate every line at identical voice settings and then check it: have two
  naive raters hear only the sad and happy establishment lines and guess the valence. If they
  can, the voice is carrying the manipulation and needs regenerating.
- **The "Why?" probes** from your original are preserved in the notes for the better-friend and
  food questions, but not for the establishment or memory-check slides.
- **Animation check in PowerPoint.** The click sequences are inherited from your slides and
  cannot be verified by the renderer used here, which draws every animation state at once. Step
  through the deck once in PowerPoint before piloting.
- **Owl and rabbit each appear twice** across trials (owl as a favourite in 4 and 6, rabbit as a
  favourite in 2 and a fact in 6). Distinct within every trial, but worth rotating across
  counterbalance versions.
