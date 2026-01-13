# StoreLink - Technical Specification

## Task Complexity Assessment: **HARD**

This is a complex, production-ready, multi-tenant SaaS platform requiring:
- Multi-tenant data isolation with business-level security
- Role-based access control (RBAC) across 2 user types
- Plan-based feature gating (FREE vs PAID)
- Full-stack architecture (FastAPI backend + Flutter frontend)
- Production-grade security, performance, and scalability
- Indian MSME market compliance
- Real revenue and customer impact

---

## 1. Technical Context

### Backend Stack
- **Framework**: FastAPI 0.104+ (Python 3.11+)
- **Database**: MySQL 8.0+
- **ORM**: SQLAlchemy 2.0+
- **Authentication**: JWT (PyJWT 2.8+)
- **Password Hashing**: bcrypt / passlib
- **Validation**: Pydantic v2
- **CORS**: FastAPI CORS middleware
- **File Upload**: python-multipart, Pillow (image processing)
- **Export**: reportlab (PDF), csv module (CSV)
- **Environment**: python-dotenv
- **Server**: Uvicorn (ASGI)

### Frontend Stack
- **Framework**: Flutter 3.16+ (Web + Mobile PWA)
- **State Management**: Provider
- **HTTP Client**: dio / http
- **Storage**: shared_preferences (token storage)
- **Routing**: go_router
- **Architecture**: Clean Architecture (data/domain/presentation layers)

### Database
- **MySQL 8.0+** with InnoDB engine
- **Character Set**: utf8mb4 (for emoji & multilingual support)
- **Timezone**: UTC storage, IST display
- **Connection Pooling**: SQLAlchemy pooling (pool_size=10, max_overflow=20)

### Deployment Targets
- **Backend**: Low-cost VPS (DigitalOcean, Linode, AWS Lightsail)
- **Database**: Same VPS or managed MySQL
- **Frontend**: Netlify / Vercel (Web), PWA for mobile
- **Storage**: Local filesystem or S3-compatible (Wasabi, Backblaze B2)

---

## 2. Database Schema Design

### Core Principles
1. **Multi-tenant isolation**: Every business-scoped table has `business_id` with indexed foreign key
2. **Soft deletes**: Use `deleted_at` timestamp (nullable) instead of hard deletes
3. **Audit trails**: `created_at`, `updated_at` on all tables
4. **UUID for public IDs**: Prevent enumeration attacks
5. **Indexed queries**: All foreign keys and frequently queried fields indexed

### Schema Tables

