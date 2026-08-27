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
  
  # Diagnostic fonctionnel
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
  
  # Partie prédiction : texte descriptif sans exécution randomForest
  resultat_pred <- eventReactive(input$btn_prediction, {
    HTML("
<div class='alert alert-info'>
<h4>📌 Module de prédiction de performance (modèle randomForest)</h4>
<p>Ce module est prévu pour estimer la performance économique (ROAA) et le risque de la chaîne d'approvisionnement à partir des caractéristiques de l'entreprise.</p>
<h5>Variables d'entrée du modèle :</h5>
<ul>
<li>Concentration fournisseurs, volatilité fournisseurs</li>
<li>Concentration clients, volatilité du chiffre d'affaires</li>
<li>Indice de transformation digitale</li>
<li>Label chaîne verte (Oui / Non)</li>
<li>Croissance des actifs, productivité verte</li>
<li>Nature de propriété (Publique / Privée)</li>
</ul>
<p>📎 Les résultats complets des prédictions et des régressions économétriques sont disponibles dans le dossier <code>resultats/regressions/</code> du dépôt GitHub (fichiers CSV générés par le script R hors shiny).</p>
<p><em>Note : L'exécution du modèle prédictif au sein de l'application shiny est désactivée pour éviter les erreurs de compatibilité de types de données.</em></p>
</div>
")
  })
  
  output$resultat_prediction <- renderUI({ resultat_pred() })
  
}

shinyApp(ui = ui, server = server)
