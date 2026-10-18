# Q3: What kinds of neighbourhood exist? (target question)

Owner: Coltrane Yao Zhiming. Code: `R/06_q3_typology/`.

**H0(a):** the mix of neighbourhood types is the same in mature and non-mature towns.
**H0(b):** cluster membership is unrelated to Q2's residuals.

## Method

- k-means on the six category scores (density-adjusted if Q2 finds density dominant)
- k by elbow + silhouette; stability by spatial block bootstrap on Q1's blocks
- Type mix vs maturity: permutation within spatial blocks, not a naive chi-square
- Unstable groups are reported as unstable, not named

## Inputs

- `data/processed/score_subzone.rds`
- `data/processed/q1_blocks.csv`
- `data/processed/q2_residuals.csv`, `outputs/tables/q2_density_share.csv`
- `data/external/town_maturity.csv`

## Hand-off

`data/processed/q3_clusters.csv`: `subzone_c`, `cluster`, `stable`
