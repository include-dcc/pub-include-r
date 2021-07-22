#' update_grants_db 
#'
#' @description A utils function
#' @importFrom magrittr %>%
#' @return The return value, if any, from executing the utility.
#'
#' @noRd
update_grants_db <- function() {
  .fetch_grants_table() %>% 
    .filter_grants() %>% 
    .format_grants()
}


.fetch_grants_table <- function() {
  sheets_id <- "17dWU0Vh_fR0Kg_tBsCAYfGBt5UdacnzZr3mlUzPay3g"
  googlesheets4::read_sheet(
    sheets_id, 
    col_types = "cccccciDccicciiccDDc?iccicicddicccccccDDiciiiciiicc"
  )
}


.filter_grants <- function(grants_tbl) {
  grants_tbl %>% filter(`INCLUDE Project?` == "Yes")
}


.format_grants <- function(grants_tbl) {
  grants_tbl %>% 
    dplyr::mutate(
      grant_regex = stringr::str_glue("(?<={Activity})\\w+"),
      `Grant Number` = stringr::str_extract(`Project Number`, grant_regex)
    ) %>% 
    dplyr::select(`Project Title`,
                  `Administering  IC`,
                  `Application ID`,
                  `Award Notice Date`,
                  FOA,
                  `Project Number`,
                  `Grant Number`,
                  Type,
                  Activity,
                  IC,
                  `Serial Number`,
                  `Project Start Date`,
                  `Project End Date`,
                  `Contact PI  Person ID`,
                  `Contact PI / Project Leader`,
                  `Organization Name`,
                  `Organization ID (IPF)`) %>% 
    dplyr::distinct() %>% 
    janitor::clean_names()
}
