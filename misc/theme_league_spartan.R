# Save this script as 'theme_league_spartan.R'

# Required Libraries
library(ggplot2)
library(hrbrthemes)
library(showtext)
library(sysfonts)

# Load League Spartan Font
font_add_google("League Spartan", "league_spartan")
showtext_auto()

# Custom Theme Function
theme_league_spartan <- function(base_size = 12, base_family = "league_spartan") {
  theme_ipsum(base_size = base_size, base_family = base_family) +
    theme(
      plot.title = element_text(face = "bold", size = base_size * 1.5),
      plot.subtitle = element_text(size = base_size * 0.9),
      legend.position = "bottom"
    )
  }

