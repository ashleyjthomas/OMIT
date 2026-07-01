# ============================================================================
#  OMIT_CLEAN.R - main analysis script for the OMIT project
#  "Children's Expectations of Emotional Intimacy in Close Relationships"
#
#  This script:
#    - loads each wave's data from "4. Data/csv files/"
#    - reshapes the wide source files into one tidy frame per manuscript study
#    - fits Bayesian mixed-effects models (saved to "5. Analysis/results/models/*.rds")
#    - produces the bar plots and age (developmental) plots consumed by
#      "6. Writing & Presentations/OMIT_manuscript.qmd"
#
#  All paths use here::here() so the script runs cleanly when invoked from the
#  project root (open OMIT.Rproj in RStudio).
#
#  DV CODING (everywhere): chose_emotion = 1 if the participant chose / was told
#  the EMOTION; 0 if the FACT.
#
#  STUDY <-> SOURCE-FILE MAP
#    Wave A  (children OMIT_data_1.9.25.csv N=57 ; adults OMIT-ADULT.csv N=47)
#        Study 1  : Better_Friend, Ice_Cream, Candy   (infer closeness)
#        Study 4A : Mom, FriendMom                     (child -> mom vs friend's-mom)
#        Study 3A : New_Friend                         (disclose to CREATE)
#    Wave B/C (children OMIT2_data_26.csv N=105 ; adults OMIT2_ADULT.csv N=49)
#        Study 4B : Mom, FriendMom                     (mom/friend's-mom -> child)
#        Study 2 : Friend, BestFriend                 (friend vs best friend)
#        Study 3B : NF/nbf                             (disclose to DEEPEN)
#
#  Companion: OMIT_manuscript.qmd renders the paper from the .rds files this
#  script produces.
# ============================================================================

library(here)   # for project-relative paths


# SETUP ----

## Packages ----

ipak <- function(pkg) {
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg)) install.packages(new.pkg, dependencies = TRUE)
  sapply(pkg, require, character.only = TRUE)
}

packages <- c(
  "afex", "vcd", "ggplot2", "likert", "lattice", "pbkrtest",
  "reshape2", "car", "plyr", "MASS", "lme4", "effects",
  "lmerTest", "multcomp", "lsmeans", "Hmisc", "tidyr",
  "ordinal", "brms", "jtools", "DHARMa", "rstanarm",
  "BayesFactor", "bayesplot", "tidybayes", "magrittr",
  "ggeffects", "sjmisc", "splines", "tidyverse", "bayestestR",
  "HDInterval", "dplyr", "formattable", "gt", "tufte", "tinytex",
  "performance", "stringr", "cowplot", "emmeans", "sjPlot"
)
ipak(packages)

library(dplyr)  # load after plyr to avoid masking


## Paths ----

raw_dir    <- here::here("4. Data", "csv files")
models_dir <- here::here("5. Analysis", "results", "models")
fig_dir    <- here::here("5. Analysis", "figures")
dir.create(models_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir,    recursive = TRUE, showWarnings = FALSE)


## Shared palette ----

okabe_ito <- c(
  "#000000", "#E69F00", "#56B4E9",
  "#009E73", "#F0E442", "#0072B2",
  "#D55E00", "#CC79A7"
)

# fill scheme for the forced-choice bars (emotion coloured by condition; fact grey)
omit_fills <- c(
  "Fact"            = "grey80",
  "Emotion (happy)" = "#ED7D31",
  "Emotion (sad)"   = "#4472C4"
)

# condition colours for the age (line) plots
cond_cols <- c(Sad = "#4472C4", Happy = "#ED7D31")

# pretty labels for relationship / measure facets
pretty_lab <- c(better_friend = "Better friend", ice_cream = "Ice cream", candy = "Candy",
                mom = "Mom", friendmom = "Friend's mom", friend = "Friend",
                bestfriend = "Best friend", create = "Create relationship",
                deepen = "Deepen relationship")


## Shared priors ----

priors_A <- c(
  prior(normal(0, 2.5), class = "b"),
  prior(normal(0, 5),   class = "Intercept"),
  prior(exponential(1), class = "sd")
)
priors_B <- c(
  prior(normal(0, 1),     class = "b"),
  prior(normal(0, 3),     class = "Intercept"),
  prior(exponential(1.5), class = "sd")
)
priors_C <- c(
  prior(normal(0, 5),     class = "b"),
  prior(normal(0, 10),    class = "Intercept"),
  prior(exponential(0.5), class = "sd")
)


## Shared helper functions ----

# recode the TEXT answers in the children Wave-B/C file:
# an emotion word ("sad"/"happy") = chose emotion (1); animal name / "fact" = 0
recode_emo_text <- function(x) {
  x <- str_trim(tolower(as.character(x)))
  dplyr::case_when(
    x %in% c("sad", "happy")       ~ 1L,
    x %in% c("", ".", "na", "n/a") ~ NA_integer_,
    TRUE                           ~ 0L
  )
}
as01 <- function(x) suppressWarnings(as.integer(round(as.numeric(x))))

# fit a brms model the first time, then load it from disk on later runs
fit_or_load <- function(file, fit_fun) {
  path <- file.path(models_dir, file)
  if (file.exists(path)) return(readRDS(path))
  m <- fit_fun()
  saveRDS(m, path)
  m
}

# standard brms call used throughout: PROBIT mixed model, default priors
# (matches our pre-registered "Bayesian probit generalized linear mixed model")
brm_std <- function(formula, data, adapt_delta = 0.8) {
  brm(formula, data = data, family = bernoulli(link = "probit"),
      save_pars = save_pars(all = TRUE),
      iter = 4000, warmup = 1000, thin = 1, chains = 4,
      cores = 4, seed = 123, refresh = 0,
      control = list(adapt_delta = adapt_delta))
}

# ONE-SIDED Bayesian binomial test vs chance (JZS prior), in the pre-registered
# hypothesis direction: "emotion" tests p(emotion) > .5 ; "fact" tests p < .5.
# Returns BF10 for that directional alternative vs the point null at .5.
bf_chance <- function(k, n, direction = "emotion") {
  interval <- if (direction == "emotion") c(0.5, 1) else c(0, 0.5)
  bf <- BayesFactor::proportionBF(k, n, p = 0.5, nullInterval = interval)
  as.numeric(as.vector(bf))[1]
}

# per-cell summary: % chose emotion + one-sided BF vs chance (hypothesis direction)
cell_summary <- function(dat, direction = "emotion") {
  grp <- intersect(c("population", "measure", "relationship", "emotion"), names(dat))
  dat %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(grp))) %>%
    dplyr::summarise(
      n       = sum(!is.na(chose_emotion)),
      k_emo   = sum(chose_emotion, na.rm = TRUE),
      pct_emo = round(100 * k_emo / n),
      BF10    = round(bf_chance(k_emo, n, direction), 2),
      BF01    = round(1 / BF10, 2),
      .groups = "drop"
    ) %>%
    dplyr::mutate(direction = direction)
}

# shared ggplot theme
theme_study <- function() {
  theme_minimal(base_size = 18, base_family = "Avenir Next") +
    theme(
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_blank(),
      panel.grid.minor   = element_blank(),
      panel.spacing      = unit(1.6, "lines"),
      axis.line          = element_line(colour = "black", linewidth = 0.6),
      axis.ticks         = element_line(colour = "black"),
      axis.text          = element_text(colour = "black", face = "bold"),
      legend.position    = "bottom",
      plot.title         = element_text(size = 18, face = "bold"),
      strip.text         = element_text(size = 14, face = "bold")
    )
}

# significance stars from a one-sided BF (vs chance, in the hypothesis direction)
bf_star <- function(bf) dplyr::case_when(bf >= 100 ~ "***", bf >= 10 ~ "**",
                                         bf >= 3 ~ "*", TRUE ~ "")

