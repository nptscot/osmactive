# Extra tags function
et <- function() {
  et <- c(
    "maxspeed",
    "oneway",
    "bicycle",
    "cycleway",
    "cycleway:left",
    "cycleway:right",
    "cycleway:both",
    "lanes",
    "lanes:both_ways",
    "lanes:forward",
    "lanes:backward",
    "lanes:bus",
    "lanes:bus:conditional",
    "oneway",
    "width",      # useful to ensure width of cycleways is at least 1.5m
    "segregated"  # classifies whether cycles and pedestrians are segregated on shared paths
  )
  return(et)
}

# Exclude functions
exclude_cycling <- function() {
  to_exclude <- paste0(
    "motorway|bridleway|disused|emergency|escap",
    "|far|foot|rest|road|track"
  )
  return(to_exclude)
}

exclude_bicycle <- function() {
  to_exclude <- paste0(
    "mtb|discouraged|unknown"
  )
  return(to_exclude)
}

exclude_driving <- function() {
  to_exclude <- paste0(
    "crossing|disused|emergency|escap|far|raceway|rest|track",
    # Paths that cannot be driven on:
    "|bridleway|cycleway|footway|path|pedestrian|steps|track|proposed|construction"
  )
  return(to_exclude)
}

# Get the OSM network functions
get_driving_network <- function(
  place,
  ex_d = exclude_driving()
) {
  osm_highways <- osmextract::oe_get(
    place = place,
    extra_tags = et()
  )
  res <- osm_highways |> 
    filter(!is.na(highway)) |>
    filter(!str_detect(string = highway, pattern = ex_d))
  return(res)
}

get_cycling_network <- function(
  place,
  ex_c = exclude_cycling(),
  ex_b = exclude_bicycle()
) {
  osm_cycleways <- osmextract::oe_get(
    place = place,
    extra_tags = et()
  )
  res <- osm_cycleways |> 
    filter(!is.na(highway)) |> 
    filter(!str_detect(string = highway, pattern = ex_c)) |>
    # Exclude mtb paths and related tags
    filter(is.na(bicycle)|!str_detect(string = bicycle, pattern = ex_b))
  return(res)
}

# Distance to the nearest road function
distance_to_road <- function(cycleways, roads) {
  segregated_points <- sf::st_point_on_surface(cycleways)
  roads_union <- roads |> 
    sf::st_union() |> 
    sf::st_transform(27700)
  roads_geos <- geos::as_geos_geometry(roads_union)
  points_geos <- geos::as_geos_geometry(segregated_points |>  sf::st_transform(27700))
  points_distances <- geos::geos_distance(points_geos, roads_geos)
  cycleways$distance_to_road <- points_distances
  return(cycleways)
}

# Segregation levels function
segregation_levels <- function(cycleways) {
  cycleways |> 
    mutate(type = case_when(
      grepl("Path", name, fixed = TRUE) ~ "detached_track",
      grepl("Towpath", name, fixed = TRUE) ~ "detached_track",
      distance_to_road > 10 ~ "detached_track",
      TRUE ~ "mixed_traffic"
    )) |> 
    mutate(cycle_segregation = case_when(
      # Where highway == cycleway
      type == "detached_track" ~ "detached_track",
      type == "level_track" ~ "level_track",
      # Cycleways on road
      cycleway == "lane" ~ "cycle_lane",
      cycleway_right == "lane" ~ "cycle_lane",
      cycleway_left == "lane" ~ "cycle_lane",
      cycleway_both == "lane" ~ "cycle_lane",
      cycleway == "track" ~ "light_segregation",
      cycleway_left == "track" ~ "light_segregation",
      cycleway_right == "track" ~ "light_segregation",
      cycleway_both == "track" ~ "light_segregation",
      # Shared with pedestrians (but not highway == cycleway)
      segregated == "no" ~ "stepped_or_footway",
      segregated == "yes" ~ "stepped_or_footway",
      # Rare cases
      cycleway == "separate" ~ "stepped_or_footway",
      cycleway_left == "separate" ~ "stepped_or_footway",
      cycleway_right == "separate" ~ "stepped_or_footway",
      cycleway_both == "separate" ~ "stepped_or_footway",
      cycleway == "buffered_lane" ~ "cycle_lane",
      cycleway_left == "buffered_lane" ~ "cycle_lane",
      cycleway_right == "buffered_lane" ~ "cycle_lane",
      cycleway_both == "buffered_lane" ~ "cycle_lane",
      cycleway == "segregated" ~ "stepped_or_footway",
      cycleway_left == "segregated" ~ "stepped_or_footway",
      cycleway_right == "segregated" ~ "stepped_or_footway",
      cycleway_both == "segregated" ~ "stepped_or_footway",
      # Default mixed traffic
      .default = "mixed_traffic"
    )) |>
    mutate(cycle_segregation = case_when(
      cycle_segregation %in% c("level_track", "light_segregation", "stepped_or_footway") ~ "roadside_cycle_track",
      cycle_segregation %in% c("cycle_lane", "mixed_traffic") ~ "mixed_traffic",
      TRUE ~ cycle_segregation
    )) |>
    mutate(cycle_segregation = factor(
      cycle_segregation,
      levels = c("detached_track", "roadside_cycle_track", "mixed_traffic"),
      ordered = TRUE
    ))
}