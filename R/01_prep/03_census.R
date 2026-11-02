# 01_prep/03_census.R -----------------------------------------------------------
# Census 2020 by subzone: residents, residents aged 65+, and residents by type of
# dwelling, keyed by subzone_c. Raw counts only -- C2 turns them into elderly
# share and housing mix, and C1 applies the residential cut-off (H2).
#
# The SingStat tables list subzones by *name* under a "<Planning Area> - Total"
# header row, show zero as "-", and round to tens. Join to MP19 on planning area
# + upper-cased subzone name, and stop if anything fails to match.

source("R/00_setup.R")

subzones <- readRDS(file.path(DIR_INT, "subzones.rds")) %>% st_drop_geometry()

read_census <- function(file) {
  x <- read_csv(file.path(DIR_RAW, file), col_types = cols(.default = "c"))
  names(x)[1] <- "label"
  x <- x %>%
    filter(label != "Total") %>%
    mutate(is_pa = str_detect(label, "\\s*-\\s*Total$"),       # "Ang Mo Kio - Total", "Changi- Total"
           pln_area_n = if_else(is_pa, str_to_upper(str_remove(label, "\\s*-\\s*Total$")), NA_character_)) %>%
    fill(pln_area_n) %>%
    filter(!is_pa) %>%
    mutate(subzone_n = str_to_upper(str_squish(label))) %>%
    select(-label, -is_pa)
  x %>% mutate(across(-c(pln_area_n, subzone_n),
                      ~ as.numeric(if_else(.x %in% c("-", ""), "0", str_remove_all(.x, ",")))))
}

age <- read_census("census2020_age.csv")
dwl <- read_census("census2020_dwelling.csv")

census <- age %>%
  transmute(pln_area_n, subzone_n,
            pop        = Total_Total,
            pop_65plus = Total_65_69 + Total_70_74 + Total_75_79 + Total_80_84 +
                         Total_85_89 + Total_90andOver) %>%
  full_join(dwl %>% transmute(pln_area_n, subzone_n,
                              dw_total        = Total,
                              dw_hdb          = HDBDwellings_Total,
                              dw_hdb_1_2room  = HDBDwellings_1_and2_RoomFlats1,
                              dw_hdb_3room    = HDBDwellings_3_RoomFlats,
                              dw_hdb_4room    = HDBDwellings_4_RoomFlats,
                              dw_hdb_5room_ec = HDBDwellings_5_RoomandExecutiveFlats,
                              dw_condo        = CondominiumsandOtherApartments,
                              dw_landed       = LandedProperties,
                              dw_other        = Others),
            by = c("pln_area_n", "subzone_n"))

joined <- subzones %>%
  select(subzone_c, subzone_n, pln_area_n) %>%
  left_join(census, by = c("pln_area_n", "subzone_n"))

unmatched_mp19   <- joined %>% filter(is.na(pop))
unmatched_census <- census %>% anti_join(subzones, by = c("pln_area_n", "subzone_n"))
if (nrow(unmatched_mp19) || nrow(unmatched_census)) {
  print(unmatched_mp19 %>% select(subzone_c, pln_area_n, subzone_n))
  print(unmatched_census %>% select(pln_area_n, subzone_n))
  stop("Census and MP19 subzone names do not line up; see above.")
}

# The two tables should agree on residents per subzone (both are resident counts).
off <- sum(abs(joined$pop - joined$dw_total) > 10)
log_step("subzones where age and dwelling totals differ by > 10: ", off)

write_csv(joined %>% select(-subzone_n, -pln_area_n), file.path(DIR_PROC, "census2020_subzone.csv"))
log_step("census2020_subzone.csv: ", nrow(joined), " subzones, ",
         format(sum(joined$pop), big.mark = ","), " residents; ",
         sum(joined$pop >= RES_MIN_POP), " with >= ", RES_MIN_POP, ", ",
         sum(joined$pop >= 500), " with >= 500, ", sum(joined$pop == 0), " with none")
