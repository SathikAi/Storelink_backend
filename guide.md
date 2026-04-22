# 🚀 StoreLink Production Deployment Guide

This guide covers the professional, zero-downtime deployment strategy for **StoreLink** (FastAPI + Flutter + React Admin) using Docker, Nginx, and SSL.

---

## 1. Production Architecture
- **Backend**: FastAPI (Gunicorn/Uvicorn workers) inside Docker.
- **Storefront**: Flutter Web (Nginx static serving) inside Docker.
- **Admin Portal**: React/Vite (Nginx static serving).
- **Database**: PostgreSQL (Managed Supabase or self-hosted Docker).
- **Cache**: Redis (Rate limiting & Session storage).
- **Proxy**: Nginx with Let's Encrypt (Certbot).

---

## 2. Infrastructure Setup (Ubuntu 22.04+)

### Update System & Install Docker
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install docker.io docker-compose-plugin certbot python3-certbot-nginx -y
```

### Clone Project
```bash
git clone https://github.com/your-repo/Storelink.git /opt/storelink
cd /opt/storelink
```

---

## 3. Environment Configuration (`.env`)

Create a root `.env` file. This controls the entire multi-container stack.

```env
# Database (Supabase Recommended)
POSTGRES_PASSWORD=your_secure_db_password
DATABASE_URL=postgresql+psycopg2://postgres:your_pass@db.your-supabase.supabase.co:5432/postgres

# Security
SECRET_KEY=openssl_rand_base64_32_chars
ADMIN_DASHBOARD_KEY=secure-admin-pass-2024
REDIS_PASSWORD=secure_redis_pass

# URLs (Critical for CORS)
API_BASE_URL=https://api.storelink.in/v1
WEB_APP_URL=https://shop.storelink.in
ADMIN_APP_URL=https://admin.storelink.in
CORS_ORIGINS=https://shop.storelink.in,https://admin.storelink.in

# Third-Party (Dodo Payments)
DODO_PAYMENTS_API_KEY=live_...
DODO_PAYMENTS_WEBHOOK_KEY=whsec_...
```

---

## 4. Deployment Steps

### Step A: Build & Launch Services
```bash
# Build all containers (Backend, Frontend, Nginx)
docker compose up -d --build
```

### Step B: Database Migrations
Run this once the backend container is healthy:
```bash
docker exec -it storelink_backend alembic upgrade head
```

### Step C: SSL Certificates (Certbot)
Run this on the host machine to get SSL for your domains:
```bash
sudo certbot --nginx -d api.storelink.in -d shop.storelink.in -d admin.storelink.in
```

---

## 5. Directory Structure for Persistence
- `/opt/storelink/backend/uploads`: User images (Products, Logos).
- `/opt/storelink/backend/logs`: System logs.
- `/var/lib/docker/volumes`: Database & Redis persistence.

---

## 6. Maintenance & Monitoring

| Task | Command |
| :--- | :--- |
| **Check Logs** | `docker compose logs -f backend` |
| **Restart App** | `docker compose restart` |
| **Update Code** | `git pull && docker compose up -d --build` |
| **Database Backup** | `docker exec storelink_db pg_dump -U user > backup.sql` |

---

## 💡 Pro Tips for Production
1. **Sentry**: Add `SENTRY_DSN` to `.env` to track backend errors in real-time.
2. **Backups**: Set up a cron job to backup the `uploads/` directory daily.
3. **CI/CD**: Use GitHub Actions to auto-deploy to your server on `git push main`.
4. **Resources**: Minimum 2GB RAM / 1 vCPU server recommended.

---
© 2024 StoreLink Management Platform
