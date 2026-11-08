# 01_prep/06_rail_stations.R ----------------------------------------------------
# Rail stations in service, for Q2's distance-to-transit covariate. The MP19 layer
# is a master plan, so it also draws lines that were not running at the OSM
# snapshot (Jurong Region and Cross Island Lines, shell stations). Those are
# listed in data/external/rail_not_open.csv and dropped; stations marked
# "uncertain" there (2026 openings) are kept until someone confirms them.

source("R/00_setup.R")

raw <- st_read(file.path(DIR_RAW, "mp19_rail_station.geojson"), quiet = TRUE) %>%
  st_zm(drop = TRUE) %>%
  st_transform(CRS_SVY21) %>%
  st_make_valid()
not_open <- read_csv(file.path(DIR_EXT, "rail_not_open.csv"), show_col_types = FALSE)

stations <- raw %>%
  transmute(name = str_squish(NAME), rail_type = RAIL_TYPE) %>%
  filter(!is.na(name), name != "<Null>") %>%
  mutate(status = coalesce(not_open$status[match(name, not_open$name)], "open"))

missing <- setdiff(not_open$name, stations$name)
if (length(missing)) stop("rail_not_open.csv names not in the MP19 layer: ", paste(missing, collapse = ", "))

stations <- stations %>% filter(status != "not_open")

saveRDS(stations, file.path(DIR_PROC, "rail_stations.rds"))
log_step("rail_stations.rds: ", n_distinct(stations$name), " stations in service (",
         nrow(stations), " polygons), ", sum(stations$status == "uncertain"),
         " polygons marked uncertain; dropped ", sum(not_open$status == "not_open"), " not-yet-open stations")
