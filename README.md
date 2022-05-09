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

This software is distributed under the AGPLv3.

If you want to report a bug, ask for an improvement or submit a fix,
open an issue, a merge request or send us an email at
bonjour@codeursenliberte.fr

## Installation for development

### Technical dependencies

Ĝis is a [Ruby on rails](https://rubyonrails.org/) application. A well known monolith.

We use [turbo](https://turbo.hotwired.dev/) for interactivity and [stimulus](https://stimulus.hotwired.dev/) for the small bits that need javascript.

In order to work on it, you will need:
- postgresql with postgis
- [rbenv](https://github.com/rbenv/rbenv-installer#rbenv-installer--doctor-scripts)

### Create the database roles

By default, the app will try to connect to the database with the user `gxis`
and the password `gxis`.

To create that user, run:

    make setup-pg-users

Those values can also be modified in `config/database.yml`.

### Initialize the development environment

On a new installation, run

    make setup

That command will install the gem `bundler`, the dependencies and will initialize the database.

## Run the app

### Start the server

To run the server, run:

    make dev

That command will automatically run `make install` to install new dependencies and run database migrations.

The app then runs at `http://localhost:5000`.

### Run the tests

    make test

### Linting

    make lint

We follow the conventions from [StandardRB](https://github.com/testdouble/standard) and [StandardJS](https://standardjs.com/).

## Importing Territories

Territories are reference geometries (like countries of the world) that are available to all users.

The territories are grouped into TerritoryCategories that have each a revision to handle evolution over time.

A `rake` task allows to import them, either from an url, either from a local file:

`rake import:geojson[regions.json,Régions de France,2022]`

`rake import:geojson[http://etalab-datasets.geo.data.gouv.fr/contours-administratifs/2022/geojson/departements-100m.geojson,Départements de France,2022]`


Expect a processing time of about 1s per Mb of geojson.

If you want to set the parent of a territories, you need to pass as an extra-parameter:
* the name of the parent category (`Régions de France`)
* the code of that parent in the dataset feature properties (`region`)

`rake import:geojson[http://etalab-datasets.geo.data.gouv.fr/contours-administratifs/2022/geojson/departements-100m.geojson,Départements de France,2022,Régions de France,region]`
