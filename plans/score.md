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
- [ ] Distance calibration (A6): route ~200 sample journeys on the footway network, compare to straight line. Needs a footway pull; off the critical path
- [x] Score v0 (A5): weighted composite + equal-weight variant + variety count, `R/03_score/02_score.R`
- [x] Radius variants (A8, part): 800 m and 1.2 km composites with rank agreement in `outputs/tables/score_robustness.csv`
- [ ] Freeze v1 (A8): after P0 decisions are agreed and H2 is published; tag the commit `score-v1`
- [ ] Coverage check write-up (done in code, `R/02_coverage/`; ECDA-only re-scope in progress on its own branch)

Next:
- v1 freeze: once the P0 meeting agrees decisions 2, 3, 7 and 11 and C1 publishes
  `residential_set.csv`, rerun `Rscript R/run_all.R prep score`, recheck
  `score_robustness.csv`, and tag `score-v1`.
- Rerun `coverage` after the ECDA re-scope branch and this one are both merged: this branch
  moved the OSM snapshot from September to 2026-11-02, so the committed coverage outputs are stale.
- A6: pull the footway network (`highway` = footway, path, pedestrian, steps, residential,
  service) through `00_fetch_osm.R` (tile it like the buildings), then route ~200 pairs.
- Tell Q3: food services, retail and food retail correlate 0.84–0.87 across the 201
  residential subzones (`outputs/tables/score_category_correlation.csv`). Unless k-means
  allows for that, it will mostly see one general-access axis. Recreation correlates
  least (0.29–0.48).
- v0 numbers: 201 residential subzones; median composite 58.9 (range 14–97); 800 m and
  1.2 km variants keep rank order at Spearman 0.95 and 0.92, but individual subzones move
  by up to 74 and 100 places.

## Hand-off (contract, do not rename columns without telling the team)

`data/processed/score_subzone.rds`: sf, subzone polygons, CRS 3414, one row for each
of the 332 MP19 subzones (filter on `residential` for analysis). Released as v0 (H4),
then frozen as v1 (H5).

| Column | Meaning |
|---|---|
| `subzone_c` | join key |
| `pop` | Census 2020 residents |
| `residential` | `pop >= RES_MIN_POP` (`R/00_setup.R`); provisional until C1 publishes H2 |
| `centre_method` | `buildings` (population-weighted) or `point_on_surface` (fallback) |
| `n_food_services` … `n_recreation` | raw facility counts within 1 km of the centre |
| `score_food_services`, `score_retail`, `score_health`, `score_food_retail`, `score_education`, `score_recreation` | 0–100: `100 * log1p(n) / max(log1p(n))` over the residential set (decision 11) |
| `score` | HES-weighted composite of the six, 0–100 |
| `score_equal` | equal-weight composite (robustness) |
| `variety` | distinct OSM tag values (`key=value`) within 1 km, all six categories |
| `score_r800`, `score_r1200` | `score` recomputed at 800 m and 1.2 km (decision 7) |

`data/processed/score_centres.rds`: sf points, CRS 3414, `subzone_c`, `centre_method`.
Q2 measures distance to rail from these, so the score and the covariates share one centre.
