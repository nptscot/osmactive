## code to prepare `osm_edinburgh` dataset goes here

remotes::install_github("nptscot/osmactive")
library(osmactive)
# Or
devtools::load_all()
library(dplyr)
library(tmap)
library(sf)
sf::sf_use_s2(TRUE)
tmap_mode("plot")

edinburgh_coords = stplanr::geo_code("Edinburgh, UK")
edinburgh_sf = sf::st_sf(
  geometry = sf::st_sfc(sf::st_point(edinburgh_coords)),
  crs = 4326
)
edinburgh_3km = edinburgh_sf |>
  sf::st_buffer(3000) 

osm = get_travel_network("Scotland", boundary = edinburgh_3km, boundary_type = "clipsrc")
names(osm)

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
plot(osm)

# # Keep only most relevant columns
osm = osm %>%
  select(osm_id, name, highway, cycleway, bicycle, lanes, sidewalk, other_tags)

cycle_network = get_cycling_network(osm)
cycle_network_old = cycle_network
driving_network = get_driving_network(osm)
edinburgh_cycle_with_distance = distance_to_road(cycle_network, driving_network)
cycleways_classified = classify_cycle_infrastructure(edinburgh_cycle_with_distance)
# cycleways_classified_old = cycleways_classified
waldo::compare(cycleways_classified, cycleways_classified_old)

plot_osm_tmap(edinburgh_segregated)


table(edinburgh_segregated$cycle_segregation)
m = plot_osm_tmap(edinburgh_segregated)
m

# Save the data
osm_edinburgh = osm
usethis::use_data(osm_edinburgh, overwrite = TRUE)
