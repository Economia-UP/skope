# Load the necessary libraries
library(inegiR)
library(dplyr)
library(readr)

# Define your INEGI API key
Sys.setenv(INEGI_API_KEY = "your_api_key_here")  # Set your API key

INEGI_API_KEY = '446548c3-7b55-4b22-8430-ac8f251ea555'

# Fetch the data using the specified series IDs
series_ids <- c("910406", "910407", "910410")  # Your INEGI series IDs

# Get the data
df <- inegi_series_multiple(series = series_ids, token = INEGI_API_KEY)

# Transform the data
df_transformed <- df %>%
  select(date, values, meta_indicatorid) %>%  # Select relevant columns
  pivot_wider(names_from = meta_indicatorid, values_from = values) %>%  # Pivot the data
  rename(
    date = date,
    'Inflación general' = '910406',  # Rename based on your specific series IDs
    'Subyacente' = '910407',
    'No subyacente' = '910410'
  )

# Specify the output directory and file name
output_dir <- "MX"
output_file <- file.path(output_dir, "mc_inflation.csv")

# Ensure the output directory exists
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
}

# Write the combined data to a CSV file
write_csv(combined_data, output_file)

cat("Data successfully written to", output_file)
