# ------------------------------------------------------------------------------
# Projet : Système de segmentation double de la chaîne d'approvisionnement
# Étape 4 : Régressions économétriques et analyse des effets modérateurs
# Objectif : Estimer l'impact de la classification sur la performance économique
# ------------------------------------------------------------------------------

# Chargement des packages
library(tidyverse)
library(fixest)

# Création du dossier de sortie
dir.create("resultats/regressions", showWarnings = FALSE, recursive = TRUE)

# 1. Chargement et préparation des données -------------------------------------
donnees_T2 <- readRDS("donnees/donnees_clustering_T2.rds")

# Construction des variables de régression
data_reg <- donnees_T2 %>%
  mutate(
    # Variable dépendante : performance économique
    roaa = roaa_moy,
    
    # Variables explicatives principales (facteurs)
    niveau_fourn = factor(niveau_fournisseur),
    niveau_client = factor(niveau_client),
    
    # Variables modératrices
    index_digital = index_numerique_moy,
    chaine_verte = factor(chaine_verte),
    
    # Variables de contrôle
    croissance = croissance_actifs_moy,       # Croissance des actifs
    productivite_verte = pfte_verte_moy,      # Productivité totale des facteurs verte
    propriete = factor(nature_propriete),     # Nature de la propriété
    secteur = factor(secteur)                 # Effet fixe secteur
  ) %>%
  # Suppression des valeurs manquantes
  drop_na(roaa, niveau_fourn, croissance, productivite_verte, propriete, secteur)

# 2. Modèles de base - Effet de la classification sur la performance ----------

# Modèle 1 : Effet du niveau fournisseur (sans contrôle)
modele_1a <- feols(roaa ~ niveau_fourn, data = data_reg, vcov = "hetero")

# Modèle 2 : Effet du niveau fournisseur + contrôles + effets fixes secteur
modele_1b <- feols(roaa ~ niveau_fourn + croissance + productivite_verte + propriete | secteur, 
                   data = data_reg, vcov = "hetero")

# Modèle 3 : Effet du niveau client + contrôles + effets fixes secteur
modele_2b <- feols(roaa ~ niveau_client + croissance + productivite_verte + propriete | secteur, 
                   data = data_reg, vcov = "hetero")

# 3. Effets modérateurs - Interaction avec la transformation digitale ----------

# Modèle 4 : Interaction niveau fournisseur × index digital
modele_3a <- feols(roaa ~ niveau_fourn * index_digital + croissance + productivite_verte + propriete | secteur,
                   data = data_reg, vcov = "hetero")

# Modèle 5 : Interaction niveau client × index digital
modele_3b <- feols(roaa ~ niveau_client * index_digital + croissance + productivite_verte + propriete | secteur,
                   data = data_reg, vcov = "hetero")

# 4. Effets modérateurs - Interaction avec la chaîne verte --------------------

# Modèle 6 : Interaction niveau fournisseur × chaîne verte
modele_4a <- feols(roaa ~ niveau_fourn * chaine_verte + croissance + productivite_verte + propriete | secteur,
                   data = data_reg, vcov = "hetero")

# Modèle 7 : Interaction niveau client × chaîne verte
modele_4b <- feols(roaa ~ niveau_client * chaine_verte + croissance + productivite_verte + propriete | secteur,
                   data = data_reg, vcov = "hetero")

# 5. Export des tableaux de résultats -----------------------------------------

# Tableau récapitulatif des modèles de base
resultats_base <- etable(modele_1a, modele_1b, modele_2b,
                         tex = FALSE,
                         signifCode = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
                         digits = 4)

write.table(resultats_base, "resultats/regressions/tableau_modeles_base.csv",
            sep = ";", row.names = TRUE, col.names = NA)

# Tableau des effets modérateurs digital
resultats_digital <- etable(modele_3a, modele_3b,
                            tex = FALSE,
                            signifCode = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
                            digits = 4)

write.table(resultats_digital, "resultats/regressions/tableau_moderateur_digital.csv",
            sep = ";", row.names = TRUE, col.names = NA)

# Tableau des effets modérateurs chaîne verte
resultats_verte <- etable(modele_4a, modele_4b,
                          tex = FALSE,
                          signifCode = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
                          digits = 4)

write.table(resultats_verte, "resultats/regressions/tableau_moderateur_verte.csv",
            sep = ";", row.names = TRUE, col.names = NA)

# 6. Bilan console -------------------------------------------------------------
cat(" Régressions économétriques terminées avec succès\n")
cat("----------------------------------------\n")
cat("Nombre d'observations dans les régressions :", nrow(data_reg), "\n")
cat("\n--- Modèle 1b : Performance ~ Niveau fournisseur + contrôles ---\n")
summary(modele_1b)
cat("\n--- Modèle 2b : Performance ~ Niveau client + contrôles ---\n")
summary(modele_2b)
cat("\n--- Modèle 3a : Effet modérateur digital (fournisseurs) ---\n")
summary(modele_3a)