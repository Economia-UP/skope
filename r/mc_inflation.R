rm(list = ls())

# Load the necessary libraries
library(inegiR)
library(dplyr)
library(tidyr)

# Define your INEGI API key
inegi.api = '446548c3-7b55-4b22-8430-ac8f251ea555'

# Fetch the data using the specified series IDs
idSeries <- c("910406", "910407", "910410")  # Your INEGI series IDs

# Get the data
series <- inegi_series_multiple(series = idSeries, token = inegi.api)

# Transform the data
series.wide <- series %>%
  select(date, values, meta_indicatorid) %>%  
  pivot_wider(names_from = meta_indicatorid, values_from = values) %>%
  rename(
    date = date,
    'Inflación general' = '910406',
    'Subyacente' = '910407',
    'No subyacente' = '910410') %>% 
  filter(date >= '2020-01-01')

# Specify the output directory and file name
output_dir <- "data"
output_file <- file.path(output_dir, "mc_inflation.csv")

# Ensure the output directory exists
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
}

# Write the combined data to a CSV file
write.csv(series.wide, output_file, row.names = FALSE)

cat("Data successfully written to", output_file)
