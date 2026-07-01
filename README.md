# Children's Expectations of Emotional Intimacy in Close Relationships

Data, analysis code, materials, and manuscript source for a set of studies on how
children (ages 6–9) and adults reason about the link between **emotional
disclosure** (revealing a sad emotion rather than a neutral fact) and **social
closeness**.

> **Note:** Author names and other identifying information have been removed from
> this repository for anonymous peer review.

## Overview of the studies

The project comprises four studies (six sub-studies), all using a forced-choice
paradigm in which the dependent variable is whether a participant expects (or
infers from) the disclosure of an **emotion** versus a **fact**:

- **Study 1 — Closeness from disclosure.** Given that a character discloses an
  emotion to one person and a fact to another, who is the closer friend? (Also:
  who would they share a single ice cream cone or partitionable candy with?)
- **Study 2 — Disclosure from closeness.** Given a friend vs. a best friend, who
  is expected to be told the emotion vs. the fact?
- **Study 3 — Disclosure to build closeness.** Is disclosing an emotion seen as a
  way to *create* (3A) or *deepen* (3B) a friendship?
- **Study 4 — Asymmetric relationships.** Does a child disclose to their own
  mother vs. a friend's mother (4A)? Does a mother disclose to her child (4B)?

## Repository structure

```
1. Preregistration & Ethics/   Placeholders (pre-registrations linked in the manuscript)
2. Materials/                  Study script
3. Stimuli/                    Stimulus files
4. Data/                       De-identified data
   ├── csv files/              Analysis input files (the code reads these)
   └── OMIT data dictionary.xlsx
5. Analysis/
   ├── code/OMIT_CLEAN.R       Single analysis script (see also 5. Analysis/README.md)
   ├── results/                Model estimates + Bayes factors (CSV) and cached fits
   │   └── models/*.rds        Cached brms model fits (so results reproduce without refitting)
   └── figures/                Figures used in the manuscript and supplement
6. Writing & Presentations/
   ├── OMIT_manuscript.qmd     Manuscript source (Quarto)
   ├── OMIT_supplement.qmd     Supplement source (diagnostics, full posteriors, robustness)
   ├── references.bib, apa.csl, apa-reference.docx
   └── *_rendered.docx         Rendered outputs
OMIT.Rproj                     RStudio project (open this to set the working directory)
LICENSE
```

## Data

Data files in `4. Data/csv files/` are **de-identified**: direct and indirect
identifiers from the raw survey exports (e.g., IP addresses and platform
participant IDs) have been removed. The analysis assigns its own anonymous
participant IDs. Column meanings are documented in `OMIT data dictionary.xlsx`.

| File | Sample |
|---|---|
| `OMIT_data_1.9.25.csv` | Children, Wave A (Studies 1, 3A, 4A) |
| `OMIT-ADULT.csv` | Adults, Wave A |
| `OMIT2_data_26.csv` | Children, Wave B/C (Studies 2, 3B, 4B) |
| `OMIT2_ADULT.csv` | Adults, Wave B/C |

The dependent variable throughout is `chose_emotion` (1 = emotion, 0 = fact).

## Reproducing the analysis

Developed with **R 4.3.1**. Analyses use Bayesian mixed-effects models fit with
[**brms**](https://paul-buerkner.github.io/brms/) (which requires a working Stan
toolchain / C++ compiler).

1. Open `OMIT.Rproj` in RStudio (this sets the working directory; all paths use
   `here::here()`).
2. Run `5. Analysis/code/OMIT_CLEAN.R`. It reshapes the raw files into one tidy
   frame per study, fits the models (caching them to `5. Analysis/results/models/*.rds`),
   and writes the summary tables (`5. Analysis/results/*.csv`) and figures
   (`5. Analysis/figures/`). The cached `.rds` fits are included in this
   repository, so the tables and figures can be regenerated without refitting
   every model.
3. Render the manuscript and supplement (they pull statistics inline from the
   result tables):

   ```r
   quarto::quarto_render("6. Writing & Presentations/OMIT_manuscript.qmd")
   quarto::quarto_render("6. Writing & Presentations/OMIT_supplement.qmd")
   ```

The script installs any missing R packages on first run (via a small helper at
the top of `OMIT_CLEAN.R`). Rendering the manuscript/supplement requires
[Quarto](https://quarto.org/); the PDF supplement additionally requires a LaTeX
installation (e.g., TinyTeX).

## Pre-registration

The studies' designs and primary analyses were pre-registered. *(Pre-registration
links are omitted here for anonymous review and will be restored in the published
version.)*

## License

See [`LICENSE`](LICENSE).
