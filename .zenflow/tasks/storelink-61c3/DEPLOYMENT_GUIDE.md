# StoreLink Production Deployment Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Server Setup](#server-setup)
3. [Database Configuration](#database-configuration)
4. [Application Deployment](#application-deployment)
5. [SSL/TLS Configuration](#ssltls-configuration)
6. [Monitoring & Logging](#monitoring--logging)
7. [Backup Configuration](#backup-configuration)
8. [Maintenance](#maintenance)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Server Requirements
- **OS**: Ubuntu 22.04 LTS or later
- **RAM**: Minimum 2GB (4GB recommended)
- **CPU**: 2 cores minimum
- **Disk**: 20GB minimum (SSD recommended)
- **Domain**: Registered domain with DNS configured

### Required Software
- Python 3.11+
- MySQL 8.0+
- Redis 7.0+
- Nginx 1.18+
- Git

---

## Server Setup

### 1. Initial Server Configuration

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y python3.11 python3.11-venv python3-pip \
    mysql-server redis-server nginx git curl \
    certbot python3-certbot-nginx

# Create application user
sudo useradd -m -s /bin/bash storelink
sudo usermod -aG www-data storelink

# Create application directory
sudo mkdir -p /var/www/storelink
sudo chown -R storelink:www-data /var/www/storelink
```

### 2. Firewall Configuration

```bash
# Enable UFW
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable

# Verify firewall status
sudo ufw status
```

---

## Database Configuration

### 1. MySQL Setup

```bash
# Secure MySQL installation
sudo mysql_secure_installation

# Login to MySQL
sudo mysql -u root -p
```

```sql
-- Create production database
CREATE DATABASE storelink_production CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create database user
CREATE USER 'storelink_user'@'localhost' IDENTIFIED BY 'STRONG_PASSWORD_HERE';

-- Grant privileges
GRANT ALL PRIVILEGES ON storelink_production.* TO 'storelink_user'@'localhost';
FLUSH PRIVILEGES;

-- Verify
SHOW DATABASES;
EXIT;
```

### 2. MySQL Performance Tuning

Edit `/etc/mysql/mysql.conf.d/mysqld.cnf`:

```ini
[mysqld]
max_connections = 200
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT
query_cache_size = 0
query_cache_type = 0
```

```bash
# Restart MySQL
sudo systemctl restart mysql
```

---

## Redis Configuration

### 1. Redis Setup

Edit `/etc/redis/redis.conf`:

```ini
bind 127.0.0.1
port 6379
maxmemory 256mb
maxmemory-policy allkeys-lru
appendonly yes
```

```bash
# Restart Redis
sudo systemctl restart redis
sudo systemctl enable redis
```

---

## Application Deployment

### 1. Clone Repository

```bash
# Switch to storelink user
sudo su - storelink

# Navigate to application directory
cd /var/www/storelink

# Clone repository
git clone https://github.com/yourusername/storelink.git .

# Or if deploying from local
# scp -r /path/to/local/storelink user@server:/var/www/storelink/
```

### 2. Create Virtual Environment

```bash
cd /var/www/storelink/backend

# Create virtual environment
python3.11 -m venv /var/www/storelink/venv

# Activate virtual environment
source /var/www/storelink/venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt
```

### 3. Configure Environment

```bash
# Copy production environment file
cp .env.production .env

# Generate secret key
SECRET_KEY=$(openssl rand -hex 32)

# Edit .env file
nano .env
```

Update the following in `.env`:

```bash
DATABASE_URL=mysql+pymysql://storelink_user:YOUR_PASSWORD@localhost:3306/storelink_production
SECRET_KEY=YOUR_GENERATED_SECRET_KEY
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
ENVIRONMENT=production
DEBUG=false
REDIS_ENABLED=true
RATE_LIMIT_ENABLED=true
LOG_FILE=/var/log/storelink/app.log
```

### 4. Create Required Directories

```bash
# Create upload directory
sudo mkdir -p /var/www/storelink/uploads
sudo chown -R www-data:www-data /var/www/storelink/uploads
sudo chmod 755 /var/www/storelink/uploads

# Create log directory
sudo mkdir -p /var/log/storelink
sudo chown -R www-data:www-data /var/log/storelink
sudo chmod 755 /var/log/storelink
```

### 5. Run Database Migrations

```bash
cd /var/www/storelink/backend
source /var/www/storelink/venv/bin/activate

# Run migrations
alembic upgrade head
```

### 6. Setup Systemd Service

```bash
# Copy service file
sudo cp /var/www/storelink/backend/storelink.service /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable and start service
sudo systemctl enable storelink
sudo systemctl start storelink

# Check status
sudo systemctl status storelink

# View logs
sudo journalctl -u storelink -f
```

---

## SSL/TLS Configuration

### 1. Obtain SSL Certificate

```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx -y

# Obtain certificate
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Certificate auto-renewal is configured automatically
# Test renewal
sudo certbot renew --dry-run
```

### 2. Configure Nginx

```bash
# Copy nginx configuration
sudo cp /var/www/storelink/backend/nginx.conf /etc/nginx/sites-available/storelink

# Update domain names in config
sudo nano /etc/nginx/sites-available/storelink

# Create symbolic link
sudo ln -s /etc/nginx/sites-available/storelink /etc/nginx/sites-enabled/

# Remove default site
sudo rm /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Restart nginx
sudo systemctl restart nginx
sudo systemctl enable nginx
```

---

## Monitoring & Logging

### 1. Setup Log Rotation

Create `/etc/logrotate.d/storelink`:

```
/var/log/storelink/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    missingok
    create 0640 www-data www-data
    sharedscripts
    postrotate
        systemctl reload storelink > /dev/null 2>&1 || true
    endscript
}
```

### 2. Sentry Configuration (Optional)

```bash
# Sign up at https://sentry.io
# Create new project
# Copy DSN

# Update .env
nano /var/www/storelink/backend/.env

# Add:
SENTRY_DSN=your-sentry-dsn-here
SENTRY_ENVIRONMENT=production

# Restart service
sudo systemctl restart storelink
```

---

## Backup Configuration

### 1. Setup Database Backups

```bash
# Make backup script executable
chmod +x /var/www/storelink/backend/scripts/backup_database.sh
chmod +x /var/www/storelink/backend/scripts/restore_database.sh
chmod +x /var/www/storelink/backend/scripts/setup_cron.sh

# Create backup directory
sudo mkdir -p /var/backups/storelink
sudo chown storelink:storelink /var/backups/storelink

# Set MySQL password environment variable
echo "export MYSQL_PASSWORD='your_db_password'" >> ~/.bashrc
source ~/.bashrc

# Setup cron job
cd /var/www/storelink/backend/scripts
./setup_cron.sh
```

### 2. Test Backup

```bash
# Run backup manually
/var/www/storelink/backend/scripts/backup_database.sh

# Check backup files
ls -lh /var/backups/storelink/
```

### 3. Setup File Backups

```bash
# Install rsync
sudo apt install rsync -y

# Create backup script
cat > /var/www/storelink/backup_files.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/var/backups/storelink/files"
DATE=$(date +"%Y%m%d_%H%M%S")

mkdir -p "$BACKUP_DIR"

rsync -av --delete \
    /var/www/storelink/uploads/ \
    "$BACKUP_DIR/uploads_${DATE}/"

find "$BACKUP_DIR" -name "uploads_*" -mtime +30 -exec rm -rf {} \;
EOF

chmod +x /var/www/storelink/backup_files.sh

# Add to crontab
(crontab -l 2>/dev/null; echo "0 3 * * * /var/www/storelink/backup_files.sh") | crontab -
```

---

## CI/CD Setup (GitHub Actions)

### 1. Generate SSH Key

```bash
# On server
ssh-keygen -t ed25519 -C "github-actions@storelink"

# Add to authorized_keys
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
```

### 2. Configure GitHub Secrets

Add the following secrets to your GitHub repository:
- `SSH_PRIVATE_KEY`: Contents of `~/.ssh/id_ed25519`
- `SERVER_HOST`: Your server IP or domain
- `SERVER_USER`: `storelink`

### 3. Push CI/CD Configuration

The `.github/workflows/ci-cd.yml` file is already configured.

```bash
git add .github/workflows/ci-cd.yml
git commit -m "Add CI/CD pipeline"
git push origin main
```

---

## Maintenance

### Daily Tasks
- Monitor application logs
- Check disk space
- Review error logs

### Weekly Tasks
- Verify backups are running
- Check system resource usage
- Review security logs

### Monthly Tasks
- Update system packages
- Review and optimize database
- Test backup restoration

---

## Monitoring Commands

```bash
# Check application status
sudo systemctl status storelink

# View application logs
sudo journalctl -u storelink -f

# View nginx logs
sudo tail -f /var/log/nginx/storelink_access.log
sudo tail -f /var/log/nginx/storelink_error.log

# View application logs
sudo tail -f /var/log/storelink/app.log

# Check disk space
df -h

# Check memory usage
free -h

# Check MySQL status
sudo systemctl status mysql

# Check Redis status
sudo systemctl status redis

# Monitor database connections
mysql -u storelink_user -p -e "SHOW PROCESSLIST;"

# Check Redis connections
redis-cli info clients
```

---

## Troubleshooting

### Application Won't Start

```bash
# Check logs
sudo journalctl -u storelink -n 50

# Check environment
source /var/www/storelink/venv/bin/activate
cd /var/www/storelink/backend
python -c "from app.config import settings; print(settings.DATABASE_URL)"

# Test database connection
alembic current
```

### Database Connection Issues

```bash
# Check MySQL is running
sudo systemctl status mysql

# Test connection
mysql -u storelink_user -p storelink_production

# Check user permissions
mysql -u root -p -e "SHOW GRANTS FOR 'storelink_user'@'localhost';"
```

### High Memory Usage

```bash
# Check processes
top
htop

# Restart application
sudo systemctl restart storelink

# Adjust worker count in storelink.service
sudo nano /etc/systemd/system/storelink.service
# Change --workers value
sudo systemctl daemon-reload
sudo systemctl restart storelink
```

### SSL Certificate Issues

```bash
# Check certificate expiry
sudo certbot certificates

# Renew manually
sudo certbot renew

# Check nginx config
sudo nginx -t
```

---

## Performance Optimization

### 1. Enable Gzip in Nginx
Already configured in nginx.conf

### 2. Database Query Optimization

```sql
-- Check slow queries
SHOW VARIABLES LIKE 'slow_query_log';

-- Enable slow query log
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2;
```

### 3. Redis Caching
Already configured. Monitor cache hit rate:

```bash
redis-cli info stats | grep keyspace
```

---

## Security Checklist

- [x] Firewall configured (UFW)
- [x] SSL/TLS enabled
- [x] Database user with limited privileges
- [x] Environment variables secured
- [x] File permissions set correctly
- [x] Rate limiting enabled
- [x] Security headers configured in Nginx
- [x] Regular backups configured
- [x] Logs monitored
- [x] Updates applied regularly

---

## Support

For issues or questions:
- Check logs first
- Review this documentation
- Check GitHub issues
- Contact: support@yourdomain.com

---

## Version History

- **v1.0.0** (2024-01-13): Initial production deployment guide
