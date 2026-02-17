# Create a tmap object for visualizing the classified cycle network

Create a tmap object for visualizing the classified cycle network

## Usage

``` r
plot_osm_tmap(
  cycle_network_classified,
  popup.vars = c("name", "osm_id", "cycle_segregation", "distance_to_road", "maxspeed",
    "highway", "cycleway", "bicycle", "lanes", "width", "surface", "other_tags"),
  lwd = 4,
  palette = get_palette_npt()
)
```

## Arguments

- cycle_network_classified:

  An sf object with the classified cycle network

- popup.vars:

  A vector of variables to be displayed in the popup

- lwd:

  The line width for the cycle network

- palette:

  The palette to be used for the cycle segregation levels, such as
  "-PuBuGn" or "npt" (default)

## Value

A tmap object for visualizing the classified cycle network
