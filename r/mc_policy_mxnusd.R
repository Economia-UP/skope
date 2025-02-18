print("mc_policy_mxnusd.R")
rm(list=ls())

library("siebanxicor")
library(dplyr)
library(purrr)
library(tidyr)
library(lubridate)

# Define your BANXICO API key
setToken(Sys.getenv("BANXICO_API"))

# Fetch the data using the specified series IDs
idSeries <- c("SF61745", "SF63528") 

# Get the data
series <- getSeriesData(idSeries)
ref <- getSerieDataFrame(series, "SF61745")
fx <- getSerieDataFrame(series, "SF63528")

series.df <- reduce(list(ref, fx), full_join, by = "date")

colnames(series.df)[2:3] <- c("Tasa objetivo", "Tipo de cambio")

# Ordena por fecha
series.df <- series.df %>%
  arrange(date)

# Rellena hacia abajo con el valor previo y hacia arriba con el siguiente (nearest neighbor)
series.df <- series.df %>%
  complete(date = seq(min(date), max(date), by = "1 day")) %>% # Asegura una secuencia completa de fechas
  fill(`Tasa objetivo`, `Tipo de cambio`, .direction = "downup") # Usa valores previos y siguientes para rellenar

# Filtra las fechas deseadas
series.df <- series.df %>%
  filter(date >= Sys.Date() - years(3))

write.csv(series.df, "data/mc_policy_mxnusd.csv", row.names = FALSE)
