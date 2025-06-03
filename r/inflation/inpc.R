print("inpc.R")
rm(list = ls())

# Load the necessary libraries
library(inegiR)
library(tidyverse)
library(ggpattern)
library(ggrepel)
library(hrbrthemes)
library(showtext)
library(svglite)

font_add_google("Rubik", "Rubik")
showtext_auto()

# Define your INEGI API key
inegi.api = Sys.getenv("INEGI_API")

# Fetch the data using the specified series IDs
idSeries1 <- c("910406", "910407", "910410")  # Your INEGI series IDs

# Get the data
series1 <- inegi_series_multiple(series = idSeries1, token = inegi.api)

# Transform the data
series.wide <- series1 %>%
  select(date, values, meta_indicatorid) %>%  
  pivot_wider(names_from = meta_indicatorid, values_from = values) %>%
  rename(
    date = date,
    'Inflación general' = '910406',
    'Subyacente' = '910407',
    'No subyacente' = '910410')

# Specify the output directory and file name
write.csv(series.wide, "data/inflation/inpc.csv", row.names = FALSE)

df <- series1 %>% 
  select(date, values, meta_indicatorid) %>%  
  mutate(
    meta_indicatorid = recode(meta_indicatorid,
                              "910406" = "Inflación general",
                              "910407" = "Subyacente",
                              "910410" = "No subyacente")) %>% 
  rename(indicator = meta_indicatorid) %>% 
  filter(date >= Sys.Date() - years(10),
         indicator != "No subyacente")


# Inflation graph
ggplot(df, aes(date, values / 100, color = indicator)) +
  geom_line(size = 1) +
  geom_point(
    data = df %>% group_by(indicator) %>% filter(date == max(date)),  # Select last point per line
    size = 2.5  # Adjust point size
  ) +
  ggrepel::geom_text_repel(
    data = df %>% group_by(indicator) %>% filter(date == max(date)),
    aes(label = scales::percent(values / 100, accuracy = 0.1)),
    nudge_x = 50,  # Desplazamiento base
    direction = "y",  # Solo mueve en eje Y
    min.segment.length = Inf,  # Elimina líneas de conexión
    hjust = -0.3,
    vjust = 0.5,
    size = 3.5,
    box.padding = 0.2,  # Espacio alrededor de etiquetas
    show.legend = FALSE
  ) +
  labs( 
    title = "Inflación en México",
    subtitle = "Índice Nacional de Precios al Consumidor",
    y = "",
    x = paste("Último dato:", format(max(df$date), '%b, %Y')),
    color = "",
    caption = paste("Fuente: INEGI. Última actualización", format(Sys.time(), '%d %b, %Y'))
  ) +
  scale_y_continuous(labels = scales::label_percent(), breaks = scales::breaks_pretty()) +  # Use scale_y_continuous if scale_y_percent doesn't work
  scale_x_date() +
  scale_color_manual(values = c("#970639", "#043574")) +
  theme_ipsum_rc(grid = "Y", base_family = "Rubik") +  # Adjusting theme
  theme(legend.position = "bottom")
ggsave("plots/inflation/inpc.svg",  width = 8, height = 6, create.dir = TRUE)

# Fetch the data using the specified series IDs (Subyacente)
idSeries2 <- c("910407", "910408", "910409")  # Your INEGI series IDs

# Get the data
series2 <- inegi_series_multiple(series = idSeries2, token = inegi.api)

# Transform the data
series2.wide <- series2 %>%
  select(date, values, meta_indicatorid) %>%
  mutate(
    meta_indicatorid = factor(meta_indicatorid,
                              levels = c("910407", "910408", "910409"))
  ) %>%
  pivot_wider(names_from = meta_indicatorid, values_from = values) %>%
  rename(
    date = date,
    "Total"      = "910407",
    "Mercancías" = "910408",
    "Servicios"  = "910409"
  ) %>%
  mutate(
    date = as.Date(date),
    across(c("Total", "Mercancías", "Servicios"), as.numeric)
  )

# Specify the output directory and file name
write.csv(series2.wide, "data/inflation/inpc_core.csv", row.names = FALSE)


sub <- series2 %>% 
  select(date, values, meta_indicatorid) %>%  
  mutate(
    meta_indicatorid = recode(meta_indicatorid,
                              "910407" = "Total",
                              "910408" = "Mercancías",
                              "910409" = "Servicios") %>% 
  factor(levels = c("Total", "Mercancías", "Servicios"))) %>% 
  rename(indicator = meta_indicatorid) %>% 
  filter(date >= Sys.Date() - years(10),
         indicator != "Total")

# Core inflation graph
ggplot(sub, aes(date, values / 100, color = indicator)) +  # Divide by 100 for the values to be in a 0-1 scale
  geom_line(size = 1) +
  geom_point(
    data = sub %>% group_by(indicator) %>% filter(date == max(date)),  # Select last point per line
    size = 2.5  # Adjust point size
  ) +
  coord_cartesian(clip = "off") +
  geom_text(
    data = sub %>% group_by(indicator) %>% filter(date == max(date)),  # Select last point per line
    aes(label = scales::label_percent()(values / 100)),  # Format label as percentage (values should already be divided by 100)
    hjust = -0.3,  # Adjust text position (shift right)
    vjust = 0.2,
    size = 3.5,
    show.legend = FALSE
  ) +
  scale_y_percent(breaks = scales::breaks_pretty()) +  # Show y-axis as percentage
  labs(
    title = "Inflación subyacente en México",
    y = "",
    x = paste("Último dato:", format(max(sub$date), '%b, %Y')),
    color = "",
    caption = paste("Fuente: INEGI. Última actualización", format(Sys.time(), '%d %b, %Y'))
  ) +
  scale_color_manual(values = c("#970639", "#043574", "black")) +
  theme_ipsum_rc(grid = "Y", base_family = "Rubik") +
  theme(legend.position = "bottom") 
ggsave("plots/inflation/inpc_sub.svg",  width = 8, height = 6, create.dir = TRUE)

