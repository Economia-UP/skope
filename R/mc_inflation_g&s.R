rm(list = ls())

# Load the necessary libraries
library(inegiR)
library(dplyr)
library(tidyr)

# Define your INEGI API key
inegi.api = '446548c3-7b55-4b22-8430-ac8f251ea555'

# Load dfs
weights <- read.csv("R/weights_g&s.csv") %>% 
  reframe(Concept, Weight = Weight/100)

# Fetch the data using the specified series IDs
idSeries <- c("910392")  

# Get the data
series <- inegi_series_multiple(series = idSeries, token = inegi.api)

series.incidence <- series %>% 
  select(date, values) %>%  
  rename(
    date = date,
    'INPC' = values) %>% 
  mutate(
    "Mercancías no alimenticias" = pi*weights$Weight[weights$Concept == "Mercancías no alimenticias"],
    "Otros servicios" = pi*weights$Weight[weights$Concept == "Otros servicios"],
  )

# Specify the output directory and file name
output_dir <- "MX"
output_file <- file.path(output_dir, "mc_inflation_g&s.csv")

# Ensure the output directory exists
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
}

# Write the combined data to a CSV file
write.csv(series.incidence, output_file, row.names = FALSE)

cat("Data successfully written to", output_file)