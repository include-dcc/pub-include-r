#' build_pub_view 
#'
#' @description A fct function
#'
#' @return The return value, if any, from executing the function.
#'
#' @noRd
build_pub_view <- function(pub, grant) {
  pub_long <- pub %>% 
    dplyr::select(journal, pubMedId, publicationYear, grantNumber) %>% 
    dplyr::mutate(grantNumber = purrr::map(grantNumber, ~.json_to_list(.))) %>% 
    tidyr::unnest(grantNumber)
  
  grant_long <- grant %>% 
    dplyr::select(grantNumber, administeringIc, activity, organizationName) %>% 
    dplyr::filter(grantNumber != "nan")
  
  pub_grant <- pub_long %>% 
    dplyr::left_join(grant_long, by = "grantNumber")
}