# 00_setup.R ------------------------------------------------------------------
# Shared paths, constants and helpers. Sourced by every numbered script.
# Singapore only: the optional Hong Kong extension (team plan P4) was dropped.

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

# The six score categories, in the order every table uses. Tags map to them in
# data/external/osm_crosswalk.csv.
CATEGORIES <- c("food_services", "retail", "health", "food_retail", "education", "recreation")

# Agreed P0 decisions (docs/consideration.md §3); change here, not in the scripts.
RES_MIN_POP <- 1000          # item 2: residents needed for a subzone to count as residential
RES_MIN_POP_ALT <- 500       # item 2: second cut-off, reported so the choice is visible
RADIUS_M    <- 1000          # item 7: walking radius for the main score ...
RADII_ALT   <- c(800, 1200)  # ... and the robustness variants
DENSITY_SHARE_MAX <- 0.5     # item 1: above this share of R2, Q3 clusters on density-adjusted scores
LISA_NSIM   <- 9999          # item 8: at 999 the smallest two-sided p is 0.002, too coarse for BH over ~200 tests
FDR_Q       <- 0.05          # item 8: Benjamini-Hochberg false discovery rate for LISA
N_PERM_BLOCK <- 999          # items 5 and 12: block permutations for Q3's H0(b) and H0(a)

# Significance level for every test (each script says whether one- or two-sided).
ALPHA <- 0.05

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

# --- shared figure theme (B3) ------------------------------------------------
# One look for every stage's figures. Called through ggplot2:: so scripts that
# draw nothing do not need ggplot2 loaded.

PAL_SEQ   <- c("#cde2fb", "#9ec5f4", "#6da7ec", "#3987e5", "#1c5cab", "#0d366b")  # magnitude
PAL_DIV   <- c(low = "#2a78d6", mid = "#f2f1ee", high = "#c2410c")                 # below / above
PAL_CAT   <- c("#1c5cab", "#c2410c", "#2f855a", "#805ad5", "#b7791f", "#319795", "#d53f8c")
GREY_NA   <- "#d9d8d4"   # no data / outside the analysis, never a data value
INK       <- "#0b0b0b"; INK2 <- "#52514e"

theme_project <- function(base_size = 9) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                   panel.grid.major = ggplot2::element_line(linewidth = 0.25, colour = "#e8e7e3"),
                   axis.text  = ggplot2::element_text(colour = INK2),
                   axis.title = ggplot2::element_text(colour = INK2),
                   plot.title = ggplot2::element_text(colour = INK, face = "bold", size = base_size + 1),
                   plot.subtitle = ggplot2::element_text(colour = INK2, size = base_size - 0.5),
                   plot.caption  = ggplot2::element_text(colour = INK2, size = base_size - 2, hjust = 0),
                   strip.text = ggplot2::element_text(colour = INK, face = "bold"),
                   legend.title = ggplot2::element_text(colour = INK2, size = base_size - 1))
}

theme_map <- function(base_size = 9) {
  theme_project(base_size) +
    ggplot2::theme(panel.grid.major = ggplot2::element_blank(),
                   axis.text = ggplot2::element_blank(), axis.title = ggplot2::element_blank())
}

save_fig <- function(plot, name, width = 7.8, height = 4.6) {
  ggplot2::ggsave(file.path(DIR_FIG, name), plot, width = width, height = height, dpi = 300, bg = "white")
}
