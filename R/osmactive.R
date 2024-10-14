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
    "cycleway:surface",
    "lanes",
    "lanes:both_ways",
    "lanes:forward",
    "lanes:backward",
    "lanes:bus",
    "lanes:bus:conditional",
    "lit", # useful to check if cycleways are lit
    "oneway",
    "width", # useful to ensure width of cycleways is at least 1.5m
    "segregated",
    "sidewalk", # useful to ensure width of cycleways is at least 1.5m
    "footway",
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
    "abandoned|bridleway|bus_guideway|byway|construction|corridor|disused|elevator|emergency|escalator|escap",
    "|far|fixme|foot|gallop|historic|motorway|no|planned|platform|proposed|raceway|rest|road|services|steps|track"
  )
  return(to_exclude)
}

# Exclude bicycle values for utility cycling
exclude_bicycle_cycling = function() {
  paste0(
    "mtb|discouraged|unknown|no"
  )
}

# Exclude highway values for driving
exclude_highway_driving = function() {
  to_exclude = paste0(
    "abandoned|bridleway|bus_guideway|byway|construction|corridor|crossing|cycleway|disused|elevator|emergency|
    escalator|escap|far|fixme|footway|gallop|historic|no|path|pedestrian|planned|platform|proposed|
    raceway|rest|road|services|steps|track"
  )
  return(to_exclude)
}

#' Get the OSM network functions
#'
#' @param place A place name or a bounding box passed to `osmextract::oe_get()`
#' @param extra_tags A vector of extra tags to be included in the OSM extract
#' @param columns_to_remove A vector of columns to be removed from the OSM network
#' @param ... Additional arguments passed to `osmextract::oe_get()`
#' @return A sf object with the OSM network
#' @export
get_travel_network = function(
    place,
    extra_tags = et_active(),
    columns_to_remove = c("waterway", "aerialway", "barrier", "manmade"),
    ...) {
  osm_highways = osmextract::oe_get(
    place = place,
    extra_tags = extra_tags,
    ...
  )
  osm_highways |>
    dplyr::filter(!is.na(highway)) |>
    # Remove all service tags based on https://wiki.openstreetmap.org/wiki/Key:service
    dplyr::filter(is.na(service)) |>
    dplyr::select(-dplyr::matches(columns_to_remove))
}

