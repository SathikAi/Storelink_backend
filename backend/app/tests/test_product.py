import pytest
import io
from decimal import Decimal
from fastapi.testclient import TestClient
from app.main import app
from app.models.user import User, UserRole
from app.models.business import Business, BusinessPlan
from app.models.category import Category
from app.models.product import Product
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
def test_product(db_session, test_business_owner, test_category):
    product = Product(
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
    db_session.add(product)
    db_session.commit()
    db_session.refresh(product)
    return product


def test_create_product(test_business_owner, auth_headers, test_category):
    product_data = {
        "category_id": test_category.id,
        "name": "Smartphone",
        "description": "Latest smartphone",
        "sku": "PHONE001",
        "price": 25000.00,
        "cost_price": 20000.00,
        "stock_quantity": 20,
        "unit": "pcs",
        "is_active": True
    }
    
    response = client.post("/v1/products", json=product_data, headers=auth_headers)
    assert response.status_code == 201
    
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Product created successfully"
    assert data["data"]["name"] == "Smartphone"
    assert data["data"]["sku"] == "PHONE001"
    assert float(data["data"]["price"]) == 25000.00
    assert data["data"]["stock_quantity"] == 20
    assert "uuid" in data["data"]


def test_create_product_without_category(test_business_owner, auth_headers):
    product_data = {
        "name": "Generic Product",
        "price": 100.00,
        "stock_quantity": 5
    }
    
    response = client.post("/v1/products", json=product_data, headers=auth_headers)
    assert response.status_code == 201
    
    data = response.json()
    assert data["data"]["category_id"] is None


def test_create_product_duplicate_sku(test_business_owner, auth_headers, test_product):
    product_data = {
        "name": "Another Laptop",
        "sku": "LAP001",
        "price": 60000.00
    }
    
    response = client.post("/v1/products", json=product_data, headers=auth_headers)
    assert response.status_code == 400
    
    data = response.json()
    assert "already exists" in data["detail"]


def test_create_product_exceeds_limit(test_business_owner, auth_headers, db_session):
    for i in range(10):
        product = Product(
            business_id=test_business_owner["business"].id,
            name=f"Product {i}",
            price=Decimal("100.00")
        )
        db_session.add(product)
    db_session.commit()
    
    product_data = {
        "name": "Product 11",
        "price": 100.00
    }
    
    response = client.post("/v1/products", json=product_data, headers=auth_headers)
    assert response.status_code == 403
    
    data = response.json()
    assert "detail" in data
    assert "PRODUCT_LIMIT_EXCEEDED" in str(data["detail"])


def test_create_product_invalid_category(test_business_owner, auth_headers):
    product_data = {
        "category_id": 99999,
        "name": "Test Product",
        "price": 100.00
    }
    
    response = client.post("/v1/products", json=product_data, headers=auth_headers)
    assert response.status_code == 404


def test_create_product_unauthorized():
    product_data = {
        "name": "Test Product",
        "price": 100.00
    }
    
    response = client.post("/v1/products", json=product_data)
    assert response.status_code == 403


def test_get_products(test_business_owner, auth_headers, test_product):
    response = client.get("/v1/products", headers=auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Products retrieved successfully"
    assert data["total"] >= 1
    assert len(data["data"]) >= 1


def test_get_products_with_pagination(test_business_owner, auth_headers, db_session):
    for i in range(5):
        product = Product(
            business_id=test_business_owner["business"].id,
            name=f"Product {i}",
            price=Decimal("100.00"),
            is_active=True
        )
        db_session.add(product)
    db_session.commit()
    
    response = client.get("/v1/products?page=1&page_size=3", headers=auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["total"] >= 5
    assert len(data["data"]) == 3
    assert data["page"] == 1
    assert data["page_size"] == 3


def test_get_products_filter_by_category(test_business_owner, auth_headers, test_category, db_session):
    product1 = Product(
        business_id=test_business_owner["business"].id,
        category_id=test_category.id,
        name="Product 1",
        price=Decimal("100.00")
    )
    product2 = Product(
        business_id=test_business_owner["business"].id,
        name="Product 2",
        price=Decimal("200.00")
    )
    db_session.add(product1)
    db_session.add(product2)
    db_session.commit()
    
    response = client.get(f"/v1/products?category_id={test_category.id}", headers=auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    for product in data["data"]:
        if product["category_id"] is not None:
            assert product["category_id"] == test_category.id


def test_get_products_filter_by_active(test_business_owner, auth_headers, db_session):
    active_prod = Product(
        business_id=test_business_owner["business"].id,
        name="Active Product",
        price=Decimal("100.00"),
        is_active=True
    )
    inactive_prod = Product(
        business_id=test_business_owner["business"].id,
        name="Inactive Product",
        price=Decimal("200.00"),
        is_active=False
    )
    db_session.add(active_prod)
    db_session.add(inactive_prod)
    db_session.commit()
    
    response = client.get("/v1/products?is_active=true", headers=auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    for product in data["data"]:
        assert product["is_active"] is True


def test_get_products_search(test_business_owner, auth_headers, db_session):
    product1 = Product(
        business_id=test_business_owner["business"].id,
        name="Samsung Galaxy",
        price=Decimal("30000.00")
    )
    product2 = Product(
        business_id=test_business_owner["business"].id,
        name="iPhone 14",
        price=Decimal("80000.00")
    )
    db_session.add(product1)
    db_session.add(product2)
    db_session.commit()
    
    response = client.get("/v1/products?search=Samsung", headers=auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["total"] >= 1
    assert any("Samsung" in product["name"] for product in data["data"])


def test_get_product_by_uuid(test_business_owner, auth_headers, test_product):
    response = client.get(f"/v1/products/{test_product.uuid}", headers=auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Product retrieved successfully"
    assert data["data"]["uuid"] == test_product.uuid
    assert data["data"]["name"] == "Laptop"


def test_get_product_by_uuid_not_found(test_business_owner, auth_headers):
    response = client.get("/v1/products/non-existent-uuid", headers=auth_headers)
    assert response.status_code == 404


def test_update_product(test_business_owner, auth_headers, test_product):
    update_data = {
        "name": "Updated Laptop",
        "price": 55000.00,
        "stock_quantity": 15
    }
    
    response = client.put(
        f"/v1/products/{test_product.uuid}",
        json=update_data,
        headers=auth_headers
    )
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Product updated successfully"
    assert data["data"]["name"] == "Updated Laptop"
    assert float(data["data"]["price"]) == 55000.00
    assert data["data"]["stock_quantity"] == 15


def test_update_product_partial(test_business_owner, auth_headers, test_product):
    update_data = {
        "description": "New description only"
    }
    
    response = client.put(
        f"/v1/products/{test_product.uuid}",
        json=update_data,
        headers=auth_headers
    )
    assert response.status_code == 200
    
    data = response.json()
    assert data["data"]["name"] == "Laptop"
    assert data["data"]["description"] == "New description only"


def test_update_product_duplicate_sku(test_business_owner, auth_headers, db_session):
    prod1 = Product(
        business_id=test_business_owner["business"].id,
        name="Product 1",
        sku="SKU001",
        price=Decimal("100.00")
    )
    prod2 = Product(
        business_id=test_business_owner["business"].id,
        name="Product 2",
        sku="SKU002",
        price=Decimal("200.00")
    )
    db_session.add(prod1)
    db_session.add(prod2)
    db_session.commit()
    db_session.refresh(prod1)
    db_session.refresh(prod2)
    
    update_data = {"sku": "SKU001"}
    response = client.put(f"/v1/products/{prod2.uuid}", json=update_data, headers=auth_headers)
    assert response.status_code == 400


def test_delete_product(test_business_owner, auth_headers, test_product):
    response = client.delete(f"/v1/products/{test_product.uuid}", headers=auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Product deleted successfully"
    
    get_response = client.get(f"/v1/products/{test_product.uuid}", headers=auth_headers)
    assert get_response.status_code == 404


def test_upload_product_image(test_business_owner, auth_headers, test_product):
    from PIL import Image
    
    img = Image.new('RGB', (100, 100), color='blue')
    img_bytes = io.BytesIO()
    img.save(img_bytes, format='PNG')
    img_bytes.seek(0)
    
    files = {"file": ("test_product.png", img_bytes, "image/png")}
    response = client.post(
        f"/v1/products/{test_product.uuid}/image",
        files=files,
        headers=auth_headers
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Product image uploaded successfully"
    assert "image_url" in data
    assert "/uploads/product_images/" in data["image_url"]


def test_upload_product_image_invalid_type(test_business_owner, auth_headers, test_product):
    files = {"file": ("test.txt", io.BytesIO(b"test content"), "text/plain")}
    response = client.post(
        f"/v1/products/{test_product.uuid}/image",
        files=files,
        headers=auth_headers
    )
    
    assert response.status_code == 400


def test_toggle_product_status(test_business_owner, auth_headers, test_product):
    initial_status = test_product.is_active
    
    response = client.patch(
        f"/v1/products/{test_product.uuid}/toggle",
        headers=auth_headers
    )
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Product status toggled successfully"
    assert data["is_active"] == (not initial_status)
    
    response2 = client.patch(
        f"/v1/products/{test_product.uuid}/toggle",
        headers=auth_headers
    )
    assert response2.status_code == 200
    data2 = response2.json()
    assert data2["is_active"] == initial_status
