# Q1: How is each category structured in space?

Owner: Hew Xing Yi. Code: `R/04_q1_spatial/`.

**H0:** Moran's I = 0, run per category (six) and for the composite score.

## Method

- Queen contiguity, k-nearest-neighbours as a check; 999 permutations
- LISA for local clusters, Benjamini-Hochberg corrected (decision 8); Gi* dropped (decision 10)
- Flag categories concentrated below subzone scale (outlier subzones, not neighbourhood types)

## Steps

- [x] B3 shared figure theme: `theme_project()`, `theme_map()`, `save_fig()` and palettes in `R/00_setup.R`
- [x] B1 weights (H3): `R/04_q1_spatial/01_weights.R` → `data/output/processed/q1_neighbours.rds` (list: `subzone_c` order, `nb_queen`, `lw_queen`, `nb_knn`, `lw_knn`; row-standardised). 201 subzones, queen mean 4.84 links, 1 island linked to its nearest subzone, 1 component; kNN k = 6 symmetrised
- [x] B2 blocks (H3): `R/04_q1_spatial/02_blocks.R` → `data/output/processed/q1_blocks.csv` (`subzone_c`, `block_id`). Planning areas, blocks under 3 subzones merged into the neighbour sharing most queen links: 31 blocks of 3–16 (median 6). Merged blocks only absorb maturity-"excluded" areas, so each block keeps one town label for H₀(a)
- [x] B4 global Moran's I: `R/04_q1_spatial/03_morans_i.R` → `data/output/tables/q1_morans_i.csv`, `data/output/figures/q1_morans_i.png`. Queen I 0.47 (health) to 0.57 (food services), composite 0.55; kNN 0.36–0.51; every p = 0.001 (permutation floor), so H₀ is rejected for all seven
- [x] B5 LISA: `R/04_q1_spatial/04_lisa.R` → `data/output/processed/q1_lisa.csv` (`subzone_c`, `variable`, `Ii`, `p_sim`, `p_bh`, `quadrant`, `cluster`), `data/output/tables/q1_lisa_counts.csv`, `data/output/figures/q1_lisa_maps.png`. Queen weights, 9,999 conditional permutations (999 cannot pass BH over 201 tests: the p floor is 0.002), BH q < 0.05 (decision 8), no Gi* (decision 10). Significant subzones are almost all High-High in the centre (composite 7; education 14; recreation 18 plus 8 Low-Low); no High-Low or Low-High outlier in any category
- [x] B6 memo to Q3 (H6): `R/04_q1_spatial/05_memo.R` → `data/output/tables/q1_memo.csv` (per category: I, p, cluster and outlier counts, `pattern`) and `data/output/processed/q1_outliers.csv` (empty). Rule fixed in the script before Q3 runs. All six categories and the composite are **contiguous**; none is concentrated below subzone scale.

  What this means for Q3: types should come out spatially coherent, so stability must be judged with the block bootstrap (H3), not random resampling, which would overstate it. There are no outlier subzones to set aside, so any small cluster Q3 finds is not explained by Q1 outliers and has to stand or fall on stability alone.
- [x] B7 report section: `report/sections/03_q1_spatial.Rmd`

## Inputs

`data/output/processed/score_subzone.rds`

## Hand-off

- `data/output/processed/q1_neighbours.rds`: the `nb` / `listw` objects (reused by Q2's residual tests and spatial model)
- `data/output/processed/q1_blocks.csv`: `subzone_c`, `block_id`, the spatial blocks Q3 resamples on
- `data/output/tables/q1_morans_i.csv`: one row per category + composite
