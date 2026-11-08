# 02_coverage/03_quality_flag.R -------------------------------------------------
# Per-subzone OSM data-quality flag: the hand-off to the score and Q1-Q3.
# Built from ECDA only: CHAS lists only scheme-participating clinics, so a CHAS
# miss says less about how well a subzone is mapped.

source("R/00_setup.R")

mt       <- readRDS(file.path(DIR_INT, "match_tested.rds"))
subzones <- readRDS(file.path(DIR_INT, "subzones.rds"))
maturity <- read_csv(file.path(DIR_EXT, "town_maturity.csv"), show_col_types = FALSE)

MIN_N  <- 5      # fewer preschools than this: no flag (the map's MIN_N in 04_outputs.R)
P_FLAG <- 0.90   # posterior probability needed to call a subzone better or worse

# --- subzone quality flag ----------------------------------------------------
# Raw subzone miss rates are unstable where there are only a few reference
# facilities, so shrink them towards the island mean with a beta-binomial
# (empirical Bayes) prior fitted by moments.

sz <- mt %>% filter(set == "ecda") %>% group_by(subzone_c) %>%
  summarise(n_ref = n(), n_missed = sum(missed), .groups = "drop") %>%
  mutate(miss_raw = n_missed / n_ref)

mu <- sum(sz$n_missed) / sum(sz$n_ref)
vw <- with(sz %>% filter(n_ref >= MIN_N), var(miss_raw))
kappa <- max(mu * (1 - mu) / vw - 1, 1)      # prior sample size
alpha <- mu * kappa; beta <- (1 - mu) * kappa

# The flag cuts the posterior probability that a subzone's true miss rate is
# below the island mean, not a +-x pp band around it. With mu near 0.9 a fixed
# band is lopsided (a rate can fall far below mu but barely rise above it), and
# it ignores how many preschools the rate rests on.
sz <- sz %>%
  mutate(miss_shrunk = (n_missed + alpha) / (n_ref + alpha + beta),
         p_below = pbeta(mu, n_missed + alpha, n_ref - n_missed + beta),
         quality_flag = case_when(n_ref < MIN_N        ~ NA_character_,
                                  p_below >= P_FLAG     ~ "better",
                                  p_below <= 1 - P_FLAG ~ "worse",
                                  TRUE                  ~ "typical"),
         quality_flag = factor(quality_flag, levels = c("better", "typical", "worse"))) %>%
  select(-p_below)

sz_all <- subzones %>% st_drop_geometry() %>%
  select(subzone_c, subzone_n, pln_area_n) %>%
  left_join(sz, by = "subzone_c") %>%
  left_join(maturity %>% select(pln_area_n, maturity), by = "pln_area_n") %>%
  mutate(n_ref = coalesce(n_ref, 0L), n_missed = coalesce(n_missed, 0L))

write_csv(sz_all, file.path(DIR_PROC, "subzone_quality_flag.csv"))
log_step("ECDA island miss rate mu = ", round(mu, 3), ", prior kappa = ", round(kappa, 1))
flags <- table(sz_all$quality_flag)
log_step("flagged subzones (>= ", MIN_N, " ECDA preschools): ", sum(flags), " of ", nrow(sz_all),
         ": ", paste(names(flags), flags, collapse = " / "))
