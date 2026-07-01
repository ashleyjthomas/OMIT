# ============================================================================
# OMIT — 00_prep_data.R
# Children's Expectations of Emotional Intimacy in Close Relationships
#
# PURPOSE
#   Take the 4 "wide" source files (one per population x data-collection wave)
#   and split them into per-STUDY tidy files that match the manuscript.
#
#   The raw files mix several manuscript "studies" into a single wide sheet,
#   and the column names use inconsistent abbreviations across files. This
#   script applies ONE consistent naming scheme and writes, for every study:
#       data_clean/wide/        studyX_children.csv , studyX_adults.csv
#       data_clean/long/        studyX_children.csv , studyX_adults.csv   (per population)
#       data_clean/long_combined/  studyX.csv        (children + adults stacked; used by analysis & figures)
#
# DV CODING (everywhere):  chose_emotion = 1 if participant chose to DISCLOSE / was
#                          told the EMOTION;  0 if they chose the FACT.
#
# STUDY <-> SOURCE-FILE MAP
#   Wave A  (children OMIT_data_1.9.25.csv  N=57 ; adults OMIT-ADULT.csv  N=47)
#       Study 1  : Better_Friend, Ice_Cream, Candy        (infer closeness from disclosure)
#       Study 2A : Mom, FriendMom                          (child -> mom vs friend's-mom)
#       Study 3A : New_Friend                              (disclose to CREATE a relationship)
#   Wave B/C (children OMIT2_data_26.csv  N=105 ; adults OMIT2_ADULT.csv  N=49)
#       Study 2B : Mom, FriendMom                          (mom/friend's-mom -> child)
#       Study 2C : Friend, BestFriend                      (friend vs best friend)
#       Study 3B : NF/nbf                                  (disclose to DEEPEN a friendship)
#
#   NAMING TRAPS in the raw data (handled below):
#     * Wave A  "bf"/"Better_Friend" = BETTER friend (Study 1 outcome)
#       Wave B/C "BF"                = BEST   friend (Study 2C relationship)
#     * Wave A  "New_Friend"/"nf"    = Study 3A (CREATE a new relationship)
#       Wave B/C "NF"/"nbf"          = Study 3B (DEEPEN an existing friendship)
#
#   FLAG: the children Wave-B/C file has 105 rows but the current manuscript
#   reports N = 75 for Studies 2B/2C/3B. All 105 are kept here; reconcile the
#   manuscript number (stale N, or a missing exclusion list) before publishing.
# ============================================================================

suppressMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(stringr)
})

# ---- locate project folders (works in RStudio or via Rscript) --------------
get_script_dir <- function() {
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
    return(dirname(rstudioapi::getActiveDocumentContext()$path))
  a <- commandArgs(FALSE)
  f <- sub("^--file=", "", a[grep("^--file=", a)])
  if (length(f)) return(dirname(normalizePath(f)))
  getwd()
}
script_dir <- get_script_dir()
proj       <- normalizePath(file.path(script_dir, "..", ".."))   # OMIT/
data_in    <- file.path(proj, "4. Data", "csv files")
out_wide   <- file.path(proj, "5. Analysis", "data_clean", "wide")
out_long   <- file.path(proj, "5. Analysis", "data_clean", "long")
out_comb   <- file.path(proj, "5. Analysis", "data_clean", "long_combined")
for (d in c(out_wide, out_long, out_comb)) dir.create(d, recursive = TRUE, showWarnings = FALSE)

# ---- helpers ---------------------------------------------------------------
# Recode the TEXT answers in the children Wave-B/C file: an emotion word
# ("sad"/"happy") == chose emotion (1); an animal name or "fact" == chose fact (0).
recode_emo_text <- function(x) {
  x <- str_trim(tolower(as.character(x)))
  dplyr::case_when(
    x %in% c("sad", "happy")          ~ 1L,
    x %in% c("", ".", "na", "n/a")    ~ NA_integer_,
    TRUE                              ~ 0L
  )
}
as01 <- function(x) suppressWarnings(as.integer(round(as.numeric(x))))  # numeric 0/1 cols

