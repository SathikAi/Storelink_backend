# StoreLink Production Deployment

## 🚀 Quick Start

### Option 1: Docker Deployment (Recommended)

```bash
# Clone repository
git clone <repo-url>
cd storelink

# Configure environment
cp .env.docker.example .env.docker
nano .env.docker  # Update credentials

# Generate secret key
openssl rand -hex 32

# Start services
docker-compose --env-file .env.docker up -d

# Run migrations
docker-compose exec backend alembic upgrade head

# Check status
docker-compose ps
curl http://localhost:8000/health
```

**See**: [DOCKER_DEPLOYMENT.md](.zenflow/tasks/storelink-61c3/DOCKER_DEPLOYMENT.md) for complete guide

---

### Option 2: Traditional Server Deployment

```bash
# System requirements: Ubuntu 22.04, Python 3.11, MySQL 8.0, Redis 7

# Install dependencies
sudo apt install python3.11 mysql-server redis-server nginx

# Clone and setup
git clone <repo-url> /var/www/storelink
cd /var/www/storelink/backend

# Create virtual environment
python3.11 -m venv ../venv
source ../venv/bin/activate
pip install -r requirements.txt

# Configure environment
cp .env.production .env
nano .env  # Update credentials

# Run migrations
alembic upgrade head

# Setup systemd service
sudo cp storelink.service /etc/systemd/system/
sudo systemctl enable storelink
sudo systemctl start storelink

# Setup nginx
sudo cp nginx.conf /etc/nginx/sites-available/storelink
sudo ln -s /etc/nginx/sites-available/storelink /etc/nginx/sites-enabled/
sudo systemctl restart nginx

# Setup SSL
sudo certbot --nginx -d yourdomain.com
```

**See**: [DEPLOYMENT_GUIDE.md](.zenflow/tasks/storelink-61c3/DEPLOYMENT_GUIDE.md) for complete guide

---

## 📋 Pre-Deployment Checklist

### Required
- [ ] Domain name registered and DNS configured
- [ ] Server with minimum 2GB RAM, 2 CPU cores
- [ ] MySQL 8.0+ installed and configured
- [ ] Redis 7.0+ installed and configured
- [ ] Strong passwords generated for all services
- [ ] SECRET_KEY generated (`openssl rand -hex 32`)

### Configuration
- [ ] Update `.env` or `.env.docker` with production values
- [ ] Set `DEBUG=false`
- [ ] Set `OTP_MOCK=false`
- [ ] Configure `CORS_ORIGINS` with your domain
- [ ] Set strong `DATABASE_URL` password
- [ ] Configure SMTP (if using email features)

### Security
- [ ] Firewall configured (ports 80, 443 only)
- [ ] SSL certificate obtained
- [ ] Rate limiting enabled
- [ ] Security headers configured in Nginx

### Operations
- [ ] Backup script configured and tested
- [ ] Monitoring/logging verified
- [ ] Health checks working
- [ ] Migrations completed successfully

---

## 🔧 Configuration Files

| File | Purpose |
|------|---------|
| `.env.production` | Production environment variables |
| `.env.docker.example` | Docker environment template |
| `nginx.conf` | Nginx reverse proxy configuration |
| `storelink.service` | Systemd service definition |
| `docker-compose.yml` | Docker orchestration |
| `Dockerfile` | Backend container image |

---

## 🛠️ Common Commands

### Service Management

```bash
# Check status
sudo systemctl status storelink
docker-compose ps

# View logs
sudo journalctl -u storelink -f
docker-compose logs -f backend

# Restart
sudo systemctl restart storelink
docker-compose restart backend

# Stop
sudo systemctl stop storelink
docker-compose down
```

### Database

```bash
# Backup
./scripts/backup_database.sh
docker-compose exec mysql mysqldump ...

# Restore
./scripts/restore_database.sh backup.sql.gz

# Migrations
alembic upgrade head
docker-compose exec backend alembic upgrade head
```

