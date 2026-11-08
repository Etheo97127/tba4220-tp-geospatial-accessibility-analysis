# 06_q3_typology/02_choose_k.R --------------------------------------------------
# How many kinds of neighbourhood? k-means (nstart 50, so a bad random start
# cannot decide it) for k = 2..8, scored by within-cluster sum of squares (elbow)
# and mean silhouette. The rule, fixed before looking: k = the highest mean
# silhouette. First the same code must recover three known groups in simulated
# data, or the pipeline is not trusted on the real scores.

source("R/00_setup.R")
library(cluster)
library(ggplot2)

inp <- readRDS(file.path(DIR_INT, "q3_inputs.rds"))

K_RANGE <- 2:8
NSTART  <- 50

fit_k <- function(X, k) {
  set.seed(SEED)
  kmeans(X, centers = k, nstart = NSTART, iter.max = 100)
}

score_k <- function(X) {
  d <- dist(X)
  bind_rows(lapply(K_RANGE, function(k) {
    km <- fit_k(X, k)
    tibble(k = k, wss = km$tot.withinss,
           silhouette = mean(silhouette(km$cluster, d)[, "sil_width"]))
  }))
}

# --- check on simulated data with three known groups -------------------------

set.seed(SEED)
centres_sim <- matrix(c(2, 2, 2, 0, 0, 0,  -2, -2, 0, 2, 0, -2,  0, 0, -2, -2, 2, 2), nrow = 3, byrow = TRUE)
X_sim <- do.call(rbind, lapply(1:3, function(g) sweep(matrix(rnorm(67 * 6, sd = 0.7), ncol = 6), 2, centres_sim[g, ], "+")))
sim <- score_k(X_sim)
stopifnot(sim$k[which.max(sim$silhouette)] == 3)
log_step("simulation check passed: silhouette picks k = 3 on three planted groups")

# --- real scores -------------------------------------------------------------

grid <- score_k(inp$X)
k_best <- grid$k[which.max(grid$silhouette)]

write_csv(grid %>% mutate(wss = round(wss, 1), silhouette = round(silhouette, 3)),
          file.path(DIR_TAB, "q3_choose_k.csv"))
saveRDS(list(k = k_best, grid = grid), file.path(DIR_INT, "q3_k.rds"))

plot_dat <- grid %>% pivot_longer(c(wss, silhouette), names_to = "measure") %>%
  mutate(measure = factor(measure, c("wss", "silhouette"),
                          c("Within-cluster sum of squares (elbow)", "Mean silhouette (higher is better)")))
p <- ggplot(plot_dat, aes(k, value)) +
  geom_line(colour = PAL_CAT[1]) + geom_point(colour = PAL_CAT[1], size = 2) +
  geom_vline(xintercept = k_best, colour = PAL_CAT[2], linetype = "22") +
  facet_wrap(~measure, scales = "free_y") +
  scale_x_continuous(breaks = K_RANGE) +
  labs(title = sprintf("k = %d neighbourhood types by the silhouette rule", k_best),
       subtitle = sprintf("k-means on %d residential subzones, six z-scored category scores (%s), nstart = %d.",
                          nrow(inp$X), inp$scores_used, NSTART),
       x = "number of types k", y = NULL) +
  theme_project()
save_fig(p, "q3_choose_k.png", width = 7.2, height = 3.2)
log_step("k chosen: ", k_best, " (silhouette ", round(max(grid$silhouette), 3), "); silhouettes ",
         paste0(grid$k, ":", round(grid$silhouette, 2), collapse = " "))