# shared forced-choice bar plot: stacked %-emotion vs %-fact.
# Two stacked panels (CHILDREN above ADULTS), population label centered in caps
# above each set, measure/relationship labels repeated per panel, significance
# stars above each bar (one-sided BF vs chance in `direction`). No plot title.
plot_omit_bars <- function(dat_long, x_var, x_labels = NULL,
                           direction = "emotion", y_name = "% of answers") {
  cell <- dat_long %>%
    dplyr::filter(!is.na(chose_emotion)) %>%
    dplyr::group_by(population, .data[[x_var]], emotion) %>%
    dplyr::summarise(emo = mean(chose_emotion), n = dplyr::n(),
                     k = sum(chose_emotion), .groups = "drop") %>%
    dplyr::rowwise() %>%
    dplyr::mutate(star = bf_star(bf_chance(k, n, direction))) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      emotion    = factor(str_to_title(emotion), levels = c("Sad", "Happy")),
      population = dplyr::recode(population, child = "Children", adult = "Adults"),
      facet      = if (!is.null(x_labels))
                     factor(x_labels[as.character(.data[[x_var]])],
                            levels = unname(x_labels))
                   else factor(.data[[x_var]]))

  bars <- cell %>%
    dplyr::mutate(fact = 1 - emo) %>%
    tidyr::pivot_longer(c(emo, fact), names_to = "choice", values_to = "prop") %>%
    dplyr::mutate(fill_group = factor(dplyr::case_when(
      choice == "fact" ~ "Fact",
      emotion == "Sad" ~ "Emotion (sad)",
      TRUE             ~ "Emotion (happy)"),
      levels = c("Fact", "Emotion (happy)", "Emotion (sad)")))

  one_panel <- function(pop) {
    ggplot(dplyr::filter(bars, population == pop),
           aes(emotion, prop, fill = fill_group)) +
      geom_col(width = 0.8, colour = "black", linewidth = 1.1) +
      geom_hline(yintercept = 0.5, linetype = "dashed", colour = "black",
                 linewidth = 0.6) +   # chance
      geom_text(data = dplyr::filter(cell, population == pop),
                aes(emotion, 1.02, label = star), inherit.aes = FALSE,
                vjust = 0, size = 6, fontface = "bold") +
      facet_wrap(~ facet, nrow = 1) +
      scale_fill_manual(values = omit_fills, name = NULL) +
      scale_y_continuous(breaks = c(0, .25, .5, .75, 1),
                         labels = c("0", "25", "50", "75", "100"),
                         expand = expansion(mult = c(0, 0.09))) +
      coord_cartesian(clip = "off") +
      labs(title = toupper(pop), x = NULL, y = y_name) +
      theme_study() +
      theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 16,
                                      margin = margin(b = 6)))
  }
  pc <- one_panel("Children"); pa <- one_panel("Adults")
  leg  <- cowplot::get_legend(pc + theme(legend.position = "bottom"))
  body <- cowplot::plot_grid(pc + theme(legend.position = "none"),
                             pa + theme(legend.position = "none"), ncol = 1)
  cowplot::plot_grid(body, leg, ncol = 1, rel_heights = c(1, 0.08))
}

# mean age of the child sample (for back-transforming centred age on the x axis)
mean_age <- function(d) mean(d$age[d$population == "child"], na.rm = TRUE)

# shared developmental (age) plot: model-predicted P(emotion) over age
# (conditional_effects ribbon + line), individual jittered responses, and dashed
# adult observed means by condition. Children only.
plot_omit_age <- function(fit, dat_child, dat_adult,
                          group_var = NULL, m_age, title = NULL) {
  prep_emo <- function(d) dplyr::mutate(d,
    emotion = factor(stringr::str_to_title(as.character(emotion)),
                     levels = c("Sad", "Happy")))

  # predicted curves (loop conditions over the grouping factor)
  ce_for <- function(cond = NULL)
    as.data.frame(conditional_effects(fit, effects = "age_c:emotion",
                                      conditions = cond)[[1]])
  if (is.null(group_var)) {
    ce <- ce_for()
  } else {
    glevels <- levels(factor(dat_child[[group_var]]))
    ce <- dplyr::bind_rows(lapply(glevels, function(g) {
      cond <- stats::setNames(
        data.frame(factor(g, levels = glevels)), group_var)   # full levels -> no "new level" error
      d <- ce_for(cond)
      d[[group_var]] <- g
      d
    }))
  }
  ce  <- prep_emo(ce) %>% dplyr::mutate(age = age_c + m_age)
  raw <- prep_emo(dplyr::filter(dat_child, !is.na(chose_emotion)))
  adf <- dat_adult %>%
    dplyr::filter(!is.na(chose_emotion)) %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(c(group_var, "emotion")))) %>%
    dplyr::summarise(ymean = mean(chose_emotion), .groups = "drop")
  adf <- prep_emo(adf)

  if (!is.null(group_var)) {
    relab <- function(x) factor(dplyr::recode(as.character(x), !!!pretty_lab))
    ce$facet  <- relab(ce[[group_var]])
    raw$facet <- relab(raw[[group_var]])
    adf$facet <- relab(adf[[group_var]])
  }

  p <- ggplot(ce, aes(age, estimate__, colour = emotion, fill = emotion)) +
    geom_jitter(data = raw, inherit.aes = FALSE,
                aes(age, chose_emotion, colour = emotion),
                width = 0.05, height = 0.03, alpha = 0.3, size = 1.5) +
    geom_ribbon(aes(ymin = lower__, ymax = upper__), alpha = 0.2, colour = NA) +
    geom_line(aes(linetype = "Children (model)"), linewidth = 1) +
    geom_hline(data = adf, aes(yintercept = ymean, colour = emotion,
                               linetype = "Adult mean"), linewidth = 0.9) +
    scale_colour_manual(values = cond_cols, name = "Condition",
                        aesthetics = c("colour", "fill")) +
    scale_linetype_manual(name = NULL,
                          values = c("Children (model)" = "solid", "Adult mean" = "dashed"),
                          guide = guide_legend(override.aes = list(colour = "black", fill = NA))) +
    scale_y_continuous(labels = scales::percent, breaks = c(0, .5, 1)) +
    coord_cartesian(ylim = c(0, 1)) +
    labs(title = stringr::str_wrap(title, 40), x = "Age (years)", y = "P(choose emotion)") +
    theme_study() +
    theme(panel.grid.major.y = element_line(colour = "grey90"),
          plot.title = element_text(size = 14, face = "bold", hjust = 0,
                                    margin = margin(b = 8)),
          plot.title.position = "plot",
          # stack the two legend blocks vertically so neither runs off the
          # (narrow, single-facet) figure width and clips "Happy"
          legend.position = "bottom",
          legend.box = "vertical",
          legend.box.just = "center",
          legend.spacing.y = unit(1, "pt"),
          legend.margin = margin(2, 4, 2, 4),
          legend.key.width = unit(1.4, "cm"),  # wide enough to show the dashed pattern
          plot.margin = margin(t = 10, r = 12, b = 6, l = 8))
  if (!is.null(group_var)) p <- p + facet_wrap(~ facet)
  p
}


# DATA ----

## Load raw sources ----

chA <- read.csv(here::here(raw_dir, "OMIT_data_1.9.25.csv"))   # children, Wave A
chB <- read.csv(here::here(raw_dir, "OMIT2_data_26.csv"))      # children, Wave B/C (text)
adA <- read.csv(here::here(raw_dir, "OMIT-ADULT.csv"))         # adults,   Wave A
adB <- read.csv(here::here(raw_dir, "OMIT2_ADULT.csv"))        # adults,   Wave B/C

# IDs + age (adults have no subject ID -> create one)
chA <- chA %>% mutate(ID = as.character(ID),
                      age = AgeYears + AgeMonths/12 + AgeDays/365)
chB <- chB %>% mutate(ID = as.character(ID),
                      age = Age_Years + Age_Months/12 + Age_Days/365)
adA <- adA %>% mutate(ID = sprintf("A1_%03d", dplyr::row_number()), age = NA_real_)
adB <- adB %>% mutate(ID = sprintf("A2_%03d", dplyr::row_number()),
                      age = suppressWarnings(as.numeric(Age)))


