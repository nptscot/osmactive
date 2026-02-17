# Complete Level of Service (LOS) table

This dataset contains the complete level of service information,
including missing categories, in a long format.

## Usage

``` r
data(los_table_complete)
```

## Format

A data frame with columns including speed limit, AADT, cycle_segregation
and level_of_service

## Source

Generated from the classify-cbd vignette

## Examples

``` r
data(los_table_complete)
cols = c("Speed Limit (mph)", "Speed (85th kph)")
unique(los_table_complete[cols])
#> # A tibble: 7 × 2
#>   `Speed Limit (mph)` `Speed (85th kph)`
#>   <chr>               <chr>             
#> 1 <20 mph             0 to 30 kph       
#> 2 20 mph              0 to 30 kph       
#> 3 30 mph              30 kph to 50 kph  
#> 4 40 mph              50 kph to 65 kph  
#> 5 50 mph              65 kph to 80 kph  
#> 6 60 mph              80 kph to 95 kph  
#> 7 60+ mph             95 kph to 110 kph 
head(los_table_complete)
#> # A tibble: 6 × 6
#>   `Speed (85th kph)` `Speed Limit (mph)` `Speed Limit (kph)` AADT        
#>   <chr>              <chr>               <chr>               <chr>       
#> 1 0 to 30 kph        <20 mph             <32 kph             0 to 999    
#> 2 0 to 30 kph        <20 mph             <32 kph             0 to 999    
#> 3 0 to 30 kph        <20 mph             <32 kph             0 to 999    
#> 4 0 to 30 kph        <20 mph             <32 kph             0 to 999    
#> 5 0 to 30 kph        <20 mph             <32 kph             0 to 999    
#> 6 0 to 30 kph        <20 mph             <32 kph             1000 to 1999
#> # ℹ 2 more variables: infrastructure <chr>, level_of_service <dbl>
```
