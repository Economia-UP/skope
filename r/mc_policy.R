rm(list=ls())

library("siebanxicor")
library(dplyr)
library(purrr)
library(tidyr)

# Define your INEGI API key
setToken("86d02771fd6b64ce29912469f70d872cf666627201a5d7e819a82c452ae61289")

# Fetch the data using the specified series IDs
idSeries <- c("SF61745", "SP30578", "SR14194") 

# Get the data
series <- getSeriesData(idSeries, '2010-01-01')
ref <- getSerieDataFrame(series, "SF61745")
inf <- getSerieDataFrame(series, "SP30578")
exp <- getSerieDataFrame(series, "SR14194")

series.df <- reduce(list(ref, inf, exp), full_join, by = "date")

colnames(series.df)[2:4] <- c("Tasa objetivo", "Inflación", "Inflación esperada")

# Ordena por fecha
series.df <- series.df %>%
  arrange(date)

# Rellena hacia abajo con el valor previo y hacia arriba con el siguiente (nearest neighbor)
series.df <- series.df %>%
  complete(date = seq(min(date), max(date), by = "1 day")) %>% # Asegura una secuencia completa de fechas
  group_by() %>% # Elimina cualquier agrupamiento previo
  fill(`Tasa objetivo`, `Inflación`, `Inflación esperada`, .direction = "downup") # Usa valores previos y siguientes para rellenar

# Filtra las fechas deseadas
series.df <- series.df %>%
  filter(date >= "2020-01-01")

# Calcula las tasas reales ex-ante y ex-post
series.df <- series.df %>%
  mutate(
    `Tasa real ex-ante` = (1 + `Tasa objetivo`) / (1 + `Inflación esperada`),
    `Tasa real ex-post` = (1 + `Tasa objetivo`) / (1 + `Inflación`)
  )

# Specify the output directory and file name
write.csv(series.df, "data/mc_policy.csv", row.names = FALSE)
