#' This function returns OSM keys that are relevant for active travel
#'
#' @export
et_active = function() {
  c(
    "name",
    "ref",
    "oneway",
    "maxspeed",
    "bicycle",
    "cycleway",
    "cycleway:left",
    "cycleway:right",
    "cycleway:both",
    "cycleway:left:bicycle",
    "cycleway:right:bicycle",
    "cycleway:both:bicycle",
    "cycleway:left:segregated",
    "cycleway:right:segregated",
    "cycleway:both:segregated",
    "cycleway:lane",
    "cycleway:left:lane",
    "cycleway:right:lane",
    "cycleway:both:lane",
    "cycleway:surface",
    "cycleway:width",
    "cycleway:est_width",
    "cycleway:buffered_lane",
    # Use relations not tags for networks:
    # "lcn",
    "lanes",
    "lanes:both_ways",
    "lanes:forward",
    "lanes:backward",
    "lit", # useful to check if cycleways are lit
    "oneway",
    "width", # To check if width is compliant with guidance
    "est_width", # in some cases present but width is missing
    "segregated",
    "foot",
    "path",
    "sidewalk",
    "sidewalk:left",
    "sidewalk:right",
    "sidewalk:both",
    "footway",
    "service",
    "surface",
    "tracktype",
    "smoothness",
    "access",
    # Additional tags with info on psv and bus lanes:
    "bus",
    "busway",
    "psv",
    "lanes:psv",
    "lanes:bus",
    "lanes:bus:conditional",
    "lanes:bus:backward",
    "lanes:bus:forward",
    "lanes:psv:backward",
    "lanes:psv:forward",
    "lanes:psv:conditional",
    "lanes:psv:conditional:backward",
    "lanes:psv:conditional:forward",
    "lanes:psv:conditional:both_ways",
    "lanes:psv:both_ways",
    "lanes:psv:backward",
    "lanes:psv:forward"
  )
}

#' Count how many bus lanes there are
#' @param osm An sf object with the road network
#' @return The number of bus lanes
#' @export
#' @examples
#' osm = osm_edinburgh
#' count_bus_lanes(osm)
count_bus_lanes = function(osm) {
  osm = sf::st_drop_geometry(osm)
  names_matching_psv_bus = grepl("lanes_bus|lanes_psv", names(osm))
  message("Matched these columns: ", names(osm)[names_matching_psv_bus])
  # Count the number of bus lanes per row:
  osm_lanes = osm[names_matching_psv_bus]
  # Convert to numeric and sum the number of bus lanes:
  suppressWarnings({
    osm_lanes_numeric = lapply(osm_lanes, as.numeric) |>
      as.data.frame()
  })
  n_bus_lanes = rowSums(osm_lanes_numeric, na.rm = TRUE)
  # summary(n_bus_lanes)
  n_bus_designated = grepl("designated", osm$bus) |>
    as.numeric() +
    grepl("lane", osm$busway)
  n_psv_designated = grepl("designated", osm$psv) |>
    as.numeric()
  n_bus_lanes = n_bus_lanes + n_bus_designated + n_psv_designated
  n_bus_lanes
}

# # # Test if lanes:psv:backwards is present

