# Get the OSM network functions

Get the OSM network functions

## Usage

``` r
get_travel_network(
  place,
  boundary = NULL,
  boundary_type = "clipsrc",
  extra_tags = et_active(),
  columns_to_remove = c("waterway", "aerialway", "barrier", "manmade"),
  ...
)
```

## Arguments

- place:

  A place name or a bounding box passed to
  [`osmextract::oe_get()`](https://docs.ropensci.org/osmextract/reference/oe_get.html)

- boundary:

  An sf object used to clip the OSM data. Passed to
  [`osmextract::oe_get()`](https://docs.ropensci.org/osmextract/reference/oe_get.html)

- boundary_type:

  The clipping method for the boundary. Default is "clipsrc" which clips
  geometries to the boundary. See osmextract documentation for other
  options.

- extra_tags:

  A vector of extra tags to be included in the OSM extract

- columns_to_remove:

  A vector of columns to be removed from the OSM network

- ...:

  Additional arguments passed to
  [`osmextract::oe_get()`](https://docs.ropensci.org/osmextract/reference/oe_get.html)

## Value

A sf object with the OSM network

## Examples

``` r
# Basic usage:
# osm = get_travel_network("Edinburgh")

# Using a boundary to clip data:
# library(sf)
# boundary_poly = st_buffer(st_sfc(st_point(c(-3.2, 55.9)), crs = 4326), 0.01)
# osm_clipped = get_travel_network("Edinburgh", boundary = boundary_poly)

# Using different boundary types:
# osm_intersect = get_travel_network("Edinburgh", boundary = boundary_poly, boundary_type = "clipsrc")
```
