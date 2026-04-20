# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Upstra Stack** — Docker Compose orchestration for the full Upstra platform. Two launch modes:

- **Production** (`docker-compose.yml`) — backend + frontend, DB/Redis natifs sur Raspberry Pi
- **Demo / Mock** (`../docker-compose.demo.yml`) — stack complète simulée : vcsim (VMware), 3 mock iLO, 1 mock UPS, PostgreSQL, Redis, backend, frontend

## Structure

```
infra-control_stack/
├── docker-compose.yml       # mode production / dev local
├── docker-compose.demo.yml  # mode démo (simulateurs)
├── .env                     # copié depuis .env-example
├── .env.demo                # copié depuis .env.demo.example
├── .env-example
└── .env.demo.example

../infra-control/            # NestJS backend (Dockerfile inside)
../infra-control_front/      # Vue 3 frontend (Dockerfile inside)
../mock_ilo/                 # Simulateur HP iLO (FastAPI HTTPS)
../mock_ups/                 # Simulateur UPS batterie (FastAPI HTTP)
```

---

## Mode démo (mock — sans hardware)

Tout tourne dans Docker, aucun vCenter / iLO / UPS physique requis.

```bash
# Depuis infra-control_stack/
cp .env.demo.example .env.demo
docker compose --env-file .env.demo -f docker-compose.demo.yml up --build
```

### Services démarrés

| Service | URL locale | Description |
|---|---|---|
| `frontend` | http://localhost:5173 | Interface Upstra |
| `backend` | http://localhost:3000 | API NestJS + Swagger `/docs` |
| `vcsim` | localhost:8989 | vCenter simulé (VMware govcsim) |
| `mock-ilo-1` | https://localhost:5001 | iLO simulé — esxi-host-01 |
| `mock-ilo-2` | https://localhost:5002 | iLO simulé — esxi-host-02 |
| `mock-ilo-3` | https://localhost:5003 | iLO simulé — esxi-host-03 |
| `mock-ups` | http://localhost:5010 | UPS simulé |
| `postgres` | localhost:5432 | Base de données |
| `redis` | localhost:6379 | Cache / état migration |

### Configuration dans l'UI après démarrage

| Ressource | IP / Host | Port | User | Pass |
|---|---|---|---|---|
| vCenter | `vcsim` | `8989` | `user` | `pass` |
| iLO serveur 1 | `mock-ilo-1` | — | `admin` | `admin` |
| iLO serveur 2 | `mock-ilo-2` | — | `admin` | `admin` |
| iLO serveur 3 | `mock-ilo-3` | — | `admin` | `admin` |
| UPS | `http://mock-ups:8000/battery` | — | — | — |

> Les hostnames sont résolus dans le réseau Docker `upstra-demo`. Le backend et les scripts Python utilisent ces noms directement.

### Déclencher le scénario de démo

```bash
# 1. Lancer la décharge UPS (rate = % perdu par poll, défaut 2)
curl -X POST "http://localhost:5010/simulate/discharge?rate=5"

# 2. Surveiller le niveau en temps réel
curl http://localhost:5010/battery

# 3. Quand level ≤ seuil Upstra (~20%) → migration automatique dans l'UI

# 4. Réinitialiser pour la prochaine démo
curl -X POST http://localhost:5010/simulate/restore
```

### Arrêter / nettoyer

```bash
docker compose -f docker-compose.demo.yml down          # arrêter
docker compose -f docker-compose.demo.yml down -v       # arrêter + supprimer volumes DB
```

---

## Mode production / dev local

```bash
# Depuis infra-control_stack/
cp .env-example .env
# éditer .env

# Stack sans DB locale (PostgreSQL et Redis tournent nativement)
docker compose up --build

# Stack avec DB locale (profil "local")
docker compose --profile local up --build
```

### Commandes individuelles

```bash
docker compose up --build          # build all + start
docker compose up                  # start without rebuilding
docker compose down                # stop and remove containers

docker compose build frontend      # build frontend only
docker compose build backend       # build backend only
docker compose up frontend         # start frontend only
docker compose up backend          # start backend only
docker compose up --build frontend # build + start frontend
```

### Services

| Service | Port | Notes |
|---|---|---|
| `backend` | `APP_PORT` (from `.env`) | NestJS API, no DB dependency in compose (DB is native on prod) |
| `frontend` | `5173:80` | Nginx-served Vue build, depends on backend |
| `db` | `5432` | PostgreSQL 15, **only active with `--profile local`** |

### Environment

Copy `.env-example` to `.env`. Both `backend` and `frontend` receive the same `.env` via `env_file`.

In production (Raspberry Pi), PostgreSQL and Redis run natively — not in Docker.

## Network

- Production : réseau bridge `upstra`
- Démo : réseau bridge `upstra-demo`
- Volume `db_data` / `demo_db_data` pour la persistance PostgreSQL
