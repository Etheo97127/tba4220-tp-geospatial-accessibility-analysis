# 01_prep/00_fetch_osm.R --------------------------------------------------------
# Pull one OpenStreetMap snapshot from Overpass into data/input/raw/sg/osm/. Not part
# of run_all.R: the snapshot is committed so every track works on the same data.
#
# The POI queries are generated from data/input/external/osm_crosswalk.csv, so the
# crosswalk is the single definition of what each category contains. One file
# per category. `out center meta` gives ways and relations a centre point and
# carries the mapper's user id, which Q2 needs for OSM contributor density.
# The residential-building query feeds the population-weighted centres (A4) and
# keeps full geometry, because footprint area is part of the weight.
#
#   Rscript R/01_prep/00_fetch_osm.R

source("R/00_setup.R")

DIR_OSM  <- file.path(DIR_RAW, "osm")
dir.create(DIR_OSM, showWarnings = FALSE)
OVERPASS <- "https://overpass-api.de/api/interpreter"
AREA_SG  <- 3600536780      # Singapore, OSM relation 536780
# overpass-api.de answers 406 to clients without a descriptive User-Agent, and
# refuses large queries sent as GET, so each query is POSTed from its saved
# .overpassql file with the system curl (bundled with Windows 10+, macOS, Linux).
UA <- "tba4220-geospatial-accessibility/0.1 (NUS course project)"
QUOTE <- if (.Platform$OS.type == "windows") "cmd" else "sh"

# The building types counted as homes. Commercial blocks with flats above
# (HDB "shophouse" blocks) are usually tagged apartments or residential too.
RES_BUILDINGS <- c("apartments", "residential", "house", "detached",
                   "semidetached_house", "terrace", "bungalow", "dormitory")

crosswalk <- read_csv(file.path(DIR_EXT, "osm_crosswalk.csv"), show_col_types = FALSE)

poi_query <- function(rows) {
  sel <- rows %>% group_by(key) %>%
    summarise(re = paste0("^(", paste(sort(unique(value)), collapse = "|"), ")$"), .groups = "drop")
  paste0("[out:json][timeout:600];\n",
         "area(id:", AREA_SG, ")->.sg;\n(\n",
         paste0('  nwr["', sel$key, '"~"', sel$re, '"](area.sg);', collapse = "\n"),
         "\n);\nout center meta;")
}

# ~46,000 footprints with full geometry is more than the public server will
# stream in one response, so the island is pulled in tiles (south, west, north,
# east); the denser north is cut in two again, because quarter-island responses
# there kept being dropped mid-transfer. A way crossing a tile edge comes back
# twice; 04_buildings.R drops the duplicate by id.
TILES <- list(sw  = c(1.15, 103.55, 1.35, 103.85),  se  = c(1.15, 103.85, 1.35, 104.10),
              nw1 = c(1.35, 103.55, 1.48, 103.70),  nw2 = c(1.35, 103.70, 1.48, 103.85),
              ne1 = c(1.35, 103.85, 1.48, 103.975), ne2 = c(1.35, 103.975, 1.48, 104.10))

building_query <- function(bb) paste0(
  "[out:json][timeout:600];\n",
  "area(id:", AREA_SG, ")->.sg;\n",
  'way["building"~"^(', paste(RES_BUILDINGS, collapse = "|"), ')$"](area.sg)(',
  paste(bb, collapse = ","), ");\n",
  "out tags geom qt;")

run_overpass <- function(query, dest) {
  if (file.exists(dest)) { log_step(basename(dest), ": exists, skipped"); return(invisible(FALSE)) }
  qfile <- sub("\\.json$", ".overpassql", dest)
  writeLines(query, qfile)                                  # the exact query, kept beside its result
  args <- c("-s", "-f", "-m", "1200", "-A", shQuote(UA, QUOTE),
            "--data-urlencode", shQuote(paste0("data@", qfile), QUOTE),
            "-o", shQuote(dest, QUOTE), OVERPASS)
  for (k in 1:5) {
    status <- system2("curl", args)
    ok <- status == 0 && file.exists(dest) && file.size(dest) > 0
    if (ok) break
    log_step("  retry ", k, ": curl exit status ", status)
    if (file.exists(dest)) file.remove(dest)
    Sys.sleep(60 * k)        # 502/504 here means the server is busy, not that the query is wrong
  }
  if (!ok) stop("Overpass failed for ", basename(dest))
  j <- fromJSON(dest, simplifyVector = FALSE)
  if (!is.null(j$remark)) stop("Overpass remark (likely a timeout): ", j$remark)
  log_step(basename(dest), ": ", length(j$elements), " elements, ", file.size(dest), " B, md5 ",
           tools::md5sum(dest), ", OSM base ", j$osm3s$timestamp_osm_base)
  Sys.sleep(10)
  invisible(TRUE)
}

for (cat in unique(crosswalk$category)) {
  run_overpass(poi_query(filter(crosswalk, category == cat)),
               file.path(DIR_OSM, paste0("osm_", cat, ".json")))
}
for (t in names(TILES)) {
  run_overpass(building_query(TILES[[t]]),
               file.path(DIR_OSM, paste0("osm_residential_buildings_", t, ".json")))
}
