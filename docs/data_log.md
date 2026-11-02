# Download log

One row per raw file. All Singapore; Q1 is Singapore-only.

| File (under `data/raw/sg/`) | Dataset | Source | Downloaded | Licence | md5 | Notes |
|---|---|---|---|---|---|---|
| `chas_clinics.geojson` | CHAS Clinics | https://data.gov.sg/datasets/d_548c33ea2d99e29ec63a7cc9edcccedc/view | 2026-09-15 | SODL 1.0 | `e40034db422a77754f482e738e248437` | 1,644,760 B. data.gov.sg API v2, dataset last updated 2024-06-06 |
| `childcare_services.geojson` | Child Care Services (ECDA) | https://data.gov.sg/datasets/d_5d668e3f544335f8028f546827b773b4/view | 2026-09-15 | SODL 1.0 | `3cdf1df41203fc05270d283bb1ed1484` | 1,488,543 B. data.gov.sg API v2, dataset last updated 2026-04-18 |
| `kindergartens.geojson` | Kindergartens (ECDA) | https://data.gov.sg/datasets/d_7fe9a72b1afff18e48111772c8d0fd39/view | 2026-09-15 | SODL 1.0 | `c00af23d9e3715b1b9e539f6ba0cb97f` | 338,619 B. data.gov.sg API v2, dataset last updated 2026-04-18 |
| `moh_health_fac.csv` | Health Facilities counts (MOH, aggregate) | https://data.gov.sg/datasets/d_e4663ad3f088a46dabd3972dc166402d/view | 2026-09-15 | SODL 1.0 | `3fbb7b201c981f2771af59f6aa18e737` | 6,200 B. data.gov.sg API v2, dataset last updated 2024-06-06 |
| `mp19_subzone.geojson` | Master Plan 2019 Subzone Boundary (No Sea) | https://data.gov.sg/datasets/d_8594ae9ff96d0c708bc2af633048edfb/view | 2026-09-15 | SODL 1.0 | `86bd781ffe03ce9e804fe6701bac24cb` | 3,180,569 B. data.gov.sg API v2, dataset last updated 2025-12-03 |
| `osm_education.json` | OSM education POIs, Singapore | https://overpass-api.de/api/interpreter (area 3600536780) | 2026-09-15 | ODbL 1.0 | `0fd4e67653dd5959e32a65de3a736c5f` | 438,872 B. Overpass query stored in R/tags.R |
| `osm_health.json` | OSM health POIs, Singapore | https://overpass-api.de/api/interpreter (area 3600536780) | 2026-09-15 | ODbL 1.0 | `dddb57c850c77660d9b31e6c9ad1b80a` | 339,056 B. Overpass query stored in R/tags.R |
| `preschools_location.geojson` | Pre-Schools Location (ECDA) | https://data.gov.sg/datasets/d_61eefab99958fd70e6aab17320a71f1c/view | 2026-09-15 | SODL 1.0 | `971aa67aec688fad242c30b68d25e4ee` | 1,341,092 B. data.gov.sg API v2, dataset last updated 2024-06-06 |
| `census2020_age.csv` | Resident Population by PA/Subzone, Age Group and Sex (Census 2020) | https://data.gov.sg/datasets/d_d95ae740c0f8961a0b10435836660ce0/view | 2026-11-02 | SODL 1.0 | `701fface4ec41ef354bc31ebf2449801` | 85,943 B. Fetched by `R/01_prep/00_fetch_datagov.R`; dataset last updated 2026-09-06. Subzones by name, "-" = 0 |
| `census2020_dwelling.csv` | Resident Population by PA/Subzone and Type of Dwelling (Census 2020) | https://data.gov.sg/datasets/d_7f243956483d5901f237e6f87b096636/view | 2026-11-02 | SODL 1.0 | `2ec5baa402184c21f61cd69836a01f87` | 17,653 B. Fetched by `R/01_prep/00_fetch_datagov.R`; dataset last updated 2026-09-06. Subzones by name, "-" = 0 |
| `hes_quinquennial.csv` | Avg Monthly Household Expenditure by Type of Goods and Services, Quinquennial (HES) | https://data.gov.sg/datasets/d_7a24e1f85969c45ad68a89f7acf4e7a8/view | 2026-11-02 | SODL 1.0 | `7dc1b1a90f54e7c7f04c4a0de9fa678d` | 1,284 B. Fetched by `R/01_prep/00_fetch_datagov.R`; dataset last updated 2026-09-09. Source of the six weights (2023 column) |
| `mp19_rail_station.geojson` | Master Plan 2019 Rail Station layer | https://data.gov.sg/datasets/d_8d886e3a83934d7447acdf5bc6959999/view | 2026-11-02 | SODL 1.0 | `88d72e70cc991017a371de2d8645e131` | 784,676 B. Fetched by `R/01_prep/00_fetch_datagov.R`; dataset last updated 2025-12-05. Station polygons |
