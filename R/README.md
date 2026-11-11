# R/ — pipeline scripts

`Rscript R/run_all.R [stage ...]` runs the folders in this order, and the scripts inside each in
number order:
`01_prep → 02_coverage → 03_score → 04_q1_spatial → 05_q2_regression → 06_q3_typology`.
The two `00_fetch_*` scripts are run by hand only. Every numbered script starts by sourcing
`00_setup.R`.

**Legend**
- Paths: `raw/` = `data/input/raw/sg/` (downloads, read-only) · `ext/` = `data/input/external/`
  (lookup tables made by hand) · `int/` = `data/output/interim/` (**not committed**; rebuilt on each
  run) · `proc/` = `data/output/processed/` · `tab/` = `data/output/tables/` ·
  `fig/` = `data/output/figures/`. Everything except `int/` is committed.
- **[I]** = intermediate dataset: written by one script and read by a later one. In an Inputs cell,
  **← script** names the script that writes it (script names are unique across folders).
- Inputs without [I] are source data. `raw/` files count as source data even though the two fetch
  scripts write them: they are a committed snapshot that the pipeline never rebuilds. Other outputs
  without [I] are final: report tables and figures, or files no later script reads.

---

## Top level

| Script | Purpose | Inputs | Outputs |
|---|---|---|---|
| `00_setup.R` | Shared settings: paths, CRS (EPSG:3414), seed, the six categories, decision constants (`RADIUS_M`, `RES_MIN_POP` ...), helpers (name cleaning, `log_step()`, figure theme) | — | No data; creates the output folders if missing |
| `run_all.R` | Runs every stage, or only those named. Adds prep first when coverage or score is asked for and prep's interim layers are missing | Stage names (optional)<br>Checks that prep's layers exist:<br>[I] `int/subzones.rds`, `int/reference.rds` — subzones, official lists ← 01_reference<br>[I] `int/osm_poi.rds` — OSM points ← 02_osm<br>[I] `int/res_buildings.rds` — homes ← 04_buildings | What the scripts it runs write |

---

## 01_prep/ — raw downloads to clean layers

**Upstream:** `raw/` and `ext/` only. **Feeds:** every other folder.

| Script | Purpose | Inputs | Outputs |
|---|---|---|---|
| `00_fetch_datagov.R` *(manual)* | Download the government datasets; files already on disk are skipped | data.gov.sg API | `raw/mp19_subzone.geojson` — MP19 subzone boundaries<br>`raw/mp19_rail_station.geojson` — MP19 rail stations<br>`raw/census2020_age.csv` — Census 2020 residents by subzone × age<br>`raw/census2020_dwelling.csv` — Census 2020 residents by subzone × dwelling type<br>`raw/hes_quinquennial.csv` — Household Expenditure Survey, spending by item<br>`raw/childcare_services.geojson`, `raw/kindergartens.geojson` — ECDA preschools<br>`raw/preschools_location.geojson` — older combined ECDA list<br>`raw/chas_clinics.geojson` — CHAS clinics<br>`raw/moh_health_fac.csv` — MOH facility counts (not read by any script) |
| `00_fetch_osm.R` *(manual)* | Pull one OSM snapshot via Overpass: one query per category built from the crosswalk, buildings in 6 tiles | Overpass API<br>`ext/osm_crosswalk.csv` — OSM tag → score category | `raw/osm/osm_<category>.json` — OSM features per category<br>`raw/osm/osm_residential_buildings_<tile>.json` — residential building outlines<br>`raw/osm/*.overpassql` — the exact query beside each result |
| `01_reference.R` | Subzone frame, and the official facility lists OSM is judged against | `raw/mp19_subzone.geojson` — subzone boundaries<br>`raw/chas_clinics.geojson` — clinics<br>`raw/childcare_services.geojson`, `raw/kindergartens.geojson` — preschools<br>`raw/preschools_location.geojson` — count cross-check only | [I] `int/subzones.rds` — 332 subzone polygons<br>[I] `int/reference.rds` — CHAS clinics + ECDA preschools, with subzone |
| `02_osm.R` | OSM JSON → one point layer: category, `scored` flag, duplicates merged, subzone attached | `raw/osm/osm_<category>.json` — OSM features<br>`ext/osm_crosswalk.csv` — tag → category<br>[I] `int/subzones.rds` — subzone polygons ← 01_reference | [I] `int/osm_poi.rds` — OSM points of interest |
| `03_census.R` | Census counts per subzone, joined to MP19 by planning area + subzone name (stops on any mismatch) | `raw/census2020_age.csv` — residents by age<br>`raw/census2020_dwelling.csv` — residents by dwelling type<br>[I] `int/subzones.rds` — subzone codes and names ← 01_reference | [I] `proc/census2020_subzone.csv` — residents, residents 65+, residents by dwelling type |
| `04_buildings.R` | Homes weighted by footprint area × storeys (missing storeys imputed, dormitories dropped), for the score centres | `raw/osm/osm_residential_buildings_<tile>.json` — building outlines<br>[I] `int/subzones.rds` — subzone polygons ← 01_reference | [I] `int/res_buildings.rds` — weighted residential buildings |
| `05_hes_weights.R` | Category weights: each category's share of 2023 household spending | `raw/hes_quinquennial.csv` — spending by item | [I] `proc/hes_weights.csv` — six category weights |
| `06_rail_stations.R` | Rail stations in service at the OSM snapshot | `raw/mp19_rail_station.geojson` — MP19 stations<br>`ext/rail_not_open.csv` — stations not yet open | [I] `proc/rail_stations.rds` — station footprints in service |
| `07_osm_contributors.R` | Mapping effort: distinct OSM mappers (last editor of each feature) per km² | [I] `int/osm_poi.rds` — OSM points with mapper id ← 02_osm<br>[I] `int/subzones.rds` — subzone areas ← 01_reference | [I] `proc/osm_contributors.csv` — mappers per km² per subzone |
| `../05_q2_regression/01_residential_set.R` *(run with prep)* | Flag subzones with ≥ `RES_MIN_POP` (1,000) residents; every analysis uses only these | [I] `proc/census2020_subzone.csv` — residents ← 03_census | [I] `proc/residential_set.csv` — residential flag per subzone<br>`tab/q2_residential_n.csv` — counts at the 1,000 and 500 cut-offs |

