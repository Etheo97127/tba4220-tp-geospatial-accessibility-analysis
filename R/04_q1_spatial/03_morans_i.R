# 04_q1_spatial/03_morans_i.R ---------------------------------------------------
# B4: global Moran's I for each category score and the composite, H0: I = 0.
# Permutation test with 999 draws (Lecture 8), one-sided for positive
# autocorrelation, run on queen weights and again on kNN as a check. The input
# is subzone scores on the residential set, never facility coordinates.

source("R/00_setup.R")
library(spdep)
library(ggplot2)

score <- readRDS(file.path(DIR_PROC, "score_subzone.rds")) %>% st_drop_geometry()
nbobj <- readRDS(file.path(DIR_PROC, "q1_neighbours.rds"))

NSIM <- 999
VARS <- c(paste0("score_", CATEGORIES), "score")

sz <- tibble(subzone_c = nbobj$subzone_c) %>% left_join(score, by = "subzone_c")
stopifnot(identical(sz$subzone_c, nbobj$subzone_c), !anyNA(sz[VARS]))

moran_one <- function(x, lw) {
  set.seed(SEED)
  m <- moran.mc(x, lw, nsim = NSIM, alternative = "greater")
  c(I = unname(m$statistic), p = m$p.value)
}

res <- bind_rows(lapply(VARS, function(v) {
  q <- moran_one(sz[[v]], nbobj$lw_queen)
  k <- moran_one(sz[[v]], nbobj$lw_knn)
  tibble(variable = v, I_queen = q[["I"]], p_queen = q[["p"]], I_knn = k[["I"]], p_knn = k[["p"]])
}))

write_csv(res %>% mutate(across(c(I_queen, I_knn), ~ round(.x, 3))), file.path(DIR_TAB, "q1_morans_i.csv"))

LAB <- c(score_food_services = "Food services", score_retail = "Retail goods", score_health = "Health",
         score_food_retail = "Food retail", score_education = "Education", score_recreation = "Recreation",
         score = "Composite")
plot_dat <- res %>%
  select(variable, queen = I_queen, knn = I_knn) %>%
  pivot_longer(-variable, names_to = "weights", values_to = "I") %>%
  mutate(variable = factor(LAB[variable], levels = rev(LAB)))
p <- ggplot(plot_dat, aes(I, variable, colour = weights)) +
  geom_vline(xintercept = 0, colour = INK2, linewidth = 0.3) +
  geom_point(size = 2.2) +
  scale_colour_manual(values = c(queen = PAL_CAT[1], knn = PAL_CAT[2]),
                      labels = c(queen = "queen contiguity", knn = paste0("k = 6 nearest")), name = NULL) +
  labs(title = if (all(res$p_queen < ALPHA))
                 "Every category's access score clusters in space" else
                 "Not every category's access score clusters in space",
       subtitle = sprintf("Global Moran's I over %d residential subzones, %d permutations; largest p = %.3f.",
                          nrow(sz), NSIM, max(c(res$p_queen, res$p_knn))),
       x = "Moran's I", y = NULL) +
  theme_project()
save_fig(p, "q1_morans_i.png", width = 6.6, height = 3.4)

log_step("Moran's I (queen): ", paste0(LAB[res$variable], " ", round(res$I_queen, 2), collapse = ", "))
