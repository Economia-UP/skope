rm(list=ls())

library("siebanxicor")
library(dplyr)
library(purrr)
library(tidyr)

# Define your INEGI API key
setToken("86d02771fd6b64ce29912469f70d872cf666627201a5d7e819a82c452ae61289")

# Fetch the data using the specified series IDs
idSeries <- c("SR14202", "SR14203","SR14204") 

# Get the data
series <- getSeriesData(idSeries)
med <- getSerieDataFrame(series, "SR14202")
first <- getSerieDataFrame(series, "SR14203")
third <- getSerieDataFrame(series, "SR14204")

series.df <- reduce(list(first, med, third), full_join, by = "date") %>% 
  filter(date >= "2024-01-01")
colnames(series.df)[2:4] <- c("Primer cuartil", "Mediana", "Tercer cuartil")

# Specify the output directory and file name
(write.csv(series.df, "data/mc_expectedinflation_sub.csv", row.names = FALSE))
