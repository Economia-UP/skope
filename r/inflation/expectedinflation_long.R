print("expectedinflation.R")
rm(list=ls())

library(siebanxicor)
library(tidyverse)
library(hrbrthemes)
library(showtext)
library(svglite)

source("r/theme_skope.R")
skope_load_fonts()

# Define your INEGI API key
setToken(Sys.getenv("BANXICO_API"))

# Fetch the data using the specified series IDs
idSeries <- c("SR14216", "SR14217","SR14218") 

# Get the data
series <- getSeriesData(idSeries)
med <- getSerieDataFrame(series, "SR14216")
first <- getSerieDataFrame(series, "SR14217")
third <- getSerieDataFrame(series, "SR14218")

series.df <- reduce(list(first, med, third), full_join, by = "date") %>% 
  filter(date >= Sys.Date() - years(2))
colnames(series.df)[2:4] <- c("Primer cuartil", "Mediana", "Tercer cuartil")

series.long <- series.df %>%
  pivot_longer(
    !date,
    names_to = "index",
    values_to = "value"
  ) %>%
  mutate(index = factor(index, levels = c("Primer cuartil", "Mediana", "Tercer cuartil")))

last_points <- series.long %>% group_by(index) %>% filter(date == max(date))


ggplot(series.long, aes(date, value/100, color = index, group = date)) +
  geom_line(color = "grey", linewidth = 1) +
  geom_point(size = 3) +
  geom_point(data = last_points, size = 3) +
  geom_text(data = last_points, aes(label = scales::percent(value/100, accuracy = 0.1)),
            vjust = -0.5, hjust = 0, show.legend = FALSE, size = 3) +
  labs(
    title = paste("Expectativas de inflación", year(Sys.Date())),
    subtitle = "Encuestas Sobre las Expectativas de los Especialistas en Economía del \nSector Privado Expectativas de Largo Plazo de la Inflación para los Próximos 5 a 8 Años",
    x = "",
    y = "",
    color = "",
    caption = skope_caption("Banxico", max(series.long$date))
  ) +
  scale_y_percent(labels = scales::percent_format(accuracy = 0.1), limits = c(0.034, 0.039)) +  # Two decimal places
  scale_x_date(labels = scales::date_format("%b\n%Y")) +
  scale_color_manual(values=c("#009076", "#ffe59c", "#c71e1d")) +
  theme_skope() +
  theme(
    legend.position = "bottom"
  )
ggsave("plots/inflation/expectedinflation_long.svg",  width = 8, height = 6, create.dir = TRUE)


# Specify the output directory and file name
write.csv(series.df, "data/inflation/expectedinflation.csv", row.names = FALSE)
