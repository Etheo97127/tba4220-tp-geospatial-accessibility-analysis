# 02_coverage/06_matcher_error.R ------------------------------------------------
# How wrong is the matcher? The 160-row validation sample (05) was checked
# against the OSM snapshot, the OSM API, Nominatim and the web; the verdicts sit
# in data/external/coverage_validation_verdicts.csv because the sample file
# itself is rewritten on every run. From them:
#   false-match rate = incorrect among accepted matches
#   false-miss rate  = rejected facilities the POI layer held after all (past the
#                      distance gate, or under another name)
# A rejected facility mapped only under a tag the crosswalk does not read (e.g.
# building=kindergarten) is outside the POI layer, so no matcher could find it: it
# is a tagging gap, counted apart. "Unsure" rows are left out. The headline
# thresholds are not re-tuned on these results (threshold fishing).

source("R/00_setup.R")
library(binom)

samp     <- read_csv(file.path(DIR_TAB, "coverage_validation_sample.csv"), show_col_types = FALSE)
verdicts <- read_csv(file.path(DIR_EXT, "coverage_validation_verdicts.csv"), show_col_types = FALSE)
mt       <- readRDS(file.path(DIR_INT, "match_tested.rds"))

MATCHER_MISS <- c("in_osm_far", "in_osm_other_name")   # in the POI layer: the matcher's error
TAG_GAP      <- "in_osm_other_tag"                      # in OSM, but outside the POI layer

# A verdict applies only to the pair it was given for; a changed match is unchecked.
checked <- samp %>% select(set, stratum, ref_id, osm_id) %>%
  mutate(osm_id = coalesce(osm_id, "")) %>%
  left_join(verdicts %>% mutate(sample_osm_id = coalesce(sample_osm_id, "")),
            by = c("set", "stratum", "ref_id", "osm_id" = "sample_osm_id"))
n_unchecked <- sum(is.na(checked$verdict))
if (n_unchecked) log_step("WARNING: ", n_unchecked, " sample rows have no verdict for their current pair")

error_rate <- function(d, stratum) {
  d <- d %>% filter(verdict %in% c("correct", "incorrect"))
  wrong <- d$verdict == "incorrect"
  error <- if (stratum == "accepted match") wrong else wrong & d$reason %in% MATCHER_MISS
  ci <- binom.confint(sum(error), nrow(d), methods = "wilson")
  tibble(n_checked = nrow(d), n_error = sum(error), rate = ci$mean, ci_lo = ci$lower, ci_hi = ci$upper,
         n_tag_gap = sum(wrong & d$reason %in% TAG_GAP))
}

err <- checked %>% filter(!is.na(verdict)) %>%
  group_by(set, stratum) %>%
  group_modify(~ error_rate(.x, .y$stratum) %>% mutate(n_unsure = sum(.x$verdict == "unsure"))) %>%
  ungroup()

# Corrected recall: true finds among accepted matches plus rejected facilities the
# matcher missed. Its range puts both error rates at their Wilson bounds at once,
# so it is wider than a 95% interval. recall_any_tag adds the tagging gaps: the
# share in OSM under any tag, including ones the score cannot see.
counts <- mt %>% group_by(set) %>% summarise(n_ref = n(), n_matched = sum(matched), .groups = "drop")
fm <- err %>% filter(stratum == "accepted match") %>% select(set, fm = rate, fm_lo = ci_lo, fm_hi = ci_hi)
fx <- err %>% filter(stratum != "accepted match") %>%
  transmute(set, fx = rate, fx_lo = ci_lo, fx_hi = ci_hi, tag_gap = n_tag_gap / n_checked)
corrected <- counts %>% left_join(fm, by = "set") %>% left_join(fx, by = "set") %>%
  mutate(n_missed            = n_ref - n_matched,
         recall_measured     = n_matched / n_ref,
         recall_corrected    = (n_matched * (1 - fm)    + n_missed * fx)    / n_ref,
         recall_corrected_lo = (n_matched * (1 - fm_hi) + n_missed * fx_lo) / n_ref,
         recall_corrected_hi = (n_matched * (1 - fm_lo) + n_missed * fx_hi) / n_ref,
         recall_any_tag      = recall_corrected + n_missed * tag_gap / n_ref) %>%
  select(set, n_ref, n_matched, false_match = fm, false_miss = fx, tag_gap, starts_with("recall"))

write_csv(err %>% mutate(across(c(rate, ci_lo, ci_hi), ~ round(.x, 3))), file.path(DIR_TAB, "coverage_matcher_error.csv"))
write_csv(corrected %>% mutate(across(where(is.double), ~ round(.x, 3))), file.path(DIR_TAB, "coverage_recall_corrected.csv"))
log_step("matcher error: ", paste0(err$set, " ", substr(err$stratum, 1, 8), " ", err$n_error, "/", err$n_checked,
                                   collapse = "; "),
         ". Corrected recall: ", paste0(corrected$set, " ", round(100 * corrected$recall_measured, 1), "% -> ",
                                        round(100 * corrected$recall_corrected, 1), "% (",
                                        round(100 * corrected$recall_corrected_lo, 1), "-",
                                        round(100 * corrected$recall_corrected_hi, 1), "%)", collapse = "; "))
