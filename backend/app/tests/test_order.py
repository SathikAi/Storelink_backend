import pytest
from decimal import Decimal
from datetime import datetime, timedelta
from fastapi.testclient import TestClient
from app.main import app
from app.models.user import User, UserRole
from app.models.business import Business, BusinessPlan
from app.models.category import Category
from app.models.product import Product
from app.models.customer import Customer
from app.models.order import Order, OrderItem, OrderStatus, PaymentStatus
from app.models.plan_limit import PlanLimit
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
    
    plan_limit = PlanLimit(
        business_id=business.id,
        max_products=100,
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
    
    return {"user": user, "business": business, "token": access_token}


@pytest.fixture
def auth_headers(test_business_owner):
    return {"Authorization": f"Bearer {test_business_owner['token']}"}


@pytest.fixture
def test_category(db_session, test_business_owner):
    category = Category(
        business_id=test_business_owner["business"].id,
        name="Electronics",
        description="Electronic items",
        is_active=True
    )
    db_session.add(category)
    db_session.commit()
    db_session.refresh(category)
    return category


@pytest.fixture
def test_products(db_session, test_business_owner, test_category):
    products = []
    
    product1 = Product(
        business_id=test_business_owner["business"].id,
        category_id=test_category.id,
        name="Laptop",
        description="High-performance laptop",
        sku="LAP001",
        price=Decimal("50000.00"),
        cost_price=Decimal("40000.00"),
        stock_quantity=10,
        unit="pcs",
        is_active=True
    )
    db_session.add(product1)
    products.append(product1)
    
    product2 = Product(
        business_id=test_business_owner["business"].id,
        category_id=test_category.id,
        name="Mouse",
        description="Wireless mouse",
        sku="MOU001",
        price=Decimal("500.00"),
        cost_price=Decimal("300.00"),
        stock_quantity=50,
        unit="pcs",
        is_active=True
    )
    db_session.add(product2)
    products.append(product2)
    
    db_session.commit()
    for product in products:
        db_session.refresh(product)
    
    return products


@pytest.fixture
def test_customer(db_session, test_business_owner):
    customer = Customer(
        business_id=test_business_owner["business"].id,
        name="John Doe",
        phone="919876543211",
        email="john@example.com",
        address="123 Test Street",
        city="Mumbai",
        state="Maharashtra",
        pincode="400001"
    )
    db_session.add(customer)
    db_session.commit()
    db_session.refresh(customer)
    return customer


@pytest.fixture
def test_order(db_session, test_business_owner, test_customer, test_products):
    order = Order(
        business_id=test_business_owner["business"].id,
        customer_id=test_customer.id,
        order_number="ORD202401010001",
        status=OrderStatus.PENDING,
        payment_status=PaymentStatus.PENDING,
        subtotal=Decimal("50500.00"),
        tax_amount=Decimal("500.00"),
        discount_amount=Decimal("0.00"),
        total_amount=Decimal("51000.00"),
        payment_method="Cash"
    )
    db_session.add(order)
    db_session.commit()
    db_session.refresh(order)
    
    item1 = OrderItem(
        order_id=order.id,
        product_id=test_products[0].id,
        product_name=test_products[0].name,
        product_sku=test_products[0].sku,
        quantity=1,
        unit_price=test_products[0].price,
        total_price=test_products[0].price
    )
    db_session.add(item1)
    
    item2 = OrderItem(
        order_id=order.id,
        product_id=test_products[1].id,
        product_name=test_products[1].name,
        product_sku=test_products[1].sku,
        quantity=1,
        unit_price=test_products[1].price,
        total_price=test_products[1].price
    )
    db_session.add(item2)
    
    db_session.commit()
    
    return order


def test_create_order_success(auth_headers, test_products, test_customer, db_session):
    payload = {
        "customer_uuid": test_customer.uuid,
        "items": [
            {
                "product_uuid": test_products[0].uuid,
                "quantity": 2
            },
            {
                "product_uuid": test_products[1].uuid,
                "quantity": 5
            }
        ],
        "payment_method": "Cash",
        "tax_amount": 1000.00,
        "discount_amount": 500.00,
        "notes": "Test order"
    }
    
    initial_stock_product1 = test_products[0].stock_quantity
    initial_stock_product2 = test_products[1].stock_quantity
    
    response = client.post("/v1/orders/", json=payload, headers=auth_headers)
    
    assert response.status_code == 201
    data = response.json()
    
    assert "uuid" in data
    assert "order_number" in data
    assert data["status"] == "PENDING"
    assert data["payment_status"] == "PENDING"
    assert len(data["items"]) == 2
    assert Decimal(data["total_amount"]) == Decimal("102500.00")
    
    db_session.refresh(test_products[0])
    db_session.refresh(test_products[1])
    
    assert test_products[0].stock_quantity == initial_stock_product1 - 2
    assert test_products[1].stock_quantity == initial_stock_product2 - 5


def test_create_order_without_customer(auth_headers, test_products):
    payload = {
        "items": [
            {
                "product_uuid": test_products[0].uuid,
                "quantity": 1
            }
        ],
        "payment_method": "Cash",
        "tax_amount": 0,
        "discount_amount": 0
    }
    
    response = client.post("/v1/orders/", json=payload, headers=auth_headers)
    
    assert response.status_code == 201
    data = response.json()
    assert data["customer_id"] is None


def test_create_order_insufficient_stock(auth_headers, test_products):
    payload = {
        "items": [
            {
                "product_uuid": test_products[0].uuid,
                "quantity": 100
            }
        ],
        "payment_method": "Cash",
        "tax_amount": 0,
        "discount_amount": 0
    }
    
    response = client.post("/v1/orders/", json=payload, headers=auth_headers)
    
    assert response.status_code == 400
    assert "Insufficient stock" in response.json()["detail"]


def test_create_order_invalid_product(auth_headers):
    payload = {
        "items": [
            {
                "product_uuid": "invalid-uuid",
                "quantity": 1
            }
        ],
        "payment_method": "Cash",
        "tax_amount": 0,
        "discount_amount": 0
    }
    
    response = client.post("/v1/orders/", json=payload, headers=auth_headers)
    
    assert response.status_code == 404
    assert "not found" in response.json()["detail"]


def test_create_order_invalid_customer(auth_headers, test_products):
    payload = {
        "customer_uuid": "invalid-uuid",
        "items": [
            {
                "product_uuid": test_products[0].uuid,
                "quantity": 1
            }
        ],
        "payment_method": "Cash",
        "tax_amount": 0,
        "discount_amount": 0
    }
    
    response = client.post("/v1/orders/", json=payload, headers=auth_headers)
    
    assert response.status_code == 404
    assert "Customer not found" in response.json()["detail"]


def test_create_order_empty_items(auth_headers):
    payload = {
        "items": [],
        "payment_method": "Cash",
        "tax_amount": 0,
        "discount_amount": 0
    }
    
    response = client.post("/v1/orders/", json=payload, headers=auth_headers)
    
    assert response.status_code == 422


def test_get_orders(auth_headers, test_order):
    response = client.get("/v1/orders/", headers=auth_headers)
    
    assert response.status_code == 200
    data = response.json()
    
    assert "orders" in data
    assert "total" in data
    assert data["total"] >= 1
    assert len(data["orders"]) >= 1


def test_get_orders_with_filters(auth_headers, test_order):
    response = client.get(
        "/v1/orders/",
        params={
            "status": "PENDING",
            "payment_status": "PENDING"
        },
        headers=auth_headers
    )
    
    assert response.status_code == 200
    data = response.json()
    
    assert data["total"] >= 1
    for order in data["orders"]:
        assert order["status"] == "PENDING"
        assert order["payment_status"] == "PENDING"


def test_get_orders_pagination(auth_headers, test_order):
    response = client.get(
        "/v1/orders/",
        params={"page": 1, "page_size": 10},
        headers=auth_headers
    )
    
    assert response.status_code == 200
    data = response.json()
    
    assert data["page"] == 1
    assert data["page_size"] == 10


def test_get_order_by_uuid(auth_headers, test_order):
    response = client.get(f"/v1/orders/{test_order.uuid}", headers=auth_headers)
    
    assert response.status_code == 200
    data = response.json()
    
    assert data["uuid"] == test_order.uuid
    assert data["order_number"] == test_order.order_number
    assert "items" in data
    assert len(data["items"]) >= 2


def test_get_order_not_found(auth_headers):
    response = client.get("/v1/orders/invalid-uuid", headers=auth_headers)
    
    assert response.status_code == 404


def test_update_order_status(auth_headers, test_order):
    payload = {
        "status": "CONFIRMED"
    }
    
    response = client.patch(
        f"/v1/orders/{test_order.uuid}",
        json=payload,
        headers=auth_headers
    )
    
    assert response.status_code == 200
    data = response.json()
    
    assert data["status"] == "CONFIRMED"


def test_update_order_payment_status(auth_headers, test_order):
    payload = {
        "payment_status": "PAID"
    }
    
    response = client.patch(
        f"/v1/orders/{test_order.uuid}",
        json=payload,
        headers=auth_headers
    )
    
    assert response.status_code == 200
    data = response.json()
    
    assert data["payment_status"] == "PAID"


def test_update_order_notes(auth_headers, test_order):
    payload = {
        "notes": "Updated notes for the order"
    }
    
    response = client.patch(
        f"/v1/orders/{test_order.uuid}",
        json=payload,
        headers=auth_headers
    )
    
    assert response.status_code == 200
    data = response.json()
    
    assert data["notes"] == "Updated notes for the order"


def test_update_order_invalid_status(auth_headers, test_order):
    payload = {
        "status": "INVALID_STATUS"
    }
    
    response = client.patch(
        f"/v1/orders/{test_order.uuid}",
        json=payload,
        headers=auth_headers
    )
    
    assert response.status_code == 400
    assert "Invalid status" in response.json()["detail"]


def test_cancel_order_success(auth_headers, test_order, test_products, db_session):
    initial_stock_product1 = test_products[0].stock_quantity
    initial_stock_product2 = test_products[1].stock_quantity
    
    response = client.post(
        f"/v1/orders/{test_order.uuid}/cancel",
        headers=auth_headers
    )
    
    assert response.status_code == 200
    data = response.json()
    
    assert data["status"] == "CANCELLED"
    
    db_session.refresh(test_products[0])
    db_session.refresh(test_products[1])
    
    assert test_products[0].stock_quantity == initial_stock_product1 + 1
    assert test_products[1].stock_quantity == initial_stock_product2 + 1


def test_cancel_delivered_order(auth_headers, test_order, db_session):
    test_order.status = OrderStatus.DELIVERED
    db_session.commit()
    
    response = client.post(
        f"/v1/orders/{test_order.uuid}/cancel",
        headers=auth_headers
    )
    
    assert response.status_code == 400
    assert "Cannot cancel" in response.json()["detail"]


def test_delete_order(auth_headers, test_order, db_session):
    response = client.delete(
        f"/v1/orders/{test_order.uuid}",
        headers=auth_headers
    )
    
    assert response.status_code == 204
    
    db_session.refresh(test_order)
    assert test_order.deleted_at is not None


def test_get_order_stats(auth_headers, test_order, db_session):
    test_order.payment_status = PaymentStatus.PAID
    db_session.commit()
    
    response = client.get("/v1/orders/stats", headers=auth_headers)
    
    assert response.status_code == 200
    data = response.json()
    
    assert "total_orders" in data
    assert "total_revenue" in data
    assert "pending_orders" in data
    assert "completed_orders" in data
    assert data["total_orders"] >= 1


def test_get_order_stats_with_date_range(auth_headers, test_order):
    today = datetime.now().date()
    yesterday = (datetime.now() - timedelta(days=1)).date()
    
    response = client.get(
        "/v1/orders/stats",
        params={
            "from_date": str(yesterday),
            "to_date": str(today)
        },
        headers=auth_headers
    )
    
    assert response.status_code == 200
    data = response.json()
    
    assert "total_orders" in data


def test_order_limit_enforcement(auth_headers, test_products, test_business_owner, db_session):
    plan_limit = db_session.query(PlanLimit).filter(
        PlanLimit.business_id == test_business_owner["business"].id
    ).first()
    plan_limit.max_orders = 0
    db_session.commit()
    
    payload = {
        "items": [
            {
                "product_uuid": test_products[0].uuid,
                "quantity": 1
            }
        ],
        "payment_method": "Cash",
        "tax_amount": 0,
        "discount_amount": 0
    }
    
    response = client.post("/v1/orders/", json=payload, headers=auth_headers)
    
    assert response.status_code == 403
    assert "ORDER_LIMIT_EXCEEDED" in response.json()["detail"]["code"]


def test_multi_item_order_transaction(auth_headers, test_products, db_session):
    test_products[0].stock_quantity = 5
    test_products[1].stock_quantity = 2
    db_session.commit()
    
    payload = {
        "items": [
            {
                "product_uuid": test_products[0].uuid,
                "quantity": 3
            },
            {
                "product_uuid": test_products[1].uuid,
                "quantity": 10
            }
        ],
        "payment_method": "Cash",
        "tax_amount": 0,
        "discount_amount": 0
    }
    
    response = client.post("/v1/orders/", json=payload, headers=auth_headers)
    
    assert response.status_code == 400
    
    db_session.refresh(test_products[0])
    db_session.refresh(test_products[1])
    
    assert test_products[0].stock_quantity == 5
    assert test_products[1].stock_quantity == 2


def test_order_number_generation(auth_headers, test_products):
    payload = {
        "items": [
            {
                "product_uuid": test_products[0].uuid,
                "quantity": 1
            }
        ],
        "payment_method": "Cash",
        "tax_amount": 0,
        "discount_amount": 0
    }
    
    response1 = client.post("/v1/orders/", json=payload, headers=auth_headers)
    response2 = client.post("/v1/orders/", json=payload, headers=auth_headers)
    
    assert response1.status_code == 201
    assert response2.status_code == 201
    
    order1 = response1.json()
    order2 = response2.json()
    
    assert order1["order_number"] != order2["order_number"]
    assert order1["order_number"].startswith("ORD")
    assert order2["order_number"].startswith("ORD")
