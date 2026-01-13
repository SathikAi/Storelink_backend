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
def test_free_plan_owner(db_session):
    user = User(
        phone="9876543210",
        password_hash=hash_password("TestPassword123"),
        full_name="Free Plan Owner",
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
        email="free@business.com",
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
        max_customers=50,
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
def test_paid_plan_owner(db_session):
    user = User(
        phone="9876543211",
        password_hash=hash_password("TestPassword123"),
        full_name="Paid Plan Owner",
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
        email="paid@business.com",
        plan=BusinessPlan.PAID,
        is_active=True
    )
    db_session.add(business)
    db_session.commit()
    db_session.refresh(business)
    
    plan_limit = PlanLimit(
        business_id=business.id,
        max_products=None,
        max_orders=None,
        max_customers=None,
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


@pytest.fixture
def free_auth_headers(test_free_plan_owner):
    return {"Authorization": f"Bearer {test_free_plan_owner['token']}"}


@pytest.fixture
def paid_auth_headers(test_paid_plan_owner):
    return {"Authorization": f"Bearer {test_paid_plan_owner['token']}"}


@pytest.fixture
def test_category(db_session, test_paid_plan_owner):
    category = Category(
        business_id=test_paid_plan_owner["business"].id,
        name="Electronics",
        description="Electronic items",
        is_active=True
    )
    db_session.add(category)
    db_session.commit()
    db_session.refresh(category)
    return category


@pytest.fixture
def test_products(db_session, test_paid_plan_owner, test_category):
    products = []
    
    product1 = Product(
        business_id=test_paid_plan_owner["business"].id,
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
        business_id=test_paid_plan_owner["business"].id,
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
def test_customers(db_session, test_paid_plan_owner):
    customers = []
    
    customer1 = Customer(
        business_id=test_paid_plan_owner["business"].id,
        name="John Doe",
        phone="919876543211",
        email="john@example.com",
        address="123 Test Street",
        city="Mumbai",
        state="Maharashtra",
        pincode="400001"
    )
    db_session.add(customer1)
    customers.append(customer1)
    
    customer2 = Customer(
        business_id=test_paid_plan_owner["business"].id,
        name="Jane Smith",
        phone="919876543212",
        email="jane@example.com",
        address="456 Test Avenue",
        city="Delhi",
        state="Delhi",
        pincode="110001"
    )
    db_session.add(customer2)
    customers.append(customer2)
    
    db_session.commit()
    for customer in customers:
        db_session.refresh(customer)
    
    return customers


@pytest.fixture
def test_orders(db_session, test_paid_plan_owner, test_customers, test_products):
    orders = []
    
    order1 = Order(
        business_id=test_paid_plan_owner["business"].id,
        customer_id=test_customers[0].id,
        order_number="ORD20240101001",
        status=OrderStatus.DELIVERED,
        payment_status=PaymentStatus.PAID,
        subtotal=Decimal("51000.00"),
        tax_amount=Decimal("9180.00"),
        discount_amount=Decimal("1000.00"),
        total_amount=Decimal("59180.00"),
        payment_method="UPI"
    )
    db_session.add(order1)
    orders.append(order1)
    
    order2 = Order(
        business_id=test_paid_plan_owner["business"].id,
        customer_id=test_customers[1].id,
        order_number="ORD20240102001",
        status=OrderStatus.PENDING,
        payment_status=PaymentStatus.PENDING,
        subtotal=Decimal("1000.00"),
        tax_amount=Decimal("180.00"),
        discount_amount=Decimal("0.00"),
        total_amount=Decimal("1180.00"),
        payment_method="Cash"
    )
    db_session.add(order2)
    orders.append(order2)
    
    db_session.commit()
    for order in orders:
        db_session.refresh(order)
    
    item1 = OrderItem(
        order_id=order1.id,
        product_id=test_products[0].id,
        product_name=test_products[0].name,
        product_sku=test_products[0].sku,
        quantity=1,
        unit_price=Decimal("50000.00"),
        total_price=Decimal("50000.00")
    )
    db_session.add(item1)
    
    item2 = OrderItem(
        order_id=order1.id,
        product_id=test_products[1].id,
        product_name=test_products[1].name,
        product_sku=test_products[1].sku,
        quantity=2,
        unit_price=Decimal("500.00"),
        total_price=Decimal("1000.00")
    )
    db_session.add(item2)
    
    item3 = OrderItem(
        order_id=order2.id,
        product_id=test_products[1].id,
        product_name=test_products[1].name,
        product_sku=test_products[1].sku,
        quantity=2,
        unit_price=Decimal("500.00"),
        total_price=Decimal("1000.00")
    )
    db_session.add(item3)
    
    db_session.commit()
    
    return orders


def test_sales_report_free_plan_denied(free_auth_headers, test_orders):
    response = client.get("/v1/reports/sales", headers=free_auth_headers)
    assert response.status_code == 403
    data = response.json()
    assert "PAID_PLAN_REQUIRED" in data["detail"]["code"]


def test_sales_report_paid_plan_success(paid_auth_headers, test_orders):
    response = client.get("/v1/reports/sales", headers=paid_auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["business_name"] == "Paid Business"
    assert data["total_orders"] == 2
    assert "orders" in data
    assert len(data["orders"]) == 2


def test_sales_report_with_date_filter(paid_auth_headers, test_orders):
    today = datetime.now().strftime("%Y-%m-%d")
    response = client.get(
        f"/v1/reports/sales?from_date={today}&to_date={today}",
        headers=paid_auth_headers
    )
    assert response.status_code == 200
    data = response.json()
    assert "orders" in data


def test_product_report_free_plan_denied(free_auth_headers, test_orders):
    response = client.get("/v1/reports/products", headers=free_auth_headers)
    assert response.status_code == 403
    data = response.json()
    assert "PAID_PLAN_REQUIRED" in data["detail"]["code"]


def test_product_report_paid_plan_success(paid_auth_headers, test_orders):
    response = client.get("/v1/reports/products", headers=paid_auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["business_name"] == "Paid Business"
    assert "products" in data
    assert len(data["products"]) > 0


def test_customer_report_free_plan_denied(free_auth_headers, test_orders):
    response = client.get("/v1/reports/customers", headers=free_auth_headers)
    assert response.status_code == 403
    data = response.json()
    assert "PAID_PLAN_REQUIRED" in data["detail"]["code"]


def test_customer_report_paid_plan_success(paid_auth_headers, test_orders):
    response = client.get("/v1/reports/customers", headers=paid_auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["business_name"] == "Paid Business"
    assert "customers" in data
    assert len(data["customers"]) > 0


def test_pdf_export_free_plan_denied(free_auth_headers, test_orders):
    response = client.get(
        "/v1/reports/export/pdf?report_type=sales",
        headers=free_auth_headers
    )
    assert response.status_code == 403


def test_pdf_export_sales_report(paid_auth_headers, test_orders):
    response = client.get(
        "/v1/reports/export/pdf?report_type=sales",
        headers=paid_auth_headers
    )
    assert response.status_code == 200
    assert response.headers["content-type"] == "application/pdf"
    assert "attachment" in response.headers["content-disposition"]


def test_pdf_export_product_report(paid_auth_headers, test_orders):
    response = client.get(
        "/v1/reports/export/pdf?report_type=products",
        headers=paid_auth_headers
    )
    assert response.status_code == 200
    assert response.headers["content-type"] == "application/pdf"


def test_pdf_export_customer_report(paid_auth_headers, test_orders):
    response = client.get(
        "/v1/reports/export/pdf?report_type=customers",
        headers=paid_auth_headers
    )
    assert response.status_code == 200
    assert response.headers["content-type"] == "application/pdf"


def test_pdf_export_invalid_report_type(paid_auth_headers, test_orders):
    response = client.get(
        "/v1/reports/export/pdf?report_type=invalid",
        headers=paid_auth_headers
    )
    assert response.status_code == 400


def test_csv_export_free_plan_denied(free_auth_headers, test_orders):
    response = client.get(
        "/v1/reports/export/csv?report_type=sales",
        headers=free_auth_headers
    )
    assert response.status_code == 403


def test_csv_export_sales_report(paid_auth_headers, test_orders):
    response = client.get(
        "/v1/reports/export/csv?report_type=sales",
        headers=paid_auth_headers
    )
    assert response.status_code == 200
    assert response.headers["content-type"] == "text/csv; charset=utf-8"
    assert "attachment" in response.headers["content-disposition"]


def test_csv_export_product_report(paid_auth_headers, test_orders):
    response = client.get(
        "/v1/reports/export/csv?report_type=products",
        headers=paid_auth_headers
    )
    assert response.status_code == 200
    assert response.headers["content-type"] == "text/csv; charset=utf-8"


def test_csv_export_customer_report(paid_auth_headers, test_orders):
    response = client.get(
        "/v1/reports/export/csv?report_type=customers",
        headers=paid_auth_headers
    )
    assert response.status_code == 200
    assert response.headers["content-type"] == "text/csv; charset=utf-8"


def test_csv_export_invalid_report_type(paid_auth_headers, test_orders):
    response = client.get(
        "/v1/reports/export/csv?report_type=invalid",
        headers=paid_auth_headers
    )
    assert response.status_code == 400


def test_sales_report_revenue_calculation(paid_auth_headers, test_orders):
    response = client.get("/v1/reports/sales", headers=paid_auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert float(data["total_revenue"]) == 59180.00


def test_product_report_aggregation(paid_auth_headers, test_orders):
    response = client.get("/v1/reports/products", headers=paid_auth_headers)
    assert response.status_code == 200
    data = response.json()
    
    mouse_product = next((p for p in data["products"] if p["product_sku"] == "MOU001"), None)
    assert mouse_product is not None
    assert mouse_product["total_quantity_sold"] == 4


def test_customer_report_aggregation(paid_auth_headers, test_orders):
    response = client.get("/v1/reports/customers", headers=paid_auth_headers)
    assert response.status_code == 200
    data = response.json()
    
    john = next((c for c in data["customers"] if c["customer_name"] == "John Doe"), None)
    assert john is not None
    assert john["total_orders"] == 1
    assert float(john["total_spent"]) == 59180.00
