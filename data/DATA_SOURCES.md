# Data sources — URLs for manual checking

Every dataset proposed for this project, with a link you can open in a browser.
Checked 2026-09-16. Singapore links were resolved through the data.gov.sg v2 API,
so the dataset ID, name, format and last-updated date below are what the portal
itself returned, not what I remembered.

Two link styles are given for data.gov.sg:

- **View** — the human page on data.gov.sg. Open this one to eyeball it.
- **Download** — `https://api-open.data.gov.sg/v1/public/api/datasets/<id>/poll-download`
  returns a JSON envelope containing a short-lived signed URL. This is what the
  project scripts call; paste it in a browser and you get the JSON, not the file.

Status key: **downloaded** = already in `data/raw/sg/` and used; **proposed** =
named in the proposal or needed for later questions, not yet pulled.

---

## A. Singapore — downloaded and used in Q1

| Dataset | Agency | Format | Portal last updated | Status | Link |
|---|---|---|---|---|---|
| CHAS Clinics | MOH | GEOJSON | 2024-06-06 | downloaded | [view](https://data.gov.sg/datasets/d_548c33ea2d99e29ec63a7cc9edcccedc/view) |
| Child Care Services | ECDA | GEOJSON | 2026-04-18 | downloaded | [view](https://data.gov.sg/datasets/d_5d668e3f544335f8028f546827b773b4/view) |
| Kindergartens | ECDA | GEOJSON | 2026-04-18 | downloaded | [view](https://data.gov.sg/datasets/d_7fe9a72b1afff18e48111772c8d0fd39/view) |
| Pre-Schools Location | ECDA | GEOJSON | 2024-06-06 | downloaded, **cross-check only** | [view](https://data.gov.sg/datasets/d_61eefab99958fd70e6aab17320a71f1c/view) |
| Master Plan 2019 Subzone Boundary (No Sea) | URA | GEOJSON | 2025-12-03 | downloaded | [view](https://data.gov.sg/datasets/d_8594ae9ff96d0c708bc2af633048edfb/view) |
| Health Facilities (Primary Care, Dental Clinics and Pharmacies) | MOH | CSV | 2024-06-06 | downloaded, **aggregate counts only** | [view](https://data.gov.sg/datasets/d_e4663ad3f088a46dabd3972dc166402d/view) |

Dataset IDs, md5 hashes and file sizes for these are in [`../docs/data_log.md`](../docs/data_log.md).

**Read before trusting these:**

- **Pre-Schools Location is not what we used.** It is the combined ECDA file, but
  it carries no postal codes and was last refreshed 2024-06. Child Care Services +
  Kindergartens are used instead: they have postal codes (needed for the
  postcode-match rule) and were refreshed 2026-04. The two ECDA files overlap —
  2,373 rows collapse to **1,975 distinct centres**, verified as the same centre
  listed twice at identical coordinates.
- **Health Facilities is aggregate counts by year, not a facility list.** It cannot
  serve as a benchmark. It is useful only as an independent denominator — it puts
  the national GP clinic count in the ~1,800 range, which is how we know CHAS
  (1,193) is a subset rather than the universe.
- **CHAS was last updated 2024-06**, so it is roughly two years behind the live OSM
  extract. Some "missing" clinics are clinics that closed.

## B. Singapore — proposed, not yet downloaded

Needed for the access score and for Q3. IDs verified against the portal.

| Dataset | Agency | Format | Portal last updated | Needed for | Link |
|---|---|---|---|---|---|
| Avg Monthly Household Expenditure by Type of Goods and Services, **Quinquennial** | SingStat | CSV | 2026-09-09 | the six weights | [view](https://data.gov.sg/datasets/d_7a24e1f85969c45ad68a89f7acf4e7a8/view) |
| Resident Population by PA/Subzone, Age Group and Sex (Census 2020) | SingStat | CSV | 2026-09-06 | elderly share (Q3) | [view](https://data.gov.sg/datasets/d_d95ae740c0f8961a0b10435836660ce0/view) |
| Resident Population by PA/Subzone and Type of Dwelling (Census 2020) | SingStat | CSV | 2026-09-06 | housing mix (Q3) | [view](https://data.gov.sg/datasets/d_7f243956483d5901f237e6f87b096636/view) |
| Master Plan 2019 Rail Station layer | URA | GEOJSON | 2025-12-05 | distance to transit (Q3) | [view](https://data.gov.sg/datasets/d_8d886e3a83934d7447acdf5bc6959999/view) |
| Hawker Centres | NEA | GEOJSON | 2026-09-16 | *suggested addition* — a third benchmark | [view](https://data.gov.sg/datasets/d_4a086da0a5553be1d89383cd90d07ecd/view) |

**The expenditure dataset is not the one the proposal implies, and this matters.**
The proposal cites "Household Expenditure Survey 2023". On data.gov.sg the
*detailed* HES tables (by type of goods and services **and income quintile**) stop
at **2017/18** — there are four of them, for 2002/03, 2007/08, 2012/13 and 2017/18,
and no 2023 edition. The only file on the portal carrying 2023 figures is the
Quinquennial series above, which covers 1993–2023 but gives **no income-quintile
breakdown**.

I checked the proposal's weight table against it, and every figure reconciles:

| Proposal category | S$/month | Source line in the quinquennial file |
|---|---|---|
| Food services | 965.7 | Food And Beverage Serving Services |
| Retail goods | 504.2 | Clothing And Footwear (119.6) **+** Furnishing, Household Equipment and Routine Household Maintenance (384.6) |
| Health | 473.5 | Health |
| Food retail | 455.9 | Food And Non-Alcoholic Beverages |
| Education | 404.2 | Education |
| Recreation, sport and culture | 334.7 | Recreation, Sport And Culture |
| **Total** | **3,138.2** | sums exactly |

So the weights are reproducible from one public file — good. But note that "Retail
goods" is a **derived sum of two COICOP divisions**, not a published line item, and
that should be stated in the report rather than left looking like a direct
quotation. If anyone later wants weights that vary by income group, that has to
come from SingStat Table Builder, not from data.gov.sg.

SingStat Table Builder: <https://tablebuilder.singstat.gov.sg/> — *returned 403 to
an automated request; it works in a normal browser.*

## C. Hong Kong — proposed, not downloaded, **not yet verified**

Q1 is Singapore-only, so nothing here was needed yet. I have **not** confirmed
specific HK dataset IDs, and I am not going to invent deep links. These are the
portals to search; treat the dataset identity as an open question.

| What we need | Where to look | Checked |
|---|---|---|
| 2021 Population Census by Small Tertiary Planning Unit Group | Census & Statistics Dept, 2021 Census site — <https://www.censtatd.gov.hk/en/scode600.html> | reachable |
| Same, via the open data portal | <https://data.gov.hk/en-datasets/search?q=tertiary+planning+unit> | reachable |
| TPU / Small TPU Group boundary files | data.gov.hk search above; also the CSDI geoportal — <https://portal.csdi.gov.hk/> | **CSDI refused an automated request — open it in a browser** |
| C&SD landing page | <https://www.censtatd.gov.hk/en/> | reachable |

**Open risk, flagged in the proposal's own contingency:** there is no Hong Kong
equivalent of CHAS or ECDA, so the Q1 completeness audit cannot be repeated there.
Whatever the HK boundary and census files turn out to be, the cross-city comparison
rests on an assumption about OSM completeness in HK that we have no way to test the
same way.

## D. OpenStreetMap

The facility locations, and the only source available in identical form for both
cities.

| Route | URL | Notes |
|---|---|---|
| **Overpass API** (what the project uses) | <https://overpass-api.de/api/interpreter> | POST a query; the exact queries are in `R/02_osm.R`. **Clicking this link gives a 406** — it only answers POSTs, so use Overpass Turbo below to look at a query |
| Overpass Turbo (to eyeball a query) | <https://overpass-turbo.eu/> | paste a query and run it visually |
| Geofabrik — Malaysia/Singapore/Brunei extract | <https://download.geofabrik.de/asia/malaysia-singapore-brunei.html> | Singapore is **not** a standalone Geofabrik extract; it comes bundled |
| Geofabrik — China extract | <https://download.geofabrik.de/asia/china.html> | where HK would come from if using Geofabrik |
| BBBike custom extracts | <https://extract.bbbike.org/> | lets you draw a box — easier for Hong Kong alone |

Singapore was pulled via Overpass using the OSM administrative area
`3600536780` (relation 536780), which clips to the national boundary and avoids
dragging in Johor Bahru the way a bounding box would.

Licence: ODbL 1.0 — attribution required, share-alike on derived databases.

## E. Supporting service

| Service | URL | Used for |
|---|---|---|
| OneMap Search API | <https://www.onemap.gov.sg/apidocs/> | address/postcode → SVY21 + WGS84 |

Not actually needed in the end: every data.gov.sg file above already carries point
geometry, so the geocoding step the plan budgeted for dropped out. Keep the link —
it is the fallback if a future reference list arrives as addresses only.

## Licences

- data.gov.sg datasets: Singapore Open Data Licence 1.0 — <https://data.gov.sg/open-data-licence>
- OpenStreetMap: ODbL 1.0 — <https://www.openstreetmap.org/copyright>
- data.gov.hk: check each dataset's own terms — <https://data.gov.hk/en/terms-and-conditions>
