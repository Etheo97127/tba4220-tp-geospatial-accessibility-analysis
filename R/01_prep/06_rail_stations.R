# 01_prep/06_rail_stations.R ----------------------------------------------------
# Rail stations in service, for Q2's distance-to-transit covariate. The MP19 layer
# is a master plan, so it also draws lines that were not running at the OSM
# snapshot (2026-11-02): Jurong Region and Cross Island Lines, shell stations,
# TEL5/DTL3e (opens 2026-12-26). Those are listed in
# data/external/rail_not_open.csv as "not_open" and dropped. Rows marked "open"
# there record checked 2026 openings (Circle Line stage 6, 2026-07-12).
# Nine polygons carry no name (e.g. Orchard Boulevard, a Sentosa Express stop,
# platforms inside Chinatown and Newton); they are kept as "unnamed" and open,
# since dropping them overstated distance to rail for central subzones.

source("R/00_setup.R")

raw <- st_read(file.path(DIR_RAW, "mp19_rail_station.geojson"), quiet = TRUE) %>%
  st_zm(drop = TRUE) %>%
  st_transform(CRS_SVY21) %>%
  st_make_valid()
not_open <- read_csv(file.path(DIR_EXT, "rail_not_open.csv"), show_col_types = FALSE)

stations <- raw %>%
  transmute(name = str_squish(NAME), rail_type = RAIL_TYPE) %>%
  mutate(name = if_else(is.na(name) | name == "<Null>", "unnamed", name)) %>%
  mutate(status = coalesce(not_open$status[match(name, not_open$name)], "open"))

missing <- setdiff(not_open$name, stations$name)
if (length(missing)) stop("rail_not_open.csv names not in the MP19 layer: ", paste(missing, collapse = ", "))

stations <- stations %>% filter(status != "not_open")

saveRDS(stations, file.path(DIR_PROC, "rail_stations.rds"))
log_step("rail_stations.rds: ", n_distinct(stations$name), " stations in service (",
         nrow(stations), " polygons), ", sum(stations$status == "uncertain"),
         " polygons marked uncertain; dropped ", sum(not_open$status == "not_open"), " not-yet-open stations")
