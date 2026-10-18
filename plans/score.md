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

`data/processed/score_subzone.rds`, one row per subzone, CRS 3414:
`subzone_c`, `pop`, `score_food_services`, `score_retail`, `score_health`,
`score_food_retail`, `score_education`, `score_recreation`, `score`, `score_equal`, `variety`.
