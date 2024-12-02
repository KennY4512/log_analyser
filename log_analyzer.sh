#!/bin/bash

# Fonction de vérification des arguments passés au script
# Objectif : Valider les arguments pour s'assurer qu'ils sont corrects et que les fichiers requis sont au bon format
# Résultats :
# - Affiche des messages d'erreur détaillés si les arguments sont incorrects
# - Arrête le script si des erreurs sont détectées
inputcheck () {

    # Affiche l'aide si aucun argument n'est fourni
    if [ "$4" == "0" ]; then
        echo -e "\e[31;1mAucun paramètre donné !\n\e[0m"
        echo -e "\e[31;1mVeuillez spécifier l'un des 2 paramètres ci-dessous suivi d'un fichier log valide :\e[0m"
        echo -e "\e[31;1maggregate :\e[0m \e[31magrégation du fichier log\e[0m"
        echo -e "\e[31;1mtemporal_analysis :\e[0m \e[31manalyse temporelle du fichier log\n\e[0m"
        echo -e "\e[31;1mOption de sortie CSV :\e[0m"
        echo -e "\e[31;1mcsv :\e[0m \e[31mcrée un fichier csv à la racine avec les resultats d'analyse\n\e[0m"
        echo -e "\e[31;1mExemple d'appel complet :\e[0m \e[31m./log_analyser.sh aggregate logfile.log csv\n\e[0m"
        echo -e "\e[31;1mExemple de format log attendu :\e[0m \e[31m[fatal] 2023-11-05T17:25:59.26159941+01:00 msg=\"division by zero\"\e[0m"
        exit 1
    fi

    # Vérification de la présence et de la syntaxe de l'argument 1
    if [ "$1" != "aggregate" ] && [ "$1" != "temporal_analysis" ]; then
        echo -e "\e[31;1mErreur :\nSyntaxe incorrecte pour le premier paramètre ! Attendu : 'aggregate' - 'temporal_analysis'\e[0m"
        exit 1
    fi

    # Vérification de la présence, de la syntaxe de l'argument 2 et du fichier log fourni
    if [ "$2" == "" ]; then
        echo -e "\e[31;1mErreur :\nVeuillez fournir un fichier de log à analyser !\e[0m"
        exit 1
    elif [[ ! -f "$2" ]]; then
        echo -e "\e[31;1mErreur :\nLe fichier de log fourni est introuvable !\e[0m"
        exit 1
    elif ! grep -q '^\[[A-Za-z]*\] [0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}.[0-9]\++[0-9]\{2\}:[0-9]\{2\} msg=".*"' "$2"; then
        echo -e "\e[31;1mErreur :\nLe contenu du fichier de log fourni n'est pas au bon format !\e[0m"
        exit 1
    fi

    # Vérification de la syntaxe de l'argument 3 s'il existe
    if [ "$3" != "" ] && [ "$3" != "csv" ]; then
        echo -e "\e[31;1mErreur :\nSyntaxe incorrecte pour le troisième paramètre ! (csv)\e[0m"
        exit 1
    fi
}

