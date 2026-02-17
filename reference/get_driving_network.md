# Get the OSM driving network

This function returns the OSM driving network by excluding certain
highway values.

## Usage

``` r
get_driving_network(osm, ex_d = exclude_highway_driving())

get_driving_network_major(
  osm,
  ex_d = exclude_highway_driving(),
  pattern = "motorway|trunk|primary|secondary|tertiary"
)
```

## Arguments

- osm:

  An OSM network object

- ex_d:

  A character string of highway values to exclude in the form
  `value1|value2` etc

- pattern:

  A character string of highway values to define major roads in the form
  `motorway|trunk|primary|secondary|tertiary`

## Value

A sf object with the OSM driving network

## Details

`get_driving_network_major` returns only the major roads.
