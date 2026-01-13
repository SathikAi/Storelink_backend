import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.models.user import User, UserRole
from app.models.business import Business, BusinessPlan
from app.models.customer import Customer
from app.models.order import Order, OrderStatus, PaymentStatus
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


@pytest.fixture
def test_customer(db_session, test_business_owner):
    customer = Customer(
        business_id=test_business_owner["business"].id,
        name="John Doe",
        phone="9876543211",
        email="john@example.com",
        address="123 Main St",
        city="Mumbai",
        state="Maharashtra",
        pincode="400001",
        is_active=True
    )
    db_session.add(customer)
    db_session.commit()
    db_session.refresh(customer)
    return customer


def test_create_customer(test_business_owner, auth_headers):
    customer_data = {
        "name": "Jane Smith",
        "phone": "9123456789",
        "email": "jane@example.com",
        "address": "456 Park Ave",
        "city": "Delhi",
        "state": "Delhi",
        "pincode": "110001",
        "notes": "VIP customer",
        "is_active": True
    }
    
    response = client.post("/v1/customers", json=customer_data, headers=auth_headers)
    assert response.status_code == 201
    
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Customer created successfully"
    assert data["data"]["name"] == "Jane Smith"
    assert data["data"]["phone"] == "9123456789"
    assert data["data"]["email"] == "jane@example.com"
    assert data["data"]["city"] == "Delhi"
    assert data["data"]["pincode"] == "110001"
    assert "uuid" in data["data"]


def test_create_customer_phone_normalization(test_business_owner, auth_headers):
    customer_data = {
        "name": "Test Customer",
        "phone": "+919876543222"
    }
    
    response = client.post("/v1/customers", json=customer_data, headers=auth_headers)
    assert response.status_code == 201
    
    data = response.json()
    assert data["data"]["phone"] == "9876543222"


def test_create_customer_phone_normalization_with_country_code(test_business_owner, auth_headers):
    customer_data = {
        "name": "Test Customer 2",
        "phone": "919876543223"
    }
    
    response = client.post("/v1/customers", json=customer_data, headers=auth_headers)
    assert response.status_code == 201
    
    data = response.json()
    assert data["data"]["phone"] == "9876543223"


def test_create_customer_invalid_phone(test_business_owner, auth_headers):
    customer_data = {
        "name": "Invalid Phone",
        "phone": "1234567890"
    }
    
    response = client.post("/v1/customers", json=customer_data, headers=auth_headers)
    assert response.status_code == 422


def test_create_customer_duplicate_phone(test_business_owner, auth_headers, test_customer):
    customer_data = {
        "name": "Duplicate Phone",
        "phone": "9876543211"
    }
    
    response = client.post("/v1/customers", json=customer_data, headers=auth_headers)
    assert response.status_code == 400
    
    data = response.json()
    assert "already exists" in data["detail"]


def test_create_customer_invalid_email(test_business_owner, auth_headers):
    customer_data = {
        "name": "Invalid Email",
        "phone": "9876543224",
        "email": "not-an-email"
    }
    
    response = client.post("/v1/customers", json=customer_data, headers=auth_headers)
    assert response.status_code == 422


def test_create_customer_invalid_pincode(test_business_owner, auth_headers):
    customer_data = {
        "name": "Invalid Pincode",
        "phone": "9876543225",
        "pincode": "12345"
    }
    
    response = client.post("/v1/customers", json=customer_data, headers=auth_headers)
    assert response.status_code == 422


def test_create_customer_unauthorized():
    customer_data = {
        "name": "Test Customer",
        "phone": "9876543210"
    }
    
    response = client.post("/v1/customers", json=customer_data)
    assert response.status_code == 403