#### **users**
```sql
CREATE TABLE users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) NOT NULL UNIQUE,
    phone VARCHAR(15) NOT NULL UNIQUE,
    email VARCHAR(255) NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role ENUM('SUPER_ADMIN', 'BUSINESS_OWNER') NOT NULL DEFAULT 'BUSINESS_OWNER',
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    INDEX idx_phone (phone),
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_uuid (uuid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### **businesses**
```sql
CREATE TABLE businesses (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) NOT NULL UNIQUE,
    owner_id BIGINT NOT NULL,
    business_name VARCHAR(255) NOT NULL,
    business_type VARCHAR(100) NULL,
    phone VARCHAR(15) NOT NULL,
    email VARCHAR(255) NULL,
    address TEXT NULL,
    city VARCHAR(100) NULL,
    state VARCHAR(100) NULL,
    pincode VARCHAR(10) NULL,
    gstin VARCHAR(15) NULL,
    logo_url VARCHAR(500) NULL,
    plan ENUM('FREE', 'PAID') DEFAULT 'FREE',
    plan_expiry_date DATE NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_owner (owner_id),
    INDEX idx_plan (plan),
    INDEX idx_uuid (uuid),
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### **otp_verifications**
```sql
CREATE TABLE otp_verifications (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    phone VARCHAR(15) NOT NULL,
    otp_code VARCHAR(6) NOT NULL,
    purpose ENUM('LOGIN', 'REGISTRATION', 'PASSWORD_RESET') NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_phone_purpose (phone, purpose),
    INDEX idx_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### **categories**
```sql
CREATE TABLE categories (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) NOT NULL UNIQUE,
    business_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
    INDEX idx_business (business_id),
    INDEX idx_active (is_active),
    UNIQUE KEY unique_category_per_business (business_id, name, deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### **products**
```sql
CREATE TABLE products (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) NOT NULL UNIQUE,
    business_id BIGINT NOT NULL,
    category_id BIGINT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT NULL,
    sku VARCHAR(100) NULL,
    price DECIMAL(10, 2) NOT NULL,
    cost_price DECIMAL(10, 2) NULL,
    stock_quantity INT DEFAULT 0,
    unit VARCHAR(50) NULL,
    image_url VARCHAR(500) NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
    INDEX idx_business (business_id),
    INDEX idx_category (category_id),
    INDEX idx_active (is_active),
    INDEX idx_sku (sku)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### **customers**
```sql
CREATE TABLE customers (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) NOT NULL UNIQUE,
    business_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(15) NOT NULL,
    email VARCHAR(255) NULL,
    address TEXT NULL,
    city VARCHAR(100) NULL,
    state VARCHAR(100) NULL,
    pincode VARCHAR(10) NULL,
    notes TEXT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
    INDEX idx_business (business_id),
    INDEX idx_phone (phone),
    INDEX idx_active (is_active),
    UNIQUE KEY unique_customer_phone_per_business (business_id, phone, deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### **orders**
```sql
CREATE TABLE orders (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) NOT NULL UNIQUE,
    order_number VARCHAR(50) NOT NULL UNIQUE,
    business_id BIGINT NOT NULL,
    customer_id BIGINT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('PENDING', 'CONFIRMED', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED') DEFAULT 'PENDING',
    subtotal DECIMAL(10, 2) NOT NULL,
    tax_amount DECIMAL(10, 2) DEFAULT 0.00,
    discount_amount DECIMAL(10, 2) DEFAULT 0.00,
    total_amount DECIMAL(10, 2) NOT NULL,
    payment_method VARCHAR(50) NULL,
    payment_status ENUM('PENDING', 'PAID', 'FAILED', 'REFUNDED') DEFAULT 'PENDING',
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL,
    INDEX idx_business (business_id),
    INDEX idx_customer (customer_id),
    INDEX idx_order_date (order_date),
    INDEX idx_status (status),
    INDEX idx_uuid (uuid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### **order_items**
```sql
CREATE TABLE order_items (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_id BIGINT NULL,
    product_name VARCHAR(255) NOT NULL,
    product_sku VARCHAR(100) NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL,
    INDEX idx_order (order_id),
    INDEX idx_product (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### **plan_limits**
```sql
CREATE TABLE plan_limits (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    business_id BIGINT NOT NULL UNIQUE,
    max_products INT NULL,
    max_orders INT NULL,
    max_customers INT NULL,
    features JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
    INDEX idx_business (business_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

**JSON structure for features**:
```json
{
  "reports_enabled": false,
  "export_pdf": false,
  "export_csv": false,
  "advanced_dashboard": false,
  "priority_support": false
}
```

---

## 3. API Architecture

### Base URL Structure
```
https://api.storelink.in/v1
```

### Authentication Flow
1. **OTP Send**: `POST /auth/otp/send` → Send OTP to phone
2. **OTP Verify**: `POST /auth/otp/verify` → Verify OTP, return JWT
3. **Login**: `POST /auth/login` → Phone + Password, return JWT
4. **Register**: `POST /auth/register` → Create user + business
5. **Refresh**: `POST /auth/refresh` → Refresh JWT token

### JWT Token Structure
```json
{
  "sub": "user_uuid",
  "user_id": 123,
  "role": "BUSINESS_OWNER",
  "business_id": 456,
  "exp": 1704067200,
  "iat": 1704063600
}
```

### API Endpoints by Module

#### **Auth Module** (`/auth`)
- `POST /auth/register` - Register new user + business
- `POST /auth/login` - Login with phone + password
- `POST /auth/otp/send` - Send OTP
- `POST /auth/otp/verify` - Verify OTP and login
- `POST /auth/refresh` - Refresh JWT token
- `POST /auth/logout` - Logout (blacklist token)
- `GET /auth/me` - Get current user profile

#### **Business Module** (`/business`)
- `GET /business/profile` - Get business profile
- `PUT /business/profile` - Update business profile
- `POST /business/logo` - Upload business logo
- `GET /business/stats` - Dashboard statistics

#### **Category Module** (`/categories`)
- `GET /categories` - List categories (paginated)
- `POST /categories` - Create category
- `GET /categories/{uuid}` - Get category details
- `PUT /categories/{uuid}` - Update category
- `DELETE /categories/{uuid}` - Soft delete category

#### **Product Module** (`/products`)
- `GET /products` - List products (paginated, filtered)
- `POST /products` - Create product (check plan limit)
- `GET /products/{uuid}` - Get product details
- `PUT /products/{uuid}` - Update product
- `DELETE /products/{uuid}` - Soft delete product
- `POST /products/{uuid}/image` - Upload product image
- `PATCH /products/{uuid}/toggle` - Toggle active status

#### **Customer Module** (`/customers`)
- `GET /customers` - List customers (paginated, search)
- `POST /customers` - Create customer
- `GET /customers/{uuid}` - Get customer details
- `PUT /customers/{uuid}` - Update customer
- `DELETE /customers/{uuid}` - Soft delete customer
- `GET /customers/{uuid}/orders` - Get customer order history

#### **Order Module** (`/orders`)
- `GET /orders` - List orders (paginated, filtered)
- `POST /orders` - Create order (check plan limit, update stock)
- `GET /orders/{uuid}` - Get order details
- `PUT /orders/{uuid}` - Update order
- `PATCH /orders/{uuid}/status` - Update order status
- `DELETE /orders/{uuid}` - Cancel order (soft delete)

#### **Reports Module** (`/reports`) - **PAID PLAN ONLY**
- `GET /reports/sales` - Sales report (date range)
- `GET /reports/products` - Product-wise report
- `GET /reports/customers` - Customer-wise report
- `GET /reports/export/pdf` - Export report as PDF
- `GET /reports/export/csv` - Export report as CSV

#### **Admin Module** (`/admin`) - **SUPER_ADMIN ONLY**
- `GET /admin/businesses` - List all businesses
- `GET /admin/businesses/{uuid}` - Get business details
- `PATCH /admin/businesses/{uuid}/status` - Activate/deactivate business
- `PATCH /admin/businesses/{uuid}/plan` - Update business plan
- `GET /admin/users` - List all users
- `PATCH /admin/users/{uuid}/status` - Activate/deactivate user
- `GET /admin/stats` - Platform statistics (revenue, users, businesses)

### Request/Response Patterns

#### Standard Response Format
```json
{
  "success": true,
  "data": { ... },
  "message": "Operation successful",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

#### Error Response Format
```json
{
  "success": false,
  "error": {
    "code": "PRODUCT_LIMIT_EXCEEDED",
    "message": "Free plan allows only 10 products. Upgrade to PAID plan.",
    "details": { "current": 10, "limit": 10 }
  },
  "timestamp": "2024-01-01T12:00:00Z"
}
```

#### Pagination Format
```json
{
  "success": true,
  "data": {
    "items": [...],
    "pagination": {
      "page": 1,
      "page_size": 20,
      "total_items": 150,
      "total_pages": 8
    }
  }
}
```

---

## 4. Backend Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI app entry point
│   ├── config.py               # Environment config
│   ├── database.py             # Database connection
│   ├── dependencies.py         # Dependency injection (get_db, get_current_user)
│   │
│   ├── core/
│   │   ├── __init__.py
│   │   ├── security.py         # JWT, password hashing
│   │   ├── rbac.py             # Role-based access control
│   │   ├── plan_gate.py        # Plan-based feature gating
│   │   └── exceptions.py       # Custom exceptions
│   │
│   ├── models/
│   │   ├── __init__.py
│   │   ├── user.py             # User SQLAlchemy model
│   │   ├── business.py         # Business model
│   │   ├── otp.py              # OTP model
│   │   ├── category.py
│   │   ├── product.py
│   │   ├── customer.py
│   │   ├── order.py
│   │   └── plan_limit.py
│   │
│   ├── schemas/
│   │   ├── __init__.py
│   │   ├── auth.py             # Pydantic schemas for auth
│   │   ├── business.py
│   │   ├── category.py
│   │   ├── product.py
│   │   ├── customer.py
│   │   ├── order.py
│   │   ├── report.py
│   │   └── common.py           # Shared schemas (pagination, etc.)
│   │
│   ├── routers/
│   │   ├── __init__.py
│   │   ├── auth.py             # Auth endpoints
│   │   ├── business.py
│   │   ├── categories.py
│   │   ├── products.py
│   │   ├── customers.py
│   │   ├── orders.py
│   │   ├── reports.py
│   │   └── admin.py
│   │
│   ├── services/
│   │   ├── __init__.py
│   │   ├── auth_service.py     # Business logic for auth
│   │   ├── otp_service.py      # OTP generation/validation
│   │   ├── business_service.py
│   │   ├── product_service.py
│   │   ├── order_service.py
│   │   ├── report_service.py
│   │   ├── plan_service.py     # Plan limit checks
│   │   └── upload_service.py   # File upload handling
│   │
│   ├── utils/
│   │   ├── __init__.py
│   │   ├── pdf_generator.py    # PDF export utility
│   │   ├── csv_generator.py    # CSV export utility
│   │   └── validators.py       # Custom validators (phone, GSTIN)
│   │
│   └── tests/
│       ├── __init__.py
│       ├── conftest.py         # Pytest fixtures
│       ├── test_auth.py
│       ├── test_products.py
│       └── test_orders.py
│
├── alembic/                    # Database migrations
│   ├── versions/
│   └── env.py
│
├── uploads/                    # Local file storage (logos, images)
│   ├── business_logos/
│   └── product_images/
│
├── .env                        # Environment variables
├── .env.example
├── requirements.txt
├── alembic.ini
└── README.md
```

---

## 5. Frontend Project Structure (Flutter)

```
frontend/
├── lib/
│   ├── main.dart               # App entry point
│   ├── app.dart                # MaterialApp configuration
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── api_constants.dart
│   │   │   ├── app_constants.dart
│   │   │   └── routes.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   └── colors.dart
│   │   ├── utils/
│   │   │   ├── validators.dart
│   │   │   ├── formatters.dart
│   │   │   └── storage.dart
│   │   └── errors/
│   │       └── exceptions.dart
│   │
│   ├── data/
│   │   ├── models/
│   │   │   ├── user_model.dart
│   │   │   ├── business_model.dart
│   │   │   ├── product_model.dart
│   │   │   ├── order_model.dart
│   │   │   └── customer_model.dart
│   │   ├── repositories/
│   │   │   ├── auth_repository.dart
│   │   │   ├── business_repository.dart
│   │   │   ├── product_repository.dart
│   │   │   ├── order_repository.dart
│   │   │   └── customer_repository.dart
│   │   └── datasources/
│   │       ├── api_client.dart
│   │       └── local_storage.dart
│   │
│   ├── domain/
│   │   └── entities/
│   │       ├── user.dart
│   │       ├── business.dart
│   │       ├── product.dart
│   │       └── order.dart
│   │
│   ├── presentation/
│   │   ├── providers/
│   │   │   ├── auth_provider.dart
│   │   │   ├── business_provider.dart
│   │   │   ├── product_provider.dart
│   │   │   ├── order_provider.dart
│   │   │   └── customer_provider.dart
│   │   │
│   │   ├── screens/
│   │   │   ├── auth/
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── otp_screen.dart
│   │   │   │   └── register_screen.dart
│   │   │   ├── dashboard/
│   │   │   │   ├── dashboard_screen.dart
│   │   │   │   └── widgets/
│   │   │   ├── business/
│   │   │   │   └── business_profile_screen.dart
│   │   │   ├── products/
│   │   │   │   ├── products_list_screen.dart
│   │   │   │   ├── product_detail_screen.dart
│   │   │   │   └── product_form_screen.dart
│   │   │   ├── orders/
│   │   │   │   ├── orders_list_screen.dart
│   │   │   │   ├── order_detail_screen.dart
│   │   │   │   └── create_order_screen.dart
│   │   │   ├── customers/
│   │   │   │   ├── customers_list_screen.dart
│   │   │   │   └── customer_detail_screen.dart
│   │   │   ├── reports/
│   │   │   │   └── reports_screen.dart
│   │   │   └── admin/
│   │   │       └── admin_dashboard_screen.dart
│   │   │
│   │   └── widgets/
│   │       ├── common/
│   │       │   ├── custom_button.dart
│   │       │   ├── custom_text_field.dart
│   │       │   ├── loading_indicator.dart
│   │       │   └── error_widget.dart
│   │       ├── product_card.dart
│   │       ├── order_card.dart
│   │       └── customer_card.dart
│   │
│   └── routes/
│       └── app_router.dart
│
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
│
├── pubspec.yaml
└── README.md
```

---

## 6. Security Implementation

### 6.1 Authentication Security

#### JWT Configuration
```python
# config.py
SECRET_KEY = os.getenv("SECRET_KEY")  # 256-bit random key
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60
REFRESH_TOKEN_EXPIRE_DAYS = 7
```

#### Password Security
- **Hashing**: bcrypt with cost factor 12
- **Minimum length**: 8 characters
- **Validation**: At least 1 letter, 1 number
- **Storage**: Only hash stored, never plaintext

#### OTP Security
- **Length**: 6 digits
- **Expiry**: 5 minutes
- **Rate limiting**: Max 3 OTPs per phone per hour
- **Invalidation**: After 3 failed attempts
- **Mock mode**: For testing (env variable `OTP_MOCK=true`)

### 6.2 Multi-Tenant Isolation

#### Mandatory Business ID Filter
Every query must filter by `business_id` from JWT token:

```python
# Bad - Security vulnerability
products = db.query(Product).all()

# Good - Multi-tenant safe
products = db.query(Product).filter(
    Product.business_id == current_user.business_id
).all()
```

#### Database-Level Enforcement
Use SQLAlchemy event listeners to auto-inject business_id:

```python
@event.listens_for(Session, 'before_flush')
def before_flush(session, flush_context, instances):
    for obj in session.new:
        if hasattr(obj, 'business_id') and obj.business_id is None:
            obj.business_id = current_business_id
```

### 6.3 Role-Based Access Control

#### Decorator Pattern
```python
from functools import wraps
from fastapi import HTTPException

def require_role(*roles):
    def decorator(func):
        @wraps(func)
        async def wrapper(current_user: User, *args, **kwargs):
            if current_user.role not in roles:
                raise HTTPException(status_code=403, detail="Access forbidden")
            return await func(current_user, *args, **kwargs)
        return wrapper
    return decorator

# Usage
@router.get("/admin/businesses")
@require_role("SUPER_ADMIN")
async def list_businesses(current_user: User):
    ...
```

### 6.4 Plan-Based Feature Gating

```python
# core/plan_gate.py
class PlanGate:
    FREE_LIMITS = {
        'max_products': 10,
        'max_orders': 50,
        'max_customers': 100,
        'reports_enabled': False,
        'export_enabled': False
    }
    
    PAID_LIMITS = {
        'max_products': None,  # Unlimited
        'max_orders': None,
        'max_customers': None,
        'reports_enabled': True,
        'export_enabled': True
    }
    
    @staticmethod
    def check_limit(business: Business, feature: str, current_count: int = None):
        limits = PlanGate.FREE_LIMITS if business.plan == 'FREE' else PlanGate.PAID_LIMITS
        
        if feature.startswith('max_'):
            max_limit = limits.get(feature)
            if max_limit is not None and current_count >= max_limit:
                raise HTTPException(
                    status_code=403,
                    detail=f"Plan limit exceeded. Upgrade to PAID plan."
                )
        else:
            if not limits.get(feature, False):
                raise HTTPException(
                    status_code=403,
                    detail=f"Feature '{feature}' requires PAID plan"
                )
```

### 6.5 Input Validation

#### Phone Number Validation
```python
import re

def validate_indian_phone(phone: str) -> bool:
    pattern = r'^[6-9]\d{9}$'
    return bool(re.match(pattern, phone))
```

#### GSTIN Validation
```python
def validate_gstin(gstin: str) -> bool:
    pattern = r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$'
    return bool(re.match(pattern, gstin.upper()))
```

### 6.6 File Upload Security

```python
ALLOWED_IMAGE_EXTENSIONS = {'jpg', 'jpeg', 'png', 'webp'}
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB

def validate_image(file: UploadFile):
    # Check extension
    ext = file.filename.split('.')[-1].lower()
    if ext not in ALLOWED_IMAGE_EXTENSIONS:
        raise HTTPException(400, "Invalid file type")
    
    # Check file size
    file.file.seek(0, 2)
    size = file.file.tell()
    file.file.seek(0)
    if size > MAX_FILE_SIZE:
        raise HTTPException(400, "File too large")
    
    # Verify image content
    try:
        image = Image.open(file.file)
        image.verify()
        file.file.seek(0)
    except:
        raise HTTPException(400, "Invalid image file")
```

### 6.7 Rate Limiting

```python
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

# Apply to sensitive endpoints
@router.post("/auth/otp/send")
@limiter.limit("3/hour")
async def send_otp(request: Request, ...):
    ...
```

---

## 7. Performance Optimization

### 7.1 Database Optimization

#### Indexing Strategy
- **Foreign Keys**: All FK columns indexed
- **Search Fields**: phone, email, sku, order_number
- **Filter Fields**: business_id, status, is_active, plan
- **Composite Indexes**: (business_id, created_at) for time-series queries

#### Query Optimization
```python
# Use select_in loading for relationships
products = db.query(Product).options(
    selectinload(Product.category)
).filter(Product.business_id == business_id).all()

# Pagination with indexed fields
products = db.query(Product).filter(
    Product.business_id == business_id
).order_by(Product.id.desc()).limit(20).offset(0).all()
```

#### Connection Pooling
```python
# database.py
engine = create_engine(
    DATABASE_URL,
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,  # Verify connections
    pool_recycle=3600    # Recycle after 1 hour
)
```

### 7.2 Caching Strategy

#### Redis for Session & OTP
```python
import redis

redis_client = redis.Redis(host='localhost', port=6379, db=0)

# Cache OTP
redis_client.setex(f"otp:{phone}", 300, otp_code)  # 5 min expiry

# Cache business profile
redis_client.setex(f"business:{business_id}", 3600, json.dumps(business_data))
```

#### Response Caching
```python
from fastapi_cache import FastAPICache
from fastapi_cache.backends.redis import RedisBackend

@router.get("/business/profile")
@cache(expire=300)  # 5 minutes
async def get_business_profile(...):
    ...
```

### 7.3 Lazy Loading & Pagination

- **Default page size**: 20 items
- **Max page size**: 100 items
- **Offset-based pagination** for simplicity
- **Count queries cached** for large datasets

### 7.4 Image Optimization

```python
from PIL import Image

def optimize_image(file_path: str, max_size=(800, 800)):
    img = Image.open(file_path)
    img.thumbnail(max_size, Image.LANCZOS)
    img.save(file_path, optimize=True, quality=85)
```

---

## 8. Plan-Based Features & Limits

### FREE Plan
| Feature | Limit |
|---------|-------|
| Products | 10 |
| Orders | 50 |
| Customers | 100 |
| Categories | Unlimited |
| Dashboard | Basic |
| Reports | ❌ Not available |
| PDF Export | ❌ Not available |
| CSV Export | ❌ Not available |
| Support | Email only |

### PAID Plan (₹3999/year)
| Feature | Limit |
|---------|-------|
| Products | Unlimited |
| Orders | Unlimited |
| Customers | Unlimited |
| Categories | Unlimited |
| Dashboard | Advanced |
| Reports | ✅ Full access |
| PDF Export | ✅ Unlimited |
| CSV Export | ✅ Unlimited |
| Support | Priority (WhatsApp) |

---

## 9. Indian Market Compliance

### GST Support
- Optional GSTIN field (15 chars)
- Tax amount tracking in orders
- GST reports (product-wise, summary)

### Indian Phone Numbers
- Format: 10 digits starting with 6-9
- WhatsApp integration ready

### Currency
- ₹ INR symbol
- Decimal precision: 2 places
- Format: ₹1,234.56

### Timezone
- **Storage**: UTC
- **Display**: IST (UTC+5:30)

### Payment Integration (Future)
- Razorpay / Paytm / PhonePe
- UPI support

---

## 10. Comparison: Dukaan vs StoreLink

| Feature | Dukaan | StoreLink |
|---------|--------|-----------|
| **Pricing** | ₹7999+/year | ₹3999/year |
| **Backend Ownership** | ❌ Platform-owned | ✅ Self-hosted |
| **Customization** | Limited | Full control |
| **CRM** | Basic | Advanced (customer history, notes) |
| **Order Management** | E-commerce only | Full business ops |
| **Reports** | Limited | Detailed (sales, product, customer) |
| **Export** | Basic | PDF + CSV |
| **Admin Control** | ❌ No | ✅ SUPER_ADMIN role |
| **Data Lock-in** | ✅ Yes | ❌ No (export anytime) |
| **Multi-channel** | Web only | Web + Mobile PWA |
| **GST Support** | Basic | Advanced |
| **Stock Management** | Basic | Advanced (SKU, units) |

---

## 11. Risks & Mitigations

### Risk 1: Multi-Tenant Data Leakage
**Impact**: Critical - Data breach, legal liability

**Mitigation**:
- Mandatory business_id filter in all queries
- SQLAlchemy event listeners for auto-injection
- Unit tests for every endpoint verifying isolation
- Code review checklist item

### Risk 2: Plan Limit Bypass
**Impact**: High - Revenue loss, unfair usage

**Mitigation**:
- Server-side validation (never client-side)
- Atomic checks before create operations
- Database constraints (partial unique indexes)
- Regular audit queries

### Risk 3: JWT Token Theft
**Impact**: High - Unauthorized access

**Mitigation**:
- Short token expiry (60 min)
- Refresh token rotation
- HTTPS only
- Secure storage (httpOnly cookies or secure local storage)
- Token blacklist on logout

### Risk 4: OTP Abuse
**Impact**: Medium - SMS cost, spam

**Mitigation**:
- Rate limiting (3 OTPs/hour per phone)
- CAPTCHA on frontend
- SMS provider rate limits
- Monitoring & alerts

### Risk 5: File Upload Attacks
**Impact**: Medium - Storage abuse, XSS

**Mitigation**:
- File type validation (whitelist)
- Size limits (5MB)
- Image content verification
- Separate storage domain (CDN)
- Sanitize filenames

### Risk 6: Performance Degradation
**Impact**: Medium - Poor UX, customer churn

**Mitigation**:
- Database indexing
- Query optimization
- Connection pooling
- Redis caching
- Pagination
- Load testing (Locust, k6)

### Risk 7: Payment Integration Failures
**Impact**: Critical - Revenue loss, trust issues

**Mitigation**:
- Webhook verification
- Idempotency keys
- Transaction logging
- Retry mechanism
- Manual reconciliation dashboard

---

## 12. Production Deployment Recommendations

### 12.1 Infrastructure

#### Option 1: Single VPS (Low Budget)
- **Provider**: DigitalOcean, Linode, Vultr
- **Specs**: 2 vCPU, 4GB RAM, 80GB SSD
- **Cost**: ~₹800-1200/month
- **Stack**: 
  - Nginx (reverse proxy)
  - Uvicorn (FastAPI)
  - MySQL 8.0
  - Redis
  - Certbot (SSL)

#### Option 2: Managed Services (Medium Budget)
- **Backend**: AWS Lightsail / DigitalOcean App Platform
- **Database**: AWS RDS MySQL / DigitalOcean Managed Database
- **Cache**: Redis Cloud / AWS ElastiCache
- **Storage**: AWS S3 / Wasabi
- **Cost**: ~₹2000-3000/month

### 12.2 Environment Variables
```env
# Database
DATABASE_URL=mysql+pymysql://user:pass@localhost:3306/storelink

# JWT
SECRET_KEY=<256-bit-random-key>
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

# OTP (Mock for testing)
OTP_MOCK=false
OTP_EXPIRY_MINUTES=5

# Redis
REDIS_URL=redis://localhost:6379/0

# File Upload
UPLOAD_DIR=./uploads
MAX_FILE_SIZE=5242880

# CORS
CORS_ORIGINS=https://app.storelink.in,https://storelink.in

# Environment
ENVIRONMENT=production
```

### 12.3 SSL/TLS
- **Free**: Let's Encrypt (Certbot)
- **Auto-renewal**: Certbot cron job
- **Nginx config**: Force HTTPS, HSTS headers

### 12.4 Monitoring & Logging

#### Application Logs
```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('app.log'),
        logging.StreamHandler()
    ]
)
```

#### Error Tracking
- **Sentry**: Automatic error reporting
- **Cost**: Free tier (5000 events/month)

#### Uptime Monitoring
- **UptimeRobot**: Free tier (50 monitors)
- **Pingdom**: Alternative

#### Analytics
- **Mixpanel / PostHog**: User analytics
- **Plausible**: Privacy-friendly web analytics

### 12.5 Backup Strategy

#### Database Backups
```bash
# Daily backup cron job
0 2 * * * mysqldump -u root -p storelink > /backups/storelink_$(date +\%Y\%m\%d).sql
```

- **Retention**: 7 daily, 4 weekly, 3 monthly
- **Storage**: S3 / Backblaze B2
- **Encryption**: GPG encryption before upload

#### File Backups
- **Strategy**: Sync uploads/ to cloud storage daily
- **Tool**: rclone, aws s3 sync

### 12.6 CI/CD Pipeline

```yaml
# .github/workflows/deploy.yml
name: Deploy Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run tests
        run: pytest
      
      - name: Deploy to server
        run: |
          ssh user@server 'cd /app && git pull && systemctl restart storelink'
```

### 12.7 Security Hardening

#### Server
- Firewall (ufw): Allow 80, 443, 22 only
- SSH: Key-based auth, disable root login
- Fail2ban: Block brute force attacks
- Auto-updates: unattended-upgrades

#### Application
- Helmet (security headers)
- CORS configuration
- Rate limiting
- Input sanitization
- SQL injection prevention (ORM)

---

## 13. Testing Strategy

### 13.1 Backend Tests

#### Unit Tests (pytest)
```python
# tests/test_auth.py
def test_create_user(db_session):
    user = create_user(db_session, phone="9876543210", password="test123")
    assert user.phone == "9876543210"
    assert user.role == "BUSINESS_OWNER"

def test_business_isolation(db_session, user1, user2):
    # Ensure user1 cannot see user2's products
    ...
```

#### Integration Tests
```python
def test_create_order_flow(client, auth_headers):
    # Test full order creation with stock update
    response = client.post(
        "/orders",
        json=order_data,
        headers=auth_headers
    )
    assert response.status_code == 201
    # Verify stock decreased
```

#### Coverage Target
- **Minimum**: 80%
- **Critical paths**: 100% (auth, payment, multi-tenant)

### 13.2 Frontend Tests

#### Widget Tests
```dart
testWidgets('Login screen should show phone field', (tester) async {
  await tester.pumpWidget(MyApp());
  expect(find.byType(TextField), findsOneWidget);
});
```

#### Integration Tests
```dart
testWidgets('Complete order creation flow', (tester) async {
  // Navigate through create order flow
  // Verify API calls
});
```

---

## 14. Implementation Phases

Given the complexity, this project should be broken into phases:

### Phase 1: Core Foundation (Week 1-2)
- Database setup & migrations
- User authentication (JWT, OTP)
- Role-based routing
- Business profile management
- Multi-tenant middleware

### Phase 2: Product Management (Week 3)
- Category CRUD
- Product CRUD
- Image upload
- Plan limit enforcement

### Phase 3: Customer & Order Management (Week 4)
- Customer CRUD
- Order creation & management
- Stock management
- Order status workflow

### Phase 4: Reports & Export (Week 5)
- Sales reports
- Product reports
- Customer reports
- PDF & CSV export
- Plan gate enforcement

### Phase 5: Admin Panel (Week 6)
- Business listing
- User management
- Plan management
- Platform statistics

### Phase 6: Frontend (Week 7-9)
- Flutter app structure
- All screens implementation
- State management
- API integration
- Responsive design

### Phase 7: Testing & Production (Week 10)
- Comprehensive testing
- Performance optimization
- Security audit
- Production deployment
- Monitoring setup

---

## 15. Success Metrics

### Technical KPIs
- **API Response Time**: < 200ms (p95)
- **Database Query Time**: < 50ms (p95)
- **Uptime**: > 99.5%
- **Error Rate**: < 0.1%
- **Test Coverage**: > 80%

### Business KPIs
- **User Registration**: Track daily signups
- **Conversion Rate**: FREE → PAID
- **Churn Rate**: < 5% monthly
- **Customer Satisfaction**: > 4.5/5
- **Support Tickets**: < 10% of active users

---

## 16. Verification Steps

### Backend Verification
1. Run database migrations: `alembic upgrade head`
2. Run tests: `pytest --cov=app tests/`
3. Check linting: `flake8 app/` or `ruff check app/`
4. Manual API testing: Postman/Insomnia collection
5. Load testing: `locust -f locustfile.py`

### Frontend Verification
1. Run tests: `flutter test`
2. Check formatting: `flutter format --set-exit-if-changed .`
3. Analyze code: `flutter analyze`
4. Build web: `flutter build web`
5. Build APK: `flutter build apk`

### Integration Verification
1. Test complete user journey (register → create product → create order)
2. Verify multi-tenant isolation
3. Test plan limits
4. Test role-based access
5. Security audit (OWASP top 10 checks)

---

## 17. Open Questions

Before implementation, clarify:

1. **OTP Provider**: Which SMS provider? (Twilio, MSG91, Fast2SMS)
2. **Payment Gateway**: Razorpay, Paytm, or manual for MVP?
3. **File Storage**: Local filesystem or S3-compatible storage?
4. **Domain**: Is storelink.in available? Subdomain structure?
5. **Support System**: Email only or ticketing system?
6. **Analytics**: Which tool? (Google Analytics, Mixpanel, self-hosted)
7. **Mobile App**: PWA sufficient or native app needed?

---

## Conclusion

This specification provides a complete, production-ready blueprint for StoreLink. The architecture prioritizes:

1. **Security**: Multi-tenant isolation, RBAC, JWT, input validation
2. **Scalability**: Indexed queries, caching, connection pooling
3. **Maintainability**: Clean architecture, separation of concerns
4. **Cost-efficiency**: Optimized for low-cost hosting
5. **Market fit**: Dukaan alternative with better pricing and features

**Estimated Development Time**: 10-12 weeks with 1 full-stack developer
**Estimated Infrastructure Cost**: ₹1000-3000/month
**Break-even Point**: ~100 paid customers (₹3999 × 100 = ₹3,99,900/year)
