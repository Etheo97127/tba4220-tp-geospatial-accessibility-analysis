# 02_coverage/03_outputs.R ------------------------------------------------------
# Tables and figures for the coverage check. Print output, so: single-hue sequential ramp for
# magnitude, a distinct grey for "not enough data to say", recessive axes.

source("R/00_setup.R")
library(ggplot2)
library(binom)
library(scales)

grid        <- read_csv(file.path(DIR_TAB, "coverage_threshold_sensitivity.csv"), show_col_types = FALSE)
match_table <- readRDS(file.path(DIR_INT, "match_table.rds"))
mt          <- readRDS(file.path(DIR_INT, "match_tested.rds"))
subzones    <- readRDS(file.path(DIR_INT, "subzones.rds"))
reference   <- readRDS(file.path(DIR_INT, "reference.rds"))
szq         <- read_csv(file.path(DIR_PROC, "subzone_quality_flag.csv"), show_col_types = FALSE)

# Sequential blue ramp, light -> dark; ordinal steps 250/450/650 for the three
# name thresholds. Grey is reserved for "insufficient data", never a data value.
SEQ    <- c("#cde2fb", "#9ec5f4", "#6da7ec", "#3987e5", "#2a78d6", "#1c5cab", "#0d366b")
ORD3   <- c("#86b6ef", "#2a78d6", "#104281")
GREY   <- "#d9d8d4"
INK    <- "#0b0b0b"; INK2 <- "#52514e"

theme_cov <- theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major = element_line(linewidth = 0.25, colour = "#e8e7e3"),
        axis.title = element_text(colour = INK2),
        axis.text  = element_text(colour = INK2),
        plot.title = element_text(colour = INK, face = "bold", size = 10),
        plot.subtitle = element_text(colour = INK2, size = 8.5),
        plot.caption  = element_text(colour = INK2, size = 7, hjust = 0),
        strip.text = element_text(colour = INK, face = "bold"),
        legend.title = element_text(colour = INK2, size = 8))

SET_LAB <- c(chas = "CHAS clinics (n = 1,193)", ecda = "ECDA preschools (n = 1,975)")

# --- Table 1: recall by category ---------------------------------------------

recall_tab <- grid %>%
  filter(d_m == 50, s_name == 0.80) %>%
  transmute(set = SET_LAB[set], variant,
            n_reference = n_ref, n_osm = n_osm, n_matched,
            recall = round(recall, 3), ci_lo = round(lo, 3), ci_hi = round(hi, 3),
            via_name, via_postcode, via_proximity)
write_csv(recall_tab, file.path(DIR_TAB, "coverage_recall_by_category.csv"))
cat("\n=== Table 1: recall at d = 50 m, s = 0.80 ===\n"); print(as.data.frame(recall_tab))

# --- Figure 1: threshold sensitivity -----------------------------------------

p1 <- grid %>% filter(variant == "strict") %>%
  mutate(set = SET_LAB[set], s_name = factor(s_name)) %>%
  ggplot(aes(d_m, recall, colour = s_name, group = s_name)) +
  geom_ribbon(aes(ymin = lo, ymax = hi, fill = s_name), alpha = 0.12, colour = NA) +
  geom_line(linewidth = 0.7) +
  geom_point(size = 1.8) +
  facet_wrap(~set) +
  scale_colour_manual(values = ORD3, name = "name similarity\nthreshold") +
  scale_fill_manual(values = ORD3, guide = "none") +
  scale_y_continuous(labels = percent_format(accuracy = 1), limits = c(0, NA)) +
  scale_x_continuous(breaks = c(25, 50, 100, 150)) +
  labs(title = "OSM recall is low at every plausible matching threshold",
       subtitle = "Share of known Singapore facilities with a matching OpenStreetMap feature",
       x = "distance threshold (m)", y = "recall",
       caption = "Shaded band: Wilson 95% CI. Headline cell is 50 m / 0.80, fixed before recall was computed.") +
  theme_cov
ggsave(file.path(DIR_FIG, "coverage_threshold_sensitivity.png"), p1,
       width = 7.2, height = 3.2, dpi = 300, bg = "white")

# --- Figure 2: subzone miss-rate map -----------------------------------------
# Subzones holding fewer than 5 reference facilities are greyed out rather than
# coloured: a one-of-one miss is not a 100% miss rate.

MIN_N <- 5
map_dat <- subzones %>%
  left_join(szq %>% select(subzone_c, n_ref, n_missed, miss_shrunk), by = "subzone_c") %>%
  mutate(shown = ifelse(!is.na(n_ref) & n_ref >= MIN_N, miss_shrunk, NA_real_))

# Crop to the inhabited part of the island. The offshore and industrial subzones
# hold no reference facilities and otherwise stretch the frame to no purpose.
bb <- st_bbox(map_dat %>% filter(!is.na(n_ref) & n_ref >= MIN_N))
pad <- 1500

# Observed rates run from about 0.51 to 0.98, so a 0-100% continuous ramp would
# render the whole island one shade. Binned, over the range that actually occurs.
BRK <- c(0.50, 0.65, 0.75, 0.85, 0.92, 1.00)

