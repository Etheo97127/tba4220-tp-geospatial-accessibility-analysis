# 02_coverage/03_quality_flag.R -------------------------------------------------
# Per-subzone OSM data-quality flag, the hand-off to the score and Q1-Q3, and the
# map of it. Built from ECDA only: CHAS lists only scheme-participating clinics,
# so a CHAS miss says less about how well a subzone is mapped.

source("R/00_setup.R")
library(ggplot2)
library(scales)

mt       <- readRDS(file.path(DIR_INT, "match_tested.rds"))
subzones <- readRDS(file.path(DIR_INT, "subzones.rds"))
maturity <- read_csv(file.path(DIR_EXT, "town_maturity.csv"), show_col_types = FALSE)

MIN_N  <- 5      # fewer preschools than this: no flag, and grey on the map
P_FLAG <- 0.90   # posterior probability needed to call a subzone better or worse

# Same blue ramp and greys as 04_outputs.R. Grey is reserved for "too few to
# rate", never a data value.
RAMP <- c("#9ec5f4", "#6da7ec", "#3987e5", "#1c5cab", "#0d366b")
GREY <- "#d9d8d4"; INK <- "#0b0b0b"; INK2 <- "#52514e"

# --- subzone quality flag ----------------------------------------------------
# Raw subzone miss rates are unstable where there are only a few reference
# facilities, so shrink them towards the island mean with a beta-binomial
# (empirical Bayes) prior fitted by moments.

sz <- mt %>% filter(set == "ecda") %>% group_by(subzone_c) %>%
  summarise(n_ref = n(), n_missed = sum(missed), .groups = "drop") %>%
  mutate(miss_raw = n_missed / n_ref)

mu <- sum(sz$n_missed) / sum(sz$n_ref)

# Moments over subzones with at least MIN_N preschools. Their raw rates vary
# partly through binomial noise, mu(1 - mu) / n on average; only the rest is
# real between-subzone variation, and that is what sets the prior.
big <- sz %>% filter(n_ref >= MIN_N)
vw  <- var(big$miss_raw) - mu * (1 - mu) * mean(1 / big$n_ref)
if (vw > 0) {
  kappa <- max(mu * (1 - mu) / vw - 1, 1)    # prior sample size
} else {
  # No variation beyond noise: pool completely, so every subzone is shrunk to mu
  # and flagged typical. A huge kappa does that and keeps pbeta() finite.
  kappa <- 1e6
  log_step("WARNING: no between-subzone variance in ECDA miss rates; pooling completely")
}
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

# --- map of shrunk miss rates ------------------------------------------------
# Subzones holding fewer than MIN_N preschools are greyed out rather than
# coloured: a one-of-one miss is not a 100% miss rate.

map_dat <- subzones %>%
  left_join(sz_all %>% select(subzone_c, n_ref, miss_shrunk), by = "subzone_c") %>%
  mutate(shown = ifelse(n_ref >= MIN_N, miss_shrunk, NA_real_))

# Crop to the inhabited part of the island. The offshore and industrial subzones
# hold no reference facilities and otherwise stretch the frame to no purpose.
bb <- st_bbox(map_dat %>% filter(n_ref >= MIN_N))
pad <- 1500

# Shrunk rates sit in a narrow band below 100%, so a 0-100% continuous ramp
# would render the whole island one shade. Five bins of a whole-percent width
# over the range that actually occurs, anchored at the top so the scale never
# passes 100%.
rng  <- range(map_dat$shown, na.rm = TRUE)
top  <- ceiling(rng[2] * 100)
step <- ceiling((top - floor(rng[1] * 100)) / 5)
BRK  <- (top - step * (5:0)) / 100

p_map <- ggplot() +
  geom_sf(data = map_dat, aes(fill = shown), colour = "white", linewidth = 0.1) +
  scale_fill_stepsn(colours = RAMP, breaks = BRK, limits = range(BRK),
                    na.value = GREY, labels = percent_format(accuracy = 1),
                    name = "share of ECDA\npreschools missing\nfrom OSM",
                    guide = guide_coloursteps(barheight = 7, barwidth = 0.8)) +
  coord_sf(xlim = c(bb$xmin - pad, bb$xmax + pad),
           ylim = c(bb$ymin - pad, bb$ymax + pad), expand = FALSE) +
  labs(title = sprintf("OSM misses %s of ECDA preschools; the best-mapped subzone misses an estimated %s",
                       percent(mu, accuracy = 1), percent(rng[1], accuracy = 1)),
       subtitle = paste0("MP19 subzones, empirical-Bayes shrunk share of ECDA preschools absent from OSM.\n",
                         "Grey: fewer than ", MIN_N, " preschools, too few to rate."),
       caption = sprintf(paste0("Reference: ECDA childcare and kindergarten listings, Singapore only. ",
                                "Island-wide miss rate %s (%s of %s).\n",
                                "CHAS clinics are a supplementary benchmark and are not mapped. ",
                                "Per-subzone counts in data/processed/subzone_quality_flag.csv."),
                         percent(mu, accuracy = 0.1),
                         comma(sum(sz$n_missed)), comma(sum(sz$n_ref)))) +
  theme_void(base_size = 9) +
  theme(plot.title = element_text(colour = INK, face = "bold", size = 10),
        plot.subtitle = element_text(colour = INK2, size = 8),
        plot.caption = element_text(colour = INK2, size = 7, hjust = 0),
        legend.title = element_text(colour = INK2, size = 8),
        legend.text = element_text(colour = INK2, size = 7))

# --- outputs -----------------------------------------------------------------

write_csv(sz_all, file.path(DIR_PROC, "subzone_quality_flag.csv"))
ggsave(file.path(DIR_FIG, "coverage_missrate_map.png"), p_map,
       width = 7.8, height = 3.6, dpi = 300, bg = "white")
log_step("ECDA island miss rate mu = ", round(mu, 3), ", prior kappa = ", round(kappa, 1))
flags <- table(sz_all$quality_flag)
log_step("flagged subzones (>= ", MIN_N, " ECDA preschools): ", sum(flags), " of ", nrow(sz_all),
         ": ", paste(names(flags), flags, collapse = " / "))
