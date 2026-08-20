# ------------------------------------------------------------------------------
# Projet : Système de segmentation double de la chaîne d'approvisionnement
# Étape 3 : Analyse des effets modérateurs
# Objectif : Étude de la transformation digitale et de la chaîne verte sur la classification
# ------------------------------------------------------------------------------

# Chargement des packages
library(tidyverse)

# Graine aléatoire
set.seed(123)

# Création du dossier de sortie
dir.create("resultats/moderateurs", showWarnings = FALSE, recursive = TRUE)

# 1. Chargement des données avec labels de clustering ---------------------------
donnees_T1 <- readRDS("donnees/donnees_clustering_T1.rds")
donnees_T2 <- readRDS("donnees/donnees_clustering_T2.rds")

# 2. Effet modérateur de la transformation digitale ----------------------------
# On compare l'index numérique moyen selon chaque niveau de classification

# --- Côté fournisseurs
digital_fourn_T2 <- donnees_T2 %>%
  group_by(niveau_fournisseur) %>%
  summarise(
    effectif = n(),
    index_numerique_moyen = round(mean(index_numerique_moy, na.rm = TRUE), 3),
    ecart_type = round(sd(index_numerique_moy, na.rm = TRUE), 3),
    .groups = "drop"
  )

# --- Côté clients
digital_clients_T2 <- donnees_T2 %>%
  group_by(niveau_client) %>%
  summarise(
    effectif = n(),
    index_numerique_moyen = round(mean(index_numerique_moy, na.rm = TRUE), 3),
    ecart_type = round(sd(index_numerique_moy, na.rm = TRUE), 3),
    .groups = "drop"
  )

# Graphique comparatif - Digital par niveau fournisseur
graph_digital_fourn <- ggplot(digital_fourn_T2, aes(x = niveau_fournisseur, y = index_numerique_moyen, fill = niveau_fournisseur)) +
  geom_col(alpha = 0.8) +
  labs(title = "Index de transformation digitale par niveau fournisseur (Période T2)",
       x = "Niveau de classification fournisseurs",
       y = "Index numérique moyen") +
  theme_minimal() +
  theme(legend.position = "none")

ggsave("resultats/moderateurs/digital_par_niveau_fournisseur.png", graph_digital_fourn, width = 8, height = 5, dpi = 300)

# 3. Effet modérateur de la chaîne verte ---------------------------------------
# On calcule la proportion d'entreprises à chaîne verte dans chaque cluster

# --- Côté fournisseurs
verte_fourn_T2 <- donnees_T2 %>%
  group_by(niveau_fournisseur) %>%
  summarise(
    effectif_total = n(),
    effectif_vert = sum(chaine_verte == 1, na.rm = TRUE),
    taux_verte = round(effectif_vert / effectif_total * 100, 1),
    .groups = "drop"
  )

# --- Côté clients
verte_clients_T2 <- donnees_T2 %>%
  group_by(niveau_client) %>%
  summarise(
    effectif_total = n(),
    effectif_vert = sum(chaine_verte == 1, na.rm = TRUE),
    taux_verte = round(effectif_vert / effectif_total * 100, 1),
    .groups = "drop"
  )

# Graphique - Taux de chaîne verte par niveau fournisseur
graph_verte_fourn <- ggplot(verte_fourn_T2, aes(x = niveau_fournisseur, y = taux_verte, fill = niveau_fournisseur)) +
  geom_col(alpha = 0.8) +
  labs(title = "Taux d'entreprises à chaîne verte par niveau fournisseur (T2)",
       x = "Niveau de classification fournisseurs",
       y = "Taux de chaîne verte (%)") +
  theme_minimal() +
  theme(legend.position = "none")

ggsave("resultats/moderateurs/verte_par_niveau_fournisseur.png", graph_verte_fourn, width = 8, height = 5, dpi = 300)

# Test du Chi-deux pour vérifier si la différence est statistiquement significative
table_contingence_fourn <- table(donnees_T2$niveau_fournisseur, donnees_T2$chaine_verte)
test_chi2_fourn <- chisq.test(table_contingence_fourn)

# 4. Analyse de la performance économique par cluster --------------------------
# On compare le ROAA moyen selon chaque classification

# --- Performance par niveau fournisseur
perf_fourn_T2 <- donnees_T2 %>%
  group_by(niveau_fournisseur) %>%
  summarise(
    roaa_moyen = round(mean(roaa_moy, na.rm = TRUE), 3),
    .groups = "drop"
  )

# --- Performance par niveau client
perf_client_T2 <- donnees_T2 %>%
  group_by(niveau_client) %>%
  summarise(
    roaa_moyen = round(mean(roaa_moy, na.rm = TRUE), 3),
    .groups = "drop"
  )

# 5. Sauvegarde des tableaux de résultats (format CSV standard virgule) --------
write_csv(digital_fourn_T2, "resultats/moderateurs/digital_fournisseurs_T2.csv")
write_csv(verte_fourn_T2, "resultats/moderateurs/verte_fournisseurs_T2.csv")
write_csv(perf_fourn_T2, "resultats/moderateurs/performance_fournisseurs_T2.csv")

# 6. Bilan console -------------------------------------------------------------
cat("✅ Analyse des effets modérateurs terminée\n")
cat("----------------------------------------\n")
cat("\n--- Index digital par niveau fournisseur ---\n")
print(digital_fourn_T2)
cat("\n--- Taux de chaîne verte par niveau fournisseur ---\n")
print(verte_fourn_T2)
cat("\n--- Test Chi-deux chaîne verte / niveau fournisseur ---\n")
cat("p-value :", test_chi2_fourn$p.value, "\n")
cat("\n--- ROAA moyen par niveau fournisseur ---\n")
print(perf_fourn_T2)
cat("\n\n--- Index digital par niveau client ---\n")
print(digital_clients_T2)
cat("\n--- Taux de chaîne verte par niveau client ---\n")
print(verte_clients_T2)
cat("\n--- ROAA moyen par niveau client ---\n")
print(perf_client_T2)

# Test chi‑deux pour clients
table_contingence_client <- table(donnees_T2$niveau_client, donnees_T2$chaine_verte)
test_chi2_client <- chisq.test(table_contingence_client)
cat("\n--- Test Chi‑deux chaîne verte / niveau client ---\n")
cat("p‑value clients :", test_chi2_client$p.value, "\n")