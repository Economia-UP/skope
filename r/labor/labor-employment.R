print("labor-employment.R")
rm(list = ls())

# Load the necessary libraries
library(inegiR)
library(tidyverse)
library(hrbrthemes)
library(showtext)
library(svglite)
library(scales)
library(zoo)

source("r/theme_skope.R")
skope_load_fonts()

# Define your INEGI API key
inegi.api = Sys.getenv("INEGI_API")

# Fetch the data using the specified series IDs
idSeries <- c("303259", "303260", "303261")  # Your INEGI series IDs

# Get the data
series <- inegi_series_multiple(series = idSeries, token = inegi.api)

df <- series %>%
  select(date, meta_indicatorid, values) %>%
  mutate(meta_indicatorid = case_when(
    meta_indicatorid == 303259 ~ "Total",
    meta_indicatorid == 303260 ~ "Hombres",
    meta_indicatorid == 303261 ~ "Mujeres")) %>% 
  mutate(year = year(date),
         meta_indicatorid = factor(meta_indicatorid, levels = c("Total", "Hombres", "Mujeres"))) %>%
  group_by(year, meta_indicatorid) %>%
  reframe(values = mean(values, na.rm = TRUE))  


ggplot(df, aes(as.Date(paste(year, "01-01", sep = "-"), format = "%Y-%m-%d"), values/100, color = meta_indicatorid)) +
  geom_line(size = 1) +
  geom_point(size = 2, aes(col = meta_indicatorid)) + 
  labs(
    title = "Tasa de desempleo (UR)",
    subtitle = "Personas desempleadas (15 años y más) como % de la fuerza laboral",
    y = "",
    x = paste("Último dato:", format(max(df$year))),
    color = "",
    caption = paste("Fuente: INEGI. Última actualización", format(Sys.time(), '%d %b, %Y'))
  ) +
  scale_color_manual(values = c("#970639", "#043574", "#015b51")) +
  scale_y_continuous(breaks = scales::breaks_pretty(), labels = scales::label_percent(), limits = c(2/100, 6/100)) + 
  scale_x_date(labels = scales::date_format("%Y"), breaks = scales::date_breaks("2 years")) + 
  theme_skope()
ggsave("plots/labor/labor-unemployment.svg",  width = 8, height = 6, create.dir = TRUE)


# Brecha
gap <- df %>%
  filter(meta_indicatorid %in% c("Hombres", "Mujeres")) %>%
  pivot_wider(names_from = meta_indicatorid, values_from = values) %>%
  mutate(gap = Hombres / Mujeres) %>%
  select(year, gap) %>% 
  ungroup()

ggplot(gap, aes(as.Date(paste(year, "01-01", sep = "-"), format = "%Y-%m-%d"), gap)) +
  geom_line(size = 1, col = "#970639") +
  geom_point(size = 2, col = "#970639") + 
  # geom_text(aes(label = round(gap,2)), nudge_y = 0.02) +
  labs(
    title = "Brecha UR Mujeres y Hombres",
    subtitle = "UR hombres/UR mujeres",
    y = "",
    x = paste("Último dato:", format(max(df$year))),
    color = "",
    caption = paste("Fuente: INEGI. Última actualización", format(Sys.time(), '%d %b, %Y'))
  ) +
  scale_y_continuous(breaks = scales::breaks_pretty(n = 8), limits = c(0.8, 1.2)) +
  scale_x_date(breaks = scales::date_breaks("2 years"), labels = scales::date_format("%Y")) +
  theme_skope()
ggsave("plots/labor/labor-gap-unemployment.svg",  width = 8, height = 6, create.dir = TRUE)
