# ============================================================================
# OMIT — 04_age_figures.R
# Plots for the developmental (age) models from 03_age_models.R:
# predicted P(choose emotion) across age (children) with 95% credible ribbons,
# by emotion condition and (where present) relationship / measure. Adds:
#   * individual children's raw responses (jittered points)
#   * a dashed horizontal line at the ADULT observed mean per condition (labelled)
#   * a colourblind-safe palette (Okabe-Ito)
#
# Run after 03_age_models.R. Writes figures/age_<study>.png.
# ============================================================================

suppressMessages({ library(dplyr); library(readr); library(ggplot2); library(ggeffects); library(brms); library(stringr) })

get_script_dir <- function() {
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
    return(dirname(rstudioapi::getActiveDocumentContext()$path))
  a <- commandArgs(FALSE); f <- sub("^--file=", "", a[grep("^--file=", a)])
  if (length(f)) return(dirname(normalizePath(f))); getwd()
}
proj    <- normalizePath(file.path(get_script_dir(), "..", ".."))
comb    <- file.path(proj, "5. Analysis", "data_clean", "long_combined")
mod_dir <- file.path(proj, "5. Analysis", "results", "models")
fig_dir <- file.path(proj, "5. Analysis", "figures")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# observed adult means per cell (for the reference lines)
B <- read_csv(file.path(proj, "5. Analysis", "results", "binomial_BF.csv"), show_col_types = FALSE) |>
  mutate(cell = coalesce(relationship, measure))

# Office palette to match the bar plots: sad = blue, happy = orange (colourblind-safe)
COND_COLS <- c(Sad = "#4472C4", Happy = "#ED7D31")

pretty <- c(better_friend="Better friend", ice_cream="Ice cream", candy="Candy",
            create="Create relationship", deepen="Deepen relationship",
            mom="Mom", friendmom="Friend's mom", friend="Friend", bestfriend="Best friend")
titles <- c(study1_bf  ="Study 1 (better friend): emotion choice by age",
            study1_food="Study 1 (food sharing): emotion choice by age",
            study2A    ="Study 2.A: emotion choice by age",
            study2B    ="Study 2.B: emotion choice by age",
            study2C    ="Study 2.C: emotion choice by age",
            study3A    ="Study 3.A: emotion choice by age",
            study3B    ="Study 3.B: emotion choice by age")
src  <- c(study1_bf="study1", study1_food="study1", study2A="study2A", study2B="study2B",
          study2C="study2C", study3A="study3A", study3B="study3B")
grp3 <- c(study1_bf=NA, study1_food="measure", study2A="relationship", study2B="relationship",
          study2C="relationship", study3A=NA, study3B=NA)
# which cells belong to each tag (to pick the right adult means / raw rows)
cells_for <- list(study1_bf="better_friend", study1_food=c("ice_cream","candy"),
                  study2A=c("mom","friendmom"), study2B=c("mom","friendmom"),
                  study2C=c("friend","bestfriend"), study3A="create", study3B="deepen")

omit_theme <- theme_minimal(base_size = 13) +
  theme(legend.position = "bottom", legend.box = "vertical",
        plot.title = element_text(face = "bold", size = 13),
        strip.text = element_text(face = "bold"), panel.grid.minor = element_blank())

titlecase_emo <- function(x) factor(str_to_title(as.character(x)), levels = c("Sad","Happy"))

make_age_fig <- function(tag) {
  m   <- readRDS(file.path(mod_dir, paste0("age_", tag, ".rds")))
  g3  <- grp3[[tag]]
  st  <- src[[tag]]
  cls <- cells_for[[tag]]

  # children raw data (for points) and centering mean age
  raw <- read_csv(file.path(comb, paste0(st, ".csv")), show_col_types = FALSE) |>
    filter(population == "child", !is.na(age))
  raw$cell <- coalesce(raw$relationship, raw$measure)
  raw <- filter(raw, cell %in% cls, !is.na(chose_emotion))
  mage <- mean(raw$age, na.rm = TRUE)
  raw$emotion <- titlecase_emo(raw$emotion)
  if (!is.na(g3)) raw$facet <- recode(raw$cell, !!!pretty)

  # model predictions
  terms <- c("age_c [all]", "emotion")
  if (!is.na(g3)) terms <- c(terms, g3)
  df <- as.data.frame(ggpredict(m, terms = terms)) |>
    mutate(age = x + mage, emotion = titlecase_emo(group))
  if (!is.na(g3)) df$facet <- recode(as.character(df$facet), !!!pretty)

  # adult observed means per cell x emotion
  adf <- B |> filter(study == st, population == "adult", cell %in% cls) |>
    transmute(cell, emotion = titlecase_emo(emotion), ymean = pct_emo / 100)
  if (!is.na(g3)) adf$facet <- recode(adf$cell, !!!pretty)

  p <- ggplot(df, aes(age, predicted, colour = emotion, fill = emotion)) +
    # individual children's raw responses (0/1), jittered
    geom_jitter(data = raw, inherit.aes = FALSE,
                mapping = aes(x = age, y = chose_emotion, colour = emotion),
                height = .03, width = .05, alpha = .25, size = 1.1) +
    geom_ribbon(aes(ymin = conf.low, ymax = conf.high, linetype = "Children (model)"),
                alpha = .15, colour = NA) +
    geom_line(aes(linetype = "Children (model)"), linewidth = 1) +
    # adult observed mean per condition
    geom_hline(data = adf, aes(yintercept = ymean, colour = emotion,
                               linetype = "Adults (observed mean)"), linewidth = .7) +
    geom_hline(yintercept = .5, linetype = 3, colour = "grey50", linewidth = .4) +
    scale_colour_manual(values = COND_COLS, name = "Condition", aesthetics = c("colour","fill")) +
    scale_linetype_manual(name = NULL,
                          values = c("Children (model)" = "solid",
                                     "Adults (observed mean)" = "dashed"),
                          guide = guide_legend(override.aes = list(colour = "black"))) +
    scale_y_continuous(labels = scales::percent, limits = c(-0.05, 1.05),
                       breaks = c(0, .25, .5, .75, 1)) +
    labs(title = titles[[tag]], x = "Age (years)", y = "P(choose emotion)") +
    omit_theme
  if (!is.na(g3)) p <- p + facet_wrap(~ facet)
  p
}

for (tag in names(titles)) {
  p <- make_age_fig(tag)
  w <- if (!is.na(grp3[[tag]])) 8 else 5.5
  ggsave(file.path(fig_dir, paste0("age_", tag, ".png")), p, width = w, height = 5.0, dpi = 300)
  message("wrote figures/age_", tag, ".png")
}
message("Done. Age figures in 5. Analysis/figures/")
