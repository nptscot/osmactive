# Mapping, classifying, and integrating diverse street network datasets: new methods and open source tools for active travel planning

## Published versions

See the [pdf
version](https://github.com/nptscot/osmactive/releases/download/v0.1/gisruk2025.pdf)
and [html
version](https://nptscot.github.io/osmactive/articles/gisruk2025.html)
at
[nptscot.github.io/osmactive](https://nptscot.github.io/osmactive/articles/gisruk2025.html).

## Introduction

Active travel is an accessible and cost-effective way to replace short
car trips and make transport systems more sustainable. The Network
Planning Tool (NPT) for Scotland is a new web-based strategic network
planning tool that estimates cycling potential down to the street level.
The NPT builds on the functionality of the Propensity to Cycle Tool
(PCT) and related tools \[@lovelace2017; @goodman2019; @lovelace2024;
@félix2025\], offering a detailed nationwide cycling potential analysis
for Scotland. The NPT is funded by Transport Scotland and developed by
the University of Leeds in collaboration with Sustrans Scotland. The
tool is open-source and hosted at
[github.come/nptscot](https://github.com/nptscot), enabling others to
learn from and contribute to the underlying methods to help make
transport planning more open and participatory \[@lovelace2020a\].

A unique feature of the NPT is its integration of multiple layers into a
single tool, overcoming limitations of previous strategic network
planning tools, which generally focus either on behaviour data (such as
the PCT) or physical infrastructure \[@vybornova2024; @vierø2024\]. The
NPT brings together more than a dozen datasets, including Ordnance
Survey Mastermap and OpenStreetmap data products to provide
comprehensive data on the potential for mode shift, infrastructure,
modelled motor traffic levels, and street space at the network level.
This paper presents new geographic methods we developed to support this
work, with reference to reproducible code that use the new `osmactive` R
package for classifying national-scale OpenStreetMap (OSM) datasets
based on attributes and geographic relationships, and the `anime` Rust
crate for astonishingly fast and accurate route network data
integration.

## Datasets and methods

The NPT uses datasets from diverse sources including from the DfT’s
network of traffic sensors, motor traffic counts based a survey
evaluating Edinburgh’s roll-out of 20 mph speed limits, the National
Travel Survey, and the Scottish Household Travel Survey. We used four
key datasets representing the road network for this project:

- Ordnance Survey OpenRoads, an open access and simplified
  representation of the road network that is ideal for visualisation
- OS MasterMap Highways, a more detailed dataset that includes
  information on road widths and other features
- OS Mastermap Topography, the most detailed vector dataset that
  includes detailed information on the geometry of many features of the
  man-made environment, including curb lines. In the OS Topo layer roads
  and other pieces of transport infrastructure such as footways
  (pavements) are represented not as corridor or lane centerlines, but
  as polygons.
- OpenStreetMap, a crowdsourced dataset that is continuously updated by
  community volunteers. The dataset is rich, with tags for width and
  smoothness of infrastructure, but is not as consistent as the OS
  datasets.

Ordnance Survey’s MasterMap Highways and Topography datasets provide
unparalleled accuracy and detail, but are a struggle to import using
consumer-grade hardware and standard tools such as QGIS. To overcome
this issue we developed [the `mastermapr`
package](https://github.com/acteng/mastermapr) in collaboration with the
government agency Active Travel England (ATE), to efficiently and
flexibly imports MasterMap datasets (50 GB compressed). After importing
the four route network datasets outlined above, we integrated them using
the following steps:

- Pavement widths were calculated from the OS MasterMap Topography
  dataset using the function `get_pavement_widths()` from the
  `osmactive` package. This function calculates the width of manmade
  roadside features associated with each road segment by dividing the
  area of matching polygons associated with each road segment by the
  length of the road segment.
- The
  [`get_bus_routes()`](https://nptscot.github.io/osmactive/reference/get_bus_routes.md)
  function from the `osmactive` package was used to determine the number
  of bus lanes on each road segment.
- We used the `anime` Rust crate to efficiently join the networks, based
  on alignment and proximity. The use of spatial indexes makes the
  implementation highly efficient compared with the
  [`rnet_join()`](https://docs.ropensci.org/stplanr/reference/rnet_join.html)
  function in the R package `stplanr` that we were using previously. See
  the [josiahparry/ANIME codebase on
  GitHub](https://github.com/JosiahParry/anime) for details of the new
  algorithm and its implementation as an R (and planned Python)
  interface to the new [`anime` Rust
  crate](https://crates.io/crates/anime).

### Classifying OpenStreetNetwork ways

Functions including
[`get_travel_network()`](https://nptscot.github.io/osmactive/reference/get_travel_network.md)
and
[`classify_cycle_infrastructure()`](https://nptscot.github.io/osmactive/reference/classify_cycle_infrastructure.md)
from the `osmactive` package were used to classify cycle infrastructure
types based on the presence of cycle lanes, tracks, and other features
(see the code snippet which generates @fig-bristol below).

``` r
osm = get_travel_network("bristol")
cycle_net = get_cycling_network(osm)
drive_net = get_driving_network(osm)
cycle_net = distance_to_road(cycle_net, drive_net)
cycle_net = classify_cycle_infrastructure(cycle_net)
plot_osm_tmap(cycle_net)
```

![Cycle infrastructre and painted cycle lanes in Bristol, generated with
5 lines of code using the osmactive package. See interactive version
online at github.com/nptscot/osmactive/releases.](images/paste-1.png)

Cycle infrastructre and painted cycle lanes in Bristol, generated with 5
lines of code using the osmactive package. See interactive version
online at
[github.com/nptscot/osmactive/releases](https://github.com/nptscot/osmactive/releases/download/v0.1/cycle_net_bristol.html).

### Road width measurements

Two key measurements are needed to assess whether existing roads can
accommodate cycle infrastructure: carriageway width and corridor width,
as defined below.

Accurate and available carriageway width measurements are important
because they determine if proposed infrastructure can fit solely within
the carriageway, without the need for moving curbs or other roadside
features. The Scottish Cycling by Design (CbD) guidance document
outlines three types of cycle infrastructure that run along the
carriageway, building on Department for Transport guidance
\[@departmentfortransport2020\]:

- Cycle track at carriageway level
- Stepped cycle track
- Cycle track at footway level

The first option, cycle track that is at carriage level, has additional
advantages over stepped cycleway, being often cheaper to construct [with
no new tarmac required in many
cases](https://www.transport.gov.scot/media/50323/cycling-by-design-update-2019-final-document-15-september-2021-1.pdf#page=76)
but requires sufficient width on the existing carriageway to accommodate
the cycle infrastructure.

Corridor width captures the carriageway plus any built roadside
features, such as footways. The following [`dplyr`
query](https://dplyr.tidyverse.org/) was used to extract the width of
manmade roadside features:
`filter(descriptive_group == "Roadside", make == "Manmade")`. From that
point, we calculated the width of pavements associated with each road
segment by dividing the area of matching polygons associated with each
road segment by the length of the road segment, as implemented in the
`get_pavement_widths()` function in the `osmactive` package.

### Minimum cycle track and buffer widths

The corridor width is important because it determines whether, in cases
where there is insufficient space on the carriageway, part of the
footway or other manmade roadside features may be reallocated for cycle
infrastructure, while still maintaining recommended minimum widths for
pedestrians. CbD guidance on widths is summarised in table @tbl-cbd.

| Cycle infrastructure type  | Absolute minimum width | Desirable minimum width |
|----------------------------|------------------------|-------------------------|
| Unidirectional cycle track | 1.5 m                  | 2.0 m                   |
| Bidirectional cycle track  | 2.0 m                  | 3.0 m                   |

Table illustrating the minimum width requirements for cycle
infrastructure according to the Cycling by Design (CbD) guidance.
{#tbl-cbd}

CbD also specifies buffers that must be accounted for when calculating
the effective available width for cycle infrastructure (@tbl-buffers).

| Road type / Speed limit | Buffer width |
|-------------------------|--------------|
| 30 mph                  | 0.5 m        |
| 40 mph                  | 1.0 m        |
| 50 mph                  | 2.0 m        |
| 60 mph                  | 2.5 m        |
| 70 mph                  | 3.5 m        |

Table illustrating the buffer widths for cycle infrastructure based on
road type and speed limit according to the Cycling by Design (CbD)
guidance. {#tbl-buffers}

Speed limit data taken from OSM was used to determine the buffer width
for each road segment.

### Bus routes and road traffic assumptions

The minimum space requirements for motor traffic depend on the uses of
the road, including whether it is a bus route and whether there are
dedicated bus lanes. Based on the Active Travel England cross section
check tool, part of [Active Travel England’s open access Excel-based
design
tools](https://www.gov.uk/government/publications/active-travel-england-design-assistance-tools)
(see
[acteng.github.io/inspectorate_tools/](https://acteng.github.io/inspectorate_tools/)
for web-based versions), we assumed the following widths for motor
traffic:

- Non-bus routes: 2 × 2.75 m
- Bus routes without dedicated bus lanes: 2 × 3.2 m
- Bus routes with dedicated bus lanes: 2 × 3.2 m plus an additional
  space of `n_bus_lanes` × 3.2 m for the dedicated bus lanes.

The number of bus lanes was determined from the OSM data with the
function
[`get_bus_routes()`](https://nptscot.github.io/osmactive/reference/get_bus_routes.html)
in the R package `osmactive` that we developed for this project. The
results are illustrated in @fig-edinburgh-bus-lanes, which can also be
reproduced with the following [Overpass Turbo
query](https://overpass-turbo.eu/s/1Xaf):

    relation["route"="bus"]({{bbox}});

## Results

The result of the data engineering, data integration, modelling and
visualisation steps described above is datasets that are visualised
interactively in the NPT web application, using `pmtiles` for efficient
rendering of large datasets \[@gonçalves2023\]. The key components of
the NPT are:

- The “Route network” layer, presenting data on cycling potential on
  OSM-based and simplified \[@lovelace_reproducible_2024\] network
  layers.
- The “Infrastructure and traffic” layer, which includes data on motor
  traffic levels and cycle infrastructure.
- The “Street space” layer, which categorises roads in accordance with
  the Cycling by Design guidance, specifying the methodology for
  classifying road spaces and cycle infrastructure, presented in
  @fig-street-space.
- The “Core network” layer, representing a cohesive network that could
  be a priority when planning new infrastructure, building on previous
  work \[@szell2021\].
- The [Network Planning Workspace (NPW)](https://nptscot.github.io/npw/)
  web application, which allows users to explore the data and create
  custom scenarios of infrastructure change.

## Conclusion

The Network Planning Tool for Scotland is a cutting-edge web application
designed for strategic cycle network planning. A unique feature of the
NPT is its integration of multiple layers into a single tool, overcoming
limitations of previous strategic network planning tools, which
generally focus either on behaviour data or physical infrastructure. The
new street space layer represents a step change in access to combined
carriageway and corridor widths, the first time this data has been made
available at a national level, to the best of our knowledge.

In future work we plan to improve the NPT by incorporating new datasets
from a variety of sources, including [Scotland’s Spatial
Hub](https://data.spatialhub.scot). We would like to develop
context-specific classifications in the `osmactive` package to better
address the diverse needs of different urban environments and support
the roll-out the methods in new places.

## References

## Acknowledgements

Thanks to Transport Scotland for funding the development of the Network
Planning Tool for Scotland, and to the many users who have provided
feedback on the tool. Thanks to Sustrans Scotland, and Matt Davis and
Angus Calder in particular, for collaborating on the project.

Thanks to the OpenStreetMap community for creating and maintaining the
data that underpins the NPT. Thanks to Ordnance Survey for providing the
MasterMap data that underpins the NPT (contains OS data © Crown
copyright and database rights 2025 OS licence number 100046668).

## Biographies

Robin Lovelace is Professor of Transport Data Science at the Leeds
Institute for Transport Studies (ITS) and specialises in data science
and geocomputation, with a focus on modeling transport systems, active
travel, and decarbonisation.

Zhao Wang is a researcher at the Leeds Institute for Transport Studies
(ITS). Zhao specializes in machine learning, data science and
geocomputation for transport planning and engineering.

Hussein Mahfouz is a PhD student at the Leeds Institute for Transport
Studies (ITS) and specialises in data science and geocomputation for
transport planning and engineering, with a focus on Demand Responsive
Transport (DRT).

Juan Pablo Fonseca Zamora is a PhD student at the Leeds Institute for
Transport Studies (ITS) and specialises in new methods for traffic
modelling.

Angus Calder is a Senior Mobility Planner at Sustrans Scotland and
specialises in active travel planning and infrastructure design.

Martin Lucas-Smith is a Director at CycleStreets Ltd and specialises in
open data and open source software for cycling.

Dustin Carlino is an independent researcher and software developer,
specialising in open source software development and geographic data
science.

Josiah Parry is a Senior Product Engineer at Environmental Systems
Research Institute, Inc (Esri) and an open source software developer.

Rosa Félix is a researcher at the University of Lisbon and specialises
geographic methods for transport planning, with a focus on active travel
and decarbonisation.
