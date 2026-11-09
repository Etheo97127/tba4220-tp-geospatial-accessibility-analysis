# 06_q3_typology/01_inputs.R ----------------------------------------------------
# Everything Q3 clusters and tests on, one row per residential subzone: the six
# category scores (raw or density-adjusted, as Q2's call under decision 1 says),
# z-scored over the residential set so every category weighs the same in the
# distance; the resampling block (H3); the town group (H1, decision 6); and the
# Q2 residual (H7).

source("R/00_setup.R")

score    <- readRDS(file.path(DIR_PROC, "score_subzone.rds")) %>% st_drop_geometry()
res      <- read_csv(file.path(DIR_PROC, "residential_set.csv"), show_col_types = FALSE)
blocks   <- read_csv(file.path(DIR_PROC, "q1_blocks.csv"), show_col_types = FALSE)
resid    <- read_csv(file.path(DIR_PROC, "q2_residuals.csv"), show_col_types = FALSE)
adjusted <- read_csv(file.path(DIR_PROC, "q2_adjusted_scores.csv"), show_col_types = FALSE)
cluster_on <- read_csv(file.path(DIR_TAB, "q2_density_share.csv"), show_col_types = FALSE)$q3_clusters_on
maturity <- read_csv(file.path(DIR_EXT, "town_maturity.csv"), show_col_types = FALSE)
pa       <- read_csv(file.path(DIR_PROC, "census2020_subzone.csv"), show_col_types = FALSE) %>%
  select(subzone_c, pln_area_n)
outliers <- read_csv(file.path(DIR_PROC, "q1_outliers.csv"), show_col_types = FALSE)

# H6: subzones Q1 finds as High-Low / Low-High outliers are single extreme
# subzones, not a kind of neighbourhood, and must not seed a type. Q1 finds none;
# if it ever does, decide how Q3 sets them aside before clustering.
if (nrow(outliers)) stop(nrow(outliers), " Q1 outlier subzones in q1_outliers.csv: decide how Q3 treats them first")

raw_cols <- paste0("score_", CATEGORIES)
scores <- if (cluster_on == "adjusted") {
  adjusted %>% rename_with(~ sub("_adj$", "", .x), -subzone_c)
} else {
  score %>% select(subzone_c, all_of(raw_cols))
}

dat <- res %>% filter(residential) %>% select(subzone_c) %>%
  left_join(scores, by = "subzone_c") %>%
  left_join(blocks, by = "subzone_c") %>%
  left_join(pa, by = "subzone_c") %>%
  left_join(maturity %>% select(pln_area_n, maturity), by = "pln_area_n") %>%
  left_join(resid %>% select(subzone_c, residual), by = "subzone_c") %>%
  arrange(subzone_c)
stopifnot(nrow(dat) == sum(res$residential), !anyNA(dat))

X <- scale(as.matrix(dat[raw_cols]))
colnames(X) <- CATEGORIES

saveRDS(list(data = dat, X = X, scores_used = cluster_on), file.path(DIR_INT, "q3_inputs.rds"))
log_step("Q3 inputs: ", nrow(dat), " residential subzones, ", cluster_on, " category scores, ",
         n_distinct(dat$block_id), " blocks; town groups ",
         paste(names(table(dat$maturity)), table(dat$maturity), collapse = ", "))
