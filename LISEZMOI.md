# Ĝis

## Contexte

***L’édition collaborative et historisée de données géographiques***

L’objectif est de créer un logiciel utilisé par le web (SaaS) pour pouvoir saisir et modifier à plusieurs des données géographiques ainsi que leurs attributs.

Le rendu, import/export, la gestion de *grosse donnée* ou encore l’annotation de fond de carte ne sont pas le cœur du projet.

On pourrait dire qu’il s’agit du « google spreadsheet de la donnée cartographique » : un outil ni très beau ni puissant, mais qui couvre l’essentiel des besoins.

Les utilisateurs ne sont ni informaticiens, ni géomaticiens, mais des débrouillards. Après tout, ce ne sont que des données tabulaires avec une colonne de type géométrie.

### Comment contribuer ?

L’utilisation, modification et diffusion de Ĝis sont restreintes.
Les conditions sont définies par la [licence publique generale GNU Affero v3](https://www.gnu.org/licenses/agpl-3.0.html).

Si vous souhaitez y apporter des changements ou des améliorations, envoyez-nous un email à bonjour@codeursenliberté.fr (avec ou sans accent).

## Installation pour le développement

### Dépendances techniques

- postgresql et postgis
- [rbenv](https://github.com/rbenv/rbenv-installer#rbenv-installer--doctor-scripts)
- [Yarn](https://yarnpkg.com/en/docs/install)

### Création des rôles de la base de données

Les informations nécessaire à l'initialisation de la base doivent être pré-configurées à la main grâce à la procédure suivante :

Si vous êtes sous Linux :

    sudo su postgres -c  'psql -c "create user gxis with password \'gxis\' superuser"'

Si vous êtes sous macOS :

    psql -c "create user gxis with password 'gxis' superuser"

### Initialisation de l'environnement de développement

    gem install bundler
    bundle install
    rails db:setup

## Lancement de l'application

### Lancement du server

On lance le serveur d'application ainsi :

    bin/rails server

L'application tourne alors à l'adresse `http://localhost:3000`.

### Exécution des tests

    make test

### Linting

    make lint

Nous suivons les conventions [StandardRB](https://github.com/testdouble/standard) de [StandardJS](https://standardjs.com/).
