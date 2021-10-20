# Ĝis

## Context

***Collaborative and historized edition of geographical data***

Ĝis web application to input and modify geographical data, their attributes
by multiple users at the same time.

Nice rendering, import/export, managing *big data* or annotating the background map are not at the heart of the project.

One could say that is is the “google spreadsheet of geographical data”:
a tool this neither very fancy nor powerful, but that covers the essential needs.

You don’t need to be a computer scientist or a geomatic engineer, just
a bit resourceful. In the end, it is just tabular data with an extra column for the geometry.

### How to contribute

La licence du logiciel Ĝis reste à déterminer.

If you want to report a bug, ask for an improvement or submit a fix,
open an issue, a merge request or send us an email at
bonjour@codeursenliberte.fr

## Installation for development

### Technical dependencies

Ĝis is a [Ruby on rails](https://rubyonrails.org/) application. A well known monolith.

In order to work on it, you will need:
- postgresql with postgis
- [rbenv](https://github.com/rbenv/rbenv-installer#rbenv-installer--doctor-scripts)
- [Yarn](https://yarnpkg.com/en/docs/install)

### Create the database roles

By default, the app will try to connect to the database with the user`gxis`
and the password `gxis`.

To create that user, run:

    make create-pg-users

Those values can also be modified in `config/database.yml`.

### Initialize the development environment

On a new installation, run

    make setup

That command will install the gem `bundler`, the dependencies and will initialize the database.

## Run the app

### Start the serveur

To run the server, run:

    make run

That command will automatically run `make install` to install new dependencies and run database migrations.

The app then runs at `http://localhost:3000`.

### Run the tests

    make test

### Linting

    make lint

We follow the conventions from [StandardRB](https://github.com/testdouble/standard) and [StandardJS](https://standardjs.com/).
