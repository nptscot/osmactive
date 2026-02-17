# Estimate traffic

Estimate traffic

## Usage

``` r
estimate_traffic(osm)
```

## Arguments

- osm:

  An sf object with the road network

## Value

An sf object with the estimated road traffic volumes in the column
`assumed_volume`

## Examples

``` r
osm = osm_edinburgh
osm_traffic = estimate_traffic(osm)
# check NAs:
sel_nas = is.na(osm_traffic$assumed_volume)
osm_no_traffic = osm_traffic[sel_nas, c("highway")]
table(osm_no_traffic$highway) # Active travel infrastructure has no road traffic
#> 
#>   corridor   cycleway    footway pedestrian      steps 
#>          3         18         36          6         10 
table(osm_traffic$assumed_volume, useNA = "always")
#> 
#>  500 3000 5000 6000 <NA> 
#>   40   12    4   12  221 
```
