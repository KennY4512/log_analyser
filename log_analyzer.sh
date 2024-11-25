#!/bin/bash

# Fonction de vérification des arguments 1 et 2
inputcheck () {

    # Affichage d'une aide s'il n'y a aucun argument passé
    if [ "$#" == "0" ]; then
        echo -e "\e[31;1mAucun paramètre donné !\n\e[0m"
        echo -e "\e[31;1mVeuillez spécifier l'un des 2 paramètres ci-dessous suivit d'un fichier log valable :\e[0m"
        echo -e "\e[31;1maggregate :\e[0m \e[31magrégation du fichier log\e[0m"
        echo -e "\e[31;1mtemporal_analysis :\e[0m \e[31manalyse temporelle du fichier log\n\e[0m"
        echo -e "\e[31;1mExemple d'appel :\e[0m \e[31m./log_analyser.sh aggregate logfile.log\n\e[0m"
        echo -e "\e[31;1mExemple de format log attendu :\e[0m \e[31m[fatal] 2023-11-05T17:25:59.26159941+01:00 msg=\"division by zero\"\e[0m"
        exit 1
    fi

    # Vérification de la présence et de la syntax de l'argument 1
    if [ "$1" == "" ]; then
        echo -e "\e[31;1mErreur :\nVeuillez fournir une action à réaliser ! (aggregate - temporal_analysis)\e[0m"
        exit 1
    elif [ "$1" != "aggregate" -a "$1" != "temporal_analysis" ]; then
        echo -e "\e[31;1mErreur :\nSyntax incorrecte dans le premier paramètre ! (aggregate - temporal_analysis)\e[0m"
        exit 1
    fi

    # Vérification de la présence, de la syntax de l'argument 2 et du fichier log fourni
    if [ "$2" == "" ]; then
        echo -e "\e[31;1mErreur :\nVeuillez fournir un fichier de log à analyser !\e[0m"
        exit 1
    elif [[ ! -f "$2" ]]; then
        echo -e "\e[31;1mErreur :\nLe fichier de log fourni est introuvable !\e[0m"
        exit 1
    elif ! grep -q '^\[[A-Za-z]*\] [0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}.[0-9]\++[0-9]\{2\}:[0-9]\{2\} msg=".*"' $2; then
        echo -e "\e[31;1mErreur :\nLe contenu du fichier de log fourni n'est pas au bon format !\e[0m"
        exit 1
    fi
}

# Fonction de parsage et d'agrégation des logs
aggregate () {

    # Initialisation des variables de niveau de log à 0
    trace_count=0
    debug_count=0
    info_count=0
    warn_count=0
    error_count=0
    fatal_count=0

    # Comptage et sockage des quantité de chaque niveau de log
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

    # Comptage de chaque message du plus et du moins récurent
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

    # Stockage des résultats précedents
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
temporal_analysis () {

    # Comptage du jour de la semaine avec le plus de messages
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

    # Convertion du résultat précédent en jour de la semaine et stockage
    days=("saturday" "sunday" "monday" "tuesday" "wednesday" "thursday" "friday")
    most_active_day=${days[$most_act_day_num]}

    # Comptage de l'heure avec le plus de messages
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

    # Comptage de l'heure avec le plus de messages fatal et error
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

# Nettoyage du terminal
clear

# Vérification des deux arguments passés
inputcheck $1 $2

# Appel de la fonction correspondant à l'argument passé
if [ "$1" == "aggregate" ]; then
    aggregate $2
elif [ "$1" == "temporal_analysis" ]; then
    temporal_analysis $2
fi