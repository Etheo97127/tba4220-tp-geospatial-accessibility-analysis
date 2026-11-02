# 02_coverage/02_gap_test.R -----------------------------------------------------
# H0: the share of missing facilities is the same in mature and non-mature towns.
#
# Three things happen here, in increasing order of how much they respect the
# geography:
#   (a) a two-proportion test on the mature / non-mature split (the proposal);
#   (b) a logistic regression, which asks whether maturity survives controlling
#       for distance to the centre;
#   (c) a random-labelling permutation test, which asks whether the missed
#       facilities cluster BEYOND the clustering of the facilities themselves --
#       something the binary split cannot see.

source("R/00_setup.R")
library(pwr)
library(binom)
suppressPackageStartupMessages({
  library(spatstat.geom); library(spatstat.random); library(spatstat.explore)
})

match_table <- readRDS(file.path(DIR_INT, "match_table.rds"))
subzones    <- readRDS(file.path(DIR_INT, "subzones.rds"))
reference   <- readRDS(file.path(DIR_INT, "reference.rds"))
maturity    <- read_csv(file.path(DIR_EXT, "town_maturity.csv"), show_col_types = FALSE)

# Headline definition only: strict OSM counterpart categories.
mt <- match_table %>% filter(variant == "strict") %>%
  left_join(maturity %>% select(pln_area_n, maturity), by = "pln_area_n") %>%
  mutate(missed = !matched)

stopifnot(!any(is.na(mt$maturity)))

cat("\n=== facilities by town classification ===\n")
print(mt %>% count(set, maturity) %>% pivot_wider(names_from = maturity, values_from = n, values_fill = 0))
log_step("excluded (not an HDB town): ", sum(mt$maturity == "excluded"),
         " of ", nrow(mt), " reference facilities")

tested <- mt %>% filter(maturity %in% c("mature", "non-mature"))

# --- (a) two-proportion test -------------------------------------------------
# ECDA is the headline benchmark (docs/REQUIREMENTS.md section 3, decided
# 2026-09-16): it is close to a census of its category. CHAS lists only
# scheme-participating clinics, and scheme membership varies along the same
# heartland / central axis as the hypothesis, so its row is supplementary and
# the two lists are never pooled.

prop_one <- function(df, set_name, label, role) {
  tab <- df %>% group_by(maturity) %>%
    summarise(n = n(), missed = sum(missed), .groups = "drop")
  m  <- tab %>% filter(maturity == "mature")
  nm <- tab %>% filter(maturity == "non-mature")
  ht <- prop.test(c(m$missed, nm$missed), c(m$n, nm$n), correct = TRUE)
  # Power at the observed difference says little after the fact. Report instead
  # the smallest difference these arm sizes detect at 80% power: solve for
  # Cohen's h, then turn h back into a gap in miss rate centred on the observed
  # overall miss rate. h is on the arcsine scale, so near 0 or 1 the same h is
  # a smaller gap in percentage points than near 50%.
  h_mdd <- pwr.2p2n.test(n1 = m$n, n2 = nm$n, sig.level = 0.05, power = 0.80)$h
  p0 <- (m$missed + nm$missed) / (m$n + nm$n)
  gap <- uniroot(function(g) ES.h(p0 + g / 2, p0 - g / 2) - h_mdd,
                 c(0, 2 * min(p0, 1 - p0)))$root
  tibble(set = set_name, role = role, test = label,
         n_mature = m$n, miss_mature = m$missed, p_mature = m$missed / m$n,
         n_nonmature = nm$n, miss_nonmature = nm$missed, p_nonmature = nm$missed / nm$n,
         diff = m$missed / m$n - nm$missed / nm$n,
         ci_lo = ht$conf.int[1], ci_hi = ht$conf.int[2],
         chisq = unname(ht$statistic), p_value = ht$p.value,
         mdd_h = h_mdd, mdd_pp = 100 * gap)
}

# Holm is applied within each role, never across them: the headline is a single
# pre-specified test and is not adjusted for the supplementary rows. With CHAS
# the only supplementary row, its adjusted p equals its raw p until another
# supplementary benchmark is added.
prop_res <- bind_rows(
  prop_one(tested %>% filter(set == "ecda"), "ecda", "ECDA preschools", "headline"),
  prop_one(tested %>% filter(set == "chas"), "chas", "CHAS clinics (supplementary)", "supplementary")
) %>%
  group_by(role) %>%
  mutate(p_holm = p.adjust(p_value, method = "holm")) %>%
  ungroup()

write_csv(prop_res, file.path(DIR_TAB, "coverage_prop_test.csv"))
cat("\n=== (a) two-proportion test: miss rate, mature vs non-mature ===\n")
print(prop_res %>% mutate(across(where(is.numeric), ~round(.x, 4))) %>% as.data.frame())

# --- (b) logistic regression -------------------------------------------------
# Does town maturity still matter once distance from the centre is allowed for?

