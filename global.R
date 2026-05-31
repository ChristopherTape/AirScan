library(shiny)
library(shinydashboard)
library(randomForest)
library(leaflet)
library(tidyverse)
library(ggplot2)
library(dplyr)
library(sf)
library(corrplot)

df <- read.csv("data/airscan_data_r.csv", stringsAsFactors = FALSE)

# Coordonnées GPS des zones
coords_zones <- data.frame(
  zone_campus = c("Parking_Entree", "Restaurant_U", "Amphi_Central", "Cites_Univ", "Zone_Verte"),
  lat = c(5.348818, 5.341344, 5.344578, 5.337946, 5.340596),
  lng = c(-3.987953, -3.989093, -3.991188, -3.995048, -3.991763),
  label = c("Parking Entrée", "Restaurant U", "Amphithéâtres", "Cités Univ.", "Zone Verte"),
  stringsAsFactors = FALSE
)

zones_polygones <- list(
  Parking_Entree = data.frame(
    lng = c(-3.988302, -3.987595, -3.987361, -3.988024, -3.988302),
    lat = c(5.348946,  5.349177,  5.348726,  5.348421,  5.348946)
  ),
  Restaurant_U = data.frame(
    lng = c(-3.989041, -3.989444, -3.989181, -3.988903, -3.989041),
    lat = c(5.341369,  5.341421,  5.341181,  5.341406,  5.341369)
  ),
  Amphi_Central = data.frame(
    lng = c(-3.991835, -3.989905, -3.990093, -3.992918, -3.991835),
    lat = c(5.345783,  5.344340,  5.344185,  5.343984,  5.345783)
  ),
  Cites_Univ = data.frame(
    lng = c(-3.995883, -3.994612, -3.994202, -3.996094, -3.995883),
    lat = c(5.338832,  5.338662,  5.336965,  5.337187,  5.338832)
  ),
  Zone_Verte = data.frame(
    lng = c(-3.992410, -3.990616, -3.990916, -3.993495, -3.992410),
    lat = c(5.341697,  5.341647,  5.339146,  5.339541,  5.341697)
  )
)

# Fonctions utilitaires AQI
couleur_aqi <- function (aqi) {
  dplyr :: case_when(
    aqi < 20  ~ "#22c55e",
    aqi < 40  ~ "#f59e0b",
    aqi < 60  ~ "#ef4444",
    TRUE      ~ "#9d174d"
  )
}

label_aqi <- function (aqi) {
  dplyr:: case_when(
    aqi < 20  ~ "Bon",
    aqi < 40  ~ "Modéré",
    aqi < 60  ~ "Mauvais",
    TRUE      ~ "Dangereux"
  )
}

# Modèle Random Forest — entraîné au chargement
set.seed(42)
df_model <- df %>%
  select(AQI_calcule, heure, jour_index, est_weekend, temperature_C,
         humidite_pct, zone_campus) %>%
  mutate(
    est_weekend = as.numeric(est_weekend=="TRUE"),
    zone_num = as.numeric(as.factor(zone_campus))
  ) %>%
  na.omit()

rf_model <- randomForest(
  AQI_calcule ~ heure + jour_index + est_weekend + temperature_C + humidite_pct + zone_num,
  data = df_model,
  ntree = 100,
  importance = TRUE
)
