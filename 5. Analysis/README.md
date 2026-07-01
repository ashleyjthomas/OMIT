# OMIT — Analysis

Analysis pipeline for *Children's Expectations of Emotional Intimacy in Close
Relationships*. Reproduces the per-study percentages, Bayesian binomial tests,
Bayesian logistic mixed-effects models, and figures reported in the manuscript.

## How to run

Open **`OMIT.Rproj`** in RStudio (this anchors all `here::here()` paths), then:

```r
source(here::here("5. Analysis", "code", "OMIT_CLEAN.R"))
```

`OMIT_CLEAN.R` is the single main analysis script (written to match the lab's
`REL_KIN_CLEAN.R` conventions). It:

- loads the four raw wide files from `4. Data/csv files/` and reshapes them into
  one tidy frame per manuscript study (DV `chose_emotion`: 1 = emotion, 0 = fact);
- fits the Bayesian logistic mixed models per study (children + adults) and the
  children-only developmental (age) models, caching each to
  `results/models/*.rds` via `fit_or_load()` (so re-running is instant);
- writes the figures (`figures/*.png`) and the summary tables
  (`results/binomial_BF.csv`, `model_estimates.csv`) that the manuscript reads;
- writes model diagnostics (`results/model_diagnostics.csv`: max R̂, min ESS,
  divergences, Bayes R²) and posterior-predictive-check figures
  (`figures/diagnostics/pp_*.png`) for the supplement;
- includes an optional `run_sensitivity()` block (priors A/B/C).

Companion Quarto docs render from those outputs (every number pulled inline via
`here()`): **`OMIT_manuscript.qmd`** (the paper) and **`OMIT_supplement.qmd`**
(diagnostics, full posterior tables, counterbalancing/exclusions, sensitivity).

The earlier split scripts (`00_prep_data.R` … `04_age_figures.R`) are superseded
and kept in `code/_deprecated/` for reference.

Packages: loaded via the `ipak()` helper at the top of the script (installs any
that are missing). First run compiles + samples ~21 brms models (~15–25 min);
later runs load them from disk.

## What maps to what (the "which experiment is which" key)

The raw data live in `../4. Data/csv files/` as **4 wide files** — one per
population × data-collection wave. Each wide file packs several manuscript
"studies" into one sheet, under inconsistent abbreviations. `00_prep_data.R`
untangles them.

| Manuscript study | Wave | DV columns (children → adults) | Design |
|---|---|---|---|
| **Study 1** infer closeness | A | `Better_Friend`,`Ice_Cream`,`Candy` → `*_bf`,`*_ice_cream`,`*_candy` | emotion × measure |
| **Study 4A** child→mom/friend's-mom | A | `Mom`,`FriendMom` → `mom`,`friendmom` | emotion × relationship |
| **Study 3A** disclose to *create* | A | `New_Friend` → `nf` | emotion |
| **Study 4B** mom/friend's-mom→child | B/C | `Mom`,`FriendMom` → `mom`,`friendmom` | emotion × relationship |
| **Study 2** friend vs best friend | B/C | `Friend`,`BF` → `Friend`,`BF` | emotion × relationship |
| **Study 3B** disclose to *deepen* | B/C | `NF` → `nbf` | emotion |

Source files:
- Wave A: `OMIT_data_1.9.25.csv` (children, N=57), `OMIT-ADULT.csv` (adults, N=47)
- Wave B/C: `OMIT2_data_26.csv` (children, N=105), `OMIT2_ADULT.csv` (adults, N=49)

**Two naming traps** (handled in prep):
- `bf`/`Better_Friend` (Wave A) = **better** friend (a Study 1 outcome);
  `BF` (Wave B/C) = **best** friend (a Study 2 relationship level).
- `New_Friend`/`nf` (Wave A) = Study 3A (**create**);
  `NF`/`nbf` (Wave B/C) = Study 3B (**deepen**).

**DV coding everywhere:** `chose_emotion = 1` if the participant chose / was told
the **emotion**, `0` if the **fact**. The children Wave-B/C file stores answers
as text (`"sad"`/`"happy"` = emotion; an animal name or `"fact"` = fact) and is
recoded automatically.

## ⚠️ Open data issue: children Wave-B/C N

`OMIT2_data_26.csv` contains **105** children (S001–S105, 8 counterbalance
orders) but the manuscript reports **N = 75** for Studies 2B/2C/3B. All 105 are
currently included. Every *other* sample (Wave-A children, both adult samples)
reproduces the manuscript's numbers exactly, so the discrepancy is isolated to
this one file — likely a stale manuscript N or a missing exclusion list.
**Reconcile before submitting.**

## Outputs

```
data_clean/
  wide/            studyX_children.csv , studyX_adults.csv   (one row per participant)
  long/            studyX_children.csv , studyX_adults.csv   (tidy, split by population)
  long_combined/   studyX.csv                                (children+adults stacked; feeds analysis & figures)
  supplementary/   circles_* , warmup_*                      (Wave-A only; NOT in manuscript text)
results/
  binomial_BF.csv        per-cell % emotion, BF10, BF01, binomial p
  model_estimates.csv    per-model posterior median, 95% CI, % in ROPE(±0.1), pd
  models/*.rds           saved brms fits
figures/
  study1.png … study3B.png
```

## Notes / decisions

- **Binomial tests** use `BayesFactor::proportionBF` (JZS default prior). BF
  magnitudes track the manuscript closely; small differences reflect the prior
  scale (tune `rscale` if exact JASP defaults are wanted).
- **Mixed models** use `brms` defaults (`bernoulli`, `(1|ID)`). References:
  `emotion` = happy; `relationship` = the less-close tie (friend / friend's-mom).
  Study 4A reproduces the manuscript's reported estimates essentially exactly;
  where Study 2 differs, it is because the manuscript used cell-means/pairwise
  coding rather than treatment contrasts (same pattern, different parameterization).
- **Supplementary** circles/warmup measures (Wave A) are exported but not modeled
  here, as they are not reported in the manuscript text. Adult circle columns
  (`circles_orin/avery/cameron/riley`) lack a recorded fact/emotion key and are
  not exported.
- `code/` also contains the **original** exploratory scripts
  (`OMIT CODE for OSF.R`, `OMIT_ADULT.R`, `OMIT_Pilot.R`, `OMIT_Study1.R`). The
  `00–02` scripts are the cleaned, manuscript-aligned replacements.
```
