# Q1: How is each category structured in space?

Owner: Hew Xing Yi. Code: `R/04_q1_spatial/`.

**H0:** Moran's I = 0, run per category (six) and for the composite score.

## Method

- Queen contiguity, k-nearest-neighbours as a check; 999 permutations
- LISA and Getis-Ord Gi* for local clusters, p-values adjusted for multiple testing
- Flag categories concentrated below subzone scale (outlier subzones, not neighbourhood types)

## Steps

- [x] B3 shared figure theme: `theme_project()`, `theme_map()`, `save_fig()` and palettes in `R/00_setup.R`
- [x] B1 weights (H3): `R/04_q1_spatial/01_weights.R` → `data/processed/q1_neighbours.rds` (list: `subzone_c` order, `nb_queen`, `lw_queen`, `nb_knn`, `lw_knn`; row-standardised). 201 subzones, queen mean 4.84 links, 1 island linked to its nearest subzone, 1 component; kNN k = 6 symmetrised
- [x] B2 blocks (H3): `R/04_q1_spatial/02_blocks.R` → `data/processed/q1_blocks.csv` (`subzone_c`, `block_id`). Planning areas, blocks under 3 subzones merged into the neighbour sharing most queen links: 31 blocks of 3–16 (median 6). Merged blocks only absorb maturity-"excluded" areas, so each block keeps one town label for H₀(a)
- [x] B4 global Moran's I: `R/04_q1_spatial/03_morans_i.R` → `outputs/tables/q1_morans_i.csv`, `outputs/figures/q1_morans_i.png`. Queen I 0.47 (health) to 0.57 (food services), composite 0.55; kNN 0.36–0.51; every p = 0.001 (permutation floor), so H₀ is rejected for all seven
- [ ] B5 LISA with BH correction (decision 8; Gi* dropped, decision 10), maps
- [ ] B6 memo to Q3 (H6)
- [ ] B7 report section

## Inputs

`data/processed/score_subzone.rds`

## Hand-off

- `data/processed/q1_neighbours.rds`: the `nb` / `listw` objects (reused by Q2's spatial error model)
- `data/processed/q1_blocks.csv`: `subzone_c`, `block_id`, the spatial blocks Q3 resamples on
- `outputs/tables/q1_morans_i.csv`: one row per category + composite
