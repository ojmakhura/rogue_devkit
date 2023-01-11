include ./Makefile.dev

gen_self_certs:
	chmod 755 .env && . ./.env && sudo rm ${ROGUE_ERP_DATA}/traefik/${DOMAIN}.crt && chmod 755 .env && . ./.env && sudo rm ${ROGUE_ERP_DATA}/traefik/${DOMAIN}.key && chmod 755 .env && . ./.env && sudo openssl req -x509 -sha256 -days 356 -nodes -newkey rsa:2048 -out ${ROGUE_ERP_DATA}/traefik/${DOMAIN}.crt -keyout ${ROGUE_ERP_DATA}/traefik/${DOMAIN}.key


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
swarm_label_true:
	chmod 755 .env && . ./.env && docker node update --label-add ${STACK_NAME}_${node_label}=true ${node}

swarm_init:
	docker swarm init

rogueerp_network:
	docker network create --driver overlay rogueerp-public

mount_prep: gen_env
	chmod 755 .env && . ./.env && mkdir -p ${ROGUE_ERP_DATA} && \
	chmod 755 .env && . ./.env && mkdir -p ${ROGUE_ERP_DATA}/db && \
	chmod 755 .env && . ./.env && mkdir -p ${ROGUE_ERP_DATA}/auth && \
	chmod 755 .env && . ./.env && cp deployment/traefik_passwd ${ROGUE_ERP_DATA}/auth/system_passwd && \
	chmod 755 .env && . ./.env && mkdir -p ${ROGUE_ERP_DATA}/keycloak && \
	chmod 755 .env && . ./.env && mkdir -p ${ROGUE_ERP_DATA}/certs && \
	chmod 755 .env && . ./.env && cp deployment/certs/* ${ROGUE_ERP_DATA}/certs && \
	chmod 755 .env && . ./.env && mkdir -p ${ROGUE_ERP_DATA}/registry && \
	chmod 755 .env && . ./.env && mkdir -p ${ROGUE_ERP_DATA}/traefik && \
	chmod 755 .env && . ./.env && cp deployment/traefik/config.yml ${ROGUE_ERP_DATA}/traefik

##
## Environment management
##
rm_env:
	rm -f .env

gen_env:
ifdef env
	if [ -f .env ]; then \
		rm -f .env; \
	fi
	@$(${env}_ENV)
	chmod 755 .env
else
	@echo 'no env defined. Please run again with `make env=<LOCAL_ENV, DEV_ENV, TEST_ENV, LIVE_ENV> target`'
	exit 1
endif