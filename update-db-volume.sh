#!/bin/bash

# Script pour changer le volume de base de données en fonction de la branche Git actuelle

# Fonction pour afficher l'aide
show_help() {
    echo "Utilisation: ./update-db-volume.sh [OPTION]"
    echo ""
    echo "Script pour gérer les volumes de base de données PostgreSQL en fonction de la branche Git active."
    echo ""
    echo "Options:"
    echo "  --no-interaction, -n    Mode non-interactif, accepte automatiquement les changements"
    echo "  --help, -h              Affiche cette aide et quitte"
    echo ""
    echo "Description:"
    echo "  Ce script adapte le nom du volume de la base de données dans docker-compose.yml"
    echo "  en fonction de la branche Git actuelle. Pour la branche 'main', le volume standard"
    echo "  'db-data' est utilisé. Pour les autres branches, un volume spécifique à la branche"
    echo "  est créé au format 'db-data-[nom-branche]'."
    echo ""
    echo "Exemples:"
    echo "  ./update-db-volume.sh              # Mode interactif standard"
    echo "  ./update-db-volume.sh -n           # Mode non-interactif (accepte automatiquement)"
    echo ""
}

# Traiter les options de ligne de commande
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_help
    exit 0
fi

# Fonction pour vérifier si le script est exécuté en mode interactif
is_interactive() {
    # Si le script est lancé depuis un terminal interactif
    [ -t 0 ]
}

# Chemin vers le fichier docker-compose.yml
COMPOSE_FILE="docker/docker-compose.yml"

# Obtenir le nom de la branche Git actuelle (nettoyer les caractères spéciaux)
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD | sed 's/[^a-zA-Z0-9_-]/-/g')
if [ "$CURRENT_BRANCH" = "main" ]; then
    echo "Branche main détectée. Conservation du volume d'origine (db-data)."

    # Vérifier si le fichier a été modifié et restaurer l'original si nécessaire
    if grep -q "db-data-" "$COMPOSE_FILE"; then
        if [ -f "${COMPOSE_FILE}.bak" ]; then
            cp "${COMPOSE_FILE}.bak" "$COMPOSE_FILE"
            echo "Le fichier docker-compose.yml a été restauré avec le volume d'origine."
        else
            # Restaurer manuellement le nom du volume original
            sed -i "s/db-data-[^:]*:/db-data:/g" "$COMPOSE_FILE"
            echo "Le nom du volume a été restauré à db-data."
        fi

        echo "Pour appliquer les changements, redémarrez vos conteneurs avec:"
        echo "docker-compose down && docker-compose up -d"
    else
        echo "Le volume est déjà configuré correctement pour la branche main."
    fi

    exit 0
fi

# Pour les autres branches, demander confirmation
VOLUME_NAME="db-data-${CURRENT_BRANCH}"

# Si c'est un hook automatique non-interactif, afficher les instructions manuelles
# Si c'est un hook automatique non-interactif, afficher les instructions manuelles
if ! is_interactive; then
    echo "----------------------------------------------------------"
    echo "BRANCHE CHANGÉE: $CURRENT_BRANCH"
    echo "Pour adapter le volume de base de données à cette branche,"
    echo "exécutez manuellement la commande:"
    echo "  ./update-db-volume.sh --no-interaction (ou -n)"
    echo "----------------------------------------------------------"
    exit 0
fi

# Vérifier les options en ligne de commande
if [ "$1" = "--no-interaction" ] || [ "$1" = "-n" ]; then
    # Option pour accepter automatiquement la création du volume sans interaction
    response="o"
    echo "Mode non-interactif activé: changement de volume automatique."
else
    # Demander confirmation à l'utilisateur
    echo "Vous êtes sur la branche: $CURRENT_BRANCH"
    echo "Souhaitez-vous changer le volume de base de données pour: $VOLUME_NAME? (o/n)"
    read -r response
fi

if [[ "$response" =~ ^[oO]$ ]]; then
    # Sauvegarder une copie du fichier docker-compose.yml original
    # (seulement s'il n'existe pas déjà)
    if [ ! -f "${COMPOSE_FILE}.bak" ]; then
        cp "$COMPOSE_FILE" "${COMPOSE_FILE}.bak"
        echo "Sauvegarde du fichier docker-compose.yml original créée."
    fi

    # Mettre à jour le nom du volume dans docker-compose.yml
    # D'abord restaurer le nom original si nécessaire, puis le modifier
    sed -i "s/db-data-[^:]*:/db-data:/g" "$COMPOSE_FILE"
    sed -i "s/db-data:/${VOLUME_NAME}:/g" "$COMPOSE_FILE"

    echo "Volume de base de données modifié pour la branche: $CURRENT_BRANCH"
    echo "Nouveau nom de volume: $VOLUME_NAME"
    echo "Pour appliquer les changements, redémarrez vos conteneurs avec:"
    echo "docker-compose down && docker-compose up -d"
else
    echo "Opération annulée. Le volume de la base de données n'a pas été modifié."
fi