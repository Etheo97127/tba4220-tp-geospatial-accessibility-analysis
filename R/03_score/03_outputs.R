# 03_score/03_outputs.R ---------------------------------------------------------
# Maps of the access score: the composite, and the six category scores as small
# multiples on one shared 0-100 scale. Non-residential subzones are grey, never
# coloured -- they are outside every analysis.

source("R/00_setup.R")
library(ggplot2)

score    <- readRDS(file.path(DIR_PROC, "score_subzone.rds"))
weights  <- read_csv(file.path(DIR_PROC, "hes_weights.csv"), show_col_types = FALSE)

SEQ  <- c("#cde2fb", "#9ec5f4", "#6da7ec", "#3987e5", "#1c5cab", "#0d366b")
GREY <- "#d9d8d4"
CAT_LAB <- c(food_services = "Food services", retail = "Retail goods", health = "Health",
             food_retail = "Food retail", education = "Education", recreation = "Recreation")

theme_map <- theme_void(base_size = 9) +
  theme(plot.title = element_text(face = "bold", size = 10),
        plot.subtitle = element_text(size = 8, colour = "#52514e"),
        plot.caption = element_text(size = 7, colour = "#52514e", hjust = 0),
        strip.text = element_text(face = "bold", size = 8),
        legend.title = element_text(size = 8, colour = "#52514e"))

fill_score <- scale_fill_stepsn(colours = SEQ, breaks = seq(0, 100, 20), limits = c(0, 100),
                                oob = scales::squish, na.value = GREY, name = "score")

map_dat <- score %>% mutate(shown = if_else(residential, score, NA_real_))
n_res <- sum(score$residential)

p1 <- ggplot(map_dat) +
  geom_sf(aes(fill = shown), colour = "white", linewidth = 0.1) +
  fill_score +
  labs(title = "Access score v0: everyday services within 1 km of where residents live",
       subtitle = paste0("Composite of six categories weighted by HES 2023 spending shares; ",
                         n_res, " residential subzones.\nGrey: fewer than ", RES_MIN_POP,
                         " residents, outside every analysis."),
       caption = "Source: OpenStreetMap (ODbL), Census 2020, HES 2023, URA MP19. Score v0 - provisional.") +
  theme_map
ggsave(file.path(DIR_FIG, "score_composite_map.png"), p1, width = 7.8, height = 4.4, dpi = 300, bg = "white")

long <- bind_rows(lapply(names(CAT_LAB), function(k) {
  map_dat %>% transmute(panel = sprintf("%s (%.1f%%)", CAT_LAB[[k]], 100 * weights$weight[weights$category == k]),
                        shown = if_else(residential, .data[[paste0("score_", k)]], NA_real_))
})) %>% mutate(panel = factor(panel, levels = unique(panel)))

p2 <- ggplot(long) +
  geom_sf(aes(fill = shown), colour = NA) +
  facet_wrap(~panel, ncol = 3) +
  fill_score +
  labs(title = "The six category scores behind the composite",
       subtitle = "100 = best-served residential subzone in that category (log of the 1 km count). Weight in brackets.",
       caption = "Grey: non-residential subzones.") +
  theme_map
ggsave(file.path(DIR_FIG, "score_category_maps.png"), p2, width = 7.8, height = 4.6, dpi = 300, bg = "white")

log_step("score figures written to ", DIR_FIG)