write_study <- function(child_wide, adult_wide, dv_cols, id_vars, study, factors) {
  # child_wide / adult_wide : standardized wide tibbles (ID + dv_cols)
  # factors : function(long_df) -> long_df that splits the "key" into emotion/relationship/measure
  message(sprintf("  Study %-3s : children = %d , adults = %d",
                  study, nrow(child_wide), nrow(adult_wide)))

  readr::write_csv(child_wide, file.path(out_wide, sprintf("study%s_children.csv", study)))
  readr::write_csv(adult_wide, file.path(out_wide, sprintf("study%s_adults.csv",   study)))

  to_long <- function(df, pop) {
    df %>%
      pivot_longer(all_of(dv_cols), names_to = "key", values_to = "chose_emotion") %>%
      mutate(population = pop) %>%
      arrange(ID, key) %>%
      factors() %>%
      relocate(population, .after = 1)
  }
  cl <- to_long(child_wide, "child")
  al <- to_long(adult_wide, "adult")

  readr::write_csv(cl, file.path(out_long, sprintf("study%s_children.csv", study)))
  readr::write_csv(al, file.path(out_long, sprintf("study%s_adults.csv",   study)))
  readr::write_csv(bind_rows(cl, al), file.path(out_comb, sprintf("study%s.csv", study)))
  invisible(NULL)
}

# ============================================================================
# READ SOURCES
# ============================================================================
chA <- read_csv(file.path(data_in, "OMIT_data_1.9.25.csv"), show_col_types = FALSE)
chB <- read_csv(file.path(data_in, "OMIT2_data_26.csv"),    show_col_types = FALSE)
adA <- read_csv(file.path(data_in, "OMIT-ADULT.csv"),       show_col_types = FALSE)
adB <- read_csv(file.path(data_in, "OMIT2_ADULT.csv"),      show_col_types = FALSE)

# ID + age for each source (adults have no subject ID -> create one)
chA <- chA %>% mutate(ID = as.character(ID),
                      age = AgeYears + AgeMonths/12 + AgeDays/365,
                      sex = Sex)
chB <- chB %>% mutate(ID = as.character(ID),
                      age = Age_Years + Age_Months/12 + Age_Days/365,
                      sex = Sex)
adA <- adA %>% mutate(ID = sprintf("A1_%03d", row_number()), age = NA_real_, sex = NA_character_)
adB <- adB %>% mutate(ID = sprintf("A2_%03d", row_number()),
                      age = suppressWarnings(as.numeric(Age)), sex = NA_character_)

# ============================================================================
# WAVE A  -> Study 1, Study 2A, Study 3A
# ============================================================================
# ---- Study 1 : infer closeness (better friend / ice cream / candy) ----------
s1_child <- chA %>% transmute(
  ID, age, sex,
  better_friend_sad = as01(Better_Friend_sad), better_friend_happy = as01(Better_Friend_happy),
  ice_cream_sad     = as01(Ice_Cream_sad),      ice_cream_happy     = as01(Ice_Cream_happy),
  candy_sad         = as01(Candy_sad),          candy_happy         = as01(Candy_happy))
s1_adult <- adA %>% transmute(
  ID, age, sex,
  better_friend_sad = as01(sad_bf),         better_friend_happy = as01(happy_bf),
  ice_cream_sad     = as01(sad_ice_cream),  ice_cream_happy     = as01(happy_ice_cream),
  candy_sad         = as01(sad_candy),      candy_happy         = as01(happy_candy))
s1_dv <- c("better_friend_sad","better_friend_happy","ice_cream_sad",
           "ice_cream_happy","candy_sad","candy_happy")
s1_fac <- function(d) d %>%
  separate(key, into = c("measure","emotion"), sep = "_(?=[^_]+$)") %>%
  mutate(measure = recode(measure, better_friend = "better_friend",
                          ice_cream = "ice_cream", candy = "candy"))

# ---- Study 2A : child discloses to mom vs friend's mom ----------------------
s2a_child <- chA %>% transmute(ID, age, sex,
  mom_sad = as01(Mom_sad), mom_happy = as01(Mom_happy),
  friendmom_sad = as01(FriendMom_sad), friendmom_happy = as01(FriendMom_happy))
s2a_adult <- adA %>% transmute(ID, age, sex,
  mom_sad = as01(mom_sad), mom_happy = as01(mom_happy),
  friendmom_sad = as01(friendmom_sad), friendmom_happy = as01(friendmom_happy))
rel_em_dv  <- c("mom_sad","mom_happy","friendmom_sad","friendmom_happy")
rel_em_fac <- function(d) d %>%
  separate(key, into = c("relationship","emotion"), sep = "_(?=[^_]+$)")

# ---- Study 3A : disclose to CREATE a relationship --------------------------
s3a_child <- chA %>% transmute(ID, age, sex,
  create_sad = as01(New_Friend_sad), create_happy = as01(New_Friend_happy))
s3a_adult <- adA %>% transmute(ID, age, sex,
  create_sad = as01(nf_sad), create_happy = as01(nf_happy))
