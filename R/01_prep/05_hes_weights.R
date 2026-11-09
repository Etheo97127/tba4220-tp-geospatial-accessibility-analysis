# 01_prep/05_hes_weights.R ------------------------------------------------------
# The six category weights: each category's share of 2023 monthly household
# spending across the six, from the HES quinquennial series. A prep step so the
# score, Q2 and the report all read one hand-off instead of the raw file.

source("R/00_setup.R")

# "Retail goods" is the sum of two COICOP divisions, not a published line; say so
# in the report.
HES_LINES <- tribble(
  ~category,       ~line,
  "food_services", "Food And Beverage Serving Services",
  "retail",        "Clothing And Footwear",
  "retail",        "Furnishing, Household Equipment And Routine Household Maintenance",
  "health",        "Health",
  "food_retail",   "Food And Non-Alcoholic Beverages",
  "education",     "Education",
  "recreation",    "Recreation, Sport And Culture"
)
PROPOSAL_TOTAL <- 3138.2     # S$/month, the proposal's Table 2 total

hes <- read_csv(file.path(DIR_RAW, "hes_quinquennial.csv"), show_col_types = FALSE) %>%
  mutate(line = str_squish(DataSeries)) %>%
  select(line, sgd_month = `2023`)

weights <- HES_LINES %>%
  left_join(hes, by = "line") %>%
  group_by(category) %>%
  summarise(hes_lines = paste(line, collapse = " + "), sgd_month = round(sum(sgd_month), 1),
            .groups = "drop") %>%
  mutate(weight = sgd_month / sum(sgd_month)) %>%
  arrange(match(category, CATEGORIES))

stopifnot(!anyNA(weights$sgd_month), identical(weights$category, CATEGORIES),
          abs(sum(weights$sgd_month) - PROPOSAL_TOTAL) < 0.05)

write_csv(weights, file.path(DIR_PROC, "hes_weights.csv"))
log_step("hes_weights.csv: ", paste0(weights$category, " ", round(100 * weights$weight, 1), "%",
                                     collapse = ", "))