# osm = get_travel_network("edinburgh")
# osm_example = "Corstorphine Road"
# osm_f = osm |>
#   dplyr::filter(name == osm_example)
# osm$other_tags[1]
# table(osm$lanes_psv_backward)
# table(osm$n_bus_lanes)
# # Another test:
# osm_princes_street = osm |>
#   dplyr::filter(name == "Princes Street")
# summary(osm_princes_street$n_bus_lanes)
# osm_princes_street$bus
# osm_bus = osm |>
#   dplyr::filter(n_bus_lanes > 0)
# mapview::mapview(osm_bus, zcol = "n_bus_lanes")
# write osm_bus to file:S
# Exclude highway values for utility cycling
exclude_highway_cycling = function() {
  to_exclude = paste0(
    "abandoned|bridleway|bus_guideway|byway|construction|corridor|disused|elevator|emergency|escalator|escap",
    "|far|fixme|gallop|historic|motorway|no|planned|platform|proposed|raceway|rest|road|services|steps|track"
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
    dplyr::filter(is.na(service)) |>
    dplyr::select(-dplyr::matches(columns_to_remove))
  osm_highways$n_bus_lanes = count_bus_lanes(osm_highways)
  osm_highways
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
  ex_d = exclude_highway_driving()
) {
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
  pattern = "motorway|trunk|primary|secondary|tertiary"
) {
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
  ex_b = exclude_bicycle_cycling()
) {
  osm |>
    dplyr::filter(!stringr::str_detect(string = highway, pattern = ex_c)) |>
    # Exclude roads where cycling is banned, plus mtb paths and related tags
    dplyr::filter(
      is.na(bicycle) | !stringr::str_detect(string = bicycle, pattern = ex_b)
    ) |>
    # Remove highway=path|pedestrian|footway without bicycle value of designated or yes:
    # Or segments if surface is not defined:
    dplyr::filter(
      !(highway %in%
        c("path", "footway", "pedestrian") &
        (surface %in%
          c(
            "ground",
            "unpaved",
            "grass",
            "compacted",
            "gravel",
            "sand",
            "dirt",
            "wood"
          ) |
          smoothness %in%
            c("very_bad", "horrible", "very_horrible", "impassable") |
          !stringr::str_detect(string = bicycle, pattern = "designated|yes")))
    ) |>
    # Remove any segments with cycleway*=="separate"
    # They are mapped as separate geometries that should be included
    # dplyr::filter(!(cycleway %in% "separate" & oneway == "yes")) |>
    # dplyr::filter(!(cycleway_both %in% "separate" & lanes == 1)) |>
    dplyr::filter(!(cycleway_left %in% "separate" & oneway %in% "yes")) |>
    dplyr::filter(!(cycleway_right %in% "separate" & oneway %in% "yes"))
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
#' @param include_mixed_traffic Whether to include mixed traffic segments in the results.
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
#' plot_osm_tmap(netc)
#' # Interactive map:
#' # tmap_mode("view")
#' # plot_osm_tmap(netc)
classify_cycle_infrastructure = function(
  osm,
  min_distance = 20,
  classification_type = "Scotland",
  include_mixed_traffic = FALSE
) {
  if (classification_type == "Scotland") {
    infra = classify_cycle_infrastructure_scotland(
      osm,
      min_distance,
      include_mixed_traffic
    )
    return(infra)
  } else {
    stop(
      "Classification type not supported yet. Please open an issue at github.com/nptscot/osmactive."
    )
  }
}

classify_cycle_infrastructure_scotland = function(
  osm,
  min_distance = 9.9,
  include_mixed_traffic = FALSE
) {
  segtypes = c("Level track", "Light segregation")
  osm_classified = osm |>
    # If highway == cycleway|pedestrian|path, detailed_segregation can be defined in most cases...
    dplyr::mutate(
      detailed_segregation = dplyr::case_when(
        highway == "cycleway" ~ "Level track",
        highway %in%
          c("footway", "path", "Pedestrian") &
          segregated %in% c("no", NA) ~
          "Footway",
        segregated %in% "yes" ~ "Level track",
        TRUE ~ "Mixed Traffic Street"
      )
    ) |>
    # ...including by name
    dplyr::mutate(
      detailed_segregation = dplyr::case_when(
        # highways named towpaths or paths are assumed to be off-road
        stringr::str_detect(name, "Path|Towpath|Railway|Trail") &
          detailed_segregation %in% segtypes ~
          "Off Road Path",
        TRUE ~ detailed_segregation
      )
    ) |>
    # Add cycle_pedestrian_separation:
    classify_shared_use() |>
    # When distance to road is more than min_distance m (and highway = cycleway|pedestrian|path), change to Off Road Path
    dplyr::mutate(
      detailed_segregation = dplyr::case_when(
        distance_to_road > min_distance & detailed_segregation %in% segtypes ~
          "Off Road Path",
        TRUE ~ detailed_segregation
      )
    ) |>
    tidyr::unite(
      "cycleway_chars",
      dplyr::starts_with("cycleway"),
      sep = "|",
      remove = FALSE
    ) |>
    dplyr::mutate(
      detailed_segregation = dplyr::case_when(
        stringr::str_detect(cycleway_chars, "lane|share_") &
          detailed_segregation == "Mixed Traffic Street" ~
          "Painted Cycle Lane",
        stringr::str_detect(cycleway_chars, "track") &
          detailed_segregation == "Mixed Traffic Street" ~
          "Light segregation",
        stringr::str_detect(cycleway_chars, "segregated") &
          detailed_segregation == "Mixed Traffic Street" ~
          "Footway",
        TRUE ~ detailed_segregation
      )
    )
  # For cycleway:left:segregated" and "cycleway:right:segregated"
  if (
    "cycleway_left_segregated" %in%
      names(osm_classified) &
      "cycleway_right_segregated" %in% names(osm_classified)
  ) {
    osm_classified = osm_classified |>
      dplyr::mutate(
        detailed_segregation = dplyr::case_when(
          cycleway_left_segregated == "yes" |
            cycleway_right_segregated == "yes" ~
            "Light segregation",
          TRUE ~ detailed_segregation
        )
      )
  }
  osm_classified = osm_classified |>
    clean_widths() |>
    dplyr::mutate(
      cycle_segregation = dplyr::case_when(
        detailed_segregation %in% segtypes & is_wide(width_clean) ~
          "Segregated Track (wide)",
        detailed_segregation %in% segtypes & !is_wide(width_clean) ~
          "Segregated Track (narrow)",
        # Shared Footway:
        detailed_segregation == "Footway" ~ "Shared Footway",
        (cycle_pedestrian_separation != "Unknown" &
          detailed_segregation != "Off Road Path") |
          (cycle_pedestrian_separation == "Shared Footway (not segregated)" &
            detailed_segregation == "Off Road Path" &
            highway != "cycleway") ~
          "Shared Footway",
        TRUE ~ detailed_segregation
      )
    ) |>
    # Switch non off-road cycleways to "Shared Footway" if they are not segregated:
    dplyr::mutate(
      cycle_segregation = dplyr::case_when(
        cycle_segregation %in%
          c("Segregated Track (wide)", "Segregated Track (narrow)") &
          cycle_pedestrian_separation == "Shared Footway (not segregated)" ~
          "Shared Footway",
        TRUE ~ cycle_segregation
      )
    ) |>
    dplyr::mutate(
      cycle_segregation = dplyr::case_when(
        highway == "cycleway" & 
          !is.na(segregated) & segregated == "no" & 
          !is.na(foot) & foot == "designated" & 
          !is.na(bicycle) & bicycle == "designated" ~ "Off Road Path",
          !is.na(bicycle) & bicycle == "designated" & 
          (is.na(segregated) | segregated == "no") ~ "Off Road Path",
        TRUE ~ as.character(cycle_segregation) 
      )
    ) |>
    dplyr::mutate(
      cycle_segregation = factor(
        cycle_segregation,
        levels = c(
          "Segregated Track (wide)",
          "Off Road Path",
          "Segregated Track (narrow)",
          "Shared Footway",
          "Painted Cycle Lane",
          "Mixed Traffic Street"
        ),
        ordered = TRUE
      )
    )
  # Remove mixed traffic if not required:
  if (!include_mixed_traffic) {
    osm_classified = osm_classified |>
      dplyr::filter(cycle_segregation != "Mixed Traffic Street") |>
      dplyr::mutate(cycle_segregation = as.character(cycle_segregation)) |>
      dplyr::mutate(
        cycle_segregation = factor(
          cycle_segregation,
          levels = c(
            "Segregated Track (wide)",
            "Off Road Path",
            "Segregated Track (narrow)",
            "Shared Footway",
            "Painted Cycle Lane"
          ),
          ordered = TRUE
        )
      )
  }
  osm_classified
}

#' Classify ways by level of pedestrian/cyclist sharing
#'
#' Ways on which bicycles and pedestrians share space are classified as "Shared Footway".
#' According to
#'
#' tagging includes:
#'
#' - highway=path (signposted foot and bicycle path, no dividing line)
#'   + foot=designated
#'   + bicycle=designated
#'   + segregated=no
#'
#' - highway=path (Signposted foot and bicycle path with dividing line.)
#'   + segregated=yes
#'
#' - highway=pedestrian (A way intended for pedestrians)
#' @param osm An sf object with the road network
#' @return An sf object with the classified cycle network
#' @export
#' @examples
#' osm = osm_edinburgh
#' cycle_network = get_cycling_network(osm)
#' cycle_network_shared = classify_shared_use(cycle_network)
#' table(cycle_network_shared$cycle_pedestrian_separation)
#' plot(cycle_network_shared["cycle_pedestrian_separation"])
#' # interactive map:
#' # mapview::mapview(cycle_network_shared, zcol = "cycle_pedestrian_separation")
classify_shared_use = function(osm) {
  osm |>
    dplyr::mutate(
      cycle_pedestrian_separation = dplyr::case_when(
        # Walking is permitted:
        (highway == "footway" |
          highway == "path" |
          highway == "pedestrian" |
          foot == "designated") &
          # Bicycle also permitted:
          (bicycle == "designated" | highway == "path") ~
          "Shared Footway (not segregated)",
        TRUE ~ "Unknown"
      )
    ) |>
    dplyr::mutate(
      cycle_pedestrian_separation = dplyr::case_when(
        # differentiate between segregated and non-segregated shared use:
        cycle_pedestrian_separation == "Shared Footway (not segregated)" &
          segregated == "yes" ~
          "Shared Footway (segregated)",
        TRUE ~ cycle_pedestrian_separation
      )
    ) |>
    dplyr::mutate(
      cycle_pedestrian_separation = factor(
        cycle_pedestrian_separation,
        levels = c(
          "Shared Footway (segregated)",
          "Shared Footway (not segregated)",
          "Unknown"
        ),
        ordered = TRUE
      )
    )
}

#' Clean cycleway widths (use est_widths when available and width otherwise)
#'
#' @param osm An sf object with the road network
#' @return An sf object with the cleaned cycleway widths in the column `width`
#' @export
#' @examples
#' osm = osm_edinburgh
#' osm$width
#' osm$est_width = NA
#' osm$est_width[1:3] = 2
#' osm_cleaned = clean_widths(osm)
#' osm$width
#' osm_cleaned$width
clean_widths = function(osm) {
  # If cycleway_width is present, use it:
  if ("cycleway_width" %in% names(osm)) {
    cycleway_width_not_nas = !is.na(osm$cycleway_width)
    osm$width[cycleway_width_not_nas] = osm$cycleway_width[
      cycleway_width_not_nas
    ]
  }
  # Check if the est_width column is present and skip if not:
  if (!"est_width" %in% names(osm) || !"cycleway_est_width" %in% names(osm)) {
    suppressWarnings({
      osm$width_clean = as.numeric(osm$width)
    })
    return(osm)
  }
  suppressWarnings({
    width = as.numeric(osm$width)
    est_width = as.numeric(osm$est_width)
    cycleway_est_width = as.numeric(osm$cycleway_est_width)
    # when cycleway_est_width is present, use it:
    est_width[!is.na(cycleway_est_width)] = cycleway_est_width[
      !is.na(cycleway_est_width)
    ]
  })
  width[is.na(width)] = 0
  est_width[is.na(est_width)] = 0
  osm$width_clean = dplyr::case_when(
    est_width > 0 & width == 0 ~ est_width,
    TRUE ~ width
  )
  osm
}

#' Classify Separated cycle track by width
#'
#' This function classifies cycleways as wide if the width is greater than or equal to `min_width`.
#' NA values are replaced with 0, meaning that ways with no measurement are considered narrow.
#'
#' @param x A numeric vector with the width of the cycleway (m)
#' @param min_width The minimum width for a cycleway to be considered wide (m)
#' @return A logical vector indicating whether the cycleway is wide
#' @export
#' @examples
#' x = osm_edinburgh$width
#' x
#' is_wide(x)
is_wide = function(x, min_width = 2) {
  suppressWarnings({
    x = as.numeric(x)
  })
  x[is.na(x)] = 0
  x >= min_width
}

#' Get the palette for the NPT cycle segregation levels
#' @return A palette for the NPT cycle segregation levels
#' @export
#' @examples
#' cols = get_palette_npt()
#' jsonlite::toJSON(as.list(cols), pretty = TRUE)
#' col_labs = c("OffRd", "SegW", "SegN", "Share", "Paint")
#' barplot(seq_along(cols), col = cols, names.arg = col_labs)
get_palette_npt = function() {
  palette_npt = c(
    "Segregated Track (wide)" = "#054d05", # Dark Green
    "Off Road Path" = "#3a9120", # Medium Green
    "Segregated Track (narrow)" = "#87d668", # Light Green
    "Shared Footway" = "#ffbf00", # Amber
    "Painted Cycle Lane" = "#FF0000" # Red
  )
  return(palette_npt)
}

#' Create a tmap object for visualizing the classified cycle network
#'
#' @param cycle_network_classified An sf object with the classified cycle network
#' @param popup.vars A vector of variables to be displayed in the popup
#' @param lwd The line width for the cycle network
#' @param palette The palette to be used for the cycle segregation levels,
#'   such as "-PuBuGn" or "npt" (default)
#' @return A tmap object for visualizing the classified cycle network
#' @export
plot_osm_tmap = function(
  cycle_network_classified,
  popup.vars = c(
    "name",
    "osm_id",
    "cycle_segregation",
    "distance_to_road",
    "maxspeed",
    "highway",
    "cycleway",
    "bicycle",
    "lanes",
    "width",
    "surface",
    "other_tags"
  ),
  lwd = 4,
  palette = get_palette_npt()
) {
  # Stop if tmap is not installed or if the version is less than 3.99:
  if (!requireNamespace("tmap", quietly = TRUE)) {
    stop("tmap is not installed. Please install tmap to use this function.")
  }
  if (utils::packageVersion("tmap") < "3.99") {
    stop("Please update tmap to version 3.99 or higher.")
  }
  # Add clean width if available:
  if ("width_clean" %in% names(cycle_network_classified)) {
    popup.vars = c(popup.vars, "width_clean")
  }
  # Subset popup.vars to include only those that are present in the data:
  popup.vars = popup.vars[popup.vars %in% names(cycle_network_classified)]
  Infrastructure = cycle_network_classified |>
    dplyr::arrange(dplyr::desc(cycle_segregation)) |>
    # Truncate the other_tags column to everything before the 5th comma and
    # add "..." to the other_tags column if it contains more than 5 commas:
    dplyr::mutate(
      other_tags = dplyr::case_when(
        stringr::str_count(other_tags, ",") > 5 ~
          paste0(
            stringr::str_extract(other_tags, "([^,]*,){0,4}[^,]*"),
            " ..."
          ),
        TRUE ~ other_tags
      )
    ) |>
    dplyr::select(all_of(popup.vars), cycle_segregation)
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
    tmap::tm_layout(basemap.server = basemaps()) +
    # TODO: remove this when the following issue is fixed:
    # https://github.com/r-tmap/tmap/issues/1064
    tmap::tm_view(use_WebGL = FALSE)
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
        maxspeed == "national" & highway %in% c("motorway", "motorway_link") ~
          "70 mph",
        maxspeed == "national" & !highway %in% c("motorway", "motorway_link") ~
          "60 mph",
        TRUE ~ maxspeed
      )
    )

  osm$maxspeed_clean = gsub(" mph", "", osm$maxspeed_clean)
  osm$maxspeed_clean = as.numeric(osm$maxspeed_clean)

  # TODO: add different rules for urban vs rural
  # Regex for different speeds:
  r_na = "footway|cycleway|path|pedestrian|razed"
  r10 = "service"
  r30 = "residential"
  # Compromise between urban being 60 default and rural 30/40:
  r40 = "primary|secondary|tertiary"
  r60 = "trunk"
  r70 = "motorway"

  osm = osm |>
    dplyr::mutate(
      maxspeed_clean = dplyr::case_when(
        !is.na(maxspeed_clean) ~ maxspeed_clean,
        # Default speeds based on highway type for untagged roads:
        # lit == "yes" ~ 20, # Keep lit rule commented out
        stringr::str_detect(highway, r_na) ~ NA_real_,
        stringr::str_detect(highway, r10) ~ 10, 
        stringr::str_detect(highway, r30) ~ 30, 
        stringr::str_detect(highway, r40) ~ 40,
        stringr::str_detect(highway, r60) ~ 60,
        stringr::str_detect(highway, r70) ~ 70,
        TRUE ~ NA_real_
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
  osm = osm |>
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
        highway == "residential" ~ 500,
        highway == "service" ~ 500,
        highway == "unclassified" ~ 500,
        stringr::str_detect(highway, pattern = "living") ~ 500,
        highway == "pedestrian" ~ NA_real_,
        highway == "footway" ~ NA_real_,
        highway == "cycleway" ~ NA_real_,
        highway == "path" ~ NA_real_
      )
    )
  osm = sf::st_sf(
    osm |> sf::st_drop_geometry(),
    geometry = sf::st_geometry(osm)
  )
  osm
}

