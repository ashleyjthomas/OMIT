# OMIT / OMIT3 — context brief

Written 18 Oct 2026 to carry the state of this project into a fresh conversation.
Everything below is established, not proposed, unless marked OPEN.

---

## 1. Where the project stands

**OMIT** is a manuscript: *Children's Expectations of Emotional Intimacy in Close
Relationships*. Children 6–9 plus adult comparison samples. Forced choice throughout:
would a protagonist disclose an **emotion** or a **fact**? DV is `chose_emotion`
(1 = emotion, 0 = fact).

**It was rejected from JEPG.** No response letter is needed. Possible next venues
discussed: Cognition, Child Development, Developmental Science.

**OMIT3** is the follow-up study, currently being built. Its job is to convert the
paper's most interesting finding — that children treat *sad* disclosure as more
diagnostic of closeness than happy — from an exploratory observation into a
pre-registered confirmatory result.

### Repo layout

`GitHub/OMIT/` (Dropbox > Mac (2) > Documents > GitHub > OMIT)

| path | what |
|---|---|
| `3. Stimuli/OMIT3 Disclosure Ladder/` | the new study's deck, art, narration |
| `4. Data/csv files/` | four wide source CSVs, one per population × wave |
| `5. Analysis/code/OMIT_CLEAN.R` | the single analysis script for everything |
| `6. Writing & Presentations/` | manuscript + supplement, Quarto source |
| `GitHub/OMIT_raw_data_PRIVATE/` | sibling folder, name-bearing files kept out of the repo |

Nothing from OMIT3 or the cross-task analyses is committed to git yet.

---

## 2. The original studies

Six sub-studies across two child samples. **No child did all six** — this matters.

| | sample | studies |
|---|---|---|
| **Set A** | 57 children, 47 adults | Study 1, 3.A, 4.A |
| **Set B/C** | 105 children, 49 adults | Study 2, 3.B, 4.B |

- **Study 1** — a protagonist tells one classmate an emotion and another a fact. Who is
  the better friend? Plus two food items: a single ice cream cone (requires physical
  intimacy) and partitionable candy (prosociality).
- **Study 2** — friend vs. best friend: who gets told the emotion?
- **Study 3.A / 3.B** — is disclosure a way to *create* (3A) or *deepen* (3B) a friendship?
- **Study 4.A** — does the child disclose to their own mother vs. a friend's mother?
- **Study 4.B** — does a mother disclose to her child? (Direction reversed.)

Every item was asked once in a **sad** story and once in a **happy** story. So a measure
like "better friend" is not a condition — it is a question asked in both conditions
(`Better_Friend_sad`, `Better_Friend_happy`).

Analysis idiom throughout: Bayesian probit mixed models in brms, inference by whether
the 95% credible interval excludes zero, plus one-sided JZS Bayes factors against chance
in the pre-registered direction.

---

## 3. The cross-task analyses (added Sept 2026)

A JEPG reviewer asked whether relations between tasks within each sample had been
examined. They had not. They now are — `# CROSS-TASK RELATIONS WITHIN EACH CHILD SAMPLE ----`
in `OMIT_CLEAN.R`, and a matching section in `OMIT_supplement.qmd` (Tables S13–S15,
`figures/crosstask.png`). Writes `results/crosstask_*.csv`.

Per-child task score = emotion choices across that task's sad + happy trials (0–2).
Study 3.A is excluded from the Set A cross-task set (it asks about someone who is not
yet a friend); Study 3.B is kept in Set B/C (an existing friendship).

### What held up

1. **Reliable child-level variance across tasks.** Pooled probit
   `chose_emotion ~ item + (1|ID)`, item intercepts absorbing each task's difficulty.
   Set A ICC .16 [.07, .29]; Set B/C ICC .23 [.14, .32]. LOO favours the child term
   (Δelpd 10.5 and 40.2). Adding age changes nothing.

