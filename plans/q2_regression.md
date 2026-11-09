# Q2: What explains access, and how much is just density?

Owner: Zachary Chng Yao Wei. Code: `R/05_q2_regression/`.

**H0:** coefficients on elderly share and housing mix are zero
(one-sided: negative for elderly share). Density is a control, not a finding.

## Method

- OLS: score ~ elderly share + housing mix + population density + distance to transit + OSM contributor density
- Collinearity check (VIF); drop near-empty subzones and report how many remain
- Moran's I on residuals (using Q1's `listw`); robust LM tests choose a spatial error or lag model (decision 10 as amended)

## Steps

- [x] C1 residential set (H2): `R/05_q2_regression/01_residential_set.R` → `data/processed/residential_set.csv` (`subzone_c`, `pop`, logical `residential`); 201 of 332 at ≥ 1,000 residents (99.65% of residents), 211 at ≥ 500 (`outputs/tables/q2_residential_n.csv`)
- [x] C2 covariate table: `R/05_q2_regression/02_covariates.R` → `data/processed/subzone_covariates.rds`, 332 rows (filter `residential`): `subzone_c`, `residential`, `pop`, `area_km2`, `elderly_share` (65+ / residents), `housing_mix` (HDB 1–3 room residents / all, decision 4), `log_density` (log residents per km²), `dist_rail_m` (centre to nearest station footprint in service), `nearest_station`, `contributors_per_km2`, `log_contrib` (log1p). NA only where pop = 0. Residential medians: 401 m to rail, 16.6% elderly, 11.2% housing mix (`outputs/tables/q2_covariates_summary.csv`)
- [x] C3 OLS: `R/05_q2_regression/03_ols.R` → `outputs/tables/q2_ols.csv`, `q2_ols_by_category.csv`, `q2_ols_fit.csv`, `q2_vif.csv`, `q2_ols_sensitivity.csv`. Standardised predictors, 201 subzones, R² 0.53, max VIF 2.2. **H₀ not rejected** for elderly share (b = +0.25, one-sided p = 0.59) or housing mix (b = +0.12, p = 0.54). Distance to rail −4.1 per SD (p < 0.001), log density +2.3 (p = 0.01), mapping effort +7.6 (p < 0.001). Without mapping effort (partly mechanical: it is counted from the same OSM features), R² 0.37 and elderly share turns *positive* (b = +2.5, two-sided p = 0.03), still the wrong side for the one-sided test
- [x] C4 spatial model: `R/05_q2_regression/04_spatial_model.R` → `outputs/tables/q2_lm_tests.csv`, `q2_models.csv` (OLS, error, lag coefficients and lag total impacts), `q2_spatial_diagnostics.csv`. OLS residuals are autocorrelated (Moran's I 0.28, p < 0.001). The plan expected a spatial error model, but the robust LM tests point to **lag** (robust error p = 0.42, robust lag p < 0.001), and lag also has the lowest AIC (1,468 vs error 1,485, OLS 1,525), so the final model is the spatial lag model (ρ = 0.54) by Anselin's rule. The rule was added with its first results, so treat the switch as evidence-led rather than pre-registered; the error model gives the same conclusion (elderly share +1.0, housing mix +0.05, both one-sided p > 0.5). Total impacts: elderly share +1.4 (one-sided p = 0.77), housing mix −1.1 (p = 0.28): **H₀ still not rejected**; distance to rail −7.1, log density +5.7, mapping effort +8.8 (all p < 0.01)
- [x] C5 hand-off (H7): `R/05_q2_regression/05_handoff.R` → `outputs/tables/q2_density_share.csv`, `data/processed/q2_adjusted_scores.csv` (`subzone_c`, `score_<cat>_adj`), `data/processed/q2_residuals.csv` (`subzone_c`, `residual`, `model`). Density alone explains R² 0.17 of the full 0.53, a share of 0.32, under the 0.5 threshold (decision 1, `DENSITY_SHARE_MAX`), so **Q3 clusters on raw scores**. Residuals are the spatial lag model's reduced form, y − (I − ρW)⁻¹Xβ: a score below what the predictors alone imply
- [x] C6 report section: `report/sections/04_q2_regression.Rmd` (Table 2: OLS and lag-model total impacts)

## Inputs

- `data/processed/score_subzone.rds`
- `data/processed/census2020_subzone.csv`, `score_centres.rds` (prep / score) and the rail station layer, for the covariates (C2)
- `data/processed/q1_neighbours.rds`

## Hand-off

- `data/processed/q2_residuals.csv`: `subzone_c`, `residual` (reduced form), `model`
- `data/processed/q2_adjusted_scores.csv`: `subzone_c`, `score_<category>_adj` (residual of each category score on log density)
- `outputs/tables/q2_density_share.csv`: share of variance from density alone; decides whether Q3 clusters on raw or density-adjusted scores
