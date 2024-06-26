% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/osmactive.R
\name{get_driving_network}
\alias{get_driving_network}
\alias{get_driving_network_major}
\title{Get the OSM driving network}
\usage{
get_driving_network(osm, ex_d = exclude_highway_driving())

get_driving_network_major(
  osm,
  ex_d = exclude_highway_driving(),
  pattern = "motorway|trunk|primary|secondary|tertiary"
)
}
\arguments{
\item{osm}{An OSM network object}

\item{ex_d}{A character string of highway values to exclude in the form \code{value1|value2} etc}

\item{pattern}{A character string of highway values to define major roads in the form \code{motorway|trunk|primary|secondary|tertiary}}
}
\value{
A sf object with the OSM driving network
}
\description{
This function returns the OSM driving network by excluding certain highway values.
}
\details{
\code{get_driving_network_major} returns only the major roads.
}
