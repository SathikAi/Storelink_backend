# Testing Notes

## SQLite Compatibility Issue

The test suite currently has compatibility issues with SQLite due to the use of `BigInteger` columns with autoincrement in SQLAlchemy 2.0. SQLite handles `BIGINT` differently than MySQL and doesn't properly support autoincrement with this type when combined with the RETURNING clause.

### Issue Details
- **Error**: `sqlite3.IntegrityError: NOT NULL constraint failed: users.id`
- **Cause**: SQLite doesn't treat `BIGINT` the same as `INTEGER PRIMARY KEY AUTOINCREMENT`
- **Affected**: All models using `BigInteger` for primary keys (User, Business, Product, Order, etc.)

### Solutions

1. **Recommended: Use MySQL for Testing**
   ```bash
   # Use MySQL/MariaDB for tests (production database)
   docker run --name mysql-test -e MYSQL_ROOT_PASSWORD=test -e MYSQL_DATABASE=storelink_test -p 3307:3306 -d mysql:8.0
   
   # Update test DATABASE_URL to use MySQL
   export TEST_DATABASE_URL="mysql+pymysql://root:test@localhost:3307/storelink_test"
   ```

2. **Alternative: Manual Testing**
   - Use Postman/Insomnia for API endpoint testing
   - Use FastAPI's built-in `/docs` Swagger UI
   - Integration testing with actual MySQL database

### Current Test Status
- ✅ Business schemas created and validated
- ✅ Business service implemented with proper error handling
- ✅ File upload service with image validation  
- ✅ Plan limit service for FREE/PAID gating
- ✅ Business router with all endpoints
- ✅ Category schemas, service, and router implemented
- ✅ Product schemas, service, and router implemented
- ✅ Product plan limit checks and stock management
- ✅ Customer schemas, service, and router implemented
- ✅ Customer phone validation (Indian format)
- ✅ Customer search and filter functionality
- ✅ Customer order history endpoint
- ⚠️ Unit tests written but require MySQL to run properly

### Manual Testing Checklist

#### Business Profile Endpoints
- [ ] GET `/v1/business/profile` - Get business profile
- [ ] PUT `/v1/business/profile` - Update business profile
- [ ] POST `/v1/business/logo` - Upload business logo  
- [ ] GET `/v1/business/stats` - Get business statistics

#### Category Endpoints
- [ ] POST `/v1/categories` - Create category
- [ ] GET `/v1/categories` - List categories (with pagination)
- [ ] GET `/v1/categories/{uuid}` - Get category by UUID
- [ ] PUT `/v1/categories/{uuid}` - Update category
- [ ] DELETE `/v1/categories/{uuid}` - Delete category

#### Product Endpoints
- [ ] POST `/v1/products` - Create product (check plan limits)
- [ ] GET `/v1/products` - List products (with filters & search)
- [ ] GET `/v1/products/{uuid}` - Get product by UUID
- [ ] PUT `/v1/products/{uuid}` - Update product
- [ ] DELETE `/v1/products/{uuid}` - Delete product
- [ ] POST `/v1/products/{uuid}/image` - Upload product image
- [ ] PATCH `/v1/products/{uuid}/toggle` - Toggle product status

#### Customer Endpoints (CRM)
- [ ] POST `/v1/customers` - Create customer
- [ ] GET `/v1/customers` - List customers (with search & pagination)
- [ ] GET `/v1/customers/{uuid}` - Get customer by UUID
- [ ] PUT `/v1/customers/{uuid}` - Update customer
- [ ] DELETE `/v1/customers/{uuid}` - Delete customer
- [ ] GET `/v1/customers/{uuid}/orders` - Get customer order history

#### Validation Testing
- [ ] Phone number validation (Indian format - customers & users)
- [ ] Phone normalization (+91 / 91 prefix removal)
- [ ] Email validation
- [ ] GSTIN validation (Indian tax number format)
- [ ] Pincode validation (6 digits)
- [ ] Image file type validation
- [ ] Image size validation (max 5MB)
- [ ] Product price validation (must be positive)
- [ ] Stock quantity validation (non-negative)
- [ ] SKU uniqueness check
- [ ] Customer phone uniqueness per business

#### Authorization Testing
- [ ] Unauthorized access (no token)
- [ ] Invalid token
- [ ] Cross-tenant access (business isolation)

#### Plan Limit Testing
- [ ] Free plan product limit (10 products max)
- [ ] Product limit error message
- [ ] Paid plan unlimited products

## Running Tests with MySQL

```bash
# Set up test database
mysql -u root -p -e "CREATE DATABASE storelink_test;"

# Update .env.test or export
export DATABASE_URL="mysql+pymysql://root:password@localhost:3306/storelink_test"

# Run tests
pytest app/tests/test_business.py -v
```

## Future Improvements
- Configure separate test models using `Integer` for SQLite compatibility
- Add test database factory pattern  
- Implement test fixtures with proper transaction rollback
- Add integration tests with Docker Compose (MySQL + API)