#' Classify Speeds
#'
#' This function classifies speeds in miles per hour (mph) into categories.
#'
#' @param speed_mph A numeric vector representing speeds in miles per hour.
#' @return A character vector with the speed categories.
#' @export 
#' @examples
#' classify_speeds(c(15, 25, 35, 45, 55, 65))
#' # Returns: "<20 mph", "20 mph", "30 mph", "40 mph", "50 mph", "60+ mph"
classify_speeds = function(speed_mph) {
  dplyr::case_when(
    speed_mph < 20 ~ "<20 mph",
    speed_mph < 30 ~ "20 mph",
    speed_mph < 40 ~ "30 mph",
    speed_mph < 50 ~ "40 mph",
    speed_mph < 60 ~ "50 mph",
    speed_mph >= 60 ~ "60+ mph"
  )
}



#' Convert AADT categories to CBD AADT character ranges
#'
#' This function takes an AADT (Annual Average Daily Traffic) category and converts it to a ranges
#'
#' @param AADT A character vector representing AADT categories. Valid categories include "0 to 1000", "0 to 2000", "1000+", "All", "1000 to 2000", "2000 to 4000", "2000+", and "4000+".
#' @return A character vector with the converted CBD AADT ranges. Possible return values are "0 to 999", "1000 to 1999", "2000 to 3999", and "4000+".
#' @export
#' @examples
#' npt_to_cbd_aadt_character("0 to 1000") # returns "0 to 999"
#' npt_to_cbd_aadt_character("1000 to 2000") # returns "1000 to 1999"
#' npt_to_cbd_aadt_character("2000 to 4000") # returns "2000 to 3999"
#' npt_to_cbd_aadt_character("4000+") # returns "4000+"
npt_to_cbd_aadt_character = function(AADT) {
  dplyr::case_when(
      AADT %in% c("0 to 1000", "All", "0 to 999") ~ "0 to 999",
      AADT %in% c("1000 to 2000", "1000+", "1000 to 1999") ~ "1000 to 1999",
      AADT %in% c("2000 to 4000", "2000+") ~ "2000 to 3999",      
      AADT %in% c("4000+") ~ "4000+"
    )
}

