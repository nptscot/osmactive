# Generate Cycle by Design Level of Service

Note: you need to have Annual Average Daily Traffic (AADT) values in the
dataset These can be estimated using the
[`estimate_traffic()`](https://nptscot.github.io/osmactive/reference/estimate_traffic.md)
function and converted to CbD AADT categories using the
[`npt_to_cbd_aadt()`](https://nptscot.github.io/osmactive/reference/npt_to_cbd_aadt.md)
function.

## Usage

``` r
level_of_service(osm)
```

## Arguments

- osm:

  An sf object with the road network including speed limits and traffic
  volumes

## Value

An sf object with the Cycle by Design Level of Service in the column
`Level of Service`

## Examples

``` r
osm = osm_edinburgh
# Get infrastructure type:
cycle_net = get_cycling_network(osm)
# Get driving network:
driving_net = get_driving_network(osm)
# Get distance to road:
osm = distance_to_road(cycle_net, driving_net)
# Classify cycle infrastructure:
osm = classify_cycle_infrastructure(osm, include_mixed_traffic = TRUE)
osm = estimate_traffic(osm)
osm$AADT = npt_to_cbd_aadt_numeric(osm$assumed_volume)
osm$infrastructure = osm$cycle_segregation
osm_los = level_of_service(osm)
#> Joining with `by = join_by(AADT, infrastructure, `Speed Limit (mph)`)`
plot(osm_los["Level of Service"])

# mapview::mapview(osm_los, zcol = "Level of Service")
# Test LoS on known road:
mill_lane = data.frame(
  # TODO: find out why highway is needed for LoS
  highway = "residential",
  AADT = "4000+",
  maxspeed = "20 mph",
  cycle_segregation = "Mixed Traffic Street"
)
#
osm = sf::st_as_sf(mill_lane, geometry = osm$geometry[1])
mill_lane_los = level_of_service(osm)
#> Joining with `by = join_by(AADT, `Speed Limit (mph)`, infrastructure)`
mill_lane_los
#> Simple feature collection with 1 feature and 10 fields
#> Geometry type: MULTILINESTRING
#> Dimension:     XY
#> Bounding box:  xmin: -3.18682 ymin: 55.95571 xmax: -3.186586 ymax: 55.95639
#> Geodetic CRS:  WGS 84
#>       highway  AADT maxspeed    cycle_segregation maxspeed_clean
#> 1 residential 4000+   20 mph Mixed Traffic Street             20
#>   Speed Limit (mph)       infrastructure Speed (85th kph) Speed Limit (kph)
#> 1            20 mph Mixed Traffic Street      0 to 30 kph            32 kph
#>   Level of Service                       geometry
#> 1              Low MULTILINESTRING ((-3.186586...
#
```
