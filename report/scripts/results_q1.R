# report/scripts/results_q1.R ---------------------------------------------------
# Values the Q1 parts of Methods and Analysis quote: the neighbour network,
# global Moran's I and where the LISA hot spots fall, by planning area.

mi    <- tab("q1_morans_i.csv")
memo  <- tab("q1_memo.csv")
wsum  <- tab("q1_weights_summary.csv")
bsz   <- tab("q1_block_sizes.csv")
comp  <- memo %>% filter(variable == "score")

# Hot spots are reported for the city centre and the north-east, where OSM maps
# preschools best; the rest are listed by town.
CENTRE <- c("ROCHOR", "KALLANG", "OUTRAM")
NE     <- c("SENGKANG", "PUNGGOL", "HOUGANG")
miss_rate <- function(d) sum(d$n_missed) / sum(d$n_ref)
ne_miss  <- miss_rate(qflag %>% filter(pln_area_n %in% NE))
all_miss <- miss_rate(qflag)

hh <- proc("q1_lisa.csv") %>% filter(cluster == "High-High") %>%
  left_join(proc("census2020_subzone.csv") %>% select(subzone_c, pln_area_n), by = "subzone_c") %>%
  mutate(town = tools::toTitleCase(tolower(pln_area_n)))
map_lab      <- function(v) ifelse(v == "score", "the composite", tolower(CAT_LAB[sub("^score_", "", v)]))
towns_by_map <- function(d) d %>% group_by(variable) %>%
  summarise(towns = and_list(sort(unique(town))), .groups = "drop")

n_centre  <- n_distinct(hh$variable[hh$pln_area_n %in% CENTRE])
centre_tw <- and_list(sort(unique(hh$town[hh$pln_area_n %in% CENTRE])))
ne_txt    <- towns_by_map(hh %>% filter(pln_area_n %in% NE)) %>%
  with(paste(map_lab(variable), "in", towns, collapse = "; "))
other_txt <- towns_by_map(hh %>% filter(!pln_area_n %in% c(CENTRE, NE))) %>%
  with(paste0(tools::toTitleCase(map_lab(variable)), " also has one in ", towns, ".", collapse = " "))
