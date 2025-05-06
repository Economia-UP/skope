library(tidyverse)
library(inegiR)
library(hrbrthemes)
library(showtext)
library(svglite)
library(scales)

font_add_google("Rubik", "Rubik")
showtext_auto()

# Define your INEGI API key
inegi.api = Sys.getenv("INEGI_API")

# 214293 Indicador coincidente
# 214295 IGAE
# 214297 Indicador de la actividad industrial
# 214299 Índice de ingresos por suministro de bienes y servicios al por menor
# 214301 Asegurados trabajadores permanentes en el IMSS
# 214303 Tasa de desocupación urbana
# 214305 Importaciones totales
series_id <- c("214293", "214295", "214297", "214299", "214301", "214303", "214305")
series <- inegi_series_multiple(series_id, token = inegi.api) %>% 
  select(date, meta_indicatorid, values) %>%
  mutate(indicator_name = case_match(
    meta_indicatorid,
    "214293" ~ "Indicador coincidente",
    "214295" ~ "IGAE",
    "214297" ~ "Indicador de la actividad industrial",
    "214299" ~ "Bienes y servicios al por menor",
    "214301" ~ "Asegurados trabajadores permanentes en el IMSS",
    "214303" ~ "Tasa de desocupación urbana",
    "214305" ~ "Importaciones totales"
  ))


# Coincidente
# series %>% filter(indicator_name == "Indicador coincidente") %>% 
# ggplot(aes(date, values, col = indicator_name)) +
#   geom_line(data = ~ filter(.x, date <= Sys.Date() - years(2)), col = "#970639", linewidth = 1) +
#   geom_line(data = ~ filter(.x, date > Sys.Date() - years(2)), col = "#970639", linetype = "dotdash", linewidth = 1) +
#   geom_hline(yintercept = 100, col = "black", linewidth = 0.5) + 
#   labs(title = "Indicador coincidente",
#      subtitle = "Componente cíclico",
#      y = "",
#      x = "",
#      caption = "Fuente: INEGI") +
#   scale_x_date(breaks = scales::date_breaks("5 year"), labels = scales::label_date(format = "%Y")) +
#   scale_y_continuous(breaks = scales::breaks_width(2)) + 
#   theme_ipsum_rc(grid = "Y", base_family = "Rubik") +
#   theme(legend.position = "bottom")
# 
# ggsave("plots/gdp/coincidente.svg",  width = 8, height = 6, create.dir = TRUE)

# Foor loop for graphs
for (x in unique(series$indicator_name)) {
series %>% filter(indicator_name == x) %>% 
  ggplot(aes(date, values, col = indicator_name)) +
  geom_line(data = ~ filter(.x, date <= Sys.Date() - years(2)), col = "#970639", linewidth = 1) +
  geom_line(data = ~ filter(.x, date > Sys.Date() - years(2)), col = "#970639", linetype = "dotdash", linewidth = 1) +
  geom_hline(yintercept = 100, col = "black", linewidth = 0.5) + 
  labs(title = x,
       subtitle = "Componente cíclico",
       y = "",
       x = "",
       caption = "Fuente: INEGI") +
  scale_x_date(breaks = scales::date_breaks("5 year"), labels = scales::label_date(format = "%Y")) +
  scale_y_continuous(breaks = scales::breaks_width(2)) + 
  theme_ipsum_rc(grid = "Y", base_family = "Rubik") +
  theme(legend.position = "bottom")

ggsave(paste0("plots/gdp/cycles/",x,".svg"),  width = 8, height = 6, create.dir = TRUE)
}
