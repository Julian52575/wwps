FROM traefik:v3.6.1 as traefik

RUN apk add --no-cache wget