emo_only_dv  <- function(stem) c(paste0(stem,"_sad"), paste0(stem,"_happy"))
emo_only_fac <- function(d) d %>%
  separate(key, into = c("measure","emotion"), sep = "_(?=[^_]+$)")

# ============================================================================
# WAVE B/C  -> Study 2B, Study 2C, Study 3B   (children file is TEXT -> recode)
# ============================================================================
# ---- Study 2B : mom / friend's mom discloses TO child ----------------------
s2b_child <- chB %>% transmute(ID, age, sex,
  mom_sad = recode_emo_text(Sad_Mom), mom_happy = recode_emo_text(Happy_Mom),
  friendmom_sad = recode_emo_text(Sad_FriendMom), friendmom_happy = recode_emo_text(Happy_FriendMom))
s2b_adult <- adB %>% transmute(ID, age, sex,
  mom_sad = as01(mom_sad), mom_happy = as01(mom_happy),
  friendmom_sad = as01(friendmom_sad), friendmom_happy = as01(friendmom_happy))

# ---- Study 2C : friend vs best friend --------------------------------------
s2c_child <- chB %>% transmute(ID, age, sex,
  friend_sad = recode_emo_text(Sad_Friend), friend_happy = recode_emo_text(Happy_Friend),
  bestfriend_sad = recode_emo_text(Sad_BF), bestfriend_happy = recode_emo_text(Happy_BF))
s2c_adult <- adB %>% transmute(ID, age, sex,
  friend_sad = as01(Friend_sad), friend_happy = as01(Friend_happy),
  bestfriend_sad = as01(BF_sad), bestfriend_happy = as01(BF_happy))
s2c_dv  <- c("friend_sad","friend_happy","bestfriend_sad","bestfriend_happy")

# ---- Study 3B : disclose to DEEPEN an existing friendship ------------------
s3b_child <- chB %>% transmute(ID, age, sex,
  deepen_sad = recode_emo_text(Sad_NF), deepen_happy = recode_emo_text(Happy_NF))
s3b_adult <- adB %>% transmute(ID, age, sex,
  deepen_sad = as01(nbf_sad), deepen_happy = as01(nbf_happy))

# ============================================================================
# WRITE EVERYTHING
# ============================================================================
message("Writing per-study files ...")
write_study(s1_child,  s1_adult,  s1_dv,            NULL, "1",  s1_fac)
write_study(s2a_child, s2a_adult, rel_em_dv,        NULL, "2A", rel_em_fac)
write_study(s3a_child, s3a_adult, emo_only_dv("create"), NULL, "3A", emo_only_fac)
write_study(s2b_child, s2b_adult, rel_em_dv,        NULL, "2B", rel_em_fac)
write_study(s2c_child, s2c_adult, s2c_dv,           NULL, "2C", rel_em_fac)
write_study(s3b_child, s3b_adult, emo_only_dv("deepen"), NULL, "3B", emo_only_fac)

# ============================================================================
# SUPPLEMENTARY (Wave A only; NOT reported in the manuscript text)
#   - circles : 1-7 closeness rating of the emotion- vs fact-target
#   - warmup  : 1-7 closeness rating of mom&child / strangers / friends
#   Children columns are unambiguous. Adult circle columns use character names
#   (orin/avery/cameron/riley) whose fact/emotion mapping is not recorded here,
#   so only the children's supplementary measures are exported.
# ============================================================================
supp_dir <- file.path(proj, "5. Analysis", "data_clean", "supplementary")
dir.create(supp_dir, showWarnings = FALSE, recursive = TRUE)

circles_child <- chA %>% transmute(ID, age, sex,
  fact_sad = Circles_fact_s, emo_sad = Circles_emo_s,
  fact_happy = Circles_fact_h, emo_happy = Circles_emo_h)
readr::write_csv(circles_child, file.path(supp_dir, "circles_children_wide.csv"))
circles_child %>%
  pivot_longer(c(fact_sad, emo_sad, fact_happy, emo_happy),
               names_to = "key", values_to = "closeness") %>%
  separate(key, into = c("target","emotion"), sep = "_(?=[^_]+$)") %>%
  readr::write_csv(file.path(supp_dir, "circles_children_long.csv"))

warmup_child <- chA %>% transmute(ID, age, sex,
  mom_and_child = Mom_and_Child, strangers = Strangers, friends = Friends)
readr::write_csv(warmup_child, file.path(supp_dir, "warmup_children_wide.csv"))
warmup_child %>%
  pivot_longer(c(mom_and_child, strangers, friends),
               names_to = "relationship", values_to = "closeness") %>%
  readr::write_csv(file.path(supp_dir, "warmup_children_long.csv"))

message("Done. Clean data written under 5. Analysis/data_clean/")
