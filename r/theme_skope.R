library(hrbrthemes)
library(showtext)
library(ggplot2)
library(dplyr)
library(scales)

skope_load_fonts <- function() {
  font_add_google("Rubik", "Rubik")
  showtext_auto()
}

theme_skope <- function(grid = "Y") {
  theme_ipsum_rc(grid = grid, base_family = "Rubik") +
    theme(legend.position = "bottom")
}

#' Create a standard caption with source and update information
#'
#' @param source Character string with the data source
#' @param last_date Date of the most recent observation
#' @return Character caption
skope_caption <- function(source, last_date) {
  paste0(
    "Fuente: ", source,
    ". Datos hasta ", format(last_date, "%d %b, %Y"),
    "\nÚltima actualización: ", format(Sys.time(), "%d %b, %Y")
  )
}

#' Highlight the last observation on a time series plot
#'
#' @param data Data frame used in the plot
#' @param x Name of the x variable as string
#' @param y Name of the y variable as string
#' @param color Point and text color. If NULL, inherit from aesthetics
#' @param label_fmt Label format function from scales
#' @return List of ggplot2 layers
highlight_last <- function(data, x, y, color = NULL,
                           label_fmt = label_number(accuracy = 0.1)) {
  last <- data %>% filter(.data[[x]] == max(.data[[x]], na.rm = TRUE))
  range_y <- range(data[[y]], na.rm = TRUE)
  nudge <- diff(range_y) * 0.03

  if (is.null(color)) {
    list(
      geom_point(data = last, aes(.data[[x]], .data[[y]]), size = 2),
      geom_text(
        data = last,
        aes(
          .data[[x]],
          .data[[y]],
          label = label_fmt(.data[[y]])
        ),
        nudge_y = nudge,
        hjust = 0,
        size = 3,
        show.legend = FALSE
      )
    )
  } else {
    list(
      geom_point(data = last, aes(.data[[x]], .data[[y]]), color = color, size = 2),
      geom_text(
        data = last,
        aes(
          .data[[x]],
          .data[[y]],
          label = label_fmt(.data[[y]])
        ),
        color = color,
        nudge_y = nudge,
        hjust = 0,
        size = 3,
        show.legend = FALSE
      )
    )
  }
}
