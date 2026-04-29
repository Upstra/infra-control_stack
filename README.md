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

| Service | URL locale | Port | Description |
|---|---|---|---|
| Frontend | http://localhost:5173 | `5173` | Interface Upstra |
| Backend API | http://localhost:3000 | `3000` | NestJS — Swagger sur `/docs` |
| vCenter simulé | localhost:8989 | `8989` | VMware govcsim (1 DC, 1 cluster, 3 hosts, 10 VMs) |
| iLO simulé 1 | https://localhost:5001 | `5001` | esxi-host-01 |
| iLO simulé 2 | https://localhost:5002 | `5002` | esxi-host-02 |
| iLO simulé 3 | https://localhost:5003 | `5003` | esxi-host-03 |
| UPS simulé | http://localhost:5010 | `5010` | Endpoint batterie contrôlable |
| PostgreSQL | localhost:5432 | `5432` | Base de données |
| Redis | localhost:6379 | `6379` | Cache / état migration |

### Configuration UI — workflow complet après démarrage

> Tous les hostnames ci-dessous sont résolus dans le réseau Docker interne `upstra-demo`.

#### Option A — Import automatique (recommandé)

1. Ouvrir http://localhost:5173
2. Dans le wizard de setup → **"Choisissez votre stratégie de configuration"**
3. Choisir **"Importer"**
4. Uploader le fichier [`demo-seed.json`](demo-seed.json) fourni dans ce dossier

Le fichier contient la salle, l'UPS et les 4 serveurs (1 vCenter + 3 ESXi avec iLO) pré-configurés pour la stack démo.

#### Option B — Saisie manuelle (étapes détaillées ci-dessous)

---

#### 1. Salle serveur

| Champ | Valeur |
|---|---|
| Nom | `Salle Demo` |

---

#### 2. Onduleur (UPS)

| Champ | Valeur |
|---|---|
| Nom | `Onduleur Demo` |
| IP | `http://mock-ups:8000/battery` |
| Grace period ON | `30` s |
| Grace period OFF | `10` s |
| Salle | `Salle Demo` |

---

#### 3. Serveur vCenter

| Champ | Valeur |
|---|---|
| Nom | `vCenter Demo` |
| Type | `vcenter` |
| IP | `vcsim` |
| URL admin | `http://vcsim:8989` |
| Login | `user` |
| Mot de passe | `pass` |
| État | `UP` |
| Salle | `Salle Demo` |

> Pas de priorité ni d'UPS pour un serveur de type `vcenter`.

---

#### 4. Serveurs ESXi (à répéter 3 fois)

| Champ | esxi-host-01 | esxi-host-02 | esxi-host-03 |
|---|---|---|---|
| Nom | `esxi-host-01` | `esxi-host-02` | `esxi-host-03` |
| Type | `esxi` | `esxi` | `esxi` |
| IP | `mock-ilo-1` | `mock-ilo-2` | `mock-ilo-3` |
| URL admin | `https://mock-ilo-1` | `https://mock-ilo-2` | `https://mock-ilo-3` |
| Login | `admin` | `admin` | `admin` |
| Mot de passe | `admin` | `admin` | `admin` |
| État | `UP` | `UP` | `UP` |
| Priorité | `1` | `2` | `3` |
| Salle | `Salle Demo` | `Salle Demo` | `Salle Demo` |
| UPS | `Onduleur Demo` | `Onduleur Demo` | `Onduleur Demo` |

**iLO (à renseigner dans chaque serveur ESXi)**

| Champ | esxi-host-01 | esxi-host-02 | esxi-host-03 |
|---|---|---|---|
| Nom | `iLO-01` | `iLO-02` | `iLO-03` |
| IP | `mock-ilo-1` | `mock-ilo-2` | `mock-ilo-3` |
| Login | `admin` | `admin` | `admin` |
| Mot de passe | `admin` | `admin` | `admin` |

---

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
| `redis` | `6379` | Redis — tourne nativement sur le serveur en prod |

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
