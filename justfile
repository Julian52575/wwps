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
    {{CONTAINER_TOOL}} compose up --build

down:
    {{CONTAINER_TOOL}} compose down

rm:
    just down || true
    {{CONTAINER_TOOL}} rm {{CONTAINER_NAME}} || {{CONTAINER_TOOL}} image rm {{IMAGE_NAME}}

nuke:
    @echo "⚠️  This will delete containers, images, and volumes!"
    read -p "Type 'yes' to continue: " confirm && \
    echo "$confirm" && \
    if [ "$confirm" != "yes" ]; then \
        echo "Aborted."; \
        exit 1; \
    fi
    just database-dump
    if [ "{{CONTAINER_TOOL}}" = "docker" ]; then \
        docker compose down --volumes --rmi all --remove-orphans; \
    else \
        podman compose down --volumes --remove-orphans; \
        podman image prune -a -f; \
    fi
    echo "☢️ Nuke successful' 

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
