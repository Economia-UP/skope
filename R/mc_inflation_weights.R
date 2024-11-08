rm(list = ls())

# Load the necessary libraries
library(inegiR)
library(dplyr)
library(tidyr)

# setwd("C:/Users/ediaz/OneDrive - up.edu.mx/GitHub/skope/R/")

# Define your INEGI API key
inegi.api = '446548c3-7b55-4b22-8430-ac8f251ea555'

# Load dfs
weights <- read.csv("R/weights.csv") %>% 
  reframe(Concept, Weight = Weight/100)

# Fetch the data using the specified series IDs
idSeries <- c("910406")  

# Get the data
series <- inegi_series_multiple(series = idSeries, token = inegi.api)

series.incidence <- series %>% 
  select(date, values) %>%  
  rename(
    date = date,
    'pi' = values) %>% 
  mutate(
    "Alimentos, bebidas y tabaco" = pi*weights$Weight[weights$Concept == "Alimentos, bebidas y tabaco"],
    "Ropa, calzado y accesorios" = pi*weights$Weight[weights$Concept == "Ropa, calzado y accesorios"],
    "Vivienda" = pi*weights$Weight[weights$Concept == "Vivienda"],
    "Muebles, aparatos y accesorios domésticos" = pi*weights$Weight[weights$Concept == "Muebles, aparatos y accesorios domésticos"],
    "Salud y cuidado personal" = pi*weights$Weight[weights$Concept == "Salud y cuidado personal"],
    "Transporte" = pi*weights$Weight[weights$Concept == "Transporte"],
    "Educación y esparcimiento" = pi*weights$Weight[weights$Concept == "Educación y esparcimiento"],
    "Otros servicios" = pi*weights$Weight[weights$Concept == "Otros servicios"]
      )

# Specify the output directory and file name
output_dir <- "MX"
output_file <- file.path(output_dir, "mc_inflation_weights.csv")

# Ensure the output directory exists
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
}

# Write the combined data to a CSV file
write.csv(series.wide, output_file, row.names = FALSE)

cat("Data successfully written to", output_file)