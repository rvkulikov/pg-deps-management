a:
	echo $(ARGS)

.PHONY: psql
psql:
	docker-compose exec -u 70 rvkulikov.pg-deps-management.pgsql psql -d database

down:
	docker-compose down --remove-orphans

up:
	docker-compose up -d --force-recreate

init: volume
	chmod +x ./test
	docker-compose down --remove-orphans
	docker-compose up -d
	sleep 2

reset: build prune init

volume:
	docker volume create --name rvkulikov.pg-deps-management.pgsql.data || true

prune:
	docker-compose rm -fsv
	docker volume rm rvkulikov.pg-deps-management.pgsql.data || true

build:
	docker build -f "./docker/Dockerfile" -t rvkulikov.pg-deps-management.pgsql:latest .