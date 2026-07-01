# ============================================================================
# OMIT — 02_figures.R
# One figure per study: proportion of Emotion vs Fact choices, by emotion
# condition x (relationship | measure), faceted by population (children/adults).
# Style follows the manuscript's stacked-proportion bars (resultsBF).
#
# Run 00_prep_data.R first. Writes PNGs to 5. Analysis/figures/.
# ============================================================================

suppressMessages({ library(dplyr); library(tidyr); library(readr); library(ggplot2); library(stringr) })

get_script_dir <- function() {
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
    return(dirname(rstudioapi::getActiveDocumentContext()$path))
  a <- commandArgs(FALSE); f <- sub("^--file=", "", a[grep("^--file=", a)])
  if (length(f)) return(dirname(normalizePath(f))); getwd()
}
proj    <- normalizePath(file.path(get_script_dir(), "..", ".."))
comb    <- file.path(proj, "5. Analysis", "data_clean", "long_combined")
fig_dir <- file.path(proj, "5. Analysis", "figures")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

pretty <- c(better_friend="Better friend", ice_cream="Ice cream", candy="Candy",
            create="Create relationship", deepen="Deepen relationship",
            mom="Mom", friendmom="Friend's mom", friend="Friend", bestfriend="Best friend")
titles <- c(study1="Study 1: Inferring closeness from disclosure",
            study2A="Study 2A: Child discloses to mom vs friend's mom",
            study2B="Study 2B: Mom / friend's mom discloses to child",
            study2C="Study 2C: Disclosing to a friend vs best friend",
            study3A="Study 3A: Disclosing to create a relationship",
            study3B="Study 3B: Disclosing to deepen a relationship")

omit_theme <- theme_minimal(base_size = 13) +
  theme(panel.grid.major.x = element_blank(), panel.grid.minor = element_blank(),
        legend.position = "bottom", plot.title = element_text(face = "bold", size = 13),
        strip.text = element_text(face = "bold"))

make_fig <- function(study) {
  d <- read_csv(file.path(comb, paste0(study, ".csv")), show_col_types = FALSE)
  xvar <- if ("relationship" %in% names(d)) "relationship" else "measure"

  prop <- d %>%
    filter(!is.na(chose_emotion)) %>%
    group_by(population, .data[[xvar]], emotion) %>%
    summarise(n = n(), emo = mean(chose_emotion), .groups = "drop") %>%
    mutate(fact = 1 - emo) %>%
    pivot_longer(c(emo, fact), names_to = "choice", values_to = "prop") %>%
    mutate(choice = ifelse(choice == "emo", "Emotion", "Fact"),
           xlab   = factor(recode(.data[[xvar]], !!!pretty)),
           emotion = factor(str_to_title(emotion), levels = c("Sad","Happy")),
           population = recode(population, child = "Children", adult = "Adults"),
           # emotion segment coloured by condition (matches the age plots);
           # fact segment is neutral grey. Fact level first -> sits on top.
           fill_group = factor(case_when(
             choice == "Fact"   ~ "Fact",
             emotion == "Sad"   ~ "Emotion (sad)",
             TRUE               ~ "Emotion (happy)"),
             levels = c("Fact", "Emotion (happy)", "Emotion (sad)")))

  ggplot(prop, aes(emotion, prop, fill = fill_group)) +
    geom_col(width = .75, colour = "black") +
    geom_hline(yintercept = .5, linetype = 2, alpha = .5) +
    facet_grid(population ~ xlab) +
    # colourblind-safe (Okabe-Ito), matched to age plots: sad = blue, happy = orange, fact = grey
    scale_fill_manual(values = c("Fact" = "grey80",
                                 "Emotion (sad)" = "#0072B2",
                                 "Emotion (happy)" = "#E69F00"), name = NULL) +
    scale_y_continuous(labels = scales::percent, expand = expansion(c(0, .02))) +
    labs(title = titles[[study]], x = NULL, y = "Proportion of judgments") +
    omit_theme
}

for (s in names(titles)) {
  p <- make_fig(s)
  ggsave(file.path(fig_dir, paste0(s, ".png")), p, width = 8, height = 5.5, dpi = 300)
  message("wrote figures/", s, ".png")
}
message("Done. Figures in 5. Analysis/figures/")
