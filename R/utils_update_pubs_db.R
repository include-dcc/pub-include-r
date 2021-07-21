#' update_pubs_db 
#'
#' @description A utils function
#'
#' @return The return value, if any, from executing the utility.
#'
#' @noRd

.load_pubs_table <- function(filepath) {
  readr::read_tsv(filepath) %>% 
    dplyr::mutate_if(~ all(stringr::str_detect(., "\\[")),  
                     ~ .pd_list_to_json(.))
}


.clean_pubs_table <- function(pubs_tbl) {
  pubs_tbl %>% 
    dplyr::mutate_if(
      ~ all(stringr::str_detect(., "\\[")),
      ~ purrr::map_chr(., ~ ifelse(. == '[""]', "", .))
    ) %>% 
    dplyr::mutate(
      dplyr::across(
        dplyr::contains("Urls"), 
        ~ purrr::map_chr(., ~ .json_to_delim_str(.))
      )
    ) %>%
    I
}