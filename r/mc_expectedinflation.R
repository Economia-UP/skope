rm(list=ls())

library("siebanxicor")
library(dplyr)
library(purrr)
library(tidyr)
library(lubridate)

# Define your INEGI API key
setToken(Sys.getenv("BANXICO_API"))

# Fetch the data using the specified series IDs
idSeries <- c("SR14195", "SR14196","SR14197") 

# Get the data
series <- getSeriesData(idSeries)
med <- getSerieDataFrame(series, "SR14195")
first <- getSerieDataFrame(series, "SR14196")
third <- getSerieDataFrame(series, "SR14197")

series.df <- reduce(list(first, med, third), full_join, by = "date") %>% 
  filter(date >= Sys.Date() - years(1))
colnames(series.df)[2:4] <- c("Primer cuartil", "Mediana", "Tercer cuartil")

# Specify the output directory and file name
write.csv(series.df, "data/mc_expectedinflation.csv", row.names = FALSE)
