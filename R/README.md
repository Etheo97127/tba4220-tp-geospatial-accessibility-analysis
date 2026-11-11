# R/ — pipeline scripts

Run order: `01_prep → 02_coverage → 03_score → 04_q1_spatial → 05_q2_regression → 06_q3_typology`
(`Rscript R/run_all.R [stage ...]`). Each script sources `00_setup.R` first.

**Legend**
- Paths: `raw/` = `data/input/raw/sg/` (downloaded, read-only) · `ext/` = `data/input/external/`
  (hand-made lookup tables) · `int/` = `data/output/interim/` · `proc/` = `data/output/processed/` ·
  `tab/` = `data/output/tables/` · `fig/` = `data/output/figures/`
- **[I]** = intermediate dataset, written by another script; **← script** names its producer
  (the upstream connection). Inputs without [I] are source data.
- Outputs in `tab/` and `fig/` are report tables/figures; the rest are read further down the pipeline.

```
raw ─► 01_prep ─► subzones, OSM POIs, census, buildings, HES weights, rail, residential set
                    │
                    ├─► 02_coverage   (how complete is OSM?)            → quality flag
                    └─► 03_score      (access score per subzone)        → score_subzone.rds
                                         │
                         04_q1_spatial (clustering) ─► neighbours, blocks, outliers
                                         │                    │
                         05_q2_regression (what predicts it) ─► residuals, adjusted scores
                                         │                    │
                         06_q3_typology (neighbourhood types) ◄┘
```

---

## Top level

| Script | Purpose | Inputs | Outputs |
|---|---|---|---|
| `00_setup.R` | Shared paths, CRS (EPSG:3414), seed, the six categories, decision constants, helpers (name cleaning, logging, figure theme) | — | Constants in memory; creates output folders |
| `run_all.R` | Runs the stages in dependency order; runs prep first if its interim layers are missing | Stage names (optional) | — |

---

## 01_prep/ — turn raw downloads into clean layers

| Script | Purpose | Inputs | Outputs |
|---|---|---|---|
| `00_fetch_datagov.R` *(manual)* | Download the government datasets once | data.gov.sg API | `raw/`: MP19 subzones `mp19_subzone.geojson`, MP19 rail stations `mp19_rail_station.geojson`, Census 2020 age `census2020_age.csv` and dwelling `census2020_dwelling.csv`, household spending `hes_quinquennial.csv`, ECDA preschools `childcare_services.geojson` + `kindergartens.geojson` (+ `preschools_location.geojson`), CHAS clinics `chas_clinics.geojson`, MOH facilities `moh_health_fac.csv` |
| `00_fetch_osm.R` *(manual)* | Pull an OpenStreetMap snapshot through Overpass queries built from the tag crosswalk | Overpass API; OSM tag → category table `ext/osm_crosswalk.csv` | `raw/osm/`: OSM features per category `osm_<category>.json`, residential building outlines `osm_residential_buildings_<tile>.json` (×6), each with its query `.overpassql` |
| `01_reference.R` | Subzone frame + the two official facility lists OSM is judged against | `raw/mp19_subzone.geojson`, `raw/chas_clinics.geojson`, `raw/childcare_services.geojson`, `raw/kindergartens.geojson`, `raw/preschools_location.geojson` (count cross-check) | [I] 332 subzone polygons `int/subzones.rds`; [I] CHAS clinics + ECDA preschools with subzone `int/reference.rds` |
| `02_osm.R` | OSM JSON → one de-duplicated point layer with category and subzone | `raw/osm/osm_*.json`, `ext/osm_crosswalk.csv`, [I] `int/subzones.rds` ← 01_reference | [I] OSM points of interest `int/osm_poi.rds` |
| `03_census.R` | Residents, residents 65+, residents by dwelling type, per subzone | `raw/census2020_age.csv`, `raw/census2020_dwelling.csv`, [I] `int/subzones.rds` ← 01_reference | [I] census counts per subzone `proc/census2020_subzone.csv` |
| `04_buildings.R` | Residential footprints weighted by area × storeys (for population-weighted centres) | `raw/osm/osm_residential_buildings_*.json`, [I] `int/subzones.rds` ← 01_reference | [I] weighted residential buildings `int/res_buildings.rds` |
| `05_hes_weights.R` | Category weights = share of 2023 household spending | `raw/hes_quinquennial.csv` | [I] six category weights `proc/hes_weights.csv` |
| `06_rail_stations.R` | Rail stations in service (drops lines not yet open) | `raw/mp19_rail_station.geojson`, not-yet-open list `ext/rail_not_open.csv` | [I] station footprints `proc/rail_stations.rds` |
| `07_osm_contributors.R` | OSM mapping effort: distinct mappers per km² per subzone | [I] `int/osm_poi.rds` ← 02_osm, [I] `int/subzones.rds` ← 01_reference | [I] mappers per km² `proc/osm_contributors.csv` |
| `../05_q2_regression/01_residential_set.R` *(runs in prep)* | Which subzones have ≥ 1,000 residents; every analysis uses only these | [I] `proc/census2020_subzone.csv` ← 03_census | [I] residential flag `proc/residential_set.csv`; `tab/q2_residential_n.csv` |

