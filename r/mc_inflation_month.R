rm(list = ls())

# Load the necessary libraries
library(inegiR)
library(dplyr)
library(tidyr)
library(lubridate)

# Define your INEGI API key
inegi.api = Sys.getenv("INEGI_API")

# Fetch the data using the specified series IDs
idSeries <- c("910399", "910400", "910403")  # Your INEGI series IDs

# Get the data
series <- inegi_series_multiple(series = idSeries, token = inegi.api)

# Transform the data
series.wide <- series %>%
  select(date, values, meta_indicatorid) %>%  
  pivot_wider(names_from = meta_indicatorid, values_from = values) %>%
  rename(
    date = date,
    'Inflación general' = '910399',
    'Subyacente' = '910400',
    'No subyacente' = '910403') %>% 
  filter(date >= Sys.Date() - years(3))

# Specify the output directory and file name
write.csv(series.wide, "data/mc_inflation_month.csv", row.names = FALSE)
