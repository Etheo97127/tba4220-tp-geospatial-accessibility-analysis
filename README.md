# Whose 15-Minute City?

**Neighbourhood types and walkable access to everyday services in Singapore.**
TBA4220 Geospatial Analysis (NUS, AY2026/27 Sem 1), Group 3 Metropolitans.

For each of Singapore's 332 subzones we build an access score from six service
categories (OpenStreetMap, weighted by Household Expenditure Survey 2023 spending
shares), then ask three questions that build toward a neighbourhood typology.
Proposal: [`docs/proposal/proposal_submitted.docx`](docs/proposal/proposal_submitted.docx).

## Workstreams

| Stage | Owner | Question | Code | Plan |
|---|---|---|---|---|
| Score + coverage check | Qu Haotian | Build the access score; how uniformly does OSM cover preschools vs ECDA? | `R/01_prep/`, `R/02_coverage/`, `R/03_score/` | [score](plans/score.md), [coverage](plans/coverage_check.md) |
| Q1 | Hew Xing Yi | How is each category structured in space? (Moran's I per category) | `R/04_q1_spatial/` | [q1](plans/q1_spatial.md) |
| Q2 | Zachary Chng Yao Wei | What explains access, and how much is just density? (OLS / spatial error) | `R/05_q2_regression/` | [q2](plans/q2_regression.md) |
| Q3 | Coltrane Yao Zhiming | What kinds of neighbourhood exist? (k-means, block bootstrap) | `R/06_q3_typology/` | [q3](plans/q3_typology.md) |

```
prep ──> coverage
  └────> score ──> Q1 ──> Q2 ──> Q3
                    └─────────────^   (Q1 blocks + Q2 residuals feed Q3)
```

## Hand-off files

Each stage reads only from `data/processed/` and writes its own outputs there.
Join key is always `subzone_c`; CRS is EPSG:3414. Column contracts are in each plan.

| File | Written by | Read by |
|---|---|---|
| `score_subzone.rds` | score | Q1, Q2, Q3 |
| `subzone_covariates.rds` | prep | Q2, Q3 |
| `q1_neighbours.rds`, `q1_blocks.csv` | Q1 | Q2, Q3 |
| `q2_residuals.csv` | Q2 | Q3 |
| `q3_clusters.csv` | Q3 | report |

## Layout

```
R/
  00_setup.R            shared paths, CRS, seed, helpers (sourced by every script)
  run_all.R             whole pipeline; `Rscript R/run_all.R q2 q3` runs selected stages
  01_prep/              subzone frame, reference lists, OSM extraction
  02_coverage/          OSM vs ECDA record linkage + uniformity tests
  03_score/  04_q1_spatial/  05_q2_regression/  06_q3_typology/
data/
  raw/sg, raw/hk        downloaded, never edited                  (committed)
  external/             hand-built lookups, e.g. town_maturity    (committed)
  interim/              intermediate objects                      (ignored, regenerated)
  processed/            hand-off tables between stages            (committed)
  DATA_SOURCES.md       every dataset with a link
outputs/figures, tables written by scripts, never hand-edited, prefixed by stage
report/                 report.Rmd + one child section per owner (reads outputs only)
docs/                   requirements, download log, proposal versions, critiques
plans/                  one working plan per workstream
```

## Getting started

1. Clone, then open `tba4220-tp-sg-geospatial-accessibility-analysis.Rproj` in RStudio
   (the working directory must be the repo root).
2. Install packages: `sf dplyr tidyr stringr readr jsonlite ggplot2 scales stringdist clue binom pwr spatstat spdep spatialreg tmap cluster factoextra osmdata`.
3. `Rscript R/run_all.R` rebuilds `data/interim`, `data/processed` and `outputs/`.
4. Knit `report/report.Rmd`.

## Rules

- `data/raw/` is read-only. Every raw file gets a row in [`docs/data_log.md`](docs/data_log.md): source URL, download date, md5, licence.
- Raw data is committed so everyone works on the same OSM snapshot. Files over ~50 MB (e.g. the Geofabrik `.osm.pbf` for routing) are ignored and fetched by script.
- CRS: EPSG:3414 (SVY21) for SG, EPSG:2326 (HK1980 Grid) for HK, EPSG:4326 only for I/O.
- Scripts are numbered within their stage and idempotent; run from the repo root.
- Output files are prefixed by stage: `coverage_`, `score_`, `q1_`, `q2_`, `q3_`.
- Seeds are set in `00_setup.R` (`SEED <- 4220`); reset it at the top of any script that samples or permutes.
- Work on a branch per workstream (`score/...`, `q1/...`), open a PR to `master`, and don't edit another stage's folder without telling its owner.
