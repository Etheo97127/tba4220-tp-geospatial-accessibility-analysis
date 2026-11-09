# report/scripts/results_q3.R ---------------------------------------------------
# Values the Q3 parts of Methods and Analysis and the Conclusions quote: the k
# choice and its no-cluster null, stability, the two block tests, and what the
# town-group test leaves out.

ck    <- tab("q3_choose_k.csv")
nul   <- tab("q3_null_test.csv")
stab  <- tab("q3_stability.csv")
tests <- tab("q3_tests.csv")
mix   <- tab("q3_type_mix.csv")
types <- tab("q3_types.csv")
rbt   <- tab("q3_residual_by_type.csv")

k     <- nul$k_chosen
sil_k <- ck$silhouette[ck$k == k]; sil_3 <- ck$silhouette[ck$k == 3]
ta    <- tests[grepl("H0\\(a\\)", tests$hypothesis), ]
tb    <- tests[grepl("H0\\(b\\)", tests$hypothesis), ]
share <- function(m, cl) mix$share[mix$maturity == m & mix$cluster == cl]
low   <- types$cluster[grepl("^Low", types$name)]
high  <- types$cluster[grepl("^High", types$name)]
prof  <- tab("q3_profiles.csv") %>% filter(cluster == low)

# Share of variance on the first principal component of the six category scores.
sc_cat <- score %>% st_drop_geometry() %>% filter(residential)
pc1    <- summary(prcomp(scale(sc_cat[paste0("score_", names(CAT_LAB))])))$importance[2, 1]

# Blocks that carry a town label are the units H0(a) permutes.
mat_ext <- ext("town_maturity.csv")
n_lab_blocks <- proc("q1_blocks.csv") %>%
  left_join(proc("census2020_subzone.csv") %>% select(subzone_c, pln_area_n), by = "subzone_c") %>%
  left_join(mat_ext %>% select(pln_area_n, maturity), by = "pln_area_n") %>%
  filter(maturity %in% c("mature", "non-mature")) %>% distinct(block_id) %>% nrow()

# What H0(a) leaves out: the Central Area (mature in HDB's list, excluded by
# design), private Tanglin and non-town areas.
res_pa <- proc("residential_set.csv") %>% filter(residential) %>% select(subzone_c) %>%
  left_join(proc("census2020_subzone.csv") %>% select(subzone_c, pln_area_n, pop, dw_hdb, dw_total), by = "subzone_c") %>%
  left_join(mat_ext %>% select(pln_area_n, maturity, note), by = "pln_area_n") %>%
  mutate(central = maturity == "excluded" & grepl("Central Area", note))
excl <- res_pa %>% filter(maturity == "excluded")
hdb_central <- res_pa %>% filter(central) %>% group_by(pln_area_n) %>%
  summarise(hdb = sum(dw_hdb) / sum(dw_total), .groups = "drop") %>% filter(hdb > 0.5) %>%
  pull(pln_area_n) %>% tolower() %>% tools::toTitleCase()
hh_comp <- proc("q1_lisa.csv") %>% filter(variable == "score", cluster == "High-High")
