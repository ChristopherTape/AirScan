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
      #menuItem("Accueil",       tabName = "accueil",      icon = icon("house")),
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
                               div(class = "zone-dot dot-danger")
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
    
    #  tabItem(tabName = "accueil",
    #          h2("Accueil", class = "page-title"),
    #          p("Page en construction...")
    #  ),
      tabItem(tabName = "carte",
              h2("Carte interactive", class = "page-title"),
              p("Page en construction...")
      ),
      tabItem(tabName = "temporelle",
              h2("Analyse temporelle", class = "page-title"),
              p("Page en construction de Armida")
      ),
      tabItem(tabName = "prediction",
              h2("Prediction ML", class = "page-title"),
              p("Page en construction...")
      ),
      tabItem(tabName = "correlations",
              h2("Correlations", class = "page-title"),
              p("Page en construction...")
      ),
      tabItem(tabName = "sante",
              h2("Impact sante", class = "page-title"),
              p("Page en construction...")
      ),
      tabItem(tabName = "balise",
              h2("La Balise", class = "page-title"),
              p("Page en construction...")
      ),
      tabItem(tabName = "equipe",
              h2("L'equipe", class = "page-title"),
              p("Page en construction...")
      )
      
    ) # fin tabItems
  ) # fin dashboardBody
) # fin dashboardPage