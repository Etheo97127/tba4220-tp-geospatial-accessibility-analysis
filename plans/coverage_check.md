# Q1 — How complete is OpenStreetMap, and are the gaps spread evenly?

> **Status (2026-11-08):** this file was written before the final proposal. Q1
> here is now the *coverage check* inside the score workstream; the new Q1 is
> per-category Moran's I, `plans/q1_spatial.md`. `R/02_coverage/` now follows
> the 2026-09-16 decision as amended on 2026-11-08 (`docs/REQUIREMENTS.md`
> section 3). ECDA preschools are the headline benchmark; CHAS clinics are
> reported only as a labelled supplementary row and are never pooled with
> ECDA. What changed: the pooled proportion-test row is gone, and Holm runs
> within headline / supplementary rather than across all rows (section 4's
> "pooled, three tests, Holm" is superseded). The post-hoc `power` column is
> replaced by the minimum detectable difference (`mdd_pp`). The logistic
> regression is fitted per set instead of pooled with `set` as a term.
> `subzone_quality_flag.csv` is built from ECDA only, with the same columns,
> and flags subzones by a posterior tail probability (section 5). The figures
> lead with ECDA, and every number in their titles and captions is computed
> from the tables.
>
> Headline numbers (ECDA, strict match, d = 50 m, s = 0.80; OSM snapshot of
> 2026-11-02, rerun after the merge into `score/v0`):
>
> - **Recall 9.7%** (Wilson 95% CI 8.5–11.1%; 192 of 1,975), and 6–11% across all
>   twelve threshold cells.
> - **Miss rate 90.9% mature vs 90.1% non-mature** (909/1,000 vs 782/868):
>   difference +0.8 pp, 95% CI −2.0 to +3.6 pp, **p = 0.61**. The arms detect a gap
>   of **3.8 pp** at 80% power and alpha 0.05, so this null result does not come
>   from low power.
> - **Random labelling p = 0.51**: missed preschools cluster no more than the
>   preschools themselves.
> - **Logistic** `missed ~ maturity + dist_cbd_km`: non-mature **OR 0.36**
>   (0.22–0.58, p < 0.001), distance OR 1.15 per km. The maturity effect from the
>   old pooled fit survives on ECDA alone, but read it as supporting evidence
>   only. The unadjusted maturity OR is 0.91 (p = 0.55). Maturity and distance to
>   the CBD correlate at r = 0.72: non-mature preschools sit further out (median
>   15.0 km against 8.4 km), though both arms share the 7.0–16.3 km band, which
>   holds 63% and 62% of them. The effect rests mainly on Sengkang (69% missed):
>   dropping it gives OR 0.57 (p = 0.03), while dropping Hougang (83%) alone leaves
>   OR 0.37 (p = 0.001); only dropping both removes it, 0.83 (p = 0.56). The
>   standard errors are not clustered by town (26 towns).
> - **Quality flag** (ECDA only): island miss rate 90.3%. 141 subzones hold at
>   least 5 preschools and get a flag: 9 better / 124 typical / 8 worse. The other
>   191 have an NA flag: 100 with no preschool, 91 with 1–4. The empirical-Bayes
>   prior sample size is kappa = 17.5.
> - CHAS, supplementary: recall 22.2% (19.9–24.7%). Miss rate 78.6% mature vs
>   73.4% non-mature, p = 0.06, MDD 7.4 pp. Logistic OR 0.53 (0.34–0.81).
>   Random labelling p = 0.003.
>
> - **Matcher error** (`06_matcher_error.R`, verdicts in
>   `data/external/coverage_validation_verdicts.csv`, unsure rows excluded): ECDA
>   false-match 0/40, false-miss 1/38 (2.6%, Wilson 0.5–13.5%). Two more of those
>   38 are in OSM only as `building=kindergarten`, a tag the crosswalk does not
>   read: a tagging gap, not matcher error. CHAS false-match 3/40 (7.5%), all from
>   the postcode rule in multi-tenant buildings, false-miss 3/37 (8.1%), all
>   clinics in OSM just beyond 50 m. Corrected recall: **ECDA 9.7% → 12.1%**
>   (9.3–21.9% with both error rates at their Wilson bounds; 16.8% counting the
>   tagging gaps), CHAS 22.2% → 26.9% (20.0–38.2%). OSM still misses close to nine
>   in ten preschools; matcher error accounts for 2.4 points of that gap.
>
> For section 6, the result points to the "recall low but uniform" case, with
> the north-east caveat from the logistic fit.

Owner: Member 1. Weeks 1–5. Also on the critical path: the access score (section 7),
because Q2/Q3/Q4 all consume it.

