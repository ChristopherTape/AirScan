#   AirScan CI — server.R       

# La fonction server prend toujours input et output 
# input  = ce que l'utilisateur envoie (clics, filtres...)
# output = ce que tu envoies vers l'écran
server <- function(input, output, session) {
  
  
  
  # DONNÉES  On calcule les stats dont on a besoin
  
  
  # Valeurs moyennes par zone
  # On pré-calcule une fois pour toutes les pages
  # group_by() + summarise() = regrouper et résumer
  stats_zones <- df %>%
    group_by(zone_campus) %>%
    summarise(
      co_moy   = round(mean(CO_ppm,       na.rm = TRUE), 1),
      co2_moy  = round(mean(CO2_ppm,      na.rm = TRUE), 0),
      nh3_moy  = round(mean(NH3_ppm,      na.rm = TRUE), 1),
      temp_moy = round(mean(temperature_C,na.rm = TRUE), 1),
      hum_moy  = round(mean(humidite_pct, na.rm = TRUE), 1),
      aqi_moy  = round(mean(AQI_calcule,  na.rm = TRUE), 1),
      .groups  = "drop"
    )
  
  

  # KPI 1 — AQI moyen campus
  # renderText() envoie du texte simple vers textOutput()

  output$aqi_moyen <- renderText({
    # mean() = moyenne de toute la colonne AQI
    # round(..., 1) = arrondir à 1 décimale
    round(mean(df$AQI_calcule, na.rm = TRUE), 1)
  })
  
  # Le badge coloré sous l'AQI
  # renderUI() envoie du HTML vers uiOutput()
  output$aqi_badge <- renderUI({
    val <- mean(df$AQI_calcule, na.rm = TRUE)
    
    # On choisit la classe CSS selon la valeur
    # case_when() = if/else multiple (tidyverse)
    classe <- dplyr::case_when(
      val < 20 ~ "badge-bon",
      val < 40 ~ "badge-modere",
      val < 60 ~ "badge-mauvais",
      TRUE     ~ "badge-danger"
    )
    
    texte <- dplyr::case_when(
      val < 20 ~ "Bon",
      val < 40 ~ "Modéré",
      val < 60 ~ "Mauvais",
      TRUE     ~ "Dangereux"
    )
    
    # tags$span() crée une balise HTML <span>
    tags$span(texte, class = classe)
  })
  
  
  
  # KPI 2 : CO max

  output$co_max <- renderText({
    round(quantile(df$CO_ppm, 0.95, na.rm = TRUE), 1)
  })
  
  output$co2_max <- renderText({
    round(quantile(df$CO2_ppm, 0.95, na.rm = TRUE), 0)
  })
  
  output$co_badge <- renderUI({
    # On veut afficher quelle zone a le CO max
    # which.max() donne l'index de la valeur max
    zone_max <- stats_zones$zone_campus[which.max(stats_zones$co_moy)]
    # Raccourcir le nom pour l'affichage
    label <- gsub("_", " ", zone_max) # remplace _ par espace
    label <- gsub("Parking Entree", "Parking", label)
    tags$span(label, class = "badge-mauvais")
  })
  
  
  
  # KPI 3  CO₂ max
  
  output$co2_max <- renderText({
    round(max(df$CO2_ppm, na.rm = TRUE), 0)
  })
  
  output$co2_badge <- renderUI({
    zone_max <- stats_zones$zone_campus[which.max(stats_zones$co2_moy)]
    label <- dplyr::case_when(
      zone_max == "Amphi_Central"  ~ "Amphi",
      zone_max == "Parking_Entree" ~ "Parking",
      zone_max == "Restaurant_U"   ~ "Restau U",
      TRUE                         ~ zone_max
    )
    tags$span(label, class = "badge-modere")
  })
  
  
  
  # KPI 4 — Zone la plus saine
  
  output$zone_saine <- renderUI({
    # which.min() = indice de la valeur MINIMUM (= zone la plus propre)
    zone_min <- stats_zones$zone_campus[which.min(stats_zones$aqi_moy)]
    label <- gsub("_", " ", zone_min)
    tags$span(label)
  })
  
  output$zone_saine_badge <- renderUI({
    aqi_min <- min(stats_zones$aqi_moy)
    tags$span(paste("AQI", aqi_min), class = "badge-bon")
  })
  
  
  
  # GRAPHIQUE Barres AQI par zone
  # renderPlot() crée un graphique ggplot2
  
  output$aqi_barplot <- renderPlot({
    
    # Couleurs selon le niveau d'AQI
    couleurs <- dplyr::case_when(
      stats_zones$aqi_moy >= 40 ~ "#ef4444",  # rouge
      stats_zones$aqi_moy >= 20 ~ "#f59e0b",  # orange
      stats_zones$aqi_moy >= 10 ~ "#22c55e",  # vert
      TRUE                      ~ "#16a34a"   # vert foncé
    )
    
    # Labels lisibles pour l'axe Y
    labels <- dplyr::case_when(
      stats_zones$zone_campus == "Parking_Entree" ~ "Parking",
      stats_zones$zone_campus == "Restaurant_U"   ~ "Restau U",
      stats_zones$zone_campus == "Amphi_Central"  ~ "Amphi",
      stats_zones$zone_campus == "Cites_Univ"     ~ "Cités",
      stats_zones$zone_campus == "Zone_Verte"     ~ "Zone verte",
      TRUE ~ stats_zones$zone_campus
    )
    
    # Trier du plus pollué au moins pollué
    ordre <- order(stats_zones$aqi_moy, decreasing = FALSE)
    
    # Créer le graphique avec ggplot2
    # aes() = aesthetic = quoi mettre en X et Y
    ggplot(stats_zones, aes(
      x    = reorder(labels, aqi_moy),  # trier par valeur
      y    = aqi_moy,
      fill = couleurs
    )) +
      # geom_col() = barres horizontales (avec coord_flip)
      geom_col(width = 0.55, show.legend = FALSE) +
      
      # Afficher la valeur au bout de chaque barre
      geom_text(aes(label = aqi_moy),
                hjust = -0.2, size = 3.8,
                color = couleurs, fontface = "bold") +
      
      # Couleurs manuelles
      scale_fill_identity() +
      
      # Limiter l'axe X pour laisser de la place aux labels
      scale_y_continuous(limits = c(0, 55)) +
      
      # Retourner le graphique (barres horizontales)
      coord_flip() +
      
      # Supprimer le fond gris par défaut de ggplot
      theme_minimal() +
      theme(
        panel.grid       = element_blank(),       # pas de grille
        axis.title       = element_blank(),       # pas de titres d'axes
        axis.text.x      = element_blank(),       # pas de chiffres en bas
        axis.text.y      = element_text(size = 12, color = "#374151"),
        plot.background  = element_rect(fill = "white", color = NA),
        panel.background = element_rect(fill = "white", color = NA)
      )
  }, bg = "white")
  
  
  
  # ZONE CARDS  Parking, Restaurant, Amphithéâtres
  # On filtre les données par zone avec filter()
  
  
  # Parking
  output$parking_co   <- renderText({ stats_zones %>% filter(zone_campus == "Parking_Entree") %>% pull(co_moy) })
  output$parking_co2  <- renderText({ stats_zones %>% filter(zone_campus == "Parking_Entree") %>% pull(co2_moy) })
  output$parking_nh3  <- renderText({ stats_zones %>% filter(zone_campus == "Parking_Entree") %>% pull(nh3_moy) })
  output$parking_temp <- renderText({ paste0(stats_zones %>% filter(zone_campus == "Parking_Entree") %>% pull(temp_moy), "°C") })
  output$parking_hum  <- renderText({ paste0(stats_zones %>% filter(zone_campus == "Parking_Entree") %>% pull(hum_moy), "% humidité") })
  
  # Restaurant U 
  output$restau_co    <- renderText({ stats_zones %>% filter(zone_campus == "Restaurant_U") %>% pull(co_moy) })
  output$restau_co2   <- renderText({ stats_zones %>% filter(zone_campus == "Restaurant_U") %>% pull(co2_moy) })
  output$restau_nh3   <- renderText({ stats_zones %>% filter(zone_campus == "Restaurant_U") %>% pull(nh3_moy) })
  output$restau_temp  <- renderText({ paste0(stats_zones %>% filter(zone_campus == "Restaurant_U") %>% pull(temp_moy), "°C") })
  output$restau_hum   <- renderText({ paste0(stats_zones %>% filter(zone_campus == "Restaurant_U") %>% pull(hum_moy), "% humidité") })
  
  # Amphithéâtres
  output$amphi_co     <- renderText({ stats_zones %>% filter(zone_campus == "Amphi_Central") %>% pull(co_moy) })
  output$amphi_co2    <- renderText({ stats_zones %>% filter(zone_campus == "Amphi_Central") %>% pull(co2_moy) })
  output$amphi_nh3    <- renderText({ stats_zones %>% filter(zone_campus == "Amphi_Central") %>% pull(nh3_moy) })
  output$amphi_temp   <- renderText({ paste0(stats_zones %>% filter(zone_campus == "Amphi_Central") %>% pull(temp_moy), "°C") })
  output$amphi_hum    <- renderText({ paste0(stats_zones %>% filter(zone_campus == "Amphi_Central") %>% pull(hum_moy), "% humidité") })
  
  # Cites Universitaires
  output$cites_co   <- renderText({ stats_zones %>% filter(zone_campus == "Cites_Univ") %>% pull(co_moy) })
  output$cites_co2  <- renderText({ stats_zones %>% filter(zone_campus == "Cites_Univ") %>% pull(co2_moy) })
  output$cites_nh3  <- renderText({ stats_zones %>% filter(zone_campus == "Cites_Univ") %>% pull(nh3_moy) })
  output$cites_temp <- renderText({ paste0(stats_zones %>% filter(zone_campus == "Cites_Univ") %>% pull(temp_moy), "C") })
  output$cites_hum  <- renderText({ paste0(stats_zones %>% filter(zone_campus == "Cites_Univ") %>% pull(hum_moy), "% humidite") })
  
  # Zone Verte
  output$verte_co   <- renderText({ stats_zones %>% filter(zone_campus == "Zone_Verte") %>% pull(co_moy) })
  output$verte_co2  <- renderText({ stats_zones %>% filter(zone_campus == "Zone_Verte") %>% pull(co2_moy) })
  output$verte_nh3  <- renderText({ stats_zones %>% filter(zone_campus == "Zone_Verte") %>% pull(nh3_moy) })
  output$verte_temp <- renderText({ paste0(stats_zones %>% filter(zone_campus == "Zone_Verte") %>% pull(temp_moy), "C") })
  output$verte_hum  <- renderText({ paste0(stats_zones %>% filter(zone_campus == "Zone_Verte") %>% pull(hum_moy), "% humidite") })
  
  #--------------PAGE CARTE ----------------------------#
  #AQI moyen par zone 
  carte_data <- stats_zones %>%
    left_join(coords_zones, by="zone_campus") %>%
    mutate(
      couleur = couleur_aqi(aqi_moy),
      categorie = label_aqi(aqi_moy)
    )
  output$carte_campus <- renderLeaflet({
    leaflet(carte_data) %>%
      addTiles() %>%
      setView(lng = -3.9920, lat = 5.3430, zoom = 15) %>%
      addCircleMarkers(
        lng = ~lng, lat = ~lat,
        radius = ~pmax(25, aqi_moy / 1.5),
        color = ~couleur,
        fillColor = ~couleur,
        fillOpacity = 0.5,
        stroke = TRUE, weight = 3,
        label = ~paste0(label, " — AQI: ", aqi_moy),
        popup = ~paste0(
          "<div style='font-family:Inter,sans-serif; min-width:200px;'>",
          "<b style='font-size:14px;'>", label, "</b><br/>",
          "<span style='color:", couleur, "; font-weight:600;'>AQI: ", aqi_moy,
          " — ", categorie, "</span><br/><hr style='margin:6px 0;'>",
          "CO: ", co_moy, " ppm<br/>",
          "CO₂: ", co2_moy, " ppm<br/>",
          "NH₃: ", nh3_moy, " ppm<br/>",
          "Temp: ", temp_moy, "°C | Hum: ", hum_moy, "%",
          "</div>"
        ),
        layerId = ~zone_campus
      ) %>%
      addLabelOnlyMarkers(
        data = carte_data,
        lng = ~lng, lat = ~lat,
        label = ~label,
        labelOptions = labelOptions(
          noHide = TRUE, direction = "top",
          style = list(
            "font-weight"    = "700",
            "font-size"      = "12px",
            "color"          = "#111827",
            "background"     = "white",
            "border"         = "1px solid #e5e7eb",
            "border-radius"  = "6px",
            "padding"        = "3px 8px",
            "box-shadow"     = "0 1px 4px rgba(0,0,0,0.15)"
          )
        )
      )
  })
  
  # le panneau qui s'affiche a droite 
  
  output$carte_detail_zone <- renderUI({
    clicked <- input$carte_campus_marker_click
    
    if (is.null(clicked)) {
      return(div(
        style = "text-align:center; color:#9ca3af; padding: 30px 0;",
        icon("map-pin", style = "font-size: 32px; margin-bottom: 12px;"),
        tags$p("Cliquez sur un marqueur pour voir les détails de la zone.")
      ))
    }
    
    zone_id  <- clicked$id
    zone_row <- carte_data %>% filter(zone_campus == zone_id)
    
    if (nrow(zone_row) == 0) return(NULL)
    
    aqi <- zone_row$aqi_moy
    badge_cls <- dplyr::case_when(
      aqi < 20 ~ "badge-bon", aqi < 40 ~ "badge-modere",
      aqi < 60 ~ "badge-mauvais", TRUE ~ "badge-danger"
    )
    
    div(
      tags$h4(zone_row$label, style = "font-weight:700; color:#111827; margin-bottom:12px;"),
      div(style = paste0("font-size:36px; font-weight:800; color:", zone_row$couleur, ";"), aqi),
      tags$span(zone_row$categorie, class = badge_cls),
      tags$hr(style = "border-color:#f3f4f6; margin:14px 0;"),
      div(style = "display:flex; justify-content:space-between; font-size:13px; margin-bottom:8px;",
          span("CO"), tags$b(paste(zone_row$co_moy, "ppm"))),
      div(style = "display:flex; justify-content:space-between; font-size:13px; margin-bottom:8px;",
          span("CO₂"), tags$b(paste(zone_row$co2_moy, "ppm"))),
      div(style = "display:flex; justify-content:space-between; font-size:13px; margin-bottom:8px;",
          span("NH₃"), tags$b(paste(zone_row$nh3_moy, "ppm"))),
      tags$hr(style = "border-color:#f3f4f6; margin:10px 0;"),
      div(style = "display:flex; justify-content:space-between; font-size:12px; color:#6b7280;",
          span(paste0("🌡 ", zone_row$temp_moy, "°C")),
          span(paste0("💧 ", zone_row$hum_moy, "%")))
    )
  })
  
  #---------------------- LA PAGE TEMPORELLE--------------#
  
  temp_df_filtre <- reactive({
    data_f <- df
    
    if (input$temp_zone != "toutes") {
      data_f <- data_f %>% filter(zone_campus == input$temp_zone)
    }
    if (input$temp_periode == "semaine") {
      data_f <- data_f %>% filter(est_weekend == "False")
    } else if (input$temp_periode == "weekend") {
      data_f <- data_f %>% filter(est_weekend == "True")
    }
    data_f
  })
  temp_var <- reactive({
    switch(input$temp_polluant,
           "AQI"  = "AQI_calcule",
           "CO"   = "CO_ppm",
           "CO2"  = "CO2_ppm",
           "NH3"  = "NH3_ppm"
    )
  })
  
  temp_label <- reactive({
    switch(input$temp_polluant,
           "AQI" = "AQI calculé",
           "CO"  = "CO (ppm)",
           "CO2" = "CO₂ (ppm)",
           "NH3" = "NH₃ (ppm)"
    )
  })
  
  # les differents Kips
  
  output$temp_kpis <- renderUI({
    df_s  <- temp_df_filtre()
    var   <- temp_var()
    vals  <- df_s[[var]]
    
    # Jour le plus pollué
    jour_pollue <- df_s %>%
      group_by(jour_semaine, jour_index) %>%
      summarise(moy = mean(.data[[var]], na.rm = TRUE), .groups = "drop") %>%
      arrange(desc(moy)) %>%
      slice(1)
    
    # Heure la plus polluée
    heure_max <- df_s %>%
      group_by(heure) %>%
      summarise(moy = mean(.data[[var]], na.rm = TRUE), .groups = "drop") %>%
      slice_max(moy, n = 1)
    
    # Heure la plus saine
    heure_min <- df_s %>%
      group_by(heure) %>%
      summarise(moy = mean(.data[[var]], na.rm = TRUE), .groups = "drop") %>%
      slice_min(moy, n = 1)
    
    div(style = "display:flex; gap:16px; margin-bottom:4px;",
        
        # Jour le plus pollué
        div(style = "flex:1; background:white; border-radius:14px; padding:20px 24px;
                   border-left:4px solid #ef4444; box-shadow:0 1px 6px rgba(0,0,0,0.07);",
            div(style = "font-size:11px; color:#9ca3af; text-transform:uppercase;
                     letter-spacing:0.08em; margin-bottom:8px;",
                icon("calendar-xmark", style="margin-right:5px;"), "Jour le plus pollué"),
            div(style = "font-size:26px; font-weight:800; color:#111827;",
                jour_pollue$jour_semaine),
            div(style = "font-size:13px; color:#6b7280; margin-top:4px;",
                paste0("Moyenne : ", round(jour_pollue$moy, 1), " ", input$temp_polluant))
        ),
        
        # Heure la plus polluée
        div(style = "flex:1; background:white; border-radius:14px; padding:20px 24px;
                   border-left:4px solid #f59e0b; box-shadow:0 1px 6px rgba(0,0,0,0.07);",
            div(style = "font-size:11px; color:#9ca3af; text-transform:uppercase;
                     letter-spacing:0.08em; margin-bottom:8px;",
                icon("arrow-trend-up", style="margin-right:5px;"), "Heure la plus polluée"),
            div(style = "font-size:26px; font-weight:800; color:#111827;",
                paste0(heure_max$heure, "h")),
            div(style = "font-size:13px; color:#6b7280; margin-top:4px;",
                paste0("Moyenne : ", round(heure_max$moy, 1), " ", input$temp_polluant))
        ),
        
        # Heure la plus saine
        div(style = "flex:1; background:white; border-radius:14px; padding:20px 24px;
                   border-left:4px solid #22c55e; box-shadow:0 1px 6px rgba(0,0,0,0.07);",
            div(style = "font-size:11px; color:#9ca3af; text-transform:uppercase;
                     letter-spacing:0.08em; margin-bottom:8px;",
                icon("arrow-trend-down", style="margin-right:5px;"), "Heure la plus saine"),
            div(style = "font-size:26px; font-weight:800; color:#111827;",
                paste0(heure_min$heure, "h")),
            div(style = "font-size:13px; color:#6b7280; margin-top:4px;",
                paste0("Moyenne : ", round(heure_min$moy, 1), " ", input$temp_polluant))
        )
    )
  })
  
  # graphique des horaires 
  
  output$temp_plot_horaire <- renderPlot({
    df_h <- temp_df_filtre() %>%
      group_by(heure) %>%
      summarise(
        valeur_moy = mean(.data[[temp_var()]], na.rm = TRUE),
        valeur_min = min(.data[[temp_var()]],  na.rm = TRUE),
        valeur_max = max(.data[[temp_var()]],  na.rm = TRUE),
        .groups = "drop"
      )
    
    couleur_ligne <- switch(input$temp_polluant,
                            "AQI" = "#3b82f6",
                            "CO"  = "#ef4444",
                            "CO2" = "#f59e0b",
                            "NH3" = "#8b5cf6"
    )
    
    ggplot(df_h, aes(x = heure, y = valeur_moy)) +
      geom_ribbon(aes(ymin = valeur_min, ymax = valeur_max),
                  fill = couleur_ligne, alpha = 0.12) +
      geom_line(color = couleur_ligne, linewidth = 1.8) +
      geom_point(aes(color = valeur_moy), size = 3.5, show.legend = FALSE) +
      scale_color_gradient(low = "#22c55e", high = "#ef4444") +
      scale_x_continuous(
        breaks = seq(0, 23, 1),
        labels = paste0(seq(0, 23, 1), "h")
      ) +
      labs(
        x = "Heure de la journée",
        y = temp_label(),
        title = paste0("Évolution de ", temp_label(), " par heure")
      ) +
      theme_minimal() +
      theme(
        plot.title        = element_text(size = 13, face = "bold", color = "#111827"),
        panel.grid.minor  = element_blank(),
        panel.grid.major  = element_line(color = "#f3f4f6"),
        axis.text         = element_text(size = 10, color = "#6b7280"),
        axis.text.x       = element_text(angle = 45, hjust = 1),
        axis.title        = element_text(size = 11, color = "#374151"),
        plot.background   = element_rect(fill = "white", color = NA),
        panel.background  = element_rect(fill = "white", color = NA)
      )
  }, bg = "white")
  
  # graphique par jour 
  
  output$temp_plot_jour <- renderPlot({
    
    polluant_actuel <- input$temp_polluant
    var_actuelle    <- temp_var()
    
    df_j <- temp_df_filtre() %>%
      group_by(jour_semaine, jour_index) %>%
      summarise(
        valeur_moy = round(mean(.data[[var_actuelle]], na.rm = TRUE), 1),
        .groups = "drop"
      ) %>%
      arrange(jour_index) %>%
      mutate(jour_semaine = factor(jour_semaine, levels = unique(jour_semaine)))
    
    val_max <- max(df_j$valeur_moy)
    val_min <- min(df_j$valeur_moy)
    val_moy <- mean(df_j$valeur_moy)
    
    df_j <- df_j %>%
      mutate(couleur = case_when(
        polluant_actuel == "AQI" ~ couleur_aqi(valeur_moy),
        valeur_moy == val_max    ~ "#ef4444",
        valeur_moy == val_min    ~ "#22c55e",
        TRUE                     ~ "#3b82f6"
      ))
    
    ggplot(df_j, aes(x = jour_semaine, y = valeur_moy, fill = couleur)) +
      geom_col(width = 0.55, show.legend = FALSE) +
      geom_text(aes(label = valeur_moy, color = couleur),
                vjust = -0.6, size = 4.2, fontface = "bold",
                show.legend = FALSE) +
      geom_hline(yintercept = val_moy,
                 linetype = "dashed", color = "#9ca3af", linewidth = 0.8) +
      annotate("text", x = 0.6, y = val_moy,
               label = paste0("Moy. ", round(val_moy, 1)),
               color = "#9ca3af", size = 3.2, vjust = -0.5) +
      scale_fill_identity() +
      scale_color_identity() +
      scale_y_continuous(limits = c(0, val_max * 1.25)) +
      labs(x = NULL, y = temp_label(),
           title = paste0(temp_label(), " moyen par jour de semaine")) +
      theme_minimal() +
      theme(
        plot.title         = element_text(size = 13, face = "bold", color = "#111827"),
        panel.grid.minor   = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(color = "#f3f4f6"),
        axis.text.x        = element_text(size = 11, color = "#374151", face = "bold"),
        axis.text.y        = element_text(size = 10, color = "#6b7280"),
        axis.title.y       = element_text(size = 11, color = "#374151"),
        plot.background    = element_rect(fill = "white", color = NA),
        panel.background   = element_rect(fill = "white", color = NA)
      )
  }, bg = "white")
  
  
  } # fin server
