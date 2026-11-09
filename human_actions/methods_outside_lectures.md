# Methods outside the lectures

Decision 10 requires every method the lectures did not teach to carry a citation and
a one-sentence explanation in the report. This file classifies every method the
pipeline uses against [`docs/course_knowledge.md`](../docs/course_knowledge.md) (TBA4220 L1–L8):

- **Taught**: used as the lectures showed.
- **Extends L#**: builds directly on a taught idea; one step beyond it.
- **Not taught**: new to the course. Needs a citation and a one-line explanation in
  the report.

## At a glance

| Track | Taught | Extends a lecture | Not taught |
|---|---|---|---|
| Coverage (A) | spatial joins, `st_is_within_distance` (L5) | random labelling with cross-K, envelope, MAD (L7) | record linkage (Jaro-Winkler), Hungarian matching, Wilson interval, two-proportion test and power, logistic regression, empirical-Bayes shrinkage |
| Score (A) | buffers and distance counts (L4–5), `st_point_on_surface` (L5) | floor-area-weighted centres, log scaling (design choices built from taught operations) | Spearman rank correlation |
| Q1 (B) | queen weights, `nb2listw`, Moran's I, Moran plot (L8) | Monte Carlo Moran's I, LISA (L8) | kNN weights, Benjamini-Hochberg |
| Q2 (C) | — (L8's trend-in-mean model is the nearest) | — | OLS, one-sided tests, VIF, AIC, residual Moran's I, robust LM tests, spatial lag/error models and impacts |
| Q3 (D) | — | k-means (L4 used it only to bin map colours), null reference and permutation tests (L7–L8's "compare with a simulated random benchmark") | silhouette and elbow, block bootstrap with Jaccard, chi-square statistic, PCA |

The pattern: Q1 stays close to the course (L8). Coverage and Q3 extend L7–L8's
simulate-a-null-benchmark logic. Q2 is the one track built almost entirely on methods
from outside the course (regression and spatial econometrics), because its question,
what explains access once density is held fixed, needs a model with several predictors.

## Details by track

Each row: what the method does, why the project needs it, and the reference for the
report.

### Coverage check (Track A)

| Method | Scope | Where | What it means | Why we use it | Cite |
|---|---|---|---|---|---|
| Distance-limited candidate pairs | Taught (L5) | `R/02_coverage/01_match.R` | `st_is_within_distance` finds every OSM feature within 150 m of each official facility | The first step of matching | — |
| Record linkage, Jaro-Winkler + token-set similarity | Not taught | `01_match.R` | A pair counts as the same facility only if it is close (≤ 50 m) *and* similarly named. Jaro-Winkler scores typos; token overlap scores reordered words | Distance alone pairs the wrong tenant in a multi-clinic building; name alone pairs the wrong branch of a chain | Winkler (1990) |
| One-to-one assignment (Hungarian algorithm) | Not taught | `01_match.R`, `R/06_q3_typology/03_stability.R` | Chooses the set of pairs with the best total score so no OSM feature is claimed twice | Greedy matching double-counts shared buildings. In Q3 it matches bootstrap clusters to the original ones | Kuhn (1955) |
| Wilson score interval | Not taught | `01_match.R`, `06_matcher_error.R` | A confidence interval for a proportion that stays inside 0–1 | Recall is near 10%, where the textbook ±1.96·SE interval is poor | Wilson (1927) |
| Two-proportion test + minimum detectable difference | Not taught | `02_gap_test.R` | Tests whether the miss rate differs between mature and non-mature towns, and gives the smallest gap the sample could detect at 80% power | A null result means something only if a real gap could have been found (3.8 points here) | Cohen (1988) |
| Logistic regression | Not taught | `02_gap_test.R` | Models the probability a facility is missing from OSM given town maturity and distance to the CBD | Separates maturity from distance to the centre, which it is tangled with (r = 0.72) | James et al. (2021) |
| Random labelling with cross-K, envelope and MAD test | Extends L7 | `02_gap_test.R` | L7 taught cross-K for marked points, envelopes and the MAD test against CSR. Here the null is a different one: shuffle the "found/missed" marks over the fixed facility locations (`rlabel`) instead of scattering points randomly | Asks whether *missed* facilities cluster beyond the clustering of facilities themselves, which CSR cannot answer | Baddeley, Rubak & Turner (2015) |
| Empirical-Bayes (beta-binomial) shrinkage | Not taught | `03_quality_flag.R` | Pulls each subzone's miss rate towards the island rate, more strongly when it has few facilities | A subzone with 1 preschool would otherwise show 0% or 100% missing | Efron & Morris (1975) |
| Matcher error and corrected recall | Not taught (arithmetic on a checked sample) | `06_matcher_error.R` | False-match and false-miss rates from 160 checked pairs, then recall adjusted for both | Shows how much of the low recall is OSM's and how much the matcher's (ECDA 9.7% measured, 16.8% corrected) | — |

### Access score (Track A)

| Method | Scope | Where | What it means | Why we use it | Cite |
|---|---|---|---|---|---|
| Counting facilities within 1 km | Taught (L4–5) | `R/03_score/02_score.R` | `st_is_within_distance` + `lengths()` from each subzone centre, in metres (EPSG:3414) | The access count itself | — |
| `st_point_on_surface` fallback centre | Taught (L5) | `01_centres.R` | A point guaranteed inside the polygon, unlike `st_centroid` | Subzones with no mapped homes | — |
| Floor-area-weighted centre | Extends L5 (design choice) | `01_centres.R` | The centre is the weighted mean of residential building points, weight = footprint × storeys | Measures access from where people live, not the polygon's middle (decision 3) | — |
| log1p scaling to the residential maximum | Design choice | `02_score.R` | Category score = 100·log(1 + count) / maximum over residential subzones | Puts hundreds of eateries and tens of clinics on one scale before the spending weights (decision 11) | — |
| Spearman rank correlation | Not taught | `02_score.R` | Agreement between two rankings | Checks that subzones keep their order under other radii and weights | James et al. (2021) |

### Q1: spatial structure (Track B)

| Method | Scope | Where | What it means | Why we use it | Cite |
|---|---|---|---|---|---|
| Queen contiguity, row-standardised weights | Taught (L8) | `R/04_q1_spatial/01_weights.R` | `poly2nb(queen = TRUE)`, `nb2listw(style = "W")` | The main neighbour rule | — |
| kNN weights (k = 6) | Not taught (same package) | `01_weights.R` | Each subzone's neighbours are its 6 nearest subzones | Checks that Moran's I does not depend on the contiguity rule | Bivand, Pebesma & Gómez-Rubio (2013) |
| Moran's I by Monte Carlo permutation | Extends L8 | `03_morans_i.R` | L8 taught `moran.test` and the shuffled-map visual test. `moran.mc` computes I on 999 shuffled maps and reads the p-value off them | Makes no normality assumption; it is the visual test made numeric | Bivand, Pebesma & Gómez-Rubio (2013) |
| LISA (local Moran's I) | Extends L8 | `04_lisa.R` | L8's Moran plot splits subzones into four quadrants. LISA tests each subzone's quadrant for significance, giving High-High and Low-Low clusters and High-Low and Low-High outliers | Shows *where* clustering is, and whether any subzone breaks its neighbours' pattern (Q3 needs this) | Anselin (1995) |
| Benjamini-Hochberg false discovery rate | Not taught | `04_lisa.R` | Adjusts 201 local p-values so that about 5% of the subzones called significant are false positives | At p < 0.05, about 10 subzones would look significant by chance alone (decision 8) | Benjamini & Hochberg (1995) |

Getis-Ord Gi* was dropped (decision 10): it repeats LISA's clusters and cannot show outliers.

### Q2: what explains access (Track C)

| Method | Scope | Where | What it means | Why we use it | Cite |
|---|---|---|---|---|---|
| OLS with standardised predictors | Not taught (L8's trend-in-mean model is the nearest) | `R/05_q2_regression/03_ols.R` | Linear regression; each coefficient reads "score points per SD of the predictor" | Compares the tested variables and controls on one scale | James et al. (2021) |
| One-sided t-test | Not taught | `03_ols.R`, `04_spatial_model.R` | Tests only the stated direction (elderly share and housing mix lower the score) | The hypotheses are directional (decision 4) | James et al. (2021) |
| Variance inflation factor (VIF) | Not taught | `03_ols.R` | How much a coefficient's variance grows because predictors overlap; above about 5 is a warning | Elderly share and housing mix are related (max VIF 2.2: fine) | James et al. (2021) |
| Moran's I on residuals | Extends L8 | `04_spatial_model.R` | L8's Moran's I applied to what the regression leaves unexplained | Clustered residuals break OLS's independence assumption, L8's own point (I = 0.28, p < 0.001) | Anselin (1988) |
| Robust Lagrange-multiplier tests | Not taught | `04_spatial_model.R` | Tell a spillover process (lag) from clustered unmeasured causes (error) | Choose the spatial model; they chose lag | Anselin, Bera, Florax & Yoon (1996) |
| Spatial lag model with impacts | Not taught | `04_spatial_model.R` | A subzone's score depends on its neighbours' scores; effects are read as total impacts (direct plus spillover) | Fits best (AIC 1,468 against 1,485 for error and 1,525 for OLS) | LeSage & Pace (2009) |
| Akaike information criterion (AIC) | Not taught | `04_spatial_model.R` | Compares models by fit, penalised for the number of parameters; lower is better | Picks between OLS, the error and the lag model alongside the LM tests | Akaike (1974) |
| Spatial error model | Not taught | `04_spatial_model.R` | Regression whose errors may correlate between neighbours | The plan's original choice; reported to show the conclusion holds | Anselin (1988) |
| R² share for density; reduced-form residual | Not taught | `05_handoff.R` | Density's share of explained variance decides raw vs adjusted scores for Q3 (decision 1). The residual is the score minus what the predictors alone imply | Hand-offs to Q3 | LeSage & Pace (2009) |

### Q3: neighbourhood types (Track D)

| Method | Scope | Where | What it means | Why we use it | Cite |
|---|---|---|---|---|---|
| k-means on z-scores | Extends L4 | `R/06_q3_typology/02_choose_k.R` | L4 used k-means only to bin map colours (`style = "kmeans"`). Here it groups subzones by their six-category profile; z-scores give each category equal weight | The proposal's clustering method | Hartigan & Wong (1979) |
| Principal component analysis (report only) | Not taught | `report/sections/05_q3_typology.Rmd` | Finds the single direction along which the six scores vary most | Shows the scores lie on one access axis (70% of the variance), which explains the no-cluster result | James et al. (2021) |
| Elbow and silhouette | Not taught | `02_choose_k.R` | Elbow: where more groups stop reducing within-group spread. Silhouette: how much better each subzone fits its own group than the next | Chooses k by a fixed rule | Rousseeuw (1987) |
| No-cluster null (parametric bootstrap) | Extends L7–L8 | `02_choose_k.R` | The same logic as L7's CSR envelope or L8's shuffled maps: rerun the k choice on 200 simulated single clouds with no groups and see whether the real data separate better | Silhouette always picks some k ≥ 2. Here p = 0.47: one gradient, not discrete types | Tibshirani, Walther & Hastie (2001) |
| Spatial block bootstrap + Jaccard | Not taught | `03_stability.R` | Resample whole planning-area blocks, re-cluster, measure each group's overlap with the original (≥ 0.75 stable) | Neighbours are near-duplicates (Q1), so resampling single subzones would overstate stability | Künsch (1989); Hennig (2007) |
| Block permutation tests (χ² and F statistics) | Extends L8 | `04_tests.R` | L8's permutation idea, with whole blocks shuffled (H₀(a)) or values shuffled within blocks (H₀(b)) | Neighbours are not independent, so textbook χ² and F p-values would be too small (decisions 5 and 12) | Good (2005) |

## Packages outside the course list

The course taught `sf`, `spdep`, `spatstat`, `ggplot2`, `tmap`, `dplyr`, `purrr` and
base R. The pipeline adds:

| Package | Used for |
|---|---|
| `stringdist` | Jaro-Winkler name similarity (coverage) |
| `clue` | Hungarian assignment (coverage, Q3) |
| `binom` | Wilson intervals |
| `pwr` | power and minimum detectable difference |
| `spatialreg` | spatial lag and error models, impacts (Q2) |
| `cluster` | silhouette (Q3) |
| `MASS` (ships with R) | simulated null clouds (Q3) |
| `readr`, `tidyr`, `stringr`, `jsonlite` | tidyverse I/O and reshaping; JSON parsing for the Overpass downloads |

## References

- Akaike, H. (1974). A new look at the statistical model identification. *IEEE Transactions on Automatic Control*, 19(6), 716–723.
- Anselin, L. (1988). *Spatial Econometrics: Methods and Models*. Kluwer.
- Anselin, L. (1995). Local indicators of spatial association — LISA. *Geographical Analysis*, 27(2), 93–115.
- Anselin, L., Bera, A. K., Florax, R., & Yoon, M. J. (1996). Simple diagnostic tests for spatial dependence. *Regional Science and Urban Economics*, 26(1), 77–104.
- Baddeley, A., Rubak, E., & Turner, R. (2015). *Spatial Point Patterns: Methodology and Applications with R*. CRC Press.
- Benjamini, Y., & Hochberg, Y. (1995). Controlling the false discovery rate. *Journal of the Royal Statistical Society B*, 57(1), 289–300.
- Bivand, R. S., Pebesma, E., & Gómez-Rubio, V. (2013). *Applied Spatial Data Analysis with R* (2nd ed.). Springer.
- Cohen, J. (1988). *Statistical Power Analysis for the Behavioral Sciences* (2nd ed.). Lawrence Erlbaum.
- Efron, B., & Morris, C. (1975). Data analysis using Stein's estimator and its generalizations. *Journal of the American Statistical Association*, 70(350), 311–319.
- Good, P. (2005). *Permutation, Parametric and Bootstrap Tests of Hypotheses* (3rd ed.). Springer.
- Hartigan, J. A., & Wong, M. A. (1979). A k-means clustering algorithm. *Applied Statistics*, 28(1), 100–108.
- Hennig, C. (2007). Cluster-wise assessment of cluster stability. *Computational Statistics & Data Analysis*, 52(1), 258–271.
- James, G., Witten, D., Hastie, T., & Tibshirani, R. (2021). *An Introduction to Statistical Learning* (2nd ed.). Springer.
- Kuhn, H. W. (1955). The Hungarian method for the assignment problem. *Naval Research Logistics Quarterly*, 2, 83–97.
- Künsch, H. R. (1989). The jackknife and the bootstrap for general stationary observations. *Annals of Statistics*, 17(3), 1217–1241.
- LeSage, J., & Pace, R. K. (2009). *Introduction to Spatial Econometrics*. CRC Press.
- Rousseeuw, P. J. (1987). Silhouettes: a graphical aid to the interpretation and validation of cluster analysis. *Journal of Computational and Applied Mathematics*, 20, 53–65.
- Tibshirani, R., Walther, G., & Hastie, T. (2001). Estimating the number of clusters in a data set via the gap statistic. *Journal of the Royal Statistical Society B*, 63(2), 411–423.
- Wilson, E. B. (1927). Probable inference, the law of succession, and statistical inference. *Journal of the American Statistical Association*, 22(158), 209–212.
- Winkler, W. E. (1990). String comparator metrics and enhanced decision rules in the Fellegi-Sunter model of record linkage. *Proceedings of the Section on Survey Research Methods*, American Statistical Association, 354–359.
