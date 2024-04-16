## code to prepare `osm_edinburgh` dataset goes here

library(dplyr)
library(tmap)
sf::sf_use_s2(FALSE)
tmap_mode("plot")

edinburgh = zonebuilder::zb_zone("Edinburgh")
edinburgh_3km = edinburgh |>
  # Change number in next line to change zone size:
  filter(circle_id <= 2)
osm = get_travel_network("Scotland", boundary = edinburgh_3km, boundary_type = "clipsrc")

osm_york_way = osm |>
  filter(name == "York Place")

mapview::mapview(osm_york_way)
osm_york_way_buffer = osm_york_way |>
  sf::st_transform(27700) |>
  sf::st_buffer(100) |>
  sf::st_transform(4326) |>
  sf::st_union()

plot(osm_york_way_buffer)

osm = osm[osm_york_way_buffer, ]

cycle_network = get_cycling_network(osm)
driving_network = get_driving_network(osm)
edinburgh_cycle_with_distance = distance_to_road(cycle_network, driving_network)
edinburgh_segregated = classify_cycleways(edinburgh_cycle_with_distance)

plot_osm_tmap(edinburgh_segregated)


table(edinburgh_segregated$cycle_segregation)
m = plot_osm_tmap(edinburgh_segregated)
m

# Save the data
osm_edinburgh = osm
usethis::use_data(osm_edinburgh, overwrite = TRUE)
