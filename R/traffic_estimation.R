#' Estimate traffic using dodgr centrality
#'
#' @param osm An sf object with the road network
#' @param wt_profile The weight profile to use (default: "motorcar")
#' @param aggregate_by Column to aggregate centrality by (default: "osm_id")
#' @param ... Additional arguments passed to dodgr::dodgr_centrality
#' @export
estimate_traffic_dodgr = function(osm, wt_profile = "motorcar", aggregate_by = "osm_id", ...) {
  # Check dependencies
  if (!requireNamespace("dodgr", quietly = TRUE)) {
    stop("Package 'dodgr' is required for this function. Please install it.")
  }
  
  message("Calculating dodgr centrality...")
  
  # Weight the network
  message("Weighting network for ", wt_profile, "...")
  graph = dodgr::weight_streetnet(osm, wt_profile = wt_profile)
  
  # Calculate centrality
  message("Calculating dodgr centrality (betweenness)...")
  graph_c = dodgr::dodgr_centrality(graph, ...)
  
  # Convert back to sf
  message("Converting output to sf...")
  osm_dodgr = dodgr::dodgr_to_sf(graph_c)
  
  if (!is.null(aggregate_by)) {
    # dodgr often renames IDs to "way_id" or "osm_id"
    id_col_dodgr = intersect(c(aggregate_by, "way_id", "osm_id"), names(osm_dodgr))
    
    if (length(id_col_dodgr) > 0) {
      id_col_dodgr = id_col_dodgr[1]
      message("Aggregating centrality by ", aggregate_by, " (using ", id_col_dodgr, " from dodgr output)...")
      
      centrality_agg = osm_dodgr |>
        sf::st_drop_geometry() |>
        dplyr::group_by(ID = !!rlang::sym(id_col_dodgr)) |>
        dplyr::summarise(centrality = mean(centrality, na.rm = TRUE), .groups = "drop")
      
      # Prepare for join
      # Handle case where osm doesn't have aggregate_by
      if (!aggregate_by %in% names(osm)) {
        osm[[aggregate_by]] = rownames(osm)
      }
      
      join_list = setNames("ID", aggregate_by)
      res = dplyr::left_join(osm, centrality_agg, by = join_list)
      return(res)
    } else {
      warning("Could not find matching ID column in dodgr output. Returning raw dodgr sf object.")
    }
  }
  
  return(osm_dodgr)
}

#' Calibrate dodgr centrality model
#'
#' @param net_c Centrality-enriched network (from estimate_traffic_dodgr)
#' @param counts_sf sf object with observed traffic counts
#' @param count_col Name of the column with traffic counts
#' @param formula Model formula for calibration
#' @export
calibrate_traffic_dodgr = function(net_c, counts_sf, count_col = "avg_daily_car", 
                                  formula = as.formula(paste(count_col, "~ highway + log1p(centrality)"))) {
  
  if (!"centrality" %in% names(net_c)) {
    stop("Network must have 'centrality' column. Run estimate_traffic_dodgr first.")
  }
  
  # Use centroids if counts_sf are lines
  counts_matching = counts_sf
  if (all(sf::st_geometry_type(counts_sf) %in% c("LINESTRING", "MULTILINESTRING"))) {
    counts_matching = sf::st_centroid(counts_sf)
  }
  
  # Match sensors to the network
  matched_idx = sf::st_nearest_feature(counts_matching, net_c)
  
  # Prepare training data
  train_df = counts_sf |>
    sf::st_drop_geometry() |>
    dplyr::mutate(
      centrality = net_c$centrality[matched_idx],
      highway = as.factor(net_c$highway[matched_idx])
    )
  
  # Filter out NA centralities
  train_df = train_df |> dplyr::filter(!is.na(centrality))
  
  # Fit model
  message("Fitting calibration model...")
  model = lm(formula, data = train_df)
  
  return(model)
}
