#AirScan CI — ui.R

dashboardPage(
  
  dashboardHeader(disable = TRUE),
  
  # SIDEBAR
  dashboardSidebar(
    tags$div(
      style = "padding: 20px 16px 10px; display: flex; align-items: center; gap: 12px;",
      tags$div(
        style = "width:36px; height:36px; background:#22c55e; border-radius:8px;
                 display:flex; align-items:center; justify-content:center;",
        icon("wind", style = "color:white; font-size:16px;")
      ),
      tags$div(
        tags$div("AirScan CI",
                 style = "color:white; font-weight:700; font-size:15px; line-height:1.2;"),
        tags$div("UFHB Cocody",
                 style = "color:#9ca3af; font-size:11px;")
      )
    ),
    tags$hr(style = "border-color: #374151; margin: 8px 0;"),
    sidebarMenu(
      id = "menu_actif",
      menuItem("Accueil",       tabName = "accueil",   icon = icon("house")),
      menuItem("Dashboard",     tabName = "dashboard",    icon = icon("chart-bar")),
      menuItem("Carte",         tabName = "carte",        icon = icon("map-pin")),
      menuItem("Temporelle",    tabName = "temporelle",   icon = icon("clock")),
      menuItem("Prediction ML", tabName = "prediction",   icon = icon("brain")),
      menuItem("Correlations",  tabName = "correlations", icon = icon("chart-line")),
      menuItem("Sante",         tabName = "sante",        icon = icon("heart-pulse")),
      menuItem("Balise",        tabName = "balise",       icon = icon("microchip")),
      menuItem("Equipe",        tabName = "equipe",       icon = icon("users"))
    ),
    tags$div(
      style = "position:absolute; bottom:16px; left:0; right:0; text-align:center;
               font-size:11px; color:#6b7280;",
  
    )
  ),
  
  # BODY 
  dashboardBody(
    
    tags$head(
      tags$link(rel = "stylesheet", href = "style.css"),
      tags$link(rel = "stylesheet",
                href = "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"),
      tags$style(HTML("
      html, body, .wrapper, .content-wrapper, .tab-content, .tab-pane {
        height: auto !important;
        min-height: 100vh !important;
        overflow: visible !important;
      }
      .main-sidebar {
        position: fixed !important;
        height: 100vh !important;
      }
  
      /* ── Plein écran quand accueil est actif ── */
      body.page-accueil .main-sidebar        { display: none !important; }
      body.page-accueil .content-wrapper     { margin-left: 0 !important; padding: 0 !important; }
      body.page-accueil .tab-content         { padding: 0 !important; }
      body.page-accueil .wrapper             { overflow: hidden !important; }
      .sidebar-menu li:first-child { display: none !important; }
    ")),
        tags$script(HTML("
      $(document).ready(function() {
  
        function updateLayout() {
          var isAccueil = $('#shiny-tab-accueil').hasClass('active');
          if (isAccueil) {
            $('body').addClass('page-accueil');
          } else {
            $('body').removeClass('page-accueil');
          }
        }
  
        // Vérifier au changement d'onglet
        $(document).on('click', '.sidebar-menu a', function() {
          setTimeout(updateLayout, 150);
        }); 
  
        // Vérifier au démarrage
        setTimeout(updateLayout, 400);
      });
  "))
    ),
    
    tabItems(
      
      
      # PAGE DASHBOARD
      
      tabItem(tabName = "dashboard",
              
              h2("Dashboard", class = "page-title"),
              p("Indicateurs temps reel de la qualite de l'air", class = "page-subtitle"),
              
              # 4 KPI Cards
              fluidRow(
                column(3,
                       div(class = "kpi-card",
                           div(class = "kpi-header", icon("wind"), span("AQI moyen campus")),
                           div(class = "kpi-value", textOutput("aqi_moyen")),
                           div(class = "kpi-badge", uiOutput("aqi_badge"))
                       )
                ),
                column(3,
                       div(class = "kpi-card",
                           div(class = "kpi-header", icon("fire"), span("CO max (ppm)")),
                           div(class = "kpi-value", textOutput("co_max")),
                           div(class = "kpi-badge", uiOutput("co_badge"))
                       )
                ),
                column(3,
                       div(class = "kpi-card",
                           div(class = "kpi-header", icon("cloud"), span("CO2 max (ppm)")),
                           div(class = "kpi-value", textOutput("co2_max")),
                           div(class = "kpi-badge", uiOutput("co2_badge"))
                       )
                ),
                column(3,
                       div(class = "kpi-card",
                           div(class = "kpi-header", icon("leaf"), span("Zone la plus saine")),
                           div(class = "kpi-value kpi-value-sm", uiOutput("zone_saine")),
                           div(class = "kpi-badge", uiOutput("zone_saine_badge"))
                       )
                )
              ),
              
              # Graphique barres
              fluidRow(
                column(12,
                       div(class = "chart-card",
                           div(class = "chart-header",
                               icon("chart-bar"), span("AQI par zone - comparaison")),
                           plotOutput("aqi_barplot", height = "220px")
                       )
                )
              ),
              
              # Zone Cards rangee 1 : Parking / Restau / Amphi 
              fluidRow(
                column(4,
                       div(class = "zone-card",
                           div(class = "zone-card-header",
                               span("Parking Entree"),
                               div(class = "zone-dot dot-warning")
                           ),
                           div(class = "zone-metrics",
                               div(class = "zone-metric",
                                   div(class = "metric-val", textOutput("parking_co")),
                                   div(class = "metric-label", "CO (ppm)")
                               ),
                               div(class = "zone-metric",
                                   div(class = "metric-val", textOutput("parking_co2")),
                                   div(class = "metric-label", "CO2 (ppm)")
                               ),
                               div(class = "zone-metric",
                                   div(class = "metric-val", textOutput("parking_nh3")),
                                   div(class = "metric-label", "NH3 (ppm)")
                               )
                           ),
                           tags$hr(class = "zone-divider"),
                           div(class = "zone-footer",
                               span(textOutput("parking_temp", inline = TRUE)),
                               span(textOutput("parking_hum",  inline = TRUE))
                           )
                       )
                ),
                column(4,
                       div(class = "zone-card",
                           div(class = "zone-card-header",
                               span("Restaurant Universitaire"),
                               div(class = "zone-dot dot-warning")
                           ),
                           div(class = "zone-metrics",
                               div(class = "zone-metric",
                                   div(class = "metric-val", textOutput("restau_co")),
                                   div(class = "metric-label", "CO (ppm)")
                               ),
                               div(class = "zone-metric",
                                   div(class = "metric-val", textOutput("restau_co2")),
                                   div(class = "metric-label", "CO2 (ppm)")
                               ),
                               div(class = "zone-metric",
                                   div(class = "metric-val", textOutput("restau_nh3")),
                                   div(class = "metric-label", "NH3 (ppm)")
                               )
                           ),
                           tags$hr(class = "zone-divider"),
                           div(class = "zone-footer",
                               span(textOutput("restau_temp", inline = TRUE)),
                               span(textOutput("restau_hum",  inline = TRUE))
                           )
                       )
                ),
                column(4,
                       div(class = "zone-card",
                           div(class = "zone-card-header",
                               span("Amphitheatres centraux"),
                               div(class = "zone-dot dot-warning")
                           ),
                           div(class = "zone-metrics",
                               div(class = "zone-metric",
                                   div(class = "metric-val", textOutput("amphi_co")),
                                   div(class = "metric-label", "CO (ppm)")
                               ),
                               div(class = "zone-metric",
                                   div(class = "metric-val", textOutput("amphi_co2")),
                                   div(class = "metric-label", "CO2 (ppm)")
                               ),
                               div(class = "zone-metric",
                                   div(class = "metric-val", textOutput("amphi_nh3")),
                                   div(class = "metric-label", "NH3 (ppm)")
                               )
                           ),
                           tags$hr(class = "zone-divider"),
                           div(class = "zone-footer",
                               span(textOutput("amphi_temp", inline = TRUE)),
                               span(textOutput("amphi_hum",  inline = TRUE))
                           )
                       )
                )
              ),
              
              # Zone Cards rangee 2 : Cites / Zone Verte
              fluidRow(
                column(4,
                       div(class = "zone-card",
                           div(class = "zone-card-header",
                               span("Cites Universitaires"),
                               div(class = "zone-dot dot-success")
                           ),
                           div(class = "zone-metrics",
                               div(class = "zone-metric",
                                   div(class = "metric-val", textOutput("cites_co")),
                                   div(class = "metric-label", "CO (ppm)")
                               ),
                               div(class = "zone-metric",
                                   div(class = "metric-val", textOutput("cites_co2")),
                                   div(class = "metric-label", "CO2 (ppm)")
                               ),
                               div(class = "zone-metric",
                                   div(class = "metric-val", textOutput("cites_nh3")),
                                   div(class = "metric-label", "NH3 (ppm)")
                               )
                           ),
                           tags$hr(class = "zone-divider"),
                           div(class = "zone-footer",
                               span(textOutput("cites_temp", inline = TRUE)),
                               span(textOutput("cites_hum",  inline = TRUE))
                           )
                       )
                ),
                column(4,
                       div(class = "zone-card",
                           div(class = "zone-card-header",
                               span("Zone Verte"),
                               div(class = "zone-dot dot-success")
                           ),
                           div(class = "zone-metrics",
                               div(class = "zone-metric",
                                   div(class = "metric-val", textOutput("verte_co")),
                                   div(class = "metric-label", "CO (ppm)")
                               ),
                               div(class = "zone-metric",
                                   div(class = "metric-val", textOutput("verte_co2")),
                                   div(class = "metric-label", "CO2 (ppm)")
                               ),
                               div(class = "zone-metric",
                                   div(class = "metric-val", textOutput("verte_nh3")),
                                   div(class = "metric-label", "NH3 (ppm)")
                               )
                           ),
                           tags$hr(class = "zone-divider"),
                           div(class = "zone-footer",
                               span(textOutput("verte_temp", inline = TRUE)),
                               span(textOutput("verte_hum",  inline = TRUE))
                           )
                       )
                ),
                column(4)
              )
              
      ), # fin tabItem dashboard
      
      
      # AUTRES PAGES
    
      tabItem(tabName = "accueil",
              tags$iframe(
                src = "accueil.html",
                style = "width:100%; height:100vh; border:none; display:block;",
                scrolling = "yes"
              )
      ),
      
      tabItem(tabName = "carte",
              h2("Carte interactive", class = "page-title"),
              p("Heatmap du campus UFHB — cliquez sur une zone pour les détails", class = "page-subtile"),
              
              # Légende
              div(style = "display:flex; align-items:center; gap:18px; margin-bottom:12px; flex-wrap:wrap;",
                  tags$b(style = "font-size:13px; color:#374151;", "Niveau AQI :"),
                  div(style = "display:flex; align-items:center; gap:6px;",
                      div(style = "width:14px; height:14px; border-radius:50%; background:#22c55e;"),
                      span(style = "font-size:13px; color:#374151;", "Bon (< 20)")),
                  div(style = "display:flex; align-items:center; gap:6px;",
                      div(style = "width:14px; height:14px; border-radius:50%; background:#f59e0b;"),
                      span(style = "font-size:13px; color:#374151;", "Modéré (20-40)")),
                  div(style = "display:flex; align-items:center; gap:6px;",
                      div(style = "width:14px; height:14px; border-radius:50%; background:#ef4444;"),
                      span(style = "font-size:13px; color:#374151;", "Mauvais (40-60)")),
                  div(style = "display:flex; align-items:center; gap:6px;",
                      div(style = "width:14px; height:14px; border-radius:50%; background:#9d174d;"),
                      span(style = "font-size:13px; color:#374151;", "Dangereux (> 60)"))
              ),
      fluidRow(
        column(8,
              div(class = "chart-card", style = "padding: 0; overflow: hidden;",
                  leafletOutput("carte_campus", height = "500px")
              )
      ),
      column(4,
             div(class = "chart-card",
                 div(class = "chart-header", icon("map-pin"), span("Détail de la zone")),
                 uiOutput("carte_detail_zone")
             )
      )
      ),
      
     
      ),
      
      tabItem(tabName = "temporelle",
              
              h2("Analyse temporelle", class = "page-title"),
              p("Évolution de la qualité de l'air par zone, polluant et période", class = "page-subtitle"),
              
              # Filtres
              fluidRow(
                column(4,
                       div(class = "chart-card",
                           div(class = "chart-header", icon("map-pin"), span("Zone")),
                           selectInput("temp_zone", label = NULL,
                                       choices = c(
                                         "Toutes les zones" = "toutes",
                                         "Parking Entrée"   = "Parking_Entree",
                                         "Restaurant U"     = "Restaurant_U",
                                         "Amphithéâtres"    = "Amphi_Central",
                                         "Cités Univ."      = "Cites_Univ",
                                         "Zone Verte"       = "Zone_Verte"
                                       ),
                                       selected = "toutes", width = "100%")
                       )
                ),
                column(4,
                       div(class = "chart-card",
                           div(class = "chart-header", icon("flask"), span("Polluant")),
                           selectInput("temp_polluant", label = NULL,
                                       choices = c("AQI", "CO", "CO2", "NH3"),
                                       selected = "AQI", width = "100%")
                       )
                ),
                column(4,
                       div(class = "chart-card",
                           div(class = "chart-header", icon("calendar"), span("Période")),
                           selectInput("temp_periode", label = NULL,
                                       choices = c("Tous" = "tous", "Semaine" = "semaine", "Weekend" = "weekend"),
                                       selected = "tous", width = "100%")
                       )
                )
              ),
              
              # KPIs
              fluidRow(
                column(12,
                       uiOutput("temp_kpis")
                )
              ),
              
              # Courbe horaire
              fluidRow(
                column(12,
                       div(class = "chart-card",
                           plotOutput("temp_plot_horaire", height = "300px")
                       )
                )
              ),
              
              # Barplot jour
              fluidRow(
                column(12,
                       div(class = "chart-card",
                           plotOutput("temp_plot_jour", height = "280px")
                       )
                )
              )
              
      ), 
      
      
      tabItem(tabName = "prediction",
              
              h2("Prédiction ML", class = "page-title"),
              p("Prédiction de l'AQI par Random Forest selon les conditions choisies", class = "page-subtitle"),
              
              fluidRow(
                # Filtres
                column(4,
                       div(class = "chart-card",
                           div(class = "chart-header", icon("sliders"), span("Paramètres de prédiction")),
                           selectInput("pred_zone", "Zone",
                                       choices = c(
                                         "Amphithéâtres"  = "Amphi_Central",
                                         "Parking Entrée" = "Parking_Entree",
                                         "Restaurant U"   = "Restaurant_U",
                                         "Cités Univ."    = "Cites_Univ",
                                         "Zone Verte"     = "Zone_Verte"
                                       ), width = "100%"),
                           sliderInput("pred_heure", "Heure de la journée",
                                       min = 0, max = 23, value = 12, step = 1, width = "100%"),
                           selectInput("pred_jour", "Jour de la semaine",
                                       choices = c(
                                         "Lundi"    = 1,
                                         "Mardi"    = 2,
                                         "Mercredi" = 3,
                                         "Jeudi"    = 4,
                                         "Vendredi" = 5,
                                         "Samedi"   = 6,
                                         "Dimanche" = 7
                                       ),
                                       selected = 1, width = "100%"
                           ),
                           sliderInput("pred_temp", "Température (°C)",
                                       min = 20, max = 40, value = 28, step = 0.5, width = "100%"),
                           sliderInput("pred_hum", "Humidité (%)",
                                       min = 30, max = 100, value = 70, step = 1, width = "100%")
                       )
                ),
                
                # Résultat + courbe 24h
                column(8,
                       div(class = "chart-card",
                           div(class = "chart-header", icon("brain"), span("Résultat de la prédiction")),
                           uiOutput("pred_result_card")
                       ),
                       br(),
                       div(class = "chart-card",
                           plotOutput("pred_courbe_24h", height = "260px")
                       )
                )
              ),
              
              fluidRow(
                column(6,
                       div(class = "chart-card",
                           plotOutput("pred_compare_plot", height = "260px")
                       )
                ),
                column(6,
                       div(class = "chart-card",
                           plotOutput("pred_importance_plot", height = "260px")
                       )
                )
              ),
              
              fluidRow(
                column(12,
                       div(class = "chart-card",
                           div(style = "display:flex; gap:40px; align-items:center; padding:8px 0;",
                               div(
                                 div(style = "font-size:11px; color:#9ca3af; text-transform:uppercase;
                         letter-spacing:0.08em;", "Performance du modèle"),
                                 div(style = "font-size:22px; font-weight:800; color:#1d4ed8;",
                                     textOutput("rf_rsq")),
                                 div(style = "font-size:22px; font-weight:800; color:#7c3aed;",
                                     textOutput("rf_rmse"))
                               ),
                               div(style = "font-size:12px; color:#6b7280; max-width:400px;",
                                   "Le modèle Random Forest a été entraîné
             avec 100 arbres de décision. Un R² proche de 1 indique
             une excellente capacité prédictive."
                               )
                           )
                       )
                )
              )
              
      ), # fin prediction
      
      
      
      
      tabItem(tabName = "correlations",
              h2("Correlations", class = "page-title"),
              p("Matrice de corrélation"),
              
              fluidRow(
                
                # Filtre zones
                column(4,
                       div(class = "corr-filter-card",
                           div(class = "chart-header",
                               icon("filter"), span("Filtrer par zone")),
                           checkboxGroupInput(
                             inputId  = "corr_zones",
                             label    = NULL,
                             choices  = c(
                               "Parking Entree"        = "Parking_Entree",
                               "Amphitheatres"         = "Amphi_Central",
                               "Restaurant Univ."      = "Restaurant_U",
                               "Cites Universitaires"  = "Cites_Univ",
                               "Zone Verte"            = "Zone_Verte"
                             ),
                             selected = c("Parking_Entree", "Amphi_Central",
                                          "Restaurant_U", "Cites_Univ", "Zone_Verte")
                           )
                       )
                ),
                
                # Filtre periode
                column(4,
                       div(class = "corr-filter-card",
                           div(class = "chart-header",
                               icon("clock"), span("Filtrer par periode")),
                           checkboxGroupInput(
                             inputId  = "corr_periodes",
                             label    = NULL,
                             choices  = c(
                               "Matin pointe"      = "Matin pointe",
                               "Matinee cours"     = "Matinée cours",
                               "Pause dejeuner"    = "Pause déjeuner",
                               "Apres-midi cours"  = "Après-midi cours",
                               "Soiree"            = "Soirée",
                               "Nuit"              = "Nuit"
                             ),
                             selected = c("Matin pointe", "Matinée cours",
                                          "Pause déjeuner", "Après-midi cours",
                                          "Soirée", "Nuit")
                           )
                       )
                ),
                
                # Variables a inclure
                column(4,
                       div(class = "corr-filter-card",
                           div(class = "chart-header",
                               icon("table-columns"), span("Variables a analyser")),
                           checkboxGroupInput(
                             inputId  = "corr_variables",
                             label    = NULL,
                             choices  = c(
                               "CO (ppm)"           = "CO_ppm",
                               "CO2 (ppm)"          = "CO2_ppm",
                               "NH3 (ppm)"          = "NH3_ppm",
                               "Temperature (°C)"   = "temperature_C",
                               "Humidite (%)"       = "humidite_pct",
                               "Score vegetation"   = "score_vegetation"
                             ),
                             selected = c("CO_ppm", "CO2_ppm", "NH3_ppm",
                                          "temperature_C", "humidite_pct",
                                          "score_vegetation")
                           )
                       )
                )
              ),
              
              #  Ligne 2 : Matrice + Statistiques
              fluidRow(
                
                # Matrice de correlation (grande)
                column(8,
                       div(class = "chart-card",
                           div(class = "chart-header",
                               icon("grid"), span("Matrice de correlation avec AQI_calcule")),
                           
                           # Legende couleurs
                           div(style = "display:flex; gap:16px; flex-wrap:wrap; margin-bottom:12px;",
                               div(class = "corr-legend-item",
                                   div(class = "corr-legend-dot",
                                       style = "background:#1a9850;"),
                                   span("Correlation positive forte")
                               ),
                               div(class = "corr-legend-item",
                                   div(class = "corr-legend-dot",
                                       style = "background:#91cf60;"),
                                   span("Positive moderee")
                               ),
                               div(class = "corr-legend-item",
                                   div(class = "corr-legend-dot",
                                       style = "background:#d73027;"),
                                   span("Negative forte")
                               ),
                               div(class = "corr-legend-item",
                                   div(class = "corr-legend-dot",
                                       style = "background:#fc8d59;"),
                                   span("Negative moderee")
                               )
                           ),
                           
                           plotOutput("matrice_correlation", height = "420px")
                       )
                ),
                
                # Panneau statistiques
                column(4,
                       
                       # KPI correlations cles
                       div(class = "chart-card", style = "margin-bottom:16px;",
                           div(class = "chart-header",
                               icon("star"), span("Correlations cles avec AQI")),
                           
                           uiOutput("corr_stats_ui")
                       ),
                       
                       # Nombre d'observations
                       div(class = "zone-card",
                           div(class = "chart-header",
                               icon("database"), span("Donnees utilisees")),
                           div(class = "corr-stat-box",
                               span(class = "corr-stat-label", "Observations"),
                               span(class = "corr-stat-value", textOutput("corr_n_obs", inline = TRUE))
                           ),
                           div(class = "corr-stat-box",
                               span(class = "corr-stat-label", "Zones selectionnees"),
                               span(class = "corr-stat-value", textOutput("corr_n_zones", inline = TRUE))
                           ),
                           div(class = "corr-stat-box",
                               span(class = "corr-stat-label", "Methode"),
                               span(class = "corr-stat-value", "Pearson")
                           )
                       )
                )
              ),
              
              #  Ligne 3 : Scatterplots 
              fluidRow(
                column(12,
                       div(class = "chart-card",
                           div(class = "chart-header",
                               icon("circle-dot"),
                               span("Nuages de points — AQI vs variable selectionnee")),
                           
                           # Selecteur variable X
                           div(style = "margin-bottom:12px;",
                               selectInput(
                                 inputId = "scatter_var",
                                 label   = "Variable en abscisse :",
                                 choices = c(
                                   "CO (ppm)"          = "CO_ppm",
                                   "CO2 (ppm)"         = "CO2_ppm",
                                   "NH3 (ppm)"         = "NH3_ppm",
                                   "Temperature (°C)"  = "temperature_C",
                                   "Humidite (%)"      = "humidite_pct",
                                   "Score vegetation"  = "score_vegetation"
                                 ),
                                 selected = "CO_ppm",
                                 width    = "260px"
                               )
                           ),
                           
                           plotOutput("scatter_aqi", height = "340px")
                       )
                )
              ),
              
              #  Ligne 4 : Barplot correlations + interpretation 
              fluidRow(
                
                # Barplot des correlations
                column(12,
                       div(class = "chart-card",
                           div(class = "chart-header",
                               icon("chart-bar"),
                               span("Intensite des correlations avec AQI_calcule")),
                           plotOutput("corr_barplot", height = "280px")
                       )
                ),
                
                # Note interpretative
                column(5,
                       div(class = "chart-card",
                           div(class = "chart-header",
                               icon("book-open"), span("Interpretation")),
                           
                           tags$p(style = "font-size:13px; color:#374151; line-height:1.7; margin-bottom:12px;",
                                  tags$strong("CO et CO2"), " sont les principaux determinants de l'AQI
                   (r > 0.90). C'est attendu : l'AQI est calcule a partir de
                   ces concentrations."),
                           
                           tags$p(style = "font-size:13px; color:#374151; line-height:1.7; margin-bottom:12px;",
                                  tags$strong("NH3"), " (ammoniac) contribue fortement (r = 0.76),
                   probablement lie au trafic, aux dechets organiques et
                   aux zones de restauration."),
                           
                           tags$p(style = "font-size:13px; color:#374151; line-height:1.7; margin-bottom:12px;",
                                  tags$strong("La vegetation"), " reduit l'AQI (r = -0.44) :
                   les zones arborees du campus filtrent naturellement
                   les polluants."),
                           
                           tags$p(style = "font-size:13px; color:#374151; line-height:1.7; margin:0;",
                                  tags$strong("L'humidite"), " a un effet negatif sur l'AQI (r = -0.38) :
                   l'humidite capte les particules et diminue la pollution
                   atmospherique.")
                       )
                )
              ),
              
              #  Note methodologique 
              fluidRow(
                column(12,
                       div(style = "background:#eff6ff; border:1px solid #bfdbfe;
                               border-radius:8px; padding:14px 16px; margin-bottom:16px;",
                           tags$p(style = "font-size:13px; color:#374151; margin:0;",
                                  icon("circle-info", style = "color:#3b82f6;"),
                                  tags$strong(" Methode :"),
                                  " Coefficient de correlation de Pearson (r). Valeurs entre -1 et +1.
                   |r| > 0.7 = forte, 0.4-0.7 = moderee, < 0.4 = faible.
                   Les donnees brutes ADC (brut_MQ135, brut_MQ7) sont exclues
                   car elles sont la source directe des ppm et introduiraient
                   une redondance artificielle."
                           )
                       )
                )
              )
              
              
      ), # fin correlations
    
      
      tabItem(tabName = "sante",
              h2("Impact sante", class = "page-title"),
              p("Impact de la qualié de l'air sur la santé"),
              
              fluidRow(
                column(8,
                       div(class = "chart-card",
                           div(class = "chart-header",
                               icon("lungs"), uiOutput("sante_titre_graphe")),
                           plotOutput("plot_risque", height = "320px")
                       )
                ),
                column(4,
                       div(class = "zone-card", style = "margin-bottom:16px;",
                           div(class = "chart-header", icon("sliders"), span("Param\u00e8tres")),
                           div(style = "margin-top:12px;",
                               div(style = "display:flex; justify-content:space-between; margin-bottom:6px;",
                                   tags$span(style = "font-size:13px; color:#374151;", "Dur\u00e9e d'exposition"),
                                   tags$strong(style = "font-size:13px; color:#111827;",
                                               textOutput("duree_label", inline = TRUE))
                               ),
                               sliderInput("duree_expo", label = NULL,
                                           min = 1, max = 10, value = 4, step = 1,
                                           width = "100%", post = " ans"),
                               div(style = "display:flex; justify-content:space-between;
                             font-size:11px; color:#6b7280; margin-top:-8px; margin-bottom:16px;",
                                   tags$span("1 an"), tags$span("10 ans")),
                               tags$p(style = "font-size:13px; color:#374151; margin:0 0 6px;", "Profil"),
                               selectInput("profil_expo", label = NULL,
                                           choices = c(
                                             "\u00c9tudiant (6h/jour)"  = "etudiant",
                                             "Personnel (8h/jour)"      = "personnel",
                                             "Riverain (12h/jour)"      = "riverain",
                                             "Passant (1h/jour)"        = "passant"
                                           ),
                                           selected = "etudiant", width = "100%")
                           )
                       ),
                       div(class = "zone-card",
                           div(class = "chart-header",
                               icon("triangle-exclamation", style = "color:#f59e0b;"),
                               span("Seuils OMS")),
                           div(style = "margin-top:12px;",
                               div(style = "display:flex; justify-content:space-between;
                             align-items:center; padding:8px 0; border-bottom:1px solid #f3f4f6;",
                                   tags$span(style = "font-size:13px; color:#374151;", "CO max (8h)"),
                                   tags$span(style = "background:#fef2f2; color:#ef4444; border-radius:12px;
                                     font-size:11px; font-weight:600; padding:2px 8px;", "9 ppm")
                               ),
                               div(style = "display:flex; justify-content:space-between;
                             align-items:center; padding:8px 0; border-bottom:1px solid #f3f4f6;",
                                   tags$span(style = "font-size:13px; color:#374151;", "CO\u2082 cognitif"),
                                   tags$span(style = "background:#fff7ed; color:#f59e0b; border-radius:12px;
                                     font-size:11px; font-weight:600; padding:2px 8px;", "1000 ppm")
                               ),
                               div(style = "display:flex; justify-content:space-between;
                             align-items:center; padding:8px 0;",
                                   tags$span(style = "font-size:13px; color:#374151;", "NH\u2083 max (8h)"),
                                   tags$span(style = "background:#eff6ff; color:#3b82f6; border-radius:12px;
                                     font-size:11px; font-weight:600; padding:2px 8px;", "25 ppm")
                               )
                           )
                       )
                )
              ),
              
              # Ligne interprétation des scores 
              fluidRow(
                
                # Échelle d'interprétation
                column(6,
                       div(class = "chart-card",
                           div(class = "chart-header",
                               icon("scale-balanced"), span("Echelle d'interprétation du score")),
                           
                           # Ligne 0-1
                           div(style = "display:flex; align-items:center; gap:12px;
                                        padding:10px 0; border-bottom:1px solid #f3f4f6;",
                               div(style = "width:14px; height:14px; border-radius:50%;
                                            background:#22c55e; flex-shrink:0;"),
                               div(style = "flex:1;",
                                   tags$span(style = "font-size:13px; font-weight:600; color:#111827;",
                                             "Score 0 – 1"),
                                   tags$span(style = "font-size:12px; color:#6b7280; margin-left:8px;",
                                             "Risque faible")
                               ),
                               tags$span(style = "background:#dcfce7; color:#16a34a; border-radius:10px;
                                                   font-size:11px; font-weight:600; padding:2px 10px;",
                                         "Faible")
                           ),
                           
                           div(style = "display:flex; align-items:center; gap:12px;
                                        padding:10px 0; border-bottom:1px solid #f3f4f6;",
                               div(style = "width:14px; height:14px; border-radius:50%;
                                            background:#eab308; flex-shrink:0;"),
                               div(style = "flex:1;",
                                   tags$span(style = "font-size:13px; font-weight:600; color:#111827;",
                                             "Score 1 – 3"),
                                   tags$span(style = "font-size:12px; color:#6b7280; margin-left:8px;",
                                             "Risque modéré")
                               ),
                               tags$span(style = "background:#fef9c3; color:#854d0e; border-radius:10px;
                                                   font-size:11px; font-weight:600; padding:2px 10px;",
                                         "Modéré")
                           ),
                           
                           div(style = "display:flex; align-items:center; gap:12px;
                                        padding:10px 0; border-bottom:1px solid #f3f4f6;",
                               div(style = "width:14px; height:14px; border-radius:50%;
                                            background:#f97316; flex-shrink:0;"),
                               div(style = "flex:1;",
                                   tags$span(style = "font-size:13px; font-weight:600; color:#111827;",
                                             "Score 3 – 5"),
                                   tags$span(style = "font-size:12px; color:#6b7280; margin-left:8px;",
                                             "Risque élevé")
                               ),
                               tags$span(style = "background:#ffedd5; color:#c2410c; border-radius:10px;
                                                   font-size:11px; font-weight:600; padding:2px 10px;",
                                         "Elevé")
                           ),
                           
                           div(style = "display:flex; align-items:center; gap:12px; padding:10px 0;",
                               div(style = "width:14px; height:14px; border-radius:50%;
                                            background:#ef4444; flex-shrink:0;"),
                               div(style = "flex:1;",
                                   tags$span(style = "font-size:13px; font-weight:600; color:#111827;",
                                             "Score 5+"),
                                   tags$span(style = "font-size:12px; color:#6b7280; margin-left:8px;",
                                             "Risque très élevé")
                               ),
                               tags$span(style = "background:#fee2e2; color:#dc2626; border-radius:10px;
                                                   font-size:11px; font-weight:600; padding:2px 10px;",
                                         "Très élevé")
                           )
                       )
                ),
                
                # Message
                column(6,
                       div(class = "chart-card",
                           div(class = "chart-header",
                               icon("message-circle"), span("Analyse automatique par zone")),
                           uiOutput("sante_interpretation_ui")
                       )
                )
              ),
              
              fluidRow(
                column(12,
                       div(style = "background:#f0fdf4; border:1px solid #bbf7d0; border-radius:8px;
                         padding:14px 16px; margin-bottom:16px;",
                           tags$p(style = "font-size:13px; color:#374151; margin:0;",
                                  icon("circle-info"), tags$strong(" Note m\u00e9thodologique :"),
                                  " Le risque respiratoire est calcul\u00e9 \u00e0 partir de l'AQI moyen de chaque zone,
                  pond\u00e9r\u00e9 par la dur\u00e9e d'exposition et le profil utilisateur.
                  Ce mod\u00e8le simplifi\u00e9 est bas\u00e9 sur les recommandations de l'OMS et doit
                  \u00eatre interpr\u00e9t\u00e9 comme une indication, non un diagnostic m\u00e9dical.")
                       )
                )
              ),
              
              fluidRow(
                column(12,
                       div(class = "chart-card",
                           tags$p(style = "font-size:15px; font-weight:700; color:#111827;
                              margin:0 0 20px;", "Récommandations"),
                           div(style = "display:flex; gap:40px; flex-wrap:wrap;",
                               div(style = "flex:1; min-width:240px;",
                                   tags$p(style = "font-size:13px; font-weight:700; color:#111827;
                                  margin:0 0 12px;", "Zones \u00e0 \u00e9viter"),
                                   div(style = "display:flex; align-items:flex-start; gap:8px; margin-bottom:10px;",
                                       tags$span(style = "width:8px; height:8px; min-width:8px; background:#ef4444;
                                       border-radius:50%; margin-top:4px; display:inline-block;"),
                                       tags$span(style = "font-size:13px; color:#374151;",
                                                 "Limiter l'exposition au Parking aux heures de pointe")
                                   ),
                                   div(style = "display:flex; align-items:flex-start; gap:8px;",
                                       tags$span(style = "width:8px; height:8px; min-width:8px; background:#f59e0b;
                                       border-radius:50%; margin-top:4px; display:inline-block;"),
                                       tags$span(style = "font-size:13px; color:#374151;",
                                                 "A\u00e9rer les amphith\u00e9\u00e2tres pendant les pauses")
                                   )
                               ),
                               div(style = "flex:1; min-width:240px;",
                                   tags$p(style = "font-size:13px; font-weight:700; color:#111827;
                                  margin:0 0 12px;", "Zones recommand\u00e9es"),
                                   div(style = "display:flex; align-items:flex-start; gap:8px; margin-bottom:10px;",
                                       tags$span(style = "width:8px; height:8px; min-width:8px; background:#22c55e;
                                       border-radius:50%; margin-top:4px; display:inline-block;"),
                                       tags$span(style = "font-size:13px; color:#374151;",
                                                 "Privil\u00e9gier la Zone Verte pour les activit\u00e9s ext\u00e9rieures")
                                   ),
                                   div(style = "display:flex; align-items:flex-start; gap:8px;",
                                       tags$span(style = "width:8px; height:8px; min-width:8px; background:#22c55e;
                                       border-radius:50%; margin-top:4px; display:inline-block;"),
                                       tags$span(style = "font-size:13px; color:#374151;",
                                                 "Les Cit\u00e9s offrent une bonne qualit\u00e9 d'air r\u00e9sidentielle")
                                   )
                               )
                           )
                       )
                )
              )
      ), # fin sante
      
      tabItem(tabName = "balise",

              h2("La Balise AirScan", class = "page-title"),
              p("Dispositif de mesure concu et assemble par l'equipe — collecte, geolocalise et transmet les donnees en temps reel", class = "page-subtitle"),

              # ── Photos ──────────────────────────────────────────────
              fluidRow(
                column(6,
                       div(class = "chart-card", style = "padding:12px;",
                           tags$img(src = "B1.jpeg",
                                    style = "width:100%; border-radius:8px; object-fit:cover; max-height:340px;",
                                    alt  = "Balise AirScan — vue dessus"),
                           tags$p(style = "font-size:12px; color:#6b7280; text-align:center; margin:8px 0 0;",
                                  "Vue d'ensemble — Arduino Mega, SIM900, GPS et capteurs MQ")
                       )
                ),
                column(6,
                       div(class = "chart-card", style = "padding:12px;",
                           tags$img(src = "B2.jpeg",
                                    style = "width:100%; border-radius:8px; object-fit:cover; max-height:340px;",
                                    alt  = "Balise AirScan — vue capteurs"),
                           tags$p(style = "font-size:12px; color:#6b7280; text-align:center; margin:8px 0 0;",
                                  "Detail capteurs — MQ-135, MQ-7 et module GPS NEO-6M")
                       )
                )
              ),

              # ── Flux de données ─────────────────────────────────────
              fluidRow(
                column(12,
                       div(class = "chart-card",
                           div(class = "chart-header", icon("route"), span("Architecture du systeme de collecte")),

                           div(style = "display:flex; align-items:center; justify-content:center;
                                        gap:0; flex-wrap:wrap; padding:8px 0 16px;",

                               # Etape 1 — Balise
                               div(style = "display:flex; flex-direction:column; align-items:center;
                                            background:#f0fdf4; border:1px solid #bbf7d0;
                                            border-radius:12px; padding:16px 20px; min-width:130px; text-align:center;",
                                   icon("microchip", style = "font-size:22px; color:#16a34a; margin-bottom:8px;"),
                                   tags$b(style = "font-size:13px; color:#111827;", "Balise"),
                                   tags$span(style = "font-size:11px; color:#6b7280; margin-top:4px;",
                                             "Arduino Mega"),
                                   tags$span(style = "font-size:11px; color:#6b7280;",
                                             "Capteurs MQ + GPS + BMP180")
                               ),

                               # Fleche
                               div(style = "padding:0 10px; font-size:22px; color:#9ca3af;", HTML("&rarr;")),

                               # Etape 2 — SIM900
                               div(style = "display:flex; flex-direction:column; align-items:center;
                                            background:#eff6ff; border:1px solid #bfdbfe;
                                            border-radius:12px; padding:16px 20px; min-width:130px; text-align:center;",
                                   icon("signal", style = "font-size:22px; color:#2563eb; margin-bottom:8px;"),
                                   tags$b(style = "font-size:13px; color:#111827;", "SIM900"),
                                   tags$span(style = "font-size:11px; color:#6b7280; margin-top:4px;",
                                             "Transmission GPRS"),
                                   tags$span(style = "font-size:11px; color:#6b7280;",
                                             "HTTP POST toutes les 5 min")
                               ),

                               div(style = "padding:0 10px; font-size:22px; color:#9ca3af;", HTML("&rarr;")),

                               # Etape 3 — Serveur
                               div(style = "display:flex; flex-direction:column; align-items:center;
                                            background:#fff7ed; border:1px solid #fed7aa;
                                            border-radius:12px; padding:16px 20px; min-width:130px; text-align:center;",
                                   icon("server", style = "font-size:22px; color:#ea580c; margin-bottom:8px;"),
                                   tags$b(style = "font-size:13px; color:#111827;", "Serveur"),
                                   tags$span(style = "font-size:11px; color:#6b7280; margin-top:4px;",
                                             "Reception + enrichissement"),
                                   tags$span(style = "font-size:11px; color:#6b7280;",
                                             "Appel API Open-Meteo")
                               ),

                               div(style = "padding:0 10px; font-size:22px; color:#9ca3af;", HTML("&rarr;")),

                               # Etape 4 — CSV
                               div(style = "display:flex; flex-direction:column; align-items:center;
                                            background:#fdf4ff; border:1px solid #e9d5ff;
                                            border-radius:12px; padding:16px 20px; min-width:130px; text-align:center;",
                                   icon("file-csv", style = "font-size:22px; color:#7c3aed; margin-bottom:8px;"),
                                   tags$b(style = "font-size:13px; color:#111827;", "Fichier CSV"),
                                   tags$span(style = "font-size:11px; color:#6b7280; margin-top:4px;",
                                             "Stockage persistant"),
                                   tags$span(style = "font-size:11px; color:#6b7280;",
                                             "airscan_data_r.csv")
                               ),

                               div(style = "padding:0 10px; font-size:22px; color:#9ca3af;", HTML("&rarr;")),

                               # Etape 5 — Dashboard
                               div(style = "display:flex; flex-direction:column; align-items:center;
                                            background:#ecfdf5; border:2px solid #22c55e;
                                            border-radius:12px; padding:16px 20px; min-width:130px; text-align:center;",
                                   icon("chart-bar", style = "font-size:22px; color:#16a34a; margin-bottom:8px;"),
                                   tags$b(style = "font-size:13px; color:#111827;", "Dashboard"),
                                   tags$span(style = "font-size:11px; color:#6b7280; margin-top:4px;",
                                             "Visualisation"),
                                   tags$span(style = "font-size:11px; color:#6b7280;",
                                             "AirScan CI")
                               )
                           )
                       )
                )
              ),

              # Composants 
              fluidRow(
                column(12,
                       tags$h4(style = "font-size:16px; font-weight:700; color:#111827;
                                        margin:0 0 14px 0;",
                               icon("puzzle-piece", style="margin-right:8px; color:#6b7280;"),
                               "Composants de la balise")
                )
              ),

              fluidRow(

                # Arduino Mega
                column(4,
                       div(class = "zone-card",
                           div(style = "display:flex; align-items:flex-start; gap:14px;",
                               div(style = "width:44px; height:44px; border-radius:10px; background:#dbeafe;
                                            display:flex; align-items:center; justify-content:center; flex-shrink:0;",
                                   icon("microchip", style = "color:#2563eb; font-size:18px;")),
                               div(
                                 tags$p(style = "font-size:14px; font-weight:700; color:#111827; margin:0 0 4px;",
                                        "Arduino Mega 2560"),
                                 tags$p(style = "font-size:12px; color:#374151; line-height:1.6; margin:0;",
                                        "Cerveau de la balise. Lit les capteurs via ses entrees analogiques et ses ports serie,
                                         calcule l'AQI, puis orchestre l'envoi des donnees via le module SIM900.
                                         Son grand nombre de pins (54 num. / 16 analogiques) permet de connecter
                                         simultanement tous les peripheriques.")
                               )
                           )
                       )
                ),

                # MQ-135
                column(4,
                       div(class = "zone-card",
                           div(style = "display:flex; align-items:flex-start; gap:14px;",
                               div(style = "width:44px; height:44px; border-radius:10px; background:#dcfce7;
                                            display:flex; align-items:center; justify-content:center; flex-shrink:0;",
                                   icon("wind", style = "color:#16a34a; font-size:18px;")),
                               div(
                                 tags$p(style = "font-size:14px; font-weight:700; color:#111827; margin:0 0 4px;",
                                        "Capteur MQ-135"),
                                 tags$p(style = "font-size:12px; color:#374151; line-height:1.6; margin:0;",
                                        "Mesure le CO₂ (dioxyde de carbone) et le NH₃ (ammoniac).
                                         Fonctionne par variation de resistance d'un element semi-conducteur chauffe :
                                         plus la concentration en gaz est elevee, plus la resistance baisse.
                                         La sortie analogique (ADC) est convertie en ppm via une courbe de calibration.")
                               )
                           )
                       )
                ),

                # MQ-7
                column(4,
                       div(class = "zone-card",
                           div(style = "display:flex; align-items:flex-start; gap:14px;",
                               div(style = "width:44px; height:44px; border-radius:10px; background:#fee2e2;
                                            display:flex; align-items:center; justify-content:center; flex-shrink:0;",
                                   icon("fire", style = "color:#dc2626; font-size:18px;")),
                               div(
                                 tags$p(style = "font-size:14px; font-weight:700; color:#111827; margin:0 0 4px;",
                                        "Capteur MQ-7"),
                                 tags$p(style = "font-size:12px; color:#374151; line-height:1.6; margin:0;",
                                        "Specialise dans la detection du monoxyde de carbone (CO), gaz inodore et
                                         potentiellement mortel. Utilise un cycle thermique chaud/froid pour maximiser
                                         la precision : chauffage a 5 V puis mesure a 1,4 V.
                                         Valeur cle pour detecter les emissions du trafic automobile au parking.")
                               )
                           )
                       )
                )
              ),

              fluidRow(

                # BMP180
                column(4,
                       div(class = "zone-card",
                           div(style = "display:flex; align-items:flex-start; gap:14px;",
                               div(style = "width:44px; height:44px; border-radius:10px; background:#fff7ed;
                                            display:flex; align-items:center; justify-content:center; flex-shrink:0;",
                                   icon("gauge-high", style = "color:#ea580c; font-size:18px;")),
                               div(
                                 tags$p(style = "font-size:14px; font-weight:700; color:#111827; margin:0 0 4px;",
                                        "BMP180 — Module GY-68"),
                                 tags$p(style = "font-size:12px; color:#374151; line-height:1.6; margin:0;",
                                        "Capteur de pression atmospherique et d'altitude barometrique.
                                         Communique avec l'Arduino via le bus I²C (SDA/SCL).
                                         Fournit la pression en hPa et l'altitude en metres,
                                         permettant de contextualiser les mesures de polluants selon
                                         les conditions atmospheriques locales.")
                               )
                           )
                       )
                ),

                # GPS NEO-6M
                column(4,
                       div(class = "zone-card",
                           div(style = "display:flex; align-items:flex-start; gap:14px;",
                               div(style = "width:44px; height:44px; border-radius:10px; background:#eff6ff;
                                            display:flex; align-items:center; justify-content:center; flex-shrink:0;",
                                   icon("location-dot", style = "color:#2563eb; font-size:18px;")),
                               div(
                                 tags$p(style = "font-size:14px; font-weight:700; color:#111827; margin:0 0 4px;",
                                        "GPS GYNEO6MV2 (NEO-6M)"),
                                 tags$p(style = "font-size:12px; color:#374151; line-height:1.6; margin:0;",
                                        "Module GPS UART qui fournit les coordonnees precises (latitude/longitude)
                                         de chaque mesure. Ces coordonnees sont envoyees au serveur, qui les utilise
                                         pour interroger l'API Open-Meteo et obtenir
                                         la temperature et l'humidite correspondant a l'emplacement exact
                                         de la balise au moment de la mesure.")
                               )
                           )
                       )
                ),

                # SIM900
                column(4,
                       div(class = "zone-card",
                           div(style = "display:flex; align-items:flex-start; gap:14px;",
                               div(style = "width:44px; height:44px; border-radius:10px; background:#fdf4ff;
                                            display:flex; align-items:center; justify-content:center; flex-shrink:0;",
                                   icon("signal", style = "color:#7c3aed; font-size:18px;")),
                               div(
                                 tags$p(style = "font-size:14px; font-weight:700; color:#111827; margin:0 0 4px;",
                                        "Module SIM900 (GSM/GPRS)"),
                                 tags$p(style = "font-size:12px; color:#374151; line-height:1.6; margin:0;",
                                        "Assure la transmission des donnees via le reseau cellulaire 2G (GPRS).
                                         A chaque cycle de mesure, il etablit une connexion HTTP POST
                                         vers le serveur distant et lui envoie toutes les valeurs collectees
                                         (gaz, pression, coordonnees GPS). Aucune infrastructure Wi-Fi requise :
                                         la balise fonctionne partout sur le campus.")
                               )
                           )
                       )
                )
              ),

              fluidRow(
                column(4,
                       div(class = "zone-card",
                           div(style = "display:flex; align-items:flex-start; gap:14px;",
                               div(style = "width:44px; height:44px; border-radius:10px; background:#f0fdf4;
                                            display:flex; align-items:center; justify-content:center; flex-shrink:0;",
                                   icon("battery-full", style = "color:#16a34a; font-size:18px;")),
                               div(
                                 tags$p(style = "font-size:14px; font-weight:700; color:#111827; margin:0 0 4px;",
                                        "Power Bank"),
                                 tags$p(style = "font-size:12px; color:#374151; line-height:1.6; margin:0;",
                                        "Alimentation portable rechargeable qui rend la balise totalement autonome.
                                         Permet de la deployer n'importe ou sur le campus sans dependance
                                         a une prise secteur, pour des sessions de mesure de plusieurs heures.")
                               )
                           )
                       )
                ),
                column(8)
              ),

              # ── Note Open-Meteo ──────────────────────────────────────
              fluidRow(
                column(12,
                       div(style = "background:#eff6ff; border:1px solid #bfdbfe;
                                    border-radius:10px; padding:16px 20px; margin-bottom:16px;",
                           div(style = "display:flex; align-items:flex-start; gap:14px;",
                               icon("cloud-sun", style = "font-size:22px; color:#2563eb; margin-top:2px; flex-shrink:0;"),
                               div(
                                 tags$p(style = "font-size:14px; font-weight:700; color:#111827; margin:0 0 6px;",
                                        "Temperature et humidite — API Open-Meteo"),
                                 tags$p(style = "font-size:13px; color:#374151; line-height:1.7; margin:0;",
                                        "La balise ne comporte pas de capteur de temperature/humidite dedie.
                                         A la reception de chaque mesure, le serveur utilise les ",
                                        tags$strong("coordonnees GPS transmises par le module NEO-6M"),
                                        " pour interroger l'",
                                        tags$strong("API Open-Meteo"),
                                        " (open-meteo.com), une source meteorologique libre et gratuite.
                                         L'API retourne la temperature en °C et l'humidite relative (%)
                                         correspondant exactement a la position et a l'heure de la mesure.
                                         Ces valeurs sont ensuite ajoutees au fichier CSV et exploitees
                                         dans les analyses de correlation et de sante du dashboard.")
                               )
                           )
                       )
                )
              )

      ), # fin balise
      tabItem(tabName = "equipe",
              h2("L'equipe", class = "page-title"),
              p("Membre de l'équipe"),
              
              fluidRow(
                column(4, div(class = "zone-card",
                              div(style = "text-align:center; padding:10px 0 12px;",
                                  tags$img(
                                    src   = "TAPE.png",
                                    style = "width:90px; height:90px; border-radius:50%;
                                             object-fit:cover; object-position:center top;
                                             display:block; margin:0 auto 14px auto;
                                             border:3px solid #dbeafe;"
                                  ),
                                  tags$p(style = "font-size:15px; font-weight:700; color:#111827; margin:0 0 6px 0;",
                                         "Tape Doubahi Jean Christopher"),
                                  tags$span(
                                    style = "background:#eff6ff; color:#2563eb; border-radius:20px;
                                             font-size:11px; font-weight:600; padding:3px 10px;
                                             display:inline-block;",
                                    "Licence MIAGE"
                                  )
                              )
                )),
                column(4, div(class = "zone-card",
                              div(style = "text-align:center; padding:10px 0 12px;",
                                  tags$img(
                                    src   = "ASSAMOI.png",
                                    style = "width:90px; height:90px; border-radius:50%;
                                             object-fit:cover; object-position:center top;
                                             display:block; margin:0 auto 14px auto;
                                             border:3px solid #dcfce7;"
                                  ),
                                  tags$p(style = "font-size:15px; font-weight:700; color:#111827; margin:0 0 6px 0;",
                                         "Assamoi Armida Yassine"),
                                  tags$span(
                                    style = "background:#f0fdf4; color:#15803d; border-radius:20px;
                                             font-size:11px; font-weight:600; padding:3px 10px;
                                             display:inline-block;",
                                    "Licence Statistique & Économie Appliquée"
                                  )
                              )
                )),
                column(4, div(class = "zone-card",
                              div(style = "text-align:center; padding:10px 0 12px;",
                                  tags$div(
                                    style = "width:90px; height:90px; border-radius:50%;
                                             background:#ffedd5; color:#ea580c;
                                             display:flex; align-items:center;
                                             justify-content:center; font-size:22px; font-weight:700;
                                             margin:0 auto 14px auto; border:3px solid #ffedd5;",
                                    "CR"
                                  ),
                                  tags$p(style = "font-size:15px; font-weight:700; color:#111827; margin:0 0 6px 0;",
                                         "Coulibaly Ramatou"),
                                  tags$span(
                                    style = "background:#fff7ed; color:#c2410c; border-radius:20px;
                                             font-size:11px; font-weight:600; padding:3px 10px;
                                             display:inline-block;",
                                    "Licence Statistique & Économie Appliquée"
                                  )
                              )
                ))
              ),
              
              fluidRow(
                column(12, div(class = "zone-card",
                               div(style = "display:flex; align-items:center; gap:16px;",
                                   tags$div(style = "width:44px; height:44px; border-radius:50%; background:#dcfce7;
                                display:flex; align-items:center; justify-content:center; flex-shrink:0;",
                                            icon("graduation-cap", style = "color:#16a34a; font-size:18px;")),
                                   div(
                                     tags$p(style = "font-size:14px; font-weight:700; color:#111827; margin:0 0 2px 0;",
                                            "Projet encadr\u00e9 par le Pr. Laurent Rouvi\u00e8re"),
                                     tags$p(style = "font-size:13px; color:#6b7280; margin:0;",
                                            "UFR Mathematiques-Informatique.UFHB 2026")
                                   )
                               )
                ))
              ),
              
              # Bandeau formation commun aux trois membres
              fluidRow(
                column(12,
                       div(style = "background:#f0fdf4; border:1px solid #bbf7d0;
                                    border-radius:10px; padding:14px 20px; margin-bottom:16px;
                                    display:flex; align-items:center; gap:14px;",
                           div(style = "width:40px; height:40px; border-radius:50%; background:#dcfce7;
                                        display:flex; align-items:center; justify-content:center; flex-shrink:0;",
                               icon("graduation-cap", style = "color:#16a34a; font-size:16px;")),
                           div(
                             tags$p(style = "font-size:13px; font-weight:700; color:#111827; margin:0 0 2px 0;",
                                    "Master 1 — Data Science"),
                             tags$p(style = "font-size:12px; color:#6b7280; margin:0;",
                                    "UFR Mathématiques-Informatique · Université Félix Houphouët-Boigny de Cocody · Abidjan 2025-2026")
                           )
                       )
                )
              ),

              fluidRow(
                column(6, div(class = "chart-card",
                              div(class = "chart-header", icon("circle-info"), span("A propos du projet")),
                              tags$p(style = "font-size:13px; color:#374151; line-height:1.7; margin:0;",
                                     "AirScan CI est un projet étudiant développé dans le cadre du Master 1 Data Science
               à l'UFR Mathématiques-Informatique de l'Université Félix Houphouët-Boigny de Cocody.
               L'objectif est de surveiller la qualité de l'air sur le campus et d'identifier
               les zones à risque pour la santé des étudiants et du personnel.")
                ))
              )
              
              
              
              
      ) # fin equipe
      
      
    ) # fin tabItems
  ) # fin dashboardBody
) # fin dashboardPage