## Reshape into one tidy frame per study ----
# Each frame: ID, population, age, emotion (sad/happy), measure|relationship, chose_emotion

# helper to stack a child wide frame + adult wide frame, then pivot long
make_long <- function(child_wide, adult_wide, dv_cols, factors) {
  dplyr::bind_rows(
    child_wide %>% mutate(population = "child"),
    adult_wide %>% mutate(population = "adult")
  ) %>%
    tidyr::pivot_longer(dplyr::all_of(dv_cols), names_to = "key", values_to = "chose_emotion") %>%
    factors()
}

# --- Study 1: better friend / ice cream / candy (Wave A) ----
s1_child <- chA %>% transmute(ID, age, population = NA,
  better_friend_sad = as01(Better_Friend_sad), better_friend_happy = as01(Better_Friend_happy),
  ice_cream_sad     = as01(Ice_Cream_sad),      ice_cream_happy     = as01(Ice_Cream_happy),
  candy_sad         = as01(Candy_sad),          candy_happy         = as01(Candy_happy))
s1_adult <- adA %>% transmute(ID, age, population = NA,
  better_friend_sad = as01(sad_bf),        better_friend_happy = as01(happy_bf),
  ice_cream_sad     = as01(sad_ice_cream), ice_cream_happy     = as01(happy_ice_cream),
  candy_sad         = as01(sad_candy),     candy_happy         = as01(happy_candy))
s1 <- make_long(
  dplyr::select(s1_child, -population), dplyr::select(s1_adult, -population),
  c("better_friend_sad","better_friend_happy","ice_cream_sad",
    "ice_cream_happy","candy_sad","candy_happy"),
  function(d) tidyr::separate(d, key, into = c("measure", "emotion"), sep = "_(?=[^_]+$)"))

# --- Study 4A: child discloses to mom vs friend's mom (Wave A) ----
s4a_child <- chA %>% transmute(ID, age,
  mom_sad = as01(Mom_sad), mom_happy = as01(Mom_happy),
  friendmom_sad = as01(FriendMom_sad), friendmom_happy = as01(FriendMom_happy))
s4a_adult <- adA %>% transmute(ID, age,
  mom_sad = as01(mom_sad), mom_happy = as01(mom_happy),
  friendmom_sad = as01(friendmom_sad), friendmom_happy = as01(friendmom_happy))
rel_cols <- c("mom_sad","mom_happy","friendmom_sad","friendmom_happy")
sep_rel  <- function(d) tidyr::separate(d, key, into = c("relationship", "emotion"), sep = "_(?=[^_]+$)")
s4a <- make_long(s4a_child, s4a_adult, rel_cols, sep_rel)

# --- Study 3A: disclose to CREATE a relationship (Wave A) ----
s3a_child <- chA %>% transmute(ID, age,
  create_sad = as01(New_Friend_sad), create_happy = as01(New_Friend_happy))
s3a_adult <- adA %>% transmute(ID, age,
  create_sad = as01(nf_sad), create_happy = as01(nf_happy))
sep_meas <- function(d) tidyr::separate(d, key, into = c("measure", "emotion"), sep = "_(?=[^_]+$)")
s3a <- make_long(s3a_child, s3a_adult, c("create_sad","create_happy"), sep_meas)

# --- Study 4B: mom / friend's mom discloses TO child (Wave B/C) ----
s4b_child <- chB %>% transmute(ID, age,
  mom_sad = recode_emo_text(Sad_Mom), mom_happy = recode_emo_text(Happy_Mom),
  friendmom_sad = recode_emo_text(Sad_FriendMom), friendmom_happy = recode_emo_text(Happy_FriendMom))
s4b_adult <- adB %>% transmute(ID, age,
  mom_sad = as01(mom_sad), mom_happy = as01(mom_happy),
  friendmom_sad = as01(friendmom_sad), friendmom_happy = as01(friendmom_happy))
s4b <- make_long(s4b_child, s4b_adult, rel_cols, sep_rel)

# --- Study 2: friend vs best friend (Wave B/C) ----
s2_child <- chB %>% transmute(ID, age,
  friend_sad = recode_emo_text(Sad_Friend), friend_happy = recode_emo_text(Happy_Friend),
  bestfriend_sad = recode_emo_text(Sad_BF), bestfriend_happy = recode_emo_text(Happy_BF))
s2_adult <- adB %>% transmute(ID, age,
  friend_sad = as01(Friend_sad), friend_happy = as01(Friend_happy),
  bestfriend_sad = as01(BF_sad), bestfriend_happy = as01(BF_happy))
s2 <- make_long(s2_child, s2_adult,
  c("friend_sad","friend_happy","bestfriend_sad","bestfriend_happy"), sep_rel)

# --- Study 3B: disclose to DEEPEN a friendship (Wave B/C) ----
s3b_child <- chB %>% transmute(ID, age,
  deepen_sad = recode_emo_text(Sad_NF), deepen_happy = recode_emo_text(Happy_NF))
s3b_adult <- adB %>% transmute(ID, age,
  deepen_sad = as01(nbf_sad), deepen_happy = as01(nbf_happy))
s3b <- make_long(s3b_child, s3b_adult, c("deepen_sad","deepen_happy"), sep_meas)


## Factor coding ----
# emotion: reference = happy ; relationship: reference = the less-close tie
code_factors <- function(d) {
  d$emotion <- factor(d$emotion, levels = c("happy", "sad"))
  if ("relationship" %in% names(d)) {
    ref <- intersect(c("friendmom", "friend"), unique(d$relationship))[1]
    d$relationship <- relevel(factor(d$relationship), ref = ref)
  }
  if ("measure" %in% names(d)) d$measure <- factor(d$measure)
  d$ID <- factor(d$ID)
  d
}
s1 <- code_factors(s1); s4a <- code_factors(s4a); s4b <- code_factors(s4b)
s2 <- code_factors(s2); s3a <- code_factors(s3a); s3b <- code_factors(s3b)

# centred age within each child sample (for the age models)
add_age_c <- function(d) {
  d$age_c <- d$age - mean(d$age[d$population == "child"], na.rm = TRUE)
  d
}
s1 <- add_age_c(s1); s4a <- add_age_c(s4a); s4b <- add_age_c(s4b)
s2 <- add_age_c(s2); s3a <- add_age_c(s3a); s3b <- add_age_c(s3b)


# STUDY 1: Inferring closeness from disclosure ----

## Better-friend measure ----

s1_bf <- dplyr::filter(s1, measure == "better_friend")

cell_summary(dplyr::filter(s1_bf, population == "child"))   # one-sided BF vs chance

# Pre-registered model: probit, condition x age, children (age IS in the model).
xfit_s1bf_child <- fit_or_load("OMIT_s1bf_child.rds", function()
  brm_std(chose_emotion ~ emotion * age_c + (1 | ID),
          dplyr::filter(s1_bf, population == "child")))
# Adults: probit, condition only no age for adults.
# (adapt_delta = 0.99 to clear the few divergent transitions seen at the default)
xfit_s1bf_adult <- fit_or_load("OMIT_s1bf_adult.rds", function()
  brm_std(chose_emotion ~ emotion + (1 | ID), dplyr::filter(s1_bf, population == "adult"),
          adapt_delta = 0.99))

rope(xfit_s1bf_child); conditional_effects(xfit_s1bf_child)

## Food-sharing measures (ice cream vs candy) ----

s1_food <- dplyr::filter(s1, measure %in% c("ice_cream", "candy"))

xfit_s1food_child <- fit_or_load("OMIT_s1food_child.rds", function()
  brm_std(chose_emotion ~ emotion * measure * age_c + (1 | ID),
          dplyr::filter(s1_food, population == "child")))
xfit_s1food_adult <- fit_or_load("OMIT_s1food_adult.rds", function()
  brm_std(chose_emotion ~ emotion * measure + (1 | ID),
          dplyr::filter(s1_food, population == "adult")))

