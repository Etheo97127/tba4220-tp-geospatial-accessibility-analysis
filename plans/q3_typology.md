# Q3: What kinds of neighbourhood exist? (target question)

Owner: Coltrane Yao Zhiming. Code: `R/06_q3_typology/`.

**H0(a):** the mix of neighbourhood types is the same in mature and non-mature towns.
**H0(b):** cluster membership is unrelated to Q2's residuals.

## Method

- k-means on the six category scores (density-adjusted if Q2 finds density dominant)
- k by elbow + silhouette; stability by spatial block bootstrap on Q1's blocks
- Type mix vs maturity: permutation within spatial blocks, not a naive chi-square
- Unstable groups are reported as unstable, not named

## Steps

- [x] D1 town list: `data/external/town_maturity.csv` with `source` and `as_of` (HDB classification last in force before Oct 2024); excluded areas left out of H₀(a) (decision 6). Residential set: 106 mature, 70 non-mature, 25 excluded subzones
- [x] D2 inputs: `R/06_q3_typology/01_inputs.R` → `data/interim/q3_inputs.rds`: six category scores (raw, per Q2's call), z-scored over the residential set, with block, town group and Q2 residual
- [ ] D3 choose k and test stability (block bootstrap)
- [ ] D4 H₀(a) type mix vs town group, labels permuted between whole blocks (decision 12)
- [ ] D5 H₀(b) type vs Q2 residual, residuals permuted within blocks (decision 5)
- [ ] D6 profile, name and map the stable types (H8)
- [ ] D7 report section and Discussion

## Inputs

- `data/processed/score_subzone.rds`
- `data/processed/q1_blocks.csv`
- `data/processed/q2_residuals.csv`, `outputs/tables/q2_density_share.csv`
- `data/external/town_maturity.csv`

## Hand-off

`data/processed/q3_clusters.csv`: `subzone_c`, `cluster`, `stable`
