import pytest
from decimal import Decimal
from fastapi.testclient import TestClient
from app.main import app
from app.models.user import User, UserRole
from app.models.business import Business, BusinessPlan
from app.models.category import Category
from app.models.product import Product
from app.models.customer import Customer
from app.models.order import Order
from app.models.plan_limit import PlanLimit
from app.core.security import hash_password, create_access_token

client = TestClient(app)


@pytest.fixture
def business_owner_account(db_session):
    user = User(
        phone="9876543210",
        password_hash=hash_password("TestPassword123"),
        full_name="Integration Test User",
        email="integration@example.com",
        role=UserRole.BUSINESS_OWNER,
        is_active=True,
        is_verified=True
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    
    business = Business(
        owner_id=user.id,
        business_name="Integration Test Business",
        phone="9876543210",
        email="business@example.com",
        plan=BusinessPlan.FREE,
        is_active=True
    )
    db_session.add(business)
    db_session.commit()
    db_session.refresh(business)
    
    plan_limit = PlanLimit(
        business_id=business.id,
        max_products=10,
        max_orders=50,
        max_customers=100,
        features={
            "reports_enabled": False,
            "export_pdf": False,
            "export_csv": False
        }
    )
    db_session.add(plan_limit)
    db_session.commit()
    
    token_data = {
        "sub": user.uuid,
        "user_id": user.id,
        "role": user.role.value,
        "business_id": business.id
    }
    access_token = create_access_token(token_data)
    
    return {"user": user, "business": business, "token": access_token, "db": db_session}


@pytest.fixture
def second_business_owner(db_session):
    user = User(
        phone="9876543211",
        password_hash=hash_password("TestPassword123"),
        full_name="Second Business Owner",
        email="second@example.com",
        role=UserRole.BUSINESS_OWNER,
        is_active=True,
        is_verified=True
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    
    business = Business(
        owner_id=user.id,
        business_name="Second Business",
        phone="9876543211",
        email="second_business@example.com",
        plan=BusinessPlan.PAID,
        is_active=True
    )
    db_session.add(business)
    db_session.commit()
    db_session.refresh(business)
    
    plan_limit = PlanLimit(
        business_id=business.id,
        max_products=-1,
        max_orders=-1,
        max_customers=-1,
        features={
            "reports_enabled": True,
            "export_pdf": True,
            "export_csv": True
        }
    )
    db_session.add(plan_limit)
    db_session.commit()
    
    token_data = {
        "sub": user.uuid,
        "user_id": user.id,
        "role": user.role.value,
        "business_id": business.id
    }
    access_token = create_access_token(token_data)
    
    return {"user": user, "business": business, "token": access_token}


def test_complete_order_workflow(business_owner_account):
    auth_headers = {"Authorization": f"Bearer {business_owner_account['token']}"}
    db = business_owner_account['db']
    
    category_data = {
        "name": "Electronics",
        "description": "Electronic items"
    }
    category_response = client.post("/v1/categories", json=category_data, headers=auth_headers)
    assert category_response.status_code == 201
    category_uuid = category_response.json()["data"]["uuid"]
    
    product_data = {
        "category_id": category_response.json()["data"]["id"],
        "name": "Laptop",
        "description": "High-performance laptop",
        "sku": "LAP001",
        "price": 50000.00,
        "cost_price": 40000.00,
        "stock_quantity": 10,
        "unit": "pcs"
    }
    product_response = client.post("/v1/products", json=product_data, headers=auth_headers)
    assert product_response.status_code == 201
    product_uuid = product_response.json()["data"]["uuid"]
    
    customer_data = {
        "name": "John Doe",
        "phone": "9876543212",
        "email": "john@example.com"
    }
    customer_response = client.post("/v1/customers", json=customer_data, headers=auth_headers)
    assert customer_response.status_code == 201
    customer_uuid = customer_response.json()["data"]["uuid"]
    
    order_data = {
        "customer_uuid": customer_uuid,
        "items": [
            {
                "product_uuid": product_uuid,
                "quantity": 2
            }
        ],
        "payment_method": "Cash",
        "tax_amount": 1000.00,
        "discount_amount": 0.00
    }
    order_response = client.post("/v1/orders/", json=order_data, headers=auth_headers)
    assert order_response.status_code == 201
    order_uuid = order_response.json()["uuid"]
    
    verify_response = client.get(f"/v1/orders/{order_uuid}", headers=auth_headers)
    assert verify_response.status_code == 200
    assert verify_response.json()["customer"]["uuid"] == customer_uuid
    assert len(verify_response.json()["items"]) == 1
    assert verify_response.json()["items"][0]["product_uuid"] == product_uuid
    
    product_check = client.get(f"/v1/products/{product_uuid}", headers=auth_headers)
    assert product_check.status_code == 200
    assert product_check.json()["data"]["stock_quantity"] == 8


def test_multi_tenant_isolation(business_owner_account, second_business_owner):
    auth_headers_1 = {"Authorization": f"Bearer {business_owner_account['token']}"}
    auth_headers_2 = {"Authorization": f"Bearer {second_business_owner['token']}"}
    db = business_owner_account['db']
    
    product_data = {
        "name": "Business 1 Product",
        "price": 1000.00,
        "stock_quantity": 10
    }
    product_response_1 = client.post("/v1/products", json=product_data, headers=auth_headers_1)
    assert product_response_1.status_code == 201
    product_1_uuid = product_response_1.json()["data"]["uuid"]
    
    product_data_2 = {
        "name": "Business 2 Product",
        "price": 2000.00,
        "stock_quantity": 20
    }
    product_response_2 = client.post("/v1/products", json=product_data_2, headers=auth_headers_2)
    assert product_response_2.status_code == 201
    product_2_uuid = product_response_2.json()["data"]["uuid"]
    
    products_list_1 = client.get("/v1/products", headers=auth_headers_1)
    assert products_list_1.status_code == 200
    product_uuids_1 = [p["uuid"] for p in products_list_1.json()["data"]]
    assert product_1_uuid in product_uuids_1
    assert product_2_uuid not in product_uuids_1
    
    products_list_2 = client.get("/v1/products", headers=auth_headers_2)
    assert products_list_2.status_code == 200
    product_uuids_2 = [p["uuid"] for p in products_list_2.json()["data"]]
    assert product_2_uuid in product_uuids_2
    assert product_1_uuid not in product_uuids_2
    
    access_attempt = client.get(f"/v1/products/{product_2_uuid}", headers=auth_headers_1)
    assert access_attempt.status_code == 404


def test_plan_limit_enforcement_complete_flow(business_owner_account):
    auth_headers = {"Authorization": f"Bearer {business_owner_account['token']}"}
    db = business_owner_account['db']
    
    for i in range(10):
        product_data = {
            "name": f"Product {i}",
            "price": 100.00 * (i + 1),
            "stock_quantity": 10
        }
        response = client.post("/v1/products", json=product_data, headers=auth_headers)
        assert response.status_code == 201
    
    exceeded_product_data = {
        "name": "Product 11",
        "price": 1000.00
    }
    response = client.post("/v1/products", json=exceeded_product_data, headers=auth_headers)
    assert response.status_code == 403
    assert "PRODUCT_LIMIT_EXCEEDED" in str(response.json()["detail"])
    
    reports_response = client.get("/v1/reports/sales", headers=auth_headers)
    assert reports_response.status_code == 403
    assert "PAID plan required" in reports_response.json()["detail"]


def test_paid_plan_features_enabled(second_business_owner, db_session):
    auth_headers = {"Authorization": f"Bearer {second_business_owner['token']}"}
    
    for i in range(15):
        product = Product(
            business_id=second_business_owner["business"].id,
            name=f"Paid Product {i}",
            price=Decimal("100.00"),
            stock_quantity=10
        )
        db_session.add(product)
    db_session.commit()
    
    products_response = client.get("/v1/products", headers=auth_headers)
    assert products_response.status_code == 200
    assert products_response.json()["total"] >= 15
    
    customer = Customer(
        business_id=second_business_owner["business"].id,
        name="Test Customer",
        phone="9876543213"
    )
    db_session.add(customer)
    db_session.commit()
    db_session.refresh(customer)
    
    order = Order(
        business_id=second_business_owner["business"].id,
        customer_id=customer.id,
        order_number="ORD001",
        subtotal=Decimal("1000.00"),
        total_amount=Decimal("1000.00"),
        payment_status="PAID"
    )
    db_session.add(order)
    db_session.commit()
    
    reports_response = client.get("/v1/reports/sales", headers=auth_headers)
    assert reports_response.status_code == 200
    
    pdf_export_response = client.get(
        "/v1/reports/export/pdf?report_type=sales",
        headers=auth_headers
    )
    assert pdf_export_response.status_code == 200
    
    csv_export_response = client.get(
        "/v1/reports/export/csv?report_type=sales",
        headers=auth_headers
    )
    assert csv_export_response.status_code == 200


def test_stock_management_consistency(business_owner_account):
    auth_headers = {"Authorization": f"Bearer {business_owner_account['token']}"}
    
    product_data = {
        "name": "Stock Test Product",
        "price": 500.00,
        "stock_quantity": 10
    }
    product_response = client.post("/v1/products", json=product_data, headers=auth_headers)
    assert product_response.status_code == 201
    product_uuid = product_response.json()["data"]["uuid"]
    
    customer_data = {
        "name": "Stock Test Customer",
        "phone": "9876543214"
    }
    customer_response = client.post("/v1/customers", json=customer_data, headers=auth_headers)
    customer_uuid = customer_response.json()["data"]["uuid"]
    
    order_data = {
        "customer_uuid": customer_uuid,
        "items": [
            {
                "product_uuid": product_uuid,
                "quantity": 5
            }
        ],
        "payment_method": "Cash",
        "tax_amount": 0,
        "discount_amount": 0
    }
    order_response = client.post("/v1/orders/", json=order_data, headers=auth_headers)
    assert order_response.status_code == 201
    order_uuid = order_response.json()["uuid"]
    
    product_check_1 = client.get(f"/v1/products/{product_uuid}", headers=auth_headers)
    assert product_check_1.json()["data"]["stock_quantity"] == 5
    
    cancel_response = client.patch(
        f"/v1/orders/{order_uuid}",
        json={"status": "CANCELLED"},
        headers=auth_headers
    )
    assert cancel_response.status_code == 200
    
    product_check_2 = client.get(f"/v1/products/{product_uuid}", headers=auth_headers)
    assert product_check_2.json()["data"]["stock_quantity"] == 10


def test_authentication_flow_complete(db_session):
    register_data = {
        "phone": "9876543215",
        "password": "SecurePassword123",
        "full_name": "Auth Test User",
        "email": "authtest@example.com",
        "business_name": "Auth Test Business",
        "business_phone": "9876543215",
        "business_email": "authbusiness@example.com"
    }
    
    register_response = client.post("/v1/auth/register", json=register_data)
    assert register_response.status_code == 201
    assert "tokens" in register_response.json()["data"]
    access_token = register_response.json()["data"]["tokens"]["access_token"]
    
    auth_headers = {"Authorization": f"Bearer {access_token}"}
    profile_response = client.get("/v1/auth/me", headers=auth_headers)
    assert profile_response.status_code == 200
    assert profile_response.json()["data"]["user"]["phone"] == "9876543215"
    
    logout_response = client.post("/v1/auth/logout", headers=auth_headers)
    assert logout_response.status_code == 200
    
    login_data = {
        "phone": "9876543215",
        "password": "SecurePassword123"
    }
    login_response = client.post("/v1/auth/login", json=login_data)
    assert login_response.status_code == 200
    assert "tokens" in login_response.json()["data"]


def test_customer_order_history_consistency(business_owner_account):
    auth_headers = {"Authorization": f"Bearer {business_owner_account['token']}"}
    
    customer_data = {
        "name": "History Test Customer",
        "phone": "9876543216"
    }
    customer_response = client.post("/v1/customers", json=customer_data, headers=auth_headers)
    customer_uuid = customer_response.json()["data"]["uuid"]
    
    product_data = {
        "name": "History Product",
        "price": 100.00,
        "stock_quantity": 100
    }
    product_response = client.post("/v1/products", json=product_data, headers=auth_headers)
    product_uuid = product_response.json()["data"]["uuid"]
    
    for i in range(3):
        order_data = {
            "customer_uuid": customer_uuid,
            "items": [
                {
                    "product_uuid": product_uuid,
                    "quantity": i + 1
                }
            ],
            "payment_method": "Cash",
            "tax_amount": 0,
            "discount_amount": 0
        }
        order_response = client.post("/v1/orders/", json=order_data, headers=auth_headers)
        assert order_response.status_code == 201
    
    history_response = client.get(f"/v1/customers/{customer_uuid}/orders", headers=auth_headers)
    assert history_response.status_code == 200
    assert history_response.json()["total"] == 3
    assert len(history_response.json()["orders"]) == 3


def test_dashboard_statistics_accuracy(business_owner_account):
    auth_headers = {"Authorization": f"Bearer {business_owner_account['token']}"}
    db = business_owner_account['db']
    
    for i in range(3):
        product = Product(
            business_id=business_owner_account["business"].id,
            name=f"Dashboard Product {i}",
            price=Decimal("100.00"),
            stock_quantity=10,
            is_active=True
        )
        db.add(product)
    db.commit()
    
    for i in range(2):
        customer = Customer(
            business_id=business_owner_account["business"].id,
            name=f"Dashboard Customer {i}",
            phone=f"987654321{i}"
        )
        db.add(customer)
    db.commit()
    
    customers = db.query(Customer).filter(
        Customer.business_id == business_owner_account["business"].id
    ).all()
    
    products = db.query(Product).filter(
        Product.business_id == business_owner_account["business"].id
    ).all()
    
    order = Order(
        business_id=business_owner_account["business"].id,
        customer_id=customers[0].id,
        order_number="DASHBOARD001",
        subtotal=Decimal("500.00"),
        total_amount=Decimal("500.00"),
        payment_status="PAID"
    )
    db.add(order)
    db.commit()
    
    dashboard_response = client.get("/v1/dashboard", headers=auth_headers)
    assert dashboard_response.status_code == 200
    
    stats = dashboard_response.json()["data"]
    assert stats["total_products"] >= 3
    assert stats["total_customers"] >= 2
    assert stats["total_orders"] >= 1
    assert float(stats["total_revenue"]) >= 500.00


def test_business_statistics_accuracy(business_owner_account):
    auth_headers = {"Authorization": f"Bearer {business_owner_account['token']}"}
    db = business_owner_account['db']
    
    product = Product(
        business_id=business_owner_account["business"].id,
        name="Stats Product",
        price=Decimal("200.00"),
        stock_quantity=5,
        is_active=True
    )
    db.add(product)
    db.commit()
    db.refresh(product)
    
    customer = Customer(
        business_id=business_owner_account["business"].id,
        name="Stats Customer",
        phone="9876543219"
    )
    db.add(customer)
    db.commit()
    db.refresh(customer)
    
    order = Order(
        business_id=business_owner_account["business"].id,
        customer_id=customer.id,
        order_number="STATS001",
        subtotal=Decimal("800.00"),
        total_amount=Decimal("800.00"),
        payment_status="PAID"
    )
    db.add(order)
    db.commit()
    
    stats_response = client.get("/v1/business/stats", headers=auth_headers)
    assert stats_response.status_code == 200
    
    stats = stats_response.json()["data"]
    assert stats["total_products"] >= 1
    assert stats["total_customers"] >= 1
    assert stats["total_orders"] >= 1
    assert float(stats["total_revenue"]) >= 800.00
