library(tidyverse)
library(tmap)
library(sf)
tmap_mode("view")

edinburgh <- zonebuilder::zb_zone("Edinburgh")
edinburgh_3km <- edinburgh |>
  # Change number in next line to change zone size:
  dplyr::filter(circle_id <= 2) |>
  sf::st_union()
osm <- get_travel_network("Scotland", boundary = edinburgh_3km, boundary_type = "clipsrc")
cycle_net <- get_cycling_network(osm)
drive_net <- get_driving_network_major(osm)
cycle_net <- distance_to_road(cycle_net, drive_net)
cycle_net <- classify_cycle_infrastructure(cycle_net)
m <- plot_osm_tmap(cycle_net)
m

tm_shape(drive_net) + tm_lines("highway", lwd = 2)

# Clean speeds in drive_net
drive_net = clean_speeds(drive_net)

drive_net = estimate_traffic(drive_net)

# table(drive_net$maxspeed_clean, useNA = "always")
# # 20   30   40 <NA> 
# #   860  152    9    0 

# Check and clean cycle_net
# table(cycle_net$cycle_segregation, useNA = "always")
# # Cycle track Roadside cycle track        Mixed traffic 
# # 267                  257                 5394
# 
# # Check with roads are missing speed limits
# nospeed = cycle_net %>% 
#   filter(is.na(maxspeed))
# table(nospeed$highway, useNA = "always")
# # cycleway          path    pedestrian   residential       service tertiary_link  unclassified          <NA> 
# #   306            69            68            27          1775             2             6             0 

# First clean cycle_net speed limits
# Functions here derived from https://github.com/udsleeds/openinfra/blob/main/R/oi_clean_maxspeed_uk.R
cycle_net = clean_speeds(cycle_net)

# table(cycle_net$maxspeed_clean, useNA = "always")
# # 5   10   20   30   40 <NA> 
# #   20   71 5137  205    9  443

# Add assumed traffic volumes
# Use Juan's estimates instead where possible
cycle_net = estimate_traffic(cycle_net)

# table(cycle_net$assumed_volume, useNA = "always")
# # 500 1000 3000 5000 6000 <NA> 
# #   2085 2311  576   79  365  466

# Join cycle_net and drive_net
# See tutorial: https://github.com/acteng/network-join-demos
cycle_net_joined_polygons = stplanr::rnet_join(
  rnet_x = cycle_net,
  rnet_y = drive_net %>% 
    transmute(
      maxspeed_road = maxspeed_clean,
      highway_join = highway,
      volume_join = assumed_volume
      ) %>% 
    sf::st_cast(to = "LINESTRING"),
  dist = 20,
  segment_length = 10
  )

# # Check results:
# cycle_net_joined_polygons %>% 
#   select(maxspeed_road) %>% 
#   plot()

# group by + summarise stage
cycleways_with_road_speeds_df = cycle_net_joined_polygons %>% 
  st_drop_geometry() %>% 
  group_by(osm_id) %>% 
  summarise(
    maxspeed_road = most_common_value(maxspeed_road),
    highway_join = most_common_value(highway_join),
    volume_join = most_common_value(volume_join)
  ) %>% 
  mutate(
    maxspeed_road = as.numeric(maxspeed_road),
    volume_join = as.numeric(volume_join)
    )

# join back onto cycle_net

cycle_net_joined = left_join(cycle_net, cycleways_with_road_speeds_df)

# table(cycle_net_joined$maxspeed_road, useNA = "always")
# # 20 mph 30 mph 40 mph   <NA> 
# #   1683    334     18   3847 

cycle_net_joined = cycle_net_joined %>% 
  mutate(
    final_speed = case_when(
      !is.na(maxspeed_clean) ~ maxspeed_clean,
      TRUE ~ maxspeed_road),
    final_volume = case_when(
      !is.na(assumed_volume) ~ assumed_volume,
      TRUE ~ volume_join)
  )

table(cycle_net_joined$final_speed, useNA = "always")
# 5   10   20   30   40 <NA> 
#   20   71 5271  227   10  286

roadside = cycle_net_joined %>%
  filter(cycle_segregation == "Roadside cycle track")

# There are some roadside cycle tracks that still aren't linked to roads
table(roadside$final_speed, useNA = "always")
# 20 mph 30 mph   <NA>
#   200     38     19
table(roadside$highway, useNA = "always")
# cycleway         path   pedestrian      primary  residential    secondary     tertiary unclassified         <NA>
#   98           14            6           94            7            8           23            7            0

table(roadside$final_volume, useNA = "always")
# 1000 3000 5000 6000 <NA> 
#   14   60   18  145   20 

