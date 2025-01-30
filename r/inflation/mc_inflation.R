print("inflation.R")
rm(list = ls())

# Load the necessary libraries
library(inegiR)
library(dplyr)
library(tidyr)
library(ggplot2)
library(hrbrthemes)
library(forcats)
library(lubridate)
library(sysfonts)

font_add_google("Roboto Condensed")
import_roboto_condensed()

# Define your INEGI API key
inegi.api = Sys.getenv("INEGI_API")

# Fetch the data using the specified series IDs
idSeries <- c("910406", "910407", "910410")  # Your INEGI series IDs

# Get the data
series <- inegi_series_multiple(series = idSeries, token = inegi.api)

# Transform the data
series.wide <- series %>%
  select(date, values, meta_indicatorid) %>%  
  pivot_wider(names_from = meta_indicatorid, values_from = values) %>%
  rename(
    date = date,
    'Inflación general' = '910406',
    'Subyacente' = '910407',
    'No subyacente' = '910410') %>% 
  filter(date >= Sys.Date() - years(3))

series.long <- pivot_longer(series.wide,
                            cols = c("Inflación general", "Subyacente", "No subyacente"),
                            names_to = "index",
                            values_to = "values")

ggplot(series.long, aes(date, values/100, color = index)) +
  geom_line(size = 1) +
  labs( title = "Crecimiento económico en México",
        subtitle = "Variación anual",
        y = "",
        x = "",
        caption = "Fuente: INEGI",
        color = "") +
  scale_y_percent() +
  theme_ipsum_rc(grid="Y") +
  scale_fill_flexoki_light() +
  theme(legend.position = "bottom") %>% 
  gg_check()
ggsave("plots/gdp_growth.png")

# Specify the output directory and file name
write.csv(series.wide, "data/mc_inflation.csv", row.names = FALSE)