import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.models.user import User, UserRole
from app.models.business import Business, BusinessPlan
from app.models.category import Category
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


def test_create_category(test_business_owner, auth_headers):
    category_data = {
        "name": "Groceries",
        "description": "Food and grocery items",
        "is_active": True
    }
    
    response = client.post("/v1/categories", json=category_data, headers=auth_headers)
    assert response.status_code == 201
    
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Category created successfully"
    assert data["data"]["name"] == "Groceries"
    assert data["data"]["description"] == "Food and grocery items"
    assert data["data"]["is_active"] is True
    assert "uuid" in data["data"]


def test_create_category_duplicate_name(test_business_owner, auth_headers, test_category):
    category_data = {
        "name": "Electronics",
        "description": "Duplicate category"
    }
    
    response = client.post("/v1/categories", json=category_data, headers=auth_headers)
    assert response.status_code == 400
    
    data = response.json()
    assert "already exists" in data["detail"]


def test_create_category_unauthorized():
    category_data = {
        "name": "Test Category"
    }
    
    response = client.post("/v1/categories", json=category_data)
    assert response.status_code == 403


def test_get_categories(test_business_owner, auth_headers, test_category):
    response = client.get("/v1/categories", headers=auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Categories retrieved successfully"
    assert data["total"] >= 1
    assert len(data["data"]) >= 1
    assert data["data"][0]["name"] == "Electronics"


def test_get_categories_with_pagination(test_business_owner, auth_headers, db_session):
    for i in range(5):
        category = Category(
            business_id=test_business_owner["business"].id,
            name=f"Category {i}",
            is_active=True
        )
        db_session.add(category)
    db_session.commit()
    
    response = client.get("/v1/categories?page=1&page_size=3", headers=auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["total"] >= 5
    assert len(data["data"]) == 3
    assert data["page"] == 1
    assert data["page_size"] == 3


def test_get_categories_filter_by_active(test_business_owner, auth_headers, db_session):
    active_cat = Category(
        business_id=test_business_owner["business"].id,
        name="Active Category",
        is_active=True
    )
    inactive_cat = Category(
        business_id=test_business_owner["business"].id,
        name="Inactive Category",
        is_active=False
    )
    db_session.add(active_cat)
    db_session.add(inactive_cat)
    db_session.commit()
    
    response = client.get("/v1/categories?is_active=true", headers=auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    for category in data["data"]:
        assert category["is_active"] is True


def test_get_category_by_uuid(test_business_owner, auth_headers, test_category):
    response = client.get(f"/v1/categories/{test_category.uuid}", headers=auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Category retrieved successfully"
    assert data["data"]["uuid"] == test_category.uuid
    assert data["data"]["name"] == "Electronics"


def test_get_category_by_uuid_not_found(test_business_owner, auth_headers):
    response = client.get("/v1/categories/non-existent-uuid", headers=auth_headers)
    assert response.status_code == 404


def test_update_category(test_business_owner, auth_headers, test_category):
    update_data = {
        "name": "Updated Electronics",
        "description": "Updated description",
        "is_active": False
    }
    
    response = client.put(
        f"/v1/categories/{test_category.uuid}",
        json=update_data,
        headers=auth_headers
    )
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Category updated successfully"
    assert data["data"]["name"] == "Updated Electronics"
    assert data["data"]["description"] == "Updated description"
    assert data["data"]["is_active"] is False


def test_update_category_partial(test_business_owner, auth_headers, test_category):
    update_data = {
        "description": "New description only"
    }
    
    response = client.put(
        f"/v1/categories/{test_category.uuid}",
        json=update_data,
        headers=auth_headers
    )
    assert response.status_code == 200
    
    data = response.json()
    assert data["data"]["name"] == "Electronics"
    assert data["data"]["description"] == "New description only"


def test_update_category_duplicate_name(test_business_owner, auth_headers, db_session):
    cat1 = Category(
        business_id=test_business_owner["business"].id,
        name="Category 1",
        is_active=True
    )
    cat2 = Category(
        business_id=test_business_owner["business"].id,
        name="Category 2",
        is_active=True
    )
    db_session.add(cat1)
    db_session.add(cat2)
    db_session.commit()
    db_session.refresh(cat1)
    db_session.refresh(cat2)
    
    update_data = {"name": "Category 1"}
    response = client.put(f"/v1/categories/{cat2.uuid}", json=update_data, headers=auth_headers)
    assert response.status_code == 400


def test_delete_category(test_business_owner, auth_headers, test_category):
    response = client.delete(f"/v1/categories/{test_category.uuid}", headers=auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Category deleted successfully"
    
    get_response = client.get(f"/v1/categories/{test_category.uuid}", headers=auth_headers)
    assert get_response.status_code == 404


def test_delete_category_not_found(test_business_owner, auth_headers):
    response = client.delete("/v1/categories/non-existent-uuid", headers=auth_headers)
    assert response.status_code == 404
