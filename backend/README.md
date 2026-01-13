# StoreLink Backend

Indian MSME Business Management SaaS Platform - FastAPI Backend

## Tech Stack
- FastAPI 0.104+
- MySQL 8.0+
- SQLAlchemy 2.0+
- JWT Authentication
- Alembic for migrations

## Getting Started

### Prerequisites
- Python 3.11+
- MySQL 8.0+

### Installation

```bash
pip install -r requirements.txt
```

### Environment Setup

```bash
cp .env.example .env
# Edit .env with your database credentials and secret key
```

### Database Setup

```bash
# Create database
mysql -u root -p -e "CREATE DATABASE storelink CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# Run migrations
alembic upgrade head
```

### Run Server

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## API Documentation

Once the server is running:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Project Structure
- `app/models/` - SQLAlchemy database models
- `app/schemas/` - Pydantic schemas for validation
- `app/routers/` - API route handlers
- `app/services/` - Business logic services
- `app/core/` - Security, RBAC, plan gating
- `app/utils/` - Utility functions (PDF, CSV, validators)
- `alembic/` - Database migration files