def test_get_customers(test_business_owner, auth_headers, test_customer):
    response = client.get("/v1/customers", headers=auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Customers retrieved successfully"
    assert data["total"] >= 1
    assert len(data["data"]) >= 1
    assert data["data"][0]["name"] == "John Doe"


def test_get_customers_with_pagination(test_business_owner, auth_headers, db_session):
    for i in range(5):
        customer = Customer(
            business_id=test_business_owner["business"].id,
            name=f"Customer {i}",
            phone=f"987654{i:04d}",
            is_active=True
        )
        db_session.add(customer)
    db_session.commit()
    
    response = client.get("/v1/customers?page=1&page_size=3", headers=auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["total"] >= 5
    assert len(data["data"]) == 3
    assert data["page"] == 1
    assert data["page_size"] == 3


def test_get_customers_search_by_name(test_business_owner, auth_headers, db_session):
    customer1 = Customer(
        business_id=test_business_owner["business"].id,
        name="Alice Johnson",
        phone="9876543230",
        is_active=True
    )
    customer2 = Customer(
        business_id=test_business_owner["business"].id,
        name="Bob Smith",
        phone="9876543231",
        is_active=True
    )
    db_session.add(customer1)
    db_session.add(customer2)
    db_session.commit()
    
    response = client.get("/v1/customers?search=Alice", headers=auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert len(data["data"]) >= 1
    assert any("Alice" in customer["name"] for customer in data["data"])


def test_get_customers_search_by_phone(test_business_owner, auth_headers, test_customer):
    response = client.get("/v1/customers?search=987654321", headers=auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert len(data["data"]) >= 1


def test_get_customers_filter_by_active(test_business_owner, auth_headers, db_session):
    active_customer = Customer(
        business_id=test_business_owner["business"].id,
        name="Active Customer",
        phone="9876543232",
        is_active=True
    )
    inactive_customer = Customer(
        business_id=test_business_owner["business"].id,
        name="Inactive Customer",
        phone="9876543233",
        is_active=False
    )
    db_session.add(active_customer)
    db_session.add(inactive_customer)
    db_session.commit()
    
    response = client.get("/v1/customers?is_active=true", headers=auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    for customer in data["data"]:
        assert customer["is_active"] is True


def test_get_customer_by_uuid(test_business_owner, auth_headers, test_customer):
    response = client.get(f"/v1/customers/{test_customer.uuid}", headers=auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Customer retrieved successfully"
    assert data["data"]["uuid"] == test_customer.uuid
    assert data["data"]["name"] == "John Doe"
    assert data["data"]["phone"] == "9876543211"


def test_get_customer_by_uuid_not_found(test_business_owner, auth_headers):
    response = client.get("/v1/customers/non-existent-uuid", headers=auth_headers)
    assert response.status_code == 404


def test_update_customer(test_business_owner, auth_headers, test_customer):
    update_data = {
        "name": "John Updated",
        "email": "john.updated@example.com",
        "city": "Pune"
    }
    
    response = client.put(
        f"/v1/customers/{test_customer.uuid}",
        json=update_data,
        headers=auth_headers
    )
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Customer updated successfully"
    assert data["data"]["name"] == "John Updated"
    assert data["data"]["email"] == "john.updated@example.com"
    assert data["data"]["city"] == "Pune"


def test_update_customer_phone(test_business_owner, auth_headers, test_customer):
    update_data = {
        "phone": "9123456780"
    }
    
    response = client.put(
        f"/v1/customers/{test_customer.uuid}",
        json=update_data,
        headers=auth_headers
    )
    assert response.status_code == 200
    
    data = response.json()
    assert data["data"]["phone"] == "9123456780"


def test_update_customer_duplicate_phone(test_business_owner, auth_headers, db_session):
    customer1 = Customer(
        business_id=test_business_owner["business"].id,
        name="Customer 1",
        phone="9876543240",
        is_active=True
    )
    customer2 = Customer(
        business_id=test_business_owner["business"].id,
        name="Customer 2",
        phone="9876543241",
        is_active=True
    )
    db_session.add(customer1)
    db_session.add(customer2)
    db_session.commit()
    db_session.refresh(customer1)
    db_session.refresh(customer2)
    
    update_data = {"phone": "9876543240"}
    response = client.put(f"/v1/customers/{customer2.uuid}", json=update_data, headers=auth_headers)
    assert response.status_code == 400


def test_delete_customer(test_business_owner, auth_headers, test_customer):
    response = client.delete(f"/v1/customers/{test_customer.uuid}", headers=auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Customer deleted successfully"
    
    get_response = client.get(f"/v1/customers/{test_customer.uuid}", headers=auth_headers)
    assert get_response.status_code == 404


def test_delete_customer_not_found(test_business_owner, auth_headers):
    response = client.delete("/v1/customers/non-existent-uuid", headers=auth_headers)
    assert response.status_code == 404


def test_get_customer_order_history(test_business_owner, auth_headers, test_customer, db_session):
    order1 = Order(
        order_number="ORD-001",
        business_id=test_business_owner["business"].id,
        customer_id=test_customer.id,
        status=OrderStatus.DELIVERED,
        payment_status=PaymentStatus.PAID,
        subtotal=1000.00,
        total_amount=1000.00
    )
    order2 = Order(
        order_number="ORD-002",
        business_id=test_business_owner["business"].id,
        customer_id=test_customer.id,
        status=OrderStatus.PENDING,
        payment_status=PaymentStatus.PENDING,
        subtotal=500.00,
        total_amount=500.00
    )
    db_session.add(order1)
    db_session.add(order2)
    db_session.commit()
    
    response = client.get(f"/v1/customers/{test_customer.uuid}/orders", headers=auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Customer order history retrieved successfully"
    assert data["customer_uuid"] == test_customer.uuid
    assert data["customer_name"] == "John Doe"
    assert data["total_orders"] == 2
    assert len(data["data"]) == 2


def test_get_customer_order_history_empty(test_business_owner, auth_headers, test_customer):
    response = client.get(f"/v1/customers/{test_customer.uuid}/orders", headers=auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["total_orders"] == 0
    assert len(data["data"]) == 0
