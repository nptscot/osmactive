message("Hello")

#remotes::install_github('nptscot/osmactive', dependencies = 'Suggests', ask = FALSE, Ncpus = parallel::detectCores())

library(shiny)
library(tmap)
library(osmextract)
library(sf)
library(dplyr)
library(osmactive)

message("Packages loaded")

ui = fluidPage(
  titlePanel("OSM Active Travel Map"),
  checkboxInput("toggleMode", "Toggle Map Mode (Plot/View)", TRUE),
  textInput("city", "Enter City Name:", "Groningen"),
  tmapOutput("map", height = "600px")
)

# TODO: make interactive?
tmap_mode("view")
server = function(input, output, session) {
  
  output$map = renderTmap({
    city_name = input$city    
    # Fetch OSM data for the city
    message("Getting OSM data")
    osm = tryCatch({
      get_travel_network(city_name)
    }, error = function(e) {
      NULL # Handle cases where the city is not found
    })
    
    if (is.null(osm)) {
      message("Loading osm data")
      return(tm_shape(sf::st_sf(sf::st_sfc(crs = 4326))) +
               tm_text("City not found"))
    }
    
    # Get cycling networkcycle_net = get_cycling_network(osm)
    drive_net = get_driving_network(osm)
    drive_net_major = get_driving_network(osm)
    cycle_net = get_cycling_network(osm)
    cycle_net = distance_to_road(cycle_net, drive_net)
    cycle_net = classify_cycle_infrastructure(cycle_net)

    output$map = renderTmap(plot_osm_tmap(cycle_net))

  })
}

shinyApp(ui = ui, server = server)