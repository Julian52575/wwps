# WibWobPS (WWPS)

A private server for *Yo-kai Watch Puni Puni* / *Wibble Wobble*, written in
Python. It is a behavioural port of the C#
[puniemu](https://github.com/hxgohxrr/puniemu) server: same NHN request/response
cipher, same table formats, same game rules and endpoints, running on aiohttp and
asyncpg instead of ASP.NET Core and Npgsql.

This project is non-profit. In-app purchases are disabled. It is not affiliated
with NHN.

## Quick start

### Using Docker 

First, `cp .env.example .env`.  

This repository hosts a `docker-compose` to run the project with 3 commands:  
``` bash
just mkcert
export DOCKER_SOCKET=/var/run/docker.sock
docker compose up
```
or, using [Just](https://github.com/casey/just):  
``` bash
just mkcert
export DOCKER_SOCKET=/var/run/docker.sock
just up
```

This simple command starts both WWPS, postgres and traefik. 
- WWPS is served at `env.SERVER_HOST` using HTTPS certificates generated with `just mkcert`. 
- Postgres is served at `localhost:POSTGRES_PORT`

#### Nix shell

If you don't want to install docker on your machine, a nix shell is provided with podman, just and other tools configured. 

Install nix quickly with these commands:  
``` bash
curl -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```
then open a new terminal. 
You can enter the shell with:  
``` bash
nix-shell
```
And EVERYGHING you need for development will be available until you `exit` the shell.   

### Locally 

```bash
pip install -r requirements.txt
psql "$DATABASE_URL" -f Database/schema.sql
cp appsettings.example.json appsettings.json   # then edit it
python -m wwps
```

Serves on `0.0.0.0:8080`. A status dashboard is at `/dashboard`.

Run the tests with:

```bash
pip install -r requirements-dev.txt
pytest
```

You also need to populate `Resources/` with the game's master tables and the
server-side data files. They were embedded in the C# assembly and were never
committed, so they are not part of this repository. See
[docs/configuration.md](docs/configuration.md).

## Documentation

| Document | Contents |
| --- | --- |
| [architecture.md](docs/architecture.md) | Module map and the life of a request |
| [protocol.md](docs/protocol.md) | The NHN cipher, response envelopes, session tokens |
| [data-model.md](docs/data-model.md) | Database schema, account cache, the pipe/asterisk table format |
| [game-logic.md](docs/game-logic.md) | Stages, conditions, exp curves, befriend odds, missions, gacha |
| [endpoints.md](docs/endpoints.md) | Every route and what it does |
| [configuration.md](docs/configuration.md) | `appsettings.json`, `Resources/`, deployment |
| [porting-notes.md](docs/porting-notes.md) | Quirks kept from the C# server, and where the port differs |
| [operations.md](docs/operations.md) | Security checks, logging, metrics, the status dashboard, and tests |

## Layout

```
wwps/            server package
  app.py         routes, middlewares, startup
  nhn_crypt.py   request/response cipher
  user_data.py   PostgreSQL + write-back account cache
  managers.py    shared game logic
  security.py    account ownership and anti-cheat checks
  metrics.py     in-process metrics registry
  dashboard.py   status dashboard (HTML + JSON + Prometheus)
  logging_setup.py  colored structured logging
  handlers/      one module per endpoint family
tests/           pytest suite
Database/        schema.sql
Resources/       game data (you supply this)
dataDownload/    static files served to the client
Tools/           data-download helper scripts from the C# repo
docs/            documentation

.env.example     an example .env
docker_entrypoint.sh    the entrypoint for the wwps server's docker image
docker-compose.yml      compose for both wwps, postgres and traefik 
justfile                helper commands for easy development (try just help)
shell.nix               the nix shell to start a virtual environment with podman configured 
```

## Useful commands

If [Just](https://github.com/casey/just) is installed, you can use these command to GREATLY ease development :   

| command | purpose |
| ------- | ------- |
| `up` | start the docker compose |
| `down` | stop the docker compose |
| `rm` | stop the docker compose and delete the game server container and image |
| `nuke` | delete the containers, images and volumes |
| `exec CMD` | run the `$CMD` inside the game server container |
| `attach` | attach the terminal to the game server container |
| `log` | print the game server logs |
| `database-dump` | dump the whole database into a .sql file |
| `database-pipe DATABASE_FILE` | cat `$DATABASE_FILE` into the database |
| `mkcert` | generate the certificates and configuration to expose the game server at env.SERVER_HOST as https |

Example: 
``` bash
[nix-shell:Julian]$ just exec ls
podman exec -it ${BASENAME}_wwps_1 ls
Database  Resources  appsettings.json  dataDownload  requirements-dev.txt  requirements.txt  wwps
```

All of these are defined within `justfile`.  

## Credits

Original C# server: Zura, DarkCraft, wibwob_yt, with reverse engineering help
from onepiecefreak3 and kuronosuFear, logo by picky_x_keizen.
