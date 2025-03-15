# Limpiar el entorno
rm(list = ls())

# Cargar librerías
library(ggplot2)
library(quantmod)
library(tidyr)
library(PerformanceAnalytics)
library(fPortfolio)
library(zoo)
library(xts)
library(quadprog)
library(scales)
library(timetk)
library(tibbletime)
library(tidyquant)
library(timeSeries)

# Definir tickers
tickers <- c(
  "TLT",      # U.S. 20+ Year Treasury Bond ETF
  # "BUNL",     # German Bunds ETF
  # "JGBS",     # Japanese Government Bonds ETF
  "XBB.TO",   # Canadian Government Bonds ETF
  # "BOND.AX",  # Australian Government Bonds ETF
  # "BZF",      # Brazilian Government Bonds ETF
  # "CNYB",   # Chinese Government Bonds ETF
  # "INDA",     # Indian Bonds ETF (Exposure via MSCI)
  # "ZAR",      # South African Bonds ETF
  "EWW"      # Mexican Bonds ETF
  # "TUR"       # Turkish Bonds ETF
)

# Descargar datos ajustados de Yahoo Finance con manejo de errores
data_list <- lapply(tickers, function(ticker) {
    # Descargar datos sin asignar automáticamente
    x <- getSymbols(ticker, from = "1990-01-01", to = Sys.Date(), auto.assign = FALSE)
    # Extraer la columna ajustada
    data <- Ad(x)
})

# Combinar todos los datos en un objeto xts
df <- do.call(merge, data_list)
names(df) <- sub(".Adjusted", "", names(df))

returns <- do.call(merge, lapply(df, dailyReturn))
names(returns) <- names(df)
returns <- na.locf(returns, na.rm = T)


# Rolling coefficients
rolling_VaR <- rollapply(
  data = returns, 
  width = 252*1,  # Fixed window size (e.g., 1260 days ~ 5 years)
  FUN = function(window_data) {
  
  # Create Portfolio object which is essentially a list object
  min_var_portfolio <- minvariancePortfolio(as.timeSeries(window_data), spec = portfolioSpec())
  VaR_value <- getPortfolio(min_var_portfolio)$targetRisk['VaR'] # or VaR&Sigma
  print(VaR_value)
  return(VaR_value)  # Return the calculated VaR or NA in case of error
}, 
  by.column = FALSE,  # Apply to the entire portfolio
  align = "right"  # Align with the most recent date
)

rolling_VaR_df <- data.frame(
  Date = index(rolling_VaR),
  VaR = coredata(rolling_VaR)
)

ggplot(na.omit(rolling_VaR_df), aes(Date, VaR)) +
  geom_line(linewidth = 1) +
  labs(
    title = "VaR volatility index",
    y = "",
    x = ""
  ) +
  scale_y_continuous(breaks = scales::breaks_pretty(), labels = scales::label_percent()) +
  scale_x_date(breaks = scales::date_breaks("1 year"), labels = scales::date_format("%Y")) +
  theme_gray()
