# Script to create Coventry cycle network visualization
# Uses current OSM data + historical length data from ohsome

library(sf)
library(dplyr)
library(ggplot2)
library(osmextract)
library(gganimate)

# Coventry bbox
coventry_bbox = c(-1.56, 52.40, -1.45, 52.43)

# Historical data from ohsome (already fetched)
historical_lengths = data.frame(
  year = 2017:2024,
  length_m = c(11995, 11745, 11930, 12312, 12491, 15154, 18058, 20207)
)

# Get current OSM data for Coventry
cat("Downloading current OSM data for Coventry...\n")

# Create bbox as sf object
coventry_sf = sf::st_as_sfc(sf::st_bbox(c(
  xmin = coventry_bbox[1], 
  ymin = coventry_bbox[2],
  xmax = coventry_bbox[3], 
  ymax = coventry_bbox[4]
), crs = 4326))

coventry_data = osmextract::oe_get(
  "England",
  boundary = coventry_sf,
  boundary_type = "spat"
)

# Filter to highways
highways = coventry_data |> 
  filter(!is.na(highway))

# Get cycle network (simplified classification)
cycleways = highways |>
  filter(highway %in% c("cycleway", "path", "footway") | 
           grepl("cycleway", cycleway, ignore.case = TRUE) |
           bicycle == "designated")

cat("Cycle network features:", nrow(cycleways), "\n")

# Create visualization
# 1. Map of current network
p1 = ggplot() +
  geom_sf(data = highways, color = "gray80", linewidth = 0.3) +
  geom_sf(data = cycleways, aes(color = highway), linewidth = 1) +
  scale_color_manual(values = c("cycleway" = "darkgreen", "path" = "blue", "footway" = "orange")) +
  theme_minimal() +
  labs(title = "Coventry Cycle Infrastructure (Current)", color = "Type")

ggsave("coventry_current_map.png", p1, width = 10, height = 8)

# 2. Growth chart
p2 = ggplot(historical_lengths, aes(x = year, y = length_m / 1000)) +
  geom_line(color = "darkgreen", linewidth = 2) +
  geom_point(color = "darkgreen", size = 3) +
  theme_minimal() +
  labs(
    title = "Cycle Path Growth in Coventry",
    subtitle = "2017-2024",
    x = "Year",
    y = "Length (km)"
  ) +
  scale_x_continuous(breaks = 2017:2024)

ggsave("coventry_growth_chart.png", p2, width = 8, height = 5)

# 3. Combined visualization with animation effect
# Create frames for each year showing cumulative network
# For simplicity, we'll just animate the chart

p3 = ggplot(historical_lengths, aes(x = year, y = length_m / 1000)) +
  geom_line(color = "darkgreen", linewidth = 2) +
  geom_point(color = "darkgreen", size = 4) +
  geom_area(fill = "green", alpha = 0.3) +
  theme_minimal() +
  labs(
    title = "Coventry Cycle Network Growth",
    subtitle = "Year: {closest_state}",
    x = "Year",
    y = "Length (km)"
  ) +
  scale_x_continuous(breaks = 2017:2024) +
  transition_reveal(year)

anim = animate(p3, nframes = 40, renderer = gifski_renderer())
anim_save("coventry_growth_animation.gif", anim)

cat("Created visualizations:\n")
cat("  - coventry_current_map.png\n")
cat("  - coventry_growth_chart.png\n")
cat("  - coventry_growth_animation.gif\n")