## Cell-means model (food sharing): each of the 4 conditions vs the happy/candy
## reference (happy/candy, sad/candy, happy/ice cream, sad/ice cream) ----
s1_food_cm <- s1_food %>%
  dplyr::mutate(cond4 = factor(paste(as.character(emotion), as.character(measure), sep = "_"),
    levels = c("happy_candy", "sad_candy", "happy_ice_cream", "sad_ice_cream")))
xfit_s1cell_child <- fit_or_load("OMIT_s1cell_child.rds", function()
  brm_std(chose_emotion ~ cond4 + (1 | ID), dplyr::filter(s1_food_cm, population == "child")))
xfit_s1cell_adult <- fit_or_load("OMIT_s1cell_adult.rds", function()
  brm_std(chose_emotion ~ cond4 + (1 | ID), dplyr::filter(s1_food_cm, population == "adult")))

## Bar plot ----

p_s1 <- plot_omit_bars(s1, "measure",
                       x_labels = c(better_friend = "Better friend",
                                    ice_cream = "Ice cream", candy = "Candy"))
ggsave(file.path(fig_dir, "study1.png"), p_s1, width = 8, height = 8.5, dpi = 300)

## Age figures (from the pre-registered child models) ----
p_age_s1bf <- plot_omit_age(xfit_s1bf_child,
                            dplyr::filter(s1_bf, population == "child"),
                            dplyr::filter(s1_bf, population == "adult"),
                            m_age = mean_age(s1_bf),
                            title = "Study 1 (better friend): emotion choice by age")
ggsave(file.path(fig_dir, "age_study1_bf.png"), p_age_s1bf, width = 6, height = 5, dpi = 300)

p_age_s1food <- plot_omit_age(xfit_s1food_child,
                              dplyr::filter(s1_food, population == "child"),
                              dplyr::filter(s1_food, population == "adult"),
                              group_var = "measure", m_age = mean_age(s1_food),
                              title = "Study 1 (food sharing): emotion choice by age")
ggsave(file.path(fig_dir, "age_study1_food.png"), p_age_s1food, width = 8, height = 5, dpi = 300)

## Circles (IOS social-closeness, 1-6) — pre-registered Part-1 primary DV ----
# Children rated how close each classmate was to the protagonist on a 6-step
# overlapping-circles scale (Aron et al., 1992, Inclusion of Other in the Self).
# Pre-registered analysis: Bayesian linear mixed model closeness ~ condition +
# (1 | ID). (The pre-registered (trial + 1 | ID) slope is omitted — no
# trial-order column in the tidy data; see main analytic note.) Here "target"
# is the classmate who was told the emotion vs the fact, crossed with the
# happy/sad condition. Children only (the adult circles are stored by character
# name and need the survey role key to map name -> emotion/fact target).
# NOTE on direction: in the raw data the circles are stored so that a LOWER
# number = MORE overlap (closer). This is confirmed two ways: (a) the warm-up
# items (strangers rated ~6, mother ~2-3, friends ~3) and (b) within children,
# the classmate they chose as the better friend / ice-cream partner gets the
# lower circle value. We therefore reverse-score to 7 - x so that HIGHER = closer,
# matching the binary measures and making the coefficients interpretable.
s1_circ_child <- chA %>%
  dplyr::transmute(ID = factor(ID), age,
    emo_sad    = 7 - suppressWarnings(as.numeric(Circles_emo_s)),
    fact_sad   = 7 - suppressWarnings(as.numeric(Circles_fact_s)),
    emo_happy  = 7 - suppressWarnings(as.numeric(Circles_emo_h)),
    fact_happy = 7 - suppressWarnings(as.numeric(Circles_fact_h))) %>%
  tidyr::pivot_longer(c(emo_sad, fact_sad, emo_happy, fact_happy),
                      names_to = "key", values_to = "closeness") %>%
  tidyr::separate(key, into = c("target", "emotion"), sep = "_(?=[^_]+$)") %>%
  dplyr::mutate(
    target  = factor(target,  levels = c("fact", "emo")),   # ref = fact classmate
    emotion = factor(emotion, levels = c("happy", "sad")),   # ref = happy
    age_c   = age - mean(age, na.rm = TRUE)) %>%
  dplyr::filter(!is.na(closeness))

xfit_s1circ_child <- fit_or_load("OMIT_s1circ_child.rds", function()
  brm(closeness ~ target * emotion + (1 | ID), data = s1_circ_child,
      family = gaussian(), iter = 4000, warmup = 1000, chains = 4,
      cores = 4, seed = 123, refresh = 0, control = list(adapt_delta = 0.95)))

# Adult circles. The adult survey is a single fixed version (attention-check
# columns Q90/Q91 and Q88/Q89 are identical for all 47 adults), so each
# character name maps to a fixed role. Confirmed against the better-friend
# choices and free-text justifications (e.g., "Percy told Avery about his
# feelings"): sad block -> Avery = emotion, Orin = fact; happy block -> Riley =
# emotion, Cameron = fact. Reverse-scored (7 - x) so higher = closer, as for kids.
s1_circ_adult <- adA %>%
  dplyr::transmute(ID = factor(ID),
    emo_sad    = 7 - suppressWarnings(as.numeric(circles_avery)),
    fact_sad   = 7 - suppressWarnings(as.numeric(circles_orin)),
    emo_happy  = 7 - suppressWarnings(as.numeric(circles_riley)),
    fact_happy = 7 - suppressWarnings(as.numeric(circles_cameron))) %>%
  tidyr::pivot_longer(c(emo_sad, fact_sad, emo_happy, fact_happy),
                      names_to = "key", values_to = "closeness") %>%
  tidyr::separate(key, into = c("target", "emotion"), sep = "_(?=[^_]+$)") %>%
  dplyr::mutate(target  = factor(target,  levels = c("fact", "emo")),
                emotion = factor(emotion, levels = c("happy", "sad"))) %>%
  dplyr::filter(!is.na(closeness))

xfit_s1circ_adult <- fit_or_load("OMIT_s1circ_adult.rds", function()
  brm(closeness ~ target * emotion + (1 | ID), data = s1_circ_adult,
      family = gaussian(), iter = 4000, warmup = 1000, chains = 4,
      cores = 4, seed = 123, refresh = 0, control = list(adapt_delta = 0.95)))

# descriptive cell means on the 1-6 scale (children + adults)
circ_means <- dplyr::bind_rows(
    dplyr::mutate(s1_circ_child, population = "child"),
    dplyr::mutate(s1_circ_adult, population = "adult")) %>%
  dplyr::group_by(population, emotion, target) %>%
  dplyr::summarise(mean = mean(closeness), sd = sd(closeness),
                   se = sd / sqrt(dplyr::n()), n = dplyr::n(), .groups = "drop")

## Circles figure ----
circ_plot_df <- circ_means %>%
  dplyr::mutate(
    target_lab  = factor(dplyr::recode(as.character(target),
                         emo = "Told the\nemotion", fact = "Told the\nfact"),
                         levels = c("Told the\nfact", "Told the\nemotion")),
    emotion_lab = factor(stringr::str_to_title(as.character(emotion)),
                         levels = c("Sad", "Happy")),
    pop_lab     = factor(dplyr::recode(population, child = "Children", adult = "Adults"),
                         levels = c("Children", "Adults")))
p_s1_circ <- ggplot(circ_plot_df, aes(target_lab, mean, fill = emotion_lab)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.62,
           colour = "black", linewidth = 0.8) +
  geom_errorbar(aes(ymin = mean - se, ymax = mean + se),
                position = position_dodge(width = 0.7), width = 0.15, linewidth = 0.8) +
  facet_wrap(~ pop_lab) +
  scale_fill_manual(values = cond_cols, name = "Condition") +
  scale_y_continuous(limits = c(0, 6), breaks = 0:6, expand = c(0, 0)) +
  labs(x = NULL, y = "Closeness (higher = closer)",
       title = "Study 1: social-closeness (circles) ratings") +
  theme_study() +
  theme(plot.title = element_text(size = 13, face = "bold"))
