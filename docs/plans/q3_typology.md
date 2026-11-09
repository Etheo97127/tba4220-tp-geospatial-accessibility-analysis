# Q3: What kinds of neighbourhood exist? (target question)

Owner: Coltrane Yao Zhiming. Code: `R/06_q3_typology/`.

**H0(a):** the mix of neighbourhood types is the same in mature and non-mature towns.
**H0(b):** cluster membership is unrelated to Q2's residuals.

## Method

- k-means on the six category scores (density-adjusted if Q2 finds density dominant)
- k by elbow + silhouette, tested against a no-cluster null (single Gaussian clouds with the scores' covariance); stability by spatial block bootstrap on Q1's blocks
- Type mix vs maturity: town labels permuted between whole blocks (decision 12), not a naive chi-square; residual test permutes within blocks (decision 5)
- Unstable groups are reported as unstable, not named

## Steps

- [x] D1 town list: `data/input/external/town_maturity.csv` with `source` and `as_of` (HDB classification last in force before Oct 2024); excluded areas left out of H₀(a) (decision 6). Residential set: 106 mature, 70 non-mature, 25 excluded subzones
- [x] D2 inputs: `R/06_q3_typology/01_inputs.R` → `data/output/interim/q3_inputs.rds`: six category scores (raw, per Q2's call), z-scored over the residential set, with block, town group and Q2 residual. Stops if Q1's `q1_outliers.csv` (H6) lists any subzone, so outliers cannot silently seed a type; it lists none
- [x] D3 k and stability: `02_choose_k.R` (simulation check recovers 3 planted groups, which also beat their null; silhouette rule gives **k = 2**, 0.36 vs 0.28 at k = 3; **null test p = 0.47**: 200 no-cluster clouds with the same covariance reach the same silhouette, so there is **no evidence of discrete types**, `data/output/tables/q3_null_test.csv`) and `03_stability.R` → `data/output/processed/q3_clusters.csv` (`subzone_c`, `cluster`, `stable`), `data/output/tables/q3_stability.csv`. 200 block-bootstrap draws on Q1's 31 blocks, Hungarian matching: type 1 (92 subzones) Jaccard 0.92, type 2 (109) 0.93, both stable. A k-means cut through a continuum is also stable, so stability here shows a reproducible high/low cut, not distinct types
- [x] D4 H₀(a): `04_tests.R` → `data/output/tables/q3_tests.csv`, `q3_type_mix.csv`. χ² of type × town group with town labels permuted between whole blocks (26 labelled blocks, 999 draws): χ² 2.97, **p = 0.27, H₀(a) not rejected**. Type 1 is 42% of mature-town subzones and 56% of non-mature ones, a gap well within what block-level relabelling produces
- [x] D5 H₀(b): same script, `q3_residual_by_type.csv`. F of residual ~ type with residuals permuted within blocks: F 133, **p = 0.001, H₀(b) rejected**. The residual is the lag model's reduced form, y − (I − ρW)⁻¹Xβ (a score below what the predictors alone imply). Type 1 averages −6.0 points, type 2 +6.3. Caveat for the report: types are defined on the scores and residuals are score minus prediction, so a low-access type gets negative residuals partly by construction; within-block permutation does not remove that. Read it as "the low-access type is not explained away by density, rail distance or mapping effort", not as an independent finding of under-service
- [x] D6 profiles: `05_profiles.R` → `data/output/tables/q3_types.csv`, `q3_profiles.csv`, `data/output/figures/q3_profiles.png`, `q3_types_map.png`. Names by a fixed rule (level ±0.5 SD; standout category ±0.5 SD from the type's own mean; "under-served" avoided because the plan reserves it for negative Q2 residuals): with the null test's verdict, the groups are named as ends of one gradient: **Low-access end** (92 subzones, every category 0.5–0.8 SD below average) and **High-access end** (109). No standout categories: they differ in level, not mix

Next (for the Discussion): the six category scores do not separate into discrete neighbourhood types. They vary along one general-access gradient (PC1 carries about 70% of the variance; food services, retail and food retail correlate at Spearman 0.84–0.88), and k = 2 is a reproducible high/low cut through it, no better separated than a no-cluster null (p = 0.47). Density explains only a third of Q2's model, so the gradient is not just density. We find no evidence that mature and non-mature towns hold the two ends in different proportions (H₀(a) p = 0.27), though with 26 labelled blocks the test has little power. The answer to the target question: Singapore's residential subzones differ in how much everyday service lies within walking distance, not in what kind, with no clear difference between older and newer towns in where they sit on it. H₀(b) (p = 0.001) is partly mechanical, as noted under D5.
- [x] D7 Q3 report section: `report/sections/05_q3_typology.Rmd`
- [x] D7 Discussion: `report/sections/06_discussion.Rmd`; the first paragraph answers the target question, followed by limitations

## Inputs

- `data/output/processed/score_subzone.rds`
- `data/output/processed/q1_blocks.csv`
- `data/output/processed/q2_residuals.csv`, `data/output/tables/q2_density_share.csv`
- `data/input/external/town_maturity.csv`

## Hand-off

`data/output/processed/q3_clusters.csv`: `subzone_c`, `cluster`, `stable`; type names and the null verdict (`structure`) in `data/output/tables/q3_types.csv`