---

## 02_coverage/ — how complete is OSM compared with the official lists?

**Upstream:** 01_prep (subzones, official lists, OSM points) and `ext/`. **Feeds:** no later
stage; the report reads its tables, figures and `proc/subzone_quality_flag.csv`.

| Script | Purpose | Inputs | Outputs |
|---|---|---|---|
| `01_match.R` | Match each official facility to at most one OSM feature (distance + name or postcode, optimal one-to-one) over 4 distances × 3 name thresholds, for strict and wide category sets | [I] `int/reference.rds` — official facilities ← 01_reference<br>[I] `int/osm_poi.rds` — OSM points ← 02_osm | [I] `tab/coverage_threshold_sensitivity.csv` — recall for each threshold pair<br>[I] `int/match_table.rds` — matched OSM feature (or none) per facility at 50 m / 0.80<br>`int/match_table.csv` — the same, as CSV to read by eye |
| `02_gap_test.R` | Does OSM miss more facilities in non-mature towns? Two-proportion test, logistic regression with distance to the CBD, random-labelling K test | [I] `int/match_table.rds` — matches ← 01_match<br>[I] `int/reference.rds` — facility points ← 01_reference<br>[I] `int/subzones.rds` — land area for the point-pattern window ← 01_reference<br>`ext/town_maturity.csv` — planning area → mature / non-mature / excluded | [I] `int/match_tested.rds` — strict matches + town maturity + missed flag<br>[I] `tab/coverage_prop_test.csv` — proportion test<br>`tab/coverage_logistic.csv`, `tab/coverage_logistic_sensitivity.csv` — odds ratios; refit without Sengkang / Hougang<br>[I] `int/random_labelling.rds` — K-function envelopes<br>[I] `tab/coverage_random_labelling.csv` — random-labelling test |
| `03_quality_flag.R` | OSM quality flag per subzone (ECDA miss rate shrunk by empirical Bayes: better / typical / worse) and its map | [I] `int/match_tested.rds` — matches + maturity ← 02_gap_test<br>[I] `int/subzones.rds` — subzone polygons ← 01_reference<br>`ext/town_maturity.csv` — town maturity | `proc/subzone_quality_flag.csv` — quality flag per subzone (read by the report)<br>`fig/coverage_missrate_map.png` — miss-rate map |
| `04_outputs.R` | Coverage report table and figures | [I] `tab/coverage_threshold_sensitivity.csv` — recall grid ← 01_match<br>[I] `int/match_tested.rds` — matches + maturity ← 02_gap_test<br>[I] `tab/coverage_prop_test.csv` — proportion test ← 02_gap_test<br>[I] `int/random_labelling.rds`, `tab/coverage_random_labelling.csv` — K test ← 02_gap_test (figure skipped if missing) | `tab/coverage_recall_by_category.csv` — recall at 50 m / 0.80<br>`fig/coverage_threshold_sensitivity.png` — recall across thresholds<br>`fig/coverage_random_labelling.png` — K envelope<br>`fig/coverage_missrate_by_planning_area.png` — miss rate by town |
| `05_ceiling_and_validation.R` | Highest recall any name-based matcher could reach (nearest OSM feature only); random sample of matches for hand checking | [I] `int/reference.rds` — official facilities ← 01_reference<br>[I] `int/osm_poi.rds` — OSM points ← 02_osm<br>[I] `int/match_tested.rds` — matches ← 02_gap_test<br>[I] `tab/coverage_threshold_sensitivity.csv` — achieved recall ← 01_match | `tab/coverage_matching_ceiling.csv` — ceiling vs achieved recall<br>[I] `tab/coverage_validation_sample.csv` — 40 accepted + 40 rejected matches per list |
| `06_matcher_error.R` | False-match and false-miss rates of the matcher; recall corrected for them | [I] `tab/coverage_validation_sample.csv` — sample ← 05_ceiling_and_validation<br>`ext/coverage_validation_verdicts.csv` — verdicts filled in by hand for that sample<br>[I] `int/match_tested.rds` — matches ← 02_gap_test | `tab/coverage_matcher_error.csv` — error rates<br>`tab/coverage_recall_corrected.csv` — corrected recall |

