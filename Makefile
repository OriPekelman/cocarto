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

lint: lint-rb lint-js ## Run all linters

lint_autocorrect: ## Run linters in autocorrect mode
	bundle exec rubocop --auto-correct-all
	bundle exec erblint --lint-all --autocorrect
	npx standard --fix

test: ## Run tests
	bin/rails test
	bin/rails test:system

help: ## Display this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: install setup setup-dev setup-pg-users dev lint lint-rb lint-js lint_autocorrect test help
