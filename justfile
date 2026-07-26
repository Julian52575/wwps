set export := true
set dotenv-load := true

BASENAME := `basename $(pwd)`
CONTAINER_TOOL := `command -v podman >/dev/null && echo podman || echo docker`
CONTAINER_NAME := "${BASENAME}_wwps_1"
IMAGE_NAME := "${BASENAME}_wwps"

help:
    just --list
    echo "Using {{CONTAINER_TOOL}}, container is {{CONTAINER_NAME}} and built from image {{IMAGE_NAME}}"

up:
    # set Docker_Socket if not set yet
    DOCKER_SOCKET=${DOCKER_SOCKET:-/var/run/docker.sock} {{CONTAINER_TOOL}} compose up --build

down:
    DOCKER_SOCKET=${DOCKER_SOCKET:-/var/run/docker.sock} {{CONTAINER_TOOL}} compose down

rm:
    just down || true
    DOCKER_SOCKET=${DOCKER_SOCKET:-/var/run/docker.sock} {{CONTAINER_TOOL}} rm {{CONTAINER_NAME}} || {{CONTAINER_TOOL}} image rm {{IMAGE_NAME}}

nuke:
    @echo "⚠️  This will delete containers, images, and volumes!"
    read -p "Type 'yes' to continue: " confirm && \
    echo "$confirm" && \
    if [ "$confirm" != "yes" ]; then \
        echo "Aborted."; \
        exit 1; \
    fi
    just database-dump || true
    if [ "{{CONTAINER_TOOL}}" = "docker" ]; then \
        DOCKER_SOCKET=${DOCKER_SOCKET:-/var/run/docker.sock} docker compose down --volumes --rmi all --remove-orphans; \
    else \
        DOCKER_SOCKET=${DOCKER_SOCKET:-/var/run/docker.sock} podman compose down --volumes --remove-orphans; \
        DOCKER_SOCKET=${DOCKER_SOCKET:-/var/run/docker.sock} podman image prune -a -f; \
    fi
    echo "☢️ Nuke successful"

exec CMD:
    {{CONTAINER_TOOL}} exec -it {{CONTAINER_NAME}} {{CMD}}

attach:
    {{CONTAINER_TOOL}} container attach {{CONTAINER_NAME}}

log:
    echo "Warning: using ctrl-c will stop the container. Kill the terminal instead."
    {{CONTAINER_TOOL}} container logs {{CONTAINER_NAME}}

DATABASE_DUMP_FILE := "wwps_db_backup_$(date +%Y%m%d_%H%M%S).sql"
database-dump:
    {{CONTAINER_TOOL}} exec "{{BASENAME}}_postgres_1" pg_dumpall -U ${POSTGRES_USER} > {{DATABASE_DUMP_FILE}}
    echo Dumped database into {{DATABASE_DUMP_FILE}}
database-pipe DATABASE_FILE:
    cat {{DATABASE_FILE}} | {{CONTAINER_TOOL}} compose exec -T postgres psql -U postgres -d puniemu

# Removes previous ceriticates and updates Traefik's dynamic.yml to match env.${SERVER_HOST}
mkcert:
    rm -rf *.pem certificates/*.pem || true
    mkcert ${SERVER_HOST}
    cp *.pem certificates/
    @printf '%s\n' \
      'tls:' \
      '  certificates:' \
      "    - certFile: /certificates/${SERVER_HOST}.pem" \
      "      keyFile: /certificates/${SERVER_HOST}-key.pem" \
      > certificates/dynamic.yml
    cat -e certificates/dynamic.yml