**Question.** What share of real facilities does OSM actually contain, and is the
missing share the same across the island?

**H0** (from the proposal): the share of missing facilities is equal in mature and
non-mature towns. Two-proportion test, two-sided, alpha = 0.05.

**Why it comes first.** Every later result is computed on OSM counts. If the gaps
are spatially clustered, they push Moran's I in Q2 and bias the coefficients in
Q3 in a direction we can at least name. Q1's job is to produce (a) a headline
completeness number per category, and (b) a per-subzone data-quality flag that the
other three carry as a robustness covariate.

---

## 1. Scope, and what the benchmark can and cannot say

Two authoritative lists, Singapore only:

| Reference list | Covers | OSM counterpart |
|---|---|---|
| CHAS clinic directory (data.gov.sg) | GP + dental clinics participating in CHAS | `amenity=clinic`, `amenity=doctors`, `amenity=dentist` |
| ECDA centre listing (data.gov.sg) | licensed childcare / infant care centres | `amenity=kindergarten`, `amenity=childcare` |

Two asymmetries to state in the report rather than paper over:

1. **Recall is measurable; precision mostly is not.** CHAS is a *subset* of all
   clinics (non-participating private clinics are absent), and ECDA excludes MOE
   kindergartens. So an OSM point with no reference match does not imply the OSM
   point is wrong. Report **recall** — the share of reference facilities found in
   OSM — as the headline. For precision, hand-audit a random sample of 100
   unmatched OSM health/education points against OneMap and report an estimated
   precision with a binomial CI: sampled, not a census.
2. **These two categories are the worst case, deliberately.** Both are typically
   small units inside HDB blocks and void decks — exactly what contributors miss.
   Frame the result as a lower bound for food services, retail and recreation,
   which are far more visible. Do not extrapolate the number itself to them.

Hong Kong gets no equivalent audit; there is no comparable open list. The
consequence for the cross-city comparison is handled in section 6.

## 2. Getting the reference lists onto the map

Both lists are addresses, not coordinates. (Check on download — if a lat/lon
column exists, use it and skip geocoding, but still verify a sample by eye.)

1. Clean: trim whitespace, pad postal codes to 6 digits, drop duplicate rows on
   (name, postcode), and record how many were dropped.
2. Geocode by **postal code** through the OneMap Search API, which returns both
   WGS84 and SVY21 coordinates. Postal code beats free-text address here —
   Singapore postal codes are effectively building-level identifiers.
3. Fall back to full-address search for failures, and list whatever still fails
   in `docs/geocode_failures.csv`. If more than ~2% fail, that is worth a sentence.
4. Transform to EPSG:3414. Snap nothing.

**Known trap:** a postal-code geocode returns the *building* point. A clinic in
unit #01-23 of an HDB block sits at the block point, while the OSM node may be
placed at the actual shopfront — an offset of 20–80 m with no error on either
side. This is the main driver of the match threshold in section 3, so the
threshold has to be chosen with that in mind rather than assumed.

Output: `data/interim/ref_chas.gpkg`, `data/interim/ref_ecda.gpkg`.

## 3. Matching OSM to the reference lists

This is record linkage, not a spatial join. Both distance and name are needed:
distance alone fails for multi-tenant buildings (a medical centre can hold six
clinics at one point); name alone fails for chains (nine "Healthway Medical").

**Candidate pairs.** For each reference point, every OSM point of the matching
category within `d` metres (`sf::st_is_within_distance`).

**Name score.** Normalise both names — lowercase, drop punctuation, drop
`pte ltd` / `llp` / `singapore`, expand `&`→`and`, `ctr`→`centre`, `med`→`medical`,
collapse whitespace. Then compute Jaro–Winkler
(`stringdist::stringsim(method = "jw", p = 0.1)`) **and** a token-set Jaccard on
the word sets, and keep the larger of the two — the first handles typos, the
second handles reordering.

**Decision rule.** A pair is a match if `dist <= d` **and**
(`name_sim >= s` **or** the OSM `addr:postcode` equals the reference postal code).
The postcode clause rescues correct matches where the OSM name is missing
altogether — common, and otherwise counted as a false miss.

**One-to-one.** Several reference points often compete for one OSM node. Score
each candidate pair (`name_sim` primary, `-dist` as tiebreak) and solve the
assignment optimally with `clue::solve_LSAP`; greedy best-first is an acceptable
fallback, but say which was used.

**Thresholds are a result, not a setting.** Do not pick `d = 50, s = 0.85` and
move on. Run the grid `d ∈ {25, 50, 100, 150} m` × `s ∈ {0.70, 0.80, 0.90}` and
report recall for all twelve cells in the appendix, with the middle cell as the
headline. If recall swings by more than ~10 pp across the grid, the honest
headline is a range, not a number.

