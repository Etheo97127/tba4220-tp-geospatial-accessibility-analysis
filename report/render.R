# report/render.R ---------------------------------------------------------------
# Knit report/report.Rmd to Word. Run from the repo root after R/run_all.R:
#   Rscript report/render.R
# Rscript does not see the pandoc that RStudio bundles, so point rmarkdown at it
# when no system pandoc is on PATH. Word, not PDF: no LaTeX is needed, and the
# proposal was submitted as .docx.

RSTUDIO_PANDOC <- c("C:/Program Files/RStudio/resources/app/bin/quarto/bin/tools",
                    "/Applications/RStudio.app/Contents/Resources/app/quarto/bin/tools",
                    "/usr/lib/rstudio/resources/app/bin/quarto/bin/tools")

if (!rmarkdown::pandoc_available()) {
  found <- RSTUDIO_PANDOC[dir.exists(RSTUDIO_PANDOC)]
  if (!length(found)) stop("No pandoc found: install it or RStudio, or knit from RStudio.")
  Sys.setenv(RSTUDIO_PANDOC = found[1])
}

rmarkdown::render("report/report.Rmd", output_dir = "report", quiet = TRUE)
cat("Wrote report/report.docx\n")
