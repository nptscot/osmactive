# Script to reproduce Coventry historical cycling infrastructure analysis
# This script uses pre-extracted data (JSON format from Python osmium)
# Due to R/GDAL environment issues with osmextract

library(jsonlite)

# Load the pre-extracted data
cycle_data = fromJSON("data-raw/cycle_infrastructure_by_year.json")

# Function to process a year's data
process_year = function(year_data) {
  if (length(year_data) == 0) return(NULL)
  df = as.data.frame(year_data)
  df$length_m = as.numeric(df$length_m)
  df$geometry = NULL  # Remove geometry for simplicity
  return(df)
}

# Process all years
all_data = lapply(names(cycle_data), function(y) {
  df = process_year(cycle_data[[y]])
  df$year = y
  return(df)
})

combined = do.call(rbind, all_data)

# Summary statistics
summary_stats = combined %>%
  group_by(year) %>%
  summarise(
    total_km = sum(length_m) / 1000,
    num_segments = n(),
    .groups = "drop"
  )

print("Summary by Year:")
print(summary_stats)

# Infrastructure by type
type_summary = combined %>%
  group_by(year, type) %>%
  summarise(length_km = sum(length_m) / 1000, .groups = "drop")

print("\nBy Infrastructure Type (km):")
type_pivot = type_summary %>%
  pivot_wider(names_from = type, values_from = length_km)
print(type_pivot)

# Create visualizations
library(ggplot2)

# Plot 1: Total growth
ggplot(summary_stats, aes(x = year, y = total_km)) +
  geom_line(group = 1, color = "blue", linewidth = 1.5) +
  geom_point(size = 3, color = "blue") +
  geom_smooth(method = "lm", se = FALSE, linetype = "dashed") +
  labs(
    title = "Coventry Cycling Infrastructure Growth (2019-2026)",
    subtitle = "Total length of tagged cycling infrastructure",
    x = "Year",
    y = "Total Length (km)"
  ) +
  theme_minimal()

ggsave("coventry_total_growth.png", width = 8, height = 5)

# Plot 2: Stacked area by type
ggplot(type_summary, aes(x = year, y = length_km, fill = type)) +
  geom_area(position = "stack") +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Coventry Cycling Infrastructure by Type",
    x = "Year",
    y = "Length (km)",
    fill = "Type"
  ) +
  theme_minimal()

ggsave("coventry_type_breakdown.png", width = 8, height = 5)

# Save summary data
write.csv(summary_stats, "coventry_summary_stats.csv", row.names = FALSE)
write.csv(type_summary, "coventry_type_summary.csv", row.names = FALSE)

cat("\nAnalysis complete!\n")
cat("Output files:\n")
cat("  - coventry_total_growth.png\n")
cat("  - coventry_type_breakdown.png\n")
cat("  - coventry_summary_stats.csv\n")
cat("  - coventry_type_summary.csv\n")