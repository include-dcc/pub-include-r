#' The application server-side
#' 
#' @param input,output,session Internal parameters for {shiny}. 
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_server <- function( input, output, session ) {
  values <- reactiveValues()
  
  pub <- readr::read_tsv("data/publications_include.txt")
  grant <- readr::read_tsv("data/grants_include.txt")
  values$pub_view <- build_pub_view(pub, grant)

  
  # List the first level callModules here
  callModule(mod_pub_overview_server, "pub_overview_1", values)
  callModule(mod_pub_sankey_server, "pub_sankey_1", values)
}
