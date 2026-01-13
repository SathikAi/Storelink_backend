# StoreLink

**Indian MSME Business Management Micro-SaaS**

A production-ready, scalable, and affordable business management platform for Indian MSMEs. 

## Overview

StoreLink is positioned as a powerful alternative to Dukaan with full backend ownership, comprehensive CRM, and complete business management capabilities at just ₹3999/year.

### Key Features

- **Multi-tenant SaaS** with business-level data isolation
- **Role-based access control** (SUPER_ADMIN, BUSINESS_OWNER)
- **Plan-based feature gating** (FREE vs PAID)
- **Product Management** - Full CRUD with categories, SKU, stock tracking
- **Order Management** - Complete order lifecycle with status tracking
- **Customer CRM** - Customer profiles, order history, search/filter
- **Reports & Export** - Sales, product, customer reports with PDF/CSV export (PAID)
- **Admin Panel** - Platform-wide business and user management
- **Mobile & Web** - Flutter-based responsive design

## Tech Stack

### Backend
- **FastAPI** - Modern Python web framework
- **MySQL 8.0+** - Relational database
- **SQLAlchemy 2.0+** - ORM
- **JWT** - Authentication
- **Alembic** - Database migrations

### Frontend
- **Flutter 3.16+** - Cross-platform framework
- **Provider** - State management
- **Clean Architecture** - Separation of concerns

## Project Structure

```
storelink/
├── backend/          # FastAPI backend
│   ├── app/
│   │   ├── models/   # Database models
│   │   ├── routers/  # API endpoints
│   │   ├── services/ # Business logic
│   │   └── core/     # Security, RBAC
│   └── alembic/      # Migrations
│
├── frontend/         # Flutter frontend
│   └── lib/
│       ├── core/     # Constants, theme
│       ├── data/     # Models, repositories
│       ├── domain/   # Entities
│       └── presentation/ # UI, providers
```

## Getting Started

### Backend Setup

```bash
cd backend
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your configuration
alembic upgrade head
uvicorn app.main:app --reload
```

### Frontend Setup

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

## Plan Comparison

| Feature | FREE | PAID (₹3999/year) |
|---------|------|-------------------|
| Products | 10 | Unlimited |
| Orders | 50 | Unlimited |
| Customers | 100 | Unlimited |
| Reports | ❌ | ✅ |
| Export (PDF/CSV) | ❌ | ✅ |
| Advanced Dashboard | ❌ | ✅ |
| Priority Support | ❌ | ✅ |

## Target Users

- Local shop owners
- Small retailers
- Home businesses
- WhatsApp sellers
- MSME entrepreneurs in India

## License

Proprietary - All rights reserved