cbd <- st_sfc(st_point(c(103.8515, 1.2839)), crs = CRS_WGS84) %>% st_transform(CRS_SVY21)
ref_xy <- reference %>% st_drop_geometry() %>%
  mutate(dist_cbd_km = as.numeric(st_distance(reference, cbd)) / 1000)

glm_dat <- tested %>% left_join(ref_xy %>% select(ref_id, dist_cbd_km), by = "ref_id") %>%
  mutate(maturity = factor(maturity, levels = c("mature", "non-mature")))

fit <- glm(missed ~ maturity + dist_cbd_km + set, data = glm_dat, family = binomial())
cat("\n=== (b) logistic regression: P(facility missing from OSM) ===\n")
print(summary(fit)$coefficients)
or <- exp(cbind(OR = coef(fit), confint.default(fit)))
cat("\nodds ratios:\n"); print(round(or, 3))
write_csv(as_tibble(or, rownames = "term") %>%
            rename(ci_lo = `2.5 %`, ci_hi = `97.5 %`),
          file.path(DIR_TAB, "coverage_logistic.csv"))

# --- (c) random labelling ----------------------------------------------------
# Under H0 the missed facilities are a random thinning of the real ones. Permute
# the matched/missed labels over the fixed point locations and compare the
# observed K function of the missed subpattern against the envelope.

# The analysis window is the Singapore land area. Simplified to a 50 m tolerance:
# the coastline detail costs a great deal in edge correction and changes nothing
# at the distances we test over.
win <- subzones %>% st_union() %>% st_make_valid() %>%
  st_simplify(dTolerance = 50) %>% st_make_valid() %>% as.owin()
log_step("window area (km2): ", round(area.owin(win) / 1e6, 1))

random_label_test <- function(set_name, nsim = 999) {
  pts <- reference %>%
    inner_join(mt %>% filter(set == set_name) %>% select(ref_id, missed), by = "ref_id")
  xy <- st_coordinates(pts)
  X <- ppp(xy[, 1], xy[, 2], window = win,
           marks = factor(ifelse(pts$missed, "missed", "found")))
  X <- unique.ppp(X)                       # duplicated points break Kcross
  # One set of simulations, reused for both the envelope and the test statistic.
  # Border correction: the window is a union of 332 polygons, and the analytic
  # edge corrections on it are what make this intractable.
  env <- envelope(X, Kcross, i = "missed", j = "missed",
                  simulate = expression(rlabel(X)),
                  nsim = nsim, r = seq(0, 1500, length.out = 61),
                  correction = "border", savefuns = TRUE, verbose = FALSE)
  # Global MAD test computed from the saved simulated functions rather than a
  # second round of 999 simulations.
  # simfuns is an fv object; go via data.frame, since fv refuses to drop `r`.
  sf_df <- as.data.frame(attr(env, "simfuns"))
  fns <- as.matrix(sf_df[, setdiff(names(sf_df), "r"), drop = FALSE])
  obs <- env$obs
  dev_obs <- max(abs(obs - rowMeans(fns)), na.rm = TRUE)
  dev_sim <- apply(fns, 2, function(z) max(abs(z - rowMeans(fns)), na.rm = TRUE))
  p_mad <- (1 + sum(dev_sim >= dev_obs)) / (1 + length(dev_sim))
  list(set = set_name, env = env, statistic = dev_obs, p.value = p_mad,
       n = npoints(X), n_missed = sum(marks(X) == "missed"))
}

set.seed(SEED)
rl <- lapply(c("chas", "ecda"), random_label_test)
names(rl) <- c("chas", "ecda")
saveRDS(rl, file.path(DIR_INT, "random_labelling.rds"))

cat("\n=== (c) random labelling test (999 permutations) ===\n")
rl_tab <- bind_rows(lapply(rl, function(z) tibble(
  set = z$set, n_points = z$n, n_missed = z$n_missed,
  statistic = z$statistic, p_value = z$p.value)))
rl_tab$p_holm <- p.adjust(rl_tab$p_value, method = "holm")
print(as.data.frame(rl_tab))
write_csv(rl_tab, file.path(DIR_TAB, "coverage_random_labelling.csv"))

# --- subzone quality flag ----------------------------------------------------
# The hand-off to the score and Q1-Q3. Raw subzone miss rates are unstable where there are
# only a few reference facilities, so shrink them towards the island mean with a
# beta-binomial (empirical Bayes) prior fitted by moments.

sz <- mt %>% group_by(subzone_c) %>%
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
log_step("island miss rate mu = ", round(mu, 3), ", prior kappa = ", round(kappa, 1))
log_step("subzones with >= 5 reference facilities: ", sum(sz_all$n_ref >= 5, na.rm = TRUE),
         " of ", nrow(sz_all))
cat("\nquality flag distribution (subzones with >= 5 reference facilities):\n")
print(sz_all %>% filter(n_ref >= 5) %>% count(quality_flag))

saveRDS(mt, file.path(DIR_INT, "match_tested.rds"))
