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

- [ ] OSM extraction for all six categories (only health + education pulled so far)
- [ ] Tag -> category lookup, extending `OSM_CATEGORY` in `R/01_prep/02_osm.R`
- [ ] Population-weighted centre per subzone
- [ ] Distance calibration: route ~200 sample journeys on the footway network, compare to straight line
- [ ] Score: weighted composite + equal-weight robustness variant + variety count
- [ ] Coverage check write-up (done in code, `R/02_coverage/`, ECDA only)

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
