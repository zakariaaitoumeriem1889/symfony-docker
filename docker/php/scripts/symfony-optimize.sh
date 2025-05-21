#!/bin/sh
set -e

# Pour exécuter si nécessaire afin d'optimiser les performances du projet
# Container a besoin d'être en cours d'exécution

# Nettoyage du cache
rm -rf /var/www/app/var/cache/*

# Ajouter optimisation Symfony
composer install --optimize-autoloader --no-scripts

# Réchauffer le cache Symfony
symfony console cache:warmup --env=dev

# Optimisations Doctrine
symfony console doctrine:cache:clear-metadata --env=dev
symfony console doctrine:cache:clear-query --env=dev
symfony console doctrine:cache:clear-result --env=dev

# Optimisations assets si webpack encore est utilisé
if [ -f /var/www/app/node_modules/.bin/encore ]; then
    yarn install
    yarn build
fi

# Créer le répertoire de sessions
mkdir -p /var/www/app/var/sessions
chmod -R 777 /var/www/app/var/sessions

echo "Optimisations terminées"