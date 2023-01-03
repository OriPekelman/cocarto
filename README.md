# cocarto

## Context

***Collaborative and historized edition of geographical data***

**cocarto** is a tool for managing geographical-related data that doesn’t require a geomatic engineer experience.  It is a web application that lets you create, edit data sets that include geographical data; multiple users can collaborate in realtime on the same data.

It’s just tabular data with an extra column for the geometry; a spreadsheet of geographical data.

It is *not*:
* a rendering tool to make nice printable maps
* a tool for managing very large datasets.

### How to contribute

This software is distributed under the AGPLv3.

If you want to report a bug, ask for an improvement or submit a fix, open an issue, a merge request or email us at bonjour@codeursenliberte.fr

## Installation for development

### Technical dependencies

**cocarto** is a [Ruby on rails](https://rubyonrails.org/) monolith application. We use [turbo](https://turbo.hotwired.dev/) for interactivity and [stimulus](https://stimulus.hotwired.dev/) for the small bits that need javascript.

In order to work on it, you will need:
- postgresql with postgis
- redis running locally
- [rbenv](https://github.com/rbenv/rbenv-installer#rbenv-installer--doctor-scripts)

### Create the database roles

By default, the app will try to connect to the database with the user `cocarto` and the password `cocarto`.

To create that user, run:

    make setup-pg-users

Those values can also be modified in `config/database.yml`.

### Initialize the development environment

On a new installation, run

    make setup-dev 
    make setup

That command will install the gem `bundler`, the dependencies and will initialize the database. The database will contain two users:

* `elisee.reclus@commune.paris`, password: `refleurir`
* `cassini@carto.gouv.fr`, password: `générations12345`

## Run the app

### Start the server

To run the server, run:

    make dev

That command will automatically run `make install` to install new dependencies and run database migrations. The app then runs at `https://localhost:3000`.

### Run the tests

    make test

### Linting

    make lint

We follow the conventions from [StandardRB](https://github.com/testdouble/standard) and [StandardJS](https://standardjs.com/).

## Importing Territories

Territories are reference geometries (like countries of the world) that are available to all users.
The territories are grouped into TerritoryCategories that have each a revision to handle evolution over time.

A `rake` task allows to import them, either from an url, either from a local file:

    rake import:geojson[regions.json,Régions de France,2022]

    rake import:geojson[http://etalab-datasets.geo.data.gouv.fr/contours-administratifs/2022/geojson/departements-100m.geojson,Départements de France,2022]

Expect a processing time of about 1s per Mb of geojson.

If you want to set the parent of a territories, you need to pass as an extra-parameter:
* the name of the parent category (`Régions de France`)
* the code of that parent in the dataset feature properties (`region`)


    rake import:geojson[http://etalab-datasets.geo.data.gouv.fr/contours-administratifs/2022/geojson/departements-100m.geojson,Départements de France,2022,Régions de France,region]

## Hosting

If you want to host the app by yourself, you will need to set the following environment variables:

* PUBLIC_URL: where is your instance running. This is used by the mailer (password recovery…)
* EMAIL_FROM: adress that is used as `From:` in the emails sent
* SMTP_HOST, SMTP_USERNAME, SMTP_PASSWORD, SMTP_PORT: being able to send emails
