# Classify historical Coventry cycle infrastructure (2019-2026)
#
# For each year, reads a GeoJSON extract of Coventry OSM highway ways
# (produced by data-raw/extract_coventry_geojson.py from Geofabrik West
# Midlands historical PBF snapshots), classifies cycle infrastructure using
# osmactive, and writes a per-year .gpkg file.

library(osmactive)
library(sf)
library(dplyr)

geojson_dir = "/tmp/coventry_pbf"
out_dir = "data-raw"
years = 2019:2026

# Columns that osmactive's classification functions reference directly.
# Historical extracts may lack some of these tags entirely (i.e. the column
# won't exist at all after reading a small area), so we make sure they are
# always present (filled with NA) before running the pipeline.
required_cols = c(
  "highway", "bicycle", "surface", "smoothness", "service", "oneway",
  "segregated", "foot", "footway", "name", "width", "est_width",
  "cycleway", "cycleway_width", "cycleway_est_width",
  "cycleway_left", "cycleway_right",
  "cycleway_left_segregated", "cycleway_right_segregated"
)

ensure_columns = function(osm, cols) {
  missing_cols = setdiff(cols, names(osm))
  for (col in missing_cols) {
    osm[[col]] = NA_character_
  }
  osm
}

summary_rows = list()

for (year in years) {
  cat("=== Processing", year, "===\n")
  geojson_path = file.path(geojson_dir, paste0("coventry-", year, ".geojson"))
  if (!file.exists(geojson_path)) {
    cat("  Skipping, file not found:", geojson_path, "\n")
    next
  }

  osm = sf::st_read(geojson_path, quiet = TRUE)
  cat("  Read", nrow(osm), "highway ways\n")

  osm = ensure_columns(osm, required_cols)

  # osmactive's functions expect these columns present, and use
  # dplyr::filter(is.na(service)) style logic; make sure the geometry
  # is valid linestring data:
  osm = osm[sf::st_is_valid(osm), ]
  osm = osm[!sf::st_is_empty(osm), ]

  cycle_net = get_cycling_network(osm)
  cat("  Cycling network:", nrow(cycle_net), "ways\n")

  driving_net = get_driving_network(osm)
  cat("  Driving network:", nrow(driving_net), "ways\n")

  cycle_net = distance_to_road(cycle_net, driving_net)

  cycle_net_classified = classify_cycle_infrastructure(
    cycle_net,
    include_mixed_traffic = FALSE
  )
  cycle_net_classified$year = year

  # GPKG field names are case-insensitive; drop columns whose lowercase name
  # collides with another column (keep the first occurrence) to avoid a
  # GDAL "duplicate names" write error (e.g. OSM tags "FIXME" and "fixme").
  lower_names = tolower(names(cycle_net_classified))
  keep = !duplicated(lower_names)
  cycle_net_classified = cycle_net_classified[, keep]

  out_path = file.path(out_dir, paste0("coventry-cycleways-", year, ".gpkg"))
  sf::st_write(cycle_net_classified, out_path, delete_dsn = TRUE, quiet = TRUE)

  total_length_km = sum(sf::st_length(cycle_net_classified), na.rm = TRUE) |>
    units::set_units("km") |>
    as.numeric()

  cat(
    "  Classified", nrow(cycle_net_classified), "cycle infrastructure segments,",
    round(total_length_km, 1), "km\n"
  )
  cat("  Saved:", out_path, "\n")

  type_summary = cycle_net_classified |>
    sf::st_drop_geometry() |>
    dplyr::mutate(length_m = as.numeric(sf::st_length(cycle_net_classified))) |>
    dplyr::group_by(cycle_segregation) |>
    dplyr::summarise(length_km = sum(length_m) / 1000, n = dplyr::n(), .groups = "drop")
  print(type_summary)

  summary_rows[[as.character(year)]] = data.frame(
    year = year,
    n_ways_raw = nrow(osm),
    n_cycle_ways = nrow(cycle_net_classified),
    total_length_km = round(total_length_km, 2)
  )
}

cat("\n=== Summary across all years ===\n")
summary_df = do.call(rbind, summary_rows)
print(summary_df)

write.csv(summary_df, file.path(out_dir, "coventry-cycleways-summary.csv"), row.names = FALSE)
cat("\nDone.\n")
