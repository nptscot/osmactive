# classify osm tags in 4 types:
# 1. Cycle track or lane: Light or separated tracks exclusive for cycling
# 2. Advisory lane: Marked (e.g. sharrow or advisory) cycle lanes, but shared with motor vehicles
# 3. Protected Active: Shared with pedestrians but not with motor vehicles
# 4. Mixed traffic: Shared with motor vehicles



library(dplyr)
library(sf)
library(osmactive)
library(tmap)

et_active = function() {
  c(
    "maxspeed",
    "oneway",
    "bicycle",
    "cycleway",
    "cycleway:left",
    "cycleway:right",
    "cycleway:both",
    "lanes",
    "lanes:both_ways",
    "lanes:forward",
    "lanes:backward",
    "lanes:bus",
    "lanes:bus:conditional",
    "oneway",
    "width",      # useful to ensure width of cycleways is at least 1.5m
    "segregated",  # classifies whether cycles and pedestrians are segregated on shared paths
    "sidewalk",    # useful to ensure width of cycleways is at least 1.5m
    "footway",
    # "highway", # included by default
    # "name", # included by default
    "service", 
    "surface", 
    "tracktype",
    "surface",
    "smoothness",
    "access",
    "foot" # add this to filter the protected to active modes 
  )
}

get_travel_network = function(
    place,
    extra_tags = et_active(),
    columns_to_remove = c("waterway", "aerialway", "barrier", "manmade"),
    ...
) {
  osm_highways = osmextract::oe_get(
    place = place,
    extra_tags = extra_tags,
    ...
  )
  osm_highways |>
    dplyr::filter(!is.na(highway)) |>
    # Remove all service tags based on https://wiki.openstreetmap.org/wiki/Key:service
    dplyr::filter(is.na(service)) |>
    dplyr::select(-dplyr::matches(columns_to_remove))
}


u = "https://ushift.tecnico.ulisboa.pt/content/data/lisbon_limit.geojson"
f = basename(u)
if (!file.exists(f)) download.file(u, f)
lisbon = sf::read_sf(f)
lisbon = lisbon |>
  sf::st_cast("POLYGON")
osm = get_travel_network("Portugal", boundary = lisbon, boundary_type = "clipsrc", force_vectortranslate = TRUE)
cycle_net = get_cycling_network(osm)
drive_net = get_driving_network_major(osm)
cycle_net = distance_to_road(cycle_net, drive_net)


classify_cycle_infrastructure_portugal = function(osm) {
  
  CYCLE_TRACK = "Cycle track or lane" # PT: Ciclovia segregada
  ADVISORY = "Advisory lane" # PT: Via partilhada com veículos motorizados (ex. zonas 30)
  PROTECTED_ACTIVE = "Protected Active" # PT: Via partilhada com peões
  MIXED_TRAFFIC = "Mixed traffic" # PT: Via banalizada
  
  osm |>
    # 1. Preliminary classification
    # If highway == cycleway|pedestrian|path, detailed_segregation can be defined in most cases...
    dplyr::mutate(detailed_segregation = dplyr::case_when(
      
      # Dedicated cycle lanes
      highway == "cycleway" ~ CYCLE_TRACK,
      highway == "path" & bicycle == "designated" ~ CYCLE_TRACK,
      
      # Sidewalks shared with bicycles
      highway == "footway" & bicycle == "yes" ~ PROTECTED_ACTIVE,
      highway == "pedestrian" & bicycle == "designated" ~ PROTECTED_ACTIVE,
      
      # When `segregated` tag set, it is not shared with traffic (https://wiki.openstreetmap.org/wiki/Key:segregated)
      segregated == "yes" ~ CYCLE_TRACK,
      segregated == "no" ~ CYCLE_TRACK,
      
      # If none verify, lets consider them lanes shared with cars 
      TRUE ~ MIXED_TRAFFIC
    )) |>
    
    # 2. Let's analyse the `cycleway` tags... (https://wiki.openstreetmap.org/wiki/Tag:highway%3Dcycleway)
    tidyr::unite("cycleway_chars", dplyr::starts_with("cycleway"), sep = "|", remove = FALSE) |>
    dplyr::mutate(detailed_segregation2 = dplyr::case_when(
      stringr::str_detect(cycleway_chars, "separate") & detailed_segregation == "Mixed traffic" ~ CYCLE_TRACK, 
      stringr::str_detect(cycleway_chars, "buffered_lane") & detailed_segregation == "Mixed traffic" ~ CYCLE_TRACK, 
      stringr::str_detect(cycleway_chars, "segregated") & detailed_segregation == "Mixed traffic" ~ CYCLE_TRACK, 
      TRUE ~ detailed_segregation
    )) |>
    
    dplyr::mutate(detailed_segregation2 = dplyr::case_when(
      stringr::str_detect(cycleway_chars, "shared_lane") ~ ADVISORY,
      stringr::str_detect(cycleway_chars, "lane") & detailed_segregation == "Mixed traffic" ~ CYCLE_TRACK,
      stringr::str_detect(cycleway_chars, "track") & detailed_segregation == "Mixed traffic" ~ CYCLE_TRACK,
      TRUE ~ detailed_segregation
    )) |>
    
    # 3. Let's clarify that previously classified cycle lanes are not shared with pedestrians
    dplyr::mutate(detailed_segregation4 = dplyr::case_when(
      detailed_segregation2 == CYCLE_TRACK & highway %in% c("cycleway", "path") & foot %in% c("designated", "permissive", "private", "use_sidepath", "yes") & (is.na(sidewalk) | sidewalk=="no") & (is.na(segregated) | segregated=="no") ~ PROTECTED_ACTIVE,
      detailed_segregation2 == CYCLE_TRACK & highway == "footway" & bicycle %in% c("yes" , "designated") ~ PROTECTED_ACTIVE,
      detailed_segregation2 == CYCLE_TRACK & highway == "pedestrian" & bicycle %in% c("yes" , "designated") ~ PROTECTED_ACTIVE,
      TRUE ~ detailed_segregation2
    )) |>
    
    dplyr::mutate(cycle_segregation = factor(
      detailed_segregation4,
      levels = c(CYCLE_TRACK, ADVISORY, PROTECTED_ACTIVE, MIXED_TRAFFIC),
      ordered = TRUE
    ))
}


   # "Cycle track or lane": Light or separated tracks exclusive for cycling
   # "Mixed traffic": Marked (e.g. sharrow or advisory) cycle lanes
   # "Proctected Active":Shared with pedestrians

cycle_net_pt = classify_cycle_infrastructure_portugal(cycle_net)

# table(stringr::str_detect(cycle_net_pt$cycleway_chars, "lane") & cycle_net_pt$detailed_segregation == "Mixed traffic")


table(cycle_net_pt$detailed_segregation)
table(cycle_net_pt$detailed_segregation2)
table(cycle_net_pt$detailed_segregation4)
table(cycle_net_pt$cycle_segregation)

m = plot_osm_tmap(cycle_net_pt)
m

mapview::mapview(cycle_net_pt |> filter(cycle_segregation != "Mixed traffic"), zcol="cycle_segregation")

# there are still a lot of them what have the osm tag foot="yes" and shouldn't have it.
# Edit in OSM. Examples
# https://www.openstreetmap.org/way/976381232
# https://www.openstreetmap.org/way/686372908
# https://www.openstreetmap.org/way/498545079


