rm(list = ls())

# Load the necessary libraries
library(inegiR)
library(dplyr)
library(tidyr)

# Define your INEGI API key
inegi.api = '446548c3-7b55-4b22-8430-ac8f251ea555'

# Load dfs
weights <- read.csv("R/weights.csv") %>% 
  reframe(Concept, Weight = Weight/100)

# Fetch the data using the specified series IDs
idSeries <- c("910401", "910402", "910404", "910405")

# Get the data
series <- inegi_series_multiple(series = idSeries, token = inegi.api)


# Transform the data
series.wide <- series %>%
  select(date, values, meta_indicatorid) %>%  
  pivot_wider(names_from = meta_indicatorid, values_from = values) %>%
  rename(
    date = date,
    'Mercancías' = '910401',
    'Servicios' = '910402',
    'Agropecuarios' = '910404',
    'Energéticos y tarifas autorizadas por el gobierno' = '910405')


series.incidence <- series.wide %>% 
  mutate(
    "Mercancías" = Mercancías*weights$Weight[weights$Concept == "Mercancías"],
    "Servicios" = Servicios*weights$Weight[weights$Concept == "Servicios"],
    "Agropecuarios" = Agropecuarios*weights$Weight[weights$Concept == "Agropecuarios"],
    "Energéticos y tarifas autorizadas por el gobierno" = `Energéticos y tarifas autorizadas por el gobierno`*weights$Weight[weights$Concept == "Energéticos y tarifas autorizadas por el gobierno "]
      )

# Specify the output directory and file name
output_dir <- "MX"
output_file <- file.path(output_dir, "mc_inflation_weights.csv")

# Ensure the output directory exists
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
}

# Write the combined data to a CSV file
write.csv(series.incidence, output_file, row.names = FALSE)

cat("Data successfully written to", output_file)