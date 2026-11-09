# 06_q3_typology/03_stability.R -------------------------------------------------
# D3: do the k types survive resampling? Spatial block bootstrap: draw whole
# blocks (H3) with replacement, refit k-means on the drawn subzones, match the
# new clusters one-to-one to the original ones (Hungarian, clue::solve_LSAP) on
# the subzones both contain, and record each original cluster's Jaccard
# overlap. Whole blocks, because neighbouring subzones are near-duplicates
# (Q1: every category is contiguous) and random resampling would overstate
# stability. Mean Jaccard >= 0.75 is stable; < 0.5 has dissolved.

source("R/00_setup.R")
library(clue)

inp  <- readRDS(file.path(DIR_INT, "q3_inputs.rds"))
kobj <- readRDS(file.path(DIR_INT, "q3_k.rds"))

N_BOOT  <- 200
NSTART  <- 50
STABLE  <- 0.75
DISSOLVED <- 0.5

X <- inp$X; blocks <- inp$data$block_id; k <- kobj$k

set.seed(SEED)
km0 <- kmeans(X, centers = k, nstart = NSTART, iter.max = 100)

jaccard <- function(a, b) length(intersect(a, b)) / length(union(a, b))

# One block-bootstrap draw: each reference cluster's best Jaccard match.
boot_once <- function(X, blocks, k, ref) {
  drawn <- sample(unique(blocks), replace = TRUE)
  rows <- unlist(lapply(drawn, function(b) which(blocks == b)))
  km <- kmeans(X[rows, , drop = FALSE], centers = k, nstart = NSTART, iter.max = 100)
  # Each subzone keeps its first assignment when its block was drawn twice.
  first <- !duplicated(rows)
  ids <- rows[first]; lab <- km$cluster[first]
  J <- outer(seq_len(k), seq_len(k), Vectorize(function(i, j)
    jaccard(intersect(which(ref == i), ids), ids[lab == j])))
  match <- solve_LSAP(J, maximum = TRUE)
  J[cbind(seq_len(k), as.integer(match))]
}

set.seed(SEED)
boot <- t(replicate(N_BOOT, boot_once(X, blocks, k, km0$cluster)))

stab <- tibble(cluster = seq_len(k), n_subzones = as.integer(table(km0$cluster)),
               mean_jaccard = colMeans(boot), sd_jaccard = apply(boot, 2, sd)) %>%
  mutate(verdict = case_when(mean_jaccard >= STABLE ~ "stable",
                             mean_jaccard < DISSOLVED ~ "dissolved",
                             TRUE ~ "unstable"))

clusters <- tibble(subzone_c = inp$data$subzone_c, cluster = km0$cluster) %>%
  left_join(stab %>% select(cluster, verdict), by = "cluster") %>%
  transmute(subzone_c, cluster, stable = verdict == "stable")

saveRDS(km0, file.path(DIR_INT, "q3_kmeans.rds"))
write_csv(clusters, file.path(DIR_PROC, "q3_clusters.csv"))
write_csv(stab %>% mutate(across(c(mean_jaccard, sd_jaccard), ~ round(.x, 3))), file.path(DIR_TAB, "q3_stability.csv"))
log_step("k = ", k, " types, ", N_BOOT, " block-bootstrap draws: ",
         paste0("type ", stab$cluster, " (n = ", stab$n_subzones, ") Jaccard ", round(stab$mean_jaccard, 2),
                " ", stab$verdict, collapse = "; "))
