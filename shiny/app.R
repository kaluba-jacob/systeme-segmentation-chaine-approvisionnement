# ------------------------------------------------------------------------------
# app.R : Outil diagnostic chaîne d'approvisionnement
# ------------------------------------------------------------------------------
library(shiny)
library(bslib)
library(randomForest)

# Chargement des modèles
parametres_std  <- readRDS("modeles/parametres_std.rds")
bornes_winsor    <- readRDS("modeles/bornes_winsor.rds")
centroides_fourn <- readRDS("modeles/centroides_fournisseurs.rds")
centroides_cli   <- readRDS("modeles/centroides_clients.rds")

modele_rf_perf   <- readRDS("modeles/modele_rf.rds")
modele_rf_risque <- readRDS("modeles/modele_rf_classif.rds")

# Fonctions utilitaires
winsoriser_valeur <- function(valeur, nom_var) {
  q01 <- bornes_winsor[[paste0(nom_var, "_q01")]]
  q99 <- bornes_winsor[[paste0(nom_var, "_q99")]]
  valeur <- max(valeur, q01)
  valeur <- min(valeur, q99)
  return(valeur)
}

standardiser_valeur <- function(valeur, nom_var) {
  moy <- parametres_std[[paste0(nom_var, "_moyenne")]]
  ec  <- parametres_std[[paste0(nom_var, "_ecart")]]
  return( (valeur - moy) / ec )
}

assigner_cluster <- function(vecteur_std, centroides) {
  distances <- apply(centroides, 1, function(c) sum((vecteur_std - c)^2))
  return(which.min(distances))
}

# UI
ui <- navbarPage(
  title = "Outil diagnostic chaîne d'approvisionnement",
  theme = bs_theme(bootswatch = "flatly"),
  
  tabPanel(
    "📋 Diagnostic profil",
    sidebarLayout(
      sidebarPanel(
        width = 4,
        h4("Indicateurs côté fournisseurs"),
        sliderInput("conc_fourn", "Concentration fournisseurs (%)",
                    min = 0, max = 100, value = 40, step = 1),
        sliderInput("volatilite_fourn", "Volatilité fournisseurs",
                    min = 0, max = 1, value = 0.2, step = 0.01),
        sliderInput("ratio_depcap", "Ratio dépenses capital (%)",
                    min = 0, max = 50, value = 10, step = 0.5),
        sliderInput("taux_livraison", "Taux de livraison à l'heure (%)",
                    min = 70, max = 99, value = 88, step = 1),
        sliderInput("taux_defaut", "Taux de défaut par lot (%)",
                    min = 0.3, max = 18, value = 4, step = 0.1),
        
        hr(),
        h4("Indicateurs côté clients"),
        sliderInput("conc_clients", "Concentration clients (%)",
                    min = 0, max = 100, value = 30, step = 1),
        sliderInput("volatilite_ca", "Volatilité du chiffre d'affaires",
                    min = 0, max = 1, value = 0.15, step = 0.01),
        sliderInput("ratio_flux", "Ratio flux d'exploitation (%)",
                    min = -20, max = 40, value = 8, step = 0.5),
        sliderInput("delai_paiement", "Délai de paiement moyen (jours)",
                    min = 12, max = 120, value = 35, step = 1),
        sliderInput("taux_retour", "Taux de retour produits (%)",
                    min = 0.2, max = 14, value = 2.5, step = 0.1),
        
        hr(),
        actionButton("btn_exemple_diag", "📋 Charger un exemple", class = "btn-outline-secondary btn-block"),
        br(),
        actionButton("btn_diagnostic", "🔍 Lancer le diagnostic", class = "btn-primary btn-block")
      ),
      mainPanel(
        width = 8,
        h3("Résultat du diagnostic"),
        br(),
        uiOutput("resultat_diagnostic")
      )
    )
  ),
  
  tabPanel(
    "🤖 Prédiction performance",
    sidebarLayout(
      sidebarPanel(
        width = 4,
        h4("Caractéristiques de l'entreprise"),
        sliderInput("ml_conc_fourn", "Concentration fournisseurs (%)",
                    min = 0, max = 100, value = 40, step = 1),
        sliderInput("ml_volatilite_fourn", "Volatilité fournisseurs",
                    min = 0, max = 1, value = 0.2, step = 0.01),
        sliderInput("ml_conc_clients", "Concentration clients (%)",
                    min = 0, max = 100, value = 30, step = 1),
        sliderInput("ml_volatilite_ca", "Volatilité du chiffre d'affaires",
                    min = 0, max = 1, value = 0.15, step = 0.01),
        sliderInput("ml_index_digital", "Index de digitalisation",
                    min = 0, max = 100, value = 50, step = 1),
        selectInput("ml_chaine_verte", "Chaîne verte adoptée", choices = c("Non" = 0, "Oui" = 1)),
        sliderInput("ml_croissance", "Croissance des actifs (%)",
                    min = -30, max = 80, value = 5, step = 1),
        sliderInput("ml_prod_verte", "Productivité verte",
                    min = 0, max = 2, value = 0.8, step = 0.01),
        selectInput("ml_propriete", "Nature de la propriété", choices = c("Publique" = 0, "Privée" = 1)),
        
        hr(),
        actionButton("btn_exemple_pred", "📋 Charger un exemple", class = "btn-outline-secondary btn-block"),
        br(),
        actionButton("btn_prediction", "📊 Lancer la prédiction", class = "btn-success btn-block")
      ),
      mainPanel(
        width = 8,
        h3("Résultats de la prédiction"),
        br(),
        uiOutput("resultat_prediction")
      )
    )
  ),
  
  tabPanel(
    "📚 Méthodologie",
    fluidPage(
      h3("À propos de cet outil"),
      p("Prototype basé sur l'étude de segmentation double chaîne d'approvisionnement")
    )
  )
)

