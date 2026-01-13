import pytest
from fastapi.testclient import TestClient
from datetime import date, timedelta
from app.main import app
from app.models.user import User, UserRole
from app.models.business import Business, BusinessPlan
from app.models.product import Product
from app.models.order import Order
from app.models.customer import Customer
from app.core.security import hash_password, create_access_token

client = TestClient(app)


@pytest.fixture
def test_super_admin(db_session):
    user = User(
        phone="9999999999",
        password_hash=hash_password("AdminPassword123"),
        full_name="Super Admin",
        email="admin@storelink.in",
        role=UserRole.SUPER_ADMIN,
        is_active=True,
        is_verified=True
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    
    token_data = {
        "sub": user.uuid,
        "user_id": user.id,
        "role": user.role.value
    }
    access_token = create_access_token(token_data)
    
    return {"user": user, "token": access_token}


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
def multiple_businesses(db_session):
    businesses_data = []
    
    for i in range(5):
        user = User(
            phone=f"987654321{i}",
            password_hash=hash_password("Password123"),
            full_name=f"Business Owner {i}",
            email=f"owner{i}@example.com",
            role=UserRole.BUSINESS_OWNER,
            is_active=True,
            is_verified=True
        )
        db_session.add(user)
        db_session.commit()
        db_session.refresh(user)
        
        business = Business(
            owner_id=user.id,
            business_name=f"Business {i}",
            phone=f"987654321{i}",
            email=f"business{i}@example.com",
            plan=BusinessPlan.FREE if i % 2 == 0 else BusinessPlan.PAID,
            plan_expiry_date=date.today() + timedelta(days=365) if i % 2 != 0 else None,
            is_active=True if i % 3 != 0 else False
        )
        db_session.add(business)
        db_session.commit()
        db_session.refresh(business)
        
        businesses_data.append({"user": user, "business": business})
    
    return businesses_data


@pytest.fixture
def admin_headers(test_super_admin):
    return {"Authorization": f"Bearer {test_super_admin['token']}"}


@pytest.fixture
def business_owner_headers(test_business_owner):
    return {"Authorization": f"Bearer {test_business_owner['token']}"}


def test_list_all_businesses_as_super_admin(test_super_admin, multiple_businesses, admin_headers):
    response = client.get("/v1/admin/businesses", headers=admin_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    assert "items" in data["data"]
    assert "pagination" in data["data"]
    assert len(data["data"]["items"]) == 5
    assert data["data"]["pagination"]["total_items"] == 5


def test_list_all_businesses_unauthorized(test_business_owner, business_owner_headers):
    response = client.get("/v1/admin/businesses", headers=business_owner_headers)
    assert response.status_code == 403
    assert "SUPER_ADMIN role required" in response.json()["detail"]


def test_list_all_businesses_with_pagination(test_super_admin, multiple_businesses, admin_headers):
    response = client.get("/v1/admin/businesses?page=1&page_size=2", headers=admin_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert len(data["data"]["items"]) == 2
    assert data["data"]["pagination"]["page"] == 1
    assert data["data"]["pagination"]["page_size"] == 2
    assert data["data"]["pagination"]["total_items"] == 5
    assert data["data"]["pagination"]["total_pages"] == 3


def test_list_all_businesses_with_plan_filter(test_super_admin, multiple_businesses, admin_headers):
    response = client.get("/v1/admin/businesses?plan=FREE", headers=admin_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    assert len(data["data"]["items"]) == 3
    
    for item in data["data"]["items"]:
        assert item["plan"] == "FREE"


def test_list_all_businesses_with_active_filter(test_super_admin, multiple_businesses, admin_headers):
    response = client.get("/v1/admin/businesses?is_active=true", headers=admin_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    
    for item in data["data"]["items"]:
        assert item["is_active"] is True


def test_list_all_businesses_with_search(test_super_admin, multiple_businesses, admin_headers):
    response = client.get("/v1/admin/businesses?search=Business 2", headers=admin_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    assert len(data["data"]["items"]) == 1
    assert "Business 2" in data["data"]["items"][0]["business_name"]


def test_get_business_detail_as_super_admin(test_super_admin, test_business_owner, admin_headers, db_session):
    business = test_business_owner["business"]
    
    product = Product(
        business_id=business.id,
        name="Test Product",
        price=100.00,
        is_active=True
    )
    db_session.add(product)
    
    customer = Customer(
        business_id=business.id,
        name="Test Customer",
        phone="9999888877"
    )
    db_session.add(customer)
    db_session.commit()
    db_session.refresh(customer)
    
    order = Order(
        business_id=business.id,
        customer_id=customer.id,
        order_number="ORD001",
        subtotal=500.00,
        total_amount=500.00,
        payment_status="PAID"
    )
    db_session.add(order)
    db_session.commit()
    
    response = client.get(f"/v1/admin/businesses/{business.uuid}", headers=admin_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    assert data["data"]["business_name"] == "Test Business"
    assert data["data"]["total_products"] == 1
    assert data["data"]["total_orders"] == 1
    assert data["data"]["total_customers"] == 1
    assert data["data"]["total_revenue"] == 500.00
    assert data["data"]["owner_name"] == "Test Business Owner"


def test_get_business_detail_not_found(test_super_admin, admin_headers):
    response = client.get("/v1/admin/businesses/invalid-uuid", headers=admin_headers)
    assert response.status_code == 404


def test_update_business_status_activate(test_super_admin, test_business_owner, admin_headers, db_session):
    business = test_business_owner["business"]
    business.is_active = False
    db_session.commit()
    
    update_data = {"is_active": True}
    response = client.patch(
        f"/v1/admin/businesses/{business.uuid}/status",
        json=update_data,
        headers=admin_headers
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "activated" in data["message"]
    
    db_session.refresh(business)
    assert business.is_active is True


def test_update_business_status_deactivate(test_super_admin, test_business_owner, admin_headers, db_session):
    business = test_business_owner["business"]
    
    update_data = {"is_active": False}
    response = client.patch(
        f"/v1/admin/businesses/{business.uuid}/status",
        json=update_data,
        headers=admin_headers
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "deactivated" in data["message"]
    
    db_session.refresh(business)
    assert business.is_active is False


def test_update_business_plan_to_paid(test_super_admin, test_business_owner, admin_headers, db_session):
    business = test_business_owner["business"]
    
    expiry_date = date.today() + timedelta(days=365)
    update_data = {
        "plan": "PAID",
        "plan_expiry_date": expiry_date.isoformat()
    }
    response = client.patch(
        f"/v1/admin/businesses/{business.uuid}/plan",
        json=update_data,
        headers=admin_headers
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "PAID" in data["message"]
    
    db_session.refresh(business)
    assert business.plan == BusinessPlan.PAID
    assert business.plan_expiry_date == expiry_date


def test_update_business_plan_to_free(test_super_admin, test_business_owner, admin_headers, db_session):
    business = test_business_owner["business"]
    business.plan = BusinessPlan.PAID
    db_session.commit()
    
    update_data = {
        "plan": "FREE",
        "plan_expiry_date": None
    }
    response = client.patch(
        f"/v1/admin/businesses/{business.uuid}/plan",
        json=update_data,
        headers=admin_headers
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    
    db_session.refresh(business)
    assert business.plan == BusinessPlan.FREE


def test_list_all_users_as_super_admin(test_super_admin, multiple_businesses, admin_headers):
    response = client.get("/v1/admin/users", headers=admin_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    assert "items" in data["data"]
    assert "pagination" in data["data"]
    assert len(data["data"]["items"]) == 6


def test_list_all_users_with_pagination(test_super_admin, multiple_businesses, admin_headers):
    response = client.get("/v1/admin/users?page=1&page_size=3", headers=admin_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert len(data["data"]["items"]) == 3
    assert data["data"]["pagination"]["page"] == 1
    assert data["data"]["pagination"]["page_size"] == 3


def test_list_all_users_with_role_filter(test_super_admin, multiple_businesses, admin_headers):
    response = client.get("/v1/admin/users?role=BUSINESS_OWNER", headers=admin_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    
    for item in data["data"]["items"]:
        assert item["role"] == "BUSINESS_OWNER"


def test_list_all_users_with_search(test_super_admin, multiple_businesses, admin_headers):
    response = client.get("/v1/admin/users?search=Owner 2", headers=admin_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    assert len(data["data"]["items"]) == 1


def test_update_user_status_activate(test_super_admin, test_business_owner, admin_headers, db_session):
    user = test_business_owner["user"]
    user.is_active = False
    db_session.commit()
    
    update_data = {"is_active": True}
    response = client.patch(
        f"/v1/admin/users/{user.uuid}/status",
        json=update_data,
        headers=admin_headers
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "activated" in data["message"]
    
    db_session.refresh(user)
    assert user.is_active is True


def test_update_user_status_deactivate(test_super_admin, test_business_owner, admin_headers, db_session):
    user = test_business_owner["user"]
    business = test_business_owner["business"]
    
    update_data = {"is_active": False}
    response = client.patch(
        f"/v1/admin/users/{user.uuid}/status",
        json=update_data,
        headers=admin_headers
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "deactivated" in data["message"]
    
    db_session.refresh(user)
    db_session.refresh(business)
    assert user.is_active is False
    assert business.is_active is False


def test_update_user_status_cannot_modify_super_admin(test_super_admin, admin_headers, db_session):
    admin_user = test_super_admin["user"]
    
    update_data = {"is_active": False}
    response = client.patch(
        f"/v1/admin/users/{admin_user.uuid}/status",
        json=update_data,
        headers=admin_headers
    )
    
    assert response.status_code == 403
    assert "Cannot modify SUPER_ADMIN" in response.json()["detail"]


def test_get_platform_statistics_empty(test_super_admin, admin_headers):
    response = client.get("/v1/admin/stats", headers=admin_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    assert data["data"]["total_businesses"] == 0
    assert data["data"]["total_users"] == 1
    assert data["data"]["super_admins"] == 1
    assert data["data"]["business_owners"] == 0


def test_get_platform_statistics_with_data(test_super_admin, multiple_businesses, admin_headers, db_session):
    business = multiple_businesses[0]["business"]
    
    product = Product(
        business_id=business.id,
        name="Test Product",
        price=100.00,
        is_active=True
    )
    db_session.add(product)
    
    customer = Customer(
        business_id=business.id,
        name="Test Customer",
        phone="9999888877"
    )
    db_session.add(customer)
    db_session.commit()
    db_session.refresh(customer)
    
    order = Order(
        business_id=business.id,
        customer_id=customer.id,
        order_number="ORD001",
        subtotal=1000.00,
        total_amount=1000.00,
        payment_status="PAID"
    )
    db_session.add(order)
    db_session.commit()
    
    response = client.get("/v1/admin/stats", headers=admin_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    assert data["data"]["total_businesses"] == 5
    assert data["data"]["active_businesses"] == 4
    assert data["data"]["inactive_businesses"] == 1
    assert data["data"]["free_plan_businesses"] == 3
    assert data["data"]["paid_plan_businesses"] == 2
    assert data["data"]["total_users"] == 6
    assert data["data"]["super_admins"] == 1
    assert data["data"]["business_owners"] == 5
    assert data["data"]["total_products"] == 1
    assert data["data"]["total_orders"] == 1
    assert data["data"]["total_customers"] == 1
    assert data["data"]["total_revenue"] == 1000.00


def test_admin_endpoints_require_authentication():
    endpoints = [
        "/v1/admin/businesses",
        "/v1/admin/users",
        "/v1/admin/stats"
    ]
    
    for endpoint in endpoints:
        response = client.get(endpoint)
        assert response.status_code == 403