---

## 03_score/ — the access score per subzone

**Upstream:** 01_prep (subzones, OSM points, homes, census, weights, residential set).
**Feeds:** Q1, Q2 and Q3 through `score_subzone.rds`; Q2 also through `score_centres.rds`.

| Script | Purpose | Inputs | Outputs |
|---|---|---|---|
| `01_centres.R` | One centre per subzone where residents live: floor-area-weighted mean of its homes, kept inside the subzone; a point on the polygon where no homes are mapped | [I] `int/subzones.rds` — subzone polygons ← 01_reference<br>[I] `int/res_buildings.rds` — weighted homes ← 04_buildings<br>[I] `proc/census2020_subzone.csv` — residents in fallback subzones ← 03_census | [I] `proc/score_centres.rds` — centre point per subzone<br>`fig/score_centres_map.png` — centres map |
| `02_score.R` | Access score: scored OSM facilities within `RADIUS_M` (1 km) of each centre per category, scaled 0–100 on a log scale over the residential set, weighted by spending; 800 / 1200 m and equal-weight variants | [I] `int/subzones.rds` — subzone polygons ← 01_reference<br>[I] `int/osm_poi.rds` — OSM points ← 02_osm<br>[I] `proc/score_centres.rds` — centres ← 01_centres<br>[I] `proc/census2020_subzone.csv` — residents ← 03_census<br>[I] `proc/hes_weights.csv` — weights ← 05_hes_weights<br>[I] `proc/residential_set.csv` — residential flag ← 01_residential_set | **[I] `proc/score_subzone.rds`** — counts, six category scores, composite and variants per subzone, with polygons<br>`tab/score_weights.csv` — weights used<br>`tab/score_poi_counts.csv` — OSM features per category and type<br>`tab/score_category_summary.csv` — per-category medians and spread<br>`tab/score_robustness.csv` — rank agreement of the variants<br>`tab/score_category_correlation.csv` — correlation between categories |
| `03_outputs.R` | Score maps | [I] `proc/score_subzone.rds` — scores ← 02_score<br>[I] `proc/hes_weights.csv` — weights for panel labels ← 05_hes_weights | `fig/score_composite_map.png` — composite map<br>`fig/score_category_maps.png` — six category maps |

---

## 04_q1_spatial/ — does access cluster in space?

