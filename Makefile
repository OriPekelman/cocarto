.DEFAULT_GOAL := help

install: ## Install or update dependencies
	bin/setup

setup: install

setup-pg-users: ## Creates the required postgresql users
	bin/setup_pg_users

dev: install ## Start the app server for development purpose
	bin/dev

lint: ## Run all the linters
	bundle exec standardrb
	bundle exec erblint --lint-all

test: ## Run tests
	bin/rails db:prepare test
	bin/rails test:system

help: ## Display this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: install setup setup-pg-users dev lint test help
