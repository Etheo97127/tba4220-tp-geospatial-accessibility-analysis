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
| Q2 | Zachary Chng Yao Wei | What explains access, and how much is just density? (OLS / spatial lag) | `R/05_q2_regression/` | [q2](plans/q2_regression.md) |
| Q3 | Coltrane Yao Zhiming | What kinds of neighbourhood exist? (k-means, block bootstrap) | `R/06_q3_typology/` | [q3](plans/q3_typology.md) |

**Bonus track (outside the project).** How far do people really walk compared with the
1 km straight line? Answered after the project, with GenAI assistance, on branch
`claude/score-a6-calibration-3fcbb3`. It is never merged into `master`; the project keeps
straight-line distance and the report lists it as a known caveat.

```
prep ──> coverage
  └────> score ──> Q1 ──> Q2 ──> Q3
                    └─────────────^   (Q1 blocks + Q2 residuals feed Q3)
```

## Hand-off files

Each stage reads only from `data/processed/` (and the hand-built lookups in
`data/external/`) and writes its own outputs there. The one exception: coverage and
score also read prep's layers in `data/interim/` (subzones, OSM POIs, reference lists,
buildings); `run_all.R` runs prep first when they are missing. Join key is always `subzone_c`;
CRS is EPSG:3414. Column contracts are in each plan; H1–H8 are the hand-off IDs in
`docs/team_plan.html`. Open decisions behind them are in `docs/consideration.md`.

| File | ID | Written by | Read by |
|---|---|---|---|
| `external/town_maturity.csv` | H1 | Q3 (D1) | coverage, Q3 |
| `external/osm_crosswalk.csv` | | score (A3) | anyone auditing the categories |
| `external/coverage_validation_verdicts.csv` | | coverage (checked sample) | coverage, report |
| `processed/census2020_subzone.csv` | | prep | score, Q1, Q2, Q3, report |
| `processed/hes_weights.csv` | | prep | score |
| `processed/rail_stations.rds` | | prep | Q2 (distance to rail) |
| `external/rail_not_open.csv` | | prep | station opening status at the OSM snapshot; `not_open` rows are dropped |
| `processed/osm_contributors.csv` | | prep | Q2 (mapping-effort control) |
| `processed/residential_set.csv` | H2 | Q2 (C1) | all |
| `processed/subzone_quality_flag.csv` | | coverage | report (data and Q1 sections) |
| `processed/score_subzone.rds` | H4, H5 | score | Q1, Q2, Q3 |
| `processed/score_centres.rds` | | score (A4) | Q2 (distance to rail) |
| `processed/subzone_covariates.rds` | | Q2 (C2) | Q2 |
| `processed/q1_neighbours.rds`, `q1_blocks.csv` | H3 | Q1 | Q2, Q3 |
| `processed/q1_lisa.csv` | | Q1 | Q1 memo, report |
| `processed/q1_outliers.csv` | H6 | Q1 | Q3 (stops if it lists any subzone) |
| `processed/q2_residuals.csv`, `q2_adjusted_scores.csv` | H7 | Q2 | Q3 |
| `processed/q3_clusters.csv` | H8 | Q3 | Q3 (tests, profiles) |

The rest of H6 (the Q1 memo) and of H7 (density share, raw-or-adjusted call) are
`outputs/tables/q1_memo.csv` and `outputs/tables/q2_density_share.csv`.

H2 `residential_set.csv` must hold all 332 subzones with `subzone_c` and a
`residential` column of `TRUE`/`FALSE` (0/1 is coerced; anything else stops the
score). Extra columns such as `pop` are fine.

## Layout

```
R/
  00_setup.R            shared paths, CRS, seed, helpers (sourced by every script)
  run_all.R             whole pipeline; `Rscript R/run_all.R q2 q3` runs selected stages
  01_prep/              subzone frame, reference lists, OSM, census, buildings
                        (00_fetch_*.R download raw data; run by hand, not by run_all)
  02_coverage/          OSM vs ECDA record linkage + uniformity tests
  03_score/  04_q1_spatial/  05_q2_regression/  06_q3_typology/
data/
  raw/sg                downloaded, never edited                  (committed)
  external/             hand-built lookups, e.g. town_maturity    (committed)
  interim/              intermediate objects                      (ignored, regenerated)
  processed/            hand-off tables between stages            (committed)
  DATA_SOURCES.md       every dataset with a link
outputs/figures, tables written by scripts, never hand-edited, prefixed by stage
outputs/slides/         project deck (.pptx), built by report/slides/build_slides.js
report/                 report.Rmd + one child section per owner (reads outputs/, data/processed/, data/external/)
docs/                   requirements, download log, proposal versions, critiques
plans/                  one working plan per workstream
```

## Getting started

1. Clone, then open `tba4220-tp-sg-geospatial-accessibility-analysis.Rproj` in RStudio
   (the working directory must be the repo root).
2. Install packages: `sf dplyr tidyr stringr readr jsonlite ggplot2 scales stringdist clue binom pwr spatstat spdep spatialreg tmap cluster factoextra osmdata rmarkdown knitr`.
3. `Rscript R/run_all.R` rebuilds `data/interim`, `data/processed` and `outputs/`.
4. `Rscript report/render.R` writes `report/report.docx` (it finds the pandoc bundled with RStudio; or knit `report/report.Rmd` in RStudio).
5. `cd report/slides && npm install && npm run build` writes `outputs/slides/group3_project_slides.pptx`
   (Node.js; its numbers are typed from the rendered report, so recheck them after a rerun).

## Rules

- `data/raw/` is read-only. Every raw file gets a row in [`docs/data_log.md`](docs/data_log.md): source URL, download date, md5, licence.
- Raw data is committed so everyone works on the same OSM snapshot. Files over ~50 MB (e.g. the Geofabrik `.osm.pbf` for routing) are ignored and fetched by script.
- CRS: EPSG:3414 (SVY21), EPSG:4326 only for I/O.
- Scripts are numbered within their stage and idempotent; run from the repo root.
- Output files are prefixed by stage: `coverage_`, `score_`, `q1_`, `q2_`, `q3_`.
- Seeds are set in `00_setup.R` (`SEED <- 4220`); reset it at the top of any script that samples or permutes.
- Work on a branch per workstream (`score/...`, `q1/...`), open a PR to `master`, and don't edit another stage's folder without telling its owner.
