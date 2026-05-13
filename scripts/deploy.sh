#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$INFRA_DIR")"

echo "=== ArcStack Deployment ==="
echo "Project root: $PROJECT_ROOT"

# Check .env exists
if [ ! -f "$INFRA_DIR/.env" ]; then
    echo "ERROR: $INFRA_DIR/.env not found. Copy .env.example and configure it."
    exit 1
fi

cd "$INFRA_DIR"

echo "Building images..."
docker compose build

echo "Starting services..."
docker compose up -d

echo "Waiting for database to be healthy..."
sleep 5

echo "Running database migrations..."
docker compose exec -T backend npx prisma migrate deploy

echo "=== Deployment complete ==="
echo ""
echo "Services:"
docker compose ps
echo ""
echo "Health check:"
curl -s http://localhost/api/v1/health || echo "(may need a moment to start)"
