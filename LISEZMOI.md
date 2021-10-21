# Ĝis

## Contexte

***L’édition collaborative et historisée de données géographiques***

Ĝis est un logiciel utilisé par le web (SaaS) pour pouvoir saisir et modifier à plusieurs des données géographiques ainsi que leurs attributs.

Le rendu, import/export, la gestion de *grosse donnée* ou encore l’annotation de fond de carte ne sont pas le cœur du projet.

On pourrait dire qu’il s’agit du « google spreadsheet de la donnée cartographique » : un outil ni très beau ni puissant, mais qui couvre l’essentiel des besoins.

Vous n’avez pas besoin de connaitre l’informatique ou la géomatique, mais juste d’un peu de débrouillardise. Vous pouvez voir cet outil comme un tableur dans lequel vous pouvez mettre des objets géographiques.

### Comment contribuer ?

L’utilisation, modification et diffusion de Ĝis sont restreintes.
Les conditions sont définies par la [licence publique generale GNU Affero v3](https://www.gnu.org/licenses/agpl-3.0.html).

Si vous souhaitez y apporter des changements ou des améliorations,
ouvrez une _issue_, une _merge request_ ou envoyez-nous un email à bonjour@codeursenliberté.fr (avec ou sans accent).

## Installation pour le développement

### Dépendances techniques

Ĝis est une application [Ruby on rails](https://rubyonrails.org/) monolitique assez classique.

Avant de travailler dessus, vous aurez besoin de :
- postgresql et postgis
- [rbenv](https://github.com/rbenv/rbenv-installer#rbenv-installer--doctor-scripts)
- [Yarn](https://yarnpkg.com/en/docs/install)

### Création des rôles de la base de données

Par défaut, l’application essaye de se connecter avec l’utilisateur `gxis`
et le mot de passe `gxis`.

Pour créer cet utilisateur, exécutez

    make create-pg-users

Alternativement, ces valeurs peuvent être modifiées dans le fichier `config/database.yml`.

### Initialisation de l'environnement de développement

À la premier installation, executez

    make setup

Cette commande installera la gem `bundler`, installera les dépendances et initialisera la base de données.

## Lancement de l'application

### Lancement du server

On lance le serveur d'application ainsi :

    make run

Cette commande exécutera automatiquement `make install` pour installer d’éventuelles mises à jour et effectuer les migrations.

L'application tourne alors à l'adresse `http://localhost:3000`.

### Exécution des tests

    make test

### Linting

    make lint

Nous suivons les conventions [StandardRB](https://github.com/testdouble/standard) de [StandardJS](https://standardjs.com/).