#' Convert AADT categories to CBD AADT character ranges
#'
#' This function takes an AADT (Annual Average Daily Traffic) category and converts it to a ranges
#'
#' @param AADT A numeric vector representing AADT
#' @return A character vector with the converted CBD AADT ranges. Possible return values are "0 to 999", "1000 to 1999", "2000 to 3999", and "4000+".
#' @export
npt_to_cbd_aadt_numeric = function(AADT) {
  dplyr::case_when(
    AADT < 1000 ~ "0 to 999",
    AADT < 2000 ~ "1000 to 1999",
    AADT < 4000 ~ "2000 to 3999",
    AADT >= 4000 ~ "4000+"
  )
}
#' Convert AADT to CBD AADT
#'
#' This function converts Annual Average Daily Traffic (AADT) to Central Business District (CBD) AADT.
#' It handles both character and numeric inputs by delegating to appropriate helper functions.
#'
#' @param AADT A character or numeric value representing the Annual Average Daily Traffic.
#' @return The converted CBD AADT value.
#' @export
npt_to_cbd_aadt = function(AADT) {
  # If it's character:
  if (is.character(AADT)) {
    return(npt_to_cbd_aadt_character(AADT))
  } else {
    return(npt_to_cbd_aadt_numeric(AADT))
  }
}
#' Generate Cycle by Design Level of Service
#' 
#' Note: you need to have Annual Average Daily Traffic (AADT) values in the dataset
#' These can be estimated using the `estimate_traffic()` function and converted
#' to CbD AADT categories using the `npt_to_cbd_aadt()` function.
#'
#' @param osm An sf object with the road network including speed limits and traffic volumes
#' @return An sf object with the Cycle by Design Level of Service in the column `Level of Service`
#' @export
#' @examples 
#' osm = osm_edinburgh
#' # Get infrastructure type:
#' cycle_net = get_cycling_network(osm)
#' # Get driving network:
#' driving_net = get_driving_network(osm)
#' # Get distance to road:
#' osm = distance_to_road(cycle_net, driving_net)
#' # Classify cycle infrastructure:
#' osm = classify_cycle_infrastructure(osm, include_mixed_traffic = TRUE)
#' osm = estimate_traffic(osm)
#' osm$AADT = npt_to_cbd_aadt_numeric(osm$assumed_volume)
#' osm$infrastructure = osm$cycle_segregation
#' osm_los = level_of_service(osm)
#' plot(osm_los["Level of Service"])
#' # mapview::mapview(osm_los, zcol = "Level of Service")
#' # Test LoS on known road:
#' mill_lane = data.frame(
#'   # TODO: find out why highway is needed for LoS
#'   highway = "residential",
#'   AADT = "4000+",
#'   maxspeed = "20 mph",
#'   cycle_segregation = "Mixed Traffic Street"
#' )
#' #
#' osm = sf::st_as_sf(mill_lane, geometry = osm$geometry[1])
#' mill_lane_los = level_of_service(osm)
#' mill_lane_los
#' #
level_of_service = function(osm) {
  # Add final_speed column if not present:
  if (!"Speed Limit (mph)" %in% names(osm)) {
    osm = clean_speeds(osm)
    osm$`Speed Limit (mph)` = classify_speeds(osm$maxspeed_clean)
  }
  if (!"AADT" %in% names(osm)) {
    stop("Required column AADT, with AADT categories from the Cycling by Design Guidance, not found in the input data.")
  }
  # If the column 'infrastructure' is not present, add it:
  if (!"infrastructure" %in% names(osm)) {
    osm$infrastructure = osm$cycle_segregation
    # # Remove the old column 'cycle_segregation':
    # osm$cycle_segregation = NULL
  }
  
  # names in both:
  names_in_both = intersect(names(osm), names(los_table_complete))
  columns_required = c("AADT", "Speed Limit (mph)", "infrastructure")
  # There should be 3 columns in both, fail if not:
  if (length(names_in_both) != 3) {
    message("Names in both columns: ", paste(names_in_both, collapse = ", "))
    message("Columns required: ", paste(columns_required, collapse = ", "))
    stop("Required columns not found in the input data.")
  }
  osm_joined = dplyr::left_join(
    osm,
    los_table_complete
  ) |>
    dplyr::rename(los = level_of_service)

  osm_joined = osm_joined |>
    dplyr::mutate(
      los = dplyr::case_when(
        cycle_segregation == "Shared Footway" & is.na(los) ~ 2,
        cycle_segregation == "Off Road Path" & is.na(los) ~ 3,
        cycle_segregation == "Segregated Track (wide)" & is.na(los) ~ 3,
        cycle_segregation == "Segregated Track (narrow)" & is.na(los) ~ 2,
        TRUE ~ los
      ) 
    ) |>
      # Differentiate between Do not use (non-compliant intervention)
      # and Do not use (mixed traffic)
      dplyr::mutate(
        los = dplyr::case_when(
          # Non-compliant infrastructure:
          cycle_segregation != "Mixed Traffic Street" & los == 0 ~ -1,
          TRUE ~ los
        )
      ) |>
    dplyr::mutate(
      los = factor(
        los,
        levels = -1:3,
        labels = rev(c("High", "Medium", "Low", "Should not be used (mixed traffic)", "Should not be used (non-compliant intervention)")),
        ordered = TRUE
       ),
       los = forcats::fct_rev(los)
    ) |>
    dplyr::rename(`Level of Service` = los)
  res = sf::st_sf(
    osm_joined |> sf::st_drop_geometry(),
    geometry = sf::st_geometry(osm_joined)
  )
  res
}

