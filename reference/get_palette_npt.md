# Get the palette for the NPT cycle segregation levels

Get the palette for the NPT cycle segregation levels

## Usage

``` r
get_palette_npt()
```

## Value

A palette for the NPT cycle segregation levels

## Examples

``` r
cols = get_palette_npt()
jsonlite::toJSON(as.list(cols), pretty = TRUE)
#> {
#>   "Segregated Track (wide)": ["#054d05"],
#>   "Off Road Path": ["#3a9120"],
#>   "Segregated Track (narrow)": ["#87d668"],
#>   "Shared Footway": ["#ffbf00"],
#>   "Painted Cycle Lane": ["#FF0000"]
#> } 
col_labs = c("OffRd", "SegW", "SegN", "Share", "Paint")
barplot(seq_along(cols), col = cols, names.arg = col_labs)
```