---

## 02_coverage/ — how complete is OSM compared with official lists?

| Script | Purpose | Inputs | Outputs |
|---|---|---|---|
| `01_match.R` | Link each official facility to at most one OSM feature (distance + name/postcode, one-to-one), over a grid of thresholds | [I] `int/reference.rds` ← prep 01, [I] `int/osm_poi.rds` ← prep 02 | Recall per threshold `tab/coverage_threshold_sensitivity.csv`; [I] matched/missed per facility `int/match_table.rds` |
| `02_gap_test.R` | Is OSM missing more facilities in non-mature towns? Proportion test, logistic regression, random-labelling test | [I] `int/match_table.rds` ← 01, [I] `int/subzones.rds`, [I] `int/reference.rds`, town maturity `ext/town_maturity.csv` | `tab/coverage_prop_test.csv`, `tab/coverage_logistic.csv`, `tab/coverage_logistic_sensitivity.csv`, `tab/coverage_random_labelling.csv`; [I] K-function envelopes `int/random_labelling.rds`; [I] matches + maturity `int/match_tested.rds` |
| `03_quality_flag.R` | Per-subzone OSM quality flag (shrunk ECDA miss rate) and its map | [I] `int/match_tested.rds` ← 02, [I] `int/subzones.rds`, `ext/town_maturity.csv` | [I] quality flag `proc/subzone_quality_flag.csv`; `fig/coverage_missrate_map.png` |
| `04_outputs.R` | Coverage tables and figures | [I] `tab/coverage_threshold_sensitivity.csv` ← 01; [I] `int/match_tested.rds`, `tab/coverage_prop_test.csv`, `int/random_labelling.rds`, `tab/coverage_random_labelling.csv` ← 02 | `tab/coverage_recall_by_category.csv`; `fig/coverage_threshold_sensitivity.png`, `fig/coverage_random_labelling.png`, `fig/coverage_missrate_by_planning_area.png` |
| `05_ceiling_and_validation.R` | Best recall any name matcher could reach; draw a sample for hand checking | [I] `int/reference.rds`, [I] `int/osm_poi.rds`, [I] `int/match_tested.rds` ← 02, [I] `tab/coverage_threshold_sensitivity.csv` ← 01 | `tab/coverage_matching_ceiling.csv`; [I] 160-row sample to check `tab/coverage_validation_sample.csv` |
| `06_matcher_error.R` | False-match / false-miss rates and corrected recall | [I] `tab/coverage_validation_sample.csv` ← 05, hand-checked verdicts `ext/coverage_validation_verdicts.csv`, [I] `int/match_tested.rds` ← 02 | `tab/coverage_matcher_error.csv`, `tab/coverage_recall_corrected.csv` |

---

## 03_score/ — the access score per subzone

| Script | Purpose | Inputs | Outputs |
|---|---|---|---|
| `01_centres.R` | One centre per subzone where residents live (floor-area-weighted mean of homes) | [I] `int/subzones.rds` ← prep 01, [I] `int/res_buildings.rds` ← prep 04, [I] `proc/census2020_subzone.csv` ← prep 03 | [I] subzone centres `proc/score_centres.rds`; `fig/score_centres_map.png` |
| `02_score.R` | Count facilities within 1 km per category, scale 0–100 (log), weight by spending; 800/1200 m and equal-weight variants | [I] `int/subzones.rds`, [I] `int/osm_poi.rds` ← prep 02, [I] `proc/score_centres.rds` ← 01, [I] `proc/census2020_subzone.csv`, [I] `proc/hes_weights.csv` ← prep 05, [I] `proc/residential_set.csv` ← q2 01 | **[I] access score per subzone `proc/score_subzone.rds`** (read by Q1–Q3); `tab/score_weights.csv`, `tab/score_poi_counts.csv`, `tab/score_category_summary.csv`, `tab/score_robustness.csv`, `tab/score_category_correlation.csv` |
| `03_outputs.R` | Maps of the composite and the six category scores | [I] `proc/score_subzone.rds` ← 02, [I] `proc/hes_weights.csv` | `fig/score_composite_map.png`, `fig/score_category_maps.png` |

---

## 04_q1_spatial/ — does access cluster in space?

| Script | Purpose | Inputs | Outputs |
|---|---|---|---|
| `01_weights.R` | Neighbour definitions on residential subzones (queen contiguity; k = 6 nearest as a check) | [I] `proc/score_subzone.rds` ← score 02, [I] `proc/residential_set.csv` | [I] neighbour lists and weights `proc/q1_neighbours.rds`; `tab/q1_weights_summary.csv` |
| `02_blocks.R` | Spatial blocks (planning areas, small ones merged) for Q3's resampling | [I] `proc/q1_neighbours.rds` ← 01, [I] `proc/census2020_subzone.csv` | [I] block per subzone `proc/q1_blocks.csv`; `tab/q1_block_sizes.csv` |
| `03_morans_i.R` | Global Moran's I per category and composite | [I] `proc/score_subzone.rds`, [I] `proc/q1_neighbours.rds` ← 01 | [I] `tab/q1_morans_i.csv`; `fig/q1_morans_i.png` |
| `04_lisa.R` | Local hot/cold spots and outliers (LISA, BH-corrected) | [I] `proc/score_subzone.rds`, [I] `proc/q1_neighbours.rds` ← 01 | [I] cluster label per subzone `proc/q1_lisa.csv`; `tab/q1_lisa_counts.csv`; `fig/q1_lisa_maps.png` |
| `05_memo.R` | Classify each category as contiguous / concentrated / no pattern for Q3 | [I] `tab/q1_morans_i.csv` ← 03, [I] `proc/q1_lisa.csv` ← 04 | `tab/q1_memo.csv`; [I] outlier subzones `proc/q1_outliers.csv` |

