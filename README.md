
<!-- README.md is generated from README.Rmd. Please edit that file -->

# osmactive

<!-- badges: start -->

[![R-CMD-check](https://github.com/nptscot/osmactive/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/nptscot/osmactive/actions/workflows/R-CMD-check.yaml)

<!-- badges: end -->

The goal of osmactive is to provide functions, example datasets and
documentation for extracting active travel infrastructure from
OpenStreetMap data.

Install the package with:

``` r
remotes::install_github("nptscot/osmactive")
```

``` r
library(osmactive)
library(tmap) # for mapping
library(dplyr) # for data manipulation
library(sf) # for spatial data
```

Alternatively, you can load the package with the following for local
development:

## Minimal example

The package comes with example data for testing functions. You can test
the functions as follows:

``` r
osm = osm_edinburgh
cycle_net = get_cycling_network(osm)
drive_net = get_driving_network(osm)
drive_net_major = get_driving_network_major(osm)
cycle_net = distance_to_road(cycle_net, drive_net)
cycle_net = classify_cycle_infrastructure(cycle_net)
table(cycle_net$detailed_segregation)
#> 
#> Cycle lane on carriageway               Level track             Mixed traffic 
#>                         1                        13                        52 
#>        Remote cycle track        Stepped or footway 
#>                         4                         1
table(cycle_net$cycle_segregation)
#> 
#>                     Remote cycle track           Separated cycle track (wide) 
#>                                      4                                      6 
#> Separated cycle track (narrow/unknown)              Cycle lane on carriageway 
#>                                      8                                      1 
#>                          Mixed traffic 
#>                                     52
tm_shape(osm) +
  tm_lines(col = "grey") +
  tm_shape(cycle_net) +
  tm_lines(col = "green") +
  tm_shape(drive_net) +
  tm_lines(col = "darkgrey") +
  tm_shape(drive_net_major) +
  tm_lines(col = "black")
```

![](man/figures/README-minimal-1.png)<!-- -->

You can also create plots with the packaged `plot_osm_tmap()` function:

``` r
m = plot_osm_tmap(cycle_net)
m
```

![](man/figures/README-minimal_plot_osm_tmap-1.png)<!-- -->

## Leeds example

``` r
leeds_zb = zonebuilder::zb_zone("Leeds")
leeds = leeds_zb |>
  filter(circle_id == 1) |>
  sf::st_union() |>
  sf::st_make_valid()
osm = get_travel_network("Leeds", boundary = leeds, boundary_type = "clipsrc")
#> 0...10...20...30...40...50...60...70...80...90...100 - done.
#> Reading layer `lines' from data source `/home/robin/data/osm/bbbike_Leeds.gpkg' using driver `GPKG'
#> Simple feature collection with 4163 features and 33 fields
#> Geometry type: MULTILINESTRING
#> Dimension:     XY
#> Bounding box:  xmin: -1.558963 ymin: 53.78843 xmax: -1.528622 ymax: 53.80639
#> Geodetic CRS:  WGS 84
cycle_net = get_cycling_network(osm)
drive_net = get_driving_network_major(osm)
cycle_net = distance_to_road(cycle_net, drive_net)
cycle_net = classify_cycle_infrastructure(cycle_net)
m = plot_osm_tmap(cycle_net)
m
```

![](man/figures/README-leeds-1.png)<!-- -->

## Edinburgh example

``` r
devtools::load_all()
library(tidyverse)
edinburgh = zonebuilder::zb_zone("Edinburgh")
edinburgh_3km = edinburgh |>
  # Change number in next line to change zone size:
  filter(circle_id <= 2) |>
  sf::st_union()
osm = get_travel_network("Scotland", boundary = edinburgh_3km, boundary_type = "clipsrc")
#> 0...10...20...30...40...50...60...70...80.
#> ..90...100 - done.
#> Reading layer `lines' from data source 
#>   `/home/robin/data/osm/geofabrik_scotland-latest.gpkg' using driver `GPKG'
#> Simple feature collection with 44341 features and 33 fields
#> Geometry type: MULTILINESTRING
#> Dimension:     XY
#> Bounding box:  xmin: -3.236391 ymin: 55.9264 xmax: -3.140354 ymax: 55.98029
#> Geodetic CRS:  WGS 84
cycle_net = get_cycling_network(osm)
drive_net = get_driving_network_major(osm)
system.time({
  cycle_net = distance_to_road(cycle_net, drive_net)
})
#>    user  system elapsed 
#>   0.371   0.000   0.371
# 0.269s with union, 0.071s without
cycle_net = classify_cycle_infrastructure(cycle_net)
m = plot_osm_tmap(cycle_net)
m
```

![](man/figures/README-edinburgh-1.png)<!-- -->

<!-- Save an interactive version of the map to check the results as follows: -->

## Dublin example

``` r
dublin_zones = zonebuilder::zb_zone("Dublin")
dublin = dublin_zones |>
  filter(circle_id == 1)
osm = get_travel_network("Republic of Ireland", boundary = dublin, boundary_type = "clipsrc")
#> 0...10...20...30...40...50...60...
#> 70...80...90...100 - done.
#> Reading layer `lines' from data source 
#>   `/home/robin/data/osm/geofabrik_ireland-and-northern-ireland-latest.gpkg' 
#>   using driver `GPKG'
#> Simple feature collection with 3723 features and 33 fields
#> Geometry type: MULTILINESTRING
#> Dimension:     XY
#> Bounding box:  xmin: -6.275573 ymin: 53.3404 xmax: -6.245544 ymax: 53.35836
#> Geodetic CRS:  WGS 84
cycle_net = get_cycling_network(osm)
drive_net = get_driving_network_major(osm)
cycle_net = distance_to_road(cycle_net, drive_net)
cycle_net = classify_cycle_infrastructure(cycle_net)
m = plot_osm_tmap(cycle_net)
m
```

![](man/figures/README-dublin-1.png)<!-- -->

## Lisbon example

``` r
u = "https://ushift.tecnico.ulisboa.pt/content/data/lisbon_limit.geojson"
f = basename(u)
if (!file.exists(f)) download.file(u, f)
lisbon = sf::read_sf(f)
lisbon = lisbon |>
  sf::st_cast("POLYGON")
osm = get_travel_network("Portugal", boundary = lisbon, boundary_type = "clipsrc", force_vectortranslate = TRUE)
#> 0...10...20...30...40...50...60...70...
#> 80...90...100 - done.
#> Reading layer `lines' from data source 
#>   `/home/robin/data/osm/geofabrik_portugal-latest.gpkg' using driver `GPKG'
#> Simple feature collection with 47866 features and 33 fields
#> Geometry type: MULTILINESTRING
#> Dimension:     XY
#> Bounding box:  xmin: -9.229835 ymin: 38.6914 xmax: -9.087336 ymax: 38.79747
#> Geodetic CRS:  WGS 84
cycle_net = get_cycling_network(osm)
drive_net = get_driving_network_major(osm)
cycle_net = distance_to_road(cycle_net, drive_net)
cycle_net = classify_cycle_infrastructure(cycle_net)
m = plot_osm_tmap(cycle_net)
m
```

![](man/figures/README-lisbon-1.png)<!-- -->

## London

``` r
devtools::load_all()
london = zonebuilder::zb_zone("Southwark Station", n_circles = 1)
london = sf::st_union(london) |>
  sf::st_make_valid()
osm = get_travel_network(london, boundary = london, boundary_type = "clipsrc")
#> 0...10...20...30...40...50...60...70...80...90...100 - done.
#> Reading layer `lines' from data source 
#>   `/home/robin/data/osm/geofabrik_greater-london-latest.gpkg' 
#>   using driver `GPKG'
#> Simple feature collection with 5856 features and 33 fields
#> Geometry type: MULTILINESTRING
#> Dimension:     XY
#> Bounding box:  xmin: -0.1188785 ymin: 51.49424 xmax: -0.09009284 ymax: 51.51222
#> Geodetic CRS:  WGS 84
cycle_net = get_cycling_network(osm)
drive_net = get_driving_network_major(osm)
cycle_net = distance_to_road(cycle_net, drive_net)
cycle_net = classify_cycle_infrastructure(cycle_net)
m = plot_osm_tmap(cycle_net)
m
```

![](man/figures/README-london-1.png)<!-- -->
