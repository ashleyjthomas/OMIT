# OMIT3 — four-trial design and counterbalance spec (18 Oct 2026)

Supersedes the counterbalance section of the 8 Oct handoff. Companion file: `OMIT3_versions.csv`
(one row per version × trial; this is what the version generator and the analysis code read).

## Trials

| trial | contrast | protagonist | classmates | animals | isolates |
|---|---|---|---|---|---|
| SH | sad emotion vs happy emotion | Casey | Blake, Morgan | none | valence, content type constant |
| SF | sad emotion vs fact | Percy | Avery, Orin | fox | replication of Study 1, sad |
| HF | happy emotion vs fact | Kendall | Riley, Cameron | elephant | replication of Study 1, happy |
| PF | personal preference vs fact | Jamie | Elliot, Parker | owl, rabbit | self-relevance without emotion |

"Higher-rung content" = sad (SH), the emotion (SF, HF), the preference (PF). Every forced choice is
scored 1 when the child picks the classmate who was told the higher-rung content.

Per trial: establish both contents → classmate 1 encounter (meets; first what was NOT told, then what was told) →
classmate 2 encounter (the reverse contents, same not-told-then-told order) → memory check (which classmate was told the higher-rung
content) → "Who do you think [name] is better friends with?" (+ Why?) → single ice cream cone → partitionable candy.
No consent slide in the CHS build: CHS frames handle consent.

## Practice block (deck slides 5–9, before trial 1)

New characters, used nowhere else: **Sam** (olive, protagonist), **Quinn** (lavender, Sam's *best friend*),
**Rowan** (dark green, Sam's *friend*). Sam is introduced alone, then flanked by Quinn and Rowan with the
roles named in the narration. Three forced choices between Quinn and Rowan follow, in a fixed order:

1. **Ball** — one of the two is holding a ball; "Which one is holding a ball?" Response training only
   (teaches the two-picture click); has a correct answer, scored for exclusion like a memory check.
1b. **Better friends** — "Who do you think Sam is better friends with: Quinn, Sam's best friend, or Rowan, Sam's friend?"
   Wording check for the primary DV: with the roles just stated, children should pick the best friend. Expected: best friend.
2. **Juice box with one straw** — "Who would Sam want to share a juice box with one straw with? Why?"
   Manipulation check for the physical-intimacy item: addresses the reviewer worry that children do not
   read a single-portion item as intimate. Expected: best friend.
3. **Cookies** (divisible) — "Who would Sam want to share cookies with? Why?" Divisible comparison item;
   no directional prediction, parallels candy in the main trials.

Counterbalanced across versions (see CSV columns `practice_best_friend_side`, `practice_ball_holder`):
best friend on the left in odd versions (V1, 3, 5, 7), right in even; the ball is held by the friend in
V1, V4, V6, V7 and by the best friend in V2, V3, V5, V8, so the first "correct" click is the best friend
in half the versions. Deck A = V1 layout (best friend left, friend holds ball).
Prop images: `props/ball.png`, `props/juicebox_one_straw.png`, `props/cookies.png` (600×600, flat outline style).

## Eight versions

Two factors define the versions; three more nest inside them so every level appears in 4 of 8.

1. **Trial order** — Williams square, balanced for first-order carryover; SH appears once in each position.
   V1/V5: SH SF PF HF · V2/V6: SF HF SH PF · V3/V7: HF PF SF SH · V4/V8: PF SH HF SF
2. **Which classmate gets the higher-rung content** — pattern P (V1–4): classmate 1 on positions 1 and 3,
   classmate 2 on positions 2 and 4; pattern Q (V5–8): the reverse. Within a child, the higher-rung
   content is told first on two trials and last on two; across children, each trial's higher-rung
   content goes to each classmate in 4 of 8 versions. This is what the A/B narration recordings map onto
   (A = higher rung to classmate 1, B = to classmate 2).

Nested:
- **SH emotion order** — sad established first in V1, V2, V5, V6; happy first in V3, V4, V7, V8.
- **SH scene** — sad at lunch / happy at recess in V1, V3, V5, V7; sad at recess / happy at lunch in V2, V4, V6, V8.
  Narration names the place ("At lunch, Casey felt sad, and didn't know why. At recess, Casey felt happy…").
  Requires two new bubble composites: sad Casey on the playground, happy Casey in the lunch room.
- **PF animal roles** — owl is the favourite (rabbit the fact) in V1, V4, V6, V7; reversed in V2, V3, V5, V8.

- **Sharing-item order** — ice cream cone before candy in V1, V3, V6, V8; candy first in V2, V4, V5, V7 (constant within a child;
  balanced across trial orders and across patterns P/Q). CSV column `dv_item_first`. Study 1 always asked ice cream first.

Fixed across versions: classmate 1 on the left; better-friends question always first.

## Primary-DV wording (for the preregistration)

Study 1 asked "Who do you think is the better friend?" (confirmed by Megan Richardson, 19 Oct 2026). OMIT3 asks
"Who do you think [protagonist] is better friends with?" This is a deliberate change. The unanchored form invites a
reading about the classmates' conduct toward the protagonist ("who was nicer?"), whereas both classmates behave
identically in every story and only what they were told differs; "better friends with" names the relationship as the
object of the judgment, which is the construct the study is about (closeness inferred from disclosure), and matches the
wording already used in the Study 1 Results ("who was better friends with the protagonist"). The practice item
"Who do you think Sam is better friends with?" checks that children map the phrase onto the best-friend role. The
change will be noted in Methods when OMIT3 is reported alongside Study 1.

## Variables the data must carry (per trial)

version, position, trial, dv_item_first, practice_best_friend_side, practice_ball_holder, practice_ball_correct,
practice_straw (1 = best friend), practice_cookies (1 = best friend), higher_rung_told_to (classmate 1/2), higher_rung_classmate (name),
narration_recording (A/B), sh_emotion_first, sh_sad_scene, pf_favourite_animal, memory_check_correct (first answer; wrong answers are corrected and re-asked),
better_friend (1 = higher rung), icecream (1 = higher rung), candy (1 = higher rung), why_text.
Participant: age_days, gender, version, modality, exclusion_flag.

## Still to settle before the versions are generated

- Whether "Why?" audio is recorded on CHS for better friend only, or for all three DVs.
- Tear size: keeping as is (decided 18 Oct).
- Ice cream wording (CHS): "Who do you think [P] would want to share a single ice cream cone with, by licking the ice cream cone?"
- Done 18 Oct: "Jamie found out their favourite animal is…"; "a single ice cream cone" in all four trials;
  second memory check per trial; not-told-then-told order in every encounter (changed 21 Oct from told-then-not-told); practice block added.
