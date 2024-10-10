# Load necessary libraries
library(httr)
library(jsonlite)
library(dplyr)
library(tidyr)
library(lubridate)
library(readr)

# Retrieve the INEGI API key from environment variables
INEGI_API_KEY <- Sys.getenv("INEGI_API_KEY")
SERIES_ID <- "910406,910407,910410"  # Your INEGI series ID
INEGI_URL <- paste0("https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/INDICATOR/",
                    SERIES_ID, "/es/0700/false/BIE/2.0/", INEGI_API_KEY, "?type=json")

# Fetch data from the INEGI API
response <- GET(INEGI_URL)
if (status_code(response) != 200) {
  stop("Error fetching data from INEGI API")
}

# Parse the response as JSON
data <- content(response, as = "text")
data_json <- fromJSON(data)

# Extract observations
observations <- data_json$Series
if (length(observations) == 0) {
  stop(paste("No observations found for series ID", SERIES_ID))
}

# Create a list to store DataFrames for each indicator
df_list <- list()

# Process each set of observations
for (obs in observations) {
  indicator <- obs$INDICADOR
  df <- obs$OBSERVATIONS %>%
    as.data.frame() %>%
    select(TIME_PERIOD, OBS_VALUE)
  
  # Ensure TIME_PERIOD is in datetime format and OBS_VALUE is numeric
  df <- df %>%
    mutate(TIME_PERIOD = ymd(TIME_PERIOD),
           !!indicator := as.numeric(OBS_VALUE)) %>%
    select(-OBS_VALUE)
  
  df_list[[indicator]] <- df  # Store each DataFrame in the list
}

# Sequentially merge all DataFrames by TIME_PERIOD using an outer join
merged_df <- reduce(df_list, full_join, by = "TIME_PERIOD")

# Rename columns to meaningful names
colnames(merged_df) <- c("TIME_PERIOD", "Inflación general", "Subyacente", "No subyacente")

# Filter data since 2018
merged_df <- merged_df %>%
  filter(TIME_PERIOD >= as.Date("2018-01-01"))

# Define the output directory and ensure it exists
output_dir <- "MX"
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
}

# Save the merged DataFrame to a CSV file in the specified folder
output_file <- file.path(output_dir, "mc_inflation.csv")
write_csv(merged_df, output_file)

message("Data successfully written to ", output_file)
