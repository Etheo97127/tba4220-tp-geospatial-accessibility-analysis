# report/scripts/helpers.R ------------------------------------------------------
# Readers and inline formatters shared by every report section. Sourced by
# report.Rmd's setup chunk, which knits from report/, so ROOT is the repo root.

ROOT <- normalizePath("..", winslash = "/")
OUT  <- file.path(ROOT, "data", "output")

fig  <- function(name) file.path(OUT, "figures", name)
tab  <- function(name) readr::read_csv(file.path(OUT, "tables", name), show_col_types = FALSE)
proc <- function(name) readr::read_csv(file.path(OUT, "processed", name), show_col_types = FALSE)
ext  <- function(name) readr::read_csv(file.path(ROOT, "data", "input", "external", name), show_col_types = FALSE)

# Inline formatting: pct(0.0971) -> "9.7%", num(1234.5) -> "1,235", p_fmt(0.0004) -> "< 0.001".
pct    <- function(x, d = 1) paste0(formatC(100 * x, format = "f", digits = d), "%")
num    <- function(x, d = 0) formatC(x, format = "f", digits = d, big.mark = ",")
p_fmt  <- function(p) ifelse(p < 0.001, "< 0.001", paste("=", formatC(p, format = "f", digits = 3)))
p_cell <- function(p) ifelse(p < 0.001, "< 0.001", formatC(p, format = "f", digits = 3))  # for table cells

# "a", "a and b", "a, b and c"
and_list <- function(x) if (length(x) < 2) x else paste(paste(x[-length(x)], collapse = ", "), "and", x[length(x)])

CAT_LAB <- c(food_services = "Food services", retail = "Retail goods", health = "Health",
             food_retail = "Food retail", education = "Education", recreation = "Recreation")

# A kable table with set relative column widths. Pandoc sizes a wide pipe table's
# columns by the length of its separator dashes, which kable makes as long as the
# longest cell, so short columns (codes, numbers) wrap one letter per line in
# Word. `widths` are relative shares; numeric-looking columns are right-aligned.
kable_w <- function(df, widths, caption) {
  out <- knitr::kable(df, format = "pipe", caption = caption)
  sep <- grep("^[|][-:|]+[|]$", out)[1]
  num_col <- vapply(df, function(x) all(grepl("^[-<≥ 0-9.,%]*$", as.character(x))), logical(1))
  dashes <- vapply(seq_along(widths), function(i) {
    d <- strrep("-", max(3, round(100 * widths[i] / sum(widths))))
    if (num_col[i]) paste0(d, ":") else paste0(":", d)
  }, character(1))
  out[sep] <- paste0("|", paste(dashes, collapse = "|"), "|")
  knitr::asis_output(paste(out, collapse = "\n"))
}
