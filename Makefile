.DEFAULT_GOAL := help

setup: ## Initial setup of dependencies
	gem install bundler
	bundle install
	rails db:setup

create-pg-users: ## Creates the required postgresql users
	./setup_pg_users.sh

install: ## Install or update dependencies
	yarn install
	bundle install
    bundle exec rake db:migrate

run: install ## Start the app server
	bundle exec rails server

lint-ruby: ## Run the ruby linter standardrb
	bundle exec standardrb

lint-js: ## Run the js linter standardjs
	yarn run lint

lint: lint-ruby lint-js ## Run all the linters

test: ## Run tests
	bin/rails test

help: ## Display this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: setup create-pg-users install run lint-ruby lint-js lint test help
