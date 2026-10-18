# 02_coverage/01_match.R --------------------------------------------------------
# Record linkage between the authoritative reference lists and OSM.
#
# This is not a spatial join. Distance alone fails inside multi-tenant buildings
# (one medical centre can hold six clinics at one address point); name alone
# fails for chains (dozens of "PCF Sparkletots"). A pair must satisfy both, or
# agree on postal code, or -- for an OSM feature with no name at all -- be very
# close. Assignment is forced one-to-one so two reference facilities cannot
# claim the same OSM node.

source("R/00_setup.R")
library(stringdist)
library(clue)
library(binom)

reference <- readRDS(file.path(DIR_INT, "reference.rds"))
osm       <- readRDS(file.path(DIR_INT, "osm_poi.rds"))

reference$name_norm <- normalise_name(reference$ref_name)

# Which OSM categories are legitimate counterparts for each reference list.
# `strict` is the headline definition; `wide` is the sensitivity variant that
# allows the categories preschools and clinics are commonly mis-tagged as.
MATCH_SETS <- list(
  chas = list(ref_cat = "health",    strict = "clinic",    wide = c("clinic", "hospital", "pharmacy")),
  ecda = list(ref_cat = "education", strict = "preschool", wide = c("preschool", "school", "other_education"))
)

D_MAX  <- 150          # widest distance ever considered; candidates built once
D_GRID <- c(25, 50, 100, 150)
S_GRID <- c(0.70, 0.80, 0.90)
D_HEAD <- 50           # headline cell, fixed before looking at any recall number
S_HEAD <- 0.80
D_NONAME <- 30         # an unnamed OSM feature this close is taken as the same place

# --- candidate generation ----------------------------------------------------

build_candidates <- function(ref, poi) {
  if (nrow(ref) == 0 || nrow(poi) == 0) return(tibble())
  nb <- st_is_within_distance(ref, poi, dist = D_MAX)
  i <- rep(seq_along(nb), lengths(nb))
  j <- unlist(nb)
  if (!length(i)) return(tibble())
  d <- as.numeric(st_distance(ref[i, ], poi[j, ], by_element = TRUE))
  rn <- ref$name_norm[i]; on <- poi$name_norm[j]
  jw  <- 1 - stringdist(rn, on, method = "jw", p = 0.1)
  jw[is.na(jw)] <- 0
  ts  <- token_set_sim(ifelse(is.na(rn), "", rn), ifelse(is.na(on), "", on))
  sim <- pmax(jw, ts)
  sim[is.na(poi$name_norm[j]) | poi$name_norm[j] == ""] <- 0
  tibble(i = i, j = j, dist = d, sim = sim,
         post_eq = !is.na(ref$ref_post[i]) & !is.na(poi$postcode[j]) &
                   ref$ref_post[i] == poi$postcode[j],
         osm_unnamed = is.na(poi$name_norm[j]) | poi$name_norm[j] == "")
}

# --- one-to-one assignment ---------------------------------------------------
# Optimal, not greedy: clue::solve_LSAP on the eligible pairs only. The matrix is
# cut down to reference rows and OSM columns that have at least one eligible
# pair, which is what keeps the Hungarian solve cheap.

