# Upstra Stack

Orchestration Docker pour le projet Upstra. Deux modes de lancement :

| Mode | Fichier | Usage |
|---|---|---|
| **Démo / Mock** | `../docker-compose.demo.yml` | Stack complète simulée, zéro hardware |
| **Production** | `docker-compose.yml` | Backend + frontend, DB/Redis natifs |

---

## Mode démo (recommandé pour découvrir le projet)

Lance toute la stack avec des simulateurs : vcsim (VMware vCenter), 3 mock iLO (HP), 1 mock UPS.

```bash
# Depuis infra-control_stack/
cp .env.demo.example .env.demo
docker compose --env-file .env.demo -f docker-compose.demo.yml up --build
```

### Services disponibles

| Service | URL | Description |
|---|---|---|
| Frontend | http://localhost:5173 | Interface Upstra |
| Backend API | http://localhost:3000 | NestJS — Swagger sur `/docs` |
| vCenter simulé | localhost:8989 | VMware govcsim (1 DC, 1 cluster, 3 hosts, 10 VMs) |
| iLO simulé 1 | https://localhost:5001 | esxi-host-01 |
| iLO simulé 2 | https://localhost:5002 | esxi-host-02 |
| iLO simulé 3 | https://localhost:5003 | esxi-host-03 |
| UPS simulé | http://localhost:5010 | Endpoint batterie contrôlable |

### Configurer dans l'UI après démarrage

| Ressource | Champ IP / URL | User | Pass |
|---|---|---|---|
| vCenter | `vcsim` (port `8989`) | `user` | `pass` |
| iLO 1 | `mock-ilo-1` | `admin` | `admin` |
| iLO 2 | `mock-ilo-2` | `admin` | `admin` |
| iLO 3 | `mock-ilo-3` | `admin` | `admin` |
| UPS | `http://mock-ups:8000/battery` | — | — |

> Les hostnames sont ceux des containers dans le réseau Docker interne `upstra-demo`.

### Déclencher le scénario de démo

```bash
# Lancer la décharge UPS (rate = % perdu par appel poll, 1-20)
curl -X POST "http://localhost:5010/simulate/discharge?rate=5"

# Surveiller le niveau
curl http://localhost:5010/battery

# → quand level ≤ seuil Upstra (~20%) : migration automatique visible dans l'UI

# Réinitialiser pour la prochaine démo
curl -X POST http://localhost:5010/simulate/restore
```

### Arrêter

```bash
# Depuis infra-control_stack/
docker compose -f docker-compose.demo.yml down        # arrêter
docker compose -f docker-compose.demo.yml down -v     # arrêter + supprimer les données DB
```

---

## Mode production / dev local

```bash
# Depuis infra-control_stack/
cp .env-example .env
# éditer .env selon l'environnement

# Sans DB locale (PostgreSQL et Redis tournent nativement sur le serveur)
docker compose up --build

# Avec DB locale (profil "local")
docker compose --profile local up --build
```

### Commandes utiles

```bash
docker compose up --build              # build tout + démarrer
docker compose up                      # démarrer sans rebuild
docker compose down                    # arrêter

docker compose build frontend          # build frontend uniquement
docker compose build backend           # build backend uniquement
docker compose up --build frontend     # build + démarrer frontend
docker compose up frontend             # démarrer frontend uniquement
```

### Services

| Service | Port | Notes |
|---|---|---|
| `backend` | `APP_PORT` (`.env`) | NestJS API |
| `frontend` | `5173:80` | Vue 3 servi par Nginx |
| `db` | `5432` | PostgreSQL 15 — uniquement avec `--profile local` |

---

## Structure des dépôts

```
infra-control_stack/         # Ce dossier — orchestration
├── docker-compose.yml       # mode prod / dev local
├── docker-compose.demo.yml  # mode démo (simulateurs)
├── .env-example
└── .env.demo.example

../infra-control/            # NestJS backend
../infra-control_front/      # Vue 3 frontend
../mock_ilo/                 # Simulateur HP iLO (FastAPI HTTPS)
../mock_ups/                 # Simulateur UPS batterie (FastAPI HTTP)
../ups_manager/              # Scripts Python VMware + iLO
```
