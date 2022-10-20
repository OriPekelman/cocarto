MAKEFLAGS += --jobs 8 --output-sync --keep-going
.DEFAULT_GOAL := help

install: ## Install or update dependencies
	bin/setup

setup: install

setup-dev: ## Install development dependencies
	bin/setup_dev

setup-pg-users: ## Creates the required postgresql users
	bin/setup_pg_users

dev: ## Start the app server for development purpose
	bin/dev

lint-rb: ## Run ruby linters
	bundle exec rubocop
	bundle exec erblint --lint-all
	bundle exec i18n-tasks health

lint-js: ## Run javascript linters
	npx standard
	npx prettier --check app/assets/stylesheets

lint-scss: ## Run sccs linters
	npx stylelint "**/*.scss"

lint-active-record: ## Run Active Record Doctor
	bundle exec rake active_record_doctor

lint: lint-rb lint-js lint-scss lint-active-record ## Run all linters

lint_autocorrect: ## Run linters in autocorrect mode
	bundle exec rubocop --autocorrect-all
	bundle exec erblint --lint-all --autocorrect
	bundle exec i18n-tasks normalize
	npx standard --fix
	npx prettier --write app/assets/stylesheets
	npx stylelint --fix "**/*.scss"

test: test-unit test-system ## Run all tests

test-unit: ## Run unit tests
	bin/rails test

test-system: ## Run system tests
	bin/rails test:system

help: ## Display this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: install setup setup-dev setup-pg-users dev lint lint-rb lint-js lint-scss lint-active-record lint_autocorrect test help
