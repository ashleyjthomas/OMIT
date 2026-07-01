# ============================================================================
#  peek_models.R - load the fitted OMIT models for interactive inspection.
#
#  This does NOT fit or render anything. It just reads the .rds files that
#  OMIT_CLEAN.R already saved, so you can look at full model output while you
#  edit the manuscript.
#
#  Usage (in the RStudio console, with OMIT.Rproj open):
#     source(here::here("5. Analysis", "code", "peek_models.R"))
#  then explore any model by name, e.g.:
#     summary(models$s2c_child)
#     conditional_effects(models$s2c_child)
#     describe_posterior(models$s2c_child, ci = .95)
#     rope(models$s2c_child)
#
#  Also reloads the summary tables the manuscript uses:
#     binom   (one-sided binomial BFs)
#     ests    (model estimates: median / CI / ROPE / pd)
# ============================================================================

library(here)
suppressMessages({ library(brms); library(bayestestR); library(readr); library(dplyr) })

.mdir   <- here::here("5. Analysis", "results", "models")
.mfiles <- list.files(.mdir, pattern = "^OMIT_.*\\.rds$", full.names = TRUE)

# named list: "s2c_child", "s2a_adult", "s1bf_child", ...
models <- setNames(lapply(.mfiles, readRDS),
                   sub("^OMIT_", "", sub("\\.rds$", "", basename(.mfiles))))

# the summary tables (same ones the manuscript reads)
.res  <- here::here("5. Analysis", "results")
binom <- readr::read_csv(file.path(.res, "binomial_BF.csv"),   show_col_types = FALSE)
ests  <- readr::read_csv(file.path(.res, "model_estimates.csv"), show_col_types = FALSE)

cat("Loaded", length(models), "models into `models`:\n")
print(names(models))
cat("\nAlso loaded tables: `binom` (binomial BFs), `ests` (model estimates).\n")
cat("Try:  summary(models$s2c_child)   |   describe_posterior(models$s2c_child)\n")
