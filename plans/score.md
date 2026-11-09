# Access score

Owner: Qu Haotian. Code: `R/01_prep/`, `R/03_score/`. On the critical path: Q1-Q3 all consume it.

**What.** For each of the 332 MP19 subzones, count facilities in six categories within
1 km of the population-weighted centre, then combine with HES 2023 spending weights.

| Category | Weight |
|---|---|
| Food services | 30.8% |
| Retail goods | 16.1% |
| Health | 15.1% |
| Food retail | 14.5% |
| Education | 12.9% |
| Recreation, sport and culture | 10.7% |

## Steps

- [x] OSM extraction for all six categories: one scripted snapshot, `R/01_prep/00_fetch_osm.R` → `data/raw/sg/osm/`
- [x] Tag -> category lookup: `data/external/osm_crosswalk.csv`, which also generates the Overpass queries
- [x] Population-weighted centre per subzone: `R/03_score/01_centres.R` (OSM residential footprints × storeys)
- [x] Distance calibration (A6): **bonus track, never merged into `master`.** The project uses
  straight-line distance and reports it as a known caveat (Discussion). Routed walks were
  measured after the project on branch `claude/score-a6-calibration-3fcbb3`, with GenAI
  assistance; their numbers do not enter the report
- [x] Score v0 (A5): weighted composite + equal-weight variant + variety count, `R/03_score/02_score.R`
- [x] Radius variants (A8, part): 800 m and 1.2 km composites with rank agreement in `outputs/tables/score_robustness.csv`
- [x] Freeze v1 (A8): decisions agreed 2026-11-09 and H2 published; score reruns unchanged; tagged `score-v1`. From here a change to `score_subzone.rds` needs a dated note in `docs/decisions.md` and a rerun of Q1–Q3
- [x] Coverage check write-up, in the data and score section (A9)
- [x] A9 data and score section: `report/sections/02_data_and_score.Rmd`; every number read from `outputs/tables` and `data/processed`

Next:
- Tell Q3: food services, retail and food retail correlate 0.84–0.88 across the 201
  residential subzones (`outputs/tables/score_category_correlation.csv`). Unless k-means
  allows for that, it will mostly see one general-access axis. Recreation correlates
  least (0.30–0.48).
- v0 numbers: 201 residential subzones; median composite 58.9 (range 14–97); 800 m and
  1.2 km variants keep rank order at Spearman 0.95 and 0.91, but individual subzones move
  by up to 74 and 100 places.

## Hand-off (contract, do not rename columns without telling the team)

`data/processed/score_subzone.rds`: sf, subzone polygons, CRS 3414, one row for each
of the 332 MP19 subzones (filter on `residential` for analysis). Released as v0 (H4),
then frozen as v1 (H5).

| Column | Meaning |
|---|---|
| `subzone_c` | join key |
| `pop` | Census 2020 residents |
| `residential` | from H2 `residential_set.csv`: `pop >= RES_MIN_POP` (`R/00_setup.R`, decision 2) |
| `centre_method` | `buildings` (population-weighted) or `point_on_surface` (fallback) |
| `n_food_services` … `n_recreation` | raw facility counts within 1 km of the centre |
| `score_food_services`, `score_retail`, `score_health`, `score_food_retail`, `score_education`, `score_recreation` | 0–100: `100 * log1p(n) / max(log1p(n))` over the residential set (decision 11) |
| `score` | HES-weighted composite of the six, 0–100 |
| `score_equal` | equal-weight composite (robustness) |
| `variety` | distinct OSM tag values (`key=value`) within 1 km, all six categories |
| `score_r800`, `score_r1200` | `score` recomputed at 800 m and 1.2 km (decision 7) |

`data/processed/score_centres.rds`: sf points, CRS 3414, one row per subzone (332):
`subzone_c`, `centre_method`, `n_buildings` (residential footprints behind the centre; 0
for fallbacks). Q2 measures distance to rail from these, so the score and the covariates
share one centre.

Prep hand-offs this track also writes (`R/01_prep/`):

`data/processed/census2020_subzone.csv`, one row per subzone (332), Census 2020 resident
counts. SingStat rounds to tens and shows zero as "-", read here as 0.

| Column | Meaning |
|---|---|
| `subzone_c` | join key |
| `pln_area_n` | URA planning area (upper case); Q1 blocks and Q3 town groups key on it |
| `pop` | residents (citizens + PRs) |
| `pop_65plus` | residents aged 65 and over |
| `dw_total` | residents in all dwelling types (equals `pop` within rounding) |
| `dw_hdb` | residents in HDB flats, all sizes |
| `dw_hdb_1_2room`, `dw_hdb_3room`, `dw_hdb_4room`, `dw_hdb_5room_ec` | residents by HDB flat size (5-room includes executive) |
| `dw_condo`, `dw_landed`, `dw_other` | residents in condominiums and other apartments, landed homes, and other dwellings |

The `dw_*` columns count **residents** by the type of dwelling they live in, not
dwellings. Housing mix (decision 4) is `(dw_hdb_1_2room + dw_hdb_3room) / dw_total`.

`data/processed/hes_weights.csv`, six rows in `CATEGORIES` order: `category`,
`hes_lines` (the HES lines summed), `sgd_month` (2023 S$ per month), `weight` (sums to 1).

Inputs the score expects from other tracks: `residential_set.csv` (H2, from C1, run in
prep) with all 332 subzones, `subzone_c` and a logical `residential`. `02_score.R` coerces
0/1, stops on anything else, and stops if the file is missing.
