# Get the OSM network functions

Get the OSM network functions

## Usage

``` r
get_points(place, extra_tags = c("traffic_calming", "crossing"), ...)
```

## Arguments

- place:

  A place name or a bounding box passed to
  [`osmextract::oe_get()`](https://docs.ropensci.org/osmextract/reference/oe_get.html)

- extra_tags:

  A vector of extra tags to be included in the OSM extract

- ...:

  Additional arguments passed to
  [`osmextract::oe_get()`](https://docs.ropensci.org/osmextract/reference/oe_get.html)

## Value

A sf object with the OSM network
