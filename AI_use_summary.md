# Generative AI Use: Detailed Account

This document details the use of a generative AI assistant (Claude, Opus 4.8;
Anthropic) in the preparation of this project, in the interest of transparency.

## Framing

All scientific work was carried out by the authors: they designed and
pre-registered the studies, collected the data, chose the theoretical framing
and every citation, made all statistical and interpretive decisions, and wrote
or revised the final text. The AI assistant's contribution was limited to
implementation and mechanical support — writing code to run the analyses the
authors specified, producing figures to the authors' design, drafting rough
scaffolding the authors then revised, applying formatting, and executing
repository changes the authors directed.

## 1. Data preparation & de-identification

- Wrote code to reshape the four wide source files into the per-study tidy
  structure the authors defined.
- Executed the de-identification the authors directed: the authors removed the
  IP addresses; the assistant stripped the participant-ID and response-ID
  columns (which the analysis does not use) and moved raw files out of the
  repository, per the authors' instructions.

## 2. Analysis code (`OMIT_CLEAN.R`)

- Wrote and reorganized the script to implement the pre-registered analysis
  plan — the model specifications, one-sided hypothesis directions, and
  inference criteria were the authors'.
- Implemented the closeness ("circles") analysis for the supplement. The
  scale's coding direction was initially reversed and was corrected after
  checking it against the warm-up items and choice data.
- Implemented the gender robustness check and diagnostics, with model caching so
  results reproduce.

## 3. Statistical models

- Fit the pre-registered Bayesian models and extracted the numerical summaries
  (posterior medians/credible intervals, Bayes factors, Bayesian R², and
  convergence diagnostics). Model choice and all interpretation were the
  authors'.

## 4. Figures

- Produced figures to the authors' specifications and combined them into the
  per-study composites at the authors' request.
- Processed the authors' overview figure into high-resolution exports.

## 5. Manuscript text

- Provided rough first-draft scaffolding for a few passages — a significance
  statement, a Constraints on Generality paragraph, a candidate passage
  relating the findings to prior theory, and the AI-use disclosure — which the
  authors rewrote and finalized. The framing, interpretation, and final wording
  are the authors'.
- Mechanical and editorial help only: reconciled two diverging drafts, inserted
  bibliography entries and citation tags for references the authors supplied and
  selected, fixed typos and formatting, and flagged numbers for the authors to
  verify.

## 6. Supplement

- Implemented the supplement sections (closeness measure, developmental change,
  gender robustness, model diagnostics), following the authors' decisions about
  what belonged where.

## 7. Bibliography

- Built the reference database from references the authors provided, added the
  citation style, and converted in-text citations to the markup format.
  Reference selection was entirely the authors'.

## 8. Journal formatting

- Applied journal/APA formatting mechanically (line numbers, double-spacing,
  section structure) and set up the rendering pipeline. Flagged guideline items;
  the authors decided what to include.

## 9. Cover letter & submission materials

- Drafted cover-letter scaffolding with the required section headings; the
  authors supplied the reviewer and editor names and the substantive content.
  Added the pre-registration documents to the repository.

## 10. Repository & anonymization

- Executed the repository decisions the authors made: the ignore rules, keeping
  the model caches, de-identifying the data, rewriting history, anonymizing the
  manuscript and repository for masked review, and the README.

## 11. Advisory

- Explained the modeling approach (the relationship between probit and binomial
  models) and the generative-AI disclosure policy and its trade-offs.

---

*Note: this account reconstructs work carried out across several sessions and
may not be exhaustive; it is provided as a good-faith description of how the
generative AI assistant was used.*
