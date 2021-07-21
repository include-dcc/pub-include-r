.pd_list_to_json <- function(pd_list_col) {
  purrr::map(pd_list_col, function(l) {
    stringr::str_replace_all(l, "(\\[|\\]|')", "") %>% 
      stringr::str_split(", ") %>% 
      purrr::flatten_chr() %>% 
      jsonlite::toJSON()
  })
}


.delim_str_to_json <- function(str, delimiter = ",") {
  json_str <- stringr::str_split(str, delimiter)[[1]] %>% 
    stringr::str_trim() %>% 
    jsonlite::toJSON()
  if (json_str == "[null]") {
    "[]"
  } else {
    json_str
  }
}


.json_to_delim_str <- function(json, delimiter = ",") {
  if (!is.na(json)) {
    jsonlite::fromJSON(json) %>% 
      stringr::str_c(collapse = delimiter)
  } else {
    NA
  }
}


.max_list_str_length <- function(list_col) {
  purrr::map(list_col, function(l) {
    if (!is.na(l)) {
      jsonlite::fromJSON(l) %>% 
        purrr::map_int(stringr::str_length) %>% 
        max(na.rm = TRUE) %>%
        I
    } else {
      0L
    }
  }) %>% 
    purrr::discard(is.infinite) %>%
    purrr::flatten_int() %>% 
    max()
}


.max_list_size <- function(list_col) {
  purrr::map(list_col, function(l) {
    if (!is.na(l)) {
      jsonlite::fromJSON(l) %>% 
        length()
    } else {
      0L
    }
  }) %>% 
    purrr::discard(is.infinite) %>%
    purrr::flatten_int() %>% 
    max()
}
