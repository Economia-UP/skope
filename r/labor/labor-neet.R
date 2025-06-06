print("labor-neet.R")
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
idSeries <- c("446701", "446875", "447049")  # Your INEGI series IDs
idSeries2 <- c("1002000067", "1002000070")

# Get the data
series <- inegi_series_multiple(series = idSeries, token = inegi.api)
series2 <- inegi_series_multiple(series = idSeries2, token = inegi.api)

df <- series %>%
  select(date, meta_indicatorid, values) %>%
  mutate(meta_indicatorid = case_when(
    meta_indicatorid == 447701 ~ "Total",
    meta_indicatorid == 447702 ~ "Hombres",
    meta_indicatorid == 447703 ~ "Mujeres",
    meta_indicatorid == 1002000067 ~ "Población de 15 a 19 años",
    meta_indicatorid == 1002000070 ~ "Población de 20 a 24 años")) %>% 
  mutate(year = year(date),
         meta_indicatorid = factor(meta_indicatorid, levels = c("Total", "Hombres", "Mujeres"))) %>% 
 pivot_wider(names_from = meta_indicatorid, values_from = values)



ggplot(df, aes(as.Date(paste(year, "01-01", sep = "-"), format = "%Y-%m-%d"), values/100, color = meta_indicatorid)) +
  geom_line(size = 1) +
  geom_point(size = 2, aes(col = meta_indicatorid)) + 
  labs(
    title = "Empleo en el sector informal (TOSI)",
    subtitle = "Empleo en unidades económicas informales como % del empleo total",
    y = "",
    x = paste("Último dato:", format(max(df$year))),
    color = "",
    caption = skope_caption("INEGI", as.Date(paste(max(df$year), "01-01", sep = "-")))
  ) +
  scale_color_manual(values = c("#970639", "#043574", "#015b51", "black")) +
  scale_y_continuous(breaks = scales::breaks_pretty(), labels = scales::label_percent(), limits = c(25/100, 31/100)) +
  scale_x_date(labels = scales::date_format("%Y"), breaks = scales::date_breaks("2 years")) + 
  theme_skope()
ggsave("plots/labor/labor-tosi.svg",  width = 8, height = 6, create.dir = TRUE)


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
    title = "Brecha TOSI entre mujeres y hombres",
    subtitle = "Brecha TOSI entre mujeres y hombres",
    y = "",
    x = paste("Último dato:", format(max(df$year))),
    color = "",
    caption = skope_caption("INEGI", as.Date(paste(max(df$year), "01-01", sep = "-")))
  ) +
  scale_y_continuous(breaks = scales::breaks_pretty(6), limits = c(0.88, 1)) +
  scale_x_date(breaks = scales::date_breaks("2 years"), labels = scales::date_format("%Y")) +
  theme_skope()
ggsave("plots/labor/labor-gap-tosi.svg",  width = 8, height = 6, create.dir = TRUE)
