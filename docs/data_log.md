# Data log

Every dataset the project uses: §1 logs each raw file (source, date, md5,
licence), §2 says what to know before trusting each source, §3 lists links
kept for later. A new raw file needs a `00_fetch_*.R` script and a row in §1.

## 1. Download log

One row per raw file, all Singapore. The Source column is the human page; open
it to eyeball the dataset.

| File (under `data/raw/sg/`) | Dataset | Source | Downloaded | Licence | md5 | Notes |
|---|---|---|---|---|---|---|
| `chas_clinics.geojson` | CHAS Clinics | https://data.gov.sg/datasets/d_548c33ea2d99e29ec63a7cc9edcccedc/view | 2026-09-15 | SODL 1.0 | `e40034db422a77754f482e738e248437` | 1,644,760 B. data.gov.sg API v2, dataset last updated 2024-06-06 |
| `childcare_services.geojson` | Child Care Services (ECDA) | https://data.gov.sg/datasets/d_5d668e3f544335f8028f546827b773b4/view | 2026-09-15 | SODL 1.0 | `3cdf1df41203fc05270d283bb1ed1484` | 1,488,543 B. data.gov.sg API v2, dataset last updated 2026-04-18 |
| `kindergartens.geojson` | Kindergartens (ECDA) | https://data.gov.sg/datasets/d_7fe9a72b1afff18e48111772c8d0fd39/view | 2026-09-15 | SODL 1.0 | `c00af23d9e3715b1b9e539f6ba0cb97f` | 338,619 B. data.gov.sg API v2, dataset last updated 2026-04-18 |
| `moh_health_fac.csv` | Health Facilities counts (MOH, aggregate) | https://data.gov.sg/datasets/d_e4663ad3f088a46dabd3972dc166402d/view | 2026-09-15 | SODL 1.0 | `3fbb7b201c981f2771af59f6aa18e737` | 6,200 B. data.gov.sg API v2, dataset last updated 2024-06-06 |
| `mp19_subzone.geojson` | Master Plan 2019 Subzone Boundary (No Sea) | https://data.gov.sg/datasets/d_8594ae9ff96d0c708bc2af633048edfb/view | 2026-09-15 | SODL 1.0 | `86bd781ffe03ce9e804fe6701bac24cb` | 3,180,569 B. data.gov.sg API v2, dataset last updated 2025-12-03 |
| `osm_education.json` | OSM education POIs, Singapore | https://overpass-api.de/api/interpreter (area 3600536780) | 2026-09-15 | ODbL 1.0 | `0fd4e67653dd5959e32a65de3a736c5f` | 438,872 B. Superseded by the 2026-11-02 snapshot in `osm/`; kept because the first coverage-check run used it. Its query was never saved |
| `osm_health.json` | OSM health POIs, Singapore | https://overpass-api.de/api/interpreter (area 3600536780) | 2026-09-15 | ODbL 1.0 | `dddb57c850c77660d9b31e6c9ad1b80a` | 339,056 B. Superseded by the 2026-11-02 snapshot in `osm/`; kept because the first coverage-check run used it. Its query was never saved |
| `preschools_location.geojson` | Pre-Schools Location (ECDA) | https://data.gov.sg/datasets/d_61eefab99958fd70e6aab17320a71f1c/view | 2026-09-15 | SODL 1.0 | `971aa67aec688fad242c30b68d25e4ee` | 1,341,092 B. data.gov.sg API v2, dataset last updated 2024-06-06 |
| `census2020_age.csv` | Resident Population by PA/Subzone, Age Group and Sex (Census 2020) | https://data.gov.sg/datasets/d_d95ae740c0f8961a0b10435836660ce0/view | 2026-11-02 | SODL 1.0 | `701fface4ec41ef354bc31ebf2449801` | 85,943 B. Fetched by `R/01_prep/00_fetch_datagov.R`; dataset last updated 2026-09-06. Subzones by name, "-" = 0 |
| `census2020_dwelling.csv` | Resident Population by PA/Subzone and Type of Dwelling (Census 2020) | https://data.gov.sg/datasets/d_7f243956483d5901f237e6f87b096636/view | 2026-11-02 | SODL 1.0 | `2ec5baa402184c21f61cd69836a01f87` | 17,653 B. Fetched by `R/01_prep/00_fetch_datagov.R`; dataset last updated 2026-09-06. Subzones by name, "-" = 0 |
| `hes_quinquennial.csv` | Avg Monthly Household Expenditure by Type of Goods and Services, Quinquennial (HES) | https://data.gov.sg/datasets/d_7a24e1f85969c45ad68a89f7acf4e7a8/view | 2026-11-02 | SODL 1.0 | `7dc1b1a90f54e7c7f04c4a0de9fa678d` | 1,284 B. Fetched by `R/01_prep/00_fetch_datagov.R`; dataset last updated 2026-09-09. Source of the six weights (2023 column) |
| `mp19_rail_station.geojson` | Master Plan 2019 Rail Station layer | https://data.gov.sg/datasets/d_8d886e3a83934d7447acdf5bc6959999/view | 2026-11-02 | SODL 1.0 | `88d72e70cc991017a371de2d8645e131` | 784,676 B. Fetched by `R/01_prep/00_fetch_datagov.R`; dataset last updated 2025-12-05. Station polygons |
| `osm/osm_food_services.json` | OSM POIs, category `food_services` | https://overpass-api.de/api/interpreter (area 3600536780) | 2026-11-02 | ODbL 1.0 | `8734809976dc86bcc3f0e6e4e7dfc5fc` | 4,141,739 B, 8,925 elements, OSM base 2026-11-02T14:36:28Z. Query generated from `data/external/osm_crosswalk.csv` by `R/01_prep/00_fetch_osm.R`, saved as `osm_food_services.overpassql` |
| `osm/osm_retail.json` | OSM POIs, category `retail` | https://overpass-api.de/api/interpreter (area 3600536780) | 2026-11-02 | ODbL 1.0 | `65f6b75074aa49619a17bbd39c660524` | 1,003,732 B, 1,997 elements, OSM base 2026-11-02T14:38:32Z. Query generated from `data/external/osm_crosswalk.csv` by `R/01_prep/00_fetch_osm.R`, saved as `osm_retail.overpassql` |
| `osm/osm_health.json` | OSM POIs, category `health` | https://overpass-api.de/api/interpreter (area 3600536780) | 2026-11-02 | ODbL 1.0 | `6864fab7b9f79f065863c06dac927a05` | 496,534 B, 1,037 elements, OSM base 2026-11-02T14:39:33Z. Query generated from `data/external/osm_crosswalk.csv` by `R/01_prep/00_fetch_osm.R`, saved as `osm_health.overpassql` |
| `osm/osm_food_retail.json` | OSM POIs, category `food_retail` | https://overpass-api.de/api/interpreter (area 3600536780) | 2026-11-02 | ODbL 1.0 | `3bed60377980f7b3e31b852c31b638b4` | 1,056,884 B, 2,316 elements, OSM base 2026-11-02T14:40:34Z. Query generated from `data/external/osm_crosswalk.csv` by `R/01_prep/00_fetch_osm.R`, saved as `osm_food_retail.overpassql` |
| `osm/osm_education.json` | OSM POIs, category `education` | https://overpass-api.de/api/interpreter (area 3600536780) | 2026-11-02 | ODbL 1.0 | `ec517a5d7e29ad368186fc3d7fe427b4` | 791,695 B, 1,306 elements, OSM base 2026-11-02T14:41:36Z. Query generated from `data/external/osm_crosswalk.csv` by `R/01_prep/00_fetch_osm.R`, saved as `osm_education.overpassql` |
| `osm/osm_recreation.json` | OSM POIs, category `recreation` | https://overpass-api.de/api/interpreter (area 3600536780) | 2026-11-02 | ODbL 1.0 | `186e11ec26c3e61d15cebad9dd9385ca` | 3,108,663 B, 6,154 elements, OSM base 2026-11-02T14:43:36Z. Query generated from `data/external/osm_crosswalk.csv` by `R/01_prep/00_fetch_osm.R`, saved as `osm_recreation.overpassql` |
| `osm/osm_residential_buildings_ne1.json` | OSM residential building footprints, tile `ne1` | https://overpass-api.de/api/interpreter (area 3600536780) | 2026-11-02 | ODbL 1.0 | `ae3f66c08518ba70d2f95f2b6140a4b0` | 14,126,357 B, 10,634 ways with geometry, OSM base 2026-11-02T15:40:28Z. Tile extents in `TILES`, `R/01_prep/00_fetch_osm.R`; query saved as `.overpassql` |
| `osm/osm_residential_buildings_ne2.json` | OSM residential building footprints, tile `ne2` | https://overpass-api.de/api/interpreter (area 3600536780) | 2026-11-02 | ODbL 1.0 | `ed63daee08b93e8e5fb7105fa727426d` | 55,135 B, 78 ways with geometry, OSM base 2026-11-02T15:44:32Z. Tile extents in `TILES`, `R/01_prep/00_fetch_osm.R`; query saved as `.overpassql` |
| `osm/osm_residential_buildings_nw1.json` | OSM residential building footprints, tile `nw1` | https://overpass-api.de/api/interpreter (area 3600536780) | 2026-11-02 | ODbL 1.0 | `2d1bf9390424cac0a6425869130e557f` | 429,488 B, 489 ways with geometry, OSM base 2026-11-02T15:38:27Z. Tile extents in `TILES`, `R/01_prep/00_fetch_osm.R`; query saved as `.overpassql` |
| `osm/osm_residential_buildings_nw2.json` | OSM residential building footprints, tile `nw2` | https://overpass-api.de/api/interpreter (area 3600536780) | 2026-11-02 | ODbL 1.0 | `b6337dec87ce9ea6f95bdebb28d7d20b` | 16,571,205 B, 11,898 ways with geometry, OSM base 2026-11-02T15:39:27Z. Tile extents in `TILES`, `R/01_prep/00_fetch_osm.R`; query saved as `.overpassql` |
| `osm/osm_residential_buildings_se.json` | OSM residential building footprints, tile `se` | https://overpass-api.de/api/interpreter (area 3600536780) | 2026-11-02 | ODbL 1.0 | `f553cf8ff541c521c91224880501d037` | 10,859,917 B, 9,652 ways with geometry, OSM base 2026-11-02T15:26:05Z. Tile extents in `TILES`, `R/01_prep/00_fetch_osm.R`; query saved as `.overpassql` |
| `osm/osm_residential_buildings_sw.json` | OSM residential building footprints, tile `sw` | https://overpass-api.de/api/interpreter (area 3600536780) | 2026-11-02 | ODbL 1.0 | `f8bff5d1b5d1e01d308f32d74e5ce995` | 14,532,679 B, 13,262 ways with geometry, OSM base 2026-11-02T15:20:02Z. Tile extents in `TILES`, `R/01_prep/00_fetch_osm.R`; query saved as `.overpassql` |

