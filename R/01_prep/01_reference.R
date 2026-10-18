# 01_prep/01_reference.R --------------------------------------------------------
# Build the two authoritative Singapore reference lists that OSM is judged
# against, plus the MP19 subzone frame.
#
# Note on the plan: no geocoding step is needed. All four data.gov.sg files
# already carry point geometry, so the OneMap round-trip drops out. The
# building-point offset it warned about still applies -- these coordinates are
# address points, not shopfronts.

source("R/00_setup.R")

# --- MP19 subzones -----------------------------------------------------------

subzones <- st_read(file.path(DIR_RAW, "mp19_subzone.geojson"), quiet = TRUE) %>%
  st_zm(drop = TRUE) %>%
  st_transform(CRS_SVY21) %>%
  st_make_valid() %>%
  select(subzone_c = SUBZONE_C, subzone_n = SUBZONE_N,
         pln_area_n = PLN_AREA_N, region_n = REGION_N, ca_ind = CA_IND)

log_step("subzones: ", nrow(subzones), " polygons, ",
         n_distinct(subzones$pln_area_n), " planning areas")
stopifnot(nrow(subzones) > 300, all(st_is_valid(subzones)))

# --- CHAS clinics ------------------------------------------------------------

chas_raw <- st_read(file.path(DIR_RAW, "chas_clinics.geojson"), quiet = TRUE) %>%
  st_zm(drop = TRUE)
chas_attr <- parse_kml_description(chas_raw$Description)
log_step("CHAS attribute fields: ", paste(names(chas_attr), collapse = ", "))

chas <- chas_raw %>%
  select(geometry) %>%
  bind_cols(chas_attr) %>%
  st_transform(CRS_SVY21) %>%
  transmute(
    ref_id    = paste0("CHAS_", HCI_CODE),
    ref_name  = HCI_NAME,
    ref_post  = str_pad(str_extract(POSTAL_CD, "\\d+"), 6, pad = "0"),
    ref_type  = LICENCE_TYPE,            # MC = medical clinic, DC = dental
    ref_cat   = "health"
  )

# One HCI code should be one clinic. Duplicates would inflate the denominator.
dup_chas <- sum(duplicated(chas$ref_id))
if (dup_chas > 0) log_step("WARNING: dropping ", dup_chas, " duplicate CHAS rows")
chas <- chas[!duplicated(chas$ref_id), ]
log_step("CHAS clinics: ", nrow(chas),
         " (MC ", sum(chas$ref_type == "MC", na.rm = TRUE),
         " / DC ", sum(chas$ref_type == "DC", na.rm = TRUE), ")")

# --- ECDA preschools ---------------------------------------------------------
# Child Care Services + Kindergartens are used rather than the combined
# "Pre-Schools Location" file: they carry postal codes (needed for the
# postcode-match rule) and are far more recently refreshed (2026-04 vs 2024-06).

read_ecda <- function(file, kind) {
  st_read(file.path(DIR_RAW, file), quiet = TRUE) %>%
    st_zm(drop = TRUE) %>%
    st_transform(CRS_SVY21) %>%
    transmute(
      ref_name = NAME,
      ref_post = str_pad(str_extract(as.character(ADDRESSPOSTALCODE), "\\d+"), 6, pad = "0"),
      ref_type = kind,
      ref_cat  = "education"
    )
}

ecda <- bind_rows(
  read_ecda("childcare_services.geojson", "childcare"),
  read_ecda("kindergartens.geojson",      "kindergarten")
)

# The two ECDA files overlap: a centre offering both infant care and a
# kindergarten programme can appear once in each. Collapse on name + postcode.
ecda <- ecda %>%
  mutate(.key = paste(normalise_name(ref_name), ref_post)) %>%
  group_by(.key) %>% slice(1) %>% ungroup() %>%
  select(-.key) %>%
  mutate(ref_id = sprintf("ECDA_%04d", row_number()))

log_step("ECDA preschools: ", nrow(ecda),
         " (childcare ", sum(ecda$ref_type == "childcare"),
         " / kindergarten ", sum(ecda$ref_type == "kindergarten"), ")")

# Cross-check the count against the combined ECDA file we are not using.
n_psl <- nrow(st_read(file.path(DIR_RAW, "preschools_location.geojson"), quiet = TRUE))
log_step("cross-check vs Pre-Schools Location (2024-06): ", n_psl,
         " points; our list is ", nrow(ecda))

# --- combine and attach subzone ---------------------------------------------

reference <- bind_rows(chas, ecda) %>%
  select(ref_id, ref_name, ref_post, ref_type, ref_cat)

ref_sz <- st_join(reference, subzones, join = st_within)

# A handful of address points land just outside the "No Sea" land polygons
# (reclaimed edges, jetties). Snap those to the nearest subzone rather than
# dropping them, but record how many needed it.
miss <- is.na(ref_sz$subzone_c)
if (any(miss)) {
  nn <- st_nearest_feature(ref_sz[miss, ], subzones)
  ref_sz[miss, c("subzone_c", "subzone_n", "pln_area_n", "region_n", "ca_ind")] <-
    st_drop_geometry(subzones)[nn, c("subzone_c", "subzone_n", "pln_area_n", "region_n", "ca_ind")]
}
log_step("reference points outside land polygons, snapped to nearest: ", sum(miss))

saveRDS(subzones,  file.path(DIR_INT, "subzones.rds"))
saveRDS(ref_sz,    file.path(DIR_INT, "reference.rds"))
log_step("reference total: ", nrow(ref_sz), " facilities")
print(count(st_drop_geometry(ref_sz), ref_cat, ref_type))
