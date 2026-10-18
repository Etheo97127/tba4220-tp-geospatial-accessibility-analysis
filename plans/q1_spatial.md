# Q1: How is each category structured in space?

Owner: Hew Xing Yi. Code: `R/04_q1_spatial/`.

**H0:** Moran's I = 0, run per category (six) and for the composite score.

## Method

- Queen contiguity, k-nearest-neighbours as a check; 999 permutations
- LISA and Getis-Ord Gi* for local clusters, p-values adjusted for multiple testing
- Flag categories concentrated below subzone scale (outlier subzones, not neighbourhood types)

## Inputs

`data/processed/score_subzone.rds`

## Hand-off

- `data/processed/q1_neighbours.rds`: the `nb` / `listw` objects (reused by Q2's spatial error model)
- `data/processed/q1_blocks.csv`: `subzone_c`, `block_id`, the spatial blocks Q3 resamples on
- `outputs/tables/q1_morans_i.csv`: one row per category + composite