assign_one_to_one <- function(cand, n_ref, n_poi, d, s) {
  el <- cand %>%
    filter(dist <= d, sim >= s | post_eq | (osm_unnamed & dist <= D_NONAME)) %>%
    mutate(score = sim + 0.05 * post_eq - dist / 1e5)
  if (nrow(el) == 0) return(tibble(i = integer(), j = integer(), dist = numeric(),
                                   sim = numeric(), rule = character()))
  ri <- sort(unique(el$i)); ci <- sort(unique(el$j))
  # Costs must be non-negative for solve_LSAP; `score` can exceed 1 because of
  # the postcode bonus, so shift rather than using 1 - score.
  M <- matrix(1e3, nrow = length(ri), ncol = length(ci))
  M[cbind(match(el$i, ri), match(el$j, ci))] <- 2 - el$score
  transposed <- nrow(M) > ncol(M)
  if (transposed) M <- t(M)
  sol <- as.integer(solve_LSAP(M))
  pairs <- if (transposed) tibble(rr = sol, cc = seq_along(sol))
           else            tibble(rr = seq_along(sol), cc = sol)
  pairs <- pairs %>% mutate(i = ri[rr], j = ci[cc]) %>% select(i, j) %>%
    inner_join(el, by = c("i", "j")) %>%           # drops filler assignments
    mutate(rule = case_when(sim >= s           ~ "name",
                            post_eq            ~ "postcode",
                            TRUE               ~ "proximity_unnamed")) %>%
    select(i, j, dist, sim, rule)
  pairs
}

# --- run ---------------------------------------------------------------------

results <- list(); grids <- list(); matched_head <- list()

for (nm in names(MATCH_SETS)) {
  cfg <- MATCH_SETS[[nm]]
  ref <- reference %>% filter(ref_cat == cfg$ref_cat)

  for (variant in c("strict", "wide")) {
    poi <- osm %>% filter(osm_cat %in% cfg[[variant]])
    cand <- build_candidates(ref, poi)
    log_step(nm, "/", variant, ": ", nrow(ref), " reference x ", nrow(poi),
             " OSM -> ", nrow(cand), " candidate pairs within ", D_MAX, " m")

    for (d in D_GRID) for (s in S_GRID) {
      m <- assign_one_to_one(cand, nrow(ref), nrow(poi), d, s)
      ci <- binom.confint(nrow(m), nrow(ref), methods = "wilson")
      grids[[length(grids) + 1]] <- tibble(
        set = nm, variant = variant, d_m = d, s_name = s,
        n_ref = nrow(ref), n_osm = nrow(poi), n_matched = nrow(m),
        recall = nrow(m) / nrow(ref), lo = ci$lower, hi = ci$upper,
        via_name = sum(m$rule == "name"),
        via_postcode = sum(m$rule == "postcode"),
        via_proximity = sum(m$rule == "proximity_unnamed"))
      if (d == D_HEAD && s == S_HEAD) {
        out <- ref %>% st_drop_geometry() %>%
          mutate(row = row_number()) %>%
          left_join(m %>% rename(row = i), by = "row") %>%
          mutate(matched = !is.na(j),
                 osm_id  = ifelse(matched, poi$osm_id[j], NA_character_),
                 osm_name = ifelse(matched, poi$osm_name[j], NA_character_),
                 set = nm, variant = variant) %>%
          select(set, variant, ref_id, ref_name, ref_post, ref_type,
                 subzone_c, subzone_n, pln_area_n, matched, osm_id, osm_name,
                 dist_m = dist, name_sim = sim, rule)
        matched_head[[paste(nm, variant)]] <- out
      }
    }
  }
}

grid <- bind_rows(grids)
write_csv(grid, file.path(DIR_TAB, "coverage_threshold_sensitivity.csv"))

match_table <- bind_rows(matched_head)
write_csv(match_table, file.path(DIR_INT, "match_table.csv"))
saveRDS(match_table, file.path(DIR_INT, "match_table.rds"))

cat("\n--- recall grid (strict) ---\n")
print(grid %>% filter(variant == "strict") %>%
        select(set, d_m, s_name, n_matched, recall, lo, hi) %>%
        mutate(across(c(recall, lo, hi), ~round(.x, 3))), n = 40)

cat("\n--- headline cell, d =", D_HEAD, "m, s =", S_HEAD, "---\n")
print(grid %>% filter(d_m == D_HEAD, s_name == S_HEAD) %>%
        mutate(recall = round(recall, 3), lo = round(lo, 3), hi = round(hi, 3)) %>%
        select(set, variant, n_ref, n_osm, n_matched, recall, lo, hi,
               via_name, via_postcode, via_proximity))
