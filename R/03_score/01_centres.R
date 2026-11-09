# 03_score/01_centres.R ---------------------------------------------------------
# One population-weighted centre per subzone (A4): the floor-area-weighted mean
# of its residential buildings, so the walk-radius circle is drawn from where people
# live rather than from the polygon's middle, which can sit in a reservoir, a
# forest, or outside an L-shaped subzone.
#
# Two guards. A weighted mean can still land outside the subzone (two estates
# either side of a park); it is then moved to the nearest residential building
# in the subzone. Subzones with no residential buildings fall back to
# st_point_on_surface() and are flagged. The centres are a hand-off: Q2 measures
# distance to rail from the same points (data/output/processed/score_centres.rds).

source("R/00_setup.R")
library(ggplot2)

subzones <- readRDS(file.path(DIR_INT, "subzones.rds"))
bld      <- readRDS(file.path(DIR_INT, "res_buildings.rds"))
census   <- read_csv(file.path(DIR_PROC, "census2020_subzone.csv"), show_col_types = FALSE)

bxy <- st_coordinates(st_point_on_surface(st_geometry(bld)))
bpts <- bld %>% st_drop_geometry() %>% mutate(x = bxy[, 1], y = bxy[, 2])

wmean <- bpts %>% group_by(subzone_c) %>%
  summarise(x = weighted.mean(x, weight), y = weighted.mean(y, weight),
            n_buildings = n(), .groups = "drop")

centres <- subzones %>% st_drop_geometry() %>% select(subzone_c) %>%
  left_join(wmean, by = "subzone_c") %>%
  mutate(centre_method = if_else(is.na(x), "point_on_surface", "buildings"),
         n_buildings = coalesce(n_buildings, 0L))

# Fallback for subzones without residential buildings.
pos <- st_coordinates(st_point_on_surface(st_geometry(subzones)))
fb  <- centres$centre_method == "point_on_surface"
centres$x[fb] <- pos[match(centres$subzone_c[fb], subzones$subzone_c), 1]
centres$y[fb] <- pos[match(centres$subzone_c[fb], subzones$subzone_c), 2]

centres <- st_as_sf(centres, coords = c("x", "y"), crs = CRS_SVY21)

# Weighted means that fell outside their own subzone: snap to the nearest building.
own    <- subzones[match(centres$subzone_c, subzones$subzone_c), ]
hits   <- st_intersects(centres, own)
inside <- vapply(seq_along(hits), function(i) i %in% hits[[i]], logical(1))
snap <- which(!inside & centres$centre_method == "buildings")
for (i in snap) {
  b <- bpts %>% filter(subzone_c == centres$subzone_c[i])
  d <- (b$x - st_coordinates(centres[i, ])[1])^2 + (b$y - st_coordinates(centres[i, ])[2])^2
  st_geometry(centres)[i] <- st_point(c(b$x[which.min(d)], b$y[which.min(d)]))
}
log_step("centres: ", sum(centres$centre_method == "buildings"), " from buildings (",
         length(snap), " snapped back inside their subzone), ",
         sum(centres$centre_method == "point_on_surface"), " point-on-surface fallbacks")

# Residents living in a subzone with no mapped residential building are the
# ones whose centre is a guess. Say how many.
fb_pop <- census %>% filter(subzone_c %in% centres$subzone_c[centres$centre_method == "point_on_surface"])
log_step("residents in fallback subzones: ", format(sum(fb_pop$pop), big.mark = ","),
         " (", sum(fb_pop$pop >= RES_MIN_POP), " fallback subzones have >= ", RES_MIN_POP, " residents)")
if (any(fb_pop$pop >= RES_MIN_POP)) print(fb_pop %>% filter(pop >= RES_MIN_POP) %>% select(subzone_c, pop))

saveRDS(centres %>% select(subzone_c, centre_method, n_buildings), file.path(DIR_PROC, "score_centres.rds"))

# Check by eye, as the plan asks: centres over subzones, fallbacks highlighted.
p <- ggplot() +
  geom_sf(data = subzones, fill = PAL_DIV[["mid"]], colour = "white", linewidth = 0.15) +
  geom_sf(data = centres, aes(colour = centre_method), size = 0.7) +
  scale_colour_manual(values = c(buildings = PAL_CAT[1], point_on_surface = PAL_CAT[2]), name = NULL) +
  labs(title = paste0("Subzone centres used for the ", RADIUS_M / 1000, " km access count"),
       subtitle = "Blue: floor-area-weighted mean of residential buildings. Orange: no residential buildings mapped, polygon point used.",
       caption = "Source: OSM residential building footprints; MP19 subzones.") +
  theme_map() +
  theme(legend.position = "bottom")
save_fig(p, "score_centres_map.png")
