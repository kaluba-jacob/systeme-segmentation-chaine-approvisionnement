# Système de segmentation double de la chaîne d'approvisionnement
> Étude empirique sur entreprises cotées : classification fournisseurs × clients, effets modérateurs de la transformation digitale et de la chaîne verte, et impact sur la performance économique.
> Empirical study on listed companies: supplier–customer classification, moderating effects of digital transformation and green supply chain, and impact on economic performance.


## 📋 Présentation du projet
Ce projet développe un système de segmentation bidirectionnel de la chaîne d'approvisionnement appliqué à un échantillon d'entreprises chinoises cotées sur deux périodes :
- **Période T1** : 2015 – 2018 (avant la pandémie)
- **Période T2** : 2019 – 2023 (pandémie et reprise post‑Covid)

L'objectif est de classifier les entreprises selon la structure de leur base fournisseurs et de leur portefeuille clients, puis d'étudier :
1.  La migration structurelle entre les deux périodes
2.  L'effet modérateur de la transformation digitale
3.  L'effet modérateur de l'adoption d'une chaîne verte
4.  L'impact de la classification sur la performance économique (ROAA)
5.  L'évolution de cette relation avant et après la crise sanitaire
6.  Modélisation prédictive machine learning : prédire rentabilité et risque fournisseur

## 🎯 Objectifs de recherche
- Construire une typologie des structures de chaîne d'approvisionnement par clustering K‑means
- Mesurer la résilience structurelle des entreprises avant et après la crise sanitaire
- Évaluer si la digitalisation renforce la performance des différentes configurations
- Tester l'association entre chaîne verte et profils de chaîne d'approvisionnement
- Estimer économétriquement l'impact de la classification sur la rentabilité
- Vérifier la robustesse des résultats et corriger les biais d'endogénéité
- Développer des modèles prédictifs pour anticiper la rentabilité et le risque fournisseur des entreprises

## 📊 Données
Échantillon de **3 227 entreprises** sur la période la plus récente (T2), avec 1 674 entreprises présentes sur les deux périodes (panel équilibré).

**Sources** : Données financières et de chaîne d'approvisionnement d'entreprises cotées.

**Indicateurs de clustering** :
- Côté fournisseurs : concentration, volatilité, ratio de dépendance capitalistique, taux de livraison à l'heure, taux de défaut
- Côté clients : concentration clientèle, volatilité du chiffre d'affaires, ratio de flux, délai de paiement, taux de retour

## 🛠️ Méthodologie
Le projet est structuré en 6 scripts reproductibles :

### Étape 1 : Prétraitement des données
`R/01_pretraitement_donnees.R`
- Nettoyage et agrégation par période
- Construction des indicateurs de structure de chaîne
- Winsorisation à 1 % des valeurs extrêmes
- Standardisation Z‑score

### Étape 2 : Clustering K‑means et analyse de migration
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
- Test du Chi‑deux d'indépendance
- Performance économique (ROAA) par profil

### Étape 4 : Modèles économétriques de base
`R/04_regressions_econometriques.R`
- Régressions OLS avec erreurs standards robustes à l'hétéroscédasticité
- Effets fixes secteur
- Variables de contrôle : croissance des actifs, productivité verte, nature de la propriété
- Modèles d'interaction pour tester les effets modérateurs

### Étape 5 : Approfondissement économétrique et robustesse
`R/05_approfondissement_econometrique.R`
- Tests de robustesse sur échantillon restreint (exclusion des valeurs extrêmes)
- Analyse hétérogène par niveau de digitalisation
- Correction d'endogénéité par appariement sur score de propension (PSM)
- Comparaison des effets sur les périodes T1 et T2

### Étape 6 : Modélisation prédictive Machine Learning
`R/06_modelisation_predictive.R`
- Modèle de régression : prédire la rentabilité ROAA
- Modèle de classification forêt aléatoire : détecter les entreprises à risque fournisseur
- Séparation train/test 80 % / 20 %
- Calcul des métriques de performance et importance des variables
- Sauvegarde des modèles entraînés au format `.rds`

