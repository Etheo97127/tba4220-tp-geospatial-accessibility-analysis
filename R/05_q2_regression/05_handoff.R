# 05_q2_regression/05_handoff.R -------------------------------------------------
# C5, the H7 hand-off to Q3. (1) How much of the explained variance is density
# alone, and so whether Q3 clusters on raw or density-adjusted scores, by the
# threshold fixed before any clustering (decision 1, DENSITY_SHARE_MAX).
# (2) Density-adjusted category scores: residuals of each score on log density.
# (3) The final model's residuals, against which Q3 tests under-service (H0(b)).
# "Under-served" means a score below what the predictors alone imply, so for a
# lag model the residual is the reduced form y - (I - rho W)^-1 X beta, not the
# innovation y - rho W y - X beta (which would count neighbours' observed scores
# as part of the prediction). For an error model it is y - X beta.

source("R/00_setup.R")
library(spdep)
library(spatialreg)

mod   <- readRDS(file.path(DIR_INT, "q2_model.rds"))
nbobj <- readRDS(file.path(DIR_PROC, "q1_neighbours.rds"))

dat <- mod$data
r2_full    <- summary(mod$ols)$r.squared
r2_density <- summary(lm(score ~ log_density, data = dat))$r.squared
share      <- r2_density / r2_full
call       <- if (share > DENSITY_SHARE_MAX) "adjusted" else "raw"

adjusted <- dat %>% select(subzone_c)
for (k in CATEGORIES) {
  adjusted[[paste0("score_", k, "_adj")]] <- residuals(lm(reformulate("log_density", paste0("score_", k)), data = dat))
}

reduced_form_residual <- function(mod, dat, lw) {
  X <- model.matrix(formula(mod$ols), dat)
  y <- dat$score
  switch(mod$final,
         ols   = as.numeric(residuals(mod$ols)),
         error = as.numeric(y - X %*% coef(mod$sem)[colnames(X)]),
         lag   = {
           W <- listw2mat(lw)
           fitted <- solve(diag(nrow(W)) - mod$slm$rho * W, X %*% coef(mod$slm)[colnames(X)])
           as.numeric(y - fitted)
         })
}

stopifnot(identical(dat$subzone_c, nbobj$subzone_c))
resid <- tibble(subzone_c = dat$subzone_c,
                residual = reduced_form_residual(mod, dat, nbobj$lw_queen),
                model = mod$final)

write_csv(tibble(r2_density = r2_density, r2_full = r2_full, density_share = share,
                 threshold = DENSITY_SHARE_MAX, q3_clusters_on = call) %>%
            mutate(across(where(is.numeric), ~ round(.x, 4))),
          file.path(DIR_TAB, "q2_density_share.csv"))
write_csv(adjusted %>% mutate(across(-subzone_c, ~ round(.x, 4))), file.path(DIR_PROC, "q2_adjusted_scores.csv"))
write_csv(resid %>% mutate(residual = round(residual, 4)), file.path(DIR_PROC, "q2_residuals.csv"))
log_step("density alone explains R2 ", round(r2_density, 3), " of ", round(r2_full, 3), " (share ",
         round(share, 2), ", threshold ", DENSITY_SHARE_MAX, "): Q3 clusters on ", call,
         " scores; residuals from the ", mod$final, " model")