### Monitoring

```bash
# Application health
curl http://localhost:8000/health

# Logs
tail -f /var/log/storelink/app.log
docker-compose logs -f

# Resource usage
docker stats
```

---

## 📊 Performance Expectations

| Metric | Target |
|--------|--------|
| Response Time | <500ms (avg) |
| Concurrent Users | 1000+ |
| Uptime | 99.9% |
| Database Connections | 20 pool size |
| Worker Processes | 4 (configurable) |

---

## 🔐 Security Features

- ✅ SSL/TLS 1.2+ encryption
- ✅ Rate limiting (100 req/min default)
- ✅ JWT authentication
- ✅ Role-based access control
- ✅ Security headers (HSTS, XSS protection)
- ✅ Database connection pooling
- ✅ Redis caching with authentication
- ✅ Automated backups (daily)

---

## 📚 Documentation

- **[DEPLOYMENT_GUIDE.md](.zenflow/tasks/storelink-61c3/DEPLOYMENT_GUIDE.md)** - Complete server deployment
- **[DOCKER_DEPLOYMENT.md](.zenflow/tasks/storelink-61c3/DOCKER_DEPLOYMENT.md)** - Docker-specific deployment
- **[PHASE_11_SUMMARY.md](.zenflow/tasks/storelink-61c3/PHASE_11_SUMMARY.md)** - Production features overview
- **[QA_REPORT.md](.zenflow/tasks/storelink-61c3/QA_REPORT.md)** - Testing and quality assurance

---

## 🆘 Troubleshooting

### Application won't start
```bash
# Check logs
sudo journalctl -u storelink -n 50
docker-compose logs backend

# Verify database connection
mysql -u storelink_user -p
docker-compose exec mysql mysql -u storelink_user -p
```

### Database connection failed
- Check MySQL is running: `sudo systemctl status mysql`
- Verify credentials in `.env`
- Test connection: `mysql -u storelink_user -p storelink_production`

### Redis connection failed
- Check Redis is running: `sudo systemctl status redis`
- Test connection: `redis-cli ping`
- Verify `REDIS_URL` in `.env`

### SSL certificate issues
```bash
# Check certificate
sudo certbot certificates

# Renew manually
sudo certbot renew

# Test nginx config
sudo nginx -t
```

---

## 💰 Cost Estimate

### Minimum Setup (Indian MSMEs)
- **VPS Hosting**: ₹500-1000/month (Hetzner, DigitalOcean, AWS Lightsail)
- **Domain**: ₹500-1000/year
- **SSL Certificate**: Free (Let's Encrypt)
- **Backup Storage**: Local (free) or S3 (~₹100/month)

**Total**: ~₹700-1200/month = ₹8,400-14,400/year

**Break-even**: 3-4 customers at ₹3999/year

---

## 📞 Support

- **Documentation**: See guides in `.zenflow/tasks/storelink-61c3/`
- **Issues**: Check logs first, then troubleshooting guides
- **Updates**: `git pull origin main && docker-compose up -d --build`

---

## 🎯 Production Readiness Status

| Component | Status |
|-----------|--------|
| Backend API | ✅ Complete (174 tests) |
| Database Schema | ✅ Complete (9 tables) |
| Authentication | ✅ Complete (JWT + OTP) |
| Business Logic | ✅ Complete (All features) |
| Security | ✅ OWASP Top 10 compliant |
| Performance | ✅ Optimized (caching, pooling) |
| Monitoring | ✅ Logging + Sentry ready |
| Backups | ✅ Automated daily |
| CI/CD | ✅ GitHub Actions |
| Documentation | ✅ Complete |
| Flutter Frontend | ⏳ Pending |

**Backend Status**: ✅ **PRODUCTION READY**

---

## 📝 License

See LICENSE file for details.

---

## 🙏 Acknowledgments

Built for Indian MSMEs with ❤️

Target: Affordable (₹3999/year), Powerful, Open-source alternative to Dukaan
