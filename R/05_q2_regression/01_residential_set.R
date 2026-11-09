# 05_q2_regression/01_residential_set.R -----------------------------------------
# H2: which subzones have enough residents for a score to mean something. Every
# analysis (Q1 weights, Q2 models, Q3 clusters) runs on these rows. The cut-off
# is decision 2 (RES_MIN_POP); n at the second cut-off is reported alongside so
# the choice is visible.

source("R/00_setup.R")

census <- read_csv(file.path(DIR_PROC, "census2020_subzone.csv"), show_col_types = FALSE)

res <- census %>%
  transmute(subzone_c, pop, residential = pop >= RES_MIN_POP)

stopifnot(nrow(res) == 332, !anyDuplicated(res$subzone_c), !anyNA(res$residential))

n_tab <- tibble(
  cut_off = c(RES_MIN_POP, RES_MIN_POP_ALT),
  n_residential = c(sum(census$pop >= RES_MIN_POP), sum(census$pop >= RES_MIN_POP_ALT)),
  share_of_residents = c(sum(census$pop[census$pop >= RES_MIN_POP]),
                         sum(census$pop[census$pop >= RES_MIN_POP_ALT])) / sum(census$pop)
)

write_csv(res, file.path(DIR_PROC, "residential_set.csv"))
write_csv(n_tab %>% mutate(share_of_residents = round(share_of_residents, 4)),
          file.path(DIR_TAB, "q2_residential_n.csv"))
log_step("residential_set.csv: ", sum(res$residential), " of 332 subzones at >= ", RES_MIN_POP,
         " residents (", round(100 * n_tab$share_of_residents[1], 2), "% of residents); ",
         n_tab$n_residential[2], " at >= ", RES_MIN_POP_ALT)
