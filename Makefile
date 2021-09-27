.DEFAULT_GOAL := help

install: ## Install or update dependencies
	bundle install
    bundle exec rake db:migrate

run: ## Start the app server
	bundle exec rails server

lint-ruby: ## Run the ruby linter standardrb
	bundle exec standardrb

#lint-js: ## Run the js linter standardjs
#	npm run lint

lint: lint-ruby lint-js ## Run all the linters

.PHONY: install run lint-ruby lint-js lint help

help: ## Display this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

test: ## Run tests
	bin/rails test