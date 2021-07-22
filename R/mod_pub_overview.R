#' pub_overview UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd 
#'
#' @importFrom shiny NS tagList 
mod_pub_overview_ui <- function(id){
  ns <- NS(id)
  tagList(
    h3("Publications Quickview"),
    fluidRow(
      DT::DTOutput(ns("pub_quickview"))
    )
  )
}
    
#' pub_overview Server Function
#'
#' @noRd 
mod_pub_overview_server <- function(input, output, session, values){
  ns <- session$ns
  output$pub_quickview <- DT::renderDT(
    isolate(values$pub_view),
    options = list(dom = 'tip'), rownames = FALSE
  )
 
}
    
## To be copied in the UI
# mod_pub_overview_ui("pub_overview_ui_1")
    
## To be copied in the server
# callModule(mod_pub_overview_server, "pub_overview_ui_1")
 
