print("growth.R")
rm(list = ls())

# Load the necessary libraries
library(inegiR)
library(dplyr)
library(tidyr)
library(ggplot2)
library(hrbrthemes)
library(forcats)
library(lubridate)
library(sysfonts)

font_add_google("Roboto Condensed")
import_roboto_condensed()

# Define your INEGI API key
# inegi.api = Sys.getenv("INEGI_API")
inegi.api <- "446548c3-7b55-4b22-8430-ac8f251ea555"

# Fetch the data using the specified series IDs
# idSeries <- c("910399", "910400", "910403")  # Your INEGI series IDs

gdp <- inegi_series(series = "736181", token = inegi.api)

orden_sexenios <- c(
  "Miguel de la Madrid (1982-1988)",
  "Carlos Salinas (1988-1994)",
  "Ernesto Zedillo (1994-2000)",
  "Vicente Fox (2000-2006)",
  "Felipe Calderón (2006-2012)",
  "Enrique Peña Nieto (2012-2018)",
  "Andrés Manuel López Obrador (2018-2024)",
  "Claudia Sheinbaum Pardo (2024-2030)"
)

gdp <- gdp %>% 
  group_by(date_shortcut) %>%
  arrange(date) %>% 
  mutate(growth  = (values/lag(values) - 1)*100) %>% 
  mutate(year = year(date),  # Extrae el año de la fecha
         sexenio = case_when(
           year > 1982 & year <= 1988 ~ "Miguel de la Madrid (1982-1988)",
           year > 1988 & year <= 1994 ~ "Carlos Salinas (1988-1994)",
           year > 1994 & year <= 2000 ~ "Ernesto Zedillo (1994-2000)",
           year > 2000 & year <= 2006 ~ "Vicente Fox (2000-2006)",
           year > 2006 & year <= 2012 ~ "Felipe Calderón (2006-2012)",
           year > 2012 & year <= 2018 ~ "Enrique Peña Nieto (2012-2018)",
           year > 2018 & year <= 2024 ~ "Andrés Manuel López Obrador (2018-2024)",
           year > 2024 & year <= 2030 ~ "Claudia Sheinbaum Pardo (2024-2030)",
           TRUE ~ "Otro"
         ),
         sexenio = factor(sexenio, levels = orden_sexenios) # Ordenar como factor
  )

sexenios_gdp <- gdp %>%
  group_by(sexenio) %>%
  reframe(mean_growth = mean(growth, na.rm = TRUE)) %>% 
  filter(!is.na(sexenio)) %>% 
  arrange(sexenio)

# Crecimiento económico
gdp %>% 
  filter(date >= "2022-01-01") %>% 
ggplot(aes(date, growth/100)) +
  geom_line(size = 1, color = "#970639") +
  labs( title = "Crecimiento económico en México",
        subtitle = "Variación anual",
        y = "",
        x = "",
        caption = "Fuente: INEGI") +
  scale_y_percent() +
  theme_ipsum_rc(grid="Y") %>% 
  gg_check()
ggsave("plots/gdp_growth.png")


# Crecimiento promedio por sexenio
ggplot(sexenios_gdp, aes(mean_growth/100, fct_rev(sexenio))) +
  geom_col(fill = "#970639") +
  labs( title = "Crecimiento promedio por sexenio",
        subtitle = "Promedio del crecimiento anual en México",
        y = "",
        x = "",
        caption = "Fuente: INEGI") +
  scale_x_percent() +
  theme_ipsum_rc(grid="X") %>% 
  gg_check()
ggsave("plots/sexenios.png")


pop <- inegi_series_multiple(series = "289242", token = inegi.api) %>% 
  select(date, date_shortcut, values)

gdppc <- left_join(gdp, pop, join_by(date), suffix = c("_gdp", "_pop")) %>% 
  reframe(date, date_shortcut = date_shortcut_gdp, gdppc = values_gdp/values_pop*1000000) %>% 
  filter(gdppc != 0)

# Crecimiento económico per cápita
ggplot(gdppc, aes(date, gdppc)) +
  geom_line(size = 1, color = "#970639") +
  labs( title = "PIB per cápita en México",
        subtitle = "Moneda nacional",
        y = "",
        x = "",
        caption = "Fuente: INEGI") +
  scale_y_comma() +
  theme_ipsum_rc(grid="Y") %>% 
  gg_check()
ggsave("plots/gdppc.png")


write.csv(gdppc, "data/growth/gdppc.csv", row.names = FALSE)
