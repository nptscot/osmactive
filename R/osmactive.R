#' This function returns OSM keys that are relevant for active travel
#'
#' @export
et_active = function() {
  c(
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
    "segregated",  # classifies whether cycles and pedestrians are segregated on shared paths
    "sidewalk",    # useful to ensure width of cycleways is at least 1.5m
    "footway",
    # "highway", # included by default
    # "name", # included by default
    "service", 
    "surface", 
    "tracktype",
    "surface",
    "smoothness",
    "access"    
  )
}

# Exclude highway values for utility cycling
exclude_highway_cycling = function() {
  to_exclude = paste0(
    "motorway|bridleway|disused|emergency|escap",
    "|far|foot|rest|road|track|steps"
  )
  return(to_exclude)
}

# Exclude bicycle values for utility cycling
exclude_bicycle_cycling = function() {
  to_exclude = paste0(
    "mtb|discouraged|unknown"
  )
  return(to_exclude)
}

# Exclude highway values for driving
exclude_highway_driving = function() {
  to_exclude = paste0(
    "crossing|disused|emergency|escap|far|raceway|rest|track",
    # Paths that cannot be driven on:
    "|bridleway|cycleway|footway|path|pedestrian|steps|track|proposed|construction"
  )
  return(to_exclude)
}

#' Get the OSM network functions
#' 
#' @param place A place name or a bounding box passed to `osmextract::oe_get()`
#' @param extra_tags A vector of extra tags to be included in the OSM extract
#' @param ... Additional arguments passed to `osmextract::oe_get()`
#' @return A sf object with the OSM network
#' @export
get_travel_network = function(
    place,
    extra_tags = et_active(),
    ...
) {
    osm_highways = osmextract::oe_get(
        place = place,
        extra_tags = extra_tags,
        ...
    )
    osm_highways |>
        dplyr::filter(!is.na(highway)) |>
        # Remove all service tags based on https://wiki.openstreetmap.org/wiki/Key:service
        dplyr::filter(is.na(service))
}

#' Get the OSM driving network
#' 
#' @inheritParams get_cycling_network
#' @param ex_d A character string of highway values to exclude in the form `value1|value2` etc
#' @return A sf object with the OSM driving network
#' @export
get_driving_network = function(
  osm,
  ex_d = exclude_highway_driving()
) {
  osm |> 
    dplyr::filter(!stringr::str_detect(string = highway, pattern = ex_d))
}
#' Get the OSM cycling network
#' 
#' @param osm An OSM network object
#' @param ex_c A vector of highway values to exclude
#' @param ex_b A vector of bicycle values to exclude
#' @return A sf object with the OSM cycling network
#' @export
get_cycling_network = function(
  osm,
  ex_c = exclude_highway_cycling(),
  ex_b = exclude_bicycle_cycling()
) {
  osm |> 
    dplyr::filter(!stringr::str_detect(string = highway, pattern = ex_c)) |>
    # Exclude mtb paths and related tags
    dplyr::filter(is.na(bicycle)|!stringr::str_detect(string = bicycle, pattern = ex_b)) |>
    # Remove highway=path without bicycle values of yes, designated, or permissive:
    dplyr::filter(
      !(highway == "path" & !stringr::str_detect(string = bicycle, pattern = "yes|designated|permissive"))
    ) |>
    # Remove links with highway == "pedestrian" and no bicycle == "yes" etc
    dplyr::filter(
      !(highway == "pedestrian" & !stringr::str_detect(string = bicycle, pattern = "yes|designated|permissive"))
    )
}

#' Calculate distance from route network segments to roads
#' 
#' This function approximates the distance from the route network to the nearest road.
#' It does this by first computing the `sf::st_point_on_surface` of the route network segments
#' and then calculating the distance to the nearest road using the `geos::geos_distance` function.
#' 
#' @param rnet The route network for which the distance to the road needs to be calculated.
#' @param roads The road network to which the distance needs to be calculated.
#' @return An sf object with the new column `distance_to_road` that contains the distance to the road.
#' @export
distance_to_road = function(rnet, roads) {
  segregated_points = sf::st_point_on_surface(rnet)
  roads_union = roads |> 
    sf::st_union() |> 
    sf::st_transform(27700)
  roads_geos = geos::as_geos_geometry(roads_union)
  points_geos = geos::as_geos_geometry(segregated_points |>  sf::st_transform(27700))
  points_distances = geos::geos_distance(points_geos, roads_geos)
  rnet$distance_to_road = points_distances
  return(rnet)
}

#' Segregation levels
#'
#' This function calculates the segregation levels for a given dataset.
#'
#' @param cycleways The input dataset for which segregation levels need to be calculated.
#' @param min_distance The minimum distance to the road for a cycleway to be considered off-road.
#' @return A an sf object with the new column `cycle_segregation` that contains the segregation levels.
#' @export
segregation_levels = function(cycleways, min_distance = 10) {
  cycleways |> 
    dplyr::mutate(type = dplyr::case_when(
      grepl("Path", name, fixed = TRUE) ~ "offroad_track",
      grepl("Towpath", name, fixed = TRUE) ~ "offroad_track",
      TRUE ~ "mixed_traffic"
    )) |> 
    dplyr::mutate(cycle_segregation = dplyr::case_when(
      # Where highway == cycleway
      type == "offroad_track" ~ "offroad_track",
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
    dplyr::mutate(cycle_segregation = dplyr::case_when(
      cycle_segregation %in% c("level_track", "light_segregation", "stepped_or_footway") ~ "roadside_cycle_track",
      cycle_segregation %in% c("cycle_lane", "mixed_traffic") ~ "mixed_traffic",
      TRUE ~ cycle_segregation
    )) |>
    # When distance to road is more than min_distance m and cycleway type is stepped_or_footway, change to offroad_track
    dplyr::mutate(cycle_segregation = dplyr::case_when(
      distance_to_road > min_distance & cycle_segregation == "roadside_cycle_track" ~ "offroad_track",
      TRUE ~ cycle_segregation
    )) |>
    dplyr::mutate(cycle_segregation = factor(
      cycle_segregation,
      levels = c("offroad_track", "roadside_cycle_track", "mixed_traffic"),
      ordered = TRUE
    ))
}

# Ignore globals:
utils::globalVariables(c("exclude_highway_cycling", "exclude_bicycle_cycling", "exclude_highway_driving", "highway"))
