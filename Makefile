include ./Makefile.dev

gen_self_certs:
	chmod 755 .env && . ./.env && sudo rm ${ROGUE_DATA}/traefik/${DOMAIN}.crt && chmod 755 .env && . ./.env && sudo rm ${ROGUE_DATA}/traefik/${DOMAIN}.key && chmod 755 .env && . ./.env && sudo openssl req -x509 -sha256 -days 356 -nodes -newkey rsa:2048 -out ${ROGUE_DATA}/traefik/${DOMAIN}.crt -keyout ${ROGUE_DATA}/traefik/${DOMAIN}.key


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

rogue_network:
	docker network create --driver overlay rogue-public

mount_prep: gen_env
	chmod 755 .env && . ./.env && mkdir -p ${ROGUE_DATA} && \
	echo "127.0.0.1	localhost" && \
	echo "$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}') ${DOMAIN} ${DB_DOMAIN} ${REGISTRY_DOMAIN} ${RABBITMQ_HOST} ${KEYCLOAK_DOMAIN} ${API_DOMAIN}" >> ${ROGUE_DATA}/hosts && \
	echo "$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}') portainer.${DOMAIN} grafana.${DOMAIN} swarmprom.${DOMAIN}" >> ${ROGUE_DATA}/hosts && \
	echo "$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}') unsee.${DOMAIN} alertmanager.${DOMAIN}" >> ${ROGUE_DATA}/hosts && \
	mkdir -p ${ROGUE_DATA}/db && \
	mkdir -p ${ROGUE_DATA}/auth && \
	cp deployment/traefik_passwd ${ROGUE_DATA}/auth/system_passwd && \
	mkdir -p ${ROGUE_DATA}/keycloak && \
	mkdir -p ${ROGUE_DATA}/certs && \
	cp deployment/certs/* ${ROGUE_DATA}/certs && \
	mkdir -p ${ROGUE_DATA}/registry && \
	mkdir -p ${ROGUE_DATA}/traefik && \
	deployment/traefik/config.yml ${ROGUE_DATA}/traefik \
	mkdir -p ${ROGUE_DATA}/openkm/repository && \
	cp deployment/openkm/* ${ROGUE_DATA}/openkm

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