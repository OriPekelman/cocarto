.DEFAULT_GOAL := help

install: ## Install or update dependencies
	bin/setup

setup: install

setup-pg-users: ## Creates the required postgresql users
	bin/setup_pg_users

run: ## Start the app server
	bin/rails server

lint-ruby: ## Run the ruby linter standardrb
	bundle exec standardrb

#lint-js: ## Run the js linter standardjs
#	yarn run lint

lint: lint-ruby # lint-js ## Run all the linters

test: ## Run tests
	bin/rails db:prepare test

help: ## Display this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: install setup setup-pg-users run lint-ruby lint-js lint test help