# Fonction d'agrégation des niveaux de log
# Objectif : Comptabiliser chaque niveau de log dans le fichier et identifier les messages les plus fréquents et les moins fréquents
# Résultats :
# - Affiche le nombre d'occurrences pour chaque niveau de log
# - Identifie les messages les plus fréquents et les moins fréquents
aggregate () {

    # Initialisation des compteurs pour chaque niveau de log à 0
    trace_count=0
    debug_count=0
    info_count=0
    warn_count=0
    error_count=0
    fatal_count=0

    # Comptage et sockage des quantités pour chaque niveau de log
    while IFS=: read -r level count; do
        case "$level" in
            "trace") trace_count=$count ;;
            "debug") debug_count=$count ;;
            "info") info_count=$count ;;
            "warn") warn_count=$count ;;
            "error") error_count=$count ;;
            "fatal") fatal_count=$count ;;
        esac
    done < <(awk -F'[][]' '
    {
        counts[$2]++
    }
    END {
        for (level in counts) {
            print level ":" counts[level]
        }
    }' "$1")

    # Identification du message le plus et le moins récurrent
    msg_info=$(awk -F 'msg="' '
    {
        msg = $2
        gsub(/".*/, "", msg)
        msg_counts[msg]++
    }
    END {
        max_count = 0
        min_count = 999999
        
        for (msg in msg_counts) {
            if (msg_counts[msg] > max_count) {
                max_count = msg_counts[msg]
                most_common_msg = msg
            }

            if (msg_counts[msg] < min_count) {
                min_count = msg_counts[msg]
                least_common_msg = msg
            }
        }

        print most_common_msg "\n" max_count "\n" least_common_msg "\n" min_count
    }' "$1")

    # Stockage des résultats précédents
    most_common_msg="$(echo "$msg_info" | sed -n 1p)"
    most_common_msg_count="$(echo "$msg_info" | sed -n 2p)"
    least_common_msg="$(echo "$msg_info" | sed -n 3p)"
    least_common_msg_count="$(echo "$msg_info" | sed -n 4p)"

    # Affichage des résultats
    echo -e "=-= Aggregating file \"\e[1m$1\e[0m\" =-="
    echo ""
    echo "Log level counts:"
    echo -e " - \e[90mtrace: \e[1m$trace_count\e[0m"
    echo -e " - \e[34mdebug: \e[1m$debug_count\e[0m"
    echo -e " - \e[32minfo: \e[1m$info_count\e[0m"
    echo -e " - \e[33mwarn: \e[1m$warn_count\e[0m"
    echo -e " - \e[31merror: \e[1m$error_count\e[0m"
    echo -e " - \e[41mfatal: \e[1m$fatal_count\e[0m"
    echo ""
    echo -e "Most common message: \"\e[1m$most_common_msg\e[0m\" (count: $most_common_msg_count)"
    echo -e "Least common message: \"\e[1m$least_common_msg\e[0m\" (count: $least_common_msg_count)"
    echo ""
    echo "=-= End of report =-="
}

# Fonction d'analyse temporelle des logs
# Objectif : Identifier les périodes les plus actives et problématiques dans le fichier de log
# Résultats :
# - Le jour de la semaine avec le plus de messages
# - L'heure avec le plus de messages
# - L'heure la plus sujette aux erreurs (fatal, error)
temporal_analysis () {

    # Détermination du jour de la semaine avec le plus de messages
    most_act_day_num=$(awk '{
        year = int(substr($2, 1, 4))
        month = int(substr($2, 6, 2))
        day = int(substr($2, 9, 2))

        if (month < 3) {
            month += 12
            year--
        }

        weekday = (day + int(13 * (month + 1) / 5) + year + int(year / 4) - int(year / 100) + int(year / 400)) % 7
        counts[weekday]++
    }
    END {
        max_count = 0

        for (day in counts) {
            if (counts[day] > max_count) {
                max_count = counts[day]
                m_act_d = day
            }
        }

        print m_act_d
    }' "$1")

    # Conversion du résultat précédent en jour de la semaine et stockage
    days=("saturday" "sunday" "monday" "tuesday" "wednesday" "thursday" "friday")
    most_active_day=${days[$most_act_day_num]}

    # Détermination de l'heure avec le plus de messages
    most_active_hour=$(awk '{
        counts[substr($2, 12, 2)+0]++
    }
    END {
        max_count = 0

        for (hour in counts) {
            if (counts[hour] > max_count) {
                max_count = counts[hour]
                m_act_h = hour
            }
        }

        print m_act_h "h"
    }' "$1")

    # Détermination de l'heure avec le plus de messages fatal et error
    most_errors_hour=$(awk -F '[][]' '{
        if ($2 == "fatal" || $2 == "error") {
            counts[substr($3, 13, 2)+0]++
        }
    }
    END {
        max_count = 0

        for (erp_hour in counts) {
            if (counts[erp_hour] > max_count) {
                max_count = counts[erp_hour]
                m_erp_h = erp_hour
            }
        }

        print m_erp_h "h"
    }' "$1")

    # Affichage des résultats
    echo -e "=-= \"\e[1m$1\e[0m\" temporal analysis =-="
    echo ""
    echo -e "Most active day: \e[1m$most_active_day\e[0m"
    echo -e "Most active hour: \e[1m$most_active_hour\e[0m"
    echo -e "\e[31mMost error-prone hour: \e[1m$most_errors_hour\e[0m"
    echo ""
    echo "=-= End of report =-="
}

# Fonction de génération des fichiers CSV
# Objectif : Exporter les résultats de l'agrégation ou de l'analyse temporelle dans un fichier CSV
# Résultats :
# - Crée un fichier CSV nommé avec un horodatage unique
# - Formate les données pour faciliter l'analyse dans des outils externes
csv () {

    # Récupération de la date et de l'heure pour le nom du fichier
    timestamp=$(date +"%Y%m%d_%H%M%S")

    # Vérification de l'action effectuée et écriture du CSV
    if [ "$1" == "aggregate" ]; then
        output_file="aggregate_$timestamp.csv"
        {
            echo "Log Level,Count"
            echo "trace,$trace_count"
            echo "debug,$debug_count"
            echo "info,$info_count"
            echo "warn,$warn_count"
            echo "error,$error_count"
            echo "fatal,$fatal_count"
        } >> "$output_file"
    elif [ "$1" == "temporal_analysis" ]; then
        output_file="temporal_$timestamp.csv"
        echo "Most Active Day,Most Active Hour,Most Error-Prone Hour" > "$output_file"
        echo "$most_active_day,$most_active_hour,$most_errors_hour" >> "$output_file"
    fi

    # Affichage de l'emplacement du CSV
    echo -e "\e\n[32mCSV file saved at : \e[1m$output_file\e[0m"
}

# Nettoyage du terminal
clear

# Vérification des deux arguments passés
inputcheck "$1" "$2" "$3" "$#"

# Appel de la fonction correspondant à l'argument passé
if [ "$1" == "aggregate" ]; then
    aggregate "$2" "$3"
elif [ "$1" == "temporal_analysis" ]; then
    temporal_analysis "$2" "$3"
fi

if [ "$3" == "csv" ]; then
    csv "$1"
fi
