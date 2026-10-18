# 02_coverage/04_ceiling_and_validation.R ---------------------------------------
# Two checks on the matcher, both aimed at the same question: is the low recall
# a property of OpenStreetMap, or of our matching procedure?
#
# (1) The proximity-only ceiling. Ignore names entirely and ask how many
#     reference facilities have ANY OSM feature of the right category nearby.
#     No name-based matcher can beat this. If measured recall sits close to the
#     ceiling, the matcher is not the binding constraint.
# (2) A stratified sample for manual verification, written out with blank
#     verdict columns. Someone has to open these and look.

source("R/00_setup.R")
library(binom)

reference <- readRDS(file.path(DIR_INT, "reference.rds"))
osm       <- readRDS(file.path(DIR_INT, "osm_poi.rds"))
mt        <- readRDS(file.path(DIR_INT, "match_tested.rds"))

SETS <- list(
  chas = list(ref_cat = "health",    osm_cat = "clinic",    label = "CHAS clinics"),
  ecda = list(ref_cat = "education", osm_cat = "preschool", label = "ECDA preschools")
)

# --- (1) ceiling -------------------------------------------------------------

ceiling_tab <- bind_rows(lapply(names(SETS), function(nm) {
  cfg <- SETS[[nm]]
  ref <- reference %>% filter(ref_cat == cfg$ref_cat)
  poi <- osm %>% filter(osm_cat == cfg$osm_cat)
  nn  <- st_nearest_feature(ref, poi)
  d   <- as.numeric(st_distance(ref, poi[nn, ], by_element = TRUE))
  bind_rows(lapply(c(25, 50, 100, 150), function(dd) {
    ci <- binom.confint(sum(d <= dd), length(d), methods = "wilson")
    tibble(set = cfg$label, d_m = dd,
           ceiling_n = sum(d <= dd), n_ref = length(d),
           ceiling = mean(d <= dd), lo = ci$lower, hi = ci$upper)
  }))
}))

achieved <- read_csv(file.path(DIR_TAB, "coverage_threshold_sensitivity.csv"), show_col_types = FALSE) %>%
  filter(variant == "strict", s_name == 0.80) %>%
  mutate(set = c(chas = "CHAS clinics", ecda = "ECDA preschools")[set]) %>%
  select(set, d_m, achieved = recall)

ceiling_tab <- ceiling_tab %>% left_join(achieved, by = c("set", "d_m")) %>%
  mutate(share_of_ceiling = achieved / ceiling)

write_csv(ceiling_tab, file.path(DIR_TAB, "coverage_matching_ceiling.csv"))
cat("\n=== proximity-only ceiling vs achieved recall (name threshold 0.80) ===\n")
print(ceiling_tab %>% mutate(across(c(ceiling, lo, hi, achieved, share_of_ceiling), ~round(.x, 3))) %>% as.data.frame())

# --- (2) validation sample ---------------------------------------------------
# 40 accepted matches and 40 rejected reference facilities per set. Whoever
# checks these fills in `verdict` (correct / incorrect / unsure) by looking the
# facility up; the false-match and false-miss rates then come straight off this
# file. Seed is fixed so the sample is reproducible.

set.seed(SEED)
N_EACH <- 40

samp <- bind_rows(lapply(names(SETS), function(nm) {
  d <- mt %>% filter(set == nm)
  bind_rows(
    d %>% filter(matched)  %>% slice_sample(n = min(N_EACH, sum(d$matched))) %>% mutate(stratum = "accepted match"),
    d %>% filter(!matched) %>% slice_sample(n = min(N_EACH, sum(!d$matched))) %>% mutate(stratum = "rejected (counted as missing)")
  )
})) %>%
  transmute(set, stratum, ref_id, ref_name, ref_post, pln_area_n,
            osm_id = coalesce(osm_id, ""), osm_name = coalesce(osm_name, ""),
            dist_m = round(dist_m, 1), name_sim = round(name_sim, 3),
            rule = coalesce(rule, ""),
            verdict = "", checked_by = "", note = "")

write_csv(samp, file.path(DIR_TAB, "coverage_validation_sample.csv"))
log_step("validation sample written: ", nrow(samp), " rows, ",
         sum(samp$stratum == "accepted match"), " accepted / ",
         sum(samp$stratum != "accepted match"), " rejected")
cat("\nFill in the `verdict` column (correct / incorrect / unsure) by hand, then\n",
    "false-match rate = incorrect among 'accepted match';\n",
    "false-miss rate  = incorrect among 'rejected'.\n", sep = "")
