library(tidyverse)
library(sf)
library(rsgeo)

cycle_net_joined = readRDS("data/cycle-net-joined.Rds")
traffic_volumes_scotland = read_sf("data-raw/final_estimates_Scotland.gpkg")

# Edinburgh traffic volumes
edinburgh <- zonebuilder::zb_zone("Edinburgh")
edinburgh_3km <- edinburgh |>
  # Change number in next line to change zone size:
  dplyr::filter(circle_id <= 2) |>
  sf::st_union()
traffic_volumes_edinburgh = traffic_volumes_scotland[edinburgh_3km, ]

tm_shape(traffic_volumes_edinburgh) + tm_lines("pred_flows")

# Join traffic volumes with cycle_net
# See tutorial: https://github.com/acteng/network-join-demos
cycle_net_traffic_polygons = stplanr::rnet_join(
  max_angle_diff = 30,
  rnet_x = cycle_net_joined,
  rnet_y = traffic_volumes_edinburgh %>% 
    transmute(
      name_1, road_classification, pred_flows
    ) %>% 
    sf::st_cast(to = "LINESTRING"),
  dist = 15,
  segment_length = 10
)

# # Check results:
# cycle_net_traffic_polygons %>%
#   select(pred_flows) %>%
#   plot()

# group by + summarise stage
cycleways_with_traffic_df = cycle_net_traffic_polygons %>% 
  st_drop_geometry() %>% 
  group_by(osm_id) %>% 
  summarise(
    pred_flows = median(pred_flows),
    road_classification = most_common_value(road_classification),
    name_1 = most_common_value(name_1)
  )

# join back onto cycle_net
cycle_net_traffic = left_join(cycle_net_joined, cycleways_with_traffic_df)

# Check results
# tm_shape(cycle_net_traffic) + tm_lines("pred_flows", lwd = 2, breaks = c(0, 1000, 2000, 4000, 6000, 50000))
# summary(cycle_net_traffic$pred_flows) # many NAs

tm_shape(cycle_net_traffic) + tm_lines("road_classification", lwd = 2)
tm_shape(cycle_net_traffic) + tm_lines("highway", lwd = 2)

# cycle_net_traffic$road_classification = gsub("A Road", "primary", cycle_net_traffic$road_classification)
# cycle_net_traffic$road_classification = gsub("B Road", "secondary", cycle_net_traffic$road_classification)
# cycle_net_traffic$road_classification = gsub("Classified Unnumbered", "tertiary", cycle_net_traffic$road_classification)

# To correct mapping errors (check to make sure this doesn't include genuine ratruns)
high_flow = cycle_net_traffic %>% 
  filter(highway %in% c("residential", "service") & pred_flows >= 4000)
tm_shape(high_flow) + tm_lines("pred_flows", lwd = 2)

# Use original traffic estimates in some cases
cycle_net_traffic = cycle_net_traffic %>% 
  mutate(
    final_traffic = case_when(
      detailed_segregation == "Cycle track" ~ 0,
      highway %in% c("residential", "service") & pred_flows >= 4000 ~ final_volume,
      !is.na(pred_flows) ~ pred_flows,
      TRUE ~ final_volume)
    )

# Check results
tm_shape(cycle_net_traffic) + tm_lines("final_traffic", lwd = 2, breaks = c(0, 1000, 2000, 4000, 6000, 50000))
# tm_shape(cycle_net_traffic) + tm_lines("detailed_segregation")

cycle_net_traffic = cycle_net_traffic %>% 
  mutate(`Level of Service` = case_when(
    detailed_segregation == "Cycle track" ~ "High",
    detailed_segregation == "Level track" & final_speed <= 30 ~ "High",
    detailed_segregation == "Stepped or footway" & final_speed <= 20 ~ "High",
    detailed_segregation == "Stepped or footway" & final_speed == 30 & final_traffic < 4000 ~ "High",
    detailed_segregation == "Light segregation" & final_speed <= 20 ~ "High",
    detailed_segregation == "Light segregation" & final_speed == 30 & final_traffic < 4000 ~ "High",
    detailed_segregation == "Cycle lane" & final_speed <= 20 & final_traffic < 4000 ~ "High",
    detailed_segregation == "Cycle lane" & final_speed == 30 & final_traffic < 1000 ~ "High",
    detailed_segregation == "Mixed traffic" & final_speed <= 20 & final_traffic < 2000 ~ "High",
    detailed_segregation == "Mixed traffic" & final_speed == 30 & final_traffic < 1000 ~ "High",
    
    detailed_segregation == "Level track" & final_speed == 40 ~ "Medium",
    detailed_segregation == "Level track" & final_speed == 50 & final_traffic < 1000 ~ "Medium",
    detailed_segregation == "Stepped or footway" & final_speed <= 40 ~ "Medium",
    detailed_segregation == "Stepped or footway" & final_speed == 50 & final_traffic < 1000 ~ "Medium",
    detailed_segregation == "Light segregation" & final_speed == 30 ~ "Medium",
    detailed_segregation == "Light segregation" & final_speed == 40 & final_traffic < 2000 ~ "Medium",
    detailed_segregation == "Light segregation" & final_speed == 50 & final_traffic < 1000 ~ "Medium",
    detailed_segregation == "Cycle lane" & final_speed <= 20 ~ "Medium",
    detailed_segregation == "Cycle lane" & final_speed == 30 & final_traffic < 4000 ~ "Medium",
    detailed_segregation == "Cycle lane" & final_speed == 40 & final_traffic < 1000 ~ "Medium",
    detailed_segregation == "Mixed traffic" & final_speed <= 20 & final_traffic < 4000 ~ "Medium",
    detailed_segregation == "Mixed traffic" & final_speed == 30 & final_traffic < 2000 ~ "Medium",
    detailed_segregation == "Mixed traffic" & final_speed == 40 & final_traffic < 1000 ~ "Medium",
    
    
    detailed_segregation == "Level track" ~ "Low",
    detailed_segregation == "Stepped or footway" ~ "Low",
    detailed_segregation == "Light segregation" & final_speed <= 50 ~ "Low",
    detailed_segregation == "Light segregation" & final_speed == 60 & final_traffic < 1000 ~ "Low",
    detailed_segregation == "Cycle lane" & final_speed <= 50 ~ "Low",
    detailed_segregation == "Cycle lane" & final_speed == 60 & final_traffic < 1000 ~ "Low",
    detailed_segregation == "Mixed traffic" & final_speed <= 30 ~ "Low",
    detailed_segregation == "Mixed traffic" & final_speed == 40 & final_traffic < 2000 ~ "Low",
    detailed_segregation == "Mixed traffic" & final_speed == 60 & final_traffic < 1000 ~ "Low",
    
    detailed_segregation == "Light segregation" ~ "Should not be used",
    detailed_segregation == "Cycle lane" ~ "Should not be used",
    detailed_segregation == "Mixed traffic" ~ "Should not be used",
    TRUE ~ "Unknown"
  )) %>% 
  dplyr::mutate(`Level of Service` = factor(
    `Level of Service`,
    levels = c("High", "Medium", "Low", "Should not be used"),
    ordered = TRUE
  ))


tm_shape(cycle_net_traffic) + tm_lines("Level of Service", lwd = 2, palette = "-PuBu")