## 📌 Principaux résultats
### Classification
- **4 profils fournisseurs** : du profil vulnérable (forte concentration, faible résilience) au profil diversifié et résilient
- **3 profils clients** : du profil concentré au profil diversifié et performant
- Toutes les répartitions sont statistiquement exploitables

### Effets modérateurs
- L'adoption de chaîne verte diffère significativement entre clusters (test Chi‑deux, p < 0,001)
- Les clusters fournisseurs les plus performants présentent un niveau de digitalisation supérieur
- Le cluster le plus vulnérable cumule faible digitalisation, faible taux de chaîne verte et rentabilité inférieure

### Impact sur la performance (période T2)
- Appartenir aux meilleurs clusters fournisseurs est associé à un **ROAA supérieur de 3 à 4 points** par rapport au groupe de référence, après contrôle des variables de confusion
- L'effet est statistiquement très significatif (p < 0,001)
- La digitalisation ne présente pas d'effet modérateur additionnel significatif sur la relation chaîne–performance

#### Répartition des clusters (période T2)
| Niveau fournisseur | Effectif | Part   | Profil associé                                        |
|:-------------------|:--------:|:------:|:------------------------------------------------------|
| 1                  |   190    |  6,6 % | Vulnérable : concentration élevée, faible résilience  |
| 2                  |  1 411   | 48,9 % | Intermédiaire : structure équilibrée majoritaire      |
| 3                  |   615    | 21,3 % | Performant : diversification et maîtrise des risques  |
| 4                  |   672    | 23,3 % | Diversifié : base fournisseurs étendue                |

| Niveau client | Effectif | Part   | Profil associé                              |
|:--------------|:--------:|:------:|:--------------------------------------------|
| 1             |   361    | 12,5 % | Concentré : forte dépendance clientèle      |
| 2             |   885    | 30,6 % | Intermédiaire : portefeuille équilibré      |
| 3             |  1 642   | 56,9 % | Diversifié : clientèle large et résiliente  |

#### Impact de la classification sur la rentabilité
Résultats des régressions avec contrôles et effets fixes secteur :
| Groupe                  | Écart de ROAA par rapport au groupe de référence | Niveau de significativité |
|:------------------------|:------------------------------------------------:|:-------------------------:|
| Fournisseurs niveau 2   |                   + 3,7 points                   |       *** p < 0,001       |
| Fournisseurs niveau 3   |                   + 3,9 points                   |       *** p < 0,001       |
| Fournisseurs niveau 4   |                   + 3,3 points                   |        ** p < 0,01        |
| Clients niveau 3        |                   + 1,7 points                   |        ** p < 0,05        |

#### Effet causal de la chaîne verte (après appariement PSM)
| Groupe                          | ROAA moyen |
|:--------------------------------|:----------:|
| Entreprises sans chaîne verte   |   4,06 %   |
| Entreprises avec chaîne verte   |   5,51 %   |
| **Gain moyen de rentabilité**   | **+ 1,45 point** |

#### Inversion de la hiérarchie avant / après pandémie
Effet du groupe fournisseurs niveau 2 par rapport au groupe 1 :
| Période             | Effet sur la ROAA  | Interprétation                                       |
|:--------------------|:------------------:|:-----------------------------------------------------|
| T1 (2015 – 2018)    |  – 1,8 point ***   | La concentration fournisseur était plus rentable      |
| T2 (2019 – 2023)    |  + 3,7 points ***  | La diversification résiliente devient plus performante |

### Résultat majeur : inversion de la hiérarchie entre T1 et T2
La crise sanitaire a profondément modifié la relation entre structure de chaîne et performance :
- **Avant la pandémie (T1)** : les structures concentrées (cluster 1) étaient plus rentables que les structures diversifiées
- **Après la pandémie (T2)** : les structures diversifiées et résilientes (clusters 2 et 3) deviennent significativement plus performantes

