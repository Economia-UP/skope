print("gdppc_sexenios.R")
rm(list = ls())

# Load the necessary libraries
library(inegiR)
library(tidyverse)
library(ggpattern)
library(hrbrthemes)
library(showtext)
library(svglite)
library(scales)

source("r/theme_skope.R")
skope_load_fonts()

# Define your INEGI API key
inegi.api = Sys.getenv("INEGI_API")


orden_sexenios <- c(
  "MMH \n(1982-1988)",
  "CSG \n(1988-1994)",
  "EZPL \n(1994-2000)",
  "VFQ \n(2000-2006)",
  "FCH \n(2006-2012)",
  "EPN \n(2012-2018)",
  "AMLO \n(2018-2024)",
  "CSP \n(2024-2030)"
)

# Fetch the data using the specified series IDs
gdp <- inegi_series(series = "736181", token = inegi.api) %>% 
  # group_by(date_shortcut) %>%
  # arrange(date) %>% 
  # mutate(growth  = (values/lag(values) - 1)*100) %>% 
  mutate(year = year(date),  # Extrae el año de la fecha
         sexenio = case_when(
           year > 1982 & year <= 1988 ~ "MMH \n(1982-1988)",
           year > 1988 & year <= 1994 ~ "CSG \n(1988-1994)",
           year > 1994 & year <= 2000 ~ "EZPL \n(1994-2000)",
           year > 2000 & year <= 2006 ~ "VFQ \n(2000-2006)",
           year > 2006 & year <= 2012 ~ "FCH \n(2006-2012)",
           year > 2012 & year <= 2018 ~ "EPN \n(2012-2018)",
           year > 2018 & year <= 2024 ~ "AMLO \n(2018-2024)",
           year > 2024 & year <= 2030 ~ "CSP \n(2024-2030)",
           TRUE ~ "Otro"
         ),
         sexenio = factor(sexenio, levels = orden_sexenios), # Ordenar como factor
  ) 

sexenios_gdp <- gdp %>%
  group_by(sexenio) %>%
  reframe(mean_growth = mean(values, na.rm = TRUE)) %>% 
  filter(!is.na(sexenio)) %>% 
  arrange(sexenio)

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
ggplot(sexenios_gdppc, aes(sexenio, mean_gdppc)) +
  geom_col(fill = "#970639") +
  labs( title = "PIB per cápita en México promedio por sexenio",
        subtitle = "Moneda nacional (MXN)",
        y = "",
        x = "",
        caption = "Fuente: INEGI") +
  coord_cartesian(ylim = c(170000, 195000)) +  # Set the visible y-axis limits here
  scale_y_continuous(labels = scales::label_comma()) +
  theme_ipsum_rc(grid = "Y", base_family = "Rubik")
  
ggsave("plots/gdp/gdppc_sexenio.svg",  width = 8, height = 6, create.dir = TRUE)

