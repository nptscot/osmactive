# Classify ways by level of pedestrian/cyclist sharing

Ways on which bicycles and pedestrians share space are classified as
"Shared Footway". According to

## Usage

``` r
classify_shared_use(osm)
```

## Arguments

- osm:

  An sf object with the road network

## Value

An sf object with the classified cycle network

## Details

tagging includes:

- highway=path (signposted foot and bicycle path, no dividing line)

  - foot=designated

  - bicycle=designated

  - segregated=no

- highway=path (Signposted foot and bicycle path with dividing line.)

  - segregated=yes

- highway=pedestrian (A way intended for pedestrians)

## Examples

``` r
osm = osm_edinburgh
cycle_network = get_cycling_network(osm)
cycle_network_shared = classify_shared_use(cycle_network)
table(cycle_network_shared$cycle_pedestrian_separation)
#> 
#>     Shared Footway (segregated) Shared Footway (not segregated) 
#>                               2                               3 
#>                         Unknown 
#>                              78 
plot(cycle_network_shared["cycle_pedestrian_separation"])

# interactive map:
# mapview::mapview(cycle_network_shared, zcol = "cycle_pedestrian_separation")
```
