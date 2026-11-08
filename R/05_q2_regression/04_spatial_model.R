# 05_q2_regression/04_spatial_model.R -------------------------------------------
# C4: are the OLS residuals spatially correlated (Moran's I on residuals, queen
# weights from Q1), and if so, which spatial model fits? The robust LM tests
# decide (Anselin's rule): robust error significant only -> spatial error model;
# robust lag significant only -> spatial lag model; both -> the larger statistic;
# neither -> OLS stands. A lag model's coefficients are not marginal effects, so
# its tested terms are read through total impacts (direct + spill-over).

source("R/00_setup.R")
library(spdep)
library(spatialreg)

mod   <- readRDS(file.path(DIR_INT, "q2_model.rds"))
nbobj <- readRDS(file.path(DIR_PROC, "q1_neighbours.rds"))

ALPHA     <- 0.05
N_IMPACTS <- 2000   # simulations for impact p-values

dat <- mod$data
ols <- mod$ols
lw  <- nbobj$lw_queen
stopifnot(identical(dat$subzone_c, nbobj$subzone_c))

one_sided <- function(term, estimate, p_two) {
  alt <- coalesce(mod$tested[term], "two.sided")
  if_else(alt == "less", if_else(estimate < 0, p_two / 2, 1 - p_two / 2), NA_real_)
}

# --- residual autocorrelation and LM tests -----------------------------------

mi <- lm.morantest(ols, lw, alternative = "greater")
lm_tests <- lm.RStests(ols, lw, test = "all")
lm_tab <- tibble(test = names(lm_tests),
                 statistic = vapply(lm_tests, function(t) as.numeric(t$statistic), numeric(1)),
                 p_value   = vapply(lm_tests, function(t) as.numeric(t$p.value), numeric(1)))
rob <- setNames(lm_tab$p_value, lm_tab$test)[c("adjRSerr", "adjRSlag")]
rob_stat <- setNames(lm_tab$statistic, lm_tab$test)[c("adjRSerr", "adjRSlag")]

final <- case_when(rob[["adjRSerr"]] < ALPHA & rob[["adjRSlag"]] < ALPHA ~
                     if_else(rob_stat[["adjRSlag"]] > rob_stat[["adjRSerr"]], "lag", "error"),
                   rob[["adjRSlag"]] < ALPHA ~ "lag",
                   rob[["adjRSerr"]] < ALPHA ~ "error",
                   TRUE ~ "ols")

# --- models ------------------------------------------------------------------

sem <- errorsarlm(formula(ols), data = dat, listw = lw)
slm <- lagsarlm(formula(ols), data = dat, listw = lw)

coef_table <- function(co, model) {
  tibble(model = model, term = rownames(co), estimate = co[, 1], se = co[, 2], p_two_sided = co[, 4]) %>%
    mutate(p_one_sided = one_sided(term, estimate, p_two_sided))
}

# Lag model: total impact of each predictor, with simulated standard errors.
set.seed(SEED)
imp <- summary(impacts(slm, listw = lw, R = N_IMPACTS), zstats = TRUE, short = TRUE)
lag_total <- tibble(model = "spatial lag (total impact)", term = sub(" dy/dx$", "", rownames(imp$semat)),
                    estimate = as.numeric(imp$res$total),
                    se = as.numeric(imp$semat[, "Total"]),
                    p_two_sided = as.numeric(imp$pzmat[, "Total"])) %>%
  mutate(p_one_sided = one_sided(term, estimate, p_two_sided))

coefs <- bind_rows(coef_table(summary(ols)$coefficients, "OLS"),
                   coef_table(summary(sem)$Coef, "spatial error"),
                   coef_table(summary(slm)$Coef, "spatial lag (coefficient)"),
                   lag_total)

diag <- tibble(
  residual_moran_I = as.numeric(mi$estimate[1]), residual_moran_p = as.numeric(mi$p.value),
  robust_lm_error_p = rob[["adjRSerr"]], robust_lm_lag_p = rob[["adjRSlag"]],
  lambda_error = as.numeric(sem$lambda), rho_lag = as.numeric(slm$rho),
  aic_ols = AIC(ols), aic_error = AIC(sem), aic_lag = AIC(slm),
  final_model = final
)

mod$sem <- sem; mod$slm <- slm; mod$final <- final
saveRDS(mod, file.path(DIR_INT, "q2_model.rds"))
write_csv(lm_tab %>% mutate(across(where(is.numeric), ~ signif(.x, 4))), file.path(DIR_TAB, "q2_lm_tests.csv"))
write_csv(coefs %>% mutate(across(where(is.numeric), ~ signif(.x, 4))), file.path(DIR_TAB, "q2_models.csv"))
write_csv(diag %>% mutate(across(where(is.numeric), ~ signif(.x, 4))), file.path(DIR_TAB, "q2_spatial_diagnostics.csv"))
log_step("residual Moran's I ", round(diag$residual_moran_I, 3), " (p = ", signif(diag$residual_moran_p, 2),
         "); robust LM error p = ", signif(rob[["adjRSerr"]], 2), ", lag p = ", signif(rob[["adjRSlag"]], 2),
         "; final model: ", final, " (AIC OLS ", round(diag$aic_ols, 1), ", error ", round(diag$aic_error, 1),
         ", lag ", round(diag$aic_lag, 1), ")")