ggsave(file.path(fig_dir, "circles_study1.png"), p_s1_circ, width = 8, height = 4.5, dpi = 300)

## Circles — developmental (age) analysis ----
# Same reverse-scored closeness DV, with mean-centred continuous age folded in:
# closeness ~ target * emotion * age_c + (1 | ID). Does the emotion-classmate
# closeness advantage change with age? (children only)
xfit_s1circ_age <- fit_or_load("OMIT_s1circ_age.rds", function()
  brm(closeness ~ target * emotion * age_c + (1 | ID), data = s1_circ_child,
      family = gaussian(), iter = 4000, warmup = 1000, chains = 4,
      cores = 4, seed = 123, refresh = 0, control = list(adapt_delta = 0.95)))

# predicted closeness across age, by target, within each condition
m_age_circ <- mean(s1_circ_child$age, na.rm = TRUE)
relab_t <- function(x) factor(dplyr::recode(as.character(x),
             emo = "Emotion classmate", fact = "Fact classmate"),
             levels = c("Fact classmate", "Emotion classmate"))
ce_circ <- dplyr::bind_rows(lapply(c("happy", "sad"), function(e) {
  d <- as.data.frame(brms::conditional_effects(xfit_s1circ_age, effects = "age_c:target",
         conditions = data.frame(emotion = factor(e, levels = c("happy", "sad"))))[[1]])
  d$emotion <- e; d
})) %>%
  dplyr::mutate(age = age_c + m_age_circ, target_lab = relab_t(target),
    emotion_lab = factor(stringr::str_to_title(emotion), levels = c("Sad", "Happy")))
raw_circ <- s1_circ_child %>%
  dplyr::mutate(target_lab = relab_t(target),
    emotion_lab = factor(stringr::str_to_title(as.character(emotion)), levels = c("Sad", "Happy")))
circ_cols <- c("Emotion classmate" = "#0072B2", "Fact classmate" = "grey55")
p_age_circ <- ggplot(ce_circ, aes(age, estimate__, colour = target_lab, fill = target_lab)) +
  geom_jitter(data = raw_circ, inherit.aes = FALSE,
              aes(age, closeness, colour = target_lab),
              width = 0.05, height = 0.12, alpha = 0.25, size = 1.3) +
  geom_ribbon(aes(ymin = lower__, ymax = upper__), alpha = 0.18, colour = NA) +
  geom_line(linewidth = 1) +
  facet_wrap(~ emotion_lab) +
  scale_colour_manual(values = circ_cols, name = NULL, aesthetics = c("colour", "fill")) +
  scale_y_continuous(limits = c(1, 6), breaks = 1:6) +
  labs(x = "Age (years)", y = "Closeness (higher = closer)",
       title = "Study 1 circles: closeness across age, by condition") +
  theme_study() +
  theme(plot.title = element_text(size = 13, face = "bold"))
ggsave(file.path(fig_dir, "age_circles.png"), p_age_circ, width = 8, height = 4.5, dpi = 300)


# STUDY 4A: Child discloses to mom vs friend's mom ----

cell_summary(s4a)

# Pre-registered model: probit, condition x age, children; adults condition-only.
xfit_s4a_child <- fit_or_load("OMIT_s4a_child.rds", function()
  brm_std(chose_emotion ~ emotion * relationship * age_c + (1 | ID),
          dplyr::filter(s4a, population == "child")))
xfit_s4a_adult <- fit_or_load("OMIT_s4a_adult.rds", function()
  brm_std(chose_emotion ~ emotion * relationship + (1 | ID),
          dplyr::filter(s4a, population == "adult")))

rope(xfit_s4a_child); conditional_effects(xfit_s4a_child)

p_s4a <- plot_omit_bars(s4a, "relationship",
                        x_labels = c(mom = "Mom", friendmom = "Friend's mom"))
ggsave(file.path(fig_dir, "study4A.png"), p_s4a, width = 8, height = 8.5, dpi = 300)

## Age figure (from the pre-registered child model) ----
p_age_s4a <- plot_omit_age(xfit_s4a_child,
                           dplyr::filter(s4a, population == "child"),
                           dplyr::filter(s4a, population == "adult"),
                           group_var = "relationship", m_age = mean_age(s4a),
                           title = "Study 4A: emotion choice by age")
ggsave(file.path(fig_dir, "age_study4A.png"), p_age_s4a, width = 8, height = 5, dpi = 300)


# STUDY 4B: Mom / friend's mom discloses to child ----
# Pre-registered hypothesis: the mother will NOT share sad emotions -> test toward FACT.

cell_summary(s4b, direction = "fact")

# Pre-registered model: probit, condition x age, children; adults condition-only.
xfit_s4b_child <- fit_or_load("OMIT_s4b_child.rds", function()
  brm_std(chose_emotion ~ emotion * relationship * age_c + (1 | ID),
          dplyr::filter(s4b, population == "child")))
xfit_s4b_adult <- fit_or_load("OMIT_s4b_adult.rds", function()
  brm_std(chose_emotion ~ emotion * relationship + (1 | ID),
          dplyr::filter(s4b, population == "adult")))

p_s4b <- plot_omit_bars(s4b, "relationship",
                        x_labels = c(mom = "Mom", friendmom = "Friend's mom"),
                        direction = "fact")
ggsave(file.path(fig_dir, "study4B.png"), p_s4b, width = 8, height = 8.5, dpi = 300)

## Age figure (from the pre-registered child model) ----
p_age_s4b <- plot_omit_age(xfit_s4b_child,
                           dplyr::filter(s4b, population == "child"),
                           dplyr::filter(s4b, population == "adult"),
                           group_var = "relationship", m_age = mean_age(s4b),
                           title = "Study 4B: emotion choice by age")
ggsave(file.path(fig_dir, "age_study4B.png"), p_age_s4b, width = 8, height = 5, dpi = 300)


# STUDY 2: Friend vs best friend ----

cell_summary(s2)

# Pre-registered model: probit, condition x age, children; adults condition-only.
xfit_s2_child <- fit_or_load("OMIT_s2_child.rds", function()
  brm_std(chose_emotion ~ emotion * relationship * age_c + (1 | ID),
          dplyr::filter(s2, population == "child")))
xfit_s2_adult <- fit_or_load("OMIT_s2_adult.rds", function()
  brm_std(chose_emotion ~ emotion * relationship + (1 | ID),
          dplyr::filter(s2, population == "adult")))

rope(xfit_s2_child)   # relationship (best friend > friend) is credible with N = 105

p_s2 <- plot_omit_bars(s2, "relationship",
                        x_labels = c(friend = "Friend", bestfriend = "Best friend"))
ggsave(file.path(fig_dir, "study2.png"), p_s2, width = 8, height = 8.5, dpi = 300)

## Age figure (from the pre-registered child model) ----
p_age_s2 <- plot_omit_age(xfit_s2_child,
                           dplyr::filter(s2, population == "child"),
                           dplyr::filter(s2, population == "adult"),
                           group_var = "relationship", m_age = mean_age(s2),
                           title = "Study 2: emotion choice by age")
ggsave(file.path(fig_dir, "age_study2.png"), p_age_s2, width = 8, height = 5, dpi = 300)


# STUDY 3A: Disclose to create a relationship ----

cell_summary(s3a)

# Pre-registered model: probit, condition x age, children; adults condition-only.
xfit_s3a_child <- fit_or_load("OMIT_s3a_child.rds", function()
  brm_std(chose_emotion ~ emotion * age_c + (1 | ID), dplyr::filter(s3a, population == "child")))
xfit_s3a_adult <- fit_or_load("OMIT_s3a_adult.rds", function()
  brm_std(chose_emotion ~ emotion + (1 | ID), dplyr::filter(s3a, population == "adult")))

p_s3a <- plot_omit_bars(s3a, "measure",
                        x_labels = c(create = "Create relationship"))
ggsave(file.path(fig_dir, "study3A.png"), p_s3a, width = 6, height = 8.5, dpi = 300)

