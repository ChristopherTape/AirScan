# AirScan CI — server.R

server <- function(input, output, session) {
  
  
  
  # Moyennes par zone — pré-calculées une fois pour toutes les pages
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
  output$aqi_moyen <- renderText({
    round(mean(df$AQI_calcule, na.rm = TRUE), 1)
  })
  
  # Badge coloré sous l'AQI
  output$aqi_badge <- renderUI({
    val <- mean(df$AQI_calcule, na.rm = TRUE)

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
    zone_max <- stats_zones$zone_campus[which.max(stats_zones$co_moy)]
    label <- gsub("_", " ", zone_max)
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
    zone_min <- stats_zones$zone_campus[which.min(stats_zones$aqi_moy)]
    label <- gsub("_", " ", zone_min)
    tags$span(label)
  })
  
  output$zone_saine_badge <- renderUI({
    aqi_min <- min(stats_zones$aqi_moy)
    tags$span(paste("AQI", aqi_min), class = "badge-bon")
  })
  
  
  
  # Barplot AQI par zone
  output$aqi_barplot <- renderPlot({

    # Couleur par niveau d'AQI
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
    
    ggplot(stats_zones, aes(
      x    = reorder(labels, aqi_moy),
      y    = aqi_moy,
      fill = couleurs
    )) +
      geom_col(width = 0.55, show.legend = FALSE) +
      geom_text(aes(label = aqi_moy),
                hjust = -0.2, size = 3.8,
                color = couleurs, fontface = "bold") +
      scale_fill_identity() +
      scale_y_continuous(limits = c(0, 55)) +
      coord_flip() +
      theme_minimal() +
      theme(
        panel.grid       = element_blank(),
        axis.title       = element_blank(),
        axis.text.x      = element_blank(),
        axis.text.y      = element_text(size = 12, color = "#374151"),
        plot.background  = element_rect(fill = "white", color = NA),
        panel.background = element_rect(fill = "white", color = NA)
      )
  }, bg = "white")
  
  
  
  # ZONE CARDS

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
  
  
  # Correlation
  
  var_labels <- c(
    CO_ppm           = "CO (ppm)",
    CO2_ppm          = "CO2 (ppm)",
    NH3_ppm          = "NH3 (ppm)",
    temperature_C    = "Temperature (°C)",
    humidite_pct     = "Humidite (%)",
    score_vegetation = "Score vegetation"
  )
  
  #  Données filtrées selon les choix de l'utilisateur 
  df_corr <- reactive({
    req(input$corr_zones, input$corr_periodes)
    df %>%
      filter(
        zone_campus     %in% input$corr_zones,
        periode_journee %in% input$corr_periodes
      )
  })
  
  # Variables sélectionnées + AQI_calcule toujours inclus
  vars_selectionnees <- reactive({
    req(input$corr_variables)
    c("AQI_calcule", input$corr_variables)
  })
  
  
  #  Matrice de corrélation 
  output$matrice_correlation <- renderPlot({
    data <- df_corr()
    vars <- vars_selectionnees()
    
    validate(
      need(nrow(data) > 10,
           "Pas assez de données. Sélectionnez plus de zones ou périodes."),
      need(length(vars) >= 2,
           "Sélectionnez au moins une variable en plus de l'AQI.")
    )
    
    mat <- cor(data[, vars], use = "complete.obs")
    
    # Labels lisibles sur la matrice
    colnames(mat) <- rownames(mat) <- c("AQI", var_labels[vars[-1]])
    
    corrplot(
      mat,
      method      = "color",
      type        = "upper",
      order       = "original",
      addCoef.col = "black",
      number.cex  = 0.85,
      tl.col      = "#111827",
      tl.srt      = 45,
      tl.cex      = 0.90,
      cl.cex      = 0.80,
      col         = colorRampPalette(c("#d73027", "#fc8d59", "#fee090",
                                       "white",
                                       "#91cf60", "#1a9850"))(200),
      mar         = c(0, 0, 1, 0)
    )
  })
  
  
  #  Badges de corrélation (panneau statistiques) 
  output$corr_stats_ui <- renderUI({
    data <- df_corr()
    vars <- input$corr_variables
    
    validate(need(nrow(data) > 5, "Données insuffisantes."))
    
    # Calcul des corrélations avec AQI_calcule
    corrs <- sapply(vars, function(v) {
      cor(data$AQI_calcule, data[[v]], use = "complete.obs")
    })
    corrs <- sort(corrs, decreasing = TRUE)
    
    # Classe du badge selon intensité
    badge_class <- function(r) {
      ar <- abs(r)
      if      (ar >= 0.7 && r > 0) "corr-badge badge-forte"
      else if (ar >= 0.7 && r < 0) "corr-badge badge-negative"
      else if (ar >= 0.4)           "corr-badge badge-moderee"
      else                          "corr-badge badge-faible"
    }
    
    badge_text <- function(r) {
      paste0(if (r > 0) "+" else "", round(r, 2))
    }
    
    # Générer les lignes UI
    items <- lapply(names(corrs), function(v) {
      r <- corrs[[v]]
      tags$div(class = "corr-stat-box",
               tags$span(class = "corr-stat-label", var_labels[v]),
               tags$span(class = badge_class(r), badge_text(r))
      )
    })
    
    tagList(items)
  })
  
  
  # Nombre d'observations et zones 
  output$corr_n_obs <- renderText({
    format(nrow(df_corr()), big.mark = " ")
  })
  
  output$corr_n_zones <- renderText({
    length(input$corr_zones)
  })
  
  
  #  Nuage de points AQI vs variable choisie
  output$scatter_aqi <- renderPlot({
    data <- df_corr()
    var  <- input$scatter_var
    
    validate(
      need(nrow(data) > 5, "Données insuffisantes pour le graphique."),
      need(var %in% names(data), "Variable non disponible.")
    )
    
    r_val   <- round(cor(data$AQI_calcule, data[[var]], use = "complete.obs"), 3)
    label_x <- var_labels[var]
    
    ggplot(data, aes_string(x = var, y = "AQI_calcule", color = "zone_campus")) +
      geom_point(alpha = 0.35, size = 1.2) +
      geom_smooth(method = "lm", color = "#3b82f6", se = TRUE,
                  linewidth = 1.2, fill = "#bfdbfe", alpha = 0.25) +
      annotate("text",
               x = -Inf, y = Inf,
               hjust = -0.1, vjust = 1.4,
               label = paste0("r = ", r_val),
               size = 5, fontface = "bold", color = "#1d4ed8") +
      scale_color_manual(
        values = c(
          Parking_Entree = "#ef4444",
          Amphi_Central  = "#f97316",
          Restaurant_U   = "#eab308",
          Cites_Univ     = "#22c55e",
          Zone_Verte     = "#16a34a"
        ),
        labels = c(
          Parking_Entree = "Parking Entree",
          Amphi_Central  = "Amphithéâtres",
          Restaurant_U   = "Restaurant Univ.",
          Cites_Univ     = "Cités Univ.",
          Zone_Verte     = "Zone Verte"
        )
      ) +
      labs(x = label_x, y = "AQI calculé", color = "Zone") +
      theme_minimal(base_size = 13) +
      theme(
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(color = "#f3f4f6"),
        axis.title       = element_text(color = "#374151", size = 12),
        axis.text        = element_text(color = "#6b7280"),
        legend.position  = "right",
        plot.background  = element_blank(),
        panel.background = element_blank()
      )
  })
  
  
  #  Barplot des corrélations 
  output$corr_barplot <- renderPlot({
    data <- df_corr()
    vars <- input$corr_variables
    
    validate(need(nrow(data) > 5 & length(vars) >= 1, "Données insuffisantes."))
    
    corrs <- sapply(vars, function(v) {
      cor(data$AQI_calcule, data[[v]], use = "complete.obs")
    })
    
    df_plot <- data.frame(
      variable    = var_labels[names(corrs)],
      correlation = as.numeric(corrs),
      stringsAsFactors = FALSE
    ) %>% arrange(correlation)
    
    df_plot$variable <- factor(df_plot$variable, levels = df_plot$variable)
    df_plot$couleur  <- ifelse(df_plot$correlation >= 0, "#22c55e", "#ef4444")
    
    ggplot(df_plot, aes(x = variable, y = correlation, fill = couleur)) +
      geom_col(width = 0.6, show.legend = FALSE) +
      geom_hline(yintercept = 0,    color = "#374151", linewidth = 0.6) +
      geom_hline(yintercept =  0.7, linetype = "dashed",
                 color = "#16a34a", linewidth = 0.5, alpha = 0.7) +
      geom_hline(yintercept = -0.7, linetype = "dashed",
                 color = "#dc2626", linewidth = 0.5, alpha = 0.7) +
      geom_text(aes(label = round(correlation, 2),
                    vjust = ifelse(correlation >= 0, -0.4, 1.3)),
                size = 4, fontface = "bold", color = "#111827") +
      scale_fill_identity() +
      scale_y_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.25)) +
      coord_flip() +
      labs(x = NULL, y = "Coefficient de corrélation (r)") +
      theme_minimal(base_size = 13) +
      theme(
        panel.grid.minor   = element_blank(),
        panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(color = "#f3f4f6"),
        axis.text          = element_text(color = "#374151", size = 11),
        axis.title.x       = element_text(color = "#6b7280", size = 11),
        plot.background    = element_blank(),
        panel.background   = element_blank()
      )
  })
  
  
  ### Sante
  
  aqi_couleur <- function(aqi) {
    if      (is.na(aqi))   "#6b7280"
    else if (aqi <= 50)    "#22c55e"
    else if (aqi <= 100)   "#eab308"
    else if (aqi <= 150)   "#f97316"
    else if (aqi <= 200)   "#ef4444"
    else                   "#7c3aed"
  }
  
  heures_par_profil <- c(
    etudiant  = 6,
    personnel = 8,
    riverain  = 12,
    passant   = 1
  )
  
  output$duree_label <- renderText({
    paste0(input$duree_expo, " an", if (input$duree_expo > 1) "s" else "")
  })
  
  output$sante_titre_graphe <- renderUI({
    span(paste0("Risque respiratoire — ", input$duree_expo,
                " an(s) — ", input$profil_expo))
  })
  
  output$plot_risque <- renderPlot({
    h     <- heures_par_profil[input$profil_expo]
    duree <- input$duree_expo
    
    df_zone <- df %>%                          # ← df au lieu de df_raw
      group_by(zone_campus) %>%
      summarise(aqi_moy = mean(AQI_calcule, na.rm = TRUE))
    
    df_zone$risque     <- df_zone$aqi_moy * (h / 24) * duree / 10
    df_zone$zone_label <- gsub("_", " ", df_zone$zone_campus)
    df_zone$zone_label <- factor(df_zone$zone_label,
                                 levels = df_zone$zone_label[order(df_zone$risque)])
    df_zone$couleur    <- sapply(df_zone$aqi_moy, aqi_couleur)
    
    ggplot(df_zone, aes(x = zone_label, y = risque, fill = couleur)) +
      geom_col(width = 0.6, show.legend = FALSE) +
      geom_text(aes(label = round(risque, 1)), hjust = -0.2,
                size = 4, fontface = "bold", color = "#111827") +
      scale_fill_identity() +
      scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
      coord_flip() +
      labs(x = NULL, y = "Score de risque respiratoire") +
      theme_minimal(base_size = 12) +
      theme(
        panel.grid.minor   = element_blank(),
        panel.grid.major.y = element_blank(),
        axis.text          = element_text(color = "#374151"),
        plot.background    = element_blank(),
        panel.background   = element_blank()
      )
  })
  
  #  Interprétation automatique par zone 
  output$sante_interpretation_ui <- renderUI({
    h     <- heures_par_profil[input$profil_expo]
    duree <- input$duree_expo
    
    df_zone <- df %>%
      group_by(zone_campus) %>%
      summarise(aqi_moy = mean(AQI_calcule, na.rm = TRUE)) %>%
      mutate(
        risque     = round(aqi_moy * (h / 24) * duree / 10, 1),
        zone_label = gsub("_", " ", zone_campus)
      ) %>%
      arrange(desc(risque))
    
    # Fonction niveau et couleur selon score
    niveau_info <- function(score) {
      if      (score < 1) list(label = "Faible",     bg = "#dcfce7", col = "#16a34a")
      else if (score < 3) list(label = "Modere",     bg = "#fef9c3", col = "#854d0e")
      else if (score < 5) list(label = "Eleve",      bg = "#ffedd5", col = "#c2410c")
      else                list(label = "Tres eleve", bg = "#fee2e2", col = "#dc2626")
    }
    
    # Générer une ligne par zone
    items <- lapply(1:nrow(df_zone), function(i) {
      z     <- df_zone$zone_label[i]
      score <- df_zone$risque[i]
      info  <- niveau_info(score)
      
      div(style = "display:flex; align-items:center; justify-content:space-between;
                   padding:9px 0; border-bottom:1px solid #f3f4f6;",
          div(
            tags$span(style = "font-size:13px; color:#374151; font-weight:500;", z),
            tags$br(),
            tags$span(style = "font-size:12px; color:#6b7280;",
                      paste0("Score : ", score))
          ),
          tags$span(
            style = paste0("background:", info$bg, "; color:", info$col,
                           "; border-radius:10px; font-size:11px;",
                           " font-weight:600; padding:3px 10px;"),
            info$label
          )
      )
    })
    
    tagList(items)
  })
  
  
  } # fin server
