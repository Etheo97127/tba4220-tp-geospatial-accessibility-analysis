# 01_prep/04_buildings.R --------------------------------------------------------
# Residential building footprints from the OSM snapshot, with a floor-area weight
# for the population-weighted centres (A4, docs/consideration.md §3 item 3).
#
# Weight = footprint area x storeys. Storeys come from `building:levels`; where it
# is missing they are imputed as the median for the same kind of building in the
# same planning area (island-wide median if the planning area has none), so an
# untagged HDB slab in Punggol is not given the height of a terrace house.

source("R/00_setup.R")

HOUSE_TYPES <- c("house", "detached", "semidetached_house", "terrace", "bungalow")
# Dormitories are pulled but not weighted: most house migrant workers, whom the
# Census 2020 resident count (citizens + PRs) leaves out, so their floor area would
# pull a centre away from the residents the score describes (23% of the weight in
# Woodlands WDSZ09 before this exclusion).
NON_RESIDENT_TYPES <- c("dormitory")

# Pulled in six tiles (TILES in 00_fetch_osm.R); a way crossing a tile edge
# appears in two of them.
tiles <- list.files(file.path(DIR_RAW, "osm"), pattern = "^osm_residential_buildings_.*\\.json$",
                    full.names = TRUE)
stopifnot(length(tiles) == 6)
els <- unlist(lapply(tiles, function(f) fromJSON(f, simplifyVector = FALSE)$elements), recursive = FALSE)
els <- els[!duplicated(vapply(els, function(e) paste(e$type, e$id), character(1)))]
els <- Filter(function(e) e$type == "way" && length(e$geometry) >= 4, els)

`%||%` <- function(a, b) if (is.null(a)) b else a
ring <- function(g) {
  m <- cbind(vapply(g, function(p) p$lon %||% NA_real_, numeric(1)),
             vapply(g, function(p) p$lat %||% NA_real_, numeric(1)))
  m <- m[complete.cases(m), , drop = FALSE]
  if (nrow(m) < 3) return(NULL)
  if (any(m[1, ] != m[nrow(m), ])) m <- rbind(m, m[1, ])   # close the ring
  if (nrow(m) < 4) return(NULL)
  st_polygon(list(m))
}
polys <- lapply(els, function(e) ring(e$geometry))
keep  <- !vapply(polys, is.null, logical(1))
log_step("residential building ways: ", length(els), ", usable rings: ", sum(keep))

bld <- st_sf(
  osm_id   = paste0("w", vapply(els[keep], function(e) as.character(e$id), character(1))),
  building = vapply(els[keep], function(e) e$tags$building %||% NA_character_, character(1)),
  levels_raw = vapply(els[keep], function(e) e$tags[["building:levels"]] %||% NA_character_, character(1)),
  geometry = st_sfc(polys[keep], crs = CRS_WGS84)
) %>%
  st_transform(CRS_SVY21) %>%
  st_make_valid()

bld <- bld %>%
  mutate(area_m2 = as.numeric(st_area(geometry)),
         # "12", "12;14", "5.5" -> first number
         levels  = suppressWarnings(as.numeric(str_extract(levels_raw, "\\d+(\\.\\d+)?"))),
         levels  = if_else(levels > 0 & levels <= 80, levels, NA_real_),
         kind    = if_else(building %in% HOUSE_TYPES, "house", "block")) %>%
  filter(area_m2 >= 20,                    # sheds, kiosks and digitising slivers
         !building %in% NON_RESIDENT_TYPES)

# Attach planning area / subzone by a point guaranteed to be inside the footprint.
subzones <- readRDS(file.path(DIR_INT, "subzones.rds"))
pts <- st_point_on_surface(st_geometry(bld))
idx <- st_within(pts, subzones)
bld$subzone_c  <- subzones$subzone_c[vapply(idx, function(i) if (length(i)) i[1] else NA_integer_, integer(1))]
bld$pln_area_n <- subzones$pln_area_n[match(bld$subzone_c, subzones$subzone_c)]
bld <- bld %>% filter(!is.na(subzone_c))

med_pa  <- bld %>% st_drop_geometry() %>% group_by(pln_area_n, kind) %>%
  summarise(med_pa = median(levels, na.rm = TRUE), .groups = "drop")
med_all <- bld %>% st_drop_geometry() %>% group_by(kind) %>%
  summarise(med_all = median(levels, na.rm = TRUE), .groups = "drop")

bld <- bld %>%
  left_join(med_pa, by = c("pln_area_n", "kind")) %>%
  left_join(med_all, by = "kind") %>%
  mutate(levels_imputed = is.na(levels),
         levels = coalesce(levels, med_pa, med_all),
         weight = area_m2 * levels) %>%
  select(osm_id, building, kind, area_m2, levels, levels_imputed, weight, subzone_c, pln_area_n)

saveRDS(bld, file.path(DIR_INT, "res_buildings.rds"))
log_step("residential buildings kept: ", nrow(bld), " in ", n_distinct(bld$subzone_c), " subzones; ",
         round(100 * mean(bld$levels_imputed), 1), "% with imputed storeys")
print(bld %>% st_drop_geometry() %>% group_by(kind) %>%
        summarise(n = n(), tagged_levels = sum(!levels_imputed),
                  median_levels = median(levels), .groups = "drop") %>% as.data.frame())
