# Documentation de l'Environnement de Développement Symfony

## Vue d'ensemble

Cette documentation décrit l'environnement de développement Docker pour les projets Symfony. L'infrastructure est conçue pour offrir un environnement de développement local robuste, isolé et facilement configurable.

## Architecture du Projet

L'environnement est composé des services suivants :

- **PHP** : PHP 8.3 avec FPM sur Alpine Linux
- **Nginx** : Serveur web
- **PostgreSQL** : Base de données (version 15)
- **Adminer** : Interface d'administration de base de données
- **Mailpit** : Serveur de mail pour le développement

## Prérequis

- Docker et Docker Compose
- Git

## Installation et démarrage

1. Clonez le dépôt
2. Lancez l'environnement Docker :
   ```bash
   docker-compose -f docker/docker-compose.yml up -d
   ```
3. Accédez à l'application via http://localhost

## Structure des répertoires

```
project/
├── docker/
│   ├── nginx/
│   │   └── conf.d/
│   │       └── default.conf
│   ├── php/
│   │   ├── conf/
│   │   │   ├── opcache.ini
│   │   │   ├── php-fpm.ini
│   │   │   ├── php.ini
│   │   │   └── xdebug.ini
│   │   ├── scripts/
│   │   │   ├── docker-entrypoint.sh
│   │   │   └── symfony-optimize.sh
│   │   └── Dockerfile
│   └── docker-compose.yml
└── update-db-volume.sh
```

## Services et configurations

### PHP (8.3-fpm-alpine)

Le conteneur PHP est préconfigurée avec :
- Extensions PHP courantes (Opcache, Intl, PDO, PostgreSQL, etc.)
- Xdebug pour le débogage
- Composer et Symfony CLI
- Scripts d'optimisation automatique

**Configuration :**
- Mémoire : 512M
- Timezone : Africa/Casablanca
- Mode Opcache activé, JIT désactivé

### Nginx

Serveur web configuré pour Symfony avec :
- Optimisation des performances
- Mise en cache des ressources statiques
- Configuration des buffers FastCGI

### PostgreSQL

Base de données avec :
- Utilisateur par défaut : postgres
- Mot de passe par défaut : postgres
- Base de données : app
- Port : 5432

### Adminer

Interface web d'administration de la base de données :
- URL : http://localhost:8080
- Thème : hever
- Connexion automatique à PostgreSQL

### Mailpit

Serveur mail de test :
- SMTP : localhost:1025
- Interface web : http://localhost:8025

## Volumes

- **db-data** : Données persistantes de PostgreSQL
- **symfony_cache** : Cache Symfony
- **symfony_log** : Logs Symfony
- **nginx_logs** : Logs Nginx

## Gestion des branches et des bases de données

L'environnement inclut un script `update-db-volume.sh` qui permet de gérer différentes instances de bases de données en fonction des branches Git :

- Pour la branche `main` : Volume standard `db-data`
- Pour les autres branches : Volumes spécifiques `db-data-[branch-name]`

### Utilisation du script de gestion des volumes

```bash
# Mode interactif
./update-db-volume.sh

# Mode non-interactif (acceptation automatique)
./update-db-volume.sh -n
```

Après changement de volume, redémarrez les conteneurs :
```bash
docker-compose -f docker/docker-compose.yml down && docker-compose -f docker/docker-compose.yml up -d
```

## Débogage avec Xdebug

Xdebug est préconfiguré en mode "trigger" :
- Port : 9003
- IDE key : PHPSTORM
- Host : host.docker.internal

Pour activer le débogage, ajoutez le paramètre `XDEBUG_TRIGGER` à votre URL ou configurez une extension navigateur.

## Optimisation des performances

Le script `symfony-optimize.sh` peut être exécuté pour optimiser les performances :

```bash
docker exec php symfony-optimize
```

Ce script :
- Nettoie le cache
- Optimise l'autoloader Composer
- Réchauffe le cache Symfony
- Optimise les caches Doctrine

## Composer et dépendances

Gestion des dépendances via Composer depuis le conteneur PHP :

```bash
# Installer les dépendances
docker exec -it php composer install

# Mettre à jour les dépendances
docker exec -it php composer update

# Ajouter une dépendance
docker exec -it php composer require [package]

# Ajouter une dépendance de développement
docker exec -it php composer require --dev [package]

# Vérifier les problèmes de sécurité
docker exec -it php composer audit
```

## Accès aux services

- **Application** : http://localhost
- **Adminer** : http://localhost:8080
- **Mailpit** : http://localhost:8025
- **PostgreSQL** : localhost:5432

