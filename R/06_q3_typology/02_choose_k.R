# 06_q3_typology/02_choose_k.R --------------------------------------------------
# How many kinds of neighbourhood? k-means (nstart 50, so a bad random start
# cannot decide it) for k = 2..8, scored by within-cluster sum of squares (elbow)
# and mean silhouette. The rule: k = the highest mean silhouette. First the same
# code must recover three known groups in simulated data, or the pipeline is not
# trusted on the real scores.
# Silhouette always picks some k >= 2, even in data with no groups at all, so the
# chosen split is tested against a null: N_NULL single Gaussian clouds with the
# real scores' covariance (one continuum, no types), scored by the same
# max-silhouette rule. If the real maximum is not above the null's, the result is
# one access gradient cut at k, not k discrete kinds of neighbourhood.

source("R/00_setup.R")
library(cluster)
library(MASS, include.only = "mvrnorm")
library(ggplot2)

inp <- readRDS(file.path(DIR_INT, "q3_inputs.rds"))

K_RANGE <- 2:8
NSTART  <- 50
N_NULL  <- 200

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

# Max silhouette over K_RANGE for n_null Gaussian clouds with X's covariance.
# Every null dataset is drawn first: fit_k() resets the seed, which inside the
# loop would make each draw identical.
null_silhouettes <- function(X, n_null) {
  set.seed(SEED)
  sets <- lapply(seq_len(n_null), function(i) mvrnorm(nrow(X), mu = colMeans(X), Sigma = cov(X)))
  vapply(sets, function(Z) max(score_k(Z)$silhouette), numeric(1))
}

# --- check on simulated data with three known groups -------------------------

set.seed(SEED)
centres_sim <- matrix(c(2, 2, 2, 0, 0, 0,  -2, -2, 0, 2, 0, -2,  0, 0, -2, -2, 2, 2), nrow = 3, byrow = TRUE)
X_sim <- do.call(rbind, lapply(1:3, function(g) sweep(matrix(rnorm(67 * 6, sd = 0.7), ncol = 6), 2, centres_sim[g, ], "+")))
sim <- score_k(X_sim)
sim_null <- null_silhouettes(X_sim, 50)
stopifnot(sim$k[which.max(sim$silhouette)] == 3, max(sim$silhouette) > max(sim_null))
log_step("simulation check passed: silhouette picks k = 3 on three planted groups, and beats all 50 null clouds")

# --- real scores -------------------------------------------------------------

grid <- score_k(inp$X)
k_best <- grid$k[which.max(grid$silhouette)]

# --- null reference: no cluster structure ------------------------------------

null_max <- null_silhouettes(inp$X, N_NULL)
obs_max <- max(grid$silhouette)
p_null  <- (1 + sum(null_max >= obs_max)) / (1 + N_NULL)
structure_verdict <- if (p_null < ALPHA) "discrete types" else "one gradient"
null_tab <- tibble(k_chosen = k_best, observed_max_silhouette = obs_max,
                   null_mean = mean(null_max), null_q95 = unname(quantile(null_max, 0.95)),
                   n_null = N_NULL, p_value = p_null, structure = structure_verdict)

write_csv(grid %>% mutate(wss = round(wss, 1), silhouette = round(silhouette, 3)),
          file.path(DIR_TAB, "q3_choose_k.csv"))
write_csv(null_tab %>% mutate(across(where(is.numeric), ~ round(.x, 3))), file.path(DIR_TAB, "q3_null_test.csv"))
saveRDS(list(k = k_best, grid = grid, structure = structure_verdict, p_null = p_null), file.path(DIR_INT, "q3_k.rds"))

plot_dat <- grid %>% pivot_longer(c(wss, silhouette), names_to = "measure") %>%
  mutate(measure = factor(measure, c("wss", "silhouette"),
                          c("Within-cluster sum of squares (elbow)", "Mean silhouette (higher is better)")))
p <- ggplot(plot_dat, aes(k, value)) +
  geom_line(colour = PAL_CAT[1]) + geom_point(colour = PAL_CAT[1], size = 2) +
  geom_vline(xintercept = k_best, colour = PAL_CAT[2], linetype = "22") +
  facet_wrap(~measure, scales = "free_y") +
  scale_x_continuous(breaks = K_RANGE) +
  labs(title = if (structure_verdict == "discrete types")
                 sprintf("k = %d neighbourhood types, more distinct than chance (p = %.3f)", k_best, p_null) else
                 sprintf("No evidence of discrete types: k = %d is a cut through one gradient (p = %.2f)", k_best, p_null),
       subtitle = sprintf("k-means on %d residential subzones, six z-scored category scores (%s), nstart = %d.",
                          nrow(inp$X), inp$scores_used, NSTART),
       x = "number of types k", y = NULL) +
  theme_project()
save_fig(p, "q3_choose_k.png", width = 7.2, height = 3.2)
log_step("k chosen: ", k_best, " (silhouette ", round(obs_max, 3), "); null max silhouette mean ",
         round(mean(null_max), 3), ", 95th pct ", round(null_tab$null_q95, 3), "; p = ", round(p_null, 3),
         " -> ", structure_verdict)
