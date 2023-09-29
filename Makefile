MAKEFLAGS += --jobs 8 --output-sync --keep-going
.DEFAULT_GOAL := help

install: ## Install or update dependencies
	bin/setup_system
	bin/setup

setup: install

setup-pg-users: ## Creates the required postgresql users
	bin/setup_pg_users

dev: ## Start the app server for development purpose
	bin/dev

lint-rubocop: ## rubocop
	bundle exec rubocop

lint-erb: ## erblint
	bundle exec erblint --lint-all

lint-i18n: ## i18n-tasks health
	bundle exec i18n-tasks health

lint-standardjs: ## standardjs
	npx standard

lint-prettier: ## prettier
	npx prettier --check app/assets/stylesheets

lint-scss: ## stylelint
	npx stylelint "**/*.scss"

LINT-BUNDLER = lint-rubocop lint-erb lint-i18n
LINT-NODE = lint-standardjs lint-prettier lint-scss

lint-active-record: ## active_record_doctor
	bundle exec rake active_record_doctor

lint-bundler: $(LINT-BUNDLER) ## Run bundler-based linters (for ci)

lint-node: $(LINT-NODE) ## Run node-based linters (for ci)

lint: lint-bundler lint-node lint-active-record ## Run all linters

autocorrect-rubocop: ## rubocop autocorrect
	bundle exec rubocop --autocorrect-all

autocorrect-erb: ## erblint autocorrect
	bundle exec erblint --lint-all --autocorrect

autocorrect-i18n: ## i18n-tasks autocorrect
	bundle exec i18n-tasks normalize

autocorrect-standardjs: ## standardjs autocorrect
	npx standard --fix

autocorrect-prettier: ## prettier autocorrect
	npx prettier --write app/assets/stylesheets

autocorrect-stylelint: ## stylelint autocorrect
	npx stylelint --fix "**/*.scss"

AUTOCORRECT = autocorrect-rubocop autocorrect-erb autocorrect-i18n autocorrect-standardjs autocorrect-prettier autocorrect-stylelint

autocorrect: $(AUTOCORRECT) ## Run linters in autocorrect mode

TEST = test-unit test-system

test: $(TEST) ## Run all tests

test-unit: ## Run unit tests
	bin/rails test

test-system: ## Run system tests
	bin/rails test:system

import-france-territories: ## Import Régions, Départements and Communes
	bin/import_france_territories

help: ## Display this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: install setup setup-pg-users dev lint lint-bundler lint-node $(LINT-BUNDLER) $(LINT-NODE) lint-active-record autocorrect $(AUTOCORRECT) test $(TEST) help
