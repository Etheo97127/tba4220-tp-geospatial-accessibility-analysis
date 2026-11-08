# 02_coverage/03_quality_flag.R -------------------------------------------------
# Per-subzone OSM data-quality flag: the hand-off to the score and Q1-Q3.
# Built from ECDA only: CHAS lists only scheme-participating clinics, so a CHAS
# miss says less about how well a subzone is mapped.

source("R/00_setup.R")

mt       <- readRDS(file.path(DIR_INT, "match_tested.rds"))
subzones <- readRDS(file.path(DIR_INT, "subzones.rds"))
maturity <- read_csv(file.path(DIR_EXT, "town_maturity.csv"), show_col_types = FALSE)

# --- subzone quality flag ----------------------------------------------------
# Raw subzone miss rates are unstable where there are only a few reference
# facilities, so shrink them towards the island mean with a beta-binomial
# (empirical Bayes) prior fitted by moments.

sz <- mt %>% filter(set == "ecda") %>% group_by(subzone_c) %>%
  summarise(n_ref = n(), n_missed = sum(missed), .groups = "drop") %>%
  mutate(miss_raw = n_missed / n_ref)

mu <- sum(sz$n_missed) / sum(sz$n_ref)
vw <- with(sz %>% filter(n_ref >= 5), var(miss_raw))
kappa <- max(mu * (1 - mu) / vw - 1, 1)      # prior sample size
alpha <- mu * kappa; beta <- (1 - mu) * kappa

sz <- sz %>%
  mutate(miss_shrunk = (n_missed + alpha) / (n_ref + alpha + beta),
         quality_flag = cut(miss_shrunk, breaks = c(-Inf, mu - 0.05, mu + 0.05, Inf),
                            labels = c("better", "typical", "worse")))

sz_all <- subzones %>% st_drop_geometry() %>%
  select(subzone_c, subzone_n, pln_area_n) %>%
  left_join(sz, by = "subzone_c") %>%
  left_join(maturity %>% select(pln_area_n, maturity), by = "pln_area_n") %>%
  mutate(n_ref = coalesce(n_ref, 0L), n_missed = coalesce(n_missed, 0L))

write_csv(sz_all, file.path(DIR_PROC, "subzone_quality_flag.csv"))
log_step("ECDA island miss rate mu = ", round(mu, 3), ", prior kappa = ", round(kappa, 1))
log_step("subzones with >= 5 ECDA preschools: ", sum(sz_all$n_ref >= 5, na.rm = TRUE),
         " of ", nrow(sz_all))
cat("\nquality flag distribution (subzones with >= 5 ECDA preschools):\n")
print(sz_all %>% filter(n_ref >= 5) %>% count(quality_flag))
