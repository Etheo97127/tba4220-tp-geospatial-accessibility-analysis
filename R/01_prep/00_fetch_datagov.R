# 01_prep/00_fetch_datagov.R ----------------------------------------------------
# Download the data.gov.sg inputs into data/input/raw/sg/. Not part of run_all.R: raw
# files are committed so everyone works on the same snapshot, and this script is
# the record of where each came from. Files already on disk are never replaced;
# delete one by hand to refetch it, then update its row in docs/data_log.md.
#
#   Rscript R/01_prep/00_fetch_datagov.R

source("R/00_setup.R")

# file under data/input/raw/sg/  ->  data.gov.sg dataset id
DATAGOV <- c(
  mp19_subzone.geojson          = "d_8594ae9ff96d0c708bc2af633048edfb",
  mp19_rail_station.geojson     = "d_8d886e3a83934d7447acdf5bc6959999",
  census2020_age.csv            = "d_d95ae740c0f8961a0b10435836660ce0",
  census2020_dwelling.csv       = "d_7f243956483d5901f237e6f87b096636",
  hes_quinquennial.csv          = "d_7a24e1f85969c45ad68a89f7acf4e7a8",
  childcare_services.geojson    = "d_5d668e3f544335f8028f546827b773b4",
  kindergartens.geojson         = "d_7fe9a72b1afff18e48111772c8d0fd39",
  preschools_location.geojson   = "d_61eefab99958fd70e6aab17320a71f1c",
  chas_clinics.geojson          = "d_548c33ea2d99e29ec63a7cc9edcccedc",
  moh_health_fac.csv            = "d_e4663ad3f088a46dabd3972dc166402d"
)

API <- "https://api-open.data.gov.sg/v1/public/api/datasets/%s/poll-download"

# poll-download returns a short-lived signed S3 URL; large tables can need a
# few polls before the export is ready. The API rate-limits anonymous callers
# (HTTP 429) after two or three quick requests, so back off and retry.
fetch_datagov <- function(file, id, tries = 8) {
  dest <- file.path(DIR_RAW, file)
  if (file.exists(dest)) return(invisible(FALSE))
  res <- NULL
  for (k in seq_len(tries)) {
    res <- tryCatch(fromJSON(sprintf(API, id)), error = function(e) NULL)
    if (!is.null(res) && res$code == 0 && !is.null(res$data$url)) break
    Sys.sleep(5 * k)
  }
  if (is.null(res$data$url)) stop("no download URL for ", id)
  download.file(res$data$url, dest, mode = "wb", quiet = TRUE)
  log_step(file, ": ", file.size(dest), " B, md5 ", tools::md5sum(dest),
           ", downloaded ", format(Sys.Date()))
  Sys.sleep(5)
  invisible(TRUE)
}

for (f in names(DATAGOV)) fetch_datagov(f, DATAGOV[[f]])
log_step("data.gov.sg files present: ", sum(file.exists(file.path(DIR_RAW, names(DATAGOV)))),
         " of ", length(DATAGOV))
