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
