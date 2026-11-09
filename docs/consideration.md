# Considerations

Everything the project has to satisfy or has decided, and why: the course brief
(§1), the benchmark choice for the coverage check (§2), the twelve P0 decisions
(§3) and the category crosswalk (§4). Code cites these as "consideration.md §3
item N". A decision changes only with a dated note in its row.

---

## 1. Course brief

Verbatim, recorded 2026-09-16.

> The main aim of this report is to explain your ideas and designs. Make sure the
> reviewers have enough details to give you feedback and advice.
>
> The report will be graded based on the following:
>
> 1. **Project Scope:**
>    1. The project should leverage at least 2 datasets (if you find one
>       comprehensive dataset, it is ok to use just one)
>    2. The analysis should use statistical methods learned beyond this course
>       (from other courses)
> 2. **Quality of information.**
> 3. **Quality of design:** Clearly thought out, feasible, easy to manage, etc.
> 4. Kindly **do not write obvious facts** (like how GIS works) in the design report.
> 5. **Page Limit (5 pages)**
>
> The proposal should have the following sections (we encourage you to add more
> sections):
>
> 1. **Cover Page:** Title, group name, course code, team members
> 2. **Abstract:** a crisp single-paragraph description of the project
> 3. **Objective:**
>    - What is (are) the question(s) that you aim to answer?
>    - Pose the question(s) in a form that is amenable to statistical testing.
>    - Why should we care / What is the motivation?
> 4. **Data:**
>    - Source
>    - data collection (if any)
>
> NOTE: your project should be complex enough to justify the size of your team.

What follows from it for the report:

- Methods from outside the course are scored under 1.2, so each one gets a
  citation and a one-sentence explanation (§3 item 10).
- Do not explain what Moran's I, LISA or a choropleth *is*. State what is run, on
  what, against which H₀. Explaining a design choice is not an obvious fact.
- Four members need four distinct method families; a purely descriptive question
  would not carry a workstream.

---

## 2. Coverage benchmark: ECDA, CHAS supplementary

**Decided 2026-09-16, amended 2026-11-08.**

