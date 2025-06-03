print("inpp.R")
rm(list = ls())

# Load the necessary libraries
library(inegiR)
library(tidyverse)
library(ggrepel)
library(ggpattern)
library(hrbrthemes)
library(showtext)
library(svglite)

font_add_google("Rubik", "Rubik")
showtext_auto()

# Define your INEGI API key
inegi.api = Sys.getenv("INEGI_API")

# Fetch the data using the specified series IDs
idSeries <- c("673095", "673098", "673100")  # Your INEGI series IDs

# Get the data
series <- inegi_series_multiple(series = idSeries, token = inegi.api)

serie <- series %>% 
  select(date, values, meta_indicatorid) %>%  
  mutate(
    meta_indicatorid = recode(meta_indicatorid,
                              "673095" = "INPP (sin petróleo y con servicios)",
                              "673098" = "Actividades secundarias sin petróleo",
                              "673100" = "Actividades terciarias") %>% 
      factor(levels = c("INPP (sin petróleo y con servicios)", 
             "Actividades secundarias sin petróleo",
             "Actividades terciarias"))) %>% 
  rename(indicator = meta_indicatorid) %>% 
  group_by(indicator) %>% 
  arrange(date) %>% 
  mutate(pc = (values/lag(values, 12) -1)*100) %>% 
  filter(date >= Sys.Date() - years(10))

# Transform the data
series.wide <- series %>% 
  select(date, values, meta_indicatorid) %>% 
  pivot_wider(names_from = meta_indicatorid, values_from = values) %>% 
  rename(
    date = date,
    "INPP (sin petróleo y con servicios)" = "673095",
    "Actividades secundarias sin petróleo" = "673098",
    "Actividades terciarias" = "673100") %>% 
  factor(levels = c("INPP (sin petróleo y con servicios)", 
                    "Actividades secundarias sin petróleo",
                    "Actividades terciarias"))

# Specify the output directory and file name
write.csv(series.wide, "data/inflation/inpp.csv", row.names = FALSE)


# Inflation (INPP) graph
ggplot(serie, aes(date, pc/100, color = indicator)) +
  geom_line(size = 1) +
  geom_point(
    data = serie %>% group_by(indicator) %>% filter(date == max(date)),  # Select last point per line
    size = 2.5  # Adjust point size
  ) +
  ggrepel::geom_text_repel(
    data = serie %>% group_by(indicator) %>% filter(date == max(date)),
    aes(label = scales::percent(pc/100, accuracy = 0.1)),
    nudge_x = 100,  # Desplazamiento base
    direction = "y",  # Solo mueve en eje Y
    min.segment.length = Inf,  # Elimina líneas de conexión
    hjust = -0.2,
    vjust = 0.5,
    size = 3.5,
    box.padding = 0.2,  # Espacio alrededor de etiquetas
    show.legend = FALSE
  ) +
  coord_cartesian(clip = "off") +  # Disable clipping for points/text at edges
  labs( title = "Inflación en México",
        subtitle = "Índice Nacional de Precios al Productor",
        y = "",
       x = paste("Último dato:", format(max(serie$date), '%b, %Y')),
        color = "",
        caption = paste("Fuente: INEGI. Última actualización", format(Sys.time(), '%d %b, %Y'))) +
  scale_y_percent(breaks = seq(min(serie$pc)/100, max(serie$pc)/100,
                               by = 0.02)) +
  scale_x_date(breaks = seq(as.Date(min(serie$date)), 
                            as.Date(max(serie$date)), 
                            by = "1 year"),
               date_labels = "%Y") +  # Format labels as only the year
  scale_color_manual(values = c("#970639", "#043574", "#015b51")) +
  theme_ipsum_rc(grid = "Y", base_family = "Rubik") +
  theme(legend.position="bottom")
ggsave("plots/inflation/inpp.svg",  width = 8, height = 6, create.dir = TRUE)

