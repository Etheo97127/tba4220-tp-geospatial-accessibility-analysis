# 03_score/03_outputs.R ---------------------------------------------------------
# Maps of the access score: the composite, and the six category scores as small
# multiples on one shared 0-100 scale. Non-residential subzones are grey, never
# coloured -- they are outside every analysis.

source("R/00_setup.R")
library(ggplot2)

score    <- readRDS(file.path(DIR_PROC, "score_subzone.rds"))
weights  <- read_csv(file.path(DIR_PROC, "hes_weights.csv"), show_col_types = FALSE)

CAT_LAB <- c(food_services = "Food services", retail = "Retail goods", health = "Health",
             food_retail = "Food retail", education = "Education", recreation = "Recreation")

fill_score <- scale_fill_stepsn(colours = PAL_SEQ, breaks = seq(0, 100, 20), limits = c(0, 100),
                                oob = scales::squish, na.value = GREY_NA, name = "score")

map_dat <- score %>% mutate(shown = if_else(residential, score, NA_real_))
n_res <- sum(score$residential)

p1 <- ggplot(map_dat) +
  geom_sf(aes(fill = shown), colour = "white", linewidth = 0.1) +
  fill_score +
  labs(title = paste0("Access score v0: everyday services within ", RADIUS_M / 1000,
                     " km of where residents live"),
       subtitle = paste0("Composite of six categories weighted by HES 2023 spending shares; ",
                         n_res, " residential subzones.\nGrey: non-residential subzones, ",
                         "outside every analysis."),
       caption = "Source: OpenStreetMap (ODbL), Census 2020, HES 2023, URA MP19. Score v0 - provisional.") +
  theme_map()
save_fig(p1, "score_composite_map.png", width = 7.8, height = 4.4)

long <- bind_rows(lapply(names(CAT_LAB), function(k) {
  map_dat %>% transmute(panel = sprintf("%s (%.1f%%)", CAT_LAB[[k]], 100 * weights$weight[weights$category == k]),
                        shown = if_else(residential, .data[[paste0("score_", k)]], NA_real_))
})) %>% mutate(panel = factor(panel, levels = unique(panel)))

p2 <- ggplot(long) +
  geom_sf(aes(fill = shown), colour = NA) +
  facet_wrap(~panel, ncol = 3) +
  fill_score +
  labs(title = "The six category scores behind the composite",
       subtitle = paste0("100 = best-served residential subzone in that category (log of the ",
                         RADIUS_M / 1000, " km count). Weight in brackets."),
       caption = "Grey: non-residential subzones.") +
  theme_map()
save_fig(p2, "score_category_maps.png", width = 7.8, height = 4.6)

log_step("score figures written to ", DIR_FIG)
