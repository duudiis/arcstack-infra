#!/bin/bash
set -euo pipefail

echo "=== Database Init ==="

cd "$(dirname "$0")/.."

echo "Running Prisma migrate..."
docker compose exec -T backend npx prisma migrate deploy

echo "Running seed (if available)..."
docker compose exec -T backend npx tsx prisma/seed.ts 2>/dev/null || echo "No seed file or seed failed (non-critical)"

echo "=== Database ready ==="
