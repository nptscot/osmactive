library(tidyverse)
library(tmap)
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

table(cycle_net$maxspeed, useNA = "always")
# 10 mph 20 mph 30 mph 40 mph  5 mph   <NA> 
#   71   3327    202      9     20   2253 

table(cycle_net$cycle_segregation, useNA = "always")
# Cycle track Roadside cycle track        Mixed traffic 
# 267                  257                 5394

roadside = cycle_net %>% 
  filter(cycle_segregation == "Roadside cycle track")

# There are some roadside cycle tracks that aren't linked to roads
table(roadside$maxspeed, useNA = "always")
# 20 mph 30 mph   <NA> 
#   114     27    116 
table(roadside$highway, useNA = "always")
# cycleway         path   pedestrian      primary  residential    secondary     tertiary unclassified         <NA> 
#   98           14            6           94            7            8           23            7            0 

# Check with roads are missing speed limits
nospeed = cycle_net %>% 
  filter(is.na(maxspeed))
table(nospeed$highway, useNA = "always")
# cycleway          path    pedestrian   residential       service tertiary_link  unclassified          <NA> 
#   306            69            68            27          1775             2             6             0 

# First add in assumed speed limits for highway categories that are missing them
cycle_net = cycle_net %>% 
  mutate(assumed_speed = case_when(
    !is.na(maxspeed) ~ maxspeed,
    highway == "residential" ~ "20 mph",
    highway == "service" ~ "20 mph",
    highway == "unclassified" ~ "20 mph",
    highway == "tertiary_link" ~ "30 mph"
  ))

table(cycle_net$assumed_speed, useNA = "always")
# 10 mph 20 mph 30 mph 40 mph  5 mph   <NA> 
#   71   5135    204      9     20    443 

# Add assumed traffic volumes
# Use Juan's estimates instead where possible
cycle_net = cycle_net %>% 
  mutate(assumed_volume = case_when(
    highway == "primary" ~ 6000,
    highway == "primary_link" ~ 6000,
    highway == "secondary" ~ 5000,
    highway == "secondary_link" ~ 5000,
    highway == "tertiary" ~ 3000,
    highway == "tertiary_link" ~ 3000,
    highway == "residential" ~ 1000,
    highway == "service" ~ 500,
    highway == "unclassified" ~ 1000
  ))

table(cycle_net$assumed_volume, useNA = "always")
# 500 1000 3000 5000 6000 <NA> 
#   2085 2311  576   79  365  466

# Join cycle_net and drive_net
# See tutorial: https://github.com/acteng/network-join-demos
cycle_net_joined_polygons = stplanr::rnet_join(
  rnet_x = cycle_net,
  rnet_y = drive_net %>% 
    transmute(
      maxspeed_road = maxspeed) %>% 
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
    maxspeed_road = most_common_value(maxspeed_road)
  )

# join back onto cycle_net

cycle_net_joined = left_join(cycle_net, cycleways_with_road_speeds_df)

# table(cycle_net_joined$maxspeed_road, useNA = "always")
# # 20 mph 30 mph 40 mph   <NA> 
# #   1683    334     18   3847 

cycle_net_joined = cycle_net_joined %>% 
  mutate(final_speed = case_when(
    !is.na(assumed_speed) ~ assumed_speed,
    TRUE ~ maxspeed_road
  ))

# table(cycle_net_joined$final_speed, useNA = "always")
# # 10 mph 20 mph 30 mph 40 mph  5 mph   <NA> 
# # 71   5271    226     10     20    286 

# roadside = cycle_net_joined %>% 
#   filter(cycle_segregation == "Roadside cycle track")
# 
# # There are some roadside cycle tracks that aren't linked to roads
# table(roadside$final_speed, useNA = "always")
# # 20 mph 30 mph   <NA> 
# #   200     38     19 
# table(roadside$highway, useNA = "always")
# # cycleway         path   pedestrian      primary  residential    secondary     tertiary unclassified         <NA> 
# #   98           14            6           94            7            8           23            7            0 

saveRDS(cycle_net, "data/cycle-net.Rds")
saveRDS(cycle_net_joined, "data/cycle-net-joined.Rds")

# Classify by final speed -------------------------------------------------

cycle_net_joined = cycle_net_joined %>% 
  mutate(level_of_service = case_when(
    detailed_segregation == "Cycle track" ~ "High",
    detailed_segregation == "Level track" & final_speed >= 30 ~ "High",
    ....
  ))