> Ce renversement de la hiérarchie met en évidence la valeur de la résilience de la chaîne d'approvisionnement en période de choc.

### Effet causal de la chaîne verte (PSM)
Après appariement sur score de propension pour neutraliser les biais de sélection :
- Les entreprises ayant adopté une chaîne verte présentent un **ROAA supérieur de 1,45 point** par rapport à des entreprises comparables sans chaîne verte
- L'effet est robuste et confirme l'existence d'un gain économique lié à la transition verte

### Tests de robustesse
- Les résultats principaux restent significatifs après exclusion des valeurs extrêmes de ROAA
- L'effet de la classification est présent dans les deux groupes de digitalisation, mais plus marqué dans les entreprises faiblement digitalisées

### 🤖 Résultats Modélisation Prédictive (Machine Learning)
Deux modèles entraînés sur jeu d’entraînement 80 %, évalués sur jeu de test 20 %.

#### Modèle 1 : Régression (prédiction de la rentabilité ROAA)
| Modèle               | RMSE      | R² (jeu de test) |
|:---------------------|:---------:|:----------------:|
| Régression linéaire  | 0,05277   | 0,164            |
| Forêt aléatoire      | 0,04681   | 0,329            |

👉 La forêt aléatoire améliore nettement la prédiction par rapport à la régression linéaire simple.

**Top 5 variables prédictives de la rentabilité :**
1. croissance des actifs
2. concentration clients
3. concentration fournisseurs
4. nature de la propriété
5. chaîne verte

#### Modèle 2 : Classification (détection des entreprises vulnérables côté fournisseurs)
Forêt aléatoire pour distinguer les profils `vulnerable` / `resilient`.

**Top 5 variables prédictives du risque fournisseur :**
1. croissance des actifs
2. concentration clients
3. productivité verte
4. concentration fournisseurs
5. volatilité du chiffre d’affaires

> Enseignement clé ML : la concentration du portefeuille client est un facteur de risque aussi important que la concentration de la base fournisseurs.

## 💡 Implications managériales et recommandations stratégiques
Au‑delà des résultats statistiques, cette segmentation fournit des pistes d’action concrètes pour les directions de la chaîne d’approvisionnement.

### Recommandations par profil de classification
#### Côté fournisseurs
| Profil | Diagnostic stratégique | Recommandations opérationnelles |
|:---|:---|:---|
| **Niveau 1 – Vulnérable** | Forte concentration, exposition majeure aux risques de rupture | 🚨 **Priorité haute** : lancer immédiatement un programme de diversification fournisseurs ; constituer un pool de fournisseurs de secours ; réduire la dépendance vis‑à‑vis des fournisseurs critiques |
| **Niveau 2 – Intermédiaire** | Structure équilibrée majoritaire, risque modéré | ⚙️ **Optimisation** : maintenir l’équilibre actuel ; travailler sur la réduction des coûts par regroupement de commandes ; développer la digitalisation des échanges |
| **Niveau 3 – Performant** | Bonne diversification et maîtrise des risques | 🤝 **Partenariat stratégique** : considérer ce périmètre comme le socle fournisseur de référence ; négocier des cadres de coopération à long terme ; mutualiser les efforts d’amélioration continue |
| **Niveau 4 – Diversifié** | Base très étendue, complexité de gestion élevée | 📊 **Rationalisation** : consolider la base fournisseurs sur les articles à faible risque ; garder la diversification sur les postes stratégiques ; harmoniser les contrats et les processus |

