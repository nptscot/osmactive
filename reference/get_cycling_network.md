# Get the OSM cycling network

Get the OSM cycling network

## Usage

``` r
get_cycling_network(
  osm,
  ex_c = exclude_highway_cycling(),
  ex_b = exclude_bicycle_cycling()
)
```

## Arguments

- osm:

  An OSM network object

- ex_c:

  A vector of highway values to exclude

- ex_b:

  A vector of bicycle values to exclude

## Value

A sf object with the OSM cycling network
