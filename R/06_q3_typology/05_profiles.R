# 06_q3_typology/05_profiles.R --------------------------------------------------
# D6: what each stable type looks like. Profile = mean z-score per category.
# Names come from a fixed rule, not from looking at the map: the overall level
# (mean z above +0.5 "High-access", below -0.5 "Low-access", else "Mid-access";
# not "under-served", which the plan reserves for a negative Q2 residual)
# plus any category standing more than 0.5 SD above or below the type's own
# mean. Unstable types are reported as unstable, not named. When 02's null test
# finds no discrete structure, the groups are named as halves of one gradient.

source("R/00_setup.R")
library(ggplot2)

inp   <- readRDS(file.path(DIR_INT, "q3_inputs.rds"))
cl    <- read_csv(file.path(DIR_PROC, "q3_clusters.csv"), show_col_types = FALSE)
score <- readRDS(file.path(DIR_PROC, "score_subzone.rds"))
kobj  <- readRDS(file.path(DIR_INT, "q3_k.rds"))
gradient <- kobj$structure == "one gradient"

LEVEL_CUT <- 0.5
STANDOUT  <- 0.5
CAT_LAB <- c(food_services = "food services", retail = "retail goods", health = "health",
             food_retail = "food retail", education = "education", recreation = "recreation")

profile <- as_tibble(inp$X) %>% mutate(cluster = cl$cluster[match(inp$data$subzone_c, cl$subzone_c)]) %>%
  pivot_longer(-cluster, names_to = "category", values_to = "z") %>%
  group_by(cluster, category) %>% summarise(mean_z = mean(z), .groups = "drop")

name_type <- function(p) {
  level <- mean(p$mean_z)
  head <- if (level > LEVEL_CUT) "High-access" else if (level < -LEVEL_CUT) "Low-access" else "Mid-access"
  dev <- p$mean_z - level
  hi <- CAT_LAB[p$category[dev > STANDOUT]]; lo <- CAT_LAB[p$category[dev < -STANDOUT]]
  tail <- c(if (length(hi)) paste("strong in", paste(hi, collapse = ", ")),
            if (length(lo)) paste("weak in", paste(lo, collapse = ", ")))
  paste0(head, if (gradient) " end" else "", if (length(tail)) paste0(", ", paste(tail, collapse = "; ")))
}

types <- cl %>% count(cluster, stable, name = "n_subzones") %>%
  rowwise() %>%
  mutate(mean_z = mean(profile$mean_z[profile$cluster == cluster]),
         name = if (stable) name_type(profile %>% filter(cluster == .env$cluster)) else "unstable (not named)") %>%
  ungroup() %>%
  mutate(structure = kobj$structure)

write_csv(types %>% mutate(mean_z = round(mean_z, 2)), file.path(DIR_TAB, "q3_types.csv"))
write_csv(profile %>% mutate(mean_z = round(mean_z, 2)), file.path(DIR_TAB, "q3_profiles.csv"))

type_lab <- setNames(sprintf("Type %d: %s (n = %d)", types$cluster, types$name, types$n_subzones), types$cluster)

p1 <- profile %>%
  mutate(category = factor(CAT_LAB[category], levels = rev(CAT_LAB)),
         type = factor(type_lab[as.character(cluster)], levels = type_lab)) %>%
  ggplot(aes(mean_z, category, fill = type)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.65) +
  geom_vline(xintercept = 0, colour = INK2, linewidth = 0.3) +
  scale_fill_manual(values = setNames(PAL_CAT[seq_along(type_lab)], type_lab), name = NULL) +
  labs(title = if (any(grepl("strong in|weak in", types$name)))
                 "The types differ in their mix of services, not just in level" else
                 "The types differ in overall level, not in their mix of services",
       subtitle = "Mean z-score of each category score by type, residential subzones.",
       x = "mean z-score (0 = residential average)", y = NULL) +
  theme_project() + theme(legend.position = "bottom", legend.direction = "vertical")
save_fig(p1, "q3_profiles.png", width = 6.6, height = 4.2)

map_dat <- score %>% select(subzone_c) %>% left_join(cl, by = "subzone_c") %>%
  mutate(type = factor(type_lab[as.character(cluster)], levels = type_lab))
p2 <- ggplot(map_dat) +
  geom_sf(aes(fill = type), colour = "white", linewidth = 0.1) +
  scale_fill_manual(values = setNames(PAL_CAT[seq_along(type_lab)], type_lab), breaks = unname(type_lab),
                    na.value = GREY_NA, name = NULL) +   # named breaks would print the names "1", "2"
  labs(title = if (gradient) "No evidence of discrete types: one access gradient, cut in two" else "Neighbourhood types across Singapore",
       subtitle = paste0("k-means on six z-scored category scores. ",
                         if (gradient) "Read the colours as the two ends of one access gradient.
"
                         else "Types more distinct than in a no-cluster null.
",
                         if (all(types$stable)) "Both splits stable under a spatial block bootstrap." else "Not all groups are stable.",
                         "
Grey: non-residential.")) +
  theme_map() + theme(legend.position = "bottom", legend.direction = "vertical")
save_fig(p2, "q3_types_map.png", width = 7.8, height = 5)

log_step("types: ", paste0(type_lab, collapse = "; "))
