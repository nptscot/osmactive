# Clean cycleway widths (use est_widths when available and width otherwise)

Clean cycleway widths (use est_widths when available and width
otherwise)

## Usage

``` r
clean_widths(osm)
```

## Arguments

- osm:

  An sf object with the road network

## Value

An sf object with the cleaned cycleway widths in the column `width`

## Examples

``` r
osm = osm_edinburgh
osm$width
#>   [1] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#>  [13] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    "3"  
#>  [25] NA    "4.5" NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#>  [37] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#>  [49] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#>  [61] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#>  [73] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#>  [85] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#>  [97] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [109] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [121] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [133] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [145] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [157] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [169] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [181] NA    NA    NA    NA    NA    NA    NA    NA    "1"   NA    NA    NA   
#> [193] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [205] NA    NA    NA    NA    NA    "3"   "2.5" NA    "20"  NA    NA    NA   
#> [217] "2"   NA    NA    NA    "2.5" NA    "2.5" "4"   NA    NA    NA    NA   
#> [229] NA    "1"   NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [241] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [253] NA    "1"   NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [265] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    "2"   NA   
#> [277] "2"   NA    NA    NA    NA    NA    NA    NA    NA    "3"   NA    "2"  
#> [289] NA   
osm$est_width = NA
osm$est_width[1:3] = 2
osm_cleaned = clean_widths(osm)
osm$width
#>   [1] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#>  [13] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    "3"  
#>  [25] NA    "4.5" NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#>  [37] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#>  [49] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#>  [61] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#>  [73] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#>  [85] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#>  [97] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [109] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [121] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [133] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [145] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [157] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [169] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [181] NA    NA    NA    NA    NA    NA    NA    NA    "1"   NA    NA    NA   
#> [193] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [205] NA    NA    NA    NA    NA    "3"   "2.5" NA    "20"  NA    NA    NA   
#> [217] "2"   NA    NA    NA    "2.5" NA    "2.5" "4"   NA    NA    NA    NA   
#> [229] NA    "1"   NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [241] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [253] NA    "1"   NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [265] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    "2"   NA   
#> [277] "2"   NA    NA    NA    NA    NA    NA    NA    NA    "3"   NA    "2"  
#> [289] NA   
osm_cleaned$width
#>   [1] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#>  [13] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    "3"  
#>  [25] NA    "4.5" NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#>  [37] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#>  [49] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#>  [61] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#>  [73] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#>  [85] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#>  [97] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [109] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [121] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [133] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [145] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [157] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [169] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [181] NA    NA    NA    NA    NA    NA    NA    NA    "1"   NA    NA    NA   
#> [193] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [205] NA    NA    NA    NA    NA    "3"   "2.5" NA    "20"  NA    NA    NA   
#> [217] "2"   NA    NA    NA    "2.5" NA    "2.5" "2"   NA    NA    NA    NA   
#> [229] NA    "1"   NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [241] NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [253] NA    "1"   NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> [265] NA    NA    NA    "2"   NA    NA    NA    NA    NA    NA    "2"   NA   
#> [277] "2"   NA    NA    NA    NA    NA    NA    NA    NA    "3"   NA    "2"  
#> [289] NA   
```
