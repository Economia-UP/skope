print("gdp.R")
rm(list = ls())

# Load the necessary libraries
library(inegiR)
library(tidyverse)
library(ggpattern)
library(hrbrthemes)
library(showtext)
library(svglite)

font_add_google("Roboto Condensed", "Roboto")
showtext_auto()

# Define your INEGI API key
inegi.api = Sys.getenv("INEGI_API")

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

sexenios_gdp <- gdp %>%
  group_by(sexenio) %>%
  reframe(mean_growth = mean(values, na.rm = TRUE)) %>% 
  filter(!is.na(sexenio)) %>% 
  arrange(sexenio)

# Fetch the data using the specified series IDs
gdp <- inegi_series(series = "736181", token = inegi.api) %>% 
  # group_by(date_shortcut) %>%
  # arrange(date) %>% 
  # mutate(growth  = (values/lag(values) - 1)*100) %>% 
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
         sexenio = factor(sexenio, levels = orden_sexenios), # Ordenar como factor
  ) 

pop <- inegi_series_multiple(series = "289242", token = inegi.api) %>% 
  select(date, date_shortcut, values)

gdppc <- left_join(gdp, pop, join_by(date), suffix = c("_gdp", "_pop")) %>% 
  reframe(date, date_shortcut = date_shortcut_gdp, gdppc = values_gdp/values_pop*1000000, sexenio) %>% 
  filter(gdppc != 0)


sexenios_gdppc <- gdppc %>%
  group_by(sexenio) %>%
  reframe(mean_gdppc = mean(gdppc, na.rm = TRUE)) %>% 
  filter(!is.na(sexenio)) %>% 
  arrange(sexenio)




# Crecimiento económico per cápita
ggplot(sexenios_gdppc, aes(mean_gdppc, fct_rev(sexenio))) +
  geom_col(fill = "#970639") +
  labs( title = "PIB per cápita en México \npromedio por sexenio",
        subtitle = "Moneda nacional",
        y = "",
        x = "",
        caption = "Fuente: INEGI") +
  scale_x_comma() +
  theme_ipsum_rc(grid="Y") %>%
  gg_check()
ggsave("plots/gdp/gdppc_sexenio.png",  width = 1200, height = 900, units = "px", dpi = 300, create.dir = TRUE)

