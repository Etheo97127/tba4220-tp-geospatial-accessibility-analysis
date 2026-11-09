# 01_prep/07_osm_contributors.R -------------------------------------------------
# Mapping effort per subzone, Q2's control for how thoroughly OSM covers an area:
# distinct mappers per km2. The snapshot carries only the last editor of each
# feature, so this undercounts contributors; it is a relative measure of effort,
# not a census of mappers.

source("R/00_setup.R")

osm      <- readRDS(file.path(DIR_INT, "osm_poi.rds")) %>% st_drop_geometry()
subzones <- readRDS(file.path(DIR_INT, "subzones.rds"))

area <- tibble(subzone_c = subzones$subzone_c,
               area_km2 = as.numeric(st_area(subzones)) / 1e6)

contrib <- osm %>%
  filter(!is.na(subzone_c)) %>%
  group_by(subzone_c) %>%
  summarise(n_features = n(), n_contributors = n_distinct(uid, na.rm = TRUE), .groups = "drop")

out <- area %>%
  left_join(contrib, by = "subzone_c") %>%
  mutate(across(c(n_features, n_contributors), ~ coalesce(.x, 0L)),
         contributors_per_km2 = n_contributors / area_km2)

stopifnot(nrow(out) == 332)
write_csv(out %>% mutate(area_km2 = round(area_km2, 4), contributors_per_km2 = round(contributors_per_km2, 3)),
          file.path(DIR_PROC, "osm_contributors.csv"))
log_step("osm_contributors.csv: median ", median(out$n_contributors), " mappers per subzone, ",
         sum(out$n_contributors == 0), " subzones with none")
