#!/usr/bin/env bash
set -e

echo "🧹 Reset rapide de la base de données & Redis..."
docker exec upstra-demo-postgres psql -U upstra -d upstra_demo -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public; CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"
docker exec upstra-demo-redis redis-cli FLUSHALL
echo "🔄 Redémarrage du backend (migrations auto)..."
docker restart upstra-demo-backend
echo "✅ Prêt en ~3 secondes !"

