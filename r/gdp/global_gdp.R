print("global_gdp.R")
rm(list = ls())

library(tidyverse)
library(rsdmx)
library(hrbrthemes)
library(showtext)
library(plotly)
library(htmlwidgets)


font_add_google("Roboto Condensed", "Roboto")
showtext_auto()

url <- "https://sdmx.oecd.org/public/rest/data/OECD.SDD.NAD,DSD_NAMAIN1@DF_QNA_EXPENDITURE_GROWTH_OECD,/A..IND+CHN+BRA+ARG+TUR+AUS+CAN+CHL+COL+DEU+ESP+FRA+GBR+GRC+ITA+JPN+KOR+MEX+USA...B1GQ......GY.?startPeriod=2020"
growth <- readSDMX(url) %>% 
  as.data.frame()

# Check data
head(growth)
names(growth)

# Clean data
growth_clean <- growth %>% 
  reframe(obsTime, REF_AREA, obsValue) %>% 
  arrange(desc(obsTime), REF_AREA) %>% 
  mutate(fill_color = ifelse(REF_AREA == "MEX", "#931336", "grey"))

# Note! Data will be updated on February 20, 2025

# Create graph
ggplot(growth_clean %>% 
         # Filtering dataframe
         filter(obsTime == max(obsTime),
                REF_AREA %in% c("ARG", "BRA", "CAN", "CHL", "CHN", "COL", "ESP", "FRA", "GBR", "IND", "ITA", "JPN", "KOR", "MEX", "USA")) %>% 
         arrange(desc(obsValue)),  # Arrange in descending order
       # Continue ggplot
       aes(obsValue/100, reorder(REF_AREA, obsValue), fill = fill_color)) +  # Reorder with negative obsValue
  geom_col(position = "dodge") + 
  # Labels
  labs(
    title = paste("Crecimiento económico por país", max(growth_clean$obsTime)),
    subtitle = "",
    y = "",
    x = "",
    fill = "",
    caption = paste("Fuente: OECD. Última actualización", format(Sys.time(), '%d %b, %Y'))
  ) +
  scale_x_percent(breaks = seq(min(growth_clean$obsValue)/100, max(growth_clean$obsValue)/100, by = 1/100)) +
  scale_fill_identity() +
  theme_ipsum_rc(grid = "Y") +
  theme(
    legend.position = "none"
  )


ggsave("plots/gdp/oecd_gdp_growth.png", width = 1200, height = 900, units = "px", dpi = 300, create.dir = TRUE)


# Necessary for interactive plots iframe
ggplotly(tooltip = "none") %>%
  # Recover caption
  layout(annotations = list(
      x = 1,  # Horizontal position (centered)
      y = -0.2, # Vertical position (below the plot)
      text = paste("Fuente: OECD. Última actualización", format(Sys.time(), '%d %b, %Y')),  # The caption text
      showarrow = FALSE,  # No arrow pointing to the caption
      xref = 'paper',  # Use paper coordinates (relative to the plot's paper size)
      yref = 'paper'   # Use paper coordinates for the caption position
    )) %>% 
  config(displayModeBar = FALSE) %>% 
  saveWidget(file = "plots/gdp/oecd_gdp_growth.html", selfcontained = TRUE)



