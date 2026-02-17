# Classify Speeds

This function classifies speeds in miles per hour (mph) into categories.

## Usage

``` r
classify_speeds(speed_mph)
```

## Arguments

- speed_mph:

  A numeric vector representing speeds in miles per hour.

## Value

A character vector with the speed categories.

## Examples

``` r
classify_speeds(c(15, 25, 35, 45, 55, 65))
#> [1] "<20 mph" "20 mph"  "30 mph"  "40 mph"  "50 mph"  "60+ mph"
# Returns: "<20 mph", "20 mph", "30 mph", "40 mph", "50 mph", "60+ mph"
```
