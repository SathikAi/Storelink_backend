import pytest
import io
from fastapi.testclient import TestClient
from app.main import app
from app.models.user import User, UserRole
from app.models.business import Business, BusinessPlan
from app.models.product import Product
from app.models.order import Order
from app.models.customer import Customer
from app.core.security import hash_password, create_access_token

client = TestClient(app)


@pytest.fixture
def test_business_owner(db_session):
    user = User(
        phone="9876543210",
        password_hash=hash_password("TestPassword123"),
        full_name="Test Business Owner",
        email="owner@example.com",
        role=UserRole.BUSINESS_OWNER,
        is_active=True,
        is_verified=True
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    
    business = Business(
        owner_id=user.id,
        business_name="Test Business",
        phone="9876543210",
        email="business@example.com",
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
def auth_headers(test_business_owner):
    return {"Authorization": f"Bearer {test_business_owner['token']}"}


def test_get_business_profile(test_business_owner, auth_headers):
    response = client.get("/v1/business/profile", headers=auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Business profile retrieved successfully"
    assert data["data"]["business_name"] == "Test Business"
    assert data["data"]["phone"] == "9876543210"
    assert data["data"]["plan"] == "FREE"
    assert data["data"]["is_active"] is True


def test_get_business_profile_unauthorized():
    response = client.get("/v1/business/profile")
    assert response.status_code == 403


def test_update_business_profile(test_business_owner, auth_headers):
    update_data = {
        "business_name": "Updated Business Name",
        "city": "Mumbai",
        "state": "Maharashtra",
        "pincode": "400001",
        "address": "Test Address, Mumbai"
    }
    
    response = client.put("/v1/business/profile", json=update_data, headers=auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Business profile updated successfully"
    assert data["data"]["business_name"] == "Updated Business Name"
    assert data["data"]["city"] == "Mumbai"
    assert data["data"]["state"] == "Maharashtra"
    assert data["data"]["pincode"] == "400001"


def test_update_business_profile_with_invalid_phone(test_business_owner, auth_headers):
    update_data = {
        "phone": "123"
    }
    
    response = client.put("/v1/business/profile", json=update_data, headers=auth_headers)
    assert response.status_code == 422


def test_update_business_profile_with_invalid_email(test_business_owner, auth_headers):
    update_data = {
        "email": "invalid-email"
    }
    
    response = client.put("/v1/business/profile", json=update_data, headers=auth_headers)
    assert response.status_code == 422


def test_update_business_profile_with_invalid_gstin(test_business_owner, auth_headers):
    update_data = {
        "gstin": "INVALID123"
    }
    
    response = client.put("/v1/business/profile", json=update_data, headers=auth_headers)
    assert response.status_code == 422


def test_update_business_profile_with_valid_gstin(test_business_owner, auth_headers):
    update_data = {
        "gstin": "27AAPFU0939F1ZV"
    }
    
    response = client.put("/v1/business/profile", json=update_data, headers=auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["data"]["gstin"] == "27AAPFU0939F1ZV"


def test_upload_business_logo(test_business_owner, auth_headers):
    from PIL import Image
    
    img = Image.new('RGB', (100, 100), color='red')
    img_bytes = io.BytesIO()
    img.save(img_bytes, format='PNG')
    img_bytes.seek(0)
    
    files = {"file": ("test_logo.png", img_bytes, "image/png")}
    response = client.post("/v1/business/logo", files=files, headers=auth_headers)
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Logo uploaded successfully"
    assert "logo_url" in data
    assert "/uploads/logos/" in data["logo_url"]


def test_upload_business_logo_invalid_file_type(test_business_owner, auth_headers):
    files = {"file": ("test.txt", io.BytesIO(b"test content"), "text/plain")}
    response = client.post("/v1/business/logo", files=files, headers=auth_headers)
    
    assert response.status_code == 400


def test_get_business_stats_empty(test_business_owner, auth_headers):
    response = client.get("/v1/business/stats", headers=auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    assert data["data"]["total_products"] == 0
    assert data["data"]["active_products"] == 0
    assert data["data"]["total_orders"] == 0
    assert data["data"]["total_customers"] == 0
    assert data["data"]["total_revenue"] == 0.0
    assert data["data"]["plan"] == "FREE"
    assert "plan_limits" in data["data"]


def test_get_business_stats_with_data(test_business_owner, auth_headers, db_session):
    product1 = Product(
        business_id=test_business_owner["business"].id,
        name="Product 1",
        price=100.00,
        is_active=True
    )
    product2 = Product(
        business_id=test_business_owner["business"].id,
        name="Product 2",
        price=200.00,
        is_active=False
    )
    db_session.add(product1)
    db_session.add(product2)
    
    customer = Customer(
        business_id=test_business_owner["business"].id,
        name="Test Customer",
        phone="9876543211"
    )
    db_session.add(customer)
    db_session.commit()
    db_session.refresh(customer)
    
    order = Order(
        business_id=test_business_owner["business"].id,
        customer_id=customer.id,
        order_number="ORD001",
        subtotal=500.00,
        total_amount=500.00,
        payment_status="PAID"
    )
    db_session.add(order)
    db_session.commit()
    
    response = client.get("/v1/business/stats", headers=auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["data"]["total_products"] == 2
    assert data["data"]["active_products"] == 1
    assert data["data"]["total_orders"] == 1
    assert data["data"]["total_customers"] == 1
    assert data["data"]["total_revenue"] == 500.00
