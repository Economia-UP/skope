print("weights.R")
rm(list = ls())

# Load the necessary libraries
library(inegiR)
library(tidyverse)

# Define your INEGI API key
inegi.api = Sys.getenv("INEGI_API")

# Load dfs
weights <- read.csv("r/inflation/weights.csv") %>% 
  reframe(Concept, Weight = Weight/100)

# Fetch the data using the specified series IDs
idSeries <- c("910401", "910402", "910404", "910405")

# Get the data
series <- inegi_series_multiple(series = idSeries, token = inegi.api)


# Transform the data
series.wide <- series %>%
  select(date, values, meta_indicatorid) %>%  
  pivot_wider(names_from = meta_indicatorid, values_from = values) %>%
  rename(
    date = date,
    'Mercancías' = '910401',
    'Servicios' = '910402',
    'Agropecuarios' = '910404',
    'Energéticos y tarifas autorizadas por el gobierno' = '910405')


series.incidence <- series.wide %>% 
  mutate(
    "Mercancías" = Mercancías*weights$Weight[weights$Concept == "Mercancías"],
    "Servicios" = Servicios*weights$Weight[weights$Concept == "Servicios"],
    "Agropecuarios" = Agropecuarios*weights$Weight[weights$Concept == "Agropecuarios"],
    "Energéticos y tarifas autorizadas por el gobierno" = `Energéticos y tarifas autorizadas por el gobierno`*weights$Weight[weights$Concept == "Energéticos y tarifas autorizadas por el gobierno "]
      ) %>% 
  filter(date >= Sys.Date() - years(1))

# Specify the output directory and file name
write.csv(series.incidence, "data/inflation/weights.csv", row.names = FALSE)
