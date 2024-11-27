# Script Log Analyzer

## Description
Ce script Shell, `log_analyzer.sh`, a pour objectif d'analyser un fichier de logs.

Il propose deux fonctionnalités principales :

1. **Agrégation des logs** : Comptabiliser les occurrences de chaque niveau de log et identifier les messages les plus courants et les moins courants.

2. **Analyse temporelle** : Identifier les périodes de forte activité et les moments les plus sujets aux erreurs.

## Usage

### 1. Appel du script
Le script peut être exécuté avec les commandes suivantes :
```bash
$ ./log_analyzer.sh
```
```bash
$ bash log_analyzer.sh
```

### 2. Afficher l'aide
Si aucune commande n'est fournie, le script affiche une page d'aide décrivant les commandes disponibles.

```bash
$ ./log_analyzer.sh
```

Sortie :

> Aucun paramètre donné !
>
> Veuillez spécifier l'un des 2 paramètres ci-dessous suivit d'un fichier log valable :
> aggregate : agrégation du fichier log
> temporal_analysis : analyse temporelle du fichier log
>
> Exemple d'appel : ./log_analyser.sh aggregate logfile.log
>
> Exemple de format log attendu : [fatal] 2023-11-05T17:25:59.26159941+01:00 msg="division by zero"

### 3. Agrégation des logs
Cette commande génère un rapport sur les différents niveaux de logs en couleur et le message le plus et le moins récurrent.

```bash
$ ./log_analyzer.sh aggregate <logfile.log>
```

Exemple de sortie :

> =-= Aggregating file "logfile.log" =-=
>
> Log level counts:
>   - trace: 144
>   - debug: 90
>   - info:  77
>   - warn:  32
>   - error: 22
>   - fatal: 0
>
> Most common message: "user logged in" (count: 54)  
> Least common message: "backup failed" (count: 1)
>
> =-= End of report =-=

### 4. Analyse temporelle
Cette commande analyse les logs pour déterminer le jour le plus actif, l'heure la plus active ainsi que l'heure avec le plus d'erreurs (messages de niveau [fatal] et [error]).

```bash
$ ./log_analyzer.sh temporal_analysis <logfile.log>
```

Exemple de sortie :

> =-= "logfile.log" temporal analysis =-=
>
> Most active day: monday  
> Most active hour: 18h  
> Most error-prone hour: 9h
>
> =-= End of report =-=

## Format des fichiers de log
Le script prend en charge les fichiers de logs au format suivant :

> [log level] YYYY-MM-DDThh:mm:ss.xxxxxxxx+hh:mm msg="text"

Exemple :

> [trace] 2024-11-04T15:33:06.226302197+01:00 msg="backup completed"

## Installation
1. Téléchargez l'archive contenant le script.

2. Donner les droits d'exécution au script :

```bash
$ chmod +x log_analyzer.sh
```

## Développement et structure
Le script est structuré en plusieurs fonctions pour une lisibilité et une modularité optimales :

- aggregate : Effectue l'agrégation des niveaux de logs.
- temporal_analysis : Réalise l'analyse temporelle.
- inputcheck : Vérifie les arguments et affiche l'aide.

Chaque fonction est commentée pour faciliter la compréhension du code.

## Dépendances
Le script utilise 3 commandes issues de binaires qui sont awk, grep et sed. Le reste du programme est constitué de primitives du shell.

## Auteur
Développé par LANG Kenny, dans le cadre du TP évalué de scripting Shell pour l'Université Lyon 1 (LP ESSIR 2024-2025).