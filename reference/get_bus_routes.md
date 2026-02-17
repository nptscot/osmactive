# Function to get multilinestrings representing bus routes

It implements the query

## Usage

``` r
get_bus_routes(
  place,
  query = "SELECT * FROM multilinestrings WHERE route == 'bus'",
  extra_tags = "route",
  ...
)
```

## Arguments

- place:

  A place name or a bounding box passed to
  [`osmextract::oe_get()`](https://docs.ropensci.org/osmextract/reference/oe_get.html)

- query:

  A query to be passed to
  [`osmextract::oe_get()`](https://docs.ropensci.org/osmextract/reference/oe_get.html)

- extra_tags:

  A vector of extra tags to be included in the OSM extract

- ...:

  Additional arguments passed to
  [`osmextract::oe_get()`](https://docs.ropensci.org/osmextract/reference/oe_get.html)

## Value

An sf object with the bus routes

## Details

    [out:json][timeout:25];
    relation["route"="bus"]({{bbox}});
    out geom;

See [overpass-turbo.eu](https://overpass-turbo.eu/s/1Xaf) for an example
of the query in action.

## Examples

``` r
# r = get_bus_routes("Edinburgh")
# r = get_bus_routes("Isle of Wight")
# plot(r["osm_id"])
```
