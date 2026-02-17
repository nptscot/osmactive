# Convert AADT categories to CBD AADT character ranges

This function takes an AADT (Annual Average Daily Traffic) category and
converts it to a ranges

## Usage

``` r
npt_to_cbd_aadt_numeric(AADT)
```

## Arguments

- AADT:

  A numeric vector representing AADT

## Value

A character vector with the converted CBD AADT ranges. Possible return
values are "0 to 999", "1000 to 1999", "2000 to 3999", and "4000+".