## Age figure (from the pre-registered child model) ----
p_age_s3a <- plot_omit_age(xfit_s3a_child,
                           dplyr::filter(s3a, population == "child"),
                           dplyr::filter(s3a, population == "adult"),
                           m_age = mean_age(s3a),
                           title = "Study 3A: emotion choice by age")
ggsave(file.path(fig_dir, "age_study3A.png"), p_age_s3a, width = 6, height = 5, dpi = 300)


# STUDY 3B: Disclose to deepen a relationship ----

cell_summary(s3b)

# Pre-registered model: probit, condition x age, children; adults condition-only.
xfit_s3b_child <- fit_or_load("OMIT_s3b_child.rds", function()
  brm_std(chose_emotion ~ emotion * age_c + (1 | ID), dplyr::filter(s3b, population == "child")))
xfit_s3b_adult <- fit_or_load("OMIT_s3b_adult.rds", function()
  brm_std(chose_emotion ~ emotion + (1 | ID), dplyr::filter(s3b, population == "adult"),
          adapt_delta = 0.99))

p_s3b <- plot_omit_bars(s3b, "measure",
                        x_labels = c(deepen = "Deepen relationship"))
ggsave(file.path(fig_dir, "study3B.png"), p_s3b, width = 6, height = 8.5, dpi = 300)

## Age figure (from the pre-registered child model) ----
p_age_s3b <- plot_omit_age(xfit_s3b_child,
                           dplyr::filter(s3b, population == "child"),
                           dplyr::filter(s3b, population == "adult"),
                           m_age = mean_age(s3b),
                           title = "Study 3B: emotion choice by age")
ggsave(file.path(fig_dir, "age_study3B.png"), p_age_s3b, width = 6, height = 5, dpi = 300)


# SENSITIVITY ANALYSIS (optional; priors A/B/C) ----
# Example for Study 2 children; mirror for other studies as needed.

run_sensitivity <- function(formula, data, tag) {
  list(
    A = fit_or_load(paste0("OMIT_sens_", tag, "_A.rds"), function()
      brm(formula, data = data, family = bernoulli(), prior = priors_A,
          iter = 3000, warmup = 1000, chains = 4, cores = 4, seed = 123, refresh = 0)),
    B = fit_or_load(paste0("OMIT_sens_", tag, "_B.rds"), function()
      brm(formula, data = data, family = bernoulli(), prior = priors_B,
          iter = 3000, warmup = 1000, chains = 4, cores = 4, seed = 123, refresh = 0)),
    C = fit_or_load(paste0("OMIT_sens_", tag, "_C.rds"), function()
      brm(formula, data = data, family = bernoulli(), prior = priors_C,
          iter = 3000, warmup = 1000, chains = 4, cores = 4, seed = 123, refresh = 0))
  )
}
# sens_s2 <- run_sensitivity(chose_emotion ~ emotion * relationship + (1 | ID),
#                             dplyr::filter(s2, population == "child"), "s2")
# lapply(sens_s2, function(m) describe_posterior(m, rope_range = c(-0.1, 0.1)))


# EXPORT TABLES FOR THE MANUSCRIPT ----
# OMIT_manuscript.qmd reads these (derived from the .rds models above).

results_dir <- here::here("5. Analysis", "results")

# posterior median / 95% CI / % in ROPE / pd for one model
tidy_post <- function(model, name) {
  dp <- describe_posterior(model, ci = .95, rope_range = c(-0.1, 0.1),
                           rope_ci = 1, test = c("rope", "pd"))
  as.data.frame(dp) %>%
    transmute(model = name, term = Parameter,
              median = round(Median, 2), CI_low = round(CI_low, 2),
              CI_high = round(CI_high, 2),
              pct_in_ROPE = round(100 * ROPE_Percentage, 1), pd = round(pd, 3))
}

## One-sided Bayesian binomial tests vs chance (pre-registered direction) ----
# emotion (p>.5): closeness / emotion-sharing hypotheses (1, 2A, 2C, 3A, 3B)
# fact   (p<.5): Study 4B (mother predicted NOT to share sad emotions)
binom_tbl <- dplyr::bind_rows(
  cell_summary(s1,  "emotion") %>% mutate(study = "study1"),
  cell_summary(s4a, "emotion") %>% mutate(study = "study4A"),
  cell_summary(s4b, "fact")    %>% mutate(study = "study4B"),
  cell_summary(s2, "emotion") %>% mutate(study = "study2"),
  cell_summary(s3a, "emotion") %>% mutate(study = "study3A"),
  cell_summary(s3b, "emotion") %>% mutate(study = "study3B")
) %>% dplyr::relocate(study)
readr::write_csv(binom_tbl, file.path(results_dir, "binomial_BF.csv"))

## Mixed-model estimates ----
# Child models are the pre-registered probit condition x age models, so they
# carry BOTH the condition terms (at mean age) AND the age interactions; adult
# models are probit condition-only. One combined table — no separate age table.
model_tbl <- dplyr::bind_rows(
  tidy_post(xfit_s1bf_child,   "study1_bf_child"),   tidy_post(xfit_s1bf_adult,   "study1_bf_adult"),
  tidy_post(xfit_s1food_child, "study1_food_child"), tidy_post(xfit_s1food_adult, "study1_food_adult"),
  tidy_post(xfit_s1cell_child, "study1_cellmeans_child"), tidy_post(xfit_s1cell_adult, "study1_cellmeans_adult"),
  tidy_post(xfit_s4a_child,    "study4A_child"),     tidy_post(xfit_s4a_adult,    "study4A_adult"),
  tidy_post(xfit_s4b_child,    "study4B_child"),     tidy_post(xfit_s4b_adult,    "study4B_adult"),
  tidy_post(xfit_s2_child,    "study2_child"),     tidy_post(xfit_s2_adult,    "study2_adult"),
  tidy_post(xfit_s3a_child,    "study3A_child"),     tidy_post(xfit_s3a_adult,    "study3A_adult"),
  tidy_post(xfit_s3b_child,    "study3B_child"),     tidy_post(xfit_s3b_adult,    "study3B_adult")
)
readr::write_csv(model_tbl, file.path(results_dir, "model_estimates.csv"))

## Circles (social-closeness, 1-6) — pre-registered Part-1 DV, children ----
# Kept in their own files (raw 1-6 scale, gaussian — not the probit scale of the
# models above). Consumed by the Supplement's circles section.
readr::write_csv(dplyr::bind_rows(
    tidy_post(xfit_s1circ_child, "study1_circles_child"),
    tidy_post(xfit_s1circ_adult, "study1_circles_adult")),
  file.path(results_dir, "circles_estimates.csv"))
readr::write_csv(circ_means, file.path(results_dir, "circles_means.csv"))
readr::write_csv(tidy_post(xfit_s1circ_age, "study1_circles_age_child"),
                 file.path(results_dir, "circles_age_estimates.csv"))


# AGE ANALYSES (Woo-style) ----
# Following Woo et al. (2024): for each study we (a) test the condition x age
# interaction (continuous-age models, fit in the study sections above), then
# (b) refit WITHOUT age to estimate the whole-group condition effect, and
# (c) fit a categorical-age model for per-age (6-9 yr) estimates. Children only
# (adults have no recorded age).
#   - interaction terms  -> model_estimates.csv (the *_child models, :age_c terms)
#   - whole-group effect -> whole_group_estimates.csv
#   - per-age estimates  -> age_effects.csv

age_specs <- list(
  study1_bf   = list(d = dplyr::filter(s1_bf,   population == "child"), rhs = "emotion"),
  study1_food = list(d = dplyr::filter(s1_food, population == "child"), rhs = "emotion * measure"),
  study2      = list(d = dplyr::filter(s2,      population == "child"), rhs = "emotion * relationship"),
  study3A     = list(d = dplyr::filter(s3a,     population == "child"), rhs = "emotion"),
  study3B     = list(d = dplyr::filter(s3b,     population == "child"), rhs = "emotion"),
  study4A     = list(d = dplyr::filter(s4a,     population == "child"), rhs = "emotion * relationship"),
  study4B     = list(d = dplyr::filter(s4b,     population == "child"), rhs = "emotion * relationship")
)

