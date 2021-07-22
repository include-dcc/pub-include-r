#' Title

#' @return
#' @export
#' @importFrom magrittr %>%
build_sankey <- function(pub_view) {
  pub_view %>% 
    dplyr::group_by(publicationYear, activity, administeringIc) %>% 
    dplyr::summarise(total = dplyr::n_distinct(pubMedId), .groups = "drop") %>% 
    dplyr::arrange(publicationYear) %>% 
    dplyr::mutate(publicationYear = as.character(publicationYear)) %>% 
    sfo::sankey_ly(
      cat_cols = c("administeringIc", "activity", "publicationYear"), 
      # col_types = c(administeringIc = "d", activity = "d", publicationYear = "c"),
      num_col = "total"
    )
}


.json_to_list <- function(json_str) {
  if (!is.na(json_str)) {
    jsonlite::fromJSON(json_str)
  } else {
    vector(mode = "character")
  }
}


sankey_ly <- function (x, cat_cols, col_types, num_col, title = NULL) 
{
  `%>%` <- magrittr::`%>%`
  index <- NULL
  if (!is.data.frame(x)) {
    stop("The input object is not a valid data.frame")
  }
  else if (!all(c(cat_cols, num_col) %in% names(x))) {
    stop("One or more column names does not matching to the names of the input object")
  }
  else if (length(num_col) != 1) {
    stop("Cannot define more than one numeric column with the num_col argument")
  }
  else if (length(cat_cols) < 2) {
    stop("Must define at least two categorical columns with the cat_cols argument")
  }
  else if (!is.null(title) && !is.character(title)) {
    stop("The title argument is not valid character object")
  }
  map <- function(x, cat_cols, col_types) {
    cat_col_vec <- unique_cat <- colour_vec <- map_df <- NULL
    x <- as.data.frame(x)
    for (i in cat_cols) {
      col_cat <- base::unique(x[, i])
      unique_cat <- c(unique_cat, col_cat)
      cat_col_vec <- c(cat_col_vec, base::rep(i, length(col_cat)))
      if (col_types[i] == "c") {
        colour_vec <- c(colour_vec, viridisLite::cividis(length(col_cat)))
      } else {
        colour_vec <- c(colour_vec, RColorBrewer::brewer.pal(length(col_cat), "Greys"))
      }
    }
    map_df <- base::data.frame(cat_col = cat_col_vec,
                               cat = unique_cat, 
                               index = 0:(length(unique_cat) - 1),
                               color = colour_vec,
                               stringsAsFactors = FALSE)
    return(map_df)
  }
  map <- map(x, cat_cols, col_types)
  df <- lapply(1:(base::length(cat_cols) - 1), function(i) {
    df <- NULL
    df <- x %>% 
      dplyr::group_by_(s = cat_cols[i], t = cat_cols[i + 1]) %>% 
      dplyr::summarise_(.dots = stats::setNames(paste("sum(", num_col, ",na.rm = TRUE)", sep = ""), "total")) %>% 
      dplyr::left_join(map %>% dplyr::select(s = cat, source = index), 
                       by = "s") %>% 
      dplyr::left_join(map %>% dplyr::select(t = cat, target = index), by = "t")
    return(df)
  }) %>% 
    dplyr::bind_rows()
  
  p <- plotly::plot_ly(
    type = "sankey", 
    orientation = "h", 
    valueformat = ".0f", 
    node = list(
      label = map$cat, 
      pad = 15, 
      thickness = 30, 
      line = list(color = "black", width = 0.5)
    ), 
    link = list(
      source = df$source, 
      target = df$target, 
      value = df$total
    )
  )
  if (!is.null(title)) {
    p <- p %>% plotly::layout(title = title)
  }
  return(p)
}

