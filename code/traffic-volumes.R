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

# Join trafic volumes with cycle_net
# See tutorial: https://github.com/acteng/network-join-demos
cycle_net_traffic = stplanr::rnet_join(
  rnet_x = cycle_net_joined,
  rnet_y = traffic_volumes_edinburgh %>% 
    transmute(
      name_1, road_classification, pred_flows
    ) %>% 
    sf::st_cast(to = "LINESTRING"),
  dist = 20,
  segment_length = 10
)