noage_est <- list(); ageyr_est <- list()
for (tag in names(age_specs)) {
  d   <- age_specs[[tag]]$d
  rhs <- age_specs[[tag]]$rhs
  d$age_yr <- factor(floor(d$age))

  # (b) whole-group model (no age) -> the effect reported in the main text
  m_noage <- fit_or_load(paste0("OMIT_", tag, "_noage.rds"), function()
    brm_std(stats::as.formula(paste("chose_emotion ~", rhs, "+ (1 | ID)")), d))
  noage_est[[tag]] <- tidy_post(m_noage, paste0(tag, "_noage"))

  # (c) categorical-age model -> per-age estimated P(emotion) by condition
  m_ageyr <- fit_or_load(paste0("OMIT_", tag, "_ageyr.rds"), function()
    brm_std(stats::as.formula(paste("chose_emotion ~", rhs, "* age_yr + (1 | ID)")), d))
  cond_vars <- if (grepl("relationship", rhs)) c("emotion", "relationship")
               else if (grepl("measure", rhs)) c("emotion", "measure")
               else "emotion"
  emm <- emmeans::emmeans(m_ageyr, specs = c(cond_vars, "age_yr"), type = "response")
  ageyr_est[[tag]] <- as.data.frame(emm) |>
    dplyr::mutate(study = tag) |> dplyr::relocate(study)
}
readr::write_csv(dplyr::bind_rows(noage_est), file.path(results_dir, "whole_group_estimates.csv"))
readr::write_csv(dplyr::bind_rows(ageyr_est), file.path(results_dir, "age_effects.csv"))
message("Woo-style age analyses written: whole_group_estimates.csv, age_effects.csv")


# GENDER ROBUSTNESS ANALYSIS ----
# Exploratory (not pre-registered): does the child's gender moderate the effects?
# (The raw data column is labelled "Sex" but reflects parent-reported gender.)
# For each study we add gender (and its interaction with emotion) to the child
# probit model: chose_emotion ~ emotion * gender + (1 | ID). Collapses across the
# relationship/measure factors so the screen is uniform across studies. The one
# non-binary child (Wave B/C) is dropped (n = 1 cannot be estimated). Inference
# follows the rest of the paper (whether 0 is in the 95% CI). Consumed by the
# Supplement's gender section -> results/gender_effects.csv.

gender_lu <- dplyr::bind_rows(
  dplyr::transmute(chA, ID = as.character(ID), gender = Sex),
  dplyr::transmute(chB, ID = as.character(ID), gender = Sex))

add_gender <- function(d) d %>%
  dplyr::mutate(ID = as.character(ID)) %>%
  dplyr::left_join(gender_lu, by = "ID") %>%
  dplyr::filter(gender %in% c("F", "M")) %>%
  dplyr::mutate(gender = factor(gender, levels = c("F", "M")), ID = factor(ID))

gender_specs <- list(
  study1_bf   = dplyr::filter(s1_bf,   population == "child"),
  study1_food = dplyr::filter(s1_food, population == "child"),
  study2      = dplyr::filter(s2,      population == "child"),
  study3A     = dplyr::filter(s3a,     population == "child"),
  study3B     = dplyr::filter(s3b,     population == "child"),
  study4A     = dplyr::filter(s4a,     population == "child"),
  study4B     = dplyr::filter(s4b,     population == "child"))

gender_est <- list()
for (tag in names(gender_specs)) {
  d <- add_gender(gender_specs[[tag]])
  m <- fit_or_load(paste0("OMIT_", tag, "_gender.rds"), function()
    brm_std(chose_emotion ~ emotion * gender + (1 | ID), d))
  gender_est[[tag]] <- tidy_post(m, paste0(tag, "_gender"))
}
readr::write_csv(dplyr::bind_rows(gender_est), file.path(results_dir, "gender_effects.csv"))
message("Gender robustness analysis written: gender_effects.csv")


# SUPPLEMENT: MODEL DIAGNOSTICS ----
# Convergence (Rhat, ESS), divergences, Bayesian R2, and posterior predictive
# checks for every model. Consumed by OMIT_supplement.qmd.

diag_dir <- file.path(fig_dir, "diagnostics")
dir.create(diag_dir, recursive = TRUE, showWarnings = FALSE)

# named list of the fitted models (in memory from fit_or_load above)
omit_models <- list(
  study1_bf_child   = xfit_s1bf_child,   study1_bf_adult   = xfit_s1bf_adult,
  study1_food_child = xfit_s1food_child, study1_food_adult = xfit_s1food_adult,
  study4A_child     = xfit_s4a_child,    study4A_adult     = xfit_s4a_adult,
  study4B_child     = xfit_s4b_child,    study4B_adult     = xfit_s4b_adult,
  study2_child     = xfit_s2_child,    study2_adult     = xfit_s2_adult,
  study3A_child     = xfit_s3a_child,    study3A_adult     = xfit_s3a_adult,
  study3B_child     = xfit_s3b_child,    study3B_adult     = xfit_s3b_adult
)

## Convergence + fit table ----
model_diag <- function(m, name) {
  dp  <- bayestestR::diagnostic_posterior(m, effects = "all", component = "all")
  r2  <- brms::bayes_R2(m)
  np  <- brms::nuts_params(m)
  data.frame(
    model       = name,
    n_param     = nrow(dp),
    max_Rhat    = round(max(dp$Rhat, na.rm = TRUE), 3),
    min_ESS     = round(min(dp$ESS,  na.rm = TRUE)),
    n_divergent = sum(np$Value[np$Parameter == "divergent__"]),
    BayesR2     = round(r2[, "Estimate"], 3),
    BayesR2_low = round(r2[, "Q2.5"], 3),
    BayesR2_high = round(r2[, "Q97.5"], 3)
  )
}
diag_tbl <- dplyr::bind_rows(Map(model_diag, omit_models, names(omit_models)))
readr::write_csv(diag_tbl, file.path(results_dir, "model_diagnostics.csv"))
print(as.data.frame(diag_tbl), row.names = FALSE)

## Posterior predictive checks ----
# Combine all models' pp_checks into ONE grid image (pp_all.png). A single image
# scales cleanly to the page in both Word and PDF; a multi-column layout panel of
# 14 separate images gets cropped. Bars = observed; points/intervals = predicted.
mod_lab_diag <- c(
  study1_bf_child = "Study 1 better friend (children)", study1_bf_adult = "Study 1 better friend (adults)",
  study1_food_child = "Study 1 food (children)",        study1_food_adult = "Study 1 food (adults)",
  study2_child = "Study 2 (children)",   study2_adult = "Study 2 (adults)",
  study3A_child = "Study 3A (children)", study3A_adult = "Study 3A (adults)",
  study3B_child = "Study 3B (children)", study3B_adult = "Study 3B (adults)",
  study4A_child = "Study 4A (children)", study4A_adult = "Study 4A (adults)",
  study4B_child = "Study 4B (children)", study4B_adult = "Study 4B (adults)")
pp_list <- lapply(names(omit_models), function(nm) {
  brms::pp_check(omit_models[[nm]], type = "dens_overlay", ndraws = 100) +
    ggplot2::labs(title = unname(mod_lab_diag[nm]), x = NULL, y = NULL) +
    theme_study() +
    theme(plot.title   = element_text(size = 8.5, face = "bold"),
          legend.position = "none",
          axis.text    = element_text(size = 7),
          plot.margin  = margin(2, 4, 2, 4))
})
pp_grid <- cowplot::plot_grid(plotlist = pp_list, ncol = 3)
ggsave(file.path(diag_dir, "pp_all.png"), pp_grid, width = 9, height = 11.5, dpi = 150)

message("OMIT_CLEAN.R complete — models in ", models_dir,
        " ; summary tables in ", results_dir,
        " ; diagnostics in ", diag_dir)


# PROCEDURE / STIMULI FIGURES (illustrative; no data) ----
# (1) study1_design.png    -> manuscript (Study 1 methods)
# (2) circles_scale.png     -> supplement (social-closeness measure)

