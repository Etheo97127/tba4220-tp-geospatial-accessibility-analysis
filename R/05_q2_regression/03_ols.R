# 05_q2_regression/03_ols.R -----------------------------------------------------
# C3: OLS of the composite score on the five predictors over the residential set.
# Predictors are standardised, so each coefficient reads "score points per SD".
# H0: elderly share and housing mix have zero effect, tested one-sided against
# the expected negative sign (decision 4); density, distance to rail and mapping
# effort are controls. The same model per category is a supporting table.
# Association only, not cause.

source("R/00_setup.R")

score <- readRDS(file.path(DIR_PROC, "score_subzone.rds")) %>% st_drop_geometry()
cov   <- readRDS(file.path(DIR_PROC, "subzone_covariates.rds"))
nbobj <- readRDS(file.path(DIR_PROC, "q1_neighbours.rds"))

PREDICTORS <- c("elderly_share", "housing_mix", "log_density", "dist_rail_m", "log_contrib")
TESTED     <- c(elderly_share = "less", housing_mix = "less")   # one-sided alternatives
OUTCOMES   <- c("score", paste0("score_", CATEGORIES))

# Rows in the Q1 weights order, so the residual tests in 04 line up with lw_queen.
dat <- tibble(subzone_c = nbobj$subzone_c) %>%
  left_join(score %>% select(subzone_c, all_of(OUTCOMES)), by = "subzone_c") %>%
  left_join(cov %>% select(subzone_c, all_of(PREDICTORS)), by = "subzone_c") %>%
  mutate(across(all_of(PREDICTORS), ~ as.numeric(scale(.x))))
stopifnot(!anyNA(dat), identical(dat$subzone_c, nbobj$subzone_c))

model_formula <- function(outcome) reformulate(PREDICTORS, response = outcome)

tidy_lm <- function(m, outcome) {
  co <- summary(m)$coefficients
  tibble(outcome = outcome, term = rownames(co), estimate = co[, 1], se = co[, 2],
         t = co[, 3], p_two_sided = co[, 4]) %>%
    mutate(alternative = coalesce(TESTED[term], "two.sided"),
           # One-sided p: half the two-sided p when the sign is the expected one.
           p_one_sided = if_else(alternative == "less",
                                 if_else(estimate < 0, p_two_sided / 2, 1 - p_two_sided / 2),
                                 NA_real_))
}

vif <- function(d) {
  vapply(PREDICTORS, function(v) {
    r2 <- summary(lm(reformulate(setdiff(PREDICTORS, v), response = v), data = d))$r.squared
    1 / (1 - r2)
  }, numeric(1))
}

m_main <- lm(model_formula("score"), data = dat)
by_cat <- bind_rows(lapply(OUTCOMES, function(y) tidy_lm(lm(model_formula(y), data = dat), y)))
fit    <- tibble(outcome = OUTCOMES,
                 r2 = vapply(OUTCOMES, function(y) summary(lm(model_formula(y), data = dat))$r.squared, numeric(1)),
                 adj_r2 = vapply(OUTCOMES, function(y) summary(lm(model_formula(y), data = dat))$adj.r.squared, numeric(1)))

# Mapping effort is counted from the same OSM features the score counts, so it is
# partly mechanical. Refit without it to check the tested coefficients do not
# hinge on that control.
m_no_effort <- lm(reformulate(setdiff(PREDICTORS, "log_contrib"), response = "score"), data = dat)
sens <- tidy_lm(m_no_effort, "score") %>% mutate(model = "without mapping effort", r2 = summary(m_no_effort)$r.squared)

saveRDS(list(data = dat, predictors = PREDICTORS, tested = TESTED, ols = m_main),
        file.path(DIR_INT, "q2_model.rds"))
write_csv(by_cat %>% filter(outcome == "score") %>% mutate(across(where(is.numeric), ~ signif(.x, 4))),
          file.path(DIR_TAB, "q2_ols.csv"))
write_csv(by_cat %>% mutate(across(where(is.numeric), ~ signif(.x, 4))),
          file.path(DIR_TAB, "q2_ols_by_category.csv"))
write_csv(fit %>% mutate(across(where(is.numeric), ~ round(.x, 3))), file.path(DIR_TAB, "q2_ols_fit.csv"))
write_csv(tibble(predictor = PREDICTORS, vif = round(vif(dat), 2)), file.path(DIR_TAB, "q2_vif.csv"))
write_csv(sens %>% mutate(across(where(is.numeric), ~ signif(.x, 4))), file.path(DIR_TAB, "q2_ols_sensitivity.csv"))

main <- by_cat %>% filter(outcome == "score", term %in% names(TESTED))
log_step("OLS composite: R2 ", round(fit$r2[1], 3), "; ",
         paste0(main$term, " b = ", round(main$estimate, 2), " (one-sided p = ", signif(main$p_one_sided, 2), ")",
                collapse = ", "), "; max VIF ", round(max(vif(dat)), 2))
