# report/scripts/results_score.R ------------------------------------------------
# Values the Data, Methods and Analysis sections quote for the residential set,
# the access score and the OSM coverage check. Reads pipeline outputs only.

# --- residential set and score ---------------------------------------------------
resn   <- tab("q2_residential_n.csv")
cut_hi <- max(resn$cut_off); cut_lo <- min(resn$cut_off)
n_res  <- resn$n_residential[resn$cut_off == cut_hi]
n_res2 <- resn$n_residential[resn$cut_off == cut_lo]
res_sh <- resn$share_of_residents[resn$cut_off == cut_hi]

w      <- tab("score_weights.csv")
summ   <- tab("score_category_summary.csv")
rob    <- tab("score_robustness.csv")
score  <- readRDS(file.path(OUT, "processed", "score_subzone.rds"))
sc_res <- score$score[score$residential]
req    <- rob$spearman[rob$column == "score_equal"]
r800   <- rob$spearman[rob$column == "score_r800"]
r1200  <- rob$spearman[rob$column == "score_r1200"]

# --- OSM coverage check (ECDA preschools headline, CHAS supplementary) --------------
rec    <- tab("coverage_recall_by_category.csv")
recc   <- tab("coverage_recall_corrected.csv")
prop   <- tab("coverage_prop_test.csv")
rl     <- tab("coverage_random_labelling.csv")
logit  <- tab("coverage_logistic.csv")
lsens  <- tab("coverage_logistic_sensitivity.csv")
merr   <- tab("coverage_matcher_error.csv")
qflag  <- proc("subzone_quality_flag.csv")

e_rec   <- rec %>% filter(grepl("ECDA", set), variant == "strict")
e_cor   <- recc %>% filter(set == "ecda")
e_prop  <- prop %>% filter(set == "ecda")
e_rl    <- rl %>% filter(set == "ecda")
c_rl    <- rl %>% filter(set == "chas")
e_or    <- logit %>% filter(set == "ecda", term == "maturitynon-mature")
e_fm    <- merr %>% filter(set == "ecda", stratum == "accepted match")
e_fmiss <- merr %>% filter(set == "ecda", stratum != "accepted match")
e_both  <- lsens %>% filter(dropped == "Sengkang and Hougang")
n_better <- sum(qflag$quality_flag == "better", na.rm = TRUE)
n_worse  <- sum(qflag$quality_flag == "worse", na.rm = TRUE)

# Rows still flagged for a Google Maps check; settled rows are set to FALSE.
verdicts  <- ext("coverage_validation_verdicts.csv")
maps_left <- sum(verdicts$needs_maps_check)
prov      <- if (maps_left > 0) ", provisionally" else ""
tag_gap_txt <- if (e_fmiss$n_tag_gap > 0) sprintf(paste0(
  " Another %d of the %d are in OSM only as a building tagged kindergarten, a tag the score does not read;",
  " counting such buildings, OSM holds about %s."),
  e_fmiss$n_tag_gap, e_fmiss$n_checked, pct(e_cor$recall_any_tag, 0)) else ""
