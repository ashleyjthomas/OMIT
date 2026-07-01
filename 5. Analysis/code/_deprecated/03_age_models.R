# ============================================================================
# OMIT — 03_age_models.R
# Developmental (age) models for every study: each study's condition structure
# crossed with continuous AGE, plus participant random intercept.
#
#   Study 1  better-friend : chose_emotion ~ emotion * age_c + (1|ID)
#   Study 1  food-sharing  : chose_emotion ~ emotion * measure * age_c + (1|ID)
#   Study 2A/2B/2C         : chose_emotion ~ emotion * relationship * age_c + (1|ID)
#   Study 3A/3B            : chose_emotion ~ emotion * age_c + (1|ID)
#
# CHILDREN ONLY. Adults are excluded because age is not recorded for the Wave-A
# adult sample (Studies 1, 2A, 3A); for a uniform "all studies" developmental
# analysis we therefore use the child samples (6-9 yrs), where age varies and is
# the question of interest. (Wave-B/C adult age models for 2B/2C/3B could be
# added separately on request.)
#
# age_c = age centered on the child-sample mean, so the non-age terms are
# interpreted at the mean age and the `:age_c` terms are the developmental slopes.
#
# Run after 00_prep_data.R. Writes results/age_model_estimates.csv and
# results/models/age_<study>.rds.
# ============================================================================

suppressMessages({ library(dplyr); library(tidyr); library(readr); library(brms); library(bayestestR) })

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

read_children <- function(s) {
  d <- read_csv(file.path(comb, paste0(s, ".csv")), show_col_types = FALSE) |>
    filter(population == "child", !is.na(age))
  d$age_c <- d$age - mean(d$age, na.rm = TRUE)        # center within child sample
  if ("emotion" %in% names(d))      d$emotion <- factor(d$emotion, levels = c("happy","sad"))
  if ("relationship" %in% names(d)) {
    ref <- intersect(c("friendmom","friend"), unique(d$relationship))[1]
    d$relationship <- relevel(factor(d$relationship), ref = ref)
  }
  if ("measure" %in% names(d))      d$measure <- factor(d$measure)
  d$ID <- factor(d$ID)
  d
}

fit_age <- function(d, formula, tag) {
  message("    fitting: ", tag, "  (N children = ", n_distinct(d$ID),
          ", mean age = ", round(mean(d$age), 2), ")")
  m <- brm(formula, data = d, family = bernoulli(),
           iter = BRMS_ITER, warmup = BRMS_WARMUP, chains = BRMS_CHAINS,
           cores = min(BRMS_CHAINS, parallel::detectCores()),
           save_pars = save_pars(all = TRUE), refresh = 0, silent = 2, seed = 123)
  saveRDS(m, file.path(mod_dir, paste0("age_", tag, ".rds")))
  dp <- describe_posterior(m, ci = .95, rope_range = c(-0.1, 0.1), rope_ci = 1,
                           test = c("rope","pd"))
  as.data.frame(dp) |>
    transmute(term = Parameter, median = round(Median, 2),
              CI_low = round(CI_low, 2), CI_high = round(CI_high, 2),
              pct_in_ROPE = round(100 * ROPE_Percentage, 1), pd = round(pd, 3)) |>
    mutate(model = paste0("age_", tag), .before = 1)
}

recipes <- list(
  study1_bf   = list(s = "study1",  f = chose_emotion ~ emotion * age_c + (1|ID),
                     sub = function(d) filter(d, measure == "better_friend")),
  study1_food = list(s = "study1",  f = chose_emotion ~ emotion * measure * age_c + (1|ID),
                     sub = function(d) filter(d, measure %in% c("ice_cream","candy"))),
  study2A     = list(s = "study2A", f = chose_emotion ~ emotion * relationship * age_c + (1|ID), sub = identity),
  study2B     = list(s = "study2B", f = chose_emotion ~ emotion * relationship * age_c + (1|ID), sub = identity),
  study2C     = list(s = "study2C", f = chose_emotion ~ emotion * relationship * age_c + (1|ID), sub = identity),
  study3A     = list(s = "study3A", f = chose_emotion ~ emotion * age_c + (1|ID), sub = identity),
  study3B     = list(s = "study3B", f = chose_emotion ~ emotion * age_c + (1|ID), sub = identity)
)

message("Fitting children age models ...")
est <- list()
for (nm in names(recipes)) {
  r <- recipes[[nm]]
  d <- r$sub(read_children(r$s))
  est[[nm]] <- tryCatch(fit_age(d, r$f, nm),
                        error = function(e){ message("      ! ", nm, ": ", conditionMessage(e)); NULL })
}
age_tbl <- bind_rows(est)
write_csv(age_tbl, file.path(res_dir, "age_model_estimates.csv"))
print(as.data.frame(age_tbl), row.names = FALSE)
message("Done. Estimates in results/age_model_estimates.csv ; models in results/models/age_*.rds")
