print("mc_mxnusd.R")
rm(list=ls())

library("siebanxicor")
library(dplyr)
library(tidyr)
library(lubridate)

# Define your INEGI API key
setToken(Sys.getenv("BANXICO_API"))

# Fetch the data using the specified series IDs
idSeries <- c("SF63528")
series <- getSeriesData(idSeries)

# Get the data
fx <- getSerieDataFrame(series, "SF63528")

month <- fx %>% 
  filter(date >= Sys.Date() - months(3))

five_years <- fx %>% 
  filter(date >= Sys.Date() - years(5))

write.csv(month, "data/mc_mxnusd_month.csv", row.names = FALSE)
write.csv(five_years, "data/mc_mxnusd_5y.csv", row.names = FALSE)