2. **In Set B/C that covariance is organised by relationship closeness, not by study.**
   The four relationship items are best friend and friend (Study 2) and own mother and
   friend's mother (Study 4.B) — two close ties, two distant ones, with disclosure
   running in opposite directions between the studies.

   | pair | matched on closeness? | r |
   |---|---|---|
   | best friend ~ own mother | both close | **.45** |
   | friend ~ friend's mother | both distant | **.37** |
   | best friend ~ friend's mother | no | .26 |
   | friend ~ own mother | no | .02 |

   Matched minus mismatched = **.27 [.10, .45]**. Read as: the individual difference is a
   view about how close a relationship must be before emotions are shared, not a
   preference for the emotion option as such. It is a gradient, not a switch.

3. **In Set A the two food items are independent of each other** (r = .02, BF₁₀ = 0.30 —
   positive evidence for independence) while each tracks the better-friend judgment
   (ice cream .34, candy .32). Each route to closeness works separately rather than
   forming one sharing factor. This is the result that motivates pre-registering the
   cone-versus-candy contrast in OMIT3.

### Traps — do not repeat these

- **The "gradient transfer" r = .34 is algebraically identical to the matched-minus-
  mismatched contrast.** `cov(BF−F, M−FM)` expands to exactly matched minus mismatched
  covariances. One finding in two dresses. Never report both as converging evidence.
- **"The closeness structure is specific to the sad condition" is NOT supported.** The gap
  is +.33 [.13, .52] in sad and +.09 [−.11, .29] in happy, but the interaction is
  +.24 [−.04, .53] — CI includes zero. Treating "credible in one condition, not the
  other" as a difference is the significant-vs-not-significant fallacy. Matched
  correlations are near-identical across conditions (.278 / .276); only the mismatched
  pairs differ (−.05 sad vs +.18 happy), which a stronger general response factor in
  happy (ICC .32 vs .16) explains without any condition-specific mechanism.
- **Cross-task correlations cannot test the "sad especially / single ice cream cone
  especially" hypothesis.** Those contrasts have CIs roughly 0.65–1.0 wide at N = 57.
  That hypothesis lives in the choice-*rate* analyses already in the paper.
- The latent sad–happy correlation is .92 [.66, 1.00] in Set B/C but only .75 [.04, .99]
  in Set A — the Set A number is uninformative, do not quote it.

---

## 4. OMIT3 — the current design

Four trials. Three measure a content against the impersonal fact, making **IF the common
baseline**; the fourth pits the two emotions directly.

| code | content | shown as |
|---|---|---|
| IF | impersonal fact | the animal alone in the bubble |
| PF | personal preference | the protagonist beside the animal |
| HE | happy emotion | the protagonist with the grin |
| SE | sad emotion | the protagonist with the tear |

Predicted ordering IF < PF < HE < SE.

| trial | pair | slides | protagonist |
|---|---|---|---|
| 1 | SE–HE | 4–15 | Casey |
| 2 | SE–IF | 16–26 | Percy (fox) — replicates Study 1, sad |
| 3 | HE–IF | 27–37 | Kendall (elephant) — replicates Study 1, happy |
| 4 | PF–IF | 38–48 | Jamie |

Each trial: establish both contents, selective disclosure to two classmates, memory
check, better-friend judgment, then ice cream and candy. **Twelve binary responses per
child** (4 better-friend + 8 food) — the same load Wave A carried.

### Design history — what was considered and dropped

- Started as **six trials** covering all pairwise comparisons. SE–PF and HE–PF were cut.
- **Consequence:** PF is never pitted against an emotion. Where a preference sits
  relative to happy or sad must be read off the two IF-anchored effect sizes — within
  child, but indirect. Trial 4 now rests entirely on the preference bubble reading
  correctly, which is the least-tested piece of the visual language.
- A **parent condition** (4.A and 4.B within-subject) was proposed and **dropped**. It
  would have turned the asymmetry claim from a between-wave comparison of an effect
  against a null into a within-child contrast. No child has ever done both 4.A and 4.B,
  since they ran in different waves. Dropping it leaves that weakness as it stands in
  the rejected manuscript. This was a deliberate choice, not an oversight.

### Deck state

