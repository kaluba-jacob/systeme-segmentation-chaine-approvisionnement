# ------------------------------------------------------------------------------
# Projet : Système de segmentation double de la chaîne d'approvisionnement
# Étape 1 : Prétraitement des données et construction du système d'indicateurs
# Objectif : Nettoyage, agrégation par période, indicateurs réels + simulation légère 
# ------------------------------------------------------------------------------

# Chargement des packages requis
library(tidyverse)
library(readxl)

# Graine aléatoire pour la reproductibilité des indicateurs simulés
set.seed(123)

# 1. Chargement des données brutes -------------------------------------------------
donnees_brutes <- read_excel("donnees/data2.xlsx", sheet = "Sheet1")

# 2. Nettoyage de base et renommage des variables ----------------------------------
# On renomme les colonnes chinoises en français pour la cohérence du projet
donnees_propres <- donnees_brutes %>%
  rename(
    code_securite = `证券代码`,
    nom_entreprise = `证券简称`,
    annee = year,
    secteur = `所属行业`,
    conc_fournisseurs = `供应商集中度`,
    conc_clients = `客户集中度`,
    conc_chaine_totale = `供应链集中度`,
    ratio_endettement = `资产负债率`,
    roaa = `总资产净利润率ROAA`,
    croissance_actifs = `总资产增长率B`,
    resultat_conserve = `留存收益`,
    depenses_capital = `资本支出`,
    chiffre_affaires = `营业收入`,
    flux_exploitation = `经营活动产生的现金流量净额`,
    index_numerique = `数字化转型指数`,
    chaine_verte = `是否绿色供应链`,
    nature_propriete = `产权性质`,
    province = `所在省份`,
    industrie_lourde = `是否重污染`,
    haute_technologie = `是否高技术制造业`,
    pfte_verte = `企业绿色全要素生产率`
  ) %>%
  mutate(
    annee = as.integer(annee),
    # Calcul de ratios financiers de base
    ratio_depenses_cap = depenses_capital / chiffre_affaires,
    ratio_flux_explo = flux_exploitation / chiffre_affaires
  ) %>%
  # Suppression des observations avec valeurs manquantes sur les indicateurs clés
  drop_na(conc_clients, conc_fournisseurs, roaa, chiffre_affaires)

# 3. Agrégation par période (T1 et T2) ---------------------------------------------
# Fonction générique pour calculer les moyennes par entreprise sur une période donnée
calculer_agregats_periode <- function(data, annee_debut, annee_fin, nom_periode) {
  data %>%
    filter(annee >= annee_debut & annee <= annee_fin) %>%
    group_by(code_securite, nom_entreprise, secteur, nature_propriete, province, industrie_lourde, haute_technologie) %>%
    summarise(
      # --- Indicateurs côté fournisseurs (données réelles) ---
      conc_fourn_moy = mean(conc_fournisseurs, na.rm = TRUE),
      volatilite_fourn = sd(conc_fournisseurs, na.rm = TRUE) / mean(conc_fournisseurs, na.rm = TRUE),
      ratio_depcap_moy = mean(ratio_depenses_cap, na.rm = TRUE),
      
      # --- Indicateurs côté clients (données réelles) ---
      conc_clients_moy = mean(conc_clients, na.rm = TRUE),
      volatilite_ca = sd(chiffre_affaires, na.rm = TRUE) / mean(chiffre_affaires, na.rm = TRUE),
      ratio_flux_moy = mean(ratio_flux_explo, na.rm = TRUE),
      
      # --- Variables de performance ---
      roaa_moy = mean(roaa, na.rm = TRUE),
      croissance_actifs_moy = mean(croissance_actifs, na.rm = TRUE),
      pfte_verte_moy = mean(pfte_verte, na.rm = TRUE),
      
      # --- Variables modératrices ---
      index_numerique_moy = mean(index_numerique, na.rm = TRUE),
      chaine_verte = max(chaine_verte, na.rm = TRUE),
      
      .groups = "drop"
    ) %>%
    mutate(
      periode = nom_periode,
      # Remplacement des NaN/Inf par 0 (cas des entreprises avec une seule année de données)
      across(c(volatilite_fourn, volatilite_ca), ~ ifelse(is.nan(.) | is.infinite(.), 0, .))
    )
}

# Application de la fonction sur les deux périodes
# T1 : 2015-2018 (période de référence avant pandémie)
# T2 : 2019-2023 (période de restructuration après pandémie)
donnees_T1 <- calculer_agregats_periode(donnees_propres, 2015, 2018, "T1_2015_2018")
donnees_T2 <- calculer_agregats_periode(donnees_propres, 2019, 2023, "T2_2019_2023")

