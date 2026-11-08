# 04_q1_spatial/05_memo.R -------------------------------------------------------
# B6, the H6 memo to Q3: for each category, does it form contiguous regions
# (types will be spatially coherent) or concentrate below subzone scale (a few
# extreme subzones, which Q3 must read as outliers, not as a kind of
# neighbourhood)? The rule is fixed here, before Q3 runs:
#   contiguous   global I significant, and significant clusters (HH + LL) at
#                least twice the significant outliers (HL + LH)
#   concentrated outliers more than half the clusters
#   no pattern   global I not significant

source("R/00_setup.R")

morans <- read_csv(file.path(DIR_TAB, "q1_morans_i.csv"), show_col_types = FALSE)
lisa   <- read_csv(file.path(DIR_PROC, "q1_lisa.csv"), show_col_types = FALSE)

ALPHA <- 0.05

counts <- lisa %>%
  group_by(variable) %>%
  summarise(n_high_high = sum(cluster == "High-High"), n_low_low = sum(cluster == "Low-Low"),
            n_high_low  = sum(cluster == "High-Low"),  n_low_high = sum(cluster == "Low-High"),
            .groups = "drop")

memo <- morans %>%
  select(variable, I_queen, p_queen) %>%
  left_join(counts, by = "variable") %>%
  mutate(clusters = n_high_high + n_low_low, outliers = n_high_low + n_low_high,
         pattern = case_when(p_queen >= ALPHA            ~ "no pattern",
                             outliers > clusters / 2     ~ "concentrated",
                             TRUE                        ~ "contiguous"))

outliers <- lisa %>% filter(cluster %in% c("High-Low", "Low-High")) %>%
  select(variable, subzone_c, cluster)

write_csv(memo, file.path(DIR_TAB, "q1_memo.csv"))
write_csv(outliers, file.path(DIR_PROC, "q1_outliers.csv"))
log_step("H6 memo: ", paste0(memo$variable, " ", memo$pattern, collapse = "; "),
         ". Outlier subzones: ", nrow(outliers))
