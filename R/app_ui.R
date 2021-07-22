#' The application User-Interface
#' 
#' @param request Internal parameter for `{shiny}`. 
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_ui <- function(request) {
  tagList(
    # Leave this function for adding external resources
    golem_add_external_resources(),
    # List the first level UI elements here 

    semantic.dashboard::dashboardPage(
      semantic.dashboard::dashboardHeader(title = "INCLUDE Publications"),
      semantic.dashboard::dashboardSidebar(
        sidebarMenu(
          menuItem("Home", tabName = "home"),
          menuItem("Overview", tabName = "overview"),
          menuItem("Sankey", tabName = "sankey")
        )
      ),
      semantic.dashboard::dashboardBody(
        golem_add_external_resources(),
        semantic.dashboard::tabItems(
          tabItem("overview", mod_pub_overview_ui("pub_overview_1")),
          tabItem("sankey", mod_pub_sankey_ui("pub_sankey_1"))
        )
      )
    )
  )
}

#' Add external Resources to the Application
#' 
#' This function is internally used to add external 
#' resources inside the Shiny application. 
#' 
#' @import shiny
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @noRd
golem_add_external_resources <- function(){

  add_resource_path(
    'www', app_sys('app/www')
  )

  tags$head(
    favicon(),
    bundle_resources(
      path = app_sys('app/www'),
      app_title = 'pubincluder'
    )
    # Add here other external resources
    # for example, you can add shinyalert::useShinyalert() 
  )
}

