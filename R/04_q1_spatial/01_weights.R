# 04_q1_spatial/01_weights.R ----------------------------------------------------
# H3 part 1: who counts as a neighbour, on the residential set only (H2). Queen
# contiguity is the main rule (Lecture 8); the k = 6 nearest subzones, measured
# between points on each polygon's surface (a centroid can fall outside an
# L-shaped subzone), is the check.
# Dropping non-residential subzones punches holes in the map, so weights are
# built after the filter, and any subzone left with no neighbour is linked to
# its nearest residential subzone rather than dropped.

source("R/00_setup.R")
library(spdep)

score <- readRDS(file.path(DIR_PROC, "score_subzone.rds"))
res   <- read_csv(file.path(DIR_PROC, "residential_set.csv"), show_col_types = FALSE)

K_NN    <- 6
SNAP_M  <- 1     # MP19 polygons leave sub-metre slivers between neighbours

sz <- score %>% select(subzone_c) %>%
  inner_join(res %>% filter(residential) %>% select(subzone_c), by = "subzone_c") %>%
  arrange(subzone_c)

# --- queen contiguity --------------------------------------------------------

link_islands <- function(nb, xy) {
  isl <- which(card(nb) == 0)
  for (i in isl) {
    d <- sqrt(colSums((t(xy) - xy[i, ])^2)); d[i] <- Inf
    j <- which.min(d)
    nb[[i]] <- sort(unique(c(setdiff(nb[[i]], 0L), j)))
    nb[[j]] <- sort(unique(c(setdiff(nb[[j]], 0L), i)))
  }
  nb
}

xy <- st_coordinates(st_point_on_surface(st_geometry(sz)))
nb_queen <- poly2nb(sz, queen = TRUE, snap = SNAP_M)
n_islands <- sum(card(nb_queen) == 0)
nb_queen <- link_islands(nb_queen, xy)
lw_queen <- nb2listw(nb_queen, style = "W")

# --- k nearest neighbours (check) --------------------------------------------

nb_knn <- make.sym.nb(knn2nb(knearneigh(xy, k = K_NN)))
lw_knn <- nb2listw(nb_knn, style = "W")

summ <- tibble(
  weights = c("queen", paste0("knn", K_NN)),
  n = length(nb_queen),
  mean_links = c(mean(card(nb_queen)), mean(card(nb_knn))),
  min_links = c(min(card(nb_queen)), min(card(nb_knn))),
  components = c(n.comp.nb(nb_queen)$nc, n.comp.nb(nb_knn)$nc),
  islands_linked = c(n_islands, 0L)
)

saveRDS(list(subzone_c = sz$subzone_c, nb_queen = nb_queen, lw_queen = lw_queen,
             nb_knn = nb_knn, lw_knn = lw_knn),
        file.path(DIR_PROC, "q1_neighbours.rds"))
write_csv(summ %>% mutate(mean_links = round(mean_links, 2)), file.path(DIR_TAB, "q1_weights_summary.csv"))
log_step("q1_neighbours.rds: ", nrow(sz), " residential subzones; queen mean ",
         round(summ$mean_links[1], 2), " links, ", n_islands, " islands linked to nearest, ",
         summ$components[1], " component(s); knn", K_NN, " ", summ$components[2], " component(s)")