# Serveur
server <- function(input, output, session) {
  
  # ------------------ BOUTONS EXEMPLE ------------------
  observeEvent(input$btn_exemple_diag, {
    updateSliderInput(session, "conc_fourn", value = 65)
    updateSliderInput(session, "volatilite_fourn", value = 0.35)
    updateSliderInput(session, "ratio_depcap", value = 15)
    updateSliderInput(session, "taux_livraison", value = 82)
    updateSliderInput(session, "taux_defaut", value = 7)
    updateSliderInput(session, "conc_clients", value = 55)
    updateSliderInput(session, "volatilite_ca", value = 0.25)
    updateSliderInput(session, "ratio_flux", value = 5)
    updateSliderInput(session, "delai_paiement", value = 60)
    updateSliderInput(session, "taux_retour", value = 5)
  })
  
  observeEvent(input$btn_exemple_pred, {
    updateSliderInput(session, "ml_conc_fourn", value = 65)
    updateSliderInput(session, "ml_volatilite_fourn", value = 0.35)
    updateSliderInput(session, "ml_conc_clients", value = 55)
    updateSliderInput(session, "ml_volatilite_ca", value = 0.25)
    updateSliderInput(session, "ml_index_digital", value = 40)
    updateSelectInput(session, "ml_chaine_verte", selected = "1")
    updateSliderInput(session, "ml_croissance", value = 10)
    updateSliderInput(session, "ml_prod_verte", value = 0.6)
    updateSelectInput(session, "ml_propriete", selected = "1")
  })
  
  # ------------------ PARTIE 1 : DIAGNOSTIC ------------------
  resultat_diag <- eventReactive(input$btn_diagnostic, {
    
    vals_fourn <- c(
      conc_fourn_moy = input$conc_fourn,
      volatilite_fourn = input$volatilite_fourn,
      ratio_depcap_moy = input$ratio_depcap / 100,
      taux_livraison_heure = input$taux_livraison,
      taux_defaut = input$taux_defaut
    )
    
    vals_cli <- c(
      conc_clients_moy = input$conc_clients,
      volatilite_ca = input$volatilite_ca,
      ratio_flux_moy = input$ratio_flux / 100,
      delai_paiement_jours = input$delai_paiement,
      taux_retour = input$taux_retour
    )
    
    for(nom in names(vals_fourn)) vals_fourn[nom] <- winsoriser_valeur(vals_fourn[nom], nom)
    for(nom in names(vals_cli)) vals_cli[nom] <- winsoriser_valeur(vals_cli[nom], nom)
    for(nom in names(vals_fourn)) vals_fourn[nom] <- standardiser_valeur(vals_fourn[nom], nom)
    for(nom in names(vals_cli)) vals_cli[nom] <- standardiser_valeur(vals_cli[nom], nom)
    
    niveau_fourn <- assigner_cluster(vals_fourn, centroides_fourn)
    niveau_cli   <- assigner_cluster(vals_cli, centroides_cli)
    
    profils_fourn <- list(
      "1" = list(titre = "Niveau 1 – Vulnérable", diag = "Forte concentration, exposition majeure aux risques de rupture.", reco = "Priorité haute : lancer immédiatement un programme de diversification fournisseurs ; constituer un pool de fournisseurs de secours."),
      "2" = list(titre = "Niveau 2 – Intermédiaire", diag = "Structure équilibrée majoritaire, risque modéré.", reco = "Optimisation : maintenir l’équilibre actuel ; travailler sur la réduction des coûts par regroupement de commandes."),
      "3" = list(titre = "Niveau 3 – Performant", diag = "Bonne diversification et maîtrise des risques.", reco = "Partenariat stratégique : négocier des cadres de coopération à long terme ; mutualiser les efforts d’amélioration continue."),
      "4" = list(titre = "Niveau 4 – Diversifié", diag = "Base très étendue, complexité de gestion élevée.", reco = "Rationalisation : consolider la base fournisseurs sur les articles à faible risque ; garder la diversification sur les postes stratégiques.")
    )
    profils_cli <- list(
      "1" = list(titre = "Niveau 1 – Concentré", diag = "Forte dépendance vis‑à‑vis de quelques clients majeurs.", reco = "Réduction du risque : développer activement de nouveaux clients pour diminuer la concentration."),
      "2" = list(titre = "Niveau 2 – Intermédiaire", diag = "Portefeuille équilibré.", reco = "Croissance ciblée : concentrer les efforts commerciaux sur les segments les plus rentables."),
      "3" = list(titre = "Niveau 3 – Diversifié", diag = "Clientèle large, faible risque de concentration.", reco = "Standardisation : généraliser les processus de livraison et de service client.")
    )
    
    HTML(paste0(
      '<div class="card mb-4"><div class="card-header bg-primary text-white"><h4>Profil fournisseurs</h4></div><div class="card-body">',
      '<h5>', profils_fourn[[as.character(niveau_fourn)]]$titre, '</h5>',
      '<p><strong>Diagnostic :</strong> ',profils_fourn[[as.character(niveau_fourn)]]$diag,'</p>',
      '<p><strong>Recommandation :</strong> ',profils_fourn[[as.character(niveau_fourn)]]$reco,'</p></div></div>',
      '<div class="card mb-4"><div class="card-header bg-info text-white"><h4>Profil clients</h4></div><div class="card-body">',
      '<h5>', profils_cli[[as.character(niveau_cli)]]$titre, '</h5>',
      '<p><strong>Diagnostic :</strong> ',profils_cli[[as.character(niveau_cli)]]$diag,'</p>',
      '<p><strong>Recommandation :</strong> ',profils_cli[[as.character(niveau_cli)]]$reco,'</p></div></div>'
    ))
  })
  
  output$resultat_diagnostic <- renderUI({ resultat_diag() })
  
  
  # ------------------ PARTIE 2 : PREDICTION RANDOMFOREST ------------------
  resultat_pred <- eventReactive(input$btn_prediction, {
    
    # --- Mapping spécial : le modèle attend "-Inf" ou "1" pour chaine_verte ---
    cv <- ifelse(input$ml_chaine_verte == "0", "-Inf", "1")
    
    # --- Dataframe de base (9 prédicteurs) ---
    base_data <- data.frame(
      concentration_fourn   = as.numeric(input$ml_conc_fourn),
      volatilite_fourn      = as.numeric(input$ml_volatilite_fourn),
      concentration_clients = as.numeric(input$ml_conc_clients),
      volatilite_ca         = as.numeric(input$ml_volatilite_ca),
      index_digital         = as.numeric(input$ml_index_digital),
      chaine_verte          = cv,
      croissance            = as.numeric(input$ml_croissance),
      productivite_verte    = as.numeric(input$ml_prod_verte),
      propriete             = as.character(input$ml_propriete),
      stringsAsFactors      = FALSE
    )
    
    # ================================================================
    # MODÈLE 1 : Prédiction ROAA (régression)
    # ================================================================
    data_perf <- base_data
    data_perf$risque_fourn <- factor("resilient", levels = c("resilient", "vulnerable"))
    data_perf$chaine_verte <- factor(data_perf$chaine_verte, levels = c("-Inf", "1"))
    data_perf$propriete    <- factor(data_perf$propriete, levels = c("0", "1"))
    data_perf <- data_perf[, c("risque_fourn", "concentration_fourn", "volatilite_fourn",
                               "concentration_clients", "volatilite_ca", "index_digital",
                               "chaine_verte", "croissance", "productivite_verte", "propriete")]
    
    roaa_pred <- tryCatch({
      as.numeric(predict(modele_rf_perf, newdata = data_perf))
    }, error = function(e) {
      message("Erreur ROAA: ", e$message)
      NA_real_
    })
    
    # ================================================================
    # MODÈLE 2 : Prédiction risque fournisseur (classification)
    # ================================================================
    data_risque <- base_data
    data_risque$roaa          <- 0.05
    data_risque$risque_fourn  <- factor("resilient", levels = c("resilient", "vulnerable"))
    data_risque$chaine_verte  <- factor(data_risque$chaine_verte, levels = c("-Inf", "1"))
    data_risque$propriete     <- factor(data_risque$propriete, levels = c("0", "1"))
    data_risque <- data_risque[, c("roaa", "concentration_fourn", "volatilite_fourn",
                                   "concentration_clients", "volatilite_ca", "index_digital",
                                   "chaine_verte", "croissance", "productivite_verte", "propriete",
                                   "risque_fourn")]
    
    risque_pred <- tryCatch({
      as.character(predict(modele_rf_risque, newdata = data_risque))
    }, error = function(e) {
      message("Erreur risque: ", e$message)
      "resilient"
    })
    
    # ================================================================
    # MISE EN FORME
    # ================================================================
    risque_label  <- ifelse(risque_pred == "resilient", "Résilient", "Vulnérable")
    risque_classe <- ifelse(risque_pred == "resilient", "success", "danger")
    roaa_affiche  <- ifelse(is.na(roaa_pred), "N/A", paste0(round(roaa_pred * 100, 2), " %"))
    
    HTML(paste0(
      '<div class="row">',
      '<div class="col-md-6">',
      '<div class="card text-center mb-4">',
      '<div class="card-header bg-success text-white"><h4>ROAA prédit</h4></div>',
      '<div class="card-body">',
      '<h2 style="font-size:3rem;">', roaa_affiche, '</h2>',
      '<p class="text-muted">Rentabilité des actifs prédite par forêt aléatoire</p>',
      '</div></div></div>',
      
      '<div class="col-md-6">',
      '<div class="card text-center mb-4">',
      '<div class="card-header bg-', risque_classe, ' text-white"><h4>Risque fournisseur</h4></div>',
      '<div class="card-body">',
      '<h2 style="font-size:3rem;">', risque_label, '</h2>',
      '<p class="text-muted">Classification par forêt aléatoire</p>',
      '</div></div></div>',
      '</div>',
      
      '<div class="alert alert-info mt-3">',
      '<strong>Interprétation : </strong>',
      'Ces prédictions sont basées sur les caractéristiques structurelles de votre chaîne d’approvisionnement. ',
      'Une diversification de la base fournisseurs et une adoption de chaîne verte sont associées à une meilleure rentabilité sur la période post‑pandémie.',
      '</div>'
    ))
  })
  
  output$resultat_prediction <- renderUI({ resultat_pred() })
  
}

shinyApp(ui = ui, server = server)
