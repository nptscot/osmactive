
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

## Edinburgh example

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
edinburgh_1km = edinburgh |> 
  # Change number in next line to change zone size:
  filter(circle_id <= 1)
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
edinburgh_cycle = cycle_network[edinburgh_1km, , op = sf::st_within]
edinburgh_driving = driving_network[edinburgh_1km, , op = sf::st_within]
edinburgh_cycle_with_distance = distance_to_road(edinburgh_cycle, edinburgh_driving)
#> Warning: st_point_on_surface assumes attributes are constant over geometries
#> Warning in st_point_on_surface.sfc(st_geometry(x)): st_point_on_surface may not
#> give correct results for longitude/latitude data
edinburgh_segregated = segregation_levels(edinburgh_cycle_with_distance)
table(edinburgh_segregated$cycle_segregation)
#> 
#>       detached_track roadside_cycle_track        mixed_traffic 
#>                   27                   63                  880
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

Save an interactive version of the map to check the results as follows:

``` r
tmap_save(m, "segregation_levels_edinburgh.html")
browseURL("segregation_levels_edinburgh.html")
```

## Lisbon example

``` r
lisbon = zonebuilder::zb_zone("Lisbon")
lisbon = sf::st_sf(
  lisbon |> sf::st_drop_geometry() |> select(-centroid),
  geometry = sf::st_geometry(lisbon)
)
# plot(lisbon)
# # From GitHub:
# u = "https://objects.githubusercontent.com/github-production-release-asset-2e65be/624478482/23975e12-8fb3-45df-8a42-7354811057f0?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAVCODYLSA53PQK4ZA%2F20240415%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20240415T120942Z&X-Amz-Expires=300&X-Amz-Signature=55acff30e944fbed3da59629252fef7033213db9f8c0a25951faaa72d7d73f46&X-Amz-SignedHeaders=host&actor_id=0&key_id=0&repo_id=624478482&response-content-disposition=attachment%3B%20filename%3DCAOP_municipios.gpkg&response-content-type=application%2Foctet-stream"
# f = "lisbon_municipalities.gpkg"
# if (!file.exists(f)) download.file(u, f)
# lisbon_region = sf::st_read(f)
# names(lisbon_region)
# lisbon = lisbon |>
#   filter(city = "Lisboa") 
lisbon_1km = lisbon |> 
  # Change number in next line to change zone size:
  filter(circle_id <= 1) |>
  sf::st_union()
# ?oe_get
osm = get_travel_network("Portugal", boundary = lisbon_1km, boundary_type = "clipsrc")
#> The input place was matched with: Portugal
#> The chosen file was already detected in the download directory. Skip downloading.
#> Starting with the vectortranslate operations on the input file!
#> 0...10...20...30...40...50...60...70...80...90...
#> Warning in CPL_gdalvectortranslate(source, destination, options, oo, doo, :
#> GDAL Error 1: An error occurred during the parsing of data around byte 30351040
#> 100 - done.
#> Finished the vectortranslate operations on the input file!
#> Reading layer `lines' from data source 
#>   `/home/robin/data/osm/geofabrik_portugal-latest.gpkg' using driver `GPKG'
#> Simple feature collection with 0 features and 31 fields
#> Bounding box:  xmin: NA ymin: NA xmax: NA ymax: NA
#> Geodetic CRS:  WGS 84
osm = osm[lisbon_1km, , op = sf::st_within]
cycle_network = get_cycling_network(osm)
driving_network = get_driving_network(osm)
cycle_network_with_distance = distance_to_road(cycle_network, driving_network)
#> Warning in st_point_on_surface.sfc(st_geometry(x)): st_point_on_surface may not
#> give correct results for longitude/latitude data
lisbon_categorized = segregation_levels(cycle_network_with_distance)
m = lisbon_categorized |> 
  arrange(cycle_segregation) |> 
  tm_shape() + tm_lines("cycle_segregation", lwd = 4, palette = "-Blues", popup.vars = c("name", "cycle_segregation", "distance_to_road", "maxspeed", "highway", "other_tags"))
#> tm_lines: Deprecated tmap v3 code detected. Code translated to v4
m
#> Nothing to show
```
