import pytest
from datetime import date, timedelta
from decimal import Decimal
from fastapi.testclient import TestClient
from app.main import app
from app.models.user import User, UserRole
from app.models.business import Business, BusinessPlan
from app.models.product import Product
from app.models.category import Category
from app.models.customer import Customer
from app.models.order import Order, OrderItem, OrderStatus, PaymentStatus
from app.core.security import hash_password, create_access_token

client = TestClient(app)


@pytest.fixture
def test_free_business(db_session):
    user = User(
        phone="9876543210",
        password_hash=hash_password("TestPassword123"),
        full_name="Free Business Owner",
        email="free@example.com",
        role=UserRole.BUSINESS_OWNER,
        is_active=True,
        is_verified=True
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    
    business = Business(
        owner_id=user.id,
        business_name="Free Business",
        phone="9876543210",
        email="free@example.com",
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
    
    return {"user": user, "business": business, "token": access_token, "db": db_session}


@pytest.fixture
def test_paid_business(db_session):
    user = User(
        phone="9876543211",
        password_hash=hash_password("TestPassword123"),
        full_name="Paid Business Owner",
        email="paid@example.com",
        role=UserRole.BUSINESS_OWNER,
        is_active=True,
        is_verified=True
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    
    business = Business(
        owner_id=user.id,
        business_name="Paid Business",
        phone="9876543211",
        email="paid@example.com",
        plan=BusinessPlan.PAID,
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
    
    return {"user": user, "business": business, "token": access_token, "db": db_session}


def create_test_data(business_id, db_session):
    category = Category(
        business_id=business_id,
        name="Test Category",
        is_active=True
    )
    db_session.add(category)
    db_session.commit()
    db_session.refresh(category)
    
    products = []
    for i in range(5):
        product = Product(
            business_id=business_id,
            category_id=category.id,
            name=f"Product {i+1}",
            sku=f"SKU{i+1}",
            price=Decimal("100.00") * (i + 1),
            stock_quantity=50 - (i * 5),
            is_active=True
        )
        db_session.add(product)
        products.append(product)
    
    db_session.commit()
    for p in products:
        db_session.refresh(p)
    
    customers = []
    for i in range(3):
        customer = Customer(
            business_id=business_id,
            name=f"Customer {i+1}",
            phone=f"98765432{10+i}",
            email=f"customer{i+1}@example.com",
            is_active=True
        )
        db_session.add(customer)
        customers.append(customer)
    
    db_session.commit()
    for c in customers:
        db_session.refresh(c)
    
    orders = []
    for i in range(4):
        order = Order(
            business_id=business_id,
            customer_id=customers[i % 3].id,
            order_number=f"ORD{20240101}{i+1:04d}",
            status=OrderStatus.DELIVERED if i < 2 else OrderStatus.PENDING,
            payment_status=PaymentStatus.PAID if i < 2 else PaymentStatus.PENDING,
            subtotal=Decimal("500.00"),
            tax_amount=Decimal("50.00"),
            discount_amount=Decimal("0.00"),
            total_amount=Decimal("550.00"),
            payment_method="CASH"
        )
        db_session.add(order)
        orders.append(order)
    
    db_session.commit()
    for o in orders:
        db_session.refresh(o)
        order_item = OrderItem(
            order_id=o.id,
            product_id=products[0].id,
            product_name=products[0].name,
            product_sku=products[0].sku,
            quantity=5,
            unit_price=products[0].price,
            total_price=products[0].price * 5
        )
        db_session.add(order_item)
    
    db_session.commit()
    
    return {
        "products": products,
        "customers": customers,
        "orders": orders
    }


def test_get_dashboard_stats_free_plan(test_free_business):
    business = test_free_business["business"]
    token = test_free_business["token"]
    db = test_free_business["db"]
    
    create_test_data(business.id, db)
    
    headers = {"Authorization": f"Bearer {token}"}
    response = client.get("/v1/dashboard/stats", headers=headers)
    
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Dashboard statistics retrieved successfully"
    
    stats = data["data"]
    assert "period" in stats
    assert "products" in stats
    assert "customers" in stats
    assert "orders" in stats
    assert "revenue" in stats
    
    assert stats["products"]["total"] == 5
    assert stats["products"]["active"] == 5
    assert stats["products"]["low_stock"] >= 0
    
    assert stats["customers"]["total"] == 3
    assert stats["customers"]["active"] == 3
    
    assert stats["orders"]["total"] == 4
    assert stats["orders"]["completed"] == 2
    assert stats["orders"]["pending"] == 2
    
    assert stats["revenue"]["total"] == 1100.0
    assert stats["revenue"]["pending"] == 1100.0
    
    assert "daily_sales" not in stats or stats["daily_sales"] is None
    assert "top_products" not in stats or stats["top_products"] is None
    assert "recent_orders" not in stats or stats["recent_orders"] is None


def test_get_dashboard_stats_paid_plan(test_paid_business):
    business = test_paid_business["business"]
    token = test_paid_business["token"]
    db = test_paid_business["db"]
    
    create_test_data(business.id, db)
    
    headers = {"Authorization": f"Bearer {token}"}
    response = client.get("/v1/dashboard/stats", headers=headers)
    
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    
    stats = data["data"]
    assert "period" in stats
    assert "products" in stats
    assert "customers" in stats
    assert "orders" in stats
    assert "revenue" in stats
    
    assert stats["products"]["total"] == 5
    assert stats["customers"]["total"] == 3
    assert stats["orders"]["total"] == 4
    
    assert "daily_sales" in stats
    assert "top_products" in stats
    assert "recent_orders" in stats
    
    assert isinstance(stats["daily_sales"], list)
    assert isinstance(stats["top_products"], list)
    assert isinstance(stats["recent_orders"], list)
    
    if stats["top_products"]:
        assert "product_uuid" in stats["top_products"][0]
        assert "product_name" in stats["top_products"][0]
        assert "quantity_sold" in stats["top_products"][0]
        assert "revenue" in stats["top_products"][0]
    
    if stats["recent_orders"]:
        assert "order_uuid" in stats["recent_orders"][0]
        assert "order_number" in stats["recent_orders"][0]
        assert "status" in stats["recent_orders"][0]
        assert "total_amount" in stats["recent_orders"][0]


def test_get_dashboard_stats_with_date_range(test_paid_business):
    business = test_paid_business["business"]
    token = test_paid_business["token"]
    db = test_paid_business["db"]
    
    create_test_data(business.id, db)
    
    headers = {"Authorization": f"Bearer {token}"}
    
    from_date = (date.today() - timedelta(days=7)).isoformat()
    to_date = date.today().isoformat()
    
    response = client.get(
        f"/v1/dashboard/stats?from_date={from_date}&to_date={to_date}",
        headers=headers
    )
    
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    
    stats = data["data"]
    assert stats["period"]["from_date"] == from_date
    assert stats["period"]["to_date"] == to_date


def test_get_dashboard_stats_unauthorized():
    response = client.get("/v1/dashboard/stats")
    assert response.status_code == 403


def test_dashboard_stats_low_stock_detection(test_free_business):
    business = test_free_business["business"]
    token = test_free_business["token"]
    db = test_free_business["db"]
    
    product = Product(
        business_id=business.id,
        name="Low Stock Product",
        sku="LOW001",
        price=Decimal("100.00"),
        stock_quantity=5,
        is_active=True
    )
    db.add(product)
    db.commit()
    
    headers = {"Authorization": f"Bearer {token}"}
    response = client.get("/v1/dashboard/stats", headers=headers)
    
    assert response.status_code == 200
    
    data = response.json()
    stats = data["data"]
    
    assert stats["products"]["low_stock"] >= 1


def test_dashboard_stats_empty_business(test_free_business):
    token = test_free_business["token"]
    
    headers = {"Authorization": f"Bearer {token}"}
    response = client.get("/v1/dashboard/stats", headers=headers)
    
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    
    stats = data["data"]
    assert stats["products"]["total"] == 0
    assert stats["customers"]["total"] == 0
    assert stats["orders"]["total"] == 0
    assert stats["revenue"]["total"] == 0.0