# Now go to script traffic-volumes.R

# # Classify by final speed -------------------------------------------------
# 
# cycle_net_joined = cycle_net_joined %>% 
#   mutate(`Level of Service` = case_when(
#     detailed_segregation == "Cycle track" ~ "High",
#     detailed_segregation == "Level track" & final_speed <= 30 ~ "High",
#     detailed_segregation == "Stepped or footway" & final_speed <= 20 ~ "High",
#     detailed_segregation == "Stepped or footway" & final_speed == 30 & final_volume < 4000 ~ "High",
#     detailed_segregation == "Light segregation" & final_speed <= 20 ~ "High",
#     detailed_segregation == "Light segregation" & final_speed == 30 & final_volume < 4000 ~ "High",
#     detailed_segregation == "Cycle lane" & final_speed <= 20 & final_volume < 4000 ~ "High",
#     detailed_segregation == "Cycle lane" & final_speed == 30 & final_volume < 1000 ~ "High",
#     detailed_segregation == "Mixed traffic" & final_speed <= 20 & final_volume < 2000 ~ "High",
#     detailed_segregation == "Mixed traffic" & final_speed == 30 & final_volume < 1000 ~ "High",
#     
#     detailed_segregation == "Level track" & final_speed == 40 ~ "Medium",
#     detailed_segregation == "Level track" & final_speed == 50 & final_volume < 1000 ~ "Medium",
#     detailed_segregation == "Stepped or footway" & final_speed <= 40 ~ "Medium",
#     detailed_segregation == "Stepped or footway" & final_speed == 50 & final_volume < 1000 ~ "Medium",
#     detailed_segregation == "Light segregation" & final_speed == 30 ~ "Medium",
#     detailed_segregation == "Light segregation" & final_speed == 40 & final_volume < 2000 ~ "Medium",
#     detailed_segregation == "Light segregation" & final_speed == 50 & final_volume < 1000 ~ "Medium",
#     detailed_segregation == "Cycle lane" & final_speed <= 20 ~ "Medium",
#     detailed_segregation == "Cycle lane" & final_speed == 30 & final_volume < 4000 ~ "Medium",
#     detailed_segregation == "Cycle lane" & final_speed == 40 & final_volume < 1000 ~ "Medium",
#     detailed_segregation == "Mixed traffic" & final_speed <= 20 & final_volume < 4000 ~ "Medium",
#     detailed_segregation == "Mixed traffic" & final_speed == 30 & final_volume < 2000 ~ "Medium",
#     detailed_segregation == "Mixed traffic" & final_speed == 40 & final_volume < 1000 ~ "Medium",
#     
#     
#     detailed_segregation == "Level track" ~ "Low",
#     detailed_segregation == "Stepped or footway" ~ "Low",
#     detailed_segregation == "Light segregation" & final_speed <= 50 ~ "Low",
#     detailed_segregation == "Light segregation" & final_speed == 60 & final_volume < 1000 ~ "Low",
#     detailed_segregation == "Cycle lane" & final_speed <= 50 ~ "Low",
#     detailed_segregation == "Cycle lane" & final_speed == 60 & final_volume < 1000 ~ "Low",
#     detailed_segregation == "Mixed traffic" & final_speed <= 30 ~ "Low",
#     detailed_segregation == "Mixed traffic" & final_speed == 40 & final_volume < 2000 ~ "Low",
#     detailed_segregation == "Mixed traffic" & final_speed == 60 & final_volume < 1000 ~ "Low",
#     
#     detailed_segregation == "Light segregation" ~ "Should not be used",
#     detailed_segregation == "Cycle lane" ~ "Should not be used",
#     detailed_segregation == "Mixed traffic" ~ "Should not be used",
#     TRUE ~ "Unknown"
#   )) %>% 
#   dplyr::mutate(`Level of Service` = factor(
#     `Level of Service`,
#     levels = c("High", "Medium", "Low", "Should not be used"),
#     ordered = TRUE
#   ))
# 
# tm_shape(cycle_net_joined) + tm_lines("Level of Service", lwd = 2, palette = "viridis")
# 
# # Checks
# snbu = cycle_net_joined %>% filter(level_of_service == "Should not be used")
# View(snbu)
# tm_shape(snbu) + tm_lines("highway", lwd = 2)
# 
# paths = cycle_net_joined %>% filter(
#   highway == "path" | highway == "pedestrian",
#   bicycle == "permissive" | bicycle == "yes"
# )
# tm_shape(paths) + tm_lines("highway")

saveRDS(cycle_net, "data-raw/cycle-net.Rds")
saveRDS(cycle_net_joined, "data-raw/cycle-net-joined.Rds")
