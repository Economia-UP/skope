# Load libraries
library(inegiR)
library(tidyverse)
library(zoo)
library(lmtest)

# Get your INEGI API token (replace with your token)
inegi.api = '446548c3-7b55-4b22-8430-ac8f251ea555'

# Retrieve INPC monthly data from INEGI
inpc_data <- inegi_series("910406", inegi.api)  # Replace "your_series_id" with the correct INPC ID

# Convert date column to Date class and set frequency to quarterly
inpc_data$date <- as.Date(inpc_data$date)
inpc_data <- inpc_data %>%
  mutate(quarter = as.yearqtr(date)) %>%
  group_by(quarter) %>%
  summarize(INPC = mean(values, na.rm = TRUE)) %>%
  ungroup()

# Calculate quarterly inflation rate as the log-difference
inpc_data <- inpc_data %>%
  mutate(inflation = c(NA, diff(log(INPC)) * 100))

# Lagged variables for regression model
inpc_data <- inpc_data %>%
  mutate(lag1 = lag(inflation, 1),
         lag2 = lag(inflation, 2),
         lag3 = lag(inflation, 3),
         lag4 = lag(inflation, 4)) %>%
  drop_na()

# Run regression model
model <- lm(inflation ~ lag1 + lag2 + lag3 + lag4, data = inpc_data)
persistence <- sum(coef(model)[-1])  # Sum of lagged coefficients for persistence

# Display results
summary(model)
cat("Inflation Persistence (sum of lagged coefficients):", persistence)
