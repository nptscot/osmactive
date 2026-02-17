# Calculate distance from route network segments to roads

This function approximates the distance from the route network to the
nearest road. It does this by first computing the
[`sf::st_point_on_surface`](https://r-spatial.github.io/sf/reference/geos_unary.html)
of the route network segments and then calculating the distance to the
nearest road using the
[`geos::geos_distance`](https://paleolimbot.github.io/geos/reference/geos_distance.html)
function.

## Usage

``` r
distance_to_road(rnet, roads)
```

## Arguments

- rnet:

  The route network for which the distance to the road needs to be
  calculated.

- roads:

  The road network to which the distance needs to be calculated.

## Value

An sf object with the new column `distance_to_road` that contains the
distance to the road.

## Examples

``` r
osm = osm_edinburgh
cycle_network = get_cycling_network(osm)
driving_network = get_driving_network(osm)
edinburgh_cycle_with_distance = distance_to_road(cycle_network, driving_network)
```
