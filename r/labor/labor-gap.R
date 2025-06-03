print("labor-gap.R")
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
idSeries <- c("448383", "448386", "448389")  # Your INEGI series IDs

# Get the data
series <- inegi_series_multiple(series = idSeries, token = inegi.api)

df <- series %>%
  select(date, meta_indicatorid, values) %>%
  mutate(meta_indicatorid = case_when(
    meta_indicatorid == 448383 ~ "Total",
    meta_indicatorid == 448386 ~ "Hombres",
    meta_indicatorid == 448389 ~ "Mujeres")) %>% 
  mutate(year = year(date),
         meta_indicatorid = factor(meta_indicatorid, levels = c("Total", "Hombres", "Mujeres"))) %>%
  group_by(year, meta_indicatorid) %>%
  reframe(values = mean(values, na.rm = TRUE), .groups = "drop")  


last_df <- df %>% filter(year == max(year))

ggplot(df, aes(as.Date(paste(year, "01-01", sep = "-"), format = "%Y-%m-%d"), values/100, color = meta_indicatorid)) +
  geom_line(size = 1) +
  geom_point(data = last_df, size = 2) +
  geom_text(data = last_df, aes(label = scales::percent(values/100, accuracy = 0.1)), vjust = -0.5, hjust = 0, show.legend = FALSE, size = 3) +
  labs(
    title = "Relación empleo-población (EPR)",
    subtitle = "Personas empleadas como % de la población en edad laboral (15 años y más)",
    y = "",
    x = paste("Último dato:", format(max(df$year))),
    color = "",
    caption = skope_caption("INEGI", as.Date(paste(max(df$year), "01-01", sep = "-")))
  ) +
  scale_color_manual(values = c("#970639", "#043574", "#015b51")) +
  scale_x_date(breaks = scales::date_breaks("2 years"), labels = scales::label_date("%Y")) +
  scale_y_percent(breaks = scales::breaks_pretty(8) , limits = c(0.3, 0.85)) + 
  theme_skope()
ggsave("plots/labor/labor-share.svg",  width = 8, height = 6, create.dir = TRUE)


# Brecha
gap <- df %>%
  filter(meta_indicatorid %in% c("Hombres", "Mujeres")) %>%
  pivot_wider(names_from = meta_indicatorid, values_from = values) %>%
  mutate(gap = Hombres / Mujeres) %>%
  select(year, gap) %>% 
  ungroup()

last_gap <- gap %>% filter(year == max(year))

ggplot(gap, aes(as.Date(paste(year, "01-01", sep = "-"), format = "%Y-%m-%d"), gap)) +
  geom_line(size = 1, col = "#970639") +
  geom_point(data = last_gap, size = 2, col = "#970639") +
  geom_text(data = last_gap, aes(label = round(gap, 2)), vjust = -0.5, hjust = 0, show.legend = FALSE, col = "#970639", size = 3) +
  labs(
    title = "Brecha EPR Mujeres y Hombres",
    subtitle = "EPR hombres/EPR mujeres",
    y = "",
    x = paste("Último dato:", format(max(df$year))),
    color = "",
    caption = skope_caption("INEGI", as.Date(paste(max(df$year), "01-01", sep = "-")))
  ) +
  scale_y_continuous(breaks = scales::breaks_pretty(), limits = c(1.6, 2)) + 
  scale_x_date(breaks = scales::date_breaks("2 years"), labels = scales::label_date("%Y")) +
  theme_skope()
ggsave("plots/labor/labor-gap.svg",  width = 8, height = 6, create.dir = TRUE)
