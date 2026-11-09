# 04_q1_spatial/02_blocks.R -----------------------------------------------------
# H3 part 2: spatial blocks for Q3's bootstrap and permutations. Blocks start as
# planning areas. A block with fewer than MIN_BLOCK residential subzones is merged
# into the neighbouring block it shares the most queen links with, so resampling
# whole blocks keeps near-duplicate neighbours together without tiny blocks
# dominating the draw.

source("R/00_setup.R")
library(spdep)

nbobj <- readRDS(file.path(DIR_PROC, "q1_neighbours.rds"))
pa    <- read_csv(file.path(DIR_PROC, "census2020_subzone.csv"), show_col_types = FALSE) %>%
  select(subzone_c, pln_area_n)

MIN_BLOCK <- 3

blocks <- tibble(subzone_c = nbobj$subzone_c) %>%
  left_join(pa, by = "subzone_c") %>%
  mutate(block_id = pln_area_n)
stopifnot(!anyNA(blocks$block_id))

# Merge the smallest undersized block first, repeat until none is left.
merge_small_blocks <- function(block_id, nb, min_size) {
  repeat {
    size <- table(block_id)
    small <- names(size)[size < min_size]
    if (!length(small)) return(block_id)
    b <- small[which.min(size[small])]
    members <- which(block_id == b)
    nbr_blocks <- block_id[unlist(nb[members])]
    nbr_blocks <- nbr_blocks[nbr_blocks != b]
    target <- names(sort(table(nbr_blocks), decreasing = TRUE))[1]
    block_id[members] <- target
  }
}

blocks$block_id <- merge_small_blocks(blocks$block_id, nbobj$nb_queen, MIN_BLOCK)
merged <- blocks %>% filter(block_id != pln_area_n) %>% distinct(pln_area_n, block_id)

sizes <- blocks %>% count(block_id, name = "n_subzones") %>% arrange(n_subzones)

write_csv(blocks %>% select(subzone_c, block_id), file.path(DIR_PROC, "q1_blocks.csv"))
write_csv(sizes, file.path(DIR_TAB, "q1_block_sizes.csv"))
log_step("q1_blocks.csv: ", nrow(blocks), " subzones in ", nrow(sizes), " blocks (sizes ",
         min(sizes$n_subzones), "-", max(sizes$n_subzones), ", median ", median(sizes$n_subzones),
         "); merged: ", if (nrow(merged)) paste(merged$pln_area_n, "->", merged$block_id, collapse = "; ") else "none")
