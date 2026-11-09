# Methods outside the lectures

Decision 10 requires every method the lectures did not teach to carry a citation and
a one-sentence explanation in the report. This is that list, one row per method, in
pipeline order. "Lectures" means the TBA4220 slides. Lecture 8 taught global Moran's
I, queen weights and permutation tests; Lectures 4 and 5 taught buffers and distance
joins; Lecture 4 used k-means only as a map classification style.

## Coverage check (Track A)

| Method | Where | What it means | Why we use it | Cite |
|---|---|---|---|---|
| Record linkage with Jaro-Winkler and token-set similarity | `R/02_coverage/01_match.R` | Pair each official facility with an OSM feature that is both close (≤ 50 m) and similarly named. Jaro-Winkler scores typo-level differences; token overlap scores reordered words | Distance alone pairs the wrong tenant in a multi-clinic building; name alone pairs the wrong branch of a chain | Winkler (1990) |
| One-to-one assignment (Hungarian algorithm) | `01_match.R`, `R/06_q3_typology/03_stability.R` | Choose the set of pairs with the best total score so no OSM feature is claimed twice | Greedy matching double-counts shared buildings; in Q3 it matches bootstrap clusters to the originals | Kuhn (1955) |
| Wilson score interval | `01_match.R`, coverage tables | A confidence interval for a proportion that stays inside 0–1 | Recall is near 10%, where the textbook ±1.96·SE interval is poor | Wilson (1927) |
| Two-proportion test with minimum detectable difference | `R/02_coverage/02_gap_test.R` | Tests whether the miss rate differs between mature and non-mature towns, and reports the smallest gap the sample could detect at 80% power | A null result means something only if the test could have found a real gap (here 3.8 points) | Cohen (1988) |
| Logistic regression | `02_gap_test.R` | Models the probability a facility is missing from OSM given town maturity and distance to the CBD | Separates maturity from the confounding effect of distance from the centre | James et al. (2021) |
| Random labelling with the cross-K function | `02_gap_test.R` | Shuffles "found / missed" over the fixed facility locations and asks whether missed ones cluster more than chance | The two-group test cannot see clustering of gaps beyond the clustering of facilities themselves | Baddeley, Rubak & Turner (2015) |
| Empirical-Bayes (beta-binomial) shrinkage | `R/02_coverage/03_quality_flag.R` | Pulls a subzone's miss rate towards the island rate in proportion to how few facilities it has | A subzone with 1 preschool would otherwise show 0% or 100% missing | Efron & Morris (1975) |

## Access score (Track A)

| Method | Where | What it means | Why we use it | Cite |
|---|---|---|---|---|
| Population-weighted centre from building floor area | `R/03_score/01_centres.R` | Each subzone's centre is the floor-area-weighted mean of its residential buildings | A polygon centroid can sit in a reservoir or outside an L-shaped subzone; access should be measured from where people live | — (design choice, decision 3) |
| log1p scaling to the residential maximum | `R/03_score/02_score.R` | Category score = 100·log(1 + count) / max over residential subzones | Puts hundreds of eateries and tens of clinics on one scale before the spending weights apply (decision 11) | — (design choice) |
| Spearman rank correlation for robustness | `02_score.R` | Agreement between the rankings under different radii or weights | We care whether subzones keep their order, not their exact values | James et al. (2021) |

## Q1: spatial structure (Track B)

| Method | Where | What it means | Why we use it | Cite |
|---|---|---|---|---|
| k-nearest-neighbour weights | `R/04_q1_spatial/01_weights.R` | Each subzone's neighbours are its 6 nearest subzones | A check that Moran's I does not hinge on the contiguity rule | Bivand, Pebesma & Gómez-Rubio (2013) |
| Local Moran's I (LISA), conditional permutation | `04_lisa.R` | Moran's I for each subzone and its neighbours; labels High-High and Low-Low clusters and High-Low and Low-High outliers | Shows *where* clustering is, and whether any subzone breaks its neighbours' pattern, which is what Q3 needs | Anselin (1995) |
| Benjamini-Hochberg false discovery rate | `04_lisa.R` | Adjusts 201 local p-values so that about 5% of the subzones called significant are false positives | At p < 0.05 about 10 subzones would look significant by chance alone (decision 8) | Benjamini & Hochberg (1995) |

