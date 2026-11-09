# 02_coverage/06_matcher_error.R ------------------------------------------------
# How wrong is the matcher? The 160-row validation sample (05) was checked
# against the OSM snapshot, the OSM API, Nominatim and the web; the verdicts are
# a hand-built lookup in data/external/coverage_validation_verdicts.csv because
# the sample file itself is rewritten on every run. From them:
#   false-match rate = incorrect among accepted matches
#   false-miss rate  = incorrect among rejected facilities (OSM had it after all)
# with "unsure" rows left out, and a recall corrected for both errors. The
# headline thresholds are not re-tuned on these results (threshold fishing).

source("R/00_setup.R")
library(binom)

samp     <- read_csv(file.path(DIR_TAB, "coverage_validation_sample.csv"), show_col_types = FALSE)
verdicts <- read_csv(file.path(DIR_EXT, "coverage_validation_verdicts.csv"), show_col_types = FALSE)
mt       <- readRDS(file.path(DIR_INT, "match_tested.rds"))

# A verdict applies only to the pair it was given for; a changed match is unchecked.
checked <- samp %>% select(set, stratum, ref_id, osm_id) %>%
  mutate(osm_id = coalesce(osm_id, "")) %>%
  left_join(verdicts %>% mutate(sample_osm_id = coalesce(sample_osm_id, "")),
            by = c("set", "stratum", "ref_id", "osm_id" = "sample_osm_id"))
n_unchecked <- sum(is.na(checked$verdict))
if (n_unchecked) log_step("WARNING: ", n_unchecked, " sample rows have no verdict for their current pair")

rate <- function(d) {
  d <- d %>% filter(verdict %in% c("correct", "incorrect"))
  ci <- binom.confint(sum(d$verdict == "incorrect"), nrow(d), methods = "wilson")
  tibble(n_checked = nrow(d), n_incorrect = sum(d$verdict == "incorrect"),
         rate = ci$mean, ci_lo = ci$lower, ci_hi = ci$upper)
}

err <- checked %>% filter(!is.na(verdict)) %>%
  group_by(set, stratum) %>%
  group_modify(~ rate(.x) %>% mutate(n_unsure = sum(.x$verdict == "unsure"))) %>%
  ungroup()

# Corrected recall: true finds among accepted + OSM features the matcher missed.
counts <- mt %>% group_by(set) %>% summarise(n_ref = n(), n_matched = sum(matched), .groups = "drop")
corrected <- counts %>%
  left_join(err %>% filter(stratum == "accepted match") %>% select(set, false_match = rate), by = "set") %>%
  left_join(err %>% filter(stratum != "accepted match") %>% select(set, false_miss = rate), by = "set") %>%
  mutate(recall_measured  = n_matched / n_ref,
         recall_corrected = (n_matched * (1 - false_match) + (n_ref - n_matched) * false_miss) / n_ref)

write_csv(err %>% mutate(across(c(rate, ci_lo, ci_hi), ~ round(.x, 3))), file.path(DIR_TAB, "coverage_matcher_error.csv"))
write_csv(corrected %>% mutate(across(where(is.double), ~ round(.x, 3))), file.path(DIR_TAB, "coverage_recall_corrected.csv"))
log_step("matcher error: ", paste0(err$set, " ", substr(err$stratum, 1, 8), " ", err$n_incorrect, "/", err$n_checked,
                                   collapse = "; "),
         ". Corrected recall: ", paste0(corrected$set, " ", round(100 * corrected$recall_measured, 1), "% -> ",
                                        round(100 * corrected$recall_corrected, 1), "%", collapse = "; "))
