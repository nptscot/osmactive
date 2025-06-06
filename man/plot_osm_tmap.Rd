% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/osmactive.R
\name{plot_osm_tmap}
\alias{plot_osm_tmap}
\title{Create a tmap object for visualizing the classified cycle network}
\usage{
plot_osm_tmap(
  cycle_network_classified,
  popup.vars = c("name", "osm_id", "cycle_segregation", "distance_to_road", "maxspeed",
    "highway", "cycleway", "bicycle", "lanes", "width", "surface", "other_tags"),
  lwd = 4,
  palette = get_palette_npt()
)
}
\arguments{
\item{cycle_network_classified}{An sf object with the classified cycle network}

\item{popup.vars}{A vector of variables to be displayed in the popup}

\item{lwd}{The line width for the cycle network}

\item{palette}{The palette to be used for the cycle segregation levels,
such as "-PuBuGn" or "npt" (default)}
}
\value{
A tmap object for visualizing the classified cycle network
}
\description{
Create a tmap object for visualizing the classified cycle network
}
