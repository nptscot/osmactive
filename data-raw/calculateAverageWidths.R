get_pavement_widths = function(
  road_geojson_path,
  roadside_geojson_path,
  crs = "EPSG:27700",
  buffer_dist = 15,
  segment_length = 20
) {
  # Read and transform GeoJSON files using sf
  roads_sf = sf::st_read(road_geojson_path) |>
    sf::st_transform(crs)

  roads_sf = stplanr::line_cast(roads_sf)

  if (segment_length > 0) {
    # Check if the rsgeo package or specific functionality is installed
    rsgeo_installed = requireNamespace("rsgeo", quietly = TRUE)

    if (rsgeo_installed) {
      # rsgeo package is installed, use rsgeo-specific functionality
      print("Using rsgeo package for line segment splitting")
      segment_lengths = as.numeric(sf::st_length(roads_sf))
      n_segments = n_segments(segment_lengths, segment_length)
      roads_split = line_segment_rsgeo(roads_sf, n_segments = n_segments)
    } else {
      # rsgeo package is not installed, fallback to standard functionality
      roads_split = stplanr::line_segment(
        roads_sf,
        segment_length = segment_length
      )
    }
    # Convert the split or original roads to GEOS geometry
    roads_geos = geos::as_geos_geometry(roads_split)
  } else {
    # Convert the original roads to GEOS geometry without splitting
    roads_geos = geos::as_geos_geometry(roads_sf)
  }

  roadside_polygons_sf = sf::st_read(roadside_geojson_path) |>
    sf::st_transform(crs)

  # Convert sf objects to geos geometries for geos operations
  roads_geos = geos::as_geos_geometry(roads_sf)
  roadside_polygons_geos = geos::as_geos_geometry(sf::st_geometry(
    roadside_polygons_sf
  ))

  # Create buffered roads using geos
  roads_buffered = geos::geos_buffer(
    roads_geos,
    dist = buffer_dist,
    params = geos::geos_buffer_params(end_cap_style = "flat")
  )
  roads_buffered_right = geos::geos_buffer(
    roads_geos,
    dist = buffer_dist,
    params = geos::geos_buffer_params(
      end_cap_style = "flat",
      single_sided = TRUE
    )
  )
  roads_buffered_left = geos::geos_difference(
    roads_buffered,
    roads_buffered_right
  )

  # Convert geos geometries back to sf for attaching average widths and further processing
  average_widths_total = calculate_widths(
    roads_geos,
    roadside_polygons_geos,
    roads_buffered
  )
  roads_sf$average_width = average_widths_total

  # Calculate average widths for right and left buffers, then attach to roads_sf as done above
  average_widths_right = calculate_widths(
    roads_geos,
    roadside_polygons_geos,
    roads_buffered_right
  )
  roads_sf$average_widths_right = average_widths_right

  average_widths_left = calculate_widths(
    roads_geos,
    roadside_polygons_geos,
    roads_buffered_left
  )
  roads_sf$average_widths_left = average_widths_left

  return(roads_sf)
}

calculate_widths = function(
  roads_geos,
  roadside_polygons_geos,
  roads_buffered
) {
  average_widths = numeric(length = length(roads_geos))

  for (i in seq_along(roads_geos)) {
    intersections = geos::geos_intersects(
      roads_buffered[i],
      roadside_polygons_geos
    )
    relevant_indices = which(intersections)

    if (length(relevant_indices) > 0) {
      relevant_polygons = roadside_polygons_geos[relevant_indices]
      pavements_intersection_within = geos::geos_intersection(
        relevant_polygons,
        roads_buffered[i]
      )
      intersecting_area = sum(geos::geos_area(pavements_intersection_within))
      road_length = geos::geos_length(roads_geos[i])

      if (road_length > 0) {
        average_widths[i] = round(intersecting_area / road_length, 2)
      } else {
        average_widths[i] = NA
      }
    } else {
      average_widths[i] = NA
    }
  }

  return(average_widths)
}

n_segments = function(line_length, max_segment_length) {
  pmax(ceiling(line_length / max_segment_length), 1)
}


line_segment_rsgeo = function(l, n_segments) {
  crs = sf::st_crs(l)
  # Test to see if the CRS is latlon or not and provide warning if so
  if (sf::st_is_longlat(l)) {
    warning(
      "The CRS of the input object is latlon.\n",
      "This may cause problems with the rsgeo implementation of line_segment()."
    )
  }

  # extract geometry and convert to rsgeo
  geo = rsgeo::as_rsgeo(sf::st_geometry(l))

  # segmentize the line strings
  res_rsgeo = rsgeo::line_segmentize(geo, n_segments)

  # make them into sfc_LINESTRING
  res = sf::st_cast(sf::st_as_sfc(res_rsgeo), "LINESTRING")

  # give them them CRS
  res = sf::st_set_crs(res, crs)

  # calculate the number of original geometries
  n_lines = length(geo)
  # create index ids to grab rows from
  ids = rep.int(seq_len(n_lines), n_segments)

  # index the original sf object
  res_tbl = sf::st_drop_geometry(l)[ids, , drop = FALSE]

  # assign the geometry column
  nrow(res_tbl)

  res_tbl[[attr(l, "sf_column")]] = res

  # convert to sf and return
  res_sf = sf::st_as_sf(res_tbl)
  res_sf
}
