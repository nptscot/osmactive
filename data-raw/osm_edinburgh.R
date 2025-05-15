## code to prepare `osm_edinburgh` dataset goes here

remotes::install_github("nptscot/osmactive")
library(osmactive)
# Or
# devtools::load_all() # Load local package code
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

# Check names
"footway" %in% names(osm_edinburgh)
osm = get_travel_network(
  "edinburgh",
  boundary = edinburgh_3km,
  boundary_type = "clipsrc",
  force_download = TRUE
)
names(osm)
"footway" %in% names(osm)
unique(osm$name)

# Rename name2 to name
if ("name2" %in% names(osm)) {
  osm$name = osm$name2
  osm$name2 = NULL
}
# rename highway2 to highway
if ("highway2" %in% names(osm)) {
  osm$highway = osm$highway2
  osm$highway2 = NULL
}

mapview::mapview(osm)
osm_york_way = osm |>
  filter(stringr::str_detect(name, "York Place"))

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
osm = osm |>
  select(
    osm_id,
    name,
    highway,
    matches("cycleway"),
    bicycle,
    lanes,
    foot,
    footway,
    path,
    sidewalk,
    segregated,
    maxspeed,
    width,
    est_width,
    lit,
    oneway,
    cycleway_surface,
    surface,
    smoothness,
    other_tags
  )
names(osm)


cycle_network = get_cycling_network(osm)
cycle_network_old = cycle_network
driving_network = get_driving_network(osm)
edinburgh_cycle_with_distance = distance_to_road(cycle_network, driving_network)
cycleways_classified = classify_cycle_infrastructure(
  edinburgh_cycle_with_distance
)
# # cycleways_classified_old = cycleways_classified
# waldo::compare(cycleways_classified, cycleways_classified_old)

plot_osm_tmap(cycleways_classified)


table(cycleways_classified$cycle_segregation)
m = plot_osm_tmap(cycleways_classified)
m

# Save the data
osm_edinburgh = osm
usethis::use_data(osm_edinburgh, overwrite = TRUE)
