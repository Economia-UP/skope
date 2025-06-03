library(tidyverse)
library(inegiR)
library(hrbrthemes)
library(showtext)
library(svglite)
library(scales)

source("r/theme_skope.R")
skope_load_fonts()

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

# Define the color palette
palette <- c(
  "#B8A751",  # Oro – Tradición
  "#193E75",  # Azul – Prudencia
  "#A1243B",  # Vino – Fortaleza
  "#006E61",  # Verde – Esperanza
  "#E0CA6F",  # Oro claro (más dorado y menos verdoso)
  "#6A9FD9",  # Azul claro (un poco menos saturado)
  "#D07483"   # Vino claro (más rosado y contrastado)
)

# Define the date range
series_filt <- series %>% 
  filter(date >= as.Date("2022-01-01"),
  indicator_name != "Indicador coincidente")

# Create the plot
# Define the date range for x-axis
min_d <- floor_date(min(series_filt$date), unit = "month")
max_d <- ceiling_date(max(series_filt$date), unit = "month")

# Plot the data
series_filt %>%
  ggplot(aes(date, values, col = indicator_name)) +
    # Líneas sólidas y dotdash según antigüedad
    geom_line(linewidth = 1) +
    geom_hline(yintercept = 100, col = "black", linewidth = 0.5) + 

    # Etiquetas y títulos
    labs(
      title    = "Indicador coincidente por componentes",
      subtitle = "Componente cíclico",
      x        = NULL,
      y        = "Por abajo de 100 indica recesión",
      caption  = "Fuente: INEGI",
      colour   = NULL            # quita el título de la leyenda
    ) +

    # Ejes
      scale_x_date(
        # un break cada mes
        breaks = seq(from = floor_date(min_d, "month"), 
                    to   = ceiling_date(max_d, "month"), 
                    by   = "3 month"),
        # etiqueta “YYYY” en enero, “Abr”, “May”, … en los otros
        labels = function(x) {
          ifelse(month(x) == 1, 
                format(x, "%b\n%Y"), 
                format(x, "%b"))
        },
        expand = expansion(mult = c(0.01, 0.01))
      ) +
    scale_y_continuous(breaks = scales::pretty_breaks()) +

    # Paleta manual + envoltorio de labels para que los nombres largos
    scale_color_manual(
      values = palette,
      labels = function(x) str_wrap(x, width = 25)
    ) +

    # Leyenda en el pie, dos columnas
    guides(
      colour = guide_legend(
        ncol   = 2,
        byrow  = TRUE,
        label.hjust = 0
      )
    ) +

    # Tema
    theme_ipsum_rc(grid = "Y", base_family = "Rubik") +
    theme(
      legend.position = "bottom",
      legend.margin   = margin(t = 5), 
      legend.spacing.x = unit(0.5, "cm")
    )

# Save the plot
ggsave("plots/gdp/coincidente-componentes.svg", width = 8, height = 6, bg = "white", create.dir = TRUE)


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
  theme_skope()
  # Save the plot
ggsave(paste0("plots/gdp/cycles/",x,".svg"),  width = 8, height = 6, create.dir = TRUE)
}
