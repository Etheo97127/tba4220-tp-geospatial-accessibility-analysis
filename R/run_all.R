# run_all.R -------------------------------------------------------------------
# Whole pipeline, end to end. Run from the repo root (open the .Rproj first):
#   Rscript R/run_all.R
# Raw data is read from data/raw/ and never written to. Everything under
# data/interim, data/processed and outputs/ is regenerated.
#
# Stages run in dependency order: the score feeds Q1-Q3, Q1's contiguity
# blocks and Q2's residuals feed Q3. Add new scripts to the matching stage.

stages <- list(
  prep = c(
    "R/01_prep/01_reference.R",                 # MP19 subzone frame + ECDA/CHAS reference lists
    "R/01_prep/02_osm.R",                       # Overpass JSON -> tidy sf points
    "R/01_prep/03_census.R",                    # Census 2020 counts by subzone_c
    "R/01_prep/04_buildings.R",                 # residential footprints + floor-area weight
    "R/01_prep/05_hes_weights.R",               # HES 2023 category weights
    "R/01_prep/06_rail_stations.R",             # rail stations in service
    "R/01_prep/07_osm_contributors.R",          # OSM mappers per km2 (mapping effort)
    "R/05_q2_regression/01_residential_set.R"   # H2, run here: score and Q1 read it
  ),
  coverage = c(
    "R/02_coverage/01_match.R",                 # record linkage + threshold grid
    "R/02_coverage/02_gap_test.R",              # proportion test, logistic, random labelling
    "R/02_coverage/03_quality_flag.R",          # subzone quality flag (hand-off)
    "R/02_coverage/04_outputs.R",               # tables and figures
    "R/02_coverage/05_ceiling_and_validation.R", # matcher ceiling + validation sample
    "R/02_coverage/06_matcher_error.R"          # false-match / false-miss rates, corrected recall
  ),
  score    = c(                                 # R/03_score/        (Haotian)
    "R/03_score/01_centres.R",                  # population-weighted centres (A4)
    "R/03_score/02_score.R",                    # counts, HES weights, variants (A5, A8)
    "R/03_score/03_outputs.R"                   # maps
  ),
  q1       = c(                                 # R/04_q1_spatial/   (Hew)
    "R/04_q1_spatial/01_weights.R",             # queen + kNN weights on the residential set (H3)
    "R/04_q1_spatial/02_blocks.R",              # resampling blocks (H3)
    "R/04_q1_spatial/03_morans_i.R",            # global Moran's I per category (B4)
    "R/04_q1_spatial/04_lisa.R",                # LISA with BH correction (B5)
    "R/04_q1_spatial/05_memo.R"                 # H6 memo to Q3 (B6)
  ),
  q2       = c(                                 # R/05_q2_regression/ (Zachary)
    "R/05_q2_regression/02_covariates.R",       # elderly share, housing mix, controls
    "R/05_q2_regression/03_ols.R",              # OLS, VIF, one-sided tests (C3)
    "R/05_q2_regression/04_spatial_model.R",    # residual tests, spatial error / lag (C4)
    "R/05_q2_regression/05_handoff.R"           # density share, adjusted scores, residuals (H7)
  ),
  q3       = c(                                 # R/06_q3_typology/  (Coltrane)
    "R/06_q3_typology/01_inputs.R",             # z-scored scores, blocks, town group, residuals
    "R/06_q3_typology/02_choose_k.R",           # elbow + silhouette, simulation check (D3)
    "R/06_q3_typology/03_stability.R",          # block bootstrap, H8 clusters (D3)
    "R/06_q3_typology/04_tests.R",              # H0(a) and H0(b) block permutations (D4, D5)
    "R/06_q3_typology/05_profiles.R"            # profiles, names, maps (D6)
  )
)

# Rscript R/run_all.R q2 q3  -> run only those stages (upstream outputs must exist)
only <- commandArgs(trailingOnly = TRUE)
unknown <- setdiff(only, names(stages))
if (length(unknown)) stop("unknown stage: ", paste(unknown, collapse = ", "))

# Coverage and score also read prep's layers in data/interim/ (subzones, OSM POIs,
# reference lists, buildings). Git does not keep them, since prep rebuilds them
# from data/raw/ in seconds, so on a fresh clone prep runs first.
PREP_LAYERS <- file.path("data", "interim", c("subzones.rds", "osm_poi.rds", "reference.rds", "res_buildings.rds"))
if (length(only) && any(c("coverage", "score") %in% only) && !"prep" %in% only &&
    !all(file.exists(PREP_LAYERS))) {
  cat("prep layers missing from data/interim/: running prep first\n")
  only <- c("prep", only)
}
if (length(only)) stages <- stages[names(stages) %in% only]

for (stage in names(stages)) {
  for (s in stages[[stage]]) {
    cat("\n", strrep("=", 70), "\n== [", stage, "] ", s, "\n", strrep("=", 70), "\n", sep = "")
    source(s, echo = FALSE)
  }
}
cat("\nDone. Tables in outputs/tables, figures in outputs/figures.\n")
