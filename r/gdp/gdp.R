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

# Estimación oportuna del PIB
eopib <- inegi_series(series = "733855", token = inegi.api)


eopib %>% 
  filter(date >= "2022-01-01") %>% 
  ggplot(aes(date, values/100)) +
  geom_line(data = eopib %>% 
              filter(date >= "2022-01-01") %>% 
              arrange(date) %>% 
              slice(1:(n() - 1)), 
            aes(date, values/100), 
            size = 1, color = "#970639") +
  geom_line(data = eopib %>% 
              filter(date >= "2022-01-01") %>% 
              arrange(desc(date)) %>% 
              slice(1:2), 
            aes(date, values/100), 
            color = "#970639", linetype = "dashed", size = 1) +  
  labs(title = "Crecimiento económico en México*",
       subtitle = "Variación anual",
       y = "",
       x = "",
       caption = "Fuente: INEGI \nDato del último trimestre del 2024 corresponde a la estimación oportuna.*") +
  scale_y_percent() + 
  theme_ipsum_rc(grid = "Y") %>% 
  gg_check()
ggsave("plots/gdp/eopib_growth.png",  width = 1200, height = 800, units = "px", dpi = 150, create.dir = TRUE)


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

gdp <- eopib %>% 
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

growth_annual <- gdp %>% 
  group_by(year) %>% 
  summarize(growth = mean(values), .groups = "drop")


growth_annual %>% 
  filter(year >= 2018) %>% 
  ggplot(aes(year, growth/100)) +
  geom_col(data = growth_annual %>% 
              filter(year >= 2018) %>% 
              arrange(year) %>% 
              slice(1:(n())), 
            aes(year, growth/100), 
            size = 1, fill = "#970639") +
  geom_col_pattern(data = growth_annual %>%
                     filter(year >= 2018) %>%
                     arrange(desc(year)) %>%
                     slice(1),
                   aes(year, growth/100),
                   fill = "#970639",  # Background color
                   pattern = "stripe",  # Striped pattern
                   pattern_color = "#fdfcfd",  # Stripe color
                   pattern_density = 0.2,  # Adjust spacing of stripes
                   pattern_angle = 45,  # Angle of stripes
                   size = 1) +
  labs(title = "Crecimiento económico en México*",
       subtitle = "Variación promedio anual",
       y = "",
       x = "",
       caption = "Fuente: INEGI \nDato del último trimestre del 2024 corresponde a la estimación oportuna.*") +
  scale_x_continuous(breaks = seq(2018, max(growth_annual$year), by = 1)) +
  scale_y_percent(breaks = seq(floor(min(growth_annual$growth / 100)), 
                               ceiling(max(growth_annual$growth / 100)), 
                               by = 0.02)) + 
  # scale_y_percent() + 
  theme_ipsum_rc(grid = "Y") %>%  
  gg_check()
ggsave("plots/gdp/eopib_annual_growth.png",  width = 1200, height = 800, units = "px", dpi = 150, create.dir = TRUE)



sexenios_gdp <- gdp %>%
  group_by(sexenio) %>%
  reframe(mean_growth = mean(values, na.rm = TRUE)) %>% 
  filter(!is.na(sexenio)) %>% 
  arrange(sexenio)


# Crecimiento promedio por sexenio
ggplot(sexenios_gdp, aes(mean_growth/100, fct_rev(sexenio))) +
  geom_col(fill = "#970639") +
  labs( title = "Crecimiento promedio por \nsexenio*",
        subtitle = "Promedio del crecimiento anual en México",
        y = "",
        x = "",
        caption = "Fuente: INEGI\nDato del último trimestre del 2024 corresponde a la estimación oportuna.*") +
  scale_x_percent() +
  theme_ipsum_rc(grid="X", base_family = "roboto_condensed") %>%   # Use Roboto Condensed
  gg_check()
ggsave("plots/gdp/gdp.png",  width = 1200, height = 900, units = "px", dpi = 300, create.dir = TRUE)


# Fetch the data using the specified series IDs
gdp <- inegi_series(series = "736181", token = inegi.api)

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
ggsave("plots/gdp/gdppc.png",  width = 1200, height = 800, units = "px", dpi = 150, create.dir = TRUE)



write.csv(gdppc, "data/growth/gdppc.csv", row.names = FALSE)
write.csv(sexenios_gdp, "data/growth/sexenios_gdp.csv", row.names = FALSE)