Getis-Ord Gi* was dropped (decision 10): it repeats LISA's clusters and cannot show outliers.

## Q2: what explains access (Track C)

| Method | Where | What it means | Why we use it | Cite |
|---|---|---|---|---|
| OLS with standardised predictors | `R/05_q2_regression/03_ols.R` | Linear regression; each coefficient reads "score points per SD of the predictor" | Lets the tested variables and the controls be compared on one scale | James et al. (2021) |
| One-sided t-test | `03_ols.R`, `04_spatial_model.R` | Tests only the stated direction (elderly share and housing mix lower the score) | The hypotheses are directional (decision 4); a result in the other direction does not reject H₀ | James et al. (2021) |
| Variance inflation factor (VIF) | `03_ols.R` | How much a coefficient's variance is inflated because predictors overlap; above about 5 is a warning | Elderly share and housing mix are related; VIF shows whether their effects can be separated (max 2.2, fine) | James et al. (2021) |
| Moran's I on regression residuals | `04_spatial_model.R` | Whether what the model leaves unexplained is spatially clustered | Clustered residuals make OLS p-values too small (0.28 here, p < 0.001) | Anselin (1988) |
| Robust Lagrange-multiplier tests | `04_spatial_model.R` | Distinguish a spillover process (lag) from clustered unmeasured causes (error) in the residual pattern | They choose the spatial model; here they chose lag, not the error model the plan expected | Anselin, Bera, Florax & Yoon (1996) |
| Spatial lag model with impacts | `04_spatial_model.R` | Each subzone's score depends on its neighbours' scores. Effects are read as total impacts, direct plus spillover | Fits better than OLS and the error model (AIC 1,468 vs 1,525 and 1,485); a lag coefficient alone is not a marginal effect | LeSage & Pace (2009) |
| Spatial error model (reported beside lag) | `04_spatial_model.R` | Regression whose errors are allowed to correlate between neighbours | The plan's original choice; shown to confirm the conclusion does not depend on the model | Anselin (1988) |
| R² share for density | `R/05_q2_regression/05_handoff.R` | R² of score on density alone ÷ R² of the full model | Decides, by a threshold fixed in advance (decision 1), whether Q3 must remove density first (0.32 < 0.5: no) | — (design choice) |

## Q3: neighbourhood types (Track D)

| Method | Where | What it means | Why we use it | Cite |
|---|---|---|---|---|
| k-means on z-scores (as a statistical method) | `R/06_q3_typology/02_choose_k.R` | Splits subzones into k groups around average profiles. z-scoring gives each category equal weight | The proposal's clustering method; the lectures used k-means only to class map colours | Hartigan & Wong (1979) |
| Elbow and silhouette | `02_choose_k.R` | Elbow: where extra groups stop reducing within-group spread. Silhouette: how much better each subzone fits its own group than the next one | Chooses k by a rule fixed in the script | Rousseeuw (1987) |
| No-cluster null (parametric bootstrap) | `02_choose_k.R` | Re-runs the same k choice on 200 simulated single clouds with the data's covariance, and asks whether the real data separate better | Silhouette always picks some k ≥ 2, even with no groups. Here p = 0.47: one gradient, not discrete types | Tibshirani, Walther & Hastie (2001) |
| Spatial block bootstrap with Jaccard stability | `03_stability.R` | Resamples whole planning-area blocks, re-clusters, and measures each group's overlap with the original (≥ 0.75 stable) | Neighbouring subzones are near-duplicates (Q1), so resampling single subzones would overstate stability | Künsch (1989); Hennig (2007) |
| Block permutation tests | `04_tests.R` | p-values from shuffling town labels between whole blocks (H₀(a)) or residuals within blocks (H₀(b)) | Neighbouring subzones are not independent, so the textbook χ² and F p-values are too small (decisions 5, 12) | Good (2005) |
| Reduced-form residual | `R/05_q2_regression/05_handoff.R` | Score minus what the predictors alone imply, y − (I − ρW)⁻¹Xβ | Matches the plan's definition of under-served; the lag model's own residual counts neighbours' observed scores as part of the prediction | LeSage & Pace (2009) |

## References

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
