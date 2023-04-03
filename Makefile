make = @make --no-print-directory

.PHONY: help
help: ## Display this help screen
	@awk -F ': |##' '/^[^\t].+?:.*?##/ { printf "\033[36m%-22s\033[0m %s\n", $$1, $$NF }' $(MAKEFILE_LIST)

.PHONY: build
build: ## Build the docker image
	docker-compose build

.PHONY: clean
clean:
	rm -f tmp/pids/server.pid

.PHONY: up
up: clean ## Start the docker containers
	docker-compose up

.PHONY: upd
upd: clean
	docker-compose up -d

.PHONY: down
down:
	docker-compose down

.PHONY: downv
downv:
	docker-compose down -v

.PHONY: bundle
bundle: ## bundle install
	docker-compose run --rm app bundle

.PHONY: c
c:
	docker-compose run --rm app bin/rails c

.PHONY: db
db:
	psql -h 127.0.0.1 -p 5441 -U postgres app_development

.PHONY: logs
logs:
	docker-compose logs -f

.PHONY: sh
sh:
	docker-compose run --rm app sh

.PHONY: bash
bash:
	docker-compose run --rm app bash

.PHONY: dbsetup
dbsetup: ## setup database
	docker-compose run --rm app rails db:setup

.PHONY: dbreset
dbreset:
	docker-compose run --rm app rails db:drop
	docker-compose run --rm app rails db:create

.PHONY: dbinit
dbinit: dbreset migrate
	docker-compose run --rm app rails db:seed
	docker-compose run --rm app rails db:seed_fu

.PHONEY: dbseed
dbseed:
	docker-compose run --rm app rails db:seed
	docker-compose run --rm app rails db:seed_fu

.PHONY: migrate
migrate: ## migrate database
	docker-compose run --rm app rails db:migrate

.PHONY: init
init: downv build bundle dbinit

.PHONY: routes
routes: ## show routes
	docker-compose run --rm app rails routes
