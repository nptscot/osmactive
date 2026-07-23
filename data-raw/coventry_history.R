# Script to download historical OSM data for Coventry and create animated map
# This script creates a dataset showing the geographic growth of cycle infrastructure

# Install required packages if not present
if (!require("osmextract")) install.packages("osmextract")
if (!require("osmactive")) remotes::install_github("nptscot/osmactive")
if (!require("gganimate")) install.packages("gganimate")
if (!require("gifski")) install.packages("gifski")

library(sf)
library(dplyr)
library(osmextract)
library(ggplot2)
library(gganimate)

# Coventry bounding box
coventry_bbox = c(-1.56, 52.40, -1.45, 52.43)

# Years to download
years = 2017:2024

# Download and process function
process_year = function(year) {
  cat("Processing", year, "...\n")
  
  # Format: YYMMDD (using Jan 1 of each year)
  version = paste0(substr(year, 3, 4), "0101")
  
  # Try to download historical data
  tryCatch({
    # Download Great Britain extract for that year
    # This will be cached by osmextract
    gb_data = osmextract::oe_get(
      "England", 
      provider = "geofabrik",
      version = version,
      force_download = TRUE
    )
    
    # Clip to Coventry bbox
    coventry_data = st_transform(gb_data, 4326) |>
      st_crop(st_bbox(c(
        xmin = coventry_bbox[1], 
        ymin = coventry_bbox[2],
        xmax = coventry_bbox[3], 
        ymax = coventry_bbox[4]
      )))
    
    # Get cycling network
    cycle_net = osmactive::get_cycling_network(coventry_data)
    
    # Classify infrastructure
    # Need driving network for distance_to_road
    driving_net = osmactive::get_driving_network(coventry_data)
    cycle_net = osmactive::distance_to_road(cycle_net, driving_net)
    cycle_net_classified = osmactive::classify_cycle_infrastructure(cycle_net)
    
    # Add year
    cycle_net_classified$year = year
    
    # Calculate total length
    total_length = sum(st_length(cycle_net_classified), na.rm = TRUE)
    cat("  Total cycle network length:", round(total_length), "m\n")
    
    return(cycle_net_classified)
  }, error = function(e) {
    cat("  Error:", e$message, "\n")
    return(NULL)
  })
}

# Process all years
cat("Downloading historical OSM data for Coventry...\n")
cycle_networks = lapply(years, process_year)

# Combine all years
cycle_combined = do.call(rbind, cycle_networks)

# Remove invalid geometries
cycle_combined = cycle_combined[st_is_valid(cycle_combined), ]

# Save as RDS
saveRDS(cycle_combined, "coventry_cycle_network_history.rds")

# Create animation
cat("Creating animation...\n")

# Filter to only include segregated infrastructure for clearer visualization
cycle_for_plot = cycle_combined |>
  filter(!is.na(cycle_segregation)) |>
  filter(cycle_segregation != "Mixed Traffic Street")

# Color palette (matching osmactive)
infra_colors = c(
  "Segregated Track (wide)" = "#054d05",
  "Off Road Path" = "#3a9120", 
  "Segregated Track (narrow)" = "#87d668",
  "Shared Footway" = "#ffbf00",
  "Painted Cycle Lane" = "#FF0000"
)

# Base map
ggplot() +
  geom_sf(data = cycle_for_plot, aes(color = cycle_segregation), linewidth = 1) +
  scale_color_manual(values = infra_colors, name = "Infrastructure") +
  theme_minimal() +
  labs(
    title = "Coventry Cycle Network Growth",
    subtitle = "Year: {closest_state}"
  ) +
  transition_states(year, transition_length = 1, state_length = 2) +
  enter_fade() +
  exit_fade()

# Save animation
anim = last_plot() +
  anim_save("coventry_cycle_network.gif", animation = last_animation(), renderer = gifski_renderer())

cat("Done! Saved coventry_cycle_network.gif\n")
