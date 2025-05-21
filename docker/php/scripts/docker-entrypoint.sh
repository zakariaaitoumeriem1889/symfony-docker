#!/bin/sh
set -e

echo "Démarrage du conteneur PHP..."

# Vérifier si le projet Symfony existe déjà
if [ ! -f "/var/www/app/composer.json" ]; then
  echo "ATTENTION: Aucun projet Symfony détecté - le conteneur démarre sans optimisations"
  # Créer les répertoires nécessaires pour éviter les erreurs
  mkdir -p /var/www/app/var/cache
  mkdir -p /var/www/app/var/log
  mkdir -p /var/www/app/var/sessions

  # Définir les permissions correctes
  chown -R www-data:www-data /var/www/app/var
  find /var/www/app/var -type d -exec chmod 755 {} \;
  find /var/www/app/var -type f -exec chmod 644 {} \; 2>/dev/null || true
else
  # Script d'optimisation pour Symfony
  # Détecter l'environnement
  if [ -z "$APP_ENV" ]; then
    APP_ENV="dev"
  fi

  echo "Optimisation de l'application Symfony pour l'environnement: $APP_ENV"

  # S'assurer que nous sommes dans le bon répertoire
  cd /var/www/app

  # Vérifier si le répertoire var existe
  if [ ! -d "/var/www/app/var" ]; then
    mkdir -p /var/www/app/var/cache
    mkdir -p /var/www/app/var/log
    mkdir -p /var/www/app/var/sessions
  fi

  # Vérifier si phpunit-bridge est déjà installé
  if [ ! -d "/var/www/app/vendor/symfony/phpunit-bridge" ] && [ -f "/var/www/app/composer.json" ]; then
    echo "Installation du package symfony/phpunit-bridge manquant..."

    # Créer ou modifier le fichier .env.local pour éviter les erreurs pendant l'installation
    touch /var/www/app/.env.local

    # Installer le package sans interagir avec le cache Symfony
    composer require --dev symfony/phpunit-bridge --no-scripts --no-interaction

    # Marquer l'installation comme terminée pour éviter de la refaire
    touch /var/www/app/vendor/.phpunit-bridge-installed
  fi

  # Installer les dépendances de base sans exécuter de scripts
  if [ -f "/var/www/app/composer.json" ]; then
    echo "Vérification des dépendances..."

    # Utiliser --no-scripts pour éviter les problèmes avec le cache Symfony
    if [ "$APP_ENV" = "prod" ]; then
      composer install --optimize-autoloader --no-dev --no-scripts --no-interaction
    else
      composer install --optimize-autoloader --no-scripts --no-interaction
    fi
  fi

  # Définir les permissions correctes
  echo "Configuration des permissions..."
  chown -R www-data:www-data /var/www/app/var
  find /var/www/app/var -type d -exec chmod 755 {} \;
  find /var/www/app/var -type f -exec chmod 644 {} \;

  echo "Configuration terminée avec succès!"
fi

# Exécuter php-fpm en premier plan
exec php-fpm