## Création d'un projet Symfony

Pour créer un nouveau projet Symfony depuis le conteneur PHP :

```bash
# Accès au conteneur PHP
docker exec -it php bash

# À l'intérieur du conteneur PHP, créer un nouveau projet
# Projet Symfony complet (recommandé)
symfony new --webapp . --no-git

# OU Projet Symfony minimal
symfony new . --no-git
```

### Structure initiale des permissions

Après création du projet, assurez-vous que les permissions sont correctes :

```bash
docker exec -it php bash -c "chmod -R 777 var"
```

## Cloner un projet Symfony existant

Pour cloner un projet Symfony existant à l'intérieur de votre environnement Docker :

```bash
# 1. Depuis votre machine hôte, assurez-vous que les conteneurs sont arrêtés
docker-compose -f docker/docker-compose.yml down

# 2. Videz le dossier racine (ou supprimez uniquement les fichiers du projet)
# ATTENTION: Sauvegardez d'abord tout travail important!

# 3. Clonez le projet dans le dossier racine
git clone https://url-du-depot.git .

# 4. Redémarrez les conteneurs
docker-compose -f docker/docker-compose.yml up -d

# 5. Accédez au conteneur PHP
docker exec -it php bash

# 6. À l'intérieur du conteneur, installez les dépendances
docker exec -it php composer install

# 7. Créez ou mettez à jour le fichier .env.local avec les bonnes coordonnées de connexion
docker exec -it php echo "DATABASE_URL=postgresql://postgres:postgres@database:5432/app?serverVersion=15&charset=utf8" > .env.local

# 8. Créez la base de données si elle n'existe pas
docker exec -it php symfony console doctrine:database:create --if-not-exists

# 9. Exécutez les migrations
docker exec -it php symfony console doctrine:migrations:migrate --no-interaction

# 10. Chargez les fixtures si nécessaire
docker exec -it php symfony console doctrine:fixtures:load --no-interaction
```

### Résolution des problèmes courants après clonage

```bash
# Nettoyer le cache
docker exec -it php symfony console cache:clear

# Vérifier les permissions
docker exec -it php chmod -R 777 var/

# Installer les assets
docker exec -it php symfony console assets:install

# Vérifier la configuration
docker exec -it php symfony console debug:config

# Vérifier les variables d'environnement
docker exec -it php symfony console debug:dotenv
```

## Commandes Symfony courantes

### Console Symfony
```bash
# Exécuter une commande Symfony
docker exec -it php symfony console [commande]

# Exemples :
docker exec -it php symfony console cache:clear
docker exec -it php symfony console debug:router
docker exec -it php symfony console debug:container
```

### Manipulation des entités et de la base de données
```bash
# Créer une entité
docker exec -it php symfony console make:entity

# Créer une migration
docker exec -it php symfony console make:migration

# Exécuter les migrations
docker exec -it php symfony console doctrine:migrations:migrate

# Charger les fixtures (données de test)
docker exec -it php symfony console doctrine:fixtures:load
```

### Création de composants
```bash
# Créer un contrôleur
docker exec -it php symfony console make:controller

# Créer un formulaire
docker exec -it php symfony console make:form

# Créer un CRUD complet
docker exec -it php symfony console make:crud

# Créer un utilisateur
docker exec -it php symfony console make:user

# Créer un système d'authentification
docker exec -it php symfony console make:auth
```

## Commandes Database (PostgreSQL)

### Accès à la base de données
```bash
# Accès au shell PostgreSQL
docker exec -it database psql -U postgres -d app

# Exporter la base de données
docker exec -it database pg_dump -U postgres app > backup.sql

# Importer une base de données
cat backup.sql | docker exec -i database psql -U postgres -d app
```

### Commandes PostgreSQL utiles
```bash
# Liste des bases de données
docker exec -it database psql -U postgres -c "\l"

# Liste des tables
docker exec -it database psql -U postgres -d app -c "\dt"

# Décrire une table
docker exec -it database psql -U postgres -d app -c "\d nom_table"

# Vider une table
docker exec -it database psql -U postgres -d app -c "TRUNCATE nom_table CASCADE;"

# Exécuter un script SQL
docker exec -it database psql -U postgres -d app -f /chemin/script.sql
```

## Informations supplémentaires

- Le conteneur PHP s'exécute avec l'utilisateur www-data (1000:1000)
- Les permissions des répertoires var/cache et var/log sont automatiquement gérées
- L'environnement détecte automatiquement les nouveaux projets Symfony et configure les optimisations nécessaires