# Get values from parallel features

This function finds features in a 'target' network (`target_net`) that
are parallel and close to features in a 'source' network (`source_net`)
and imputes missing values in a specified column of the `target_net`
based on the median value from the nearby parallel features in the
`source_net`.

## Usage

``` r
get_parallel_values(
  target_net,
  source_net,
  column = "maxspeed",
  buffer_dist = 10,
  angle_threshold = 20,
  value_pattern = " mph",
  value_replacement = "",
  add_suffix = " mph"
)
```

## Arguments

- target_net:

  An sf object representing the network where values need imputation
  (e.g., cycle network). Must contain a unique `osm_id` column.

- source_net:

  An sf object representing the network to source values from (e.g.,
  drive network). Must contain a unique `osm_id` column.

- column:

  The name of the column (as a string) in both networks to check for NAs
  in `target_net` and source values from `source_net`. Defaults to
  "maxspeed". This column should ideally be numeric or coercible to
  numeric after removing units.

- buffer_dist:

  The buffer distance (in the units of the CRS) around `target_net`
  features to search for nearby `source_net` features. Defaults to 10.

- angle_threshold:

  The maximum allowed absolute difference in bearing (degrees) between
  features in `target_net` and `source_net` for them to be considered
  parallel. Defaults to 20.

- value_pattern:

  Optional regex pattern to remove from the `column` values in
  `source_net` before converting to numeric. Defaults to " mph". Set to
  NULL to skip removal.

- value_replacement:

  Replacement string for `value_pattern`. Defaults to "".

- add_suffix:

  Optional suffix to add back to the imputed numeric value before
  assigning it back to the `column`. Defaults to " mph". Set to NULL to
  skip adding suffix.

## Value

An sf object, the `target_net` with the specified `column` potentially
updated with imputed values from `source_net`.

## Details

It's a generalisation of the `find_nearby_speeds` function previously
used to impute missing `maxspeed` values in a cycle network based on
nearby roads.

## Examples

``` r
# Assuming cycle_net_f and drive_net_f are loaded sf objects from the package

# Impute missing 'maxspeed' in cycle_net_f using drive_net_f
cycle_net_updated_speed = get_parallel_values(
  target_net = cycle_net_f,
  source_net = drive_net_f,
  column = "maxspeed",
  buffer_dist = 10,
  angle_threshold = 20
)
#> Warning: st_point_on_surface assumes attributes are constant over geometries
#> Warning: st_point_on_surface may not give correct results for longitude/latitude data

# Example imputing a hypothetical 'width' column (assuming it exists and needs imputation)
# cycle_net_f$width = as.character(cycle_net_f$width) # Ensure character if adding suffix
# cycle_net_f$width[sample(1:nrow(cycle_net_f), 5)] = NA # Add some NAs for example
# cycle_net_updated_width = get_parallel_values(
#   target_net = cycle_net_f,
#   source_net = drive_net_f, # Using drive_net just for example structure
#   column = "width",
#   buffer_dist = 5,
#   angle_threshold = 15,
#   value_pattern = NULL, # Assuming width is already numeric or has no suffix
#   add_suffix = NULL
# )

print(paste("NA maxspeed before:", sum(is.na(cycle_net_f$maxspeed))))
#> [1] "NA maxspeed before: 28"
print(paste("NA maxspeed after:", sum(is.na(cycle_net_updated_speed$maxspeed))))
#> [1] "NA maxspeed after: 20"
```
