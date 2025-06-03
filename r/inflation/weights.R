print("weights.R")
rm(list = ls())

# Load the necessary libraries
library(inegiR)
library(hrbrthemes)
library(tidyverse)
library(showtext)
library(svglite)

source("r/theme_skope.R")
skope_load_fonts()

# Define your INEGI API key
inegi.api = Sys.getenv("INEGI_API")

# Load dfs
weights <- read.csv("r/inflation/weights.csv") %>% 
  reframe(Concept, Weight = Weight/100)

# Fetch the data using the specified series IDs
idSeries <- c("910408", "910409", "910411", "910412")

# Get the data
series <- inegi_series_multiple(series = idSeries, token = inegi.api)


# Transform the data
series.wide <- series %>%
  select(date, values, meta_indicatorid) %>%  
  pivot_wider(names_from = meta_indicatorid, values_from = values) %>%
  rename(
    date = date,
    'Mercancías' = '910408',
    'Servicios' = '910409',
    'Agropecuarios' = '910411',
    'Energéticos y tarifas autorizadas por el gobierno' = '910412')


series.incidence <- series.wide %>% 
  mutate(
    "Mercancías" = Mercancías*weights$Weight[weights$Concept == "Mercancías"],
    "Servicios" = Servicios*weights$Weight[weights$Concept == "Servicios"],
    "Agropecuarios" = Agropecuarios*weights$Weight[weights$Concept == "Agropecuarios"],
    "Energéticos y tarifas autorizadas por el gobierno" = `Energéticos y tarifas autorizadas por el gobierno`*weights$Weight[weights$Concept == "Energéticos y tarifas autorizadas por el gobierno "]
      ) %>% 
  filter(date >= Sys.Date() - years(10))

series.plot <- series.incidence %>% 
  pivot_longer(
    !date,
    names_to = "component",
    values_to = "value"
  )




# Inflation, general index
idSeries1 <- c("910406", "910407", "910410")  # Your INEGI series IDs
series1 <- inegi_series_multiple(series = idSeries1, token = inegi.api)
pi <- series1 %>% 
  select(date, values, meta_indicatorid) %>%  
  mutate(
    meta_indicatorid = recode(meta_indicatorid,
                              "910406" = "Inflación general",
                              "910407" = "Subyacente",
                              "910410" = "No subyacente")) %>% 
  rename(indicator = meta_indicatorid) %>% 
  filter(date >= Sys.Date() - years(10))


# Unite df
series.all <- bind_rows(series.plot, pi)


# Graph
ggplot(series.plot, aes(date, value/100, fill = component)) +
  geom_area() +
  labs(
    title = "Inflación por sus componentes",
    x = "",
    y = "",
    fill = "",
    caption = skope_caption("INEGI", max(series.plot$date))
  ) +
  # scale_fill_ipsum() +
  scale_fill_manual(values = c("#970639", "#043574", "#015b51", "#b79357")) +
  scale_y_percent() + 
  theme_ipsum_rc(base_family = "Rubik", grid = "Y") +
  theme(
    legend.position = "bottom"
  )
ggsave("plots/inflation/inpc_components.svg",  width = 8, height = 6, create.dir = TRUE)

# Specify the output directory and file name
write.csv(series.incidence, "data/inflation/weights.csv", row.names = FALSE)
