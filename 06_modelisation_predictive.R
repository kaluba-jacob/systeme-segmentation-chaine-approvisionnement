# ------------------------------------------------------------------------------
# Projet : Système de segmentation double de la chaîne d'approvisionnement
# Étape 6 : Modélisation prédictive (Machine Learning)
# Objectif : Prédire la rentabilité et le profil de risque des entreprises
# ------------------------------------------------------------------------------
# Chargement des packages
library(tidyverse)
library(randomForest)
library(caret)
# Création du dossier de sortie
dir.create("resultats/predictif", showWarnings = FALSE, recursive = TRUE)
# 1. Préparation des données ---------------------------------------------------
donnees_T2 <- readRDS("donnees/donnees_clustering_T2.rds")
data_model <- donnees_T2 %>%
  mutate(
    # Variable cible 1 : régression (prédire la rentabilité)
    roaa = roaa_moy,
    
    # Variable cible 2 : classification (profil vulnérable ou non)
    risque_fourn = factor(ifelse(niveau_fournisseur == 1, "vulnerable", "resilient")),
    
    # Prédicteurs : indicateurs de structure de chaîne + caractéristiques
    concentration_fourn = conc_fourn_moy,
    volatilite_fourn = volatilite_fourn,
    concentration_clients = conc_clients_moy,
    volatilite_ca = volatilite_ca,
    index_digital = index_numerique_moy,
    chaine_verte = factor(chaine_verte),
    croissance = croissance_actifs_moy,
    productivite_verte = pfte_verte_moy,
    propriete = factor(nature_propriete)
  ) %>%
  select(roaa, risque_fourn,
         concentration_fourn, volatilite_fourn,
         concentration_clients, volatilite_ca,
         index_digital, chaine_verte, croissance, productivite_verte, propriete) %>%
  drop_na()
# 2. Séparation Train / Test (80% / 20%) ---------------------------------------
set.seed(123)
index_train <- createDataPartition(data_model$roaa, p = 0.8, list = FALSE)
data_train <- data_model[index_train, ]
data_test  <- data_model[-index_train, ]
cat("✅ Données chargées et séparées\n")
cat("----------------------------------------\n")
cat(paste("Taille jeu d'entraînement :", nrow(data_train), "entreprises\n"))
cat(paste("Taille jeu de test :", nrow(data_test), "entreprises\n"))
# 3. Modèle 1 : Régression linéaire (référence) --------------------------------
modele_lm <- lm(roaa ~ . - risque_fourn, data = data_train)
pred_lm <- predict(modele_lm, newdata = data_test)
perf_lm <- data.frame(
  Modele = "Régression linéaire",
  RMSE = RMSE(pred_lm, data_test$roaa),
  R2 = R2(pred_lm, data_test$roaa)
)
cat("\n📊 Modèle 1 - Régression linéaire\n")
cat("----------------------------------------\n")
print(perf_lm, row.names = FALSE)
# 4. Modèle 2 : Forêt aléatoire (Machine Learning) -----------------------------
set.seed(123)
modele_rf <- randomForest(
  roaa ~ . - risque_fourn,
  data = data_train,
  ntree = 150,          ### MODIFIÉ : passé de 200 à 150
  importance = TRUE
)
pred_rf <- predict(modele_rf, newdata = data_test)
perf_rf <- data.frame(
  Modele = "Forêt aléatoire",
  RMSE = RMSE(pred_rf, data_test$roaa),
  R2 = R2(pred_rf, data_test$roaa)
)
cat("\n📊 Modèle 2 - Forêt aléatoire\n")
cat("----------------------------------------\n")
print(perf_rf, row.names = FALSE)
# 5. Tableau comparatif final --------------------------------------------------
tableau_perf <- bind_rows(perf_lm, perf_rf) %>%
  mutate(
    RMSE = round(RMSE, 5),
    R2 = round(R2, 3)
  )
write_csv(tableau_perf, "resultats/predictif/performances_regression.csv")
cat("\n🏆 Tableau comparatif des performances\n")
cat("----------------------------------------\n")
print(tableau_perf, row.names = FALSE)
# 6. Importance des variables (régression) ------------------------------------
importance_vars <- as.data.frame(importance(modele_rf)) %>%
  rownames_to_column("Variable") %>%
  arrange(desc(`%IncMSE`)) %>%
  select(Variable, `%IncMSE`) %>%
  mutate(`%IncMSE` = round(`%IncMSE`, 2))
write_csv(importance_vars, "resultats/predictif/importance_variables.csv")
cat("\n🔝 Top 5 variables les plus prédictives de la rentabilité\n")
cat("----------------------------------------\n")
print(head(importance_vars, 5), row.names = FALSE)
# 7. Modèle de classification : prédire le risque fournisseur ------------------
set.seed(123)
modele_rf_classif <- randomForest(
  risque_fourn ~ . - roaa,
  data = data_train,
  ntree = 150,          ### MODIFIÉ : passé de 200 à 150
  importance = TRUE
)
# Prédiction sur jeu de test
pred_classif <- predict(modele_rf_classif, newdata = data_test)
# Matrice de confusion
matrice_confusion <- confusionMatrix(pred_classif, data_test$risque_fourn)
cat("\n⚠️ Modèle classification : risque fournisseur\n")
cat("----------------------------------------\n")
print(matrice_confusion$table)
# Métriques globaux (évite erreur dimension sur byClass)
perf_classif <- data.frame(
  Modele = "Forêt aléatoire - Classification risque fournisseur",
  Accuracy = round(matrice_confusion$overall["Accuracy"], 3),
  Kappa = round(matrice_confusion$overall["Kappa"], 3)
)
print(perf_classif, row.names = FALSE)
# Export résultats
write_csv(as.data.frame(matrice_confusion$table), "resultats/predictif/matrice_confusion.csv")
write_csv(perf_classif, "resultats/predictif/performance_classification.csv")
# Importance variables pour la classification
importance_classif <- as.data.frame(importance(modele_rf_classif)) %>%
  rownames_to_column("Variable") %>%
  arrange(desc(MeanDecreaseGini)) %>%
  select(Variable, MeanDecreaseGini) %>%
  mutate(MeanDecreaseGini = round(MeanDecreaseGini, 2))
write_csv(importance_classif, "resultats/predictif/importance_classif.csv")
cat("\n🔝 Top 5 variables prédictives du risque fournisseur\n")
cat("----------------------------------------\n")
print(head(importance_classif,5), row.names = FALSE)
# 8. Sauvegarde des modèles pour réutilisation future --------------------------
saveRDS(modele_lm, "resultats/predictif/modele_lm.rds")
saveRDS(modele_rf, "resultats/predictif/modele_rf.rds")
saveRDS(modele_rf_classif, "resultats/predictif/modele_rf_classif.rds")
cat("\n✅ Fin de l'étape 6, tous les fichiers exportés dans resultats/predictif/\n")
