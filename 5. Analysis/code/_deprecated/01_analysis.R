# ============================================================================
# OMIT — 01_analysis.R
# Analyses matching the manuscript:
#   (A) Bayesian binomial tests vs chance (0.5) for every cell  -> BF10 / BF01
#   (B) Bayesian logistic mixed-effects models (brms, default priors), with
#       participant as a random intercept, summarised by posterior median,
#       95% credible interval, and % in the ROPE (-0.1, 0.1).
#
# Run 00_prep_data.R first. Reads from data_clean/long_combined/.
# Writes results/binomial_BF.csv, results/model_estimates.csv, results/models/*.rds
#
# NOTE: the brms models compile + sample and take a few minutes total.
#       Set RUN_BRMS <- FALSE to produce only the (fast) binomial-test table.
# ============================================================================

suppressMessages({
  library(dplyr); library(tidyr); library(readr); library(stringr)
  library(BayesFactor); library(brms); library(bayestestR)
})

RUN_BRMS <- TRUE          # set FALSE to skip the (slow) Bayesian mixed models
BRMS_ITER <- 4000; BRMS_WARMUP <- 1000; BRMS_CHAINS <- 4
set.seed(123)

get_script_dir <- function() {
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
    return(dirname(rstudioapi::getActiveDocumentContext()$path))
  a <- commandArgs(FALSE); f <- sub("^--file=", "", a[grep("^--file=", a)])
  if (length(f)) return(dirname(normalizePath(f))); getwd()
}
proj    <- normalizePath(file.path(get_script_dir(), "..", ".."))
comb    <- file.path(proj, "5. Analysis", "data_clean", "long_combined")
res_dir <- file.path(proj, "5. Analysis", "results")
mod_dir <- file.path(res_dir, "models")
dir.create(mod_dir, recursive = TRUE, showWarnings = FALSE)

studies <- c("study1","study2A","study2B","study2C","study3A","study3B")
read_study <- function(s) read_csv(file.path(comb, paste0(s, ".csv")), show_col_types = FALSE)

# ============================================================================
# (A) BAYESIAN BINOMIAL TESTS vs CHANCE  (default JZS prior via BayesFactor)
# ============================================================================
# proportionBF tests p != 0.5; BF10 = evidence for "differs from chance".
cell_bf <- function(d) {
  grp <- intersect(c("population","measure","relationship","emotion"), names(d))
  d %>% group_by(across(all_of(grp))) %>%
    summarise(
      n      = sum(!is.na(chose_emotion)),
      k_emo  = sum(chose_emotion, na.rm = TRUE),
      pct_emo = round(100 * k_emo / n, 1),
      BF10   = round(as.numeric(as.vector(proportionBF(k_emo, n, p = 0.5))), 2),
      .groups = "drop") %>%
    mutate(BF01 = round(1 / BF10, 2),
           p_binom = round(sapply(seq_len(n()), function(i)
                       binom.test(k_emo[i], n[i], 0.5)$p.value), 4))
}

message("(A) Bayesian binomial tests vs chance ...")
binom_tbl <- bind_rows(lapply(studies, function(s)
  cell_bf(read_study(s)) %>% mutate(study = s, .before = 1)))
write_csv(binom_tbl, file.path(res_dir, "binomial_BF.csv"))
print(as.data.frame(binom_tbl), row.names = FALSE)

# ============================================================================
# (B) BAYESIAN LOGISTIC MIXED-EFFECTS MODELS
# ============================================================================
# Model structure per manuscript:
#   Study 1  better-friend : chose_emotion ~ emotion + (1|ID)
#   Study 1  food-sharing  : chose_emotion ~ emotion * measure + (1|ID)   (ice_cream vs candy)
#   Study 2A/2B/2C         : chose_emotion ~ emotion * relationship + (1|ID)
#   Study 3A/3B            : chose_emotion ~ emotion + (1|ID)
# Each fit separately for children and adults. Default brms priors.

set_factors <- function(d) {
  if ("emotion" %in% names(d))
    d$emotion <- factor(d$emotion, levels = c("happy","sad"))      # ref = happy
  if ("relationship" %in% names(d)) {
    lv <- unique(d$relationship)
    ref <- intersect(c("friendmom","friend"), lv)[1]               # ref = less-close tie
    d$relationship <- relevel(factor(d$relationship), ref = ref)
  }
  if ("measure" %in% names(d))
    d$measure <- factor(d$measure)
  d$ID <- factor(d$ID)
  d
}

fit_one <- function(d, formula, tag) {
  d <- set_factors(d)
  message("    fitting: ", tag)
  m <- brm(formula, data = d, family = bernoulli(),
           iter = BRMS_ITER, warmup = BRMS_WARMUP, chains = BRMS_CHAINS,
           cores = min(BRMS_CHAINS, parallel::detectCores()),
           save_pars = save_pars(all = TRUE), refresh = 0, silent = 2,
           seed = 123)
  saveRDS(m, file.path(mod_dir, paste0(tag, ".rds")))
  dp <- describe_posterior(m, ci = .95, rope_range = c(-0.1, 0.1),
                           rope_ci = 1, test = c("rope","pd"))
  as.data.frame(dp) %>%
    transmute(term = Parameter, median = round(Median, 2),
              CI_low = round(CI_low, 2), CI_high = round(CI_high, 2),
              pct_in_ROPE = round(100 * ROPE_Percentage, 1), pd = round(pd, 3)) %>%
    mutate(model = tag, .before = 1)
}

# model recipe: study -> list(formula, subset)  applied within each population
recipes <- list(
  study1_bf    = list(s="study1", f = chose_emotion ~ emotion + (1|ID),
                      sub = function(d) filter(d, measure == "better_friend")),
  study1_food  = list(s="study1", f = chose_emotion ~ emotion * measure + (1|ID),
                      sub = function(d) filter(d, measure %in% c("ice_cream","candy"))),
  study2A      = list(s="study2A", f = chose_emotion ~ emotion * relationship + (1|ID),
                      sub = identity),
  study2B      = list(s="study2B", f = chose_emotion ~ emotion * relationship + (1|ID),
                      sub = identity),
  study2C      = list(s="study2C", f = chose_emotion ~ emotion * relationship + (1|ID),
                      sub = identity),
  study3A      = list(s="study3A", f = chose_emotion ~ emotion + (1|ID),
                      sub = identity),
  study3B      = list(s="study3B", f = chose_emotion ~ emotion + (1|ID),
                      sub = identity)
)

if (RUN_BRMS) {
  message("(B) Bayesian logistic mixed-effects models ...")
  est <- list()
  for (nm in names(recipes)) {
    r <- recipes[[nm]]; d0 <- read_study(r$s)
    for (pop in c("child","adult")) {
      dd <- r$sub(filter(d0, population == pop))
      tag <- paste0(nm, "_", pop)
      est[[tag]] <- tryCatch(fit_one(dd, r$f, tag),
                             error = function(e){message("      ! ", tag, ": ", conditionMessage(e)); NULL})
    }
  }
  model_tbl <- bind_rows(est)
  write_csv(model_tbl, file.path(res_dir, "model_estimates.csv"))
  print(as.data.frame(model_tbl), row.names = FALSE)
  message("Models saved to results/models/ ; estimates in results/model_estimates.csv")
} else {
  message("(B) skipped (RUN_BRMS = FALSE).")
}
message("Done.")
