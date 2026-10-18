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
    "R/01_prep/02_osm.R"                        # Overpass JSON -> tidy sf points
  ),
  coverage = c(
    "R/02_coverage/01_match.R",                 # record linkage + threshold grid
    "R/02_coverage/02_gap_test.R",              # proportion test, logistic, random labelling
    "R/02_coverage/03_outputs.R",               # tables and figures
    "R/02_coverage/04_ceiling_and_validation.R" # matcher ceiling + manual-check sample
  ),
  score    = character(0),                      # R/03_score/        (Haotian)
  q1       = character(0),                      # R/04_q1_spatial/   (Hew)
  q2       = character(0),                      # R/05_q2_regression/ (Zachary)
  q3       = character(0)                       # R/06_q3_typology/  (Coltrane)
)

# Rscript R/run_all.R q2 q3  -> run only those stages (upstream outputs must exist)
only <- commandArgs(trailingOnly = TRUE)
if (length(only)) stages <- stages[only]

for (stage in names(stages)) {
  for (s in stages[[stage]]) {
    cat("\n", strrep("=", 70), "\n== [", stage, "] ", s, "\n", strrep("=", 70), "\n", sep = "")
    source(s, echo = FALSE)
  }
}
cat("\nDone. Tables in outputs/tables, figures in outputs/figures.\n")
