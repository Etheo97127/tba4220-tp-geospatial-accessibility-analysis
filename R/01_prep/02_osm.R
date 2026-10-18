# 01_prep/02_osm.R --------------------------------------------------------------
# Turn the raw Overpass responses into a tidy sf point layer.
#
# Ways and relations are reduced to their centroid (Overpass `out center`), so a
# school drawn as a building polygon and a clinic mapped as a single node end up
# comparable. Everything is Singapore only.

source("R/00_setup.R")

# --- tag -> analysis category ------------------------------------------------
# Kept as an explicit lookup rather than buried in a regex: the coverage check reports recall per
# category, and the other questions reuse this file for the access score.

OSM_CATEGORY <- tribble(
  ~key,         ~value,            ~osm_cat,
  "amenity",    "clinic",          "clinic",
  "amenity",    "doctors",         "clinic",
  "amenity",    "dentist",         "clinic",
  "healthcare", "clinic",          "clinic",
  "healthcare", "doctor",          "clinic",
  "healthcare", "dentist",         "clinic",
  "healthcare", "centre",          "clinic",
  "amenity",    "pharmacy",        "pharmacy",
  "healthcare", "pharmacy",        "pharmacy",
  "amenity",    "hospital",        "hospital",
  "amenity",    "kindergarten",    "preschool",
  "amenity",    "childcare",       "preschool",
  "amenity",    "school",          "school",
  "amenity",    "college",         "college",
  "amenity",    "university",      "college",
  "amenity",    "library",         "library",
  "amenity",    "language_school", "other_education",
  "amenity",    "music_school",    "other_education"
)

read_overpass <- function(file) {
  j <- fromJSON(file.path(DIR_RAW, file), simplifyVector = FALSE)
  els <- j$elements
  tibble(
    osm_type = vapply(els, function(e) e$type, character(1)),
    osm_ref  = vapply(els, function(e) as.character(e$id), character(1)),
    lon = vapply(els, function(e) if (!is.null(e$lon)) e$lon else if (!is.null(e$center)) e$center$lon else NA_real_, numeric(1)),
    lat = vapply(els, function(e) if (!is.null(e$lat)) e$lat else if (!is.null(e$center)) e$center$lat else NA_real_, numeric(1)),
    name      = vapply(els, function(e) e$tags[["name"]]      %||% NA_character_, character(1)),
    name_en   = vapply(els, function(e) e$tags[["name:en"]]   %||% NA_character_, character(1)),
    operator  = vapply(els, function(e) e$tags[["operator"]]  %||% NA_character_, character(1)),
    postcode  = vapply(els, function(e) e$tags[["addr:postcode"]] %||% NA_character_, character(1)),
    amenity   = vapply(els, function(e) e$tags[["amenity"]]    %||% NA_character_, character(1)),
    healthcare= vapply(els, function(e) e$tags[["healthcare"]] %||% NA_character_, character(1))
  )
}
`%||%` <- function(a, b) if (is.null(a)) b else a

osm <- bind_rows(read_overpass("osm_health.json"),
                 read_overpass("osm_education.json"))
log_step("overpass elements read: ", nrow(osm))

# Drop anything without a usable position (relations with no center).
no_geom <- is.na(osm$lon) | is.na(osm$lat)
log_step("dropped, no coordinate: ", sum(no_geom))
osm <- osm[!no_geom, ]

# Resolve category. `amenity` wins over `healthcare` where both are present,
# because it is the tag the query was built on.
osm <- osm %>%
  left_join(filter(OSM_CATEGORY, key == "amenity") %>% select(amenity = value, cat_a = osm_cat), by = "amenity") %>%
  left_join(filter(OSM_CATEGORY, key == "healthcare") %>% select(healthcare = value, cat_h = osm_cat), by = "healthcare") %>%
  mutate(osm_cat = coalesce(cat_a, cat_h)) %>%
  select(-cat_a, -cat_h) %>%
  filter(!is.na(osm_cat))

# An element can be returned by both queries (e.g. a clinic inside a school).
osm <- osm[!duplicated(paste(osm$osm_type, osm$osm_ref)), ]

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
log_step("de-duplicated OSM features (same name, same category, <25 m): ", sum(drop))
osm <- osm[!drop, ]

# --- subzone ----------------------------------------------------------------
subzones <- readRDS(file.path(DIR_INT, "subzones.rds"))
osm <- st_join(osm, subzones, join = st_within)

saveRDS(osm, file.path(DIR_INT, "osm_poi.rds"))
log_step("OSM POIs kept: ", nrow(osm))
print(st_drop_geometry(osm) %>%
        count(osm_cat) %>%
        mutate(named = vapply(osm_cat, function(k)
          sum(!is.na(osm$osm_name[osm$osm_cat == k]) & osm$osm_name[osm$osm_cat == k] != ""), integer(1)),
          pct_named = round(100 * named / n, 1)))
