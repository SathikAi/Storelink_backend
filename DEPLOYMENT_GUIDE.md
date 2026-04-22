# StoreLink — Full Deployment Guide

> **Stack:** Flutter Web · Flutter Android · FastAPI · PostgreSQL · Redis · Nginx · Docker

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Prerequisites](#2-prerequisites)
3. [Server Setup (VPS)](#3-server-setup-vps)
4. [Environment Configuration](#4-environment-configuration)
5. [Backend Deployment](#5-backend-deployment)
6. [Flutter Web Deployment](#6-flutter-web-deployment)
7. [Android APK Build](#7-android-apk-build)
8. [Admin Portal](#8-admin-portal)
9. [SSL Certificate (HTTPS)](#9-ssl-certificate-https)
10. [Full Docker Deploy (Recommended)](#10-full-docker-deploy-recommended)
11. [Database Migrations](#11-database-migrations)
12. [Monitoring & Logs](#12-monitoring--logs)
13. [Updating the App](#13-updating-the-app)
14. [Environment Variables Reference](#14-environment-variables-reference)
15. [Troubleshooting](#15-troubleshooting)

---

## 1. Architecture Overview

```
                        Internet
                           │
                     ┌─────▼─────┐
                     │   Nginx   │  :80 / :443
                     │ (Reverse  │  SSL Termination
                     │  Proxy)   │  Rate Limiting
                     └─────┬─────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
    ┌──────▼──────┐ ┌──────▼──────┐ ┌─────▼──────┐
    │  Flutter    │ │   FastAPI   │ │  /uploads  │
    │  Web App   │ │  Backend    │ │  (Static)  │
    │  :80 (web) │ │  :8000      │ │            │
    └─────────────┘ └──────┬──────┘ └────────────┘
                           │
              ┌────────────┼────────────┐
              │                         │
       ┌──────▼──────┐         ┌────────▼────┐
       │ PostgreSQL  │         │    Redis    │
       │   :5432     │         │    :6379    │
       └─────────────┘         └─────────────┘

Mobile (Android APK) → talks directly to Backend API
```

### URL Routing

| URL | Serves |
|-----|--------|
| `https://yourdomain.com/` | Flutter Web App |
| `https://yourdomain.com/v1/*` | FastAPI Backend |
| `https://yourdomain.com/admin-dashboard` | Admin Portal |
| `https://yourdomain.com/uploads/*` | Uploaded images |
| `https://yourdomain.com/health` | Health check |

---

## 2. Prerequisites

### Local Machine (Development)
- Flutter SDK ≥ 3.6.0
- Python 3.11+
- Android Studio + SDK (for APK)
- Git

### VPS / Cloud Server (Production)
- **OS:** Ubuntu 22.04 LTS (recommended)
- **RAM:** Minimum 2GB (4GB recommended)
- **CPU:** 2 vCPU
- **Storage:** 20GB SSD
- **Open Ports:** 22 (SSH), 80 (HTTP), 443 (HTTPS)

### VPS Providers (India-friendly)
- **DigitalOcean** — $12/month (2GB RAM) — [digitalocean.com](https://digitalocean.com)
- **Vultr** — $12/month
- **Hetzner** — $5/month (cheapest, Germany server)
- **AWS Lightsail** — $10/month
- **Hostinger VPS** — ₹599/month (India server)

---

## 3. Server Setup (VPS)

### 3.1 First-time Server Setup

```bash
# Connect to your server
ssh root@YOUR_SERVER_IP

# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh
usermod -aG docker $USER

# Install Docker Compose
apt install -y docker-compose-plugin

# Install Git and other tools
apt install -y git curl wget ufw

# Firewall setup
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable

# Verify Docker
docker --version
docker compose version
```

### 3.2 Clone the Project

```bash
# On the server
cd /opt
git clone https://github.com/YOUR_USERNAME/storelink.git
cd storelink

# OR upload from local machine
scp -r ./storelink root@YOUR_SERVER_IP:/opt/storelink
```

---

## 4. Environment Configuration

### 4.1 Create .env file

```bash
cd /opt/storelink
cp .env.example .env
nano .env
```

### 4.2 Fill in all values

```env
# ── Domain ─────────────────────────────────────────────
DOMAIN=yourdomain.com
API_BASE_URL=https://yourdomain.com/v1
WEB_APP_URL=https://yourdomain.com

# ── Database ────────────────────────────────────────────
POSTGRES_PASSWORD=MyStr0ngP@ssw0rd123!

# ── Redis ───────────────────────────────────────────────
REDIS_PASSWORD=MyR3disP@ss456!

# ── JWT Secret (generate below) ─────────────────────────
SECRET_KEY=your64charhexsecrethere

# ── Admin Dashboard ─────────────────────────────────────
ADMIN_DASHBOARD_KEY=MyAdminKey789!

# ── CORS ────────────────────────────────────────────────
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com

# ── Dodo Payments ───────────────────────────────────────
DODO_WEBHOOK_SECRET=whsec_your_webhook_secret

# ── Sentry (optional) ───────────────────────────────────
SENTRY_DSN=

# ── OTP ─────────────────────────────────────────────────
OTP_MOCK=false
```

### 4.3 Generate SECRET_KEY

```bash
python3 -c "import secrets; print(secrets.token_hex(32))"
# Copy the output → paste into SECRET_KEY in .env
```

### 4.4 Update Nginx config with your domain

```bash
# Replace DOMAIN with your actual domain
sed -i "s/DOMAIN/yourdomain.com/g" nginx/nginx.conf
```

---

## 5. Backend Deployment

### 5.1 Local Development (dev machine)

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate      # Linux/Mac
# venv\Scripts\activate       # Windows

# Install dependencies
pip install -r requirements.txt

# Create .env in backend folder
cp .env.example .env
nano .env

# Run migrations
alembic upgrade head

# Start server (with auto-reload)
uvicorn app.main:app --host 0.0.0.0 --port 9001 --reload
```

Backend running at: `http://localhost:9001`
API docs: `http://localhost:9001/docs`

### 5.2 Backend .env (development)

```env
DATABASE_URL=postgresql+psycopg2://postgres:password@localhost:5432/storelink
SECRET_KEY=dev_secret_key_minimum_32_characters_long
ENVIRONMENT=development
DEBUG=true
OTP_MOCK=true
CORS_ORIGINS=http://localhost:8080,http://127.0.0.1:8080
ADMIN_DASHBOARD_KEY=storelink-admin-2024
```

### 5.3 API Endpoints Reference

| Endpoint | Description |
|----------|-------------|
| `POST /v1/auth/otp/send` | Send OTP |
| `POST /v1/auth/otp/verify` | Verify OTP → get JWT |
| `GET /v1/auth/me` | Current user info + plan |
| `GET/POST /v1/business/profile` | Business profile |
| `GET/POST /v1/products` | Product management |
| `GET/POST /v1/orders` | Order management |
| `GET /v1/reports/sales` | Sales report (PAID only) |
| `GET /v1/reports/products` | Product report (PAID only) |
| `GET /v1/reports/customers` | Customer report (PAID only) |
| `POST /v1/billing/upgrade` | Start subscription |
| `POST /v1/billing/webhook` | Dodo payment webhook |
| `GET /v1/store/{uuid}` | Public store data |
| `GET /health` | Health check |

---

## 6. Flutter Web Deployment

### 6.1 Local Development

```bash
cd frontend

# Get dependencies
flutter pub get

# Run web in browser (dev)
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:9001/v1 \
  --dart-define=WEB_APP_URL=http://localhost:8080
```

### 6.2 Build for Production (web)

```bash
cd frontend

flutter build web --release \
  --dart-define=API_BASE_URL=https://yourdomain.com/v1 \
  --dart-define=WEB_APP_URL=https://yourdomain.com
```

Output: `frontend/build/web/`

### 6.3 Serve locally to test build

```bash
cd frontend/build/web
python -m http.server 8080
# Open: http://localhost:8080
```

### 6.4 Build for LAN Testing (phone + laptop same WiFi)

```bash
# Find your LAN IP
ipconfig    # Windows
ifconfig    # Linux/Mac

flutter build web --release \
  --dart-define=API_BASE_URL=http://192.168.1.38:9001/v1 \
  --dart-define=WEB_APP_URL=http://192.168.1.38:8080
```

---

## 7. Android APK Build

### 7.1 Development APK (for testing)

```bash
cd frontend

# Debug APK (larger, but no signing needed)
flutter build apk --debug \
  --dart-define=API_BASE_URL=http://192.168.1.38:9001/v1

# Release APK (for sharing / internal testing)
flutter build apk --release \
  --dart-define=API_BASE_URL=http://192.168.1.38:9001/v1 \
  --dart-define=WEB_APP_URL=http://192.168.1.38:8080
```

APK location: `frontend/build/app/outputs/flutter-apk/app-release.apk`

### 7.2 Production APK (for Play Store)

**Step 1 — Generate signing keystore (one time only)**

```bash
keytool -genkey -v \
  -keystore storelink-release.jks \
  -keyalg RSA -keysize 2048 \
  -validity 10000 \
  -alias storelink
# Remember the password you enter!
```

**Step 2 — Create key.properties**

```bash
# Create file: frontend/android/key.properties
cat > frontend/android/key.properties << EOF
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=storelink
storeFile=../storelink-release.jks
EOF
```

**Step 3 — Update android/app/build.gradle**

```gradle
// In android/app/build.gradle, add before android {}:
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing code ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

**Step 4 — Build signed APK**

```bash
cd frontend

# For production (uses live API)
flutter build apk --release \
  --dart-define=API_BASE_URL=https://yourdomain.com/v1 \
  --dart-define=WEB_APP_URL=https://yourdomain.com

# For App Bundle (Google Play Store)
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://yourdomain.com/v1 \
  --dart-define=WEB_APP_URL=https://yourdomain.com
```

### 7.3 Install APK on Phone

**Method 1 — USB:**
```bash
# List connected devices
adb devices

# Install directly
adb install frontend/build/app/outputs/flutter-apk/app-release.apk
```

**Method 2 — WhatsApp/Drive:**
1. APK file-ஐ உங்களுக்கே WhatsApp-ல் send பண்ணு
2. Phone-ல் download → install பண்ணு
3. Settings → Security → Unknown Sources → Allow

**Method 3 — QR Code share (Firebase App Distribution):**
```bash
# Install Firebase CLI
npm install -g firebase-tools
firebase login
firebase appdistribution:distribute app-release.apk \
  --app YOUR_FIREBASE_APP_ID \
  --groups "testers"
```

---

## 8. Admin Portal

### Access

- **URL:** `https://yourdomain.com/admin-dashboard`
- **Login:** Admin key from `.env` → `ADMIN_DASHBOARD_KEY`

### Features

| Tab | What it shows |
|-----|---------------|
| Overview | Stats cards, plan distribution chart, expiry alerts, recent signups |
| Businesses | All businesses with search, filter, CSV export, store links |
| Users | All users with role and status |
| Profile Completion | How complete each business profile is |

### Security

- Admin key must be **minimum 16 characters** in production
- Change the default key `storelink-admin-2024` before deploying
- Admin dashboard is behind Nginx — no rate limit bypass possible
- All admin API calls require `X-Admin-Key` header

---

## 9. SSL Certificate (HTTPS)

### 9.1 Point domain to your server

In your domain registrar (GoDaddy/Namecheap/etc.):
```
A Record:  yourdomain.com     → YOUR_SERVER_IP
A Record:  www.yourdomain.com → YOUR_SERVER_IP
```

Wait 10-30 minutes for DNS to propagate.

### 9.2 Get SSL certificate (first time)

```bash
cd /opt/storelink

# Start nginx with HTTP only (temporary)
docker compose up -d nginx

# Wait 30 seconds
sleep 30

# Get certificate
docker compose run --rm certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email admin@yourdomain.com \
  --agree-tos \
  --no-eff-email \
  -d yourdomain.com \
  -d www.yourdomain.com

# Restart nginx with HTTPS config
docker compose restart nginx
```

### 9.3 Auto-renew (certbot handles this)

The certbot container already auto-renews every 12 hours.

### 9.4 Verify SSL

```bash
curl -I https://yourdomain.com/health
# Should return: HTTP/2 200
```

---

## 10. Full Docker Deploy (Recommended)

### 10.1 First Deploy

```bash
cd /opt/storelink

# 1. Setup environment
cp .env.example .env
nano .env   # Fill in all values

# 2. Update nginx domain
sed -i "s/DOMAIN/yourdomain.com/g" nginx/nginx.conf

# 3. Create directories
mkdir -p backend/uploads backend/logs certbot/conf certbot/www

# 4. Build all images
docker compose build

# 5. Start database first
docker compose up -d postgres redis
sleep 10

# 6. Run migrations
docker compose run --rm backend alembic upgrade head

# 7. Start everything
docker compose up -d

# 8. Setup SSL (after DNS points to server)
docker compose run --rm certbot certonly \
  --webroot --webroot-path=/var/www/certbot \
  --email admin@yourdomain.com --agree-tos --no-eff-email \
  -d yourdomain.com -d www.yourdomain.com

# 9. Restart nginx for HTTPS
docker compose restart nginx
```

### 10.2 Using the Deploy Script

```bash
# Make executable
chmod +x deploy.sh

# First deploy with SSL + migrations
./deploy.sh --ssl --migrate

# Future updates (no SSL needed again)
./deploy.sh
```

### 10.3 Check Status

```bash
# All containers running?
docker compose ps

# Backend logs
docker compose logs backend --tail=50

# Nginx logs
docker compose logs nginx --tail=50

# Database logs
docker compose logs postgres --tail=20
```

### 10.4 Docker Commands Cheatsheet

```bash
# Stop everything
docker compose down

# Restart one service
docker compose restart backend

# Rebuild and restart backend
docker compose up -d --build backend

# Enter backend container
docker compose exec backend bash

# Enter database
docker compose exec postgres psql -U storelink_user -d storelink

# View all logs live
docker compose logs -f
```

---

## 11. Database Migrations

### Create a new migration

```bash
# In backend folder (or via docker)
alembic revision --autogenerate -m "description_of_change"

# Apply migration
alembic upgrade head

# Via docker (production)
docker compose run --rm backend alembic upgrade head
```

### Rollback migration

```bash
# Go back one step
alembic downgrade -1

# Go back to specific revision
alembic downgrade abc123def456
```

### Check migration status

```bash
alembic current
alembic history --verbose
```

### Backup database before migration

```bash
# Backup
docker compose exec postgres pg_dump -U storelink_user storelink > backup_$(date +%Y%m%d).sql

# Restore if needed
cat backup_20260415.sql | docker compose exec -T postgres psql -U storelink_user storelink
```

---

## 12. Monitoring & Logs

### 12.1 Application Logs

```bash
# Backend logs (live)
docker compose logs -f backend

# Nginx access logs
docker compose logs -f nginx

# All logs
docker compose logs -f
```

### 12.2 Health Check

```bash
# Quick check
curl https://yourdomain.com/health

# Expected response:
# {"success": true, "status": "healthy"}
```

### 12.3 Sentry Setup (optional — error tracking)

1. Create account at [sentry.io](https://sentry.io) (free tier available)
2. Create new project → Python/FastAPI
3. Copy DSN → add to `.env`:
   ```
   SENTRY_DSN=https://xxxxx@sentry.io/yyyyy
   ```
4. Errors will auto-appear in Sentry dashboard

### 12.4 Server Resources

```bash
# Check disk usage
df -h

# Check memory
free -h

# Check CPU/processes
htop

# Docker resource usage
docker stats
```

### 12.5 Log Rotation

Logs are stored in `backend/logs/`. Auto-rotate via logrotate:

```bash
cat > /etc/logrotate.d/storelink << EOF
/opt/storelink/backend/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
}
EOF
```

---

## 13. Updating the App

### 13.1 Backend Only Update

```bash
cd /opt/storelink
git pull origin main
docker compose up -d --build backend
```

### 13.2 Frontend Update (Web)

Frontend is rebuilt inside Docker automatically on deploy:

```bash
cd /opt/storelink
git pull origin main
docker compose up -d --build frontend
docker compose restart nginx
```

### 13.3 Full Update with Migration

```bash
cd /opt/storelink
git pull origin main

# Backup DB first
docker compose exec postgres pg_dump -U storelink_user storelink > backup_$(date +%Y%m%d_%H%M).sql

# Run migrations
docker compose run --rm backend alembic upgrade head

# Rebuild and restart
docker compose up -d --build
```

### 13.4 Zero-downtime Update

```bash
# Build new images without stopping old ones
docker compose build backend frontend

# Restart one by one
docker compose up -d --no-deps backend
sleep 10
docker compose up -d --no-deps frontend
docker compose restart nginx
```

### 13.5 Update Android APK

```bash
# On your dev machine
cd frontend

flutter build apk --release \
  --dart-define=API_BASE_URL=https://yourdomain.com/v1 \
  --dart-define=WEB_APP_URL=https://yourdomain.com

# Share new APK to testers via WhatsApp/Firebase
```

---

## 14. Environment Variables Reference

### Backend (.env)

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `DATABASE_URL` | ✅ | PostgreSQL connection | `postgresql+psycopg2://user:pass@host:5432/db` |
| `SECRET_KEY` | ✅ | JWT signing key (min 32 chars) | `a1b2c3...` (64 hex chars) |
| `ENVIRONMENT` | ✅ | `development` or `production` | `production` |
| `DEBUG` | ✅ | Must be `false` in production | `false` |
| `OTP_MOCK` | ✅ | `true` for dev, `false` for prod | `false` |
| `ADMIN_DASHBOARD_KEY` | ✅ | Admin portal password | `MyStr0ngKey!` |
| `CORS_ORIGINS` | ✅ | Allowed origins (comma-separated) | `https://yourdomain.com` |
| `REDIS_URL` | ❌ | Redis connection (for rate limiting) | `redis://:pass@redis:6379/0` |
| `REDIS_ENABLED` | ❌ | Enable Redis caching | `true` |
| `RATE_LIMIT_ENABLED` | ❌ | Enable API rate limiting | `true` |
| `DODO_PAYMENTS_API_KEY` | ❌ | Dodo payment gateway key | `sk_live_...` |
| `DODO_PAYMENTS_PRODUCT_ID_MONTHLY` | ❌ | Monthly plan product ID | `prod_...` |
| `DODO_PAYMENTS_PRODUCT_ID_YEARLY` | ❌ | Yearly plan product ID | `prod_...` |
| `DODO_PAYMENTS_WEBHOOK_KEY` | ❌ | Webhook verification secret | `whsec_...` |
| `DODO_PAYMENTS_RETURN_URL` | ❌ | After payment redirect | `https://yourdomain.com/v1/billing/upgrade-success` |
| `DODO_PAYMENTS_ENVIRONMENT` | ❌ | `test_mode` or `live_mode` | `live_mode` |
| `SENTRY_DSN` | ❌ | Sentry error tracking | `https://xxx@sentry.io/yyy` |
| `SMTP_HOST` | ❌ | Email server | `smtp.gmail.com` |
| `SMTP_USER` | ❌ | Email username | `your@gmail.com` |
| `SMTP_PASSWORD` | ❌ | Email app password | `xxxx xxxx xxxx xxxx` |

### Flutter Build (--dart-define)

| Variable | Description | Dev | Production |
|----------|-------------|-----|------------|
| `API_BASE_URL` | Backend API URL | `http://192.168.1.x:9001/v1` | `https://yourdomain.com/v1` |
| `WEB_APP_URL` | Web app base URL (for store links) | `http://192.168.1.x:8080` | `https://yourdomain.com` |

---

## 15. Troubleshooting

### Backend won't start

```bash
# Check logs
docker compose logs backend

# Common issues:
# 1. Database not ready → wait more and retry
docker compose restart backend

# 2. Missing env variable
docker compose exec backend env | grep SECRET_KEY

# 3. Migration not run
docker compose run --rm backend alembic upgrade head
```

### Flutter Web — blank page / error

```bash
# Check if web server is running
curl http://localhost:80

# Check if API is reachable from browser console (F12)
# Look for CORS errors → check CORS_ORIGINS in .env

# Rebuild with correct API URL
docker compose up -d --build frontend
```

### Flutter Web — reports not loading (type errors)

```
Error: TypeError: null: type 'Null' is not a subtype of type 'num'
```

**Cause:** Old build with wrong model parsing.
**Fix:** Rebuild Flutter web with latest code.

```bash
docker compose up -d --build frontend
```

### Mobile APK — connection error

```
DioException [connection error]: XMLHttpRequest onError
```

**Cause:** APK built with wrong API URL (old LAN IP).
**Fix:** Rebuild APK with correct URL.

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://yourdomain.com/v1
```

### SSL certificate error

```bash
# Check certificate exists
docker compose exec nginx ls /etc/letsencrypt/live/

# Renew manually
docker compose run --rm certbot renew

# Check certificate expiry
docker compose run --rm certbot certificates
```

### PostgreSQL connection refused

```bash
# Check if postgres is running
docker compose ps postgres

# Check postgres logs
docker compose logs postgres

# Restart postgres
docker compose restart postgres
sleep 10
docker compose restart backend
```

### Nginx 502 Bad Gateway

```bash
# Backend not running
docker compose logs backend --tail=20

# Restart backend
docker compose restart backend

# Check backend health
docker compose exec nginx curl http://backend:8000/health
```

### Port already in use

```bash
# Check what's using port 80
sudo lsof -i :80
sudo kill -9 <PID>

# Or just restart docker
docker compose down
docker compose up -d
```

### Out of disk space

```bash
# Check disk
df -h

# Clean Docker unused images/volumes
docker system prune -a --volumes

# Check log sizes
du -sh backend/logs/*
```

---

## Quick Reference Card

```bash
# ── Daily Operations ─────────────────────────────────────
docker compose ps                    # Status check
docker compose logs -f backend       # Live backend logs
curl https://yourdomain.com/health   # Health check

# ── Deploy Updates ───────────────────────────────────────
./deploy.sh                          # Full update
docker compose up -d --build backend # Backend only
docker compose restart nginx         # Nginx only

# ── Database ─────────────────────────────────────────────
docker compose run --rm backend alembic upgrade head    # Migrate
docker compose exec postgres psql -U storelink_user storelink  # DB shell
docker compose exec postgres pg_dump -U storelink_user storelink > backup.sql  # Backup

# ── Flutter Mobile ───────────────────────────────────────
flutter build apk --release \
  --dart-define=API_BASE_URL=https://yourdomain.com/v1
# APK: frontend/build/app/outputs/flutter-apk/app-release.apk

# ── Emergency Restart ────────────────────────────────────
docker compose down && docker compose up -d
```

---

## Deployment Checklist

Before going live, verify:

- [ ] `.env` file created with all values filled in
- [ ] `ADMIN_DASHBOARD_KEY` changed from default
- [ ] `OTP_MOCK=false` in production
- [ ] `DEBUG=false` in production
- [ ] Domain DNS points to server IP
- [ ] SSL certificate obtained and working
- [ ] `CORS_ORIGINS` includes your domain
- [ ] Database migrations applied (`alembic upgrade head`)
- [ ] Health check returns 200: `curl https://yourdomain.com/health`
- [ ] Admin dashboard accessible: `https://yourdomain.com/admin-dashboard`
- [ ] Flutter web loads correctly
- [ ] Mobile APK built with production API URL
- [ ] Dodo Payments webhook URL updated in Dodo dashboard
- [ ] Sentry configured for error monitoring (optional)
- [ ] Database backup configured

---

*StoreLink — Indian MSME SaaS Platform*
