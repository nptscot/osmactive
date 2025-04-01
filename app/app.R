library(shiny)
library(tmap)
library(osmextract)
library(sf)
library(dplyr)
library(osmactive)

ui = fluidPage(
  titlePanel("OSM Active Travel Map"),
  checkboxInput("toggleMode", "Toggle Map Mode (Plot/View)", TRUE),
  textInput("city", "Enter City Name:", "Groningen"),
  tmapOutput("map", height = "600px")
)


server = function(input, output, session) {
  
  # Reactive value to store the current tmap mode
  tmapMode = reactiveVal("plot")
  
  # Observe the button click and toggle the tmap mode
  observeEvent(input$toggleMode, {
    currentMode = tmapMode()
    if (currentMode == "plot") {
      tmapMode("view")
      tmap_mode("view")
    } else {
      tmapMode("plot")
      tmap_mode("plot")
    }
  })
  
  output$map = renderTmap({
    city_name = input$city
    currentMode = tmapMode()
    
    # Fetch OSM data for the city
    osm = tryCatch({
      get_travel_network(city_name)
    }, error = function(e) {
      NULL # Handle cases where the city is not found
    })
    
    if (is.null(osm)) {
      return(tm_shape(sf::st_sf(sf::st_sfc(crs = 4326))) +
               tm_text("City not found"))
    }
    
    # Get cycling networkcycle_net = get_cycling_network(osm)
    drive_net = get_driving_network(osm)
    drive_net_major = get_driving_network(osm)
    cycle_net = get_cycling_network(osm)
    cycle_net = distance_to_road(cycle_net, drive_net)
    cycle_net = classify_cycle_infrastructure(cycle_net)
    plot_osm_tmap(cycle_net)
  })
}

shinyApp(ui = ui, server = server)