**Upstream:** 03_score (scores, polygons), 01_prep (residential set, planning areas).
**Feeds:** Q2 (spatial weights) and Q3 (blocks, outliers).

| Script | Purpose | Inputs | Outputs |
|---|---|---|---|
| `01_weights.R` | Neighbours among residential subzones: queen contiguity, with k = 6 nearest as a check | [I] `proc/score_subzone.rds` — subzone polygons ← 02_score<br>[I] `proc/residential_set.csv` — residential flag ← 01_residential_set | [I] `proc/q1_neighbours.rds` — neighbour lists and weights (queen, kNN)<br>`tab/q1_weights_summary.csv` — links per subzone |
| `02_blocks.R` | Resampling blocks for Q3: planning areas, with blocks under 3 subzones merged into a neighbour | [I] `proc/q1_neighbours.rds` — queen neighbours ← 01_weights<br>[I] `proc/census2020_subzone.csv` — planning area per subzone ← 03_census | [I] `proc/q1_blocks.csv` — block per subzone<br>`tab/q1_block_sizes.csv` — subzones per block |
| `03_morans_i.R` | Global Moran's I for each category and the composite | [I] `proc/score_subzone.rds` — scores ← 02_score<br>[I] `proc/q1_neighbours.rds` — weights ← 01_weights | [I] `tab/q1_morans_i.csv` — I and p per score<br>`fig/q1_morans_i.png` — I per score |
| `04_lisa.R` | Local hot and cold spots and outliers (LISA, Benjamini-Hochberg corrected) | [I] `proc/score_subzone.rds` — scores and polygons ← 02_score<br>[I] `proc/q1_neighbours.rds` — queen weights ← 01_weights | [I] `proc/q1_lisa.csv` — LISA value and cluster label per subzone and score<br>`tab/q1_lisa_counts.csv` — cluster counts<br>`fig/q1_lisa_maps.png` — cluster maps |
| `05_memo.R` | Call each category contiguous / concentrated / no pattern, and list outlier subzones for Q3 | [I] `tab/q1_morans_i.csv` — global I ← 03_morans_i<br>[I] `proc/q1_lisa.csv` — LISA clusters ← 04_lisa | `tab/q1_memo.csv` — pattern per category<br>[I] `proc/q1_outliers.csv` — High-Low / Low-High subzones |

---

## 05_q2_regression/ — what explains the score?

`01_residential_set.R` runs with prep (see 01_prep).
**Upstream:** 01_prep (census, rail, mapping effort, residential set), 03_score (scores, centres),
04_q1_spatial (weights). **Feeds:** Q3.

| Script | Purpose | Inputs | Outputs |
|---|---|---|---|
| `02_covariates.R` | Predictors: elderly share (65+), housing mix (residents in HDB 1–3 room flats), log density, distance to rail, mapping effort | [I] `proc/census2020_subzone.csv` — residents, age, dwelling ← 03_census<br>[I] `proc/residential_set.csv` — residential flag ← 01_residential_set<br>[I] `proc/score_centres.rds` — centres ← 01_centres<br>[I] `proc/rail_stations.rds` — stations ← 06_rail_stations<br>[I] `proc/osm_contributors.csv` — mappers per km² ← 07_osm_contributors | [I] `proc/subzone_covariates.rds` — predictors per subzone<br>`tab/q2_covariates_summary.csv` — predictor summaries |
| `03_ols.R` | OLS of the score on standardised predictors: one-sided tests, VIF, a model per category, a refit without mapping effort | [I] `proc/score_subzone.rds` — scores ← 02_score<br>[I] `proc/subzone_covariates.rds` — predictors ← 02_covariates<br>[I] `proc/q1_neighbours.rds` — row order ← 01_weights | [I] `int/q2_model.rds` — model data + OLS fit<br>`tab/q2_ols.csv` — composite coefficients<br>`tab/q2_ols_by_category.csv` — per-category coefficients<br>`tab/q2_ols_fit.csv` — R²<br>`tab/q2_vif.csv` — collinearity<br>`tab/q2_ols_sensitivity.csv` — refit without mapping effort |
| `04_spatial_model.R` | Test OLS residuals for spatial correlation; fit spatial error and lag models and choose one by robust LM tests | [I] `int/q2_model.rds` — OLS fit ← 03_ols<br>[I] `proc/q1_neighbours.rds` — queen weights ← 01_weights | [I] `int/q2_model.rds` — overwritten, adds the spatial models and the choice<br>`tab/q2_lm_tests.csv` — LM tests<br>`tab/q2_models.csv` — OLS / error / lag coefficients and lag impacts<br>`tab/q2_spatial_diagnostics.csv` — residual Moran's I, ρ, λ, AIC, chosen model |
| `05_handoff.R` | Hand-off to Q3: does density explain most of R² (raw or density-adjusted scores)? Density-adjusted scores; residuals of the chosen model | [I] `int/q2_model.rds` — fitted models ← 04_spatial_model<br>[I] `proc/q1_neighbours.rds` — queen weights ← 01_weights | [I] `tab/q2_density_share.csv` — density share and Q3's raw / adjusted call<br>[I] `proc/q2_adjusted_scores.csv` — category scores net of density<br>[I] `proc/q2_residuals.csv` — model residual per subzone |

