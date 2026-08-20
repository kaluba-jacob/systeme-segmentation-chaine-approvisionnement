# ------------------------------------------------------------------------------
# Projet : Système de segmentation double de la chaîne d'approvisionnement
# Étape 5 : Approfondissement économétrique et tests de robustesse
# Objectif : Robustesse, hétérogénéité et correction d'endogénéité par PSM
# ------------------------------------------------------------------------------

# Chargement des packages
library(tidyverse)
library(fixest)
library(MatchIt)

# Création du dossier de sortie
dir.create("resultats/robustesse", showWarnings = FALSE, recursive = TRUE)

# 1. Préparation des données pour les deux périodes ----------------------------
preparer_data <- function(data) {
  data %>%
    mutate(
      roaa = roaa_moy,
      niveau_fourn = factor(niveau_fournisseur),
      niveau_client = factor(niveau_client),
      index_digital = index_numerique_moy,
      chaine_verte = factor(chaine_verte),
      croissance = croissance_actifs_moy,
      productivite_verte = pfte_verte_moy,
      propriete = factor(nature_propriete),
      secteur = factor(secteur)
    ) %>%
    drop_na(roaa, niveau_fourn, croissance, productivite_verte, propriete, secteur, index_digital)
}

donnees_T2 <- readRDS("donnees/donnees_clustering_T2.rds")
donnees_T1 <- readRDS("donnees/donnees_clustering_T1.rds")

data_T2 <- preparer_data(donnees_T2)
data_T1 <- preparer_data(donnees_T1)

# 2. Tests de robustesse du modèle de base ------------------------------------

# Modèle de référence (T2)
modele_ref <- feols(roaa ~ niveau_fourn + croissance + productivite_verte + propriete | secteur,
                    data = data_T2, vcov = "hetero")

# Robustesse 1 : Exclusion des 5% de valeurs extrêmes de ROAA
seuils <- quantile(data_T2$roaa, c(0.025, 0.975), na.rm = TRUE)
data_restreint <- data_T2 %>%
  filter(roaa >= seuils[1], roaa <= seuils[2])

modele_robuste_1 <- feols(roaa ~ niveau_fourn + croissance + productivite_verte + propriete | secteur,
                          data = data_restreint, vcov = "hetero")

# Robustesse 2 : Effet du niveau client sur échantillon restreint
modele_robuste_2 <- feols(roaa ~ niveau_client + croissance + productivite_verte + propriete | secteur,
                          data = data_restreint, vcov = "hetero")

# 3. Analyse hétérogène par niveau de digitalisation --------------------------

# Séparation en deux groupes selon la médiane de l'index digital
mediane_digital <- median(data_T2$index_digital, na.rm = TRUE)

data_bas_digital <- data_T2 %>% filter(index_digital <= mediane_digital)
data_haut_digital <- data_T2 %>% filter(index_digital > mediane_digital)

# Régression sur groupe faible digitalisation
modele_bas_digital <- feols(roaa ~ niveau_fourn + croissance + productivite_verte + propriete | secteur,
                            data = data_bas_digital, vcov = "hetero")

# Régression sur groupe forte digitalisation
modele_haut_digital <- feols(roaa ~ niveau_fourn + croissance + productivite_verte + propriete | secteur,
                             data = data_haut_digital, vcov = "hetero")

# 4. Correction d'endogénéité : Propensity Score Matching (PSM) ---------------
# On estime l'effet causal de la chaîne verte sur la performance

# Estimation du score de propension
modele_psm <- matchit(chaine_verte ~ croissance + productivite_verte + propriete + secteur,
                      data = data_T2,
                      method = "nearest",
                      ratio = 1)

# Extraction de l'échantillon apparié
data_apparie <- match.data(modele_psm)

# Régression sur échantillon apparié
modele_psm_final <- feols(roaa ~ chaine_verte + niveau_fourn + croissance + productivite_verte + propriete | secteur,
                          data = data_apparie, vcov = "hetero")

# Calcul de l'effet moyen du traitement (ATT)
att <- data_apparie %>%
  group_by(chaine_verte) %>%
  summarise(roaa_moy = mean(roaa, na.rm = TRUE))

# 5. Comparaison T1 vs T2 ------------------------------------------------------

# Modèle sur la période T1
modele_T1 <- feols(roaa ~ niveau_fourn + croissance + productivite_verte + propriete | secteur,
                   data = data_T1, vcov = "hetero")

# 6. Export des résultats ------------------------------------------------------

# Tableau robustesse
tableau_robustesse <- etable(modele_ref, modele_robuste_1, modele_robuste_2,
                             tex = FALSE,
                             signifCode = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
                             digits = 4)

write.table(tableau_robustesse, "resultats/robustesse/tableau_robustesse.csv",
            sep = ",", row.names = TRUE, col.names = NA)

# Tableau hétérogénéité
tableau_heterogeneite <- etable(modele_bas_digital, modele_haut_digital,
                                tex = FALSE,
                                signifCode = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
                                digits = 4)

write.table(tableau_heterogeneite, "resultats/robustesse/tableau_heterogeneite_digital.csv",
            sep = ",", row.names = TRUE, col.names = NA)

# 7. Bilan console -------------------------------------------------------------
cat("✅ Approfondissement économétrique terminé\n")
cat("----------------------------------------\n")
cat("\n--- Test de robustesse : Échantillon restreint 95% ---\n")
summary(modele_robuste_1)
cat("\n--- Hétérogénéité : Groupe faible digitalisation ---\n")
summary(modele_bas_digital)
cat("\n--- Hétérogénéité : Groupe forte digitalisation ---\n")
summary(modele_haut_digital)
cat("\n--- Effet de la chaîne verte après appariement PSM ---\n")
summary(modele_psm_final)
cat("\n--- Performance moyenne selon chaîne verte (échantillon apparié) ---\n")
print(att)
cat("\n--- Comparaison T1 vs T2 : Effet niveau fournisseur sur T1 ---\n")
summary(modele_T1)