# Install necessary packages if not already installed
install.packages("oaxaca")
install.packages("ggplot2")
install.packages("httr")
install.packages("zip")

# Load required libraries
library(oaxaca)
library(ggplot2)
library(dplyr)
library(readr)
library(httr)  # For downloading files
library(zip)   # For extracting ZIP files

# Define the years and quarters to analyze
anio <- 24  # Use last two digits of the year (e.g., 2024 -> 24)
trimestres <- 1:4

# Define destination folder for downloads
carpeta_destino <- "/r/labor/oaxaca/"

# Ensure the destination folder exists
if (!dir.exists(carpeta_destino)) {
  dir.create(carpeta_destino, recursive = TRUE)
}

# Store results
resultados <- data.frame()

# Loop through each quarter
for (trim in trimestres) {
  
  # Construct the ZIP file URL
  url <- paste0("https://www.inegi.org.mx/contenidos/programas/enoe/15ymas/microdatos/enoe_2024_trim", 
                trim, "_csv.zip")
  
  # Define local ZIP file name
  archivo_zip <- paste0(carpeta_destino, "enoe_2024_trim", trim, ".zip")
  
  # Download file using httr::GET
  response <- GET(url, write_disk(archivo_zip, overwrite = TRUE), timeout(300))  # 300s timeout
  
  # Check if the download was successful
  if (http_error(response)) {
    print(paste("Failed to download:", url))
    next
  }
  
  # Extract only the relevant CSV file
  unzip(archivo_zip, exdir = carpeta_destino)
  
  # Search for the correct CSV file (ENOE_SDEMT#YY.csv)
  patron_csv <- paste0("ENOE_SDEMT", trim, anio, ".csv")
  archivo_csv <- list.files(carpeta_destino, pattern = patron_csv, full.names = TRUE)
  
  if (length(archivo_csv) == 0) {
    print(paste("No matching CSV found for:", trim))
    next  # Skip if no relevant file is found
  }
  
  # Load the dataset
  datos <- read_csv(archivo_csv[1])  # Adjust if needed based on structure
  
  # Create necessary variables for analysis
  datos <- datos %>%
    mutate(log_ingocup = log(ingocup), 
           exp = eda - anios_esc - 6, 
           exp2 = exp^2)
  
  # Filter out invalid values
  datos <- datos %>% filter(!is.na(log_ingocup) & !is.na(sex))
  
  # Define Oaxaca-Blinder model
  modelo <- log_ingocup ~ anios_esc + exp + exp2 + seg_soc + rama + pos_ocu
  oaxaca_result <- oaxaca(modelo, data = datos, group = "sex", R = 100)
  
  # Extract estimated wage gap
  wage_gap <- oaxaca_result$overall[3, "estimate"]  # Unexplained wage gap component
  
  # Store results
  resultados <- rbind(resultados, data.frame(Año = 2024, Trimestre = trim, Wage_Gap = wage_gap))
  
  # Print progress
  print(paste("Processed: 2024 Trimestre:", trim))
}

# Plot the wage gap over quarters
ggplot(resultados, aes(x = factor(Trimestre), y = Wage_Gap, group = Año, color = factor(Año))) +
  geom_line(size = 1.2) +
  geom_point(size = 3) +
  labs(title = "Evolución del Wage Gap por Trimestre",
       x = "Trimestre",
       y = "Brecha Salarial (Oaxaca-Blinder)",
       color = "Año") +
  theme_minimal()
