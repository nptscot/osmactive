# Clean speeds

Clean speeds

## Usage

``` r
clean_speeds(osm)
```

## Arguments

- osm:

  An sf object with the road network

## Value

An sf object with the cleaned speed values in the column
`maxspeed_clean`

## Examples

``` r
osm = osm_edinburgh
osm_cleaned = clean_speeds(osm)
# check NAs:
sel_nas = is.na(osm_cleaned$maxspeed_clean)
osm_no_maxspeed = osm_cleaned[sel_nas, c("highway")]
table(osm_no_maxspeed$highway) # Active travel infrastructure has no maxspeed
#> 
#>   corridor   cycleway    footway pedestrian      steps 
#>          3         18         36          6         10 
table(osm_cleaned$maxspeed)
#> 
#> 20 mph     30  5 mph 
#>     42      4      1 
table(osm_cleaned$maxspeed_clean)
#> 
#>  5 10 20 30 
#>  1 23 42  6 
plot(osm_cleaned[c("maxspeed", "maxspeed_clean")])
```
