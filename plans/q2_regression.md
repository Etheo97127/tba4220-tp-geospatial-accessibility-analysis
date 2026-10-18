# Q2: What explains access, and how much is just density?

Owner: Zachary Chng Yao Wei. Code: `R/05_q2_regression/`.

**H0:** coefficients on elderly share and housing mix are zero
(one-sided: negative for elderly share). Density is a control, not a finding.

## Method

- OLS: score ~ elderly share + housing mix + population density + distance to transit + OSM contributor density
- Collinearity check (VIF); drop near-empty subzones and report how many remain
- Moran's I on residuals (using Q1's `listw`); refit as spatial error model if needed

## Inputs

- `data/processed/score_subzone.rds`
- `data/processed/subzone_covariates.rds` (Census 2020 age + dwelling type, MRT stations, maturity); built in `R/01_prep/`, not yet written
- `data/processed/q1_neighbours.rds`

## Hand-off

- `data/processed/q2_residuals.csv`: `subzone_c`, `residual`
- `outputs/tables/q2_density_share.csv`: share of variance from density alone; decides whether Q3 clusters on raw or density-adjusted scores
