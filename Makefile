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

.PHONY: api
api: clean ## Start the docker containers without hasura
	docker-compose up app mailcatcher nginx

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

.PHONY: schemadoc
schemadoc:
	docker run -v $(PWD)/docs/schema:/output --net="host" schemaspy/schemaspy:6.1.0 -t pgsql -host localhost:5441 -db app_development -u postgres -p password -connprops useSSL\\\\=false -all

.PHONY: routes
routes: ## show routes
	docker-compose run --rm app rails routes

.PHONY: rails
rails: ## execute rails command (e.g. make rails CMD="routes")
	docker-compose run --rm app rails $(CMD)

.PHONY: migratereset
migratereset: ## execute rails db:migrate:reset
	make rails CMD="db:migrate:reset"

.PHONEY: rspec
rspec: ## execute rspec command (e.g. make rspec TARGET="spec/models/mgt_user_spec.rb")
	docker-compose run --rm app rspec $(TARGET) --format documentation

.PHONY: rollback
rollback: ## rollback database
	$(make) rails CMD="db:rollback"

.PHONY: console
console: ## rails console
	$(make) rails CMD="console"

.PHONY: generate/migration
generate/migration: ## generate migration (e.g. make generate/migration name="create_users name:string")
	$(make) rails CMD="generate migration $(name)"

.PHONY: generate/model
generate/model: ## generate model (e.g. make generate/model name="user name:string")
	$(make) rails CMD="generate model $(name)"

.PHONY: generate/controller
generate/controller: ## generate controller (e.g. make generate/controller name="users")
	$(make) rails CMD="generate controller $(name)"
