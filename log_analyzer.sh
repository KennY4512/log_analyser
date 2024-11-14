#!/bin/bash

# Fonction de vérification des arguments 1 et 2
inputcheck () {

    if [ "$#" == "0" ]; then
        echo -e "\e[31;1mAucun paramètre donné !\n\e[0m"
        echo -e "\e[31;1mVeuillez spécifier l'un des 2 paramètres ci-dessous suivit d'un fichier log valable :\e[0m"
        echo -e "\e[31;1maggregate :\e[0m \e[31magrégation du fichier log\e[0m"
        echo -e "\e[31;1mtemporal_analysis :\e[0m \e[31manalyse temporelle du fichier log\n\e[0m"
        echo -e "\e[31;1mExemple d'appel :\e[0m \e[31m./log_analyser.sh aggregate logfile.log\e[0m"
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

    # Vérification de la présence, de la bonne syntax de l'argument 2 et du fichier log fourni
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

# Fonction de parsage et d'agrégation des donnés des logs
aggregate () {

    trace_count=0
    debug_count=0
    info_count=0
    warn_count=0
    error_count=0
    fatal_count=0

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

    msg_info=$(awk -F'msg="' '
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
        print most_common_msg ":" max_count
        print least_common_msg ":" min_count
    }' "$1")

    IFS=':' read -r most_common_msg most_common_msg_count <<< "$(echo "$msg_info" | head -n 1)"
    IFS=':' read -r least_common_msg least_common_msg_count <<< "$(echo "$msg_info" | tail -n 1)"

    echo "=-= Aggregating file \"$1\" =-="
    echo ""
    echo "Log level counts:"
    echo -e " - \e[90mtrace\e[0m: \e[90;1m$trace_count\e[0m"
    echo -e " - \e[34mdebug\e[0m: \e[34;1m$debug_count\e[0m"
    echo -e " - \e[32minfo\e[0m: \e[32;1m$info_count\e[0m"
    echo -e " - \e[33mwarn\e[0m: \e[33;1m$warn_count\e[0m"
    echo -e " - \e[31merror\e[0m: \e[31;1m$error_count\e[0m"
    echo -e " - \e[41mfatal\e[0m: \e[41;1m$fatal_count\e[0m"
    echo ""
    echo -e "Most common message: \"\e[1m$most_common_msg\e[0m\" (count: $most_common_msg_count)"
    echo -e "Least common message: \"\e[1m$least_common_msg\e[0m\" (count: $least_common_msg_count)"
    echo ""
    echo "=-= End of report =-="
}

# Nettoyage du terminal
clear

# Vérification des deux arguments passés
inputcheck $1 $2

if [ "$1" == "aggregate" ]; then
    aggregate $2
elif [ "$1" == "temporal_analysis" ]; then
    echo "to be dev"
fi