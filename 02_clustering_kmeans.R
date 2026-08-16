# ------------------------------------------------------------------------------
# Projet : Système de segmentation double de la chaîne d'approvisionnement
# Étape 2 : Clustering K-means et analyse de migration structurelle
# Objectif : Classification fournisseurs (4 groupes) et clients (3 groupes), analyse avant/après pandémie
# ------------------------------------------------------------------------------

# Chargement des packages
library(tidyverse)
library(factoextra)

# Graine aléatoire pour reproductibilité
set.seed(123)

# Création automatique du dossier de sortie
dir.create("resultats/clustering", showWarnings = FALSE, recursive = TRUE)

# 1. Chargement des données prétraitées -----------------------------------------
donnees_T1 <- readRDS("donnees/donnees_traitees_T1.rds")
donnees_T2 <- readRDS("donnees/donnees_traitees_T2.rds")

# Définition des variables de clustering (déjà standardisées)
vars_fourn_std <- c("conc_fourn_moy_std", "volatilite_fourn_std", "ratio_depcap_moy_std", 
                    "taux_livraison_heure_std", "taux_defaut_std")
vars_clients_std <- c("conc_clients_moy_std", "volatilite_ca_std", "ratio_flux_moy_std",
                      "delai_paiement_jours_std", "taux_retour_std")

# --- Nettoyage de sécurité : suppression des NA et Inf avant tout clustering
nettoyer_avant_clust <- function(data, vars) {
  data %>%
    mutate(across(all_of(vars), ~ ifelse(is.infinite(.), NA, .))) %>%
    drop_na(all_of(vars))
}

donnees_T1 <- nettoyer_avant_clust(donnees_T1, c(vars_fourn_std, vars_clients_std))
donnees_T2 <- nettoyer_avant_clust(donnees_T2, c(vars_fourn_std, vars_clients_std))

# 2. Détermination du nombre optimal de clusters -------------------------------
# --- Côté fournisseurs (sur T2, période la plus récente et la plus fournie)
data_fourn_T2 <- donnees_T2 %>% select(all_of(vars_fourn_std))

# Graphique de la méthode du coude
graph_coude_fourn <- fviz_nbclust(data_fourn_T2, kmeans, method = "wss") +
  labs(title = "Nombre optimal de clusters - Côté fournisseurs",
       x = "Nombre de clusters k",
       y = "Somme des carrés intra-classe (WSS)") +
  theme_minimal()

ggsave("resultats/clustering/coude_fournisseurs.png", graph_coude_fourn, width = 8, height = 5, dpi = 300)

# --- Côté clients
data_clients_T2 <- donnees_T2 %>% select(all_of(vars_clients_std))

graph_coude_clients <- fviz_nbclust(data_clients_T2, kmeans, method = "wss") +
  labs(title = "Nombre optimal de clusters - Côté clients",
       x = "Nombre de clusters k",
       y = "Somme des carrés intra-classe (WSS)") +
  theme_minimal()

ggsave("resultats/clustering/coude_clients.png", graph_coude_clients, width = 8, height = 5, dpi = 300)

# 3. Exécution du clustering K-means -------------------------------------------
# Fonction générique pour appliquer le clustering et ajouter les labels
appliquer_kmeans <- function(data, vars, k, prefixe) {
  modele <- kmeans(data %>% select(all_of(vars)), centers = k, nstart = 25)
  data %>%
    mutate({{prefixe}} := factor(modele$cluster, levels = 1:k))
}

# --- Clustering fournisseurs (k=4) sur les deux périodes
donnees_T1 <- appliquer_kmeans(donnees_T1, vars_fourn_std, 4, "niveau_fournisseur")
donnees_T2 <- appliquer_kmeans(donnees_T2, vars_fourn_std, 4, "niveau_fournisseur")

# --- Clustering clients (k=3) sur les deux périodes
donnees_T1 <- appliquer_kmeans(donnees_T1, vars_clients_std, 3, "niveau_client")
donnees_T2 <- appliquer_kmeans(donnees_T2, vars_clients_std, 3, "niveau_client")

