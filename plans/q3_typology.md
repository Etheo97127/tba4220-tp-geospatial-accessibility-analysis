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
- [x] D3 k and stability: `02_choose_k.R` (simulation check recovers 3 planted groups; silhouette rule gives **k = 2**, 0.36 vs 0.28 at k = 3) and `03_stability.R` → `data/processed/q3_clusters.csv` (`subzone_c`, `cluster`, `stable`), `outputs/tables/q3_stability.csv`. 200 block-bootstrap draws on Q1's 31 blocks, Hungarian matching: type 1 (92 subzones) Jaccard 0.92, type 2 (109) 0.93, **both stable**
- [x] D4 H₀(a): `04_tests.R` → `outputs/tables/q3_tests.csv`, `q3_type_mix.csv`. χ² of type × town group with town labels permuted between whole blocks (26 labelled blocks, 999 draws): χ² 2.97, **p = 0.27, H₀(a) not rejected**. Type 1 is 43% of mature-town subzones and 56% of non-mature ones, a gap well within what block-level relabelling produces
- [x] D5 H₀(b): same script, `q3_residual_by_type.csv`. F of residual ~ type with residuals permuted within blocks: F 104, **p = 0.001, H₀(b) rejected**. Type 1 averages −5.5 points below Q2's prediction, type 2 +4.7. Caveat for the report: types are defined on the scores and residuals are score minus prediction, so a low-access type gets negative residuals partly by construction; within-block permutation does not remove that. Read it as "the low-access type is not explained away by density, rail distance or mapping effort", not as an independent finding of under-service
- [ ] D6 profile, name and map the stable types (H8)
- [ ] D7 report section and Discussion

## Inputs

- `data/processed/score_subzone.rds`
- `data/processed/q1_blocks.csv`
- `data/processed/q2_residuals.csv`, `outputs/tables/q2_density_share.csv`
- `data/external/town_maturity.csv`

## Hand-off

`data/processed/q3_clusters.csv`: `subzone_c`, `cluster`, `stable`
