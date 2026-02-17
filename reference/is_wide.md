# Classify Separated cycle track by width

This function classifies cycleways as wide if the width is greater than
or equal to `min_width`. NA values are replaced with 0, meaning that
ways with no measurement are considered narrow.

## Usage

``` r
is_wide(x, min_width = 2)
```

## Arguments

- x:

  A numeric vector with the width of the cycleway (m)

- min_width:

  The minimum width for a cycleway to be considered wide (m)

## Value

A logical vector indicating whether the cycleway is wide

## Examples

``` r
x = osm_edinburgh$width
x
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
is_wide(x)
#>   [1] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
#>  [13] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE  TRUE
#>  [25] FALSE  TRUE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
#>  [37] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
#>  [49] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
#>  [61] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
#>  [73] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
#>  [85] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
#>  [97] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
#> [109] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
#> [121] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
#> [133] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
#> [145] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
#> [157] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
#> [169] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
#> [181] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
#> [193] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
#> [205] FALSE FALSE FALSE FALSE FALSE  TRUE  TRUE FALSE  TRUE FALSE FALSE FALSE
#> [217]  TRUE FALSE FALSE FALSE  TRUE FALSE  TRUE  TRUE FALSE FALSE FALSE FALSE
#> [229] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
#> [241] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
#> [253] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
#> [265] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE  TRUE FALSE
#> [277]  TRUE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE  TRUE FALSE  TRUE
#> [289] FALSE
```
