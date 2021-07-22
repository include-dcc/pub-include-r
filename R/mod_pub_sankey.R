#' pub_sankey UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd 
#'
#' @importFrom shiny NS tagList 
mod_pub_sankey_ui <- function(id){
  ns <- NS(id)
  tagList(
    fluidRow(
      plotly::plotlyOutput(ns("pub_sankey"))
    )
  )
}
    
#' pub_sankey Server Functions
#'
#' @noRd 
mod_pub_sankey_server <- function(input, output, session, values){
  ns <- session$ns
  output$pub_sankey <- plotly::renderPlotly(
    isolate(values$pub_view) %>% 
      build_sankey()
  )
}
    
## To be copied in the UI
# mod_pub_sankey_ui("pub_sankey_ui_1")
    
## To be copied in the server
# mod_pub_sankey_server("pub_sankey_ui_1")
