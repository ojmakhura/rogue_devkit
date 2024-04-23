include ./Makefile.dev

gen_self_certs:
	chmod 755 .env && . ./.env && sudo rm ${RIMS_DATA}/traefik/${DOMAIN}.crt && chmod 755 .env && . ./.env && sudo rm ${RIMS_DATA}/traefik/${DOMAIN}.key && chmod 755 .env && . ./.env && sudo openssl req -x509 -sha256 -days 356 -nodes -newkey rsa:2048 -out ${RIMS_DATA}/traefik/${DOMAIN}.crt -keyout ${RIMS_DATA}/traefik/${DOMAIN}.key


##
## Start the docker containers
##
up_full_app: up_proxy up_db

up_db: gen_env
	chmod 755 .env && . ./.env && docker stack deploy -c docker-compose-db.yml ${STACK_NAME}-db

down_db: gen_env
	chmod 755 .env && . ./.env && docker stack rm ${STACK_NAME}-db

up_keycloak: build_keycloak_image gen_env
	chmod 755 .env && . ./.env && docker stack deploy -c docker-compose-keycloak.yml ${STACK_NAME}-keycloak

down_keycloak: gen_env
	chmod 755 .env && . ./.env && docker stack rm ${STACK_NAME}-keycloak

up_proxy: gen_env 
	chmod 755 .env && . ./.env && docker stack deploy -c docker-compose-traefik.yml ${STACK_NAME}-proxy

down_proxy: gen_env
	chmod 755 .env && . ./.env && docker stack rm ${STACK_NAME}-proxy

up_service: gen_env
	chmod 755 .env && . ./.env && docker stack deploy -c docker-compose-${service}.yml ${STACK_NAME}-${service}

##
## Build docker containers
##
build_image: gen_env
	. ./.env && docker compose -f docker-compose-${stack}.yml build

##
## System initialisation
##
swarm_label_true: gen_env
	chmod 755 .env && . ./.env && docker node update --label-add ${STACK_NAME}_${node_label}=true ${node}

swarm_init:
	docker swarm init

rims_network:
	docker network create --driver overlay rims-public

mount_prep: gen_env
	chmod 755 .env && . ./.env && mkdir -p ${RIMS_DATA} && \
	mkdir -p ${RIMS_DATA}/postgres && \
	mkdir -p ${RIMS_DATA}/auth && \
	cp deployment/traefik_passwd ${RIMS_DATA}/auth/system_passwd && \
	mkdir -p ${RIMS_DATA}/keycloak && \
	mkdir -p ${RIMS_DATA}/certs && \
	cp deployment/certs/* ${RIMS_DATA}/certs && \
	mkdir -p ${RIMS_DATA}/registry && \
	mkdir -p ${RIMS_DATA}/traefik && \
	deployment/traefik/config.yml ${RIMS_DATA}/traefik \
	mkdir -p ${RIMS_DATA}/prometheus && \
	mkdir -p ${RIMS_DATA}/grafana && \
	mkdir -p ${RIMS_DATA}/caddy && \
	mkdir -p ${RIMS_DATA}/portainer && \
	mkdir -p ${RIMS_DATA}/jenkins && \

##
## Environment management
##
rm_env:
	rm -f .env

gen_env:
	if [ -f .env ]; then \
		rm -f .env; \
	fi
	@$(ENV)
	chmod 755 .env