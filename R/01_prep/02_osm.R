# 01_prep/02_osm.R --------------------------------------------------------------
# Turn the raw Overpass snapshot (data/raw/sg/osm/, pulled by 00_fetch_osm.R)
# into one tidy sf point layer for the coverage check and the access score.
#
# Ways and relations are reduced to their centre (Overpass `out center`), so a
# school drawn as a building polygon and a clinic mapped as a single node end up
# comparable. Everything is Singapore only.

source("R/00_setup.R")

# --- tag -> category ---------------------------------------------------------
# data/external/osm_crosswalk.csv is the single definition. `osm_cat` is the
# fine type the coverage check matches on; `category` is one of the six score
# categories; `scored = FALSE` rows (hospitals) are kept for the coverage check
# but never counted in the score.

crosswalk <- read_csv(file.path(DIR_EXT, "osm_crosswalk.csv"), show_col_types = FALSE)
stopifnot(!any(duplicated(crosswalk[, c("key", "value")])),
          setequal(unique(crosswalk$category), CATEGORIES))

# When an element carries tags from more than one key (a cafe that is also
# tagged healthcare=*), the first key here decides its category.
KEY_ORDER <- c("amenity", "healthcare", "shop", "leisure", "tourism")
stopifnot(all(crosswalk$key %in% KEY_ORDER))

`%||%` <- function(a, b) if (is.null(a)) b else a

read_overpass <- function(path) {
  els <- fromJSON(path, simplifyVector = FALSE)$elements
  tag <- function(k) vapply(els, function(e) e$tags[[k]] %||% NA_character_, character(1))
  out <- tibble(
    osm_type = vapply(els, function(e) e$type, character(1)),
    osm_ref  = vapply(els, function(e) as.character(e$id), character(1)),
    lon = vapply(els, function(e) e$lon %||% e$center$lon %||% NA_real_, numeric(1)),
    lat = vapply(els, function(e) e$lat %||% e$center$lat %||% NA_real_, numeric(1)),
    uid       = vapply(els, function(e) as.character(e$uid %||% NA), character(1)),
    timestamp = vapply(els, function(e) e$timestamp %||% NA_character_, character(1)),
    name      = tag("name"),
    name_en   = tag("name:en"),
    operator  = tag("operator"),
    postcode  = tag("addr:postcode"),
    access    = tag("access")
  )
  for (k in KEY_ORDER) out[[k]] <- tag(k)
  out
}

files <- list.files(file.path(DIR_RAW, "osm"), pattern = "^osm_.*\\.json$", full.names = TRUE)
files <- files[!grepl("residential_buildings", files)]
osm <- bind_rows(lapply(files, read_overpass))
log_step("overpass elements read: ", nrow(osm), " from ", length(files), " files")

# An element can be returned by more than one category's query.
osm <- osm[!duplicated(paste(osm$osm_type, osm$osm_ref)), ]

# Drop anything without a usable position (relations with no center).
no_geom <- is.na(osm$lon) | is.na(osm$lat)
log_step("dropped, no coordinate: ", sum(no_geom))
osm <- osm[!no_geom, ]

# Resolve category in KEY_ORDER: the first key whose value is in the crosswalk wins.
osm$key <- NA_character_; osm$value <- NA_character_
for (k in KEY_ORDER) {
  hit <- is.na(osm$key) & osm[[k]] %in% crosswalk$value[crosswalk$key == k]
  osm$key[hit] <- k; osm$value[hit] <- osm[[k]][hit]
}
osm <- osm %>%
  filter(!is.na(key)) %>%
  left_join(crosswalk, by = c("key", "value")) %>%
  mutate(tag = paste0(key, "=", value),
         # Condo playgrounds, private gyms and staff canteens are not open to residents.
         scored = scored & !(access %in% c("private", "no")))

osm <- osm %>%
  mutate(osm_id   = paste0(substr(osm_type, 1, 1), osm_ref),
         osm_name = coalesce(name, name_en, operator)) %>%
  st_as_sf(coords = c("lon", "lat"), crs = CRS_WGS84) %>%
  st_transform(CRS_SVY21)

# --- de-duplicate ------------------------------------------------------------
# A POI mapped both as a node and as a building polygon appears twice. Collapse
# same-category features within 25 m that share a normalised name. Unnamed
# features are never collapsed -- we cannot tell two anonymous clinics apart.

osm$name_norm <- normalise_name(osm$osm_name)
cand <- st_is_within_distance(osm, osm, dist = 25)
drop <- rep(FALSE, nrow(osm))
for (i in seq_len(nrow(osm))) {
  if (drop[i] || is.na(osm$name_norm[i]) || osm$name_norm[i] == "") next
  for (j in cand[[i]]) {
    if (j <= i || drop[j]) next
    if (!is.na(osm$name_norm[j]) &&
        osm$name_norm[j] == osm$name_norm[i] &&
        osm$osm_cat[j] == osm$osm_cat[i]) drop[j] <- TRUE
  }
}
log_step("de-duplicated OSM features (same name, same osm_cat, <25 m): ", sum(drop))
osm <- osm[!drop, ]

# --- subzone ----------------------------------------------------------------
subzones <- readRDS(file.path(DIR_INT, "subzones.rds"))
osm <- st_join(osm, subzones, join = st_within)

saveRDS(osm, file.path(DIR_INT, "osm_poi.rds"))
log_step("OSM POIs kept: ", nrow(osm), " (", sum(osm$scored), " scored)")
print(st_drop_geometry(osm) %>%
        group_by(category, osm_cat) %>%
        summarise(n = n(), scored = sum(scored),
                  pct_named = round(100 * mean(!is.na(osm_name) & osm_name != ""), 1),
                  .groups = "drop") %>%
        as.data.frame())
