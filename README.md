# 🧱 Upstra Stack

Monorepo de lancement pour le projet Upstra (Frontend + Backend + DB).

## 📦 Structure

- `infra-control_front/` → Vue 3 + Vite
- `infra-control/` → NestJS
- `infra-control_stack/` → Orchestration Docker

## 🚀 Lancer le stack

```bash
docker compose up --build
```

## 🛠️ Build un module

```bash
docker compose build frontend
```

## 🛠️ Build tous les modules

```bash
docker compose build
```

## 🛠️ Lancer un module

```bash
docker compose up frontend
```

## 🛠️ Lancer tous les modules

```bash
docker compose up
```

## 🛠️ Build un module puis le lancer

```bash
docker compose up --build frontend
```
