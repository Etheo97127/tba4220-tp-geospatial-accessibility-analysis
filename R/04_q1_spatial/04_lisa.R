# 04_q1_spatial/04_lisa.R -------------------------------------------------------
# B5: local Moran's I (LISA) for each category and the composite, on queen
# weights. Conditional-permutation p-values (LISA_NSIM = 9,999 draws) are
# corrected with Benjamini-Hochberg across the subzones of each map (decision 8);
# Gi* is not run (decision 10) because it repeats LISA's clusters and cannot show
# the High-Low / Low-High outliers Q3 needs. Labels follow the Moran-scatterplot
# quadrant of each significant subzone.

source("R/00_setup.R")
library(spdep)
library(ggplot2)

score <- readRDS(file.path(DIR_PROC, "score_subzone.rds"))
nbobj <- readRDS(file.path(DIR_PROC, "q1_neighbours.rds"))

VARS  <- c(paste0("score_", CATEGORIES), "score")
LAB   <- c(score_food_services = "Food services", score_retail = "Retail goods", score_health = "Health",
           score_food_retail = "Food retail", score_education = "Education", score_recreation = "Recreation",
           score = "Composite")
CLUSTER_COL <- c("High-High" = PAL_DIV[["high"]], "Low-Low" = PAL_DIV[["low"]],
                 "High-Low" = "#f6ad55", "Low-High" = "#90cdf4", "not significant" = "#f2f1ee")

sz <- tibble(subzone_c = nbobj$subzone_c) %>% left_join(st_drop_geometry(score), by = "subzone_c")
stopifnot(identical(sz$subzone_c, nbobj$subzone_c))

lisa_one <- function(x, lw, var) {
  set.seed(SEED)
  loc <- localmoran_perm(x, lw, nsim = LISA_NSIM, alternative = "two.sided")
  quad <- as.character(attr(loc, "quadr")$mean)          # "High-High", "Low-Low", ...
  p <- loc[, "Pr(z != E(Ii)) Sim"]
  p_bh <- p.adjust(p, method = "BH")
  tibble(subzone_c = nbobj$subzone_c, variable = var, Ii = loc[, "Ii"], p_sim = p, p_bh = p_bh,
         quadrant = quad, cluster = if_else(p_bh < FDR_Q, quad, "not significant"))
}

lisa <- bind_rows(lapply(VARS, function(v) lisa_one(sz[[v]], nbobj$lw_queen, v)))

counts <- lisa %>% count(variable, cluster) %>%
  pivot_wider(names_from = cluster, values_from = n, values_fill = 0)

write_csv(lisa %>% mutate(across(c(Ii, p_sim, p_bh), ~ round(.x, 4))), file.path(DIR_PROC, "q1_lisa.csv"))
write_csv(counts, file.path(DIR_TAB, "q1_lisa_counts.csv"))

map_dat <- score %>% select(subzone_c) %>%
  left_join(lisa, by = "subzone_c", relationship = "one-to-many") %>%
  filter(!is.na(variable)) %>%
  mutate(panel = factor(LAB[variable], levels = LAB),
         cluster = factor(cluster, levels = names(CLUSTER_COL)))
p <- ggplot() +
  geom_sf(data = score, fill = GREY_NA, colour = NA) +
  geom_sf(data = map_dat, aes(fill = cluster), colour = NA) +
  facet_wrap(~panel, ncol = 4) +
  scale_fill_manual(values = CLUSTER_COL, drop = FALSE, name = NULL) +
  labs(title = if (any(lisa$cluster %in% c("High-Low", "Low-High")))
                 "Where access clusters, and the subzones that break the pattern" else
                 "Access clusters in a few hot spots; no subzone breaks its neighbours' pattern",
       subtitle = sprintf("LISA on queen weights, %d permutations, Benjamini-Hochberg q < %.2f. Grey: non-residential.",
                          LISA_NSIM, FDR_Q)) +
  theme_map() + theme(legend.position = "bottom")
save_fig(p, "q1_lisa_maps.png", width = 7.8, height = 4.6)

sig <- lisa %>% filter(variable == "score", cluster != "not significant") %>% count(cluster)
log_step("LISA composite: ", paste0(sig$cluster, " ", sig$n, collapse = ", "))
