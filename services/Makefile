.PHONY: help gen-compose gen-full-stack gen-validate logs portainer-up portainer-down stack-down stack-up teardown
.SILENT: help

include .env

RELEASE_DIR=..

# Reverse Proxy should be base. Everything other service
# should be set behind Traefik
COMPOSE_FILES:=-f docker-compose.traefik.yml

define OPTIONS
  - chronograf grafana influxdb mosquitto -
  - node-red portainer telegraf -
  - traefik -
endef
export OPTIONS

ARGS:=$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(ARGS):;@:)

ifeq (chronograf, $(filter chronograf,$(ARGS)))
	COMPOSE_FILES:=$(COMPOSE_FILES) -f docker-compose.chronograf.yml
endif

ifeq (grafana, $(filter grafana,$(ARGS)))
	COMPOSE_FILES:=$(COMPOSE_FILES) -f docker-compose.grafana.yml
endif

ifeq (influxdb, $(filter influxdb,$(ARGS)))
	COMPOSE_FILES:=$(COMPOSE_FILES) -f docker-compose.influxdb.yml
endif

ifeq (mosquitto, $(filter mosquitto,$(ARGS)))
	COMPOSE_FILES:=$(COMPOSE_FILES) -f docker-compose.mosquitto.yml
endif

ifeq (node-red, $(filter node-red,$(ARGS)))
	COMPOSE_FILES:=$(COMPOSE_FILES) -f docker-compose.node-red.yml
endif

ifeq (telegraf, $(filter telegraf,$(ARGS)))
	COMPOSE_FILES:=$(COMPOSE_FILES) -f docker-compose.telegraf.yml
endif


SERVICES:=$(filter-out ${OPTIONS},$(ARGS))

.PHONY: $(OPTIONS)

help:
	echo "See README.md"

gen-compose:
	docker compose $(COMPOSE_FILES) config > $(RELEASE_DIR)/docker-compose.yml

gen-full-stack:
	make gen-compose chronograf grafana influxdb mosquitto \
				node-red portainer telegraf \
				traefik

gen-validate:
	docker compose --project-directory=$(RELEASE_DIR) config --services

logs:
	docker compose logs -f $(ARGS)

portainer-down:
	docker compose -f docker-compose.portainer.yml down

portainer-up:
	docker compose -f docker-compose.portainer.yml up -d

stack-down:
	docker compose --project-directory=$(RELEASE_DIR) down

stack-up:
	docker compose up -d $(SERVICES)

teardown:stack-down
	docker compose --project-directory=$(RELEASE_DIR) down --volumes
	docker compose -f docker-compose.portainer.yml down --volumes
	rm -f $(RELEASE_DIR)/docker-compose.yml