.fig_ink <- "#222222"

## (1) Study 1 design figure, composited from the real stimulus assets in
## figures/assets/ (protagonist, classmates, fox = the fact, crying/smiling snoo
## = the sad/happy emotion, ice cream, candy). Three steps: setup + the two
## conditions -> selective disclosure -> forced-choice judgments.
.assets <- file.path(fig_dir, "assets")
.ap  <- function(f) file.path(.assets, f)
.fam <- "Avenir Next"; .grey <- "#6a6a6a"
.sadc <- cond_cols[["Sad"]]; .hapc <- cond_cols[["Happy"]]
.img <- function(f, x, y, w, h)
  cowplot::draw_image(.ap(f), x = x, y = y, width = w, height = h, hjust = 0.5, vjust = 0.5)
.lab <- function(t, x, y, size = 11, face = "plain", col = .fig_ink, ...)
  cowplot::draw_label(t, x = x, y = y, size = size, fontface = face, fontfamily = .fam, colour = col, ...)
.arr <- function(y0, y1, x = 0.5)
  annotate("segment", x = x, xend = x, y = y0, yend = y1,
           arrow = arrow(length = unit(0.13, "in"), type = "closed"),
           colour = "#9a9a9a", linewidth = 0.9)
p_design <- cowplot::ggdraw() +
  .lab("Study 1 design", 0.5, 0.985, size = 17, face = "bold") +
  # Step 1: setup + the two conditions
  .lab("1.  A child learns an animal fact and feels an emotion at school", 0.5, 0.945, size = 13, face = "bold") +
  .img("protagonist.png", 0.13, 0.865, 0.12, 0.12) + .lab("a child", 0.13, 0.79, size = 10) +
  .img("fox.png", 0.37, 0.875, 0.155, 0.08) + .lab("learns an animal fact", 0.37, 0.795, size = 10) +
  .lab("...and feels an emotion:", 0.585, 0.93, size = 10, face = "italic", col = .grey) +
  .img("felt_sad.png", 0.66, 0.865, 0.10, 0.095) + .lab("SAD condition", 0.66, 0.79, size = 9.5, face = "bold", col = .sadc) +
  .img("felt_happy.png", 0.87, 0.865, 0.10, 0.095) + .lab("HAPPY condition", 0.87, 0.79, size = 9.5, face = "bold", col = .hapc) +
  .lab("(within subjects: each child saw one sad story and one happy story)", 0.73, 0.765, size = 8, col = .grey) +
  .arr(0.745, 0.715) +
  # Step 2: selective disclosure
  .lab("2.  The child tells one classmate the emotion, the other the fact", 0.5, 0.685, size = 13, face = "bold") +
  .img("felt_sad.png", 0.195, 0.635, 0.062, 0.06) + .img("felt_happy.png", 0.265, 0.635, 0.062, 0.06) +
  .img("mate_blue.png", 0.23, 0.515, 0.12, 0.12) + .lab("told the EMOTION\n(sad or happy; not the fact)", 0.23, 0.43, size = 9.5) +
  .img("protagonist.png", 0.5, 0.55, 0.105, 0.105) + .lab("the child", 0.5, 0.485, size = 9) +
  .img("fox.png", 0.77, 0.63, 0.12, 0.06) +
  .img("mate_orange.png", 0.77, 0.515, 0.12, 0.12) + .lab("told the FACT\n(not the emotion)", 0.77, 0.43, size = 9.5) +
  .arr(0.395, 0.365) +
  # Step 3: judgments
  .lab("3.  Participants judge which classmate is closer", 0.5, 0.335, size = 13, face = "bold") +
  .img("mate_blue.png", 0.30, 0.25, 0.115, 0.115) + .lab("vs.", 0.46, 0.25, size = 13, face = "bold") +
  .img("mate_orange.png", 0.62, 0.25, 0.115, 0.115) +
  .lab("told the emotion", 0.30, 0.175, size = 9, col = .grey) + .lab("told the fact", 0.62, 0.175, size = 9, col = .grey) +
  .lab("Which classmate is the better friend?", 0.40, 0.105, size = 10.5, hjust = 0) +
  .lab("Who would the child share a single ice cream cone with?", 0.40, 0.06, size = 10.5, hjust = 0) +
  .lab("Who would the child share partitionable candy with?", 0.40, 0.015, size = 10.5, hjust = 0) +
  .img("icecream.png", 0.36, 0.06, 0.035, 0.05) + .img("candy.png", 0.36, 0.015, 0.05, 0.035)
ggsave(file.path(fig_dir, "study1_design.png"), p_design, width = 9, height = 9.4, dpi = 300, bg = "white")

## (2) Supplement circles scale: this is the ACTUAL stimulus, extracted from the
## pre-registration PDF (the six bordered circle-overlap options children chose
## among) and stored as a static asset at figures/circles_measure.png. It is not
## re-generated here (it is a stimulus image, not a data figure).

## ---- Combined multi-panel figures for the manuscript ------------------------
## One figure per study, built from the in-memory ggplot objects so that the
## developmental (age) panels can share a SINGLE legend rather than repeating it.
## Bars keep their own (Fact/Emotion) legend; age titles are dropped (the figure
## caption identifies each panel).
.figP     <- function(f) file.path(fig_dir, f)
.notitle  <- function(p) p + ggplot2::labs(title = NULL)
.nolegend <- function(p) p + ggplot2::theme(legend.position = "none")

# Study 1: A = bars (own legend); B = better-friend age; C = food age.
# B & C share one age legend, shown once beneath them.
leg_age1 <- cowplot::get_legend(p_age_s1bf)
s1_bc    <- cowplot::plot_grid(.nolegend(.notitle(p_age_s1bf)),
                               .nolegend(.notitle(p_age_s1food)),
                               ncol = 1, labels = c("B", "C"))
s1_right <- cowplot::plot_grid(s1_bc, leg_age1, ncol = 1, rel_heights = c(1, 0.13))
comb_s1  <- cowplot::plot_grid(p_s1, s1_right, ncol = 2, labels = c("A", ""),
                               rel_widths = c(1.15, 1))
ggsave(.figP("combined_study1.png"), comb_s1, width = 11, height = 7, dpi = 300, bg = "white")

# Study 2: A = bars; B = age (kept legends differ, so both remain)
comb_s2 <- cowplot::plot_grid(p_s2, .notitle(p_age_s2), ncol = 2,
                              labels = c("A", "B"), rel_widths = c(0.95, 1.15))
ggsave(.figP("combined_study2.png"), comb_s2, width = 11, height = 5.2, dpi = 300, bg = "white")

# Study 3: A = 3.A age; B = 3.B age (bars omitted). One shared age legend.
leg_age3 <- cowplot::get_legend(p_age_s3a)
s3_ab    <- cowplot::plot_grid(.nolegend(.notitle(p_age_s3a)),
                               .nolegend(.notitle(p_age_s3b)),
                               ncol = 2, labels = c("A", "B"))
comb_s3  <- cowplot::plot_grid(s3_ab, leg_age3, ncol = 1, rel_heights = c(1, 0.13))
ggsave(.figP("combined_study3_age.png"), comb_s3, width = 10, height = 4.8, dpi = 300, bg = "white")

# Study 4.A: A = bars; B = age
comb_s4a <- cowplot::plot_grid(p_s4a, .notitle(p_age_s4a), ncol = 2,
                               labels = c("A", "B"), rel_widths = c(0.95, 1.15))
ggsave(.figP("combined_study4A.png"), comb_s4a, width = 11, height = 5.2, dpi = 300, bg = "white")

# Study 4.B: A = bars; B = age
comb_s4b <- cowplot::plot_grid(p_s4b, .notitle(p_age_s4b), ncol = 2,
                               labels = c("A", "B"), rel_widths = c(0.95, 1.15))
ggsave(.figP("combined_study4B.png"), comb_s4b, width = 11, height = 5.2, dpi = 300, bg = "white")
