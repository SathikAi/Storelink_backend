#!/bin/bash
# StoreLink — Production Deploy Script
# Usage: ./deploy.sh [--ssl] [--migrate]
# Run on your VPS / cloud server

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ── Check .env exists ─────────────────────────────────────────
if [ ! -f ".env" ]; then
  error ".env file not found! Copy .env.example → .env and fill in values."
fi

source .env

# ── Validate required vars ────────────────────────────────────
for VAR in DOMAIN POSTGRES_PASSWORD REDIS_PASSWORD SECRET_KEY ADMIN_DASHBOARD_KEY API_BASE_URL; do
  if [ -z "${!VAR}" ]; then
    error "Missing required env var: $VAR"
  fi
done

info "Deploying StoreLink to $DOMAIN"

# ── Create required directories ───────────────────────────────
mkdir -p backend/uploads backend/logs certbot/conf certbot/www nginx

# ── SSL setup (first time only) ──────────────────────────────
if [[ "$*" == *"--ssl"* ]]; then
  warn "Setting up SSL for $DOMAIN..."
  # Start nginx with HTTP only first
  docker compose up -d nginx
  sleep 5
  # Get certificate
  docker compose run --rm certbot certonly \
    --webroot --webroot-path=/var/www/certbot \
    --email admin@$DOMAIN \
    --agree-tos --no-eff-email \
    -d $DOMAIN -d www.$DOMAIN
  # Update nginx config with domain
  sed -i "s/DOMAIN/$DOMAIN/g" nginx/nginx.conf
  info "SSL certificate obtained!"
fi

# ── Pull latest code ──────────────────────────────────────────
if [ -d ".git" ]; then
  info "Pulling latest code..."
  git pull origin main
fi

# ── Build images ──────────────────────────────────────────────
info "Building Docker images..."
docker compose build --no-cache backend frontend

# ── Run database migrations ───────────────────────────────────
if [[ "$*" == *"--migrate"* ]]; then
  info "Running database migrations..."
  docker compose run --rm backend alembic upgrade head
fi

# ── Start / restart services ──────────────────────────────────
info "Starting services..."
docker compose up -d

# ── Wait and health check ─────────────────────────────────────
info "Waiting for services to be healthy..."
sleep 15

if curl -sf http://localhost/health > /dev/null 2>&1; then
  info "✅ StoreLink is live at https://$DOMAIN"
  info "📊 Admin dashboard: https://$DOMAIN/admin-dashboard"
else
  warn "Health check failed — check logs with: docker compose logs backend"
fi

# ── Show status ───────────────────────────────────────────────
docker compose ps