---

## 05_q2_regression/ — what explains the score?

(`01_residential_set.R` runs in prep; see above.)

| Script | Purpose | Inputs | Outputs |
|---|---|---|---|
| `02_covariates.R` | Predictors: elderly share (65+), housing mix (HDB 1–3 room share), log density, distance to rail, mapping effort | [I] `proc/census2020_subzone.csv` ← prep 03, [I] `proc/residential_set.csv`, [I] `proc/score_centres.rds` ← score 01, [I] `proc/rail_stations.rds` ← prep 06, [I] `proc/osm_contributors.csv` ← prep 07 | [I] predictors per subzone `proc/subzone_covariates.rds`; `tab/q2_covariates_summary.csv` |
| `03_ols.R` | OLS of score on standardised predictors; one-sided tests, VIF, per-category models | [I] `proc/score_subzone.rds` ← score 02, [I] `proc/subzone_covariates.rds` ← 02, [I] `proc/q1_neighbours.rds` ← q1 01 (row order) | [I] fitted model + data `int/q2_model.rds`; `tab/q2_ols.csv`, `tab/q2_ols_by_category.csv`, `tab/q2_ols_fit.csv`, `tab/q2_vif.csv`, `tab/q2_ols_sensitivity.csv` |
| `04_spatial_model.R` | Test residuals for spatial correlation; fit spatial error/lag models and pick one | [I] `int/q2_model.rds` ← 03, [I] `proc/q1_neighbours.rds` ← q1 01 | [I] `int/q2_model.rds` (updated with spatial models and choice); `tab/q2_lm_tests.csv`, `tab/q2_models.csv`, `tab/q2_spatial_diagnostics.csv` |
| `05_handoff.R` | Hand-off to Q3: does density dominate (raw vs adjusted scores)? density-adjusted scores; final-model residuals | [I] `int/q2_model.rds` ← 04, [I] `proc/q1_neighbours.rds` | [I] decision `tab/q2_density_share.csv`; [I] adjusted scores `proc/q2_adjusted_scores.csv`; [I] residuals `proc/q2_residuals.csv` |

---

## 06_q3_typology/ — kinds of neighbourhood

| Script | Purpose | Inputs | Outputs |
|---|---|---|---|
| `01_inputs.R` | Assemble the clustering table: six z-scored scores, block, town maturity, Q2 residual | [I] `proc/score_subzone.rds` ← score 02, [I] `proc/residential_set.csv`, [I] `proc/q1_blocks.csv` ← q1 02, [I] `proc/q1_outliers.csv` ← q1 05, [I] `proc/q2_residuals.csv` + `proc/q2_adjusted_scores.csv` + `tab/q2_density_share.csv` ← q2 05, `ext/town_maturity.csv`, [I] `proc/census2020_subzone.csv` | [I] clustering inputs `int/q3_inputs.rds` |
| `02_choose_k.R` | Choose the number of types (silhouette), checked on simulated data and against a no-cluster null | [I] `int/q3_inputs.rds` ← 01 | [I] chosen k + verdict `int/q3_k.rds`; `tab/q3_choose_k.csv`, `tab/q3_null_test.csv`; `fig/q3_choose_k.png` |
| `03_stability.R` | Final k-means; spatial block bootstrap to test whether each type is stable | [I] `int/q3_inputs.rds` ← 01, [I] `int/q3_k.rds` ← 02 | [I] k-means fit `int/q3_kmeans.rds`; [I] type per subzone `proc/q3_clusters.csv`; `tab/q3_stability.csv` |
| `04_tests.R` | H0(a) type mix same in mature/non-mature towns; H0(b) type unrelated to Q2 residual (block permutations) | [I] `int/q3_inputs.rds` ← 01, [I] `proc/q3_clusters.csv` ← 03 | `tab/q3_tests.csv`, `tab/q3_type_mix.csv`, `tab/q3_residual_by_type.csv` |
| `05_profiles.R` | Describe and name each type; profile chart and map | [I] `int/q3_inputs.rds` ← 01, [I] `proc/q3_clusters.csv` ← 03, [I] `int/q3_k.rds` ← 02, [I] `proc/score_subzone.rds` | `tab/q3_types.csv`, `tab/q3_profiles.csv`; `fig/q3_profiles.png`, `fig/q3_types_map.png` |
