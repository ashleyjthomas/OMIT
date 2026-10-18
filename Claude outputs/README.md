# Disclosure-ladder stimuli (OMIT3)

Built from the art in `3. Stimuli/OMIT Stimuli` and `OMIT2 Stimuli`. Nothing here is new
artwork: the characters are the original neutral figures, the props are the original props,
and the two derived expressions are composited from the original tear and the original smile.

## Why the expressions are derived rather than reused

The original decks contain three separate drawings per character — a neutral figure, a
figure with a tear, and a figure with a grin — and they are drawn at different head-to-body
proportions. That was invisible in the original design, because sad and happy never appeared
in the same story. In the new design Trial 1 puts them in one story (Casey feels sad in the
morning and happy in the afternoon), so a proportion change would read as the character
changing size between panels.

So all three expressions are now composited onto the **same** neutral base:

- `*_neutral.png` — the original figure, untouched
- `*_sad.png` — the same figure plus the original teardrop, beside the right eye, no mouth
- `*_happy.png` — the same figure plus the original grin, cropped from `magenta_happy`
  and scaled by eye separation

Geometry is therefore identical across all three, and identical across all 18 colours.
The sad convention is unchanged from the original decks: tear only, no mouth.

## Contents

| Folder | Files | What |
|---|---|---|
| `characters_derived/` | 54 | 18 colours × {neutral, sad, happy} |
| `icons_final/` | 27 | bubble contents (both stimulus sets), prohibition sign |
| `props/` | 17 | school, bus, desk, chalkboard, ice cream, candy, question mark, banners, animals |
| `storyboard/` | 7 | worked example of Trial 2 (Rowan, SE vs PF) |

`roster.png`, `expressions.png`, `storyboard_sheet.png` are contact sheets for review.

## Character assignment

| Trial | Pair | Protagonist | Colour | Classmates | Colours |
|---|---|---|---|---|---|
| 1 | SE–HE | Casey | purple | Morgan, Blake | orange, mint |
| 2 | SE–PF | Rowan | blue | Jesse, Kai | peach, darkgreen |
| 3 | SE–IF | Avery | brown | Toby, Sam | lightblue, yellowgreen |
| 4 | HE–PF | Devon | darkteal | Harper, Quinn | lavender, darkbrown |
| 5 | HE–IF | Logan | magenta | Bailey, Reese | olive, periwinkle |
| 6 | PF–IF | Jamie | slate | Elliot, Parker | orange2, navy |

Colours are paired so the two classmates in a trial are never close in hue or lightness,
and neither is close to the protagonist. All names are gender-neutral and the figures carry
no gender cues, so protagonist gender does not need counterbalancing.

## Bubble contents

Following the original convention, bubbles contain **pictures, not text**:

- `content_IF_fox.png` — the animal fact: the animal alone
- `content_PF_<name>_owl.png` — the favourite animal: the protagonist *beside* the animal
- `content_SE_<name>.png` — a small copy of that protagonist wearing the tear
- `content_HE_<name>.png` — a small copy of that protagonist wearing the grin
- `prohibition.png` — laid over a bubble to show what was *not* told, as in the original slides

**No heart, and no affective marker of any kind on the preference item.** A heart says
"loves owls", which is exactly the emotion reading that "favourite animal" was chosen to
avoid — it would blur PF into the emotion conditions. Instead the set uses a distinction
already implicit in the original decks: **content about the world shows the thing; content
about oneself shows oneself.** The emotion bubbles already contain a small copy of the
protagonist wearing the state, so the preference bubble shows the protagonist beside the
animal. The world-versus-own-mind contrast is then visible in the pictures rather than
asserted by a symbol.

This relies on the bubble picture indexing the *topic* rather than the proposition, which is
how the original system already works: the fox picture does not depict "moves without making
any sound" either — the narration carries that, and the memory check only ever asks which
classmate was told "about the foxes".

**Fox and owl, not fox and rabbit.** The rabbit and elephant in the original decks are
detailed illustrations while the fox is flat vector. Trial 6 puts the fact animal and the
favourite animal in the same story, so a style difference there would be confounded with
content type. Fox and owl are the two flat cartoon animals in the set. Set B swaps their
roles (`content_IF_owl.png`, `content_PF_fox_favourite.png`) so an animal-specific effect
can't masquerade as a content effect.

## Open items

- Whether "protagonist beside the animal" reads as *favourite* rather than *saw one* is
  worth checking in piloting. The alternative built and discarded was the protagonist with a
  small thought bubble containing the animal, which reads more clearly as a mental state but
  nests a thought bubble inside the classroom panel's thought bubble.
- No frown was added to the sad figure, per the original convention. Worth knowing that
  sadness is therefore marked by a tear and happiness by a mouth — different feature
  channels — and Trial 1 compares them directly.
- Scene composition in the storyboard is a reconstruction of the original layout, not a
  pixel match to the decks.
