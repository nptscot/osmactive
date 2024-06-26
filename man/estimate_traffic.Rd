% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/osmactive.R
\name{estimate_traffic}
\alias{estimate_traffic}
\title{Estimate traffic}
\usage{
estimate_traffic(osm)
}
\arguments{
\item{osm}{An sf object with the road network}
}
\value{
An sf object with the estimated road traffic volumes in the column \code{assumed_volume}
}
\description{
Estimate traffic
}
\examples{
osm = osm_edinburgh
osm_traffic = estimate_traffic(osm)
# check NAs:
sel_nas = is.na(osm_traffic$assumed_volume)
osm_no_traffic = osm_traffic[sel_nas, c("highway")]
table(osm_no_traffic$highway) # Active travel infrastructure has no road traffic
table(osm_traffic$assumed_volume, useNA = "always")
}