# 4. Profilage des clusters (moyennes des indicateurs) -------------------------
# Fonction pour générer le tableau de profil
profiler_clusters <- function(data, groupe_var, vars_originales) {
  data %>%
    group_by({{groupe_var}}) %>%
    summarise(
      effectif = n(),
      pourcentage = round(n() / nrow(data) * 100, 1),
      across(all_of(vars_originales), ~ round(mean(., na.rm = TRUE), 2)),
      .groups = "drop"
    )
}

vars_fourn_originales <- c("conc_fourn_moy", "volatilite_fourn", "ratio_depcap_moy", 
                           "taux_livraison_heure", "taux_defaut")
vars_clients_originales <- c("conc_clients_moy", "volatilite_ca", "ratio_flux_moy",
                             "delai_paiement_jours", "taux_retour")

# Profils fournisseurs
profil_fourn_T1 <- profiler_clusters(donnees_T1, niveau_fournisseur, vars_fourn_originales)
profil_fourn_T2 <- profiler_clusters(donnees_T2, niveau_fournisseur, vars_fourn_originales)

# Profils clients
profil_client_T1 <- profiler_clusters(donnees_T1, niveau_client, vars_clients_originales)
profil_client_T2 <- profiler_clusters(donnees_T2, niveau_client, vars_clients_originales)

# Sauvegarde des tableaux de profil
write_csv2(profil_fourn_T2, "resultats/clustering/profil_fournisseurs_T2.csv")
write_csv2(profil_client_T2, "resultats/clustering/profil_clients_T2.csv")

# 5. Analyse de migration T1 → T2 ----------------------------------------------
# On ne garde que les entreprises présentes dans les deux périodes (panel équilibré)
entreprises_communes <- inner_join(
  donnees_T1 %>% select(code_securite, niveau_fournisseur, niveau_client),
  donnees_T2 %>% select(code_securite, niveau_fournisseur, niveau_client),
  by = "code_securite",
  suffix = c("_T1", "_T2")
)

# Matrice de migration - Fournisseurs
migration_fourn <- entreprises_communes %>%
  count(niveau_fournisseur_T1, niveau_fournisseur_T2) %>%
  group_by(niveau_fournisseur_T1) %>%
  mutate(pourcentage = round(n / sum(n) * 100, 1)) %>%
  ungroup()

# Matrice de migration - Clients
migration_clients <- entreprises_communes %>%
  count(niveau_client_T1, niveau_client_T2) %>%
  group_by(niveau_client_T1) %>%
  mutate(pourcentage = round(n / sum(n) * 100, 1)) %>%
  ungroup()

write_csv2(migration_fourn, "resultats/clustering/migration_fournisseurs.csv")
write_csv2(migration_clients, "resultats/clustering/migration_clients.csv")

# 6. Analyse croisée double extrémité (fournisseurs × clients) -----------------
croise_T2 <- donnees_T2 %>%
  count(niveau_fournisseur, niveau_client) %>%
  group_by(niveau_fournisseur) %>%
  mutate(pourcentage = round(n / sum(n) * 100, 1)) %>%
  ungroup()

write_csv2(croise_T2, "resultats/clustering/croise_fourn_clients_T2.csv")

# 7. Sauvegarde des données avec labels de clustering --------------------------
saveRDS(donnees_T1, "donnees/donnees_clustering_T1.rds")
saveRDS(donnees_T2, "donnees/donnees_clustering_T2.rds")

# 8. Bilan console -------------------------------------------------------------
cat(" Clustering K-means terminé avec succès\n")
cat("----------------------------------------\n")
cat("Effectif T1 après nettoyage :", nrow(donnees_T1), "entreprises\n")
cat("Effectif T2 après nettoyage :", nrow(donnees_T2), "entreprises\n")
cat("Nombre d'entreprises communes T1/T2 :", nrow(entreprises_communes), "\n")
cat("\n--- Répartition fournisseurs T2 ---\n")
print(profil_fourn_T2 %>% select(niveau_fournisseur, effectif, pourcentage))
cat("\n--- Répartition clients T2 ---\n")
print(profil_client_T2 %>% select(niveau_client, effectif, pourcentage))