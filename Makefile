.PHONY: help ps build build-prod start fresh fresh-prod stop restart destroy \
	cache cache-clear migrate migrate migrate-fresh tests tests-html

CONTAINER_PHP=2pos # change this for every project

help: ## Print help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

ps: ## Show containers.
	@docker compose ps

init: ## init app
	cp .env.example .env
	make fresh

build: ## Build all containers for DEV
	@docker compose build --no-cache

start: ## Start all containers
	@docker compose up --force-recreate -d

fresh: stop destroy build start install  ## Destroy & recreate all using dev containers.

stop: ## Stop all containers
	@docker compose stop

restart: stop start ## Restart all containers

destroy: stop ## Destroy all containers

ssh: ## SSH into PHP container
	docker exec -it ${CONTAINER_PHP} sh

install: ## Run composer install
	docker exec ${CONTAINER_PHP} composer install

update: ## Run composer update
	docker exec ${CONTAINER_PHP} composer update

bump: ## Run composer bump packages update
	docker exec ${CONTAINER_PHP} composer bump

migrate: ## Run migration files
	docker exec ${CONTAINER_PHP} php artisan migrate

migrate-fresh: ## Clear database and run all migrations
	docker exec ${CONTAINER_PHP} php artisan migrate:fresh

seed: ## Run seed
	docker exec ${CONTAINER_PHP} php artisan db:seed

key-generate: ## Run key generate
	docker exec ${CONTAINER_PHP} php artisan key:generate

lint: ## Run pint
	docker exec ${CONTAINER_PHP} composer lint

refactor: ## Run rector
	docker exec ${CONTAINER_PHP} composer refactor

test-lint: ## Run pint test
	docker exec ${CONTAINER_PHP} composer test:lint

test-refactor: ## Run rector test
	docker exec ${CONTAINER_PHP} composer test:refactor

test-type-coverage: ## Run type coverage test
	docker exec ${CONTAINER_PHP} composer test:type-coverage

test-unit: ## Run pest unit test
	docker exec ${CONTAINER_PHP} composer test:unit

test-types: ## Run phpstan test
	docker exec ${CONTAINER_PHP} composer test:types

tests: ## Run all tests
	docker exec ${CONTAINER_PHP} composer test

tests-html: ## Run tests and generate coverage. Report found in reports/index.html
	docker exec ${CONTAINER_PHP} php -d zend_extension=xdebug.so -d xdebug.mode=coverage ./vendor/bin/phpunit --coverage-html reports

