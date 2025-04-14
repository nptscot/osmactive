#' Get values from parallel features
#'
#' This function finds features in a 'target' network (`target_net`) that are parallel
#' and close to features in a 'source' network (`source_net`) and imputes missing
#' values in a specified column of the `target_net` based on the median value
#' from the nearby parallel features in the `source_net`.
#'
#' It's a generalisation of the `find_nearby_speeds` function previously used
#' to impute missing `maxspeed` values in a cycle network based on nearby roads.
#'
#' @param target_net An sf object representing the network where values need imputation (e.g., cycle network). Must contain a unique `osm_id` column.
#' @param source_net An sf object representing the network to source values from (e.g., drive network). Must contain a unique `osm_id` column.
#' @param column The name of the column (as a string) in both networks to check for NAs
#'   in `target_net` and source values from `source_net`. Defaults to "maxspeed".
#'   This column should ideally be numeric or coercible to numeric after removing units.
#' @param buffer_dist The buffer distance (in the units of the CRS) around `target_net`
#'   features to search for nearby `source_net` features. Defaults to 10.
#' @param angle_threshold The maximum allowed absolute difference in bearing (degrees)
#'   between features in `target_net` and `source_net` for them to be considered parallel.
#'   Defaults to 20.
#' @param value_pattern Optional regex pattern to remove from the `column` values in `source_net`
#'   before converting to numeric. Defaults to " mph". Set to NULL to skip removal.
#' @param value_replacement Replacement string for `value_pattern`. Defaults to "".
#' @param add_suffix Optional suffix to add back to the imputed numeric value before
#'   assigning it back to the `column`. Defaults to " mph". Set to NULL to skip adding suffix.
#'
#' @return An sf object, the `target_net` with the specified `column` potentially
#'   updated with imputed values from `source_net`.
#' @export
#' @importFrom sf st_buffer st_point_on_surface st_join st_drop_geometry st_sf st_geometry
#' @importFrom dplyr filter select mutate group_by summarise ungroup left_join case_when if_else row_number inner_join rename all_of
#' @examples
#' # Assuming cycle_net_f and drive_net_f are loaded sf objects from the package
#'
#' # Impute missing 'maxspeed' in cycle_net_f using drive_net_f
#' cycle_net_updated_speed = get_parallel_values(
#'   target_net = cycle_net_f,
#'   source_net = drive_net_f,
#'   column = "maxspeed",
#'   buffer_dist = 10,
#'   angle_threshold = 20
#' )
#'
#' # Example imputing a hypothetical 'width' column (assuming it exists and needs imputation)
#' # cycle_net_f$width = as.character(cycle_net_f$width) # Ensure character if adding suffix
#' # cycle_net_f$width[sample(1:nrow(cycle_net_f), 5)] = NA # Add some NAs for example
#' # cycle_net_updated_width = get_parallel_values(
#' #   target_net = cycle_net_f,
#' #   source_net = drive_net_f, # Using drive_net just for example structure
#' #   column = "width",
#' #   buffer_dist = 5,
#' #   angle_threshold = 15,
#' #   value_pattern = NULL, # Assuming width is already numeric or has no suffix
#' #   add_suffix = NULL
#' # )
#'
#' print(paste("NA maxspeed before:", sum(is.na(cycle_net_f$maxspeed))))
#' print(paste("NA maxspeed after:", sum(is.na(cycle_net_updated_speed$maxspeed))))
get_parallel_values = function(target_net, source_net, column = "maxspeed",
                                buffer_dist = 10, angle_threshold = 20,
                                value_pattern = " mph", value_replacement = "",
                                add_suffix = " mph") {

  # --- Input Checks ---
  if (!requireNamespace("stplanr", quietly = TRUE)) {
    stop("Package 'stplanr' needed for this function to work. Please install it.", call. = FALSE)
  }
  if (!inherits(target_net, "sf") || !inherits(source_net, "sf")) {
    stop("Both target_net and source_net must be sf objects.")
  }
  if (!column %in% names(target_net)) {
    stop("Column '", column, "' not found in target_net.")
  }
  if (!column %in% names(source_net)) {
    stop("Column '", column, "' not found in source_net.")
  }
   if (!"osm_id" %in% names(target_net) || !"osm_id" %in% names(source_net)) {
      stop("Both target_net and source_net must contain a unique 'osm_id' column.")
  }
  # Check if CRS are the same, warn if not? Or transform? Assume user provides compatible CRS for now.

  # --- Symbol Setup ---
  col_sym = rlang::sym(column)
  col_new_sym = rlang::sym(paste0(column, "_new"))
  osm_id_target_sym = rlang::sym("osm_id_target") # For clarity in joins/grouping

  # --- 1. Prepare Target Network (Features needing imputation) ---
  target_missing = target_net |>
    dplyr::filter(is.na(!!col_sym))

  if (nrow(target_missing) == 0) {
    message("No missing values found in column '", column, "' of target_net. Returning original data.")
    return(target_net)
  }

  # Calculate bearing and select necessary columns:
  target_missing$azimuth_target = stplanr::line_bearing(target_missing, bidirectional = TRUE)
  target_missing = target_missing |>
    dplyr::select(osm_id, azimuth_target) 
  # Buffer the target features needing imputation
  target_missing_buffer = sf::st_buffer(target_missing, dist = buffer_dist)


  target_missing_buffer = sf::st_buffer(target_missing, dist = buffer_dist)

  source_with_values = source_net |>
    dplyr::filter(!is.na(!!col_sym) & !(!!col_sym %in% c("", " ")))

  if (nrow(source_with_values) == 0) {
    warning("No non-missing values found in column '", column, "' of source_net. Cannot impute.")
    return(target_net)
  }

  # Calculate bearing and select necessary columns:
  source_with_values$azimuth_source = stplanr::line_bearing(source_with_values, bidirectional = TRUE)
  source_with_values = source_with_values |>
    dplyr::select(azimuth_source, !!col_sym) |>
    # Rename col_sym to _source:
    dplyr::rename(new_values = !!col_sym) 

  # Use points on surface for potentially faster spatial join
  source_with_values_points = sf::st_point_on_surface(source_with_values)

  source_with_values_points_near = 
    source_with_values_points[target_missing_buffer, ]
  
  # Check if any points were found within the buffer
  if (nrow(source_with_values_points_near) == 0) {
    warning("No nearby source features found within the buffer distance. Cannot impute.")
    return(target_net)
  }

  # --- 3. Spatial Join: Find nearby source points within target buffers ---
  # This join links each target buffer to the source points it contains
  joined_data_sf = sf::st_join(
      target_missing_buffer |>
        dplyr::select(osm_id, azimuth_target), # Keep only relevant columns
      source_with_values_points
  )

  # --- 4. Filter by Angle and Calculate New Value ---
  joined_data_clean = joined_data_sf |>
    sf::st_drop_geometry() |> # Now work with the attribute table
    #       angle_diff = abs(azimuth_cycle - azimuth_road),
    #   maxspeed_numeric = gsub(maxspeed, pattern = " mph", replacement = "") |>
    #   as.numeric()
    # ) |>
    # filter(angle_diff < angle_threshold) |>
    # group_by(osm_id) |>
    # dplyr::summarise(
    #   maxspeed_new = median(maxspeed_numeric, na.rm = TRUE) |>
    #     paste0(" mph")
    # ) |>
    # ungroup()
    dplyr::mutate(
      angle_diff = abs(azimuth_target - azimuth_source), 
      new_value_numeric = gsub(new_values, pattern = value_pattern, replacement = value_replacement) |>
        as.numeric()
    ) |>
    dplyr::filter(angle_diff < angle_threshold) |>
    # Group by the target feature ID
    dplyr::group_by(osm_id) |>
    # Calculate the median of the numeric values from parallel source features
    dplyr::summarise(
      # Use dynamic name for the summarized column
      new_value := stats::median(new_value_numeric, na.rm = TRUE),
      .groups = 'drop' # Drop grouping
    ) |>
    # Add suffix if specified
    dplyr::mutate(
      new_value = if (!is.null(add_suffix)) {
        paste0(new_value, add_suffix)
      } else {
        as.character(new_value) # Ensure it's character if no suffix
      }
    ) 

    target_net_joined = dplyr::left_join(
      target_net,
      joined_data_clean |>
        dplyr::select(osm_id, new_value), # Select only relevant columns for join
      by = "osm_id" # Join by the unique ID
    ) |>
    # Update the original column where it was NA using the new value
    dplyr::mutate(
      # Coerce new value to match type of original column if necessary?
      # For now, assume character assignment works or original column is character.
      # This might fail if original column is strictly numeric and new value has suffix.
      # Consider adding type check and coercion.
      !!col_sym := dplyr::case_when(
        is.na(!!col_sym) & !is.na(new_value) ~ new_value, # Impute only if original is NA and new is not NA
        TRUE ~ !!col_sym
      )
    ) |>
    # Remove the temporary new value column
    dplyr::select(-new_value) 
  return(target_net_joined)
}
