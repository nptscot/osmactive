## code to prepare `traffic_volumes_edinburgh` dataset goes here

library(tidyverse)
osm = osm_edinburgh
nrow(osm)
table(osm$highway)
osm_with_traffic_volumes_random = osm |>
  transmute(
    osm_id = osm_id,
    traffic_volume = case_when(
        highway == "primary" ~ round(runif(n(), 1000, 6000)),
        highway == "secondary" ~ round(runif(n(), 500, 5000)),
        highway == "tertiary" ~ round(runif(n(), 200, 4000)),
        TRUE ~ round(runif(n(), 0, 3000))
    )
  )

plot(osm_with_traffic_volumes_random["traffic_volume"])andom

# Hard-coded values
osm_with_traffic_volumes = osm |>
  transmute(
    osm_id = osm_id,
    traffic_volume = case_when(
      highway == "primary" ~ 6000,
      highway == "secondary" ~ 5000,
      highway == "tertiary" ~ 3000,
      TRUE ~ 1000
    )
)
plot(osm_with_traffic_volumes["traffic_volume"])

# Save the data
traffic_volumes_edinburgh = osm_with_traffic_volumes |>
  sf::st_drop_geometry()
traffic_random_edinburgh = osm_with_traffic_volumes_random |>
  sf::st_drop_geometry()

usethis::use_data(traffic_volumes_edinburgh, overwrite = TRUE)
usethis::use_data(traffic_random_edinburgh, overwrite = TRUE)
