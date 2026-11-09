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
  h_mdd <- pwr.2p2n.test(n1 = m$n, n2 = nm$n, sig.level = ALPHA, power = 0.80)$h
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
# Fitted on each set separately: ECDA is the headline, CHAS supplementary. Not
# pooled with `set` as a term, for the same reason as the proportion test.

cbd <- st_sfc(st_point(c(103.8515, 1.2839)), crs = CRS_WGS84) %>% st_transform(CRS_SVY21)
ref_xy <- reference %>% st_drop_geometry() %>%
  mutate(dist_cbd_km = as.numeric(st_distance(reference, cbd)) / 1000)

glm_dat <- tested %>% left_join(ref_xy %>% select(ref_id, dist_cbd_km), by = "ref_id") %>%
  mutate(maturity = factor(maturity, levels = c("mature", "non-mature")))

fit_one <- function(dat, set_name, role) {
  fit <- glm(missed ~ maturity + dist_cbd_km, data = dat %>% filter(set == set_name),
             family = binomial())
  co <- summary(fit)$coefficients
  ci <- confint.default(fit)
  tibble(set = set_name, role = role, term = rownames(co),
         OR = exp(co[, "Estimate"]), ci_lo = exp(ci[, 1]), ci_hi = exp(ci[, 2]),
         p_value = co[, "Pr(>|z|)"])
}

logit_res <- bind_rows(fit_one(glm_dat, "ecda", "headline"),
                       fit_one(glm_dat, "chas", "supplementary"))
cat("\n=== (b) logistic regression: P(facility missing from OSM), odds ratios ===\n")
print(logit_res %>% mutate(across(where(is.numeric), ~round(.x, 4))) %>% as.data.frame())
write_csv(logit_res, file.path(DIR_TAB, "coverage_logistic.csv"))

# Which towns carry the ECDA maturity effect? Sengkang and Hougang, two
# north-eastern non-mature towns, are mapped far better than the rest. Refit
# without each, then without both. Post hoc, so it qualifies the effect only.
DROP_TOWNS <- list(Sengkang = "SENGKANG", Hougang = "HOUGANG",
                   `Sengkang and Hougang` = c("SENGKANG", "HOUGANG"))
logit_drop <- bind_rows(lapply(names(DROP_TOWNS), function(towns) {
  fit_one(glm_dat %>% filter(!pln_area_n %in% DROP_TOWNS[[towns]]), "ecda", "headline") %>%
    filter(term == "maturitynon-mature") %>%
    mutate(dropped = towns, .after = role)
}))
print(logit_drop %>% mutate(across(where(is.numeric), ~round(.x, 4))) %>% as.data.frame())
write_csv(logit_drop, file.path(DIR_TAB, "coverage_logistic_sensitivity.csv"))

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
  # Co-located facilities (two preschools in one block) stay separate points.
  # unique.ppp() would drop a duplicate only when its label matches too, so it
  # thinned same-label pairs alone and removed the very co-location under test.
  X <- ppp(xy[, 1], xy[, 2], window = win,
           marks = factor(ifelse(pts$missed, "missed", "found")))
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
  dev <- env$obs - rowMeans(fns)
  dev_obs <- max(abs(dev), na.rm = TRUE)
  dev_sim <- apply(fns, 2, function(z) max(abs(z - rowMeans(fns)), na.rm = TRUE))
  p_mad <- (1 + sum(dev_sim >= dev_obs)) / (1 + length(dev_sim))
  # The MAD test is two-sided. Record which side the largest departure lies on,
  # so "more clustered than chance" is only claimed when K sits above the mean.
  direction <- ifelse(dev[which.max(abs(dev))] > 0, "clustered", "dispersed")
  list(set = set_name, env = env, statistic = dev_obs, p.value = p_mad,
       direction = direction, n = npoints(X), n_missed = sum(marks(X) == "missed"))
}

# Simulated CHAS first, then ECDA, so the seeded draws match earlier runs; the
# table below puts the ECDA headline first. Holm within role, as in (a).
set.seed(SEED)
rl <- lapply(c("chas", "ecda"), random_label_test)
names(rl) <- c("chas", "ecda")
saveRDS(rl, file.path(DIR_INT, "random_labelling.rds"))

cat("\n=== (c) random labelling test (999 permutations) ===\n")
rl_tab <- bind_rows(lapply(rl, function(z) tibble(
  set = z$set, role = ifelse(z$set == "ecda", "headline", "supplementary"),
  n_points = z$n, n_missed = z$n_missed,
  statistic = z$statistic, direction = z$direction, p_value = z$p.value))) %>%
  arrange(role != "headline") %>%
  group_by(role) %>%
  mutate(p_holm = p.adjust(p_value, method = "holm")) %>%
  ungroup()
print(as.data.frame(rl_tab))
write_csv(rl_tab, file.path(DIR_TAB, "coverage_random_labelling.csv"))

# Read by 03 to 06 of this stage.
saveRDS(mt, file.path(DIR_INT, "match_tested.rds"))
