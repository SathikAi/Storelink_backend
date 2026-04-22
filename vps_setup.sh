#!/bin/bash
# StoreLink — Hostinger VPS Setup
# Run: bash vps_setup.sh

set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

DOMAIN="storelink.sbs"
REPO="https://github.com/SathikAi/Storelink_backend.git"

# ── 1. Check Docker ────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
    info "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker && systemctl start docker
else
    info "Docker already installed: $(docker --version)"
fi

if ! docker compose version &>/dev/null; then
    apt-get install -y -qq docker-compose-plugin
fi

# ── 2. Install git if missing ──────────────────────────────────
apt-get install -y -qq git curl 2>/dev/null || true

# ── 3. Stop anything on port 80/443 ───────────────────────────
info "Checking for port conflicts..."
docker ps -q | xargs -r docker stop 2>/dev/null || true
# Stop system nginx/apache if running
systemctl stop nginx apache2 2>/dev/null || true

# ── 4. Clone repo ──────────────────────────────────────────────
info "Cloning StoreLink..."
mkdir -p /var/www && cd /var/www
rm -rf storelink
git clone "$REPO" storelink
cd storelink

# ── 5. Generate secrets ────────────────────────────────────────
SECRET=$(openssl rand -hex 32)
PG_PASS=$(openssl rand -hex 16)
REDIS_PASS=$(openssl rand -hex 16)
ADMIN_KEY=$(openssl rand -hex 16)

# ── 6. Write .env ──────────────────────────────────────────────
info "Writing .env with domain: $DOMAIN"
cat > .env <<EOF
DOMAIN=$DOMAIN
API_BASE_URL=https://$DOMAIN/v1
WEB_APP_URL=https://$DOMAIN

POSTGRES_PASSWORD=$PG_PASS
REDIS_PASSWORD=$REDIS_PASS
SECRET_KEY=$SECRET
ADMIN_DASHBOARD_KEY=$ADMIN_KEY

CORS_ORIGINS=https://$DOMAIN,https://www.$DOMAIN

DODO_WEBHOOK_SECRET=changeme
SENTRY_DSN=
OTP_MOCK=false
EOF

# ── 7. Patch nginx.conf: replace DOMAIN placeholder ───────────
info "Configuring nginx for $DOMAIN..."
sed -i "s/DOMAIN/$DOMAIN/g" nginx/nginx.conf

# ── 8. HTTP-only nginx for certbot challenge ───────────────────
# Temporarily use a simple HTTP config so certbot can validate
cat > /tmp/nginx_http_only.conf <<'NGINX'
server {
    listen 80;
    server_name _;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 200 'StoreLink coming soon...';
        add_header Content-Type text/plain;
    }
}
NGINX

# ── 9. Start nginx + certbot to get SSL cert ──────────────────
info "Starting nginx for SSL certificate..."
mkdir -p certbot/conf certbot/www backend/uploads backend/logs

# Mount temp HTTP config to get cert
docker run -d --name temp_nginx \
    -p 80:80 \
    -v /tmp/nginx_http_only.conf:/etc/nginx/conf.d/default.conf:ro \
    -v /var/www/storelink/certbot/www:/var/www/certbot:ro \
    nginx:1.25-alpine

sleep 3

info "Obtaining SSL certificate for $DOMAIN..."
docker run --rm \
    -v /var/www/storelink/certbot/conf:/etc/letsencrypt \
    -v /var/www/storelink/certbot/www:/var/www/certbot \
    certbot/certbot certonly \
    --webroot --webroot-path=/var/www/certbot \
    --email admin@$DOMAIN \
    --agree-tos --no-eff-email \
    -d $DOMAIN -d www.$DOMAIN \
    --non-interactive

docker stop temp_nginx && docker rm temp_nginx

info "SSL certificate obtained!"

# ── 10. Build images ───────────────────────────────────────────
info "Building Docker images (5-10 mins)..."
docker compose build

# ── 11. Run DB migrations ──────────────────────────────────────
info "Running database migrations..."
docker compose run --rm backend alembic upgrade head

# ── 12. Start all services ─────────────────────────────────────
info "Starting all services..."
docker compose up -d

# ── 13. Health check ───────────────────────────────────────────
info "Waiting 30s for services..."
sleep 30

if curl -sf https://$DOMAIN/health > /dev/null 2>&1; then
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅  StoreLink is LIVE!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  🌐 App:           https://$DOMAIN"
    echo "  📡 API Docs:      https://$DOMAIN/v1/docs"
    echo "  🔧 Admin Portal:  https://$DOMAIN/admin/"
    echo "  🖥  Admin HTML:    https://$DOMAIN/admin-dashboard"
    echo ""
    echo "  🔑 Admin Key:     $ADMIN_KEY"
    echo ""
    echo "  ⚠️  Save the Admin Key — it won't be shown again!"
    echo ""
else
    warn "Health check via HTTPS failed, trying HTTP..."
    if curl -sf http://$DOMAIN/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Live on HTTP (SSL may need a moment)${NC}"
    else
        echo -e "${RED}Services not responding. Check logs:${NC}"
        docker compose logs backend --tail=40
    fi
fi

docker compose ps
