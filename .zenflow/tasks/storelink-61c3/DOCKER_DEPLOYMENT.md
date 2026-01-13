# StoreLink Docker Deployment Guide

## Quick Start with Docker

This guide provides instructions for deploying StoreLink using Docker and Docker Compose.

---

## Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Domain name configured (for SSL)
- Git

---

## Initial Setup

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/storelink.git
cd storelink
```

### 2. Configure Environment

```bash
# Copy environment template
cp .env.docker.example .env.docker

# Generate secret key
SECRET_KEY=$(openssl rand -hex 32)

# Edit environment file
nano .env.docker
```

Update the following variables:
```bash
MYSQL_ROOT_PASSWORD=your_strong_root_password
MYSQL_PASSWORD=your_strong_password
SECRET_KEY=your_generated_secret_key
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

---

## Deployment

### 1. Start Services

```bash
# Build and start all services
docker-compose --env-file .env.docker up -d

# View logs
docker-compose logs -f

# Check service status
docker-compose ps
```

### 2. Run Database Migrations

```bash
# Execute migrations
docker-compose exec backend alembic upgrade head

# Verify
docker-compose exec backend alembic current
```

### 3. SSL Certificate Setup

First, update `backend/nginx.conf` with your domain name, then:

```bash
# Stop nginx temporarily
docker-compose stop nginx

# Obtain certificate
docker-compose run --rm certbot certonly --webroot \
  --webroot-path=/var/www/certbot \
  -d yourdomain.com \
  -d www.yourdomain.com \
  --email your-email@domain.com \
  --agree-tos \
  --no-eff-email

# Start nginx
docker-compose start nginx
```

---

## Management Commands

### Service Management

```bash
# Start services
docker-compose --env-file .env.docker up -d

# Stop services
docker-compose down

# Restart specific service
docker-compose restart backend

# View logs
docker-compose logs -f backend
docker-compose logs -f nginx

# Scale backend workers
docker-compose up -d --scale backend=3
```

### Database Management

```bash
# Backup database
docker-compose exec mysql mysqldump \
  -u storelink_user -p storelink_production \
  > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore database
docker-compose exec -T mysql mysql \
  -u storelink_user -p storelink_production \
  < backup_file.sql

# Access MySQL shell
docker-compose exec mysql mysql -u storelink_user -p storelink_production
```

### Application Management

```bash
# Access backend shell
docker-compose exec backend /bin/bash

# Run tests
docker-compose exec backend pytest

# Check application health
curl http://localhost:8000/health

# View application logs
docker-compose logs -f backend
```

### Redis Management

```bash
# Access Redis CLI
docker-compose exec redis redis-cli

# Monitor Redis
docker-compose exec redis redis-cli MONITOR

# Flush Redis cache
docker-compose exec redis redis-cli FLUSHDB
```

---

## Monitoring

### Container Health

```bash
# Check container status
docker-compose ps

# View resource usage
docker stats

# Inspect specific container
docker inspect storelink_backend
```

### Application Logs

```bash
# Real-time logs
docker-compose logs -f

# Logs for specific service
docker-compose logs -f backend

# Last 100 lines
docker-compose logs --tail=100 backend
```

---

## Backup & Restore

### Automated Backup Script

Create `backup.sh`:

```bash
#!/bin/bash

BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# Database backup
docker-compose exec -T mysql mysqldump \
  -u storelink_user -p${MYSQL_PASSWORD} \
  storelink_production \
  > "$BACKUP_DIR/db_${DATE}.sql"

# Files backup
docker-compose exec backend tar -czf - /app/uploads \
  > "$BACKUP_DIR/uploads_${DATE}.tar.gz"

# Keep only last 7 days
find "$BACKUP_DIR" -name "*.sql" -mtime +7 -delete
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
```

```bash
chmod +x backup.sh

# Add to crontab
(crontab -l 2>/dev/null; echo "0 2 * * * /path/to/storelink/backup.sh") | crontab -
```

---

## Updating

### Application Update

```bash
# Pull latest changes
git pull origin main

# Rebuild and restart
docker-compose build backend
docker-compose up -d backend

# Run migrations
docker-compose exec backend alembic upgrade head

# Verify
curl http://localhost:8000/health
```

### System Update

```bash
# Pull latest images
docker-compose pull

# Recreate containers
docker-compose up -d --force-recreate

# Clean up old images
docker image prune -a
```

---

## Troubleshooting

### Backend Not Starting

```bash
# Check logs
docker-compose logs backend

# Verify database connection
docker-compose exec backend python -c "from app.config import settings; print(settings.DATABASE_URL)"

# Test database connectivity
docker-compose exec mysql mysql -u storelink_user -p
```

### Database Connection Issues

```bash
# Check MySQL status
docker-compose ps mysql

# Restart MySQL
docker-compose restart mysql

# Check MySQL logs
docker-compose logs mysql
```

### Nginx/SSL Issues

```bash
# Check nginx config
docker-compose exec nginx nginx -t

# Restart nginx
docker-compose restart nginx

# View nginx logs
docker-compose logs nginx

# Renew SSL certificate
docker-compose run --rm certbot renew
```

### Performance Issues

```bash
# Check resource usage
docker stats

# View container details
docker-compose ps

# Restart specific service
docker-compose restart backend
```

---

## Production Optimization

### Docker Compose Override

Create `docker-compose.prod.yml`:

```yaml
version: '3.8'

services:
  backend:
    deploy:
      replicas: 4
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  mysql:
    command: --max-connections=200 --innodb-buffer-pool-size=1G
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G

  redis:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
```

Use with:
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

---

## Security Best Practices

1. **Secrets Management**
   - Never commit `.env.docker` to version control
   - Use Docker secrets for sensitive data
   - Rotate credentials regularly

2. **Network Security**
   - Use isolated Docker networks
   - Expose only necessary ports
   - Enable firewall (UFW)

3. **Updates**
   - Keep Docker and images updated
   - Monitor security advisories
   - Apply patches promptly

4. **Monitoring**
   - Set up container monitoring
   - Configure alerts
   - Review logs regularly

---

## Cleanup

### Remove All Containers

```bash
# Stop and remove all containers
docker-compose down

# Remove volumes (WARNING: deletes all data)
docker-compose down -v

# Remove images
docker-compose down --rmi all
```

### Prune System

```bash
# Remove unused containers
docker container prune

# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune

# Remove everything
docker system prune -a --volumes
```

---

## Support

For Docker-specific issues:
- Check logs: `docker-compose logs`
- Verify configuration: `docker-compose config`
- Test connectivity: `docker-compose exec backend ping mysql`

For application issues, refer to the main [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
