# Proposal requirements — TBA4220

Verbatim brief, plus a compliance check against `proposal_v2.docx`.
Source: course brief. Recorded 2026-09-16.

---

## 1. The brief (as given)

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

---

## 2. Compliance check

| # | Requirement | Status | Note |
|---|---|---|---|
| 1.1 | ≥ 2 datasets | **met** | Six: OSM (both cities), CHAS, ECDA, HES 2023, MP19 subzones, SG Census 2020, HK 2021 Census. |
| 1.2 | Methods beyond this course | **met** | Record linkage w/ precision & recall; two-proportion test; Holm correction; random labelling (spatstat); k-means w/ silhouette + stability resampling; random forest; spatially-blocked CV. Proposal already names these explicitly in a *Methods from outside this module* paragraph — keep that paragraph, it is where this criterion is scored. |
| 2 | Quality of information | **at risk** | Q1's claim ("how complete is OSM") is not supported by the benchmarks available. See §3. |
| 3 | Quality of design — feasible, manageable | **at risk** | Pedestrian routing and the HK data pull are the two schedule risks; both already have stated contingencies. Keep them. |
| 4 | No obvious facts | **check on edit** | Do not explain what Moran's I / LISA / a choropleth *is*. State what is run, on what, against which H0. Explaining a *design choice* is not an obvious fact and should stay. |
| 5 | 5 pages | **likely breached** | Current draft runs long. Cuts proposed in §4. |
| — | Complexity justifies 4 members | **met, but fragile** | Four members = four distinct method families. Any move to replace a question with a purely descriptive one (e.g. "which amenity is most common") weakens this criterion — descriptive work does not carry a workstream. |
| — | Cover Page | **met** | |
| — | Abstract, single paragraph | **met** | |
| — | Objective: questions in testable form | **met** | All four carry an explicit H0. |
| — | Data: source + collection | **met** | Collection is correctly described as "no survey; two derived steps" (matching, routed sample). |

---

## 3. The one substantive fix  — DECIDED 2026-09-16

Q1 as drafted asks *how complete* OSM is. That requires a census benchmark.
CHAS is not one: it covers scheme-participating GP/dental clinics only, and MOH's
own aggregates put national GP clinics near ~1,800 against CHAS's ~1,193. A subset
benchmark gives unbiased recall only if scheme membership is unrelated to how
likely OSM is to map the facility — which fails here, and fails along the *same
axis* (heartland vs central) as Q1's own mature/non-mature hypothesis.

**Decision: Q1 narrows to preschools, benchmarked against ECDA, and the claim
changes from completeness to spatial uniformity.** CHAS is dropped.

Rationale:

- ECDA (childcare + kindergartens) is effectively a census of its category. The
  only known exclusion is MOE Kindergartens, ~60 against ~1,975, about 3%. It is
  the one benchmark available to this project that does not have the subset
  problem, so it is the one worth keeping.
- Uniformity is estimable from a benchmark that is complete-in-category; a
  completeness *level* for all amenities is not estimable from anything we have.
- Uniformity is also what Q2-Q4 actually need from Q1: whether OSM's measurement
  error is spatially structured, not how large it is.

**Accepted cost, to be stated in the proposal rather than hidden.** Audited
coverage falls from two categories (28.0% of score weight) to one — education,
**12.9%**. This is a deliberate trade: it removes the benchmark-validity objection
at the price of narrower category coverage. It is defensible only *because* the
claim is now about spatial structure rather than about a completeness level that
would need to generalise across categories.

Optional extension if the schedule holds: recreation (NParks / SportSG / PA / NLB
point layers, already geocoded, no postcode step, ~800 records) would take audited
weight to 24%. Food services is worth more (30.8%) but needs postcode extraction
from ~36,700 free-text address strings. Retail goods (16.1%) has no government
registry in any form and should be named as unauditable.

**Health stays as one of the six score categories.** Only the CHAS *audit* is
dropped. The six weights are unchanged, and Q3's elderly-access hypothesis depends
on health being present.

## 4. Page-limit cuts

In priority order, if over 5 pages:

1. Compress *Where the Weights Come From* — keep the weight table, cut the
   two-paragraph justification to three sentences. The table carries the argument.
2. Collapse the 8-row work plan table into two sentences plus the dependency note
   (the Week-2 rough-score release is the only bit a reviewer needs).
3. Fold *Limitations* into the Method section as one closing paragraph.
4. Trim the reference list to the four that are actually cited in the text.

Do not cut: the four H0 statements, the *Methods from outside this module*
paragraph, or the *What could go wrong* contingencies. Those are scored directly
under criteria 1.2 and 3.
