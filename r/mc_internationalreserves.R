print("mc_internationalreserves.R")
rm(list=ls())

library("siebanxicor")
library(dplyr)
library(purrr)
library(tidyr)
library(lubridate)

# Define your BANXICO API key
setToken(Sys.getenv("BANXICO_API"))

# Fetch the data using the specified series IDs
idSeries <- c("SF29656", "SF29654", "SF63528") 

startDate = format(Sys.Date() - years(5), "%Y-%m-%d")
endDate = format(Sys.Date(), "%Y-%m-%d")


# Get the data
series <- getSeriesData(idSeries, startDate = startDate, endDate = endDate)
reserves <- getSerieDataFrame(series, "SF29656")
asset <- getSerieDataFrame(series, "SF29654")
fx <-  getSerieDataFrame(series, "SF63528")

series.df <- reduce(list(reserves, asset), full_join, by = "date")
colnames(series.df) <- c("date", "Reserva internacional", "Activo internacional total")

# series.long <- pivot_longer(series.df, cols = c("Reserva internacional", "Activo internacional total"), 
#                             names_to = "Index", values_to = "Values")

# Specify the output directory and file name
write.csv(reserves, "data/mc_internationalreserves.csv", row.names = FALSE)
write.csv(series.df, "data/mc_reserves&assets.csv", row.names = FALSE)