`3. Stimuli/OMIT3 Disclosure Ladder/OMIT3 Four Trials A.pptx` — **51 slides**, cut from a
73-slide six-trial deck by deleting slides 16–26 and 38–48 (contiguous trial blocks, so
nothing inside a surviving trial was touched). Every kept slide verified against the
source on text, picture count, shape count, animation timing and speaker notes: zero
differences. 28 slides carry animation timing.

The deck was built by **editing** the original `OMIT Stim A.pptx`, not rebuilding it, so
layouts, bubbles, prohibition signs and click animations are inherited from decks that
already ran with children.

Three non-obvious build decisions:
- Every trial uses the **happy-block template**, because the original sad block showed a
  visible tear while the happy block used narration alone. That asymmetry did not matter
  until trial 1 put the two head to head.
- Expressions are **derived from one base figure** per character, so proportions do not
  shift between panels within a story.
- The preference item carries **no heart or affective marker** — that would reintroduce
  the emotion reading "favourite animal" exists to avoid.

### Narration

`narration-from-deck.md` and `.csv` — one row per slide, extracted from the deck's own
speaker notes so lines and slides cannot drift. 44 of 51 slides carry a line.

**`Claude outputs/narration-script.md` is superseded and must not be used.** It names
Avery and Logan as the protagonists of the two replication trials where the deck has
Percy and Kendall. The deck is correct — those are the original Study 1 characters.

### Known problem: the practice trial

The old script opened with a practice item (Nico, Frankie, Ollie — "click on the kid
wearing the red shirt") to teach the click response. It is **not in the deck**, and it
cannot be used as written: it identifies classmates by shirt colour, and Wave A already
excluded a child who was colourblind and could not do the colour-based response task.
There is no red figure in the character set either. Needs replacing with something
non-colour before any audio is generated.

---

## 5. OPEN — not yet decided

- **Matched adult sample?** Every OMIT study ran one. Adults were inconsistent on valence
  across the originals (no difference in Study 1, a difference in Study 2 and 3.B), which
  the discussion leaves unexplained. An adult trial 1 would address it, cheaply and online.
- **Target N and recruitment.** 80–100 children was discussed, roughly double Wave A.
  These are moderated Zoom sessions with screen sharing — 80–100 scheduled appointments,
  not an async batch.
- **Counterbalance scheme.** Must be settled before versions are generated, because it
  fixes what the analysis codes. Varies independently: which classmate gets which content,
  which animal plays fact vs. favourite, trial order. Originals used eight versions (A–H).
  The owl and rabbit each appear in more than one trial and should rotate across versions.
- **Narration delivery** — live experimenter or recorded audio. If recorded: generate at
  identical voice settings, then have two naive raters hear only the sad and happy
  establishment lines and guess the valence. If they can, the voice is carrying the
  manipulation and it must be regenerated. Trial 1 is what this would invalidate.
- **Does OMIT3 stand alone or join a resubmitted OMIT?**
- **Should the classroom establishments become full-width scenes,** like the lunch room
  and playground? The classroom is still the original small chalkboard plus desk.

---

## 6. Working conventions

- R analysis is **one big `*_CLEAN.R` per project** — `here()`, `ipak`, okabe-ito palette,
  priors A/B/C, `theme_study()` in Avenir Next, RStudio `----` section headers. Do not
  split it into a pipeline of small scripts.
- Manuscript and supplement are **Quarto**; statistics are pulled inline from
  `5. Analysis/results/*.csv` by helper functions, never hard-coded.
- brms fits are cached to `5. Analysis/results/models/*.rds` via `fit_or_load()`. **If an
  item set or formula changes, delete the stale `.rds` or it will silently load the old fit.**
- `ipak` at the top of `OMIT_CLEAN.R` tries to install missing packages. Eleven of its
  listed packages are absent from the current R 4.6.1 library; the analysis does not use
  them. When running non-interactively, shadow `install.packages` rather than let it
  install into the user library.
- Do not write contrastive framing ("unlike X…") or self-congratulatory notes into
  deliverables. State what is true; rationale goes in conversation.
