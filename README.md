
<!-- README.md is generated from README.Rmd. Please edit that file -->

# osmactive

<!-- badges: start -->
<!-- badges: end -->

The goal of osmactive is to provide functions, example datasets and
documentation for extracting active travel infrastructure from
OpenStreetMap data.

Install the package with:

``` r
remotes::install_github("nptscot/osmactive")
```

## Example

``` r
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
library(tmap)
#> 
#> Attaching package: 'tmap'
#> The following object is masked from 'package:datasets':
#> 
#>     rivers
edinburgh = zonebuilder::zb_zone("Edinburgh")
edinburgh_3km = edinburgh |> 
  filter(circle_id <= 2)
osm = get_travel_network("Scotland")
#> The input place was matched with: Scotland
#> The chosen file was already detected in the download directory. Skip downloading.
#> The corresponding gpkg file was already detected. Skip vectortranslate operations.
#> Reading layer `lines' from data source 
#>   `/home/robin/data/osm/geofabrik_scotland-latest.gpkg' using driver `GPKG'
#> Simple feature collection with 1388227 features and 31 fields
#> Geometry type: LINESTRING
#> Dimension:     XY
#> Bounding box:  xmin: -20.62345 ymin: 52.69143 xmax: 9.975589 ymax: 65.36242
#> Geodetic CRS:  WGS 84
cycle_network = get_cycling_network(osm)
driving_network = get_driving_network(osm)
edinburgh_cycle = cycle_network[edinburgh_3km, , op = sf::st_within]
edinburgh_driving = driving_network[edinburgh_3km, , op = sf::st_within]
edinburgh_cycle_with_distance = distance_to_road(edinburgh_cycle, edinburgh_driving)
#> Warning: st_point_on_surface assumes attributes are constant over geometries
#> Warning in st_point_on_surface.sfc(st_geometry(x)): st_point_on_surface may not
#> give correct results for longitude/latitude data
edinburgh_segregated = segregation_levels(edinburgh_cycle_with_distance)
table(edinburgh_segregated$cycle_segregation)
#> 
#>       detached_track roadside_cycle_track        mixed_traffic 
#>                 1522                  197                 5636
m = edinburgh_segregated |> 
  arrange(cycle_segregation) |> 
  tm_shape() + tm_lines("cycle_segregation", lwd = 4, palette = "-Blues", popup.vars = c("name", "cycle_segregation", "distance_to_road", "maxspeed", "highway", "other_tags"))
#> tm_lines: Deprecated tmap v3 code detected. Code translated to v4
m
```

![](README_files/figure-gfm/edinburgh-1.png)<!-- -->

``` r
# tmap_save(m, "segregation_levels_edinburgh.html")
```
