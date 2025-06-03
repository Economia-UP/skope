print("gdp.R")
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

# Estimación oportuna del PIB
eopib <- inegi_series(series = "733855", token = inegi.api)

# Prepare data for plotting
eopib_line <- eopib %>%
  filter(date >= "2022-01-01") %>%
  mutate(p = values / 100)

eopib_line %>%
  ggplot(aes(date, p)) +
  geom_line(data = eopib %>%
              filter(date >= "2022-01-01") %>%
              arrange(date) %>%
              slice(1:(n() - 1)),
            aes(date, values/100),
            linewidth = 1, color = "#970639") +
  geom_line(data = eopib %>%
              filter(date >= "2022-01-01") %>%
              arrange(desc(date)) %>%
              slice(1:2),
            aes(date, values/100),
            color = "#970639", linetype = "dashed", size = 1) +
  highlight_last(eopib_line, "date", "p", color = "#970639", label_fmt = label_percent(accuracy = 0.1)) +
  labs(title = "Crecimiento económico en México*",
       subtitle = "Variación anual",
       y = "",
       x = "",
       caption = skope_caption("INEGI", max(eopib$date))) +
  scale_y_percent() +
  theme_skope()

ggsave("plots/gdp/eopib_growth.svg",  width = 8, height = 6, create.dir = TRUE)


orden_sexenios <- c(
  "MMH (1982-1988)",
  "CSG (1988-1994)",
  "EZPL (1994-2000)",
  "VFQ (2000-2006)",
  "FCH (2006-2012)",
  "EPN (2012-2018)",
  "AMLO (2018-2024)",
  "CSP (2024-2030)"
)

gdp <- eopib %>% 
  # group_by(date_shortcut) %>%
  # arrange(date) %>% 
  # mutate(growth  = (values/lag(values) - 1)*100) %>% 
  mutate(year = year(date),  # Extrae el año de la fecha
         sexenio = case_when(
           year > 1982 & year <= 1988 ~ "MMH (1982-1988)",
           year > 1988 & year <= 1994 ~ "CSG (1988-1994)",
           year > 1994 & year <= 2000 ~ "EZPL (1994-2000)",
           year > 2000 & year <= 2006 ~ "VFQ (2000-2006)",
           year > 2006 & year <= 2012 ~ "FCH (2006-2012)",
           year > 2012 & year <= 2018 ~ "EPN (2012-2018)",
           year > 2018 & year <= 2024 ~ "AMLO (2018-2024)",
           year > 2024 & year <= 2030 ~ "CSP (2024-2030)",
           TRUE ~ "Otro"
         ),
         sexenio = factor(sexenio, levels = orden_sexenios), # Ordenar como factor
  ) 

growth_annual <- gdp %>% 
  group_by(year) %>% 
  reframe(growth = mean(values), .groups = "drop")


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
       caption = skope_caption("INEGI", max(eopib$date))) +
  scale_x_continuous(breaks = scales::breaks_width(width = 1)) +
  scale_y_percent(breaks = scales::breaks_pretty(8)) +
  theme_skope()
ggsave("plots/gdp/eopib_annual_growth.svg",  width = 8, height = 6, create.dir = TRUE)



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
        caption = skope_caption("INEGI", max(eopib$date))) +
  scale_x_percent() +
  theme_skope("X")
ggsave("plots/gdp/gdp.svg",  width = 8, height = 6, create.dir = TRUE)


# Fetch the data using the specified series IDs
gdp <- inegi_series(series = "736181", token = inegi.api)

pop <- inegi_series_multiple(series = "289242", token = inegi.api) %>% 
  select(date, date_shortcut, values)

gdppc <- left_join(gdp, pop, join_by(date), suffix = c("_gdp", "_pop")) %>%
  reframe(date, date_shortcut = date_shortcut_gdp, gdppc = values_gdp/values_pop*1000000) %>%
  filter(gdppc != 0)

gdppc_line <- gdppc %>% mutate(p = gdppc)

# Crecimiento económico per cápita
ggplot(gdppc_line, aes(date, p)) +
  geom_line(size = 1, color = "#970639") +
  highlight_last(gdppc_line, "date", "p", color = "#970639", label_fmt = label_comma()) +
  labs( title = "PIB per cápita en México",
        subtitle = "Moneda nacional",
        y = "",
        x = "",
        caption = skope_caption("INEGI", max(gdppc$date))) +
  scale_y_comma() +
  theme_skope()
ggsave("plots/gdp/gdppc.svg",  width = 8, height = 6, create.dir = TRUE)



write.csv(gdppc, "data/growth/gdppc.csv", row.names = FALSE)
write.csv(sexenios_gdp, "data/growth/sexenios_gdp.csv", row.names = FALSE)
