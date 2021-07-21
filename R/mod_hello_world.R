#' hello_world UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd 
#'
#' @importFrom shiny NS tagList 
mod_hello_world_ui <- function(id){
  ns <- NS(id)
  tagList(
    
    # Sidebar layout with input and output definitions ----
    sidebarLayout(
      
      # Sidebar panel for inputs ----
      sidebarPanel(
        
        # Input: Slider for the number of bins ----
        sliderInput(inputId = ns("bins"),
                    label = "Number of bins:",
                    min = 1,
                    max = 50,
                    value = 30)
      ),
      # Main panel for displaying outputs ----
      mainPanel(

        # Output: Histogram ----
        plotOutput(ns("distPlot"))

      )
    )
  )
}
    
#' hello_world Server Function
#'
#' @noRd 
mod_hello_world_server <- function(input, output, session){
  ns <- session$ns
  output$distPlot <- renderPlot({

    x    <- faithful$waiting
    bins <- seq(min(x), max(x), length.out = input$bins + 1)

    hist(x, breaks = bins, col = "#75AADB", border = "white",
         xlab = "Waiting time to next eruption (in mins)",
         main = "Histogram of waiting times")
    
  })
}
    
## To be copied in the UI
# mod_hello_world_ui("hello_world_ui_1")
    
## To be copied in the server
# callModule(mod_hello_world_server, "hello_world_ui_1")
 