# 4. Simulation légère de 4 indicateurs métier (Option B) --------------------------
# Principe : Tous les indicateurs sont ancrés sur des variables réelles + bruit contrôlé.
# Les valeurs sont tronquées pour rester dans des plages réalistes du monde professionnel.

ajouter_indicateurs_simules <- function(data) {
  data %>%
    mutate(
      # ===== Côté fournisseurs =====
      # Taux de livraison à l'heure : négativement corrélé à la volatilité fournisseurs
      # Plus la relation est stable, plus la ponctualité est élevée
      taux_livraison_heure = 86 - volatilite_fourn * 12 + rnorm(n(), 0, 2),
      taux_livraison_heure = pmin(pmax(taux_livraison_heure, 70), 99),
      
      # Taux de défaut par lot : positivement corrélé à la volatilité fournisseurs
      taux_defaut = 3 + volatilite_fourn * 10 + rnorm(n(), 0, 0.7),
      taux_defaut = pmin(pmax(taux_defaut, 0.3), 18),
      
      # ===== Côté clients =====
      # Délai de paiement moyen : positivement corrélé à la concentration clients
      # Plus le client est dominant, plus il impose des délais longs
      delai_paiement_jours = 28 + conc_clients_moy * 0.5 + rnorm(n(), 0, 4.5),
      delai_paiement_jours = pmin(pmax(delai_paiement_jours, 12), 120),
      
      # Taux de retour produits : positivement corrélé à la volatilité du CA
      taux_retour = 1.8 + volatilite_ca * 7 + rnorm(n(), 0, 0.4),
      taux_retour = pmin(pmax(taux_retour, 0.2), 14)
    )
}

# Application sur les deux périodes
donnees_T1 <- ajouter_indicateurs_simules(donnees_T1)
donnees_T2 <- ajouter_indicateurs_simules(donnees_T2)

# 4bis. Winsorisation des variables de clustering (élimination des valeurs aberrantes)
# Principe : on coupe les 1% les plus extrêmes de chaque distribution pour stabiliser le K-means

winsoriser <- function(x, probs = c(0.01, 0.99)) {
  limites <- quantile(x, probs, na.rm = TRUE)
  x <- pmax(x, limites[1])
  x <- pmin(x, limites[2])
  return(x)
}

# Variables concernées par la winsorisation (toutes les variables qui entrent dans le clustering)
vars_clust_fournisseurs <- c("conc_fourn_moy", "volatilite_fourn", "ratio_depcap_moy", "taux_livraison_heure", "taux_defaut")
vars_clust_clients <- c("conc_clients_moy", "volatilite_ca", "ratio_flux_moy", "delai_paiement_jours", "taux_retour")
toutes_vars_clust <- c(vars_clust_fournisseurs, vars_clust_clients)

# Application sur les deux périodes
donnees_T1 <- donnees_T1 %>%
  mutate(across(all_of(toutes_vars_clust), winsoriser))

donnees_T2 <- donnees_T2 %>%
  mutate(across(all_of(toutes_vars_clust), winsoriser))

# 5. Standardisation Z-score pour le clustering ------------------------------------
# Essentiel pour éliminer les effets d'échelle entre les variables

# Définition des variables utilisées pour le clustering
vars_clust_fournisseurs <- c("conc_fourn_moy", "volatilite_fourn", "ratio_depcap_moy", "taux_livraison_heure", "taux_defaut")
vars_clust_clients <- c("conc_clients_moy", "volatilite_ca", "ratio_flux_moy", "delai_paiement_jours", "taux_retour")

# Fonction de standardisation
standardiser_zscore <- function(data, variables) {
  data %>%
    mutate(across(all_of(variables), ~ scale(.)[,1], .names = "{.col}_std"))
}

# Application
donnees_T1 <- standardiser_zscore(donnees_T1, c(vars_clust_fournisseurs, vars_clust_clients))
donnees_T2 <- standardiser_zscore(donnees_T2, c(vars_clust_fournisseurs, vars_clust_clients))

# 6. Sauvegarde des jeux de données finaux -----------------------------------------
saveRDS(donnees_T1, "donnees/donnees_traitees_T1.rds")
saveRDS(donnees_T2, "donnees/donnees_traitees_T2.rds")

# 7. Bilan dans la console ---------------------------------------------------------
cat(" Prétraitement des données terminé avec succès\n")
cat("----------------------------------------\n")
cat("Période T1 (2015-2018) :", nrow(donnees_T1), "entreprises\n")
cat("Période T2 (2019-2023) :", nrow(donnees_T2), "entreprises\n")
cat("Indicateurs de clustering fournisseurs :", length(vars_clust_fournisseurs), "\n")
cat("Indicateurs de clustering clients :", length(vars_clust_clients), "\n")