The coverage check asks how *uniformly* OSM covers preschools, benchmarked against
ECDA, not how *complete* OSM is. A completeness claim needs a census benchmark, and
CHAS is not one: it lists scheme-participating GP and dental clinics only (~1,193
against MOH's ~1,800 GP clinics). A subset benchmark gives unbiased recall only if
scheme membership is unrelated to how likely OSM is to map the clinic, and that
fails along the same heartland / central axis as the mature / non-mature test.

- ECDA (childcare + kindergartens) is effectively a census of its category. The
  only known exclusion is MOE Kindergartens, ~60 of ~1,975, about 3%.
- Uniformity is estimable from a benchmark that is complete in its category; a
  completeness level for all amenities is not estimable from anything we have.
- Uniformity is what Q1–Q3 need: whether OSM's error is spatially structured, not
  how large it is.

**Accepted cost, stated in the report.** Audited coverage is one category,
education, **12.9%** of score weight (two categories, 28.0%, with CHAS). Recreation
(NParks / SportSG / PA / NLB points, ~800 records) would take it to 24%; food
services (30.8%) needs postcodes parsed from ~36,700 address strings; retail goods
(16.1%) has no registry and is unauditable.

**Amendment, 2026-11-08: CHAS kept as a labelled supplementary benchmark.** Tables
and figures report CHAS, marked "supplementary", next to ECDA. It is never pooled
with ECDA, never a headline result and never enters the subzone quality flag. It
shows the bias above: its missed clinics cluster beyond chance where ECDA's do not
(random labelling p = 0.001 against 0.32), and its mature / non-mature gap (78.6%
vs 73.4% missed, p = 0.06) runs along the heartland / central axis.

Health stays one of the six score categories with its weight unchanged; only the
CHAS audit is demoted.

---

## 3. P0 decisions

The twelve gaps listed under "Settle before work starts" in
`docs/archive/team_plan.html`, one row each.

**Status: agreed 2026-11-09.** Drafted 2026-11-02 and accepted by Qu Haotian, who
is the only member working on the project, after checking each against the
results.

Calendar: the plan's W1 is taken as the week of **26 Oct 2026**. That made H1 and
H2 due 1 Nov, and H3 and H4 due 8 Nov.

| # | Gap | Decision | Owner | Status |
|---|---|---|---|---|
| 1 | Density rule | Q3 clusters on density-adjusted scores if density alone explains **more than half** the full model's R² (C5: R² of `score ~ log_density` ÷ R² of the full model > 0.5). Fixed before Q2 runs. | C, D | agreed 2026-11-09 |
| 2 | Residential cut-off | A subzone counts as residential if it has **≥ 1,000 residents** (Census 2020 total). Report n at 500 and 1,000 too, so the choice is visible. Shared constant `RES_MIN_POP` in `R/00_setup.R`; C1 publishes the set as H2. | C | agreed 2026-11-09 |
| 3 | Population layer | **OSM residential building footprints** (`building` = apartments, residential, house, detached, semidetached_house, terrace, bungalow), weighted by footprint area × `building:levels`, with missing levels imputed by building type. Dormitories are pulled but get no weight: most house migrant workers, who are not in the Census resident count. Subzones with no residential buildings fall back to `st_point_on_surface()` and are flagged. The query pulls buildings mapped as ways only: those mapped as multipolygon relations get no weight (250 relations against 45,867 ways on Overpass on 2026-11-09, about 0.5%). This replaces the GHS-POP / WorldPop raster in `docs/plans/coverage_check.md` §7. That choice was made for a two-city score; the Hong Kong extension is dropped, and buildings keep every input in one source. | A | agreed 2026-11-09 |
| 4 | Housing mix | **Share of residents in HDB 1–3 room flats** (1-and-2-room plus 3-room, over all residents in the dwelling table). Higher means less affluent. Expected sign on the score: **negative** (less affluent subzones have lower access at the same density), tested one-sided like elderly share. | C | agreed 2026-11-09 |
| 5 | Test for H₀(b) | F statistic from `anova(lm(residual ~ type))`. Permute residuals **within** spatial blocks (H3), 999 times. p = share of permuted F ≥ observed. | D | agreed 2026-11-09 |
| 6 | Town groups | Planning-area level, from `data/input/external/town_maturity.csv`: mature / non-mature / excluded. **Excluded subzones are left out of H₀(a)**, not treated as a third group. HDB's own list counts "Central Area" as a mature estate. We still exclude the Central Area planning areas: their subzones are mostly commercial, and their residents are a small, unrepresentative share. Say so in the report. D1 adds the source URL and date to the file. | D | agreed 2026-11-09 |
| 7 | Walk radius | 1 km main score. **800 m and 1.2 km variants** are computed in the same loop (A8), reported as rank correlation with the main score. | A | agreed 2026-11-09 |
| 8 | Local-test correction | **Benjamini–Hochberg FDR at q = 0.05** for LISA (`p.adjust(p, "BH")`), with 9,999 permutations: at 999 the smallest two-sided p is 0.002 and BH over 201 subzones can pass nothing. | B | agreed 2026-11-09 |
| 9 | Text fix: "three caveats" lists two | Add the third caveat in the report: the weights are **national averages** (the 2023 quinquennial file has no income breakdown), so every subzone is scored on the same basket whatever its residents actually spend. Also state that "Retail goods" is the sum of two COICOP divisions, not a published line. | A | agreed 2026-11-09 |
| 10 | Methods outside the lectures | Keep LISA (Q3 needs its outliers), OLS + VIF + LM tests, then a spatial error **or lag** model chosen by the robust LM tests (Anselin's rule; the data chose lag, with the error model reported beside it) (Q2); silhouette tested against a no-cluster null + spatial block bootstrap + Jaccard (Q3). **Drop Gi\***: it repeats LISA's clusters and cannot show outliers. Each kept method gets a citation and a one-sentence explanation in the report. | B, C, D | agreed 2026-11-09 |
| 11 | Score normalisation | Category score = **100 × log1p(count) ÷ max log1p(count) over the residential set**, so 0–100 with the best-served residential subzone at 100. Composite = Σ HES weight × category score, also 0–100. Equal-weight variant = mean of the six. Non-residential subzones can exceed 100; they are outside every analysis. | A | agreed 2026-11-09 |
| 12 | Permutation for H₀(a) | Permute town-group labels **between whole blocks** (each block keeps one label), 999 times, with the chi-square statistic of type × town group. H₀(b) still permutes residuals within blocks (item 5). | D | agreed 2026-11-09 |

---

## 4. Category crosswalk

Follows from §3 item 11 and the proposal's Table 2. The tag → category table is
`data/input/external/osm_crosswalk.csv`, and the OSM pull is generated from it, so
the file is the single definition. Choices worth checking:

- Hospitals are pulled (the coverage check uses them) but **not scored**. The proposal's
  health examples are GP and dental clinics, polyclinics and pharmacies.
- Libraries count as **education**, as in the proposal's Table 2.
- Bars and pubs are not pulled: alcohol is its own COICOP division, outside the six.
- Private facilities (`access=private` or `no`: condo playgrounds, staff canteens) are pulled
  but not scored.
- Swimming pools and sports pitches are not pulled at all: in Singapore most are condo
  facilities, and they are mapped too unevenly to count.
- Every facility is one point. Overpass gives a way or relation the centre of its bounding
  box, so a long or large park counts as a single point that may sit far from residents
  living along it. Pasir Ris Park and Changi Beach Park land outside every subzone. This
  understates recreation access beside coastal and linear parks. A fix for v1 would measure
  parks by distance to the polygon edge.
- `shop=electronics` counts as retail goods. In Singapore these stores mostly sell household
  appliances (COICOP 05), even though audio-visual equipment strictly falls under recreation.
