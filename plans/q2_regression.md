# Q2: What explains access, and how much is just density?

Owner: Zachary Chng Yao Wei. Code: `R/05_q2_regression/`.

**H0:** coefficients on elderly share and housing mix are zero
(one-sided: negative for elderly share). Density is a control, not a finding.

## Method

- OLS: score ~ elderly share + housing mix + population density + distance to transit + OSM contributor density
- Collinearity check (VIF); drop near-empty subzones and report how many remain
- Moran's I on residuals (using Q1's `listw`); refit as spatial error model if needed

## Steps

- [x] C1 residential set (H2): `R/05_q2_regression/01_residential_set.R` → `data/processed/residential_set.csv` (`subzone_c`, `pop`, logical `residential`); 201 of 332 at ≥ 1,000 residents (99.65% of residents), 211 at ≥ 500 (`outputs/tables/q2_residential_n.csv`)
- [ ] C2 covariate table → `data/processed/subzone_covariates.rds`
- [ ] C3 OLS + VIF + one-sided tests, per category as a supporting table
- [ ] C4 residual Moran's I + LM tests on Q1's weights; spatial error model if needed
- [ ] C5 density share, raw-or-adjusted call (decision 1), adjusted scores, residuals (H7)
- [ ] C6 report section

## Inputs

- `data/processed/score_subzone.rds`
- `data/processed/census2020_subzone.csv`, `score_centres.rds` (prep / score) and the rail station layer, for the covariates (C2)
- `data/processed/q1_neighbours.rds`

## Hand-off

- `data/processed/q2_residuals.csv`: `subzone_c`, `residual`
- `outputs/tables/q2_density_share.csv`: share of variance from density alone; decides whether Q3 clusters on raw or density-adjusted scores
