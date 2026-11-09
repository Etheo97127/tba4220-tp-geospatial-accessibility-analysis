# report/scripts/results_q2.R ---------------------------------------------------
# Values the Q2 parts of Methods and Analysis quote: OLS, the spatial models,
# the category models with a Holm correction, and density's share of R².

ols   <- tab("q2_ols.csv")
vif   <- tab("q2_vif.csv")
diag  <- tab("q2_spatial_diagnostics.csv")
mods  <- tab("q2_models.csv")
dens  <- tab("q2_density_share.csv")
sens  <- tab("q2_ols_sensitivity.csv")
fit   <- tab("q2_ols_fit.csv")
bycat <- tab("q2_ols_by_category.csv")

# The two tested terms across the six category models: 12 one-sided tests,
# Holm-corrected here because the pipeline reports them uncorrected.
cat_t <- bycat %>% filter(outcome != "score", alternative == "less") %>%
  mutate(p_holm = p.adjust(p_one_sided, method = "holm")) %>% arrange(p_one_sided)
slope_scale <- 1 / (1 - diag$rho_lag)   # lag coefficient -> total impact

TERM_LAB <- c(elderly_share = "Elderly share (65+)", housing_mix = "Housing mix (HDB 1–3 room)",
              log_density = "Log population density", dist_rail_m = "Distance to rail",
              log_contrib = "OSM mapping effort")
lag_tot <- mods %>% filter(model == "spatial lag (total impact)")
sem     <- mods %>% filter(model == "spatial error")
co      <- function(d, t, col = "estimate") d[[col]][d$term == t]
# One-sided p for the two tested terms, two-sided for the controls.
p_used  <- function(d, t) { p <- co(d, t, "p_one_sided"); if (is.na(p)) co(d, t, "p_two_sided") else p }
