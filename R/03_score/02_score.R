# 03_score/02_score.R -----------------------------------------------------------
# The access score (A5, with the A8 radius variants). For each subzone centre,
# count scored OSM facilities within the walk radius per category, put the six
# counts on one scale, and combine them with HES 2023 spending weights.
#
#   category score = 100 * log1p(n) / max(log1p(n)) over the residential set
#   score          = sum of HES weight x category score         (0-100)
#   score_equal    = mean of the six category scores            (robustness)
#   variety        = distinct OSM tag values within the radius  (counted apart)
#
# The scale comes from residential subzones only (decision 11), so an empty
# airport or a CBD block does not set it. Non-residential subzones are scored
# too, can exceed 100, and are outside every analysis.

source("R/00_setup.R")

subzones <- readRDS(file.path(DIR_INT, "subzones.rds"))
osm      <- readRDS(file.path(DIR_INT, "osm_poi.rds")) %>% filter(scored)
centres  <- readRDS(file.path(DIR_PROC, "score_centres.rds"))
census   <- read_csv(file.path(DIR_PROC, "census2020_subzone.csv"), show_col_types = FALSE)
weights  <- read_csv(file.path(DIR_PROC, "hes_weights.csv"), show_col_types = FALSE)

W <- setNames(weights$weight, weights$category)
stopifnot(setequal(names(W), CATEGORIES), abs(sum(W) - 1) < 1e-9)
write_csv(weights %>% mutate(weight = round(weight, 4)), file.path(DIR_TAB, "score_weights.csv"))

# --- residential set ---------------------------------------------------------
# C1 publishes the agreed set as H2. Until it exists, apply the proposed cut-off.

h2 <- file.path(DIR_PROC, "residential_set.csv")
if (file.exists(h2)) {
  res <- read_csv(h2, show_col_types = FALSE) %>% select(subzone_c, residential)
  log_step("residential set: from ", basename(h2))
} else {
  res <- census %>% transmute(subzone_c, residential = pop >= RES_MIN_POP)
  log_step("residential set: provisional, pop >= ", RES_MIN_POP, " (no residential_set.csv yet)")
}

sz <- centres %>%
  left_join(census %>% select(subzone_c, pop), by = "subzone_c") %>%
  left_join(res, by = "subzone_c")
stopifnot(nrow(sz) == nrow(subzones), !anyNA(sz$residential))

# --- counts ------------------------------------------------------------------

# Subzones x categories matrix of facilities within r metres of each centre.
count_within <- function(centres, poi, r) {
  out <- sapply(CATEGORIES, function(k) lengths(st_is_within_distance(centres, poi[poi$category == k, ], dist = r)))
  colnames(out) <- CATEGORIES
  out
}

normalise <- function(n, residential) {
  apply(n, 2, function(v) 100 * log1p(v) / max(log1p(v[residential])))
}

composite <- function(s, w) as.numeric(s[, CATEGORIES] %*% w[CATEGORIES])

n_main <- count_within(sz, osm, RADIUS_M)
s_main <- normalise(n_main, sz$residential)

alt <- lapply(RADII_ALT, function(r) composite(normalise(count_within(sz, osm, r), sz$residential), W))
names(alt) <- paste0("score_r", RADII_ALT)

nb <- st_is_within_distance(sz, osm, dist = RADIUS_M)
variety <- vapply(nb, function(i) n_distinct(osm$tag[i]), integer(1))

score <- sz %>%
  st_drop_geometry() %>%
  select(subzone_c, pop, residential, centre_method) %>%
  bind_cols(as_tibble(n_main) %>% rename_with(~ paste0("n_", .x))) %>%
  bind_cols(as_tibble(s_main) %>% rename_with(~ paste0("score_", .x))) %>%
  mutate(score       = composite(s_main, W),
         score_equal = rowMeans(s_main),
         variety     = variety) %>%
  bind_cols(as_tibble(alt))

score <- subzones %>% select(subzone_c) %>%
  inner_join(score, by = "subzone_c") %>%
  select(subzone_c, pop, residential, centre_method,
         starts_with("n_"), paste0("score_", CATEGORIES),
         score, score_equal, variety, all_of(names(alt)))

stopifnot(nrow(score) == nrow(subzones), !anyNA(st_drop_geometry(score)))
saveRDS(score, file.path(DIR_PROC, "score_subzone.rds"))
log_step("score_subzone.rds: ", nrow(score), " subzones, ", sum(score$residential), " residential")

# --- tables ------------------------------------------------------------------

rs <- st_drop_geometry(score) %>% filter(residential)

# A3 sanity check: what each category is built from.
write_csv(st_drop_geometry(osm) %>% count(category, osm_cat, name = "n_features") %>%
            arrange(match(category, CATEGORIES), desc(n_features)),
          file.path(DIR_TAB, "score_poi_counts.csv"))

summ <- bind_rows(lapply(CATEGORIES, function(k) tibble(
  category = k,
  weight = round(W[[k]], 3),
  osm_features = sum(osm$category == k),
  median_count = median(rs[[paste0("n_", k)]]),
  share_zero = round(mean(rs[[paste0("n_", k)]] == 0), 3),
  median_score = round(median(rs[[paste0("score_", k)]]), 1),
  sd_score = round(sd(rs[[paste0("score_", k)]]), 1)
)))
write_csv(summ, file.path(DIR_TAB, "score_category_summary.csv"))
cat("\n=== categories over the", nrow(rs), "residential subzones ===\n"); print(as.data.frame(summ))

# A8: how much do the robustness variants reorder subzones?
rob <- tibble(
  variant = c("equal weights", paste0(RADII_ALT, " m radius")),
  column  = c("score_equal", names(alt)),
  spearman = vapply(c("score_equal", names(alt)), function(v) cor(rs$score, rs[[v]], method = "spearman"), numeric(1)),
  max_rank_shift = vapply(c("score_equal", names(alt)), function(v)
    as.integer(max(abs(rank(-rs$score) - rank(-rs[[v]])))), integer(1))
)
write_csv(rob %>% mutate(spearman = round(spearman, 3)), file.path(DIR_TAB, "score_robustness.csv"))
cat("\n=== robustness: rank agreement with the main score (residential set) ===\n"); print(as.data.frame(rob))

# Correlation between categories: Q3 clusters on these, so it should see this.
cc <- round(cor(rs[, paste0("score_", CATEGORIES)], method = "spearman"), 2)
write_csv(as_tibble(cc, rownames = "category"), file.path(DIR_TAB, "score_category_correlation.csv"))
