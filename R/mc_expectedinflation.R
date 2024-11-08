rm(list=ls())

library("siebanxicor")
library(dplyr)
library(purrr)
library(tidyr)

# Define your INEGI API key
setToken("86d02771fd6b64ce29912469f70d872cf666627201a5d7e819a82c452ae61289")

# Fetch the data using the specified series IDs
idSeries <- c("SR14195", "SR14196","SR14197") 

# Get the data
series <- getSeriesData(idSeries)
med <- getSerieDataFrame(series, "SR14195")
first <- getSerieDataFrame(series, "SR14196")
third <- getSerieDataFrame(series, "SR14197")

series.df <- reduce(list(first, med, third), full_join, by = "date")
colnames(series.df)[2:4] <- c("Primer cuartil", "Mediana", "Tercer cuartil")

# Specify the output directory and file name
output_dir <- "MX"
output_file <- file.path(output_dir, "mc_expectedinflation.csv")
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
}
write.csv(series.df, output_file, row.names = FALSE)
cat("Data successfully written to", output_file)