#### Côté clients
| Profil | Diagnostic stratégique | Recommandations opérationnelles |
|:---|:---|:---|
| **Niveau 1 – Concentré** | Forte dépendance vis‑à‑vis de quelques clients majeurs | ⚠️ **Réduction du risque** : développer activement de nouveaux clients pour diminuer la concentration ; mettre en place des contrats pluriannuels pour sécuriser le chiffre d’affaires |
| **Niveau 2 – Intermédiaire** | Portefeuille équilibré | 🎯 **Croissance ciblée** : maintenir la mixité client ; concentrer les efforts commerciaux sur les segments les plus rentables |
| **Niveau 3 – Diversifié** | Clientèle large, faible risque de concentration | ✅ **Standardisation** : généraliser les processus de livraison et de service client ; optimiser les coûts de gestion grâce à la standardisation des offres |

### Enseignement clé : la résilience est devenue un actif économique
Le résultat le plus marquant de l’étude est le **renversement complet de la hiérarchie de performance** entre les deux périodes :

> Avant la pandémie, une structure de chaîne concentrée permettait de meilleures marges grâce aux effets d’échelle et à l’optimisation des coûts.
> Après la crise sanitaire, les entreprises disposant d’une chaîne diversifiée et résiliente affichent une rentabilité significativement supérieure.

**Conclusion managériale** :
Le passage d’une logique de **« cost optimization »** à une logique de **« resilience optimization »** n’est pas seulement un choix de prudence, c’est un investissement qui se traduit par un gain mesurable de rentabilité en période d’incertitude.

## 📂 Structure du projet
- **`R/`** : Scripts d'analyse exécutables dans l'ordre numérique
  - `01_pretraitement_donnees.R` : Nettoyage, agrégation par période, winsorisation et standardisation
  - `02_clustering_kmeans.R` : Classification K‑means double + analyse de migration T1/T2
  - `03_analyse_moderateurs.R` : Étude des effets digital et chaîne verte par cluster
  - `04_regressions_econometriques.R` : Modèles OLS avec effets fixes et erreurs robustes
  - `05_approfondissement_econometrique.R` : Robustesse, hétérogénéité et PSM
  - `06_modelisation_predictive.R` : Modélisation ML régression + classification risque fournisseur

- **`donnees/`** : Fichiers de données intermédiaires au format `.rds`
  - Les données brutes et fichiers générés sont ignorés par `.gitignore`

- **`resultats/`** : Sorties automatiques de l'analyse
  - `clustering/` : Graphiques du coude, profils des clusters, matrices de migration
  - `moderateurs/` : Tableaux et graphiques sur les effets modérateurs
  - `regressions/` : Tableaux des modèles économétriques de base
  - `robustesse/` : Tableaux des tests de robustesse, hétérogénéité et PSM
  - `predictif/` : Métriques ML, importance variables, modèles `.rds` sauvegardés

- Fichiers racine
  - `.gitignore` : Fichiers à exclure du versionnement
  - `README.md` : Documentation du projet
  - `systeme‑segmentation‑chaine‑approvisionnement.Rproj` : Projet RStudio

## 🚀 Pour reproduire l'analyse
1.  Cloner le dépôt
2.  Placer le fichier de données brutes `data2.xlsx` dans le dossier `donnees/`
3.  Exécuter les scripts dans l'ordre numérique de 01 à 06
4.  Tous les résultats (graphiques et tableaux CSV) sont générés automatiquement dans le dossier `resultats/`

## 🧰 Technologies utilisées
- **R 4.5.3**
- `tidyverse` pour la manipulation de données et la visualisation
- `readxl` pour l'import Excel
- `factoextra` pour la détermination du nombre de clusters
- `fixest` pour les régressions à haute performance et erreurs robustes
- `MatchIt` pour l'appariement sur score de propension (PSM)
- `randomForest` pour la modélisation prédictive
- `caret` pour la séparation train/test et métriques de classification

## 📝 Auteur
Projet réalisé par **kaluba luboya jacob** dans le cadre d'un travail de recherche sur la résilience des chaînes d'approvisionnement et la transformation verte.