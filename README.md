# Système de segmentation double de la chaîne d'approvisionnement

> Étude empirique sur entreprises cotées : classification fournisseurs × clients, effets modérateurs de la transformation digitale et de la chaîne verte, et impact sur la performance économique.

## 📋 Présentation du projet

Ce projet développe un système de segmentation bidirectionnel de la chaîne d'approvisionnement appliqué à un échantillon d'entreprises chinoises cotées sur deux périodes :
- **Période T1** : 2015 – 2018 (avant la pandémie)
- **Période T2** : 2019 – 2023 (pandémie et reprise post-Covid)

L'objectif est de classifier les entreprises selon la structure de leur base fournisseurs et de leur portefeuille clients, puis d'étudier :
1.  La migration structurelle entre les deux périodes
2.  L'effet modérateur de la transformation digitale
3.  L'effet modérateur de l'adoption d'une chaîne verte
4.  L'impact de la classification sur la performance économique (ROAA)

## 🎯 Objectifs de recherche

- Construire une typologie des structures de chaîne d'approvisionnement par clustering K-means
- Mesurer la résilience structurelle des entreprises avant et après la crise sanitaire
- Évaluer si la digitalisation renforce la performance des différentes configurations
- Tester l'association entre chaîne verte et profils de chaîne d'approvisionnement
- Estimer économétriquement l'impact de la classification sur la rentabilité

## 📊 Données

Échantillon de **3 227 entreprises** sur la période la plus récente (T2), avec 1 674 entreprises présentes sur les deux périodes (panel équilibré).

**Sources** : Données financières et de chaîne d'approvisionnement d'entreprises cotées.

**Indicateurs de clustering** :
- Côté fournisseurs : concentration, volatilité, ratio de dépendance capitalistique, taux de livraison à l'heure, taux de défaut
- Côté clients : concentration clientèle, volatilité du chiffre d'affaires, ratio de flux, délai de paiement, taux de retour

## 🛠️ Méthodologie

Le projet est structuré en 4 scripts reproductibles :

### Étape 1 : Prétraitement des données
`R/01_pretraitement_donnees.R`
- Nettoyage et agrégation par période
- Construction des indicateurs de structure de chaîne
- Simulation d'indicateurs métier complémentaires
- Winsorisation à 1% des valeurs extrêmes
- Standardisation Z-score

### Étape 2 : Clustering K-means et analyse de migration
`R/02_clustering_kmeans.R`
- Détermination du nombre optimal de clusters (méthode du coude)
- Classification 4 niveaux côté fournisseurs
- Classification 3 niveaux côté clients
- Matrice de migration T1 → T2 sur panel équilibré
- Analyse croisée double extrémité

### Étape 3 : Analyse des effets modérateurs
`R/03_analyse_moderateurs.R`
- Index de digitalisation moyen par cluster
- Taux d'adoption de chaîne verte par cluster
- Test du Chi-deux d'indépendance
- Performance économique (ROAA) par profil

### Étape 4 : Modèles économétriques
`R/04_regressions_econometriques.R`
- Régressions OLS avec erreurs standards robustes à l'hétéroscédasticité
- Effets fixes secteur
- Variables de contrôle : croissance des actifs, productivité verte, nature de la propriété
- Modèles d'interaction pour tester les effets modérateurs

## 📌 Principaux résultats

### Classification
- **4 profils fournisseurs** : du profil vulnérable (faible digital, forte concentration) au profil résilient
- **3 profils clients** : du profil concentré au profil diversifié et performant
- Toutes les répartitions sont statistiquement exploitables

### Effets modérateurs
- L'adoption de chaîne verte diffère significativement entre clusters (test Chi-deux, p < 0,001)
- Les clusters fournisseurs les plus performants présentent un niveau de digitalisation supérieur
- Le cluster le plus vulnérable cumule faible digitalisation, faible taux de chaîne verte et rentabilité inférieure

### Impact sur la performance
- Appartenir aux meilleurs clusters fournisseurs est associé à un **ROAA supérieur de 3 à 4 points** par rapport au groupe de référence, après contrôle des variables de confusion
- L'effet est statistiquement très significatif (p < 0,001)
- La digitalisation ne présente pas d'effet modérateur additionnel significatif sur la relation chaîne–performance

## 📁 Structure du projet

```
R/ : Scripts d'analyse exécutables dans l'ordre numérique
01_pretraitement_donnees.R : Nettoyage, agrégation par période, winsorisation et standardisation
02_clustering_kmeans.R : Classification K-means double + analyse de migration T1/T2
03_analyse_moderateurs.R : Étude des effets digital et chaîne verte par cluster
04_regressions_econometriques.R : Modèles OLS avec effets fixes et erreurs robustes
donnees/ : Fichiers de données intermédiaires au format .rds
Les données brutes et fichiers générés sont ignorés par .gitignore
resultats/ : Sorties automatiques de l'analyse
clustering/ : Graphiques du coude, profils des clusters, matrices de migration
moderateurs/ : Tableaux et graphiques sur les effets modérateurs
regressions/ : Tableaux des modèles économétriques exportés en CSV
Fichiers racine
.gitignore : Fichiers à exclure du versionnement
README.md : Documentation du projet
systeme-segmentation-chaine-approvisionnement.Rproj : Projet RStudio
```

## 🚀 Pour reproduire l'analyse

1.  Cloner le dépôt
2.  Placer le fichier de données brutes `data2.xlsx` dans le dossier `donnees/`
3.  Exécuter les scripts dans l'ordre numérique
4.  Tous les résultats (graphiques et tableaux CSV) sont générés automatiquement dans le dossier `resultats/`

## 🧰 Technologies utilisées

- **R 4.5.3**
- `tidyverse` pour la manipulation de données et la visualisation
- `readxl` pour l'import Excel
- `factoextra` pour la détermination du nombre de clusters
- `fixest` pour les régressions à haute performance et erreurs robustes

## 📝 Auteur

Projet réalisé par **[kaluba luboya jacob]** dans le cadre d'un travail de recherche sur la résilience des chaînes d'approvisionnement et la transformation verte.