#' Get the OSM driving network
#'
#' This function returns the OSM driving network by excluding certain highway values.
#'
#' `get_driving_network_major` returns only the major roads.
#'
#' @inheritParams get_cycling_network
#' @param ex_d A character string of highway values to exclude in the form `value1|value2` etc
#' @return A sf object with the OSM driving network
#' @export
get_driving_network = function(
    osm,
    ex_d = exclude_highway_driving()) {
  osm |>
    dplyr::filter(!stringr::str_detect(string = highway, pattern = ex_d))
}
#' @export
#' @inheritParams get_driving_network
#' @param pattern A character string of highway values to define major roads in the form `motorway|trunk|primary|secondary|tertiary`
#' @rdname get_driving_network
get_driving_network_major = function(
    osm,
    ex_d = exclude_highway_driving(),
    pattern = "motorway|trunk|primary|secondary|tertiary") {
  osm |>
    dplyr::filter(!stringr::str_detect(string = highway, pattern = ex_d)) |>
    dplyr::filter(stringr::str_detect(string = highway, pattern = pattern))
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
    ex_b = exclude_bicycle_cycling()) {
  osm |>
    dplyr::filter(!stringr::str_detect(string = highway, pattern = ex_c)) |>
    # Exclude roads where cycling is banned, plus mtb paths and related tags
    dplyr::filter(is.na(bicycle) | !stringr::str_detect(string = bicycle, pattern = ex_b)) |>
    # Remove highway=path without bicycle value of designated:
    dplyr::filter(
      !(highway == "path" & !stringr::str_detect(string = bicycle, pattern = "designated"))
    ) |>
    # Remove highway=pedestrian without bicycle value of designated:
    dplyr::filter(
      !(highway == "pedestrian" & !stringr::str_detect(string = bicycle, pattern = "designated"))
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
#' @examples
#' osm = osm_edinburgh
#' cycle_network = get_cycling_network(osm)
#' driving_network = get_driving_network(osm)
#' edinburgh_cycle_with_distance = distance_to_road(cycle_network, driving_network)
distance_to_road = function(rnet, roads) {
  suppressWarnings({
    rnet_points = rnet |> 
      sf::st_transform(27700) |>
      sf::st_point_on_surface()        
  })
  roads_transformed = roads |>
    sf::st_transform(27700)
  roads_geos = geos::as_geos_geometry(roads_transformed)
  points_geos = geos::as_geos_geometry(rnet_points)
  roads_nearest_i = geos::geos_nearest(points_geos, roads_geos)
  roads_nearest = roads_geos[roads_nearest_i]
  points_distances = geos::geos_distance(points_geos, roads_nearest)
  rnet$distance_to_road = round(points_distances, 1)
  return(rnet)
}

#' Segregation levels
#'
#' This function classifies OSM ways in by cycle infrastructure type levels for a given dataset.
#'
#' See [wiki.openstreetmap.org/wiki/Key:cycleway](https://wiki.openstreetmap.org/wiki/Key:cycleway)
#' and [taginfo.openstreetmap.org/keys/cycleway#values](https://taginfo.openstreetmap.org/keys/cycleway#values)
#' for more information on cycleway values used to classify cycle infrastructure.
#'
#' Currently, only the "Scotland" classification type is supported.
#' See the Scottish Government's [Cycling by Design](https://www.transport.gov.scot/publication/cycling-by-design/) for more information.
#'
#' @param osm The input dataset for which segregation levels need to be calculated.
#' @param min_distance The minimum distance to the road for a cycleway to be considered off-road.
#' @param classification_type The classification type to be used. Currently only "Scotland" is supported.
#' @return A an sf object with the new column `cycle_segregation` that contains the segregation levels.
#' @export
#' @examples
#' library(tmap)
#' tmap_mode("plot")
#' osm = osm_edinburgh
#' cycle_network = get_cycling_network(osm)
#' driving_network = get_driving_network(osm)
#' netd = distance_to_road(cycle_network, driving_network)
#' netc = classify_cycle_infrastructure(netd)
#' library(sf)
#' plot(netc["cycle_segregation"])
#' plot(netc["distance_to_road"])
classify_cycle_infrastructure = function(osm, min_distance = 10, classification_type = "Scotland") {
  if (classification_type == "Scotland") {
    return(classify_cycle_infrastructure_scotland(osm, min_distance))
  } else {
    stop("Classification type not supported yet. Please open an issue at github.com/nptscot/osmactive.")
  }
}
classify_cycle_infrastructure_scotland = function(osm, min_distance = 10) {
  osm |>
    # If highway == cycleway|pedestrian|path, detailed_segregation can be defined in most cases...
    dplyr::mutate(detailed_segregation = dplyr::case_when(
      highway == "cycleway" ~ "Level track",
      highway == "pedestrian" ~ "Stepped or footway",
      highway == "path" ~ "Stepped or footway",
      # these by default are not shared with traffic:
      segregated == "yes" ~ "Stepped or footway",
      segregated == "no" ~ "Stepped or footway",
      TRUE ~ "Mixed traffic"
    )) |>
    # ...including by name
    dplyr::mutate(detailed_segregation = dplyr::case_when(
      # highways named towpaths or paths are assumed to be off-road
      stringr::str_detect(name, "Path|Towpath|Railway|Trail") &
        detailed_segregation %in% c("Level track", "Stepped or footway") ~ "Remote cycle track",
      TRUE ~ detailed_segregation
    )) |>
    # When distance to road is more than min_distance m (and highway = cycleway|pedestrian|path), change to Remote cycle track
    dplyr::mutate(detailed_segregation = dplyr::case_when(
      distance_to_road > min_distance & detailed_segregation %in% c("Level track", "Stepped or footway") ~ "Remote cycle track",
      TRUE ~ detailed_segregation
    )) |>
    tidyr::unite("cycleway_chars", dplyr::starts_with("cycleway"), sep = "|", remove = FALSE) |>
    dplyr::mutate(detailed_segregation = dplyr::case_when(
      stringr::str_detect(cycleway_chars, "lane") & detailed_segregation == "Mixed traffic" ~ "Cycle lane on carriageway",
      stringr::str_detect(cycleway_chars, "track") & detailed_segregation == "Mixed traffic" ~ "Light segregation",
      stringr::str_detect(cycleway_chars, "separate") & detailed_segregation == "Mixed traffic" ~ "Stepped or footway",
      stringr::str_detect(cycleway_chars, "buffered_lane") & detailed_segregation == "Mixed traffic" ~ "Cycle lane on carriageway",
      stringr::str_detect(cycleway_chars, "segregated") & detailed_segregation == "Mixed traffic" ~ "Stepped or footway",
      TRUE ~ detailed_segregation
    )) |>
    dplyr::mutate(cycle_segregation = dplyr::case_when(
      detailed_segregation %in% c("Level track", "Light segregation", "Stepped or footway") ~ "Separated cycle track",
      TRUE ~ detailed_segregation
    )) |>
    dplyr::mutate(cycle_segregation = factor(
      cycle_segregation,
      levels = c("Remote cycle track", "Separated cycle track", "Cycle lane on carriageway", "Mixed traffic"),
      ordered = TRUE
    ))
}

# Classify Separated cycle track by width and 

#' Create a tmap object for visualizing the classified cycle network
#'
#' @param cycle_network_classified An sf object with the classified cycle network
#' @param popup.vars A vector of variables to be displayed in the popup
#' @param lwd The line width for the cycle network
#' @param palette The palette to be used for the cycle segregation levels
#' @return A tmap object for visualizing the classified cycle network
#' @export
plot_osm_tmap = function(
    cycle_network_classified,
    popup.vars = c("name", "cycle_segregation", "distance_to_road", "maxspeed", "highway", "cycleway", "other_tags"),
    lwd = 4,
    palette = "-PuBuGn") {
  # Stop if tmap is not installed or if the version is less than 3.99:
  if (!requireNamespace("tmap", quietly = TRUE)) {
    stop("tmap is not installed. Please install tmap to use this function.")
  }
  if (packageVersion("tmap") < "3.99") {
    stop("Please update tmap to version 3.99 or higher.")
  }
  # Subset popup.vars to include only those that are present in the data:
  popup.vars = popup.vars[popup.vars %in% names(cycle_network_classified)]
  Infrastructure = cycle_network_classified |>
    dplyr::arrange(desc(cycle_segregation))
  tmap::tm_shape(Infrastructure) +
    tmap::tm_lines(
      col = "cycle_segregation",
      lwd = lwd,
      col.scale = tmap::tm_scale_categorical(values = palette),
      popup.vars = popup.vars,
      plot.order = tmap::tm_plot_order("DATA"),
      # Change legend title:
      col.legend = tmap::tm_legend(title = "Infrastructure type")
    ) +
    # Add scale bar
    tmap::tm_scalebar(position = c("left", "bottom")) +
    tmap::tm_layout(basemap.server = basemaps())
}

basemaps = function() {
  c(
    # Grey background:
    "Esri.WorldGrayCanvas",
    # CyclOSM:
    "CyclOSM",
    # OpenStreetMap:
    "OpenStreetMap"
  )
}

# Function: most_common_value
# Description: This function takes a vector as input and returns the most common value in the vector.
# Parameters:
#   - x: A vector of values
# Returns:
#   - The most common value in the vector, or NA if the vector is empty or contains only NA values.
most_common_value = function(x) {
  if (length(x) == 0) {
    return(NA)
  } else {
    # Remove NA values if length X is greater than 1 and there are non NA values:
    x = x[!is.na(x)]
    res = names(sort(table(x), decreasing = TRUE)[1])
    if (is.null(res)) {
      return(NA)
    } else {
      return(res)
    }
  }
}

#' Clean speeds
#'
#' @param osm An sf object with the road network
#' @return An sf object with the cleaned speed values in the column `maxspeed_clean`
#' @export
#' @examples
#' osm = osm_edinburgh
#' osm_cleaned = clean_speeds(osm)
#' # check NAs:
#' sel_nas = is.na(osm_cleaned$maxspeed_clean)
#' osm_no_maxspeed = osm_cleaned[sel_nas, c("highway")]
#' table(osm_no_maxspeed$highway) # Active travel infrastructure has no maxspeed
#' table(osm_cleaned$maxspeed)
#' table(osm_cleaned$maxspeed_clean)
#' plot(osm_cleaned[c("maxspeed", "maxspeed_clean")])
clean_speeds = function(osm) {
  osm = osm |>
    dplyr::mutate(
      maxspeed_clean = dplyr::case_when(
        maxspeed == "national" & highway %in% c("motorway", "motorway_link") ~ "70 mph",
        maxspeed == "national" & !highway %in% c("motorway", "motorway_link") ~ "60 mph",
        TRUE ~ maxspeed
      )
    )

  osm$maxspeed_clean = gsub(" mph", "", osm$maxspeed_clean)
  osm$maxspeed_clean = as.numeric(osm$maxspeed_clean)

  osm = osm |>
    dplyr::mutate(
      maxspeed_clean = dplyr::case_when(
        !is.na(maxspeed_clean) ~ maxspeed_clean,
        highway == "residential" ~ 20,
        highway == "service" ~ 20,
        highway == "unclassified" ~ 20,
        highway == "tertiary" ~ 30,
        highway == "tertiary_link" ~ 30,
        highway == "secondary" ~ 30,
        highway == "secondary_link" ~ 30,
        highway == "primary" ~ 40,
        highway == "primary_link" ~ 40,
        highway == "trunk" ~ 60,
        highway == "trunk_link" ~ 60,
      )
    )
  osm = sf::st_sf(
    osm |> sf::st_drop_geometry(),
    geometry = sf::st_geometry(osm)
  )
  osm
}

#' Estimate traffic
#'
#' @param osm An sf object with the road network
#' @return An sf object with the estimated road traffic volumes in the column `assumed_volume`
#' @export
#' @examples
#' osm = osm_edinburgh
#' osm_traffic = estimate_traffic(osm)
#' # check NAs:
#' sel_nas = is.na(osm_traffic$assumed_volume)
#' osm_no_traffic = osm_traffic[sel_nas, c("highway")]
#' table(osm_no_traffic$highway) # Active travel infrastructure has no road traffic
#' table(osm_traffic$assumed_volume, useNA = "always")
estimate_traffic = function(osm) {
  osm = osm|>
    dplyr::mutate(
      assumed_volume = dplyr::case_when(
        highway == "motorway" ~ 20000,
        highway == "motorway_link" ~ 20000,
        highway == "trunk" ~ 8000,
        highway == "trunk_link" ~ 8000,
        highway == "primary" ~ 6000,
        highway == "primary_link" ~ 6000,
        highway == "secondary" ~ 5000,
        highway == "secondary_link" ~ 5000,
        highway == "tertiary" ~ 3000,
        highway == "tertiary_link" ~ 3000,
        highway == "residential" ~ 1000,
        highway == "service" ~ 500,
        highway == "unclassified" ~ 1000
      )
    )
  osm = sf::st_sf(
    osm |> sf::st_drop_geometry(),
    geometry = sf::st_geometry(osm)
  )
  osm
}


#' Generate Cycle by Design Level of Service
#'
#' @param osm An sf object with the road network including speed limits and traffic volumes
#' @return An sf object with the Cycle by Design Level of Service in the column `Level of Service`
#' @export
level_of_service = function(osm) {
  osm = osm |>
    dplyr::mutate(`Level of Service` = dplyr::case_when(
      detailed_segregation == "Remote cycle track" ~ "High",
      detailed_segregation == "Level track" & final_speed <= 30 ~ "High",
      detailed_segregation == "Stepped or footway" & final_speed <= 20 ~ "High",
      detailed_segregation == "Stepped or footway" & final_speed == 30 & final_traffic < 4000 ~ "High",
      detailed_segregation == "Light segregation" & final_speed <= 20 ~ "High",
      detailed_segregation == "Light segregation" & final_speed == 30 & final_traffic < 4000 ~ "High",
      detailed_segregation == "Cycle lane on carriageway" & final_speed <= 20 & final_traffic < 4000 ~ "High",
      detailed_segregation == "Cycle lane on carriageway" & final_speed == 30 & final_traffic < 1000 ~ "High",
      detailed_segregation == "Mixed traffic" & final_speed <= 20 & final_traffic < 2000 ~ "High",
      detailed_segregation == "Mixed traffic" & final_speed == 30 & final_traffic < 1000 ~ "High",

      detailed_segregation == "Level track" & final_speed == 40 ~ "Medium",
      detailed_segregation == "Level track" & final_speed == 50 & final_traffic < 1000 ~ "Medium",
      detailed_segregation == "Stepped or footway" & final_speed <= 40 ~ "Medium",
      detailed_segregation == "Stepped or footway" & final_speed == 50 & final_traffic < 1000 ~ "Medium",
      detailed_segregation == "Light segregation" & final_speed == 30 ~ "Medium",
      detailed_segregation == "Light segregation" & final_speed == 40 & final_traffic < 2000 ~ "Medium",
      detailed_segregation == "Light segregation" & final_speed == 50 & final_traffic < 1000 ~ "Medium",
      detailed_segregation == "Cycle lane on carriageway" & final_speed <= 20 ~ "Medium",
      detailed_segregation == "Cycle lane on carriageway" & final_speed == 30 & final_traffic < 4000 ~ "Medium",
      detailed_segregation == "Cycle lane on carriageway" & final_speed == 40 & final_traffic < 1000 ~ "Medium",
      detailed_segregation == "Mixed traffic" & final_speed <= 20 & final_traffic < 4000 ~ "Medium",
      detailed_segregation == "Mixed traffic" & final_speed == 30 & final_traffic < 2000 ~ "Medium",
      detailed_segregation == "Mixed traffic" & final_speed == 40 & final_traffic < 1000 ~ "Medium",


      detailed_segregation == "Level track" ~ "Low",
      detailed_segregation == "Stepped or footway" ~ "Low",
      detailed_segregation == "Light segregation" & final_speed <= 50 ~ "Low",
      detailed_segregation == "Light segregation" & final_speed == 60 & final_traffic < 1000 ~ "Low",
      detailed_segregation == "Cycle lane on carriageway" & final_speed <= 50 ~ "Low",
      detailed_segregation == "Cycle lane on carriageway" & final_speed == 60 & final_traffic < 1000 ~ "Low",
      detailed_segregation == "Mixed traffic" & final_speed <= 30 ~ "Low",
      detailed_segregation == "Mixed traffic" & final_speed == 40 & final_traffic < 2000 ~ "Low",
      detailed_segregation == "Mixed traffic" & final_speed == 60 & final_traffic < 1000 ~ "Low",

      detailed_segregation == "Light segregation" ~ "Should not be used",
      detailed_segregation == "Cycle lane on carriageway" ~ "Should not be used",
      detailed_segregation == "Mixed traffic" ~ "Should not be used",
      TRUE ~ "Unknown"
    )) |>
    dplyr::mutate(`Level of Service` = factor(
      `Level of Service`,
      levels = c("High", "Medium", "Low", "Should not be used"),
      ordered = TRUE
    ))
  osm = sf::st_sf(
    osm |> sf::st_drop_geometry(),
    geometry = sf::st_geometry(osm)
  )
  osm
}


#' Data from edinburgh's OSM network
#'
#'
#' @docType data
#' @keywords datasets
#' @name osm_edinburgh
#' @format An sf data frame
#' @examples
#' library(sf)
#' names(osm_edinburgh)
#' head(osm_edinburgh)
#' plot(osm_edinburgh)
NULL

#' Data from edinburgh's OSM network with traffic volumes
#'
#' @docType data
#' @keywords datasets
#' @name traffic_volumes_edinburgh
#' @aliases traffic_random_edinburgh
#' @format A data frame
#' @examples
#' head(traffic_volumes_edinburgh)
#' head(traffic_random_edinburgh)
NULL

# Ignore globals:
utils::globalVariables(c("exclude_highway_cycling", "exclude_bicycle_cycling", "exclude_highway_driving", "highway"))
