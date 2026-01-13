# Testing Instructions

## Component Tests

All authentication components have been verified and are working correctly:
- ✓ JWT token generation and validation  
- ✓ Password hashing and verification
- ✓ Auth service (OTP, login, register)
- ✓ Auth endpoints
- ✓ Multi-tenant middleware
- ✓ RBAC decorators

## Integration Tests

The test suite in `app/tests/test_auth.py` is designed for MySQL database compatibility.

### Running Tests with MySQL

1. Ensure MySQL is running and accessible
2. Update `.env` with test database credentials
3. Run: `pytest app/tests/test_auth.py -v`

### SQLite Limitations

SQLite has compatibility issues with:
- `BigInteger` with `autoincrement=True`
- `RETURNING` clause in INSERT statements
- These are production models designed for MySQL

### Production Testing

For production environment:
1. Deploy to staging environment with MySQL
2. Run full integration test suite
3. Perform manual API testing with tools like Postman or HTTPie

## Manual API Testing

You can test the API endpoints manually:

```bash
# Start the server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Test endpoints
curl -X POST http://localhost:8000/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{...}'
```
