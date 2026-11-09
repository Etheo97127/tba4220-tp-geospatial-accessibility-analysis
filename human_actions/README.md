# Human actions

Everything in the project that needs a person: a check an agent cannot do reliably, a
decision that should be a human's, or something to read and learn. The code never
reads this folder. When a task is done, apply its result where the "Then" column
says, and tick it here.

| # | Task | Status | Then |
|---|---|---|---|
| 1 | [Google Maps check of 29 coverage rows](#1-google-maps-check-of-29-coverage-rows) | open | results into `data/input/external/coverage_validation_verdicts.csv`; rerun `coverage` |
| 2 | [Review the 12 agreed decisions](#2-review-the-12-agreed-decisions) | open (optional) | edit `docs/consideration.md` and the constant in `R/00_setup.R`; rerun all |
| 3 | [Confirm the calendar, deadlines and report format](#3-confirm-the-calendar-deadlines-and-report-format) | open | fix the calendar line in `docs/consideration.md`; tell the agent the format and page limit |
| 4 | [ECDA childcare timestamp](#4-ecda-childcare-timestamp) | **done** 2026-11-09 | no newer edition; the 2021 record date is a stated limitation in the report |
| 5 | [Read the methods outside the lectures](#5-read-the-methods-outside-the-lectures) | open | use it when reviewing the report |
| 6 | [Push and open the pull request](#6-push-and-open-the-pull-request) | open | after the report is assembled and reviewed |
| — | Verify the six 2026 rail openings | **done** 2026-11-09 | CCL6 opened 2026-07-12 (kept); TEL5/DTL3e open 2026-12-26 (dropped). Commit `a78c472` |
| — | Hand-check the 160-row coverage sample | **done** 2026-11-09 | checked by an agent; 29 rows left for task 1 |

## 1. Google Maps check of 29 coverage rows

`maps_check_rows.csv` lists the 29 validation-sample rows an agent could not settle
without Google Maps: possibly closed clinics, generic names and church preschools.
The other 131 rows are settled. With Gemini's Google Maps connector, for each row ask:

> Is there a [clinic / preschool] named *ref_name* at *address* (postcode *ref_post*,
> near *lat*, *lon*) open today? Give the Google Maps place name, its status (open /
> permanently closed / moved / not found) and the Maps link.

Fill `maps_place_name`, `maps_status` (open / closed / moved / not_found) and `maps_url`
in the same file, then hand it back. How results are applied:

- **closed or moved**: the facility was not there to be mapped, so it leaves the
  reference list instead of counting as missing (verdict `excluded`).
- **open**: the agent's verdict stands, or an `unsure` becomes `correct` (the facility
  exists and OSM lacks it).
- **not found**: stays `unsure`.

Each row applied gets `needs_maps_check` set to `FALSE` in
`data/input/external/coverage_validation_verdicts.csv`. The report counts the rows still
`TRUE`, and stops calling the error rates provisional once none are left.

The false-match and false-miss rates in `data/output/tables/coverage_matcher_error.csv`
then tighten. The sample (40 per group) is large enough; it does not need to grow.

## 2. Review the 12 agreed decisions

`docs/consideration.md` lists the P0 decisions, accepted on 2026-11-09 under your
delegation. The ones that most shape results:

- 2 (≥ 1,000 residents per residential subzone);
- 3 (OSM building footprints for the population-weighted centres; dormitories excluded);
- 4 (housing mix = share in HDB 1–3 room flats);
- 11 (log scaling to the residential maximum);
- 10 (which methods are kept).

To change one, edit its row with a dated note, change the constant in `R/00_setup.R`
if it has one, and rerun `Rscript R/run_all.R`.

## 3. Confirm the calendar, deadlines and report format

The plan's weeks are relative. Everything assumes W1 = week of 26 Oct 2026, so the
report is due around the end of W6 (about 6 Dec 2026). Check the real submission date
and correct the calendar line in `docs/consideration.md`.

The report format is now known (30-page limit; Introduction, Background, Data, Methods,
Analysis, Conclusions, Extra mile) and the report follows it, with an extra section on
reproducing the results. `Rscript report/scripts/render.R` writes `report/report.docx`:
28 pages in Word, nine figures and six tables. Word is used because no LaTeX is
installed; for PDF, open the .docx in Word and save as PDF. Still to confirm: the
submission date and whether the course wants .docx or PDF.

## 4. ECDA childcare timestamp

Every record in `data/input/raw/sg/childcare_services.geojson` has `FMEL_UPD_D` =
2021-12-01, though data.gov.sg says the dataset was updated 2026-04-18. Some centres
that look "missing from OSM" may have closed or been renamed since 2021. Check the
dataset page
(<https://data.gov.sg/datasets/d_5d668e3f544335f8028f546827b773b4/view>) for a newer
edition. If there is one, delete the raw file and rerun
`R/01_prep/00_fetch_datagov.R` (it re-downloads only missing files); otherwise state
the 2021 vintage as a limitation.

**Result (2026-11-09):** the data.gov.sg API still gives 2026-04-18 as the dataset's
last update, the edition downloaded on 2026-09-15, so there is nothing newer. The
report's Discussion states the 2021 record date as a limitation, and
`docs/plans/coverage_check.md` notes it. Recheck only if data.gov.sg publishes a new edition.

## 5. Read the methods outside the lectures

[`methods_outside_lectures.md`](methods_outside_lectures.md) classifies every method
the pipeline uses against the course (`docs/course_knowledge.md`): taught, extends a
lecture, or not taught. Each entry gives a plain explanation, why it is used, and the
reference the report must cite. Read it before reviewing the report, so every
non-course method can be defended in Q&A.

## 6. Push and open the pull request

All work is on local stacked branches. When the report is assembled and reviewed, push
the final branch and open one pull request to `master`. The agent will ask before
pushing.