**Validate the matcher itself.** Hand-check a stratified random sample of 40
accepted matches and 40 rejected reference facilities (seed fixed and recorded),
and report the false-match and false-miss rate of the *procedure*. This is the
difference between "OSM recall is 68%" and "our matcher says 68%".

Output: `data/interim/match_table.csv` — one row per reference facility, with
`matched` (logical), `osm_id`, `dist_m`, `name_sim`, `rule_fired`.

## 4. The test: are the gaps spread evenly?

**Grouping variable.** The proposal says mature vs non-mature town. One line of
caveat is warranted: HDB retired the mature/non-mature classification in 2024
(replaced by the Standard/Plus/Prime flat framework). So fix the list explicitly
as a historical definition, store it in `data/external/town_maturity.csv` with a
source note, and treat it as a given classification rather than current policy.
Assign each reference facility to a planning area by point-in-polygon on MP19.

Facilities outside any HDB town (Central Area, Tuas, Western Water Catchment,
offshore) cannot be classified — report the count and exclude them, rather than
silently folding them into one arm.

**Power check before running it** (`pwr::pwr.2p2n.test`). With roughly 1,000+ CHAS
clinics and 1,500+ ECDA centres split across the two arms, a difference of ~5 pp
should be detectable at 80% power. If the arms come out lopsided, say so — a null
result resting on 60 facilities in one arm means very little.

**Test.** `prop.test(c(miss_mature, miss_nonmature), c(n_mature, n_nonmature))`.
Report both proportions, the difference, the 95% CI on the difference, the
statistic and p. Run it per category and pooled; with three tests, Holm-adjust.
The CI matters more than the p-value here — "gaps differ by 3 pp, CI −2 to +8" is
a useful answer, and it is not the same claim as "no difference".

**One stronger test, because the binary split throws away the geography.**
Random labelling on the reference point pattern (`spatstat`): permute the
matched/missed labels across the fixed set of facility locations 999 times and
compare the observed `Kcross` (or mark-connection function) against the envelope.
Under H0 the gaps are a random thinning of the real facilities, so clustering of
missed points *beyond* the clustering of the facilities themselves shows up here
and is invisible to a two-town split. This is Q1's "method from outside the
module", alongside precision/recall and the multiple-testing correction.

If time allows, a logistic regression of `missed ~ maturity + distance to CBD +
subzone population density` shows which of those actually carries the effect.
Optional, and reported as supporting rather than headline.

## 5. Outputs

- `outputs/tables/q1_recall_by_category.csv` — n, matched, recall, Wilson 95% CI.
- `outputs/tables/q1_threshold_sensitivity.csv` — the twelve-cell grid.
- `outputs/tables/q1_prop_test.csv` — proportions, difference, CI, p, adjusted p.
- `outputs/figures/q1_missrate_map.png` — subzone choropleth of miss rate with
  missed facilities drawn over it. Subzones holding fewer than 5 reference
  facilities are greyed out, not coloured; a one-of-one miss is not 100%.
- `outputs/figures/q1_random_labelling.png` — the envelope plot.
- `data/processed/subzone_quality_flag.csv` — per subzone, counting ECDA
  preschools only (CHAS clinics never enter it): reference count, miss rate,
  empirical-Bayes shrunk miss rate (so thin subzones do not dominate), and a
  three-level flag. Built by `R/02_coverage/03_quality_flag.R`. **This is the
  hand-off to Q2/Q3/Q4.**
  The flag is NA below 5 preschools, the same cut that greys out the map.
  Otherwise it cuts the posterior probability that the subzone's true miss rate
  is below the island mean (Beta posterior from the empirical-Bayes prior):
  at least 0.90 is "better", at most 0.10 "worse", anything between "typical".
  This replaced a ±5 pp band around the mean. With the mean near 0.9 that band
  let a single matched preschool make a subzone "better", while no subzone with
  fewer than 6 preschools could ever be "worse". Some asymmetry remains, and it
  is real: when the mean is already 0.9, a high miss rate is weak evidence, so
  "worse" needs about twenty or more preschools, nearly all of them missed.
  The prior is fitted by moments on subzones with at least 5 preschools, after
  subtracting the binomial share of the variance in their raw rates.

## 6. What the answer changes downstream

Write this section as instructions to the other three, not as a conclusion:

- **Recall roughly uniform** → carry on; cite the number as a limitation; done.
- **Recall low but uniform** → counts are scaled down fairly evenly, so relative
  comparisons survive but "number of amenities within 1 km" as an absolute figure
  does not. Q2/Q3/Q4 stand; the score is ordinal, not absolute.