## 2. Reading the sources

Singapore links were resolved through the data.gov.sg v2 API on 2026-09-16, so
IDs, names and last-updated dates are what the portal returned. The fetch
scripts call `https://api-open.data.gov.sg/v1/public/api/datasets/<id>/poll-download`,
which returns a JSON envelope with a short-lived signed URL, not the file.

- **Pre-Schools Location is a cross-check only.** It is the combined ECDA file but
  has no postal codes and was last refreshed 2024-06. Child Care Services +
  Kindergartens are used instead: they have postal codes (needed for the
  postcode-match rule) and were refreshed 2026-04. The two overlap: 2,373 rows
  collapse to **1,975 distinct centres**, the same centre listed twice at
  identical coordinates.
- **Health Facilities is aggregate counts by year, not a facility list.** It is
  only an independent denominator: it puts national GP clinics near ~1,800, which
  is how we know CHAS (1,193) is a subset (`docs/consideration.md` §2).
- **CHAS was last updated 2024-06**, about two years behind the OSM snapshot, so
  some "missed" clinics have closed.
- **HES weights come from the Quinquennial file, not a "HES 2023" table.** The
  detailed HES tables (by goods and services *and* income quintile) stop at
  2017/18; the Quinquennial series (1993–2023) is the only file with 2023
  figures and has no income breakdown. The proposal's weights reconcile with it
  exactly:

  | Category | S$/month | Line in the Quinquennial file |
  |---|---|---|
  | Food services | 965.7 | Food And Beverage Serving Services |
  | Retail goods | 504.2 | Clothing And Footwear (119.6) + Furnishing, Household Equipment and Routine Household Maintenance (384.6) |
  | Health | 473.5 | Health |
  | Food retail | 455.9 | Food And Non-Alcoholic Beverages |
  | Education | 404.2 | Education |
  | Recreation, sport and culture | 334.7 | Recreation, Sport And Culture |
  | **Total** | **3,138.2** | sums exactly |

  "Retail goods" is a derived sum of two COICOP divisions, not a published line;
  the report says so. Income-varying weights would need SingStat Table Builder
  (<https://tablebuilder.singstat.gov.sg/>, 403 to scripts, works in a browser).
- **OSM** is pulled through Overpass with area `3600536780` (relation 536780),
  which clips to the national boundary instead of a bounding box that would take
  in Johor Bahru. `R/01_prep/00_fetch_osm.R` builds each query from
  `data/external/osm_crosswalk.csv` and saves it beside its result as
  `data/raw/sg/osm/*.overpassql`. The 2026-11-02 pull is the snapshot every stage
  uses; the September `osm_health.json` and `osm_education.json` are history.
  Opening the Overpass URL in a browser gives a 406 (it needs a descriptive
  User-Agent); paste a saved query into Overpass Turbo instead.

Licences: data.gov.sg files are under the Singapore Open Data Licence 1.0
(<https://data.gov.sg/open-data-licence>); OSM is ODbL 1.0, attribution required
and share-alike on derived databases (<https://www.openstreetmap.org/copyright>).

## 3. Not downloaded, kept for later

| Source | Link | Why it might be needed |
|---|---|---|
| Hawker Centres (NEA, GeoJSON, updated 2026-09-16) | [view](https://data.gov.sg/datasets/d_4a086da0a5553be1d89383cd90d07ecd/view) | a third coverage benchmark, for food services |
| Overpass Turbo | <https://overpass-turbo.eu/> | run a saved query visually |
| Geofabrik Malaysia/Singapore/Brunei extract | <https://download.geofabrik.de/asia/malaysia-singapore-brunei.html> | full OSM extract; Singapore is not a standalone file |
| OneMap Search API | <https://www.onemap.gov.sg/apidocs/> | address/postcode → SVY21 geocoding, if a reference list arrives as addresses only |
