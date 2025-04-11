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
#' @importFrom rlang sym :=
#' @examples
#' \dontrun{
#' # Assuming cycle_net_f and drive_net_f are loaded sf objects from the package
#' data(cycle_net_f)
#' data(drive_net_f)
#'
#' # Impute missing 'maxspeed' in cycle_net_f using drive_net_f
#' cycle_net_updated_speed <- get_parallel_values(
#'   target_net = cycle_net_f,
#'   source_net = drive_net_f,
#'   column = "maxspeed",
#'   buffer_dist = 10,
#'   angle_threshold = 20
#' )
#'
#' # Example imputing a hypothetical 'width' column (assuming it exists and needs imputation)
#' # cycle_net_f$width <- as.character(cycle_net_f$width) # Ensure character if adding suffix
#' # cycle_net_f$width[sample(1:nrow(cycle_net_f), 5)] <- NA # Add some NAs for example
#' # cycle_net_updated_width <- get_parallel_values(
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
#' }
get_parallel_values <- function(target_net, source_net, column = "maxspeed",
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
  col_sym <- rlang::sym(column)
  col_new_sym <- rlang::sym(paste0(column, "_new"))
  osm_id_target_sym <- rlang::sym("osm_id_target") # For clarity in joins/grouping

  # --- 1. Prepare Target Network (Features needing imputation) ---
  target_missing <- target_net |>
    dplyr::filter(is.na(!!col_sym))

  if (nrow(target_missing) == 0) {
    message("No missing values found in column '", column, "' of target_net. Returning original data.")
    return(target_net)
  }

  # Calculate bearing and select necessary columns
  target_missing <- target_missing |>
    dplyr::mutate(azimuth_target = stplanr::line_bearing(.data$geometry, bidirectional = TRUE)) |>
    dplyr::select(!!osm_id_target_sym := .data$osm_id, azimuth_target) # Keep only needed cols + geometry

  # Buffer the target features needing imputation
  target_missing_buffer <- sf::st_buffer(target_missing, dist = buffer_dist)

  # --- 2. Prepare Source Network (Features with values) ---
  source_with_values <- source_net |>
    dplyr::filter(!is.na(!!col_sym) & !(!!col_sym %in% c("", " "))) # Also filter empty strings

  if (nrow(source_with_values) == 0) {
    warning("No non-missing values found in column '", column, "' of source_net. Cannot impute.")
    return(target_net)
  }

  # Calculate bearing and select necessary columns
  source_with_values <- source_with_values |>
     dplyr::mutate(azimuth_source = stplanr::line_bearing(.data$geometry, bidirectional = TRUE)) |>
     dplyr::select(osm_id_source = .data$osm_id, !!col_sym, azimuth_source) # Keep only needed cols + geometry

  # Use points on surface for potentially faster spatial join
  source_with_values_points <- sf::st_point_on_surface(source_with_values)

  # --- 3. Spatial Join: Find nearby source points within target buffers ---
  # This join links each target buffer to the source points it contains
  joined_data_sf <- sf::st_join(
      target_missing_buffer,
      source_with_values_points,
      join = sf::st_intersects,
      # Ensure unique suffix if column names clash (though we selected specific ones)
      suffix = c("", ".source")
  )

  # Check if any intersections were found
  if (nrow(joined_data_sf) == 0 || all(is.na(joined_data_sf$osm_id_source))) {
      warning("No nearby source features found within the buffer distance. Cannot impute.")
      return(target_net)
  }

  # --- 4. Filter by Angle and Calculate New Value ---
  joined_data_clean <- joined_data_sf |>
    sf::st_drop_geometry() |> # Now work with the attribute table
    dplyr::filter(!is.na(.data$osm_id_source)) |> # Ensure join was successful
    dplyr::mutate(
      angle_diff = abs(.data$azimuth_target - .data$azimuth_source) %% 180, # Use modulo 180 for bidirectional bearing
      angle_diff = pmin(.data$angle_diff, 180 - .data$angle_diff), # Ensure smallest angle difference (0-90)
      # Convert value to numeric, removing pattern if specified
      value_raw = !!col_sym,
      value_numeric = dplyr::if_else(
          !is.null(value_pattern) & !is.na(.data$value_raw),
          gsub(.data$value_raw, pattern = value_pattern, replacement = value_replacement),
          as.character(.data$value_raw) # Ensure character before as.numeric if no pattern
      )
    ) |>
    # Attempt conversion to numeric, coercing errors to NA
    dplyr::mutate(value_numeric = suppressWarnings(as.numeric(.data$value_numeric))) |>
    # Filter by angle threshold and valid numeric value
    dplyr::filter(.data$angle_diff < angle_threshold, !is.na(.data$value_numeric)) |>
    # Group by the target feature ID
    dplyr::group_by(!!osm_id_target_sym) |>
    # Calculate the median of the numeric values from parallel source features
    dplyr::summarise(
      # Use dynamic name for the summarized column
      !!col_new_sym := stats::median(.data$value_numeric, na.rm = TRUE),
      .groups = 'drop' # Drop grouping
    ) |>
    # Filter out rows where median calculation resulted in NA (e.g., no valid numeric values after filtering)
    dplyr::filter(!is.na(!!col_new_sym)) |>
    # Add suffix back if specified
    dplyr::mutate(
        !!col_new_sym := dplyr::if_else(
            !is.null(add_suffix),
            paste0(!!col_new_sym, add_suffix),
            # Coerce to character to be safe, as original might be character.
            as.character(!!col_new_sym)
        )
    )

  # Check if any values were successfully calculated
  if (nrow(joined_data_clean) == 0) {
      warning("Could not calculate imputed values (e.g., due to angle threshold or non-numeric source values).")
      return(target_net)
  }

  # --- 5. Join Imputed Values back to Target Network ---
  # Ensure the target ID column name matches for the join ('osm_id')
  # The join key in joined_data_clean is osm_id_target_sym

  target_net_joined <- dplyr::left_join(
    target_net,
    joined_data_clean |> dplyr::rename(osm_id = !!osm_id_target_sym), # Rename join key to 'osm_id'
    by = "osm_id" # Join by the unique ID
  ) |>
    # Update the original column where it was NA using the new value
    dplyr::mutate(
      # Coerce new value to match type of original column if necessary?
      # For now, assume character assignment works or original column is character.
      # This might fail if original column is strictly numeric and new value has suffix.
      # Consider adding type check and coercion.
      !!col_sym := dplyr::case_when(
        is.na(!!col_sym) & !is.na(!!col_new_sym) ~ !!col_new_sym, # Impute only if original is NA and new is not NA
        TRUE ~ !!col_sym
      )
    ) |>
    # Remove the temporary new value column
    dplyr::select(-!!col_new_sym)


  # Ensure the output is an sf object with the original geometry type
  # The dplyr verbs should preserve the sf class and geometry column
  # If geometry gets lost, use sf::st_sf(..., geometry = sf::st_geometry(target_net))

  # Restore original geometry if lost during joins/manipulation
  if (!inherits(target_net_joined, "sf")) {
       target_net_joined <- sf::st_sf(target_net_joined, geometry = sf::st_geometry(target_net))
  } else if (!identical(sf::st_geometry(target_net_joined), sf::st_geometry(target_net))) {
      # Ensure geometry column name and content is the same if manipulations altered it
       sf::st_geometry(target_net_joined) <- sf::st_geometry(target_net)
  }


  return(target_net_joined)
}

# Ensure osm_id is not lost if it's part of the geometry column's attributes in some sf versions
# This is generally not standard, osm_id should be a regular column.
# The code assumes osm_id is a standard attribute column.
