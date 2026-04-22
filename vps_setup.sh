#!/bin/bash
# StoreLink — Hostinger VPS One-Shot Setup
# Run this in Hostinger hPanel → VPS → Terminal (browser terminal)
# Usage: bash vps_setup.sh

set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# ── 1. System update + Docker install ─────────────────────────
info "Updating system..."
apt-get update -qq && apt-get upgrade -y -qq

info "Installing Docker..."
curl -fsSL https://get.docker.com | sh
systemctl enable docker && systemctl start docker
apt-get install -y -qq git docker-compose-plugin

# ── 2. Clone repo ──────────────────────────────────────────────
info "Cloning StoreLink..."
mkdir -p /var/www && cd /var/www
rm -rf storelink
git clone https://github.com/SathikAi/Storelink_backend.git storelink
cd storelink

# ── 3. Generate secrets ────────────────────────────────────────
SECRET=$(openssl rand -hex 32)
PG_PASS=$(openssl rand -hex 16)
REDIS_PASS=$(openssl rand -hex 16)
ADMIN_KEY=$(openssl rand -hex 16)
SERVER_IP=$(curl -s ifconfig.me)

# ── 4. Write .env ──────────────────────────────────────────────
info "Writing .env..."
cat > .env <<EOF
DOMAIN=$SERVER_IP
API_BASE_URL=http://$SERVER_IP/v1
WEB_APP_URL=http://$SERVER_IP

POSTGRES_PASSWORD=$PG_PASS
REDIS_PASSWORD=$REDIS_PASS
SECRET_KEY=$SECRET
ADMIN_DASHBOARD_KEY=$ADMIN_KEY

CORS_ORIGINS=http://$SERVER_IP

DODO_WEBHOOK_SECRET=changeme
SENTRY_DSN=
OTP_MOCK=false
EOF

# ── 5. Create HTTP-only nginx config (no domain/SSL yet) ───────
info "Writing HTTP nginx config..."
cat > nginx/nginx.conf <<'NGINX'
limit_req_zone $binary_remote_addr zone=api:10m rate=30r/s;
limit_req_zone $binary_remote_addr zone=auth:10m rate=5r/m;

server {
    listen 80;
    server_name _;

    client_max_body_size 15M;

    location / {
        proxy_pass         http://frontend:80;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_intercept_errors on;
        error_page 404 = /index.html;
    }

    location /admin/ {
        proxy_pass         http://admin-portal:80/admin/;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
    }

    location /v1/ {
        proxy_pass         http://backend:8000;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade           $http_upgrade;
        proxy_set_header   Connection        'upgrade';
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_read_timeout 60s;
        limit_req zone=api burst=30 nodelay;
        limit_req_status 429;
    }

    location ~ ^/v1/auth/(otp|login) {
        proxy_pass         http://backend:8000;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        limit_req zone=auth burst=5 nodelay;
        limit_req_status 429;
    }

    location /admin-dashboard {
        proxy_pass         http://backend:8000;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
    }

    location /uploads/ {
        alias   /var/www/uploads/;
        expires 30d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    location /health {
        proxy_pass http://backend:8000;
        access_log off;
    }

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript
               application/json application/javascript application/xml+rss;
}
NGINX

# ── 6. Remove SSL-only services from compose for first boot ───
# (certbot not needed without domain)
info "Removing certbot from compose for HTTP-only deploy..."
python3 - <<'PYEOF'
import re
with open('docker-compose.yml', 'r') as f:
    content = f.read()

# Remove certbot service block
content = re.sub(
    r'\n  # ── Certbot.*?entrypoint:.*?\n',
    '\n',
    content,
    flags=re.DOTALL
)

# Remove certbot volume mounts from nginx
content = content.replace(
    '      - ./certbot/conf:/etc/letsencrypt:ro\n', ''
).replace(
    '      - ./certbot/www:/var/www/certbot:ro\n', ''
)

with open('docker-compose.yml', 'w') as f:
    f.write(content)

print("docker-compose.yml patched for HTTP-only")
PYEOF

# ── 7. Make directories ────────────────────────────────────────
mkdir -p backend/uploads backend/logs

# ── 8. Build and start ─────────────────────────────────────────
info "Building Docker images (this takes 5-10 mins)..."
docker compose build

info "Running DB migrations..."
docker compose run --rm backend alembic upgrade head

info "Starting all services..."
docker compose up -d

# ── 9. Health check ────────────────────────────────────────────
info "Waiting 30s for services to start..."
sleep 30

if curl -sf http://localhost/health > /dev/null 2>&1; then
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ StoreLink is LIVE!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  App:           http://$SERVER_IP"
    echo "  API:           http://$SERVER_IP/v1/docs"
    echo "  Admin Portal:  http://$SERVER_IP/admin/"
    echo "  Admin (HTML):  http://$SERVER_IP/admin-dashboard"
    echo ""
    echo "  Admin Key: $ADMIN_KEY"
    echo ""
    echo "  Save these values — you'll need them!"
    echo ""
else
    echo -e "${RED}Health check failed. Check logs:${NC}"
    docker compose logs backend --tail=30
fi
