# 05_q2_regression/02_covariates.R ----------------------------------------------
# C2: one row per subzone with the Q2 predictors. Elderly share and housing mix
# are the tested variables (decision 4 defines housing mix); density, distance to
# rail and mapping effort are controls. Distance is measured from the same
# population-weighted centre the score counts from, so both describe one point.

source("R/00_setup.R")

census   <- read_csv(file.path(DIR_PROC, "census2020_subzone.csv"), show_col_types = FALSE)
res      <- read_csv(file.path(DIR_PROC, "residential_set.csv"), show_col_types = FALSE)
centres  <- readRDS(file.path(DIR_PROC, "score_centres.rds"))
rail     <- readRDS(file.path(DIR_PROC, "rail_stations.rds"))
contrib  <- read_csv(file.path(DIR_PROC, "osm_contributors.csv"), show_col_types = FALSE)

# Distance to the edge of the nearest station footprint, not its centroid: an
# interchange polygon can be 300 m long.
nearest <- st_nearest_feature(centres, rail)
dist_rail <- tibble(subzone_c = centres$subzone_c,
                    dist_rail_m = as.numeric(st_distance(centres, rail[nearest, ], by_element = TRUE)),
                    nearest_station = rail$name[nearest])

cov <- census %>%
  select(subzone_c, pop, pop_65plus, dw_total, dw_hdb_1_2room, dw_hdb_3room) %>%
  left_join(res %>% select(subzone_c, residential), by = "subzone_c") %>%
  left_join(contrib %>% select(subzone_c, area_km2, n_contributors, contributors_per_km2), by = "subzone_c") %>%
  left_join(dist_rail, by = "subzone_c") %>%
  mutate(elderly_share = if_else(pop > 0, pop_65plus / pop, NA_real_),
         housing_mix   = if_else(dw_total > 0, (dw_hdb_1_2room + dw_hdb_3room) / dw_total, NA_real_),
         # Density is strongly right-skewed (0 to ~50,000 per km2), so it enters on the log scale.
         log_density   = if_else(pop > 0, log(pop / area_km2), NA_real_),
         log_contrib   = log1p(contributors_per_km2)) %>%
  select(subzone_c, residential, pop, area_km2, elderly_share, housing_mix, log_density,
         dist_rail_m, nearest_station, contributors_per_km2, log_contrib)

rs <- cov %>% filter(residential)
stopifnot(nrow(cov) == 332, !anyNA(rs %>% select(-nearest_station)))

saveRDS(cov, file.path(DIR_PROC, "subzone_covariates.rds"))

desc <- rs %>%
  summarise(across(c(elderly_share, housing_mix, log_density, dist_rail_m, log_contrib),
                   list(mean = mean, sd = sd, min = min, max = max))) %>%
  pivot_longer(everything(), names_to = c("variable", ".value"), names_pattern = "(.+)_(mean|sd|min|max)$") %>%
  mutate(across(c(mean, sd, min, max), ~ round(.x, 3)))
write_csv(desc, file.path(DIR_TAB, "q2_covariates_summary.csv"))
log_step("subzone_covariates.rds: ", nrow(rs), " residential subzones; median distance to rail ",
         round(median(rs$dist_rail_m)), " m, elderly share ", round(100 * median(rs$elderly_share), 1),
         "%, housing mix ", round(100 * median(rs$housing_mix), 1), "%")
