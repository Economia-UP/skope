rm(list=ls())

library("siebanxicor")
library(dplyr)
library(purrr)
library(tidyr)

# Define your INEGI API key
setToken("86d02771fd6b64ce29912469f70d872cf666627201a5d7e819a82c452ae61289")

# Fetch the data using the specified series IDs
idSeries <- c("SF61745", "SP30578","SR14194") 

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

# Rellena hacia abajo y luego interpola los valores faltantes
series.df <- series.df %>%
  complete(date = seq(min(date), max(date), by = "1 day")) %>% # Asegura una secuencia completa de fechas
  group_by() %>% # Elimina cualquier agrupamiento previo
  mutate(
    `Tasa objetivo` = na.approx(`Tasa objetivo`, na.rm = FALSE, rule = 2),
    `Inflación` = na.approx(`Inflación`, na.rm = FALSE, rule = 2),
    `Inflación esperada` = na.approx(`Inflación esperada`, na.rm = FALSE, rule = 2)
  )

# Filtra las fechas deseadas
series.df <- series.df %>%
  filter(date >= "2020-01-01")


series.df$"Tasa real ex-ante" = series.df$"Tasa objetivo" - series.df$"Inflación esperada"
series.df$"Tasa real ex-post" = series.df$"Tasa objetivo" - series.df$"Inflación"

# Specify the output directory and file name
write.csv(series.df, "data/mc_policy.csv", row.names = FALSE)
