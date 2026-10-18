# 00_setup.R ------------------------------------------------------------------
# Shared paths, constants and helpers. Sourced by every numbered script.
# Singapore only for now; the Hong Kong extension will add its own DIR_RAW_HK.

suppressPackageStartupMessages({
  library(sf)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(readr)
  library(jsonlite)
})

# Paths are relative to the project root, so scripts must be run from there.
ROOT      <- normalizePath(".", winslash = "/")
DIR_RAW   <- file.path(ROOT, "data", "raw", "sg")
DIR_INT   <- file.path(ROOT, "data", "interim")
DIR_PROC  <- file.path(ROOT, "data", "processed")
DIR_EXT   <- file.path(ROOT, "data", "external")
DIR_FIG   <- file.path(ROOT, "outputs", "figures")
DIR_TAB   <- file.path(ROOT, "outputs", "tables")
for (d in c(DIR_INT, DIR_PROC, DIR_EXT, DIR_FIG, DIR_TAB)) dir.create(d, showWarnings = FALSE, recursive = TRUE)

CRS_SVY21 <- 3414   # SVY21 / Singapore TM, metres
CRS_WGS84 <- 4326

SEED <- 4220
set.seed(SEED)

# --- helpers -----------------------------------------------------------------

# data.gov.sg ships its KML-derived GeoJSONs with every attribute glued into one
# HTML table in a `Description` column. Pull it back out into real columns.
parse_kml_description <- function(x) {
  rows <- str_match_all(x, "<th>\\s*([^<]*?)\\s*</th>\\s*<td>\\s*([^<]*?)\\s*</td>")
  keys <- lapply(rows, function(m) if (nrow(m)) m[, 2] else character(0))
  vals <- lapply(rows, function(m) if (nrow(m)) m[, 3] else character(0))
  all_keys <- unique(unlist(keys))
  all_keys <- setdiff(all_keys, "Attributes")
  out <- lapply(all_keys, function(k) {
    vapply(seq_along(keys), function(i) {
      j <- match(k, keys[[i]])
      if (is.na(j)) NA_character_ else vals[[i]][j]
    }, character(1))
  })
  names(out) <- all_keys
  as_tibble(out)
}

# Normalise a facility name so that two spellings of the same place compare
# equal. Kept deliberately conservative: anything that could distinguish two
# genuinely different facilities (numbers, block references) is retained.
normalise_name <- function(x) {
  x %>%
    str_to_lower() %>%
    str_replace_all("&", " and ") %>%
    str_replace_all("[^a-z0-9]+", " ") %>%
    str_replace_all("\\b(pte|ltd|llp|inc|co|company|private|limited)\\b", " ") %>%
    str_replace_all("\\bs pore\\b|\\bsingapore\\b", " ") %>%
    str_replace_all("\\bctr\\b", " centre ") %>%
    str_replace_all("\\bcntr\\b", " centre ") %>%
    str_replace_all("\\bcenter\\b", " centre ") %>%
    str_replace_all("\\bmed\\b", " medical ") %>%
    str_replace_all("\\bsurg\\b", " surgery ") %>%
    str_replace_all("\\bdr\\b", " doctor ") %>%
    str_replace_all("\\bfmly\\b", " family ") %>%
    str_replace_all("\\bpreschool\\b", " pre school ") %>%
    str_replace_all("\\bkindergarden\\b", " kindergarten ") %>%
    str_squish()
}

# Jaccard overlap of word sets: catches reordered names ("Acumed Medical Bedok"
# vs "Bedok Acumed Medical") that edit distance handles badly.
token_set_sim <- function(a, b) {
  ta <- str_split(a, " "); tb <- str_split(b, " ")
  vapply(seq_along(ta), function(i) {
    x <- setdiff(ta[[i]], ""); y <- setdiff(tb[[i]], "")
    if (!length(x) || !length(y)) return(0)
    length(intersect(x, y)) / length(union(x, y))
  }, numeric(1))
}

log_step <- function(...) cat(format(Sys.time(), "[%H:%M:%S] "), ..., "\n", sep = "")