#' Function to get multilinestrings representing bus routes
#'
#' It implements the query
#'
#' ```
#' [out:json][timeout:25];
#' relation["route"="bus"]({{bbox}});
#' out geom;
#' ```
#'
#' See [overpass-turbo.eu](https://overpass-turbo.eu/s/1Xaf)
#' for an example of the query in action.
#'
#' @param place A place name or a bounding box passed to `osmextract::oe_get()`
#' @param query A query to be passed to `osmextract::oe_get()`
#' @param extra_tags A vector of extra tags to be included in the OSM extract
#' @param ... Additional arguments passed to `osmextract::oe_get()`
#' @return An sf object with the bus routes
#' @export
#' @examples
#' # r = get_bus_routes("Edinburgh")
#' # r = get_bus_routes("Isle of Wight")
#' # plot(r["osm_id"])
get_bus_routes = function(
  place,
  query = "SELECT * FROM multilinestrings WHERE route == 'bus'",
  extra_tags = "route",
  ...
) {
  osm_bus = osmextract::oe_get(
    place = place,
    query = query,
    extra_tags = extra_tags,
    ...
  )
  osm_bus
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
utils::globalVariables(c(
  "exclude_highway_cycling",
  "exclude_bicycle_cycling",
  "exclude_highway_driving",
  "highway",
  "cycle_segregation",
  "other_tags"
))

#' @name los_table_complete
#' @title Complete Level of Service (LOS) table
#' @description This dataset contains the complete level of service information, including missing categories, in a long format.
#' @format A data frame with columns including speed limit, AADT, cycle_segregation and level_of_service
#' @source Generated from the classify-cbd vignette
#' @usage data(los_table_complete)
#' @examples
#' data(los_table_complete)
#' cols = c("Speed Limit (mph)", "Speed (85th kph)")
#' unique(los_table_complete[cols])
#' head(los_table_complete)
NULL

  # Undocumented code objects:
  #   'cycle_net_f' 'drive_net_f'
#' @name cycle_net_f
#' @title Cycle network for Edinburgh, filtered around Leith Walk
#' @description This dataset contains the cycle network for Edinburgh, filtered around Leith Walk.
#' @format An sf data frame
#' @examples
#' head(cycle_net_f)
#' plot(cycle_net_f)
NULL

#' @name drive_net_f
#' @title Driving network for Edinburgh, filtered around Leith Walk
#' @description This dataset contains the driving network for Edinburgh, filtered around Leith Walk.
#' @format An sf data frame
#' @examples
#' head(drive_net_f)
#' plot(drive_net_f)
NULL