p2 <- ggplot() +
  geom_sf(data = map_dat, aes(fill = shown), colour = "white", linewidth = 0.1) +
  scale_fill_stepsn(colours = SEQ[c(2, 3, 4, 6, 7)], breaks = BRK, limits = c(0.50, 1.00),
                    na.value = GREY, labels = percent_format(accuracy = 1),
                    name = "share of known\nfacilities missing\nfrom OSM",
                    guide = guide_coloursteps(barheight = 7, barwidth = 0.8)) +
  coord_sf(xlim = c(bb$xmin - pad, bb$xmax + pad),
           ylim = c(bb$ymin - pad, bb$ymax + pad), expand = FALSE) +
  labs(title = "OSM coverage is poor everywhere, and the gaps are not evenly spread",
       subtitle = paste0("MP19 subzones, empirical-Bayes shrunk share of known facilities absent from OSM.\n",
                         "Grey: fewer than ", MIN_N, " reference facilities, too few to rate."),
       caption = paste0("Reference: CHAS clinic directory and ECDA childcare/kindergarten listings, Singapore only. ",
                        "Island-wide miss rate 85.7%.\nPer-subzone counts in data/processed/subzone_quality_flag.csv.")) +
  theme_void(base_size = 9) +
  theme(plot.title = element_text(colour = INK, face = "bold", size = 10),
        plot.subtitle = element_text(colour = INK2, size = 8),
        plot.caption = element_text(colour = INK2, size = 7, hjust = 0),
        legend.title = element_text(colour = INK2, size = 8),
        legend.text = element_text(colour = INK2, size = 7))
ggsave(file.path(DIR_FIG, "coverage_missrate_map.png"), p2,
       width = 7.8, height = 3.6, dpi = 300, bg = "white")

# --- Figure 3: random labelling envelope -------------------------------------

rl_path <- file.path(DIR_INT, "random_labelling.rds")
if (file.exists(rl_path)) {
  rl <- readRDS(rl_path)
  rl_stats <- read_csv(file.path(DIR_TAB, "coverage_random_labelling.csv"), show_col_types = FALSE)
  # K(r) grows like r^2, which swamps the departure we care about. Centre each
  # curve on the permutation mean so the envelope is a flat band around zero and
  # the excess is legible.
  env_df <- bind_rows(lapply(rl, function(z) {
    e <- z$env
    st <- rl_stats %>% filter(set == z$set)
    lab <- sprintf("%s\n%s distinct locations, %s missed  |  p = %.3f",
                   ifelse(z$set == "chas", "CHAS clinics", "ECDA preschools"),
                   comma(z$n), comma(z$n_missed), st$p_value)
    tibble(set = lab, r = e$r,
           obs = e$obs - e$mmean, lo = e$lo - e$mmean, hi = e$hi - e$mmean)
  }))
  p3 <- ggplot(env_df, aes(r)) +
    geom_ribbon(aes(ymin = lo, ymax = hi), fill = SEQ[2], alpha = 0.7) +
    geom_hline(yintercept = 0, colour = INK2, linewidth = 0.3, linetype = "22") +
    geom_line(aes(y = obs), colour = SEQ[7], linewidth = 0.8) +
    facet_wrap(~set, scales = "free_y") +
    scale_y_continuous(labels = label_number(scale = 1e-6, suffix = "M")) +
    labs(title = "Clinic gaps cluster beyond the clustering of clinics; preschool gaps do not",
         subtitle = "Observed K of the missed facilities minus the mean over 999 random relabellings.\nBand: the 999 relabellings. A line above the band means the gaps are more clustered than chance.",
         x = "distance r (m)", y = "K(r) - permutation mean",
         caption = "Random labelling permutes matched/missed over fixed facility locations, so it tests clustering of the gaps beyond the clustering of the facilities themselves.\nCo-located facilities are collapsed to one point, which is why the counts are below the full reference totals.") +
    theme_cov
  ggsave(file.path(DIR_FIG, "coverage_random_labelling.png"), p3,
         width = 7.2, height = 3.2, dpi = 300, bg = "white")
  log_step("wrote random labelling figure")
} else {
  log_step("random_labelling.rds not found - skipping figure 3")
}

# --- Figure 4: miss rate by planning area ------------------------------------

pa <- mt %>% filter(maturity %in% c("mature", "non-mature")) %>%
  group_by(pln_area_n, maturity) %>%
  summarise(n = n(), missed = sum(missed), .groups = "drop") %>%
  filter(n >= 20) %>%
  mutate(rate = missed / n) %>%
  bind_cols(binom.confint(.$missed, .$n, methods = "wilson") %>% select(lo = lower, hi = upper))

p4 <- pa %>%
  mutate(pln_area_n = reorder(str_to_title(pln_area_n), rate)) %>%
  ggplot(aes(rate, pln_area_n, colour = maturity)) +
  geom_linerange(aes(xmin = lo, xmax = hi), linewidth = 0.5) +
  geom_point(size = 1.9) +
  scale_colour_manual(values = c(mature = ORD3[3], `non-mature` = ORD3[1]), name = NULL) +
  scale_x_continuous(labels = percent_format(accuracy = 1)) +
  labs(title = "No clean split between mature and non-mature towns",
       subtitle = "Share of known facilities missing from OSM, by planning area (>= 20 reference facilities)",
       x = "missing from OSM", y = NULL,
       caption = "Bars: Wilson 95% CI. Both reference lists pooled.") +
  theme_cov + theme(panel.grid.major.y = element_blank())
ggsave(file.path(DIR_FIG, "coverage_missrate_by_planning_area.png"), p4,
       width = 6.6, height = 5.2, dpi = 300, bg = "white")

log_step("figures written to ", DIR_FIG)