- **Recall varies systematically** (the interesting case) → name the direction.
  If non-mature towns are under-mapped, their access scores are biased *downward*,
  which inflates Moran's I in Q2 (the missingness is itself spatially structured)
  and inflates any Q3 coefficient correlated with town age. Q3 then refits with
  the quality flag as a control; Q2 reports Moran's I with and without the weakest
  category.
- Any category whose recall is bad enough to be unusable is dropped from the
  **cross-city** comparison and its weight redistributed over the remaining five —
  decided here, in Q1, and stated explicitly rather than quietly kept.

Standing caveat: this audit is Singapore-only, so HK completeness is unmeasured
and a cross-city difference in access could in principle be a difference in
mapping effort. Partial mitigation: report OSM contributor and edit density per
small area for both cities as a crude comparability check, and keep the rest as a
stated limitation.

## 7. Dependency — the access score (M1 also owns this)

Not part of Q1's question, but it is what the other three are waiting on.

- **Wk 2 deliverable: rough equal-weight Singapore score** written to
  `data/processed/`, so M2/M3/M4 can start. Ship it knowingly imperfect — the
  schema is what matters, so freeze the column names then and do not change them.
- **Wk 3: final score, both cities**, with spending weights applied.
- Extraction: one `osmdata` query per category with an explicit tag list, kept in
  `R/tags.R` and reused verbatim for both cities. Identical queries are what make
  the comparison legitimate.
- De-duplicate: polygons and relations to centroids, then drop same-category
  points within 25 m whose normalised names match. Left untreated, malls and food
  courts double-count badly.
- ~~Population-weighted centroids: use a gridded population raster (GHS-POP or
  WorldPop, 100 m) for *both* cities rather than a Singapore-specific source, so
  the centroid definition is identical on each side.~~ **Superseded** by item 3
  in `docs/decisions.md` (proposed; on branch `score/v0` until it merges):
  centroids are weighted by OSM residential building footprints instead.
- Detour factor: 200 sampled OD pairs routed on the OSM foot network (`dodgr`, or
  a local OSRM foot profile); report the mean ratio and its spread, and apply the
  1 km walk as a `1000 / detour` straight-line radius. Report score sensitivity to
  the factor at ±1 SD. Kept off the critical path by design.

## 8. Week plan

| Wk | Q1 work | Done when |
|---|---|---|
| 1 | Download CHAS, ECDA, MP19 subzones; log each in `docs/data_log.md`; confirm the OSM extract loads for both cities | raw files present and logged |
| 2 | OSM extraction, cleaning, de-dup; geocode both reference lists; **ship the rough equal-weight score** | score in `data/processed/`, schema frozen |
| 3 | Matcher built, threshold grid run, 80-case hand validation; detour factor; final weighted score for both cities | `match_table.csv` + final score |
| 4 | (M2 runs Q2 on the score) — M1 buffer and catch-up | — |
| 5 | Proportion test, random labelling, maps, quality flag; hand section 6 to M2/M3/M4 | all outputs written |

## 9. Risks specific to Q1

- **Geocoding is the hidden time sink** — rate limits and address-format failures.
  Cache every API response to `data/interim/geocode_cache/` so a rerun is free,
  and start it in Week 1, not Week 3.
- **Threshold fishing.** It is tempting to tune `d` and `s` until recall looks
  respectable. Defence: publish the grid in the appendix, and do the 80-case hand
  validation once, at thresholds chosen *before* looking at the recall number.
- **The reference lists are snapshots.** OSM is edited continuously; CHAS and ECDA
  are dated extracts, and clinics open and close. A few percent of "misses" are
  facilities that did not exist when the area was mapped. Record both dates, state
  it, and do not chase it further.
- **A null result is a real outcome.** If the gaps are spread evenly, that is a
  clean answer that strengthens Q2–Q4, and the report should say so plainly rather
  than hunting for a split that yields a significant p.

Next (from the validation check, 2026-11-09):
- The headline thresholds are **not** re-tuned on these verdicts (section 9, threshold
  fishing). Candidate fixes for a future, pre-declared matcher version: require name
  similarity with the postcode rule for clinics; allow 75–100 m when name similarity is
  near 1; pull `building=kindergarten` (two of the ECDA false misses are mapped only that
  way); strip spaces inside brand names ("Sparkle Tots").
- 29 sample rows are flagged `needs_maps_check` (possible closures, generic names, church
  preschools). A Google Maps pass on them would firm up the rates.
- Every ECDA childcare record carries `FMEL_UPD_D` 2021-12-01, though the portal says the
  dataset was updated 2026-04. Some "missing" centres may have closed or renamed since 2021.
