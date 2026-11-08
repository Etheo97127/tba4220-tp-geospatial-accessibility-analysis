# 06_q3_typology/04_tests.R -----------------------------------------------------
# D4, H0(a): the mix of types is the same in mature and non-mature towns.
# Statistic: chi-square of type x town group. Maturity is set by planning area
# and blocks start as planning areas, so labels are permuted between whole
# blocks (decision 12); shuffling inside a block would change nothing. Excluded
# areas are left out (decision 6). The textbook chi-square p is not used:
# neighbouring subzones are not independent.
# D5, H0(b): type membership is unrelated to Q2's residuals. Statistic: F from
# anova(lm(residual ~ type)); residuals permuted within blocks (decision 5).

source("R/00_setup.R")

inp <- readRDS(file.path(DIR_INT, "q3_inputs.rds"))
cl  <- read_csv(file.path(DIR_PROC, "q3_clusters.csv"), show_col_types = FALSE)

N_PERM <- 999

dat <- inp$data %>% select(subzone_c, block_id, maturity, residual) %>%
  left_join(cl %>% select(subzone_c, cluster), by = "subzone_c") %>%
  mutate(cluster = factor(cluster))

perm_p <- function(observed, permuted) (1 + sum(permuted >= observed)) / (1 + length(permuted))

# --- D4: type mix vs town group ----------------------------------------------

grp <- dat %>% filter(maturity %in% c("mature", "non-mature"))
block_label <- grp %>% distinct(block_id, maturity)
stopifnot(!anyDuplicated(block_label$block_id))   # one label per block

chisq_stat <- function(type, group) suppressWarnings(unname(chisq.test(table(type, group), correct = FALSE)$statistic))

obs_a <- chisq_stat(grp$cluster, grp$maturity)
set.seed(SEED)
perm_a <- replicate(N_PERM, {
  shuffled <- setNames(sample(block_label$maturity), block_label$block_id)
  chisq_stat(grp$cluster, shuffled[grp$block_id])
})

mix <- grp %>% count(maturity, cluster) %>% group_by(maturity) %>%
  mutate(share = n / sum(n)) %>% ungroup()

# --- D5: type vs Q2 residual -------------------------------------------------

f_stat <- function(resid, type) anova(lm(resid ~ type))$`F value`[1]

obs_b <- f_stat(dat$residual, dat$cluster)
set.seed(SEED)
perm_b <- replicate(N_PERM, {
  r <- dat$residual
  for (b in unique(dat$block_id)) {
    i <- which(dat$block_id == b)
    r[i] <- r[i][sample.int(length(i))]
  }
  f_stat(r, dat$cluster)
})

resid_by_type <- dat %>% group_by(cluster) %>%
  summarise(n = n(), mean_residual = mean(residual), .groups = "drop")

tests <- tibble(
  hypothesis = c("H0(a): type mix same in mature and non-mature towns",
                 "H0(b): type unrelated to Q2 residual"),
  statistic = c("chi-square", "F"), observed = c(obs_a, obs_b),
  permutation = c("town labels between whole blocks", "residuals within blocks"),
  n_perm = N_PERM, n_subzones = c(nrow(grp), nrow(dat)),
  p_value = c(perm_p(obs_a, perm_a), perm_p(obs_b, perm_b))
)

write_csv(tests %>% mutate(observed = round(observed, 3), p_value = round(p_value, 3)), file.path(DIR_TAB, "q3_tests.csv"))
write_csv(mix %>% mutate(share = round(share, 3)), file.path(DIR_TAB, "q3_type_mix.csv"))
write_csv(resid_by_type %>% mutate(mean_residual = round(mean_residual, 3)), file.path(DIR_TAB, "q3_residual_by_type.csv"))
log_step("H0(a) chi-square ", round(obs_a, 2), ", p = ", round(tests$p_value[1], 3),
         "; H0(b) F ", round(obs_b, 2), ", p = ", round(tests$p_value[2], 3))
