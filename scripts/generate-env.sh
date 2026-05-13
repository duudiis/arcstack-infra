#!/bin/bash
set -euo pipefail

echo "=== Generating .env file ==="

JWT_SECRET=$(openssl rand -hex 32)
JWT_REFRESH_SECRET=$(openssl rand -hex 32)
DB_PASSWORD=$(openssl rand -hex 16)
REDIS_PASSWORD=$(openssl rand -hex 16)

cat > .env << EOF
DB_PASSWORD=${DB_PASSWORD}
REDIS_PASSWORD=${REDIS_PASSWORD}
JWT_SECRET=${JWT_SECRET}
JWT_REFRESH_SECRET=${JWT_REFRESH_SECRET}
OPENAI_API_KEY=sk-your-openai-api-key

# Set these for production:
# FRONTEND_HOST=arcstack.yourdomain.com
# API_HOST=api.arcstack.yourdomain.com
# FRONTEND_URL=https://arcstack.yourdomain.com
# API_URL=https://api.arcstack.yourdomain.com
# WS_URL=wss://api.arcstack.yourdomain.com
# COOKIE_DOMAIN=.yourdomain.com
# NODE_ENV=production
EOF

echo ".env file generated with random secrets."
echo "Don't forget to set OPENAI_API_KEY and production domain vars!"
