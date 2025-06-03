library(hrbrthemes)
library(showtext)
library(ggplot2)

skope_load_fonts <- function() {
  font_add_google("Rubik", "Rubik")
  showtext_auto()
}

theme_skope <- function(grid = "Y") {
  theme_ipsum_rc(grid = grid, base_family = "Rubik") +
    theme(legend.position = "bottom")
}
