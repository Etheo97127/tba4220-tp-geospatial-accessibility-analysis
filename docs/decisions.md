# P0 decisions

The twelve gaps listed under "Settle before work starts" in `docs/team_plan.html`,
one row each. P0's exit gate needs every row to carry an agreed decision.

**Status: proposed (2026-11-02), not yet agreed.** Each proposal is a default to
accept or overrule at the P0 meeting. The owner confirms it and moves it to
"agreed" with a date. Once agreed, a decision changes only with notice to every
track that uses it.

Calendar: the plan's W1 is taken as the week of **26 Oct 2026**. That makes H1 and
H2 due 1 Nov, and H3 and H4 due 8 Nov. Confirm or correct at the meeting.

| # | Gap | Proposed decision | Owner | Status |
|---|---|---|---|---|
| 1 | Density rule | Q3 clusters on density-adjusted scores if density alone explains **more than half** the full model's R² (C5: R² of `score ~ log_density` ÷ R² of the full model > 0.5). Fixed before Q2 runs. | C, D | proposed |
| 2 | Residential cut-off | A subzone counts as residential if it has **≥ 1,000 residents** (Census 2020 total). Report n at 500 and 1,000 too, so the choice is visible. Shared constant `RES_MIN_POP` in `R/00_setup.R`; C1 publishes the set as H2. | C | proposed |
| 3 | Population layer | **OSM residential building footprints** (`building` = apartments, residential, house, detached, semidetached_house, terrace, bungalow), weighted by footprint area × `building:levels`, with missing levels imputed by building type. Dormitories are pulled but get no weight: most house migrant workers, who are not in the Census resident count. Subzones with no residential buildings fall back to `st_point_on_surface()` and are flagged. This replaces the GHS-POP / WorldPop raster in `plans/coverage_check.md` §7. That choice was made for a two-city score; Hong Kong is now an optional extension, and buildings keep every input in one source. | A | proposed |
| 4 | Housing mix | **Share of residents in HDB 1–3 room flats** (1-and-2-room plus 3-room, over all residents in the dwelling table). Higher means less affluent. Expected sign on the score: **negative** (less affluent subzones have lower access at the same density), tested one-sided like elderly share. | C | proposed |
| 5 | Test for H₀(b) | F statistic from `anova(lm(residual ~ type))`. Permute residuals **within** spatial blocks (H3), 999 times. p = share of permuted F ≥ observed. | D | proposed |
| 6 | Town groups | Planning-area level, from `data/external/town_maturity.csv`: mature / non-mature / excluded. **Excluded subzones are left out of H₀(a)**, not treated as a third group. HDB's own list counts "Central Area" as a mature estate. We still exclude the Central Area planning areas: their subzones are mostly commercial, and their residents are a small, unrepresentative share. Say so in the report. D1 adds the source URL and date to the file. | D | proposed |
| 7 | Walk radius | 1 km main score. **800 m and 1.2 km variants** are computed in the same loop (A8), reported as rank correlation with the main score. | A | proposed |
| 8 | Local-test correction | **Benjamini–Hochberg FDR at q = 0.05** for LISA (`p.adjust(p, "BH")`). | B | proposed |
| 9 | Text fix: "three caveats" lists two | Add the third caveat in the report: the weights are **national averages** (the 2023 quinquennial file has no income breakdown), so every subzone is scored on the same basket whatever its residents actually spend. Also state that "Retail goods" is the sum of two COICOP divisions, not a published line. | A | proposed |
| 10 | Methods outside the lectures | Keep LISA (Q3 needs its outliers), OLS + VIF + LM tests + spatial error model (Q2), silhouette + spatial block bootstrap + Jaccard (Q3). **Drop Gi\***: it repeats LISA's clusters and cannot show outliers. Each kept method gets a citation and a one-sentence explanation in the report. | B, C, D | proposed |
| 11 | Score normalisation | Category score = **100 × log1p(count) ÷ max log1p(count) over the residential set**, so 0–100 with the best-served residential subzone at 100. Composite = Σ HES weight × category score, also 0–100. Equal-weight variant = mean of the six. Non-residential subzones can exceed 100; they are outside every analysis. | A | proposed |
| 12 | Permutation for H₀(a) | Permute town-group labels **between whole blocks** (each block keeps one label), 999 times, with the chi-square statistic of type × town group. H₀(b) still permutes residuals within blocks (item 5). | D | proposed |

## Category crosswalk (follows from item 11 and the proposal's Table 2)

The tag → category table is `data/external/osm_crosswalk.csv`, and the OSM pull is
generated from it, so the file is the single definition. Choices worth checking:

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