---

## 06_q3_typology/ — kinds of neighbourhood

**Upstream:** 01_prep (residential set, planning areas), `ext/town_maturity.csv`, 03_score,
04_q1_spatial (blocks, outliers), 05_q2_regression (residuals, adjusted scores, raw / adjusted
call). **Feeds:** the report.

| Script | Purpose | Inputs | Outputs |
|---|---|---|---|
| `01_inputs.R` | Build the clustering table: six z-scored scores (raw or adjusted, as Q2 decided), block, town maturity, Q2 residual. Stops if Q1 found outlier subzones | [I] `proc/score_subzone.rds` — raw scores ← 02_score<br>[I] `proc/residential_set.csv` — residential flag ← 01_residential_set<br>[I] `proc/census2020_subzone.csv` — planning area ← 03_census<br>`ext/town_maturity.csv` — town maturity<br>[I] `proc/q1_blocks.csv` — blocks ← 02_blocks<br>[I] `proc/q1_outliers.csv` — outliers ← 05_memo<br>[I] `tab/q2_density_share.csv` — raw / adjusted call ← 05_handoff<br>[I] `proc/q2_adjusted_scores.csv` — adjusted scores ← 05_handoff<br>[I] `proc/q2_residuals.csv` — residuals ← 05_handoff | [I] `int/q3_inputs.rds` — clustering table and z-scored matrix |
| `02_choose_k.R` | Choose the number of types by silhouette (k = 2–8), after a check on simulated data; test the split against no-cluster null data | [I] `int/q3_inputs.rds` — clustering inputs ← 01_inputs | [I] `int/q3_k.rds` — chosen k and verdict (discrete types / one gradient)<br>`tab/q3_choose_k.csv` — WSS and silhouette per k<br>`tab/q3_null_test.csv` — null test<br>`fig/q3_choose_k.png` — elbow and silhouette |
| `03_stability.R` | Final k-means; spatial block bootstrap to see whether each type is stable | [I] `int/q3_inputs.rds` — clustering inputs ← 01_inputs<br>[I] `int/q3_k.rds` — k ← 02_choose_k | [I] `proc/q3_clusters.csv` — type and stable flag per subzone<br>`tab/q3_stability.csv` — Jaccard per type<br>`int/q3_kmeans.rds` — k-means fit (not read later) |
| `04_tests.R` | H0(a) the type mix is the same in mature and non-mature towns; H0(b) type is unrelated to the Q2 residual; both by block permutation | [I] `int/q3_inputs.rds` — blocks, maturity, residuals ← 01_inputs<br>[I] `proc/q3_clusters.csv` — types ← 03_stability | `tab/q3_tests.csv` — test results<br>`tab/q3_type_mix.csv` — type shares by town group<br>`tab/q3_residual_by_type.csv` — mean residual per type |
| `05_profiles.R` | Describe and name each type by a fixed rule; profile chart and map | [I] `int/q3_inputs.rds` — z-scores ← 01_inputs<br>[I] `proc/q3_clusters.csv` — types ← 03_stability<br>[I] `int/q3_k.rds` — structure verdict ← 02_choose_k<br>[I] `proc/score_subzone.rds` — polygons for the map ← 02_score | `tab/q3_types.csv` — type names and sizes<br>`tab/q3_profiles.csv` — mean z per type × category<br>`fig/q3_profiles.png` — profile chart<br>`fig/q3_types_map.png` — type map |
