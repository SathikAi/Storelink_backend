import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.main import app
from app.database import Base, get_db
from app.models.user import User, UserRole
from app.models.business import Business, BusinessPlan
from app.core.security import hash_password

SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db

Base.metadata.create_all(bind=engine)

client = TestClient(app)


@pytest.fixture(autouse=True)
def reset_database():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    yield


@pytest.fixture
def test_user_data():
    return {
        "phone": "9876543210",
        "password": "TestPassword123",
        "full_name": "Test User",
        "email": "test@example.com",
        "business_name": "Test Business",
        "business_phone": "9876543211",
        "business_email": "business@example.com"
    }


@pytest.fixture
def existing_user():
    db = TestingSessionLocal()
    user = User(
        phone="9876543210",
        password_hash=hash_password("TestPassword123"),
        full_name="Existing User",
        email="existing@example.com",
        role=UserRole.BUSINESS_OWNER,
        is_active=True,
        is_verified=True
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    
    business = Business(
        owner_id=user.id,
        business_name="Existing Business",
        phone="9876543210",
        plan=BusinessPlan.FREE,
        is_active=True
    )
    db.add(business)
    db.commit()
    db.refresh(business)
    
    db.close()
    return {"user": user, "business": business}


def test_register_success(test_user_data):
    response = client.post("/v1/auth/register", json=test_user_data)
    assert response.status_code == 201
    data = response.json()
    
    assert data["success"] is True
    assert data["message"] == "Registration successful"
    assert "user" in data["data"]
    assert "business" in data["data"]
    assert "tokens" in data["data"]
    assert data["data"]["user"]["phone"] == test_user_data["phone"]
    assert data["data"]["user"]["full_name"] == test_user_data["full_name"]
    assert data["data"]["business"]["business_name"] == test_user_data["business_name"]
    assert "access_token" in data["data"]["tokens"]
    assert "refresh_token" in data["data"]["tokens"]


def test_register_duplicate_phone(test_user_data, existing_user):
    response = client.post("/v1/auth/register", json=test_user_data)
    assert response.status_code == 400
    data = response.json()
    assert "already registered" in data["detail"].lower()


def test_register_invalid_phone():
    invalid_data = {
        "phone": "123",
        "password": "TestPassword123",
        "full_name": "Test User",
        "business_name": "Test Business",
        "business_phone": "9876543211"
    }
    response = client.post("/v1/auth/register", json=invalid_data)
    assert response.status_code == 422


def test_login_success(existing_user):
    login_data = {
        "phone": "9876543210",
        "password": "TestPassword123"
    }
    response = client.post("/v1/auth/login", json=login_data)
    assert response.status_code == 200
    data = response.json()
    
    assert data["success"] is True
    assert data["message"] == "Login successful"
    assert "tokens" in data["data"]
    assert "access_token" in data["data"]["tokens"]
    assert "refresh_token" in data["data"]["tokens"]


def test_login_invalid_credentials():
    login_data = {
        "phone": "9876543210",
        "password": "WrongPassword"
    }
    response = client.post("/v1/auth/login", json=login_data)
    assert response.status_code == 401
    data = response.json()
    assert "Invalid" in data["detail"]


def test_login_user_not_found():
    login_data = {
        "phone": "9999999999",
        "password": "TestPassword123"
    }
    response = client.post("/v1/auth/login", json=login_data)
    assert response.status_code == 401


def test_send_otp_registration():
    otp_data = {
        "phone": "9876543210",
        "purpose": "REGISTRATION"
    }
    response = client.post("/v1/auth/otp/send", json=otp_data)
    assert response.status_code == 200
    data = response.json()
    
    assert data["success"] is True
    assert "OTP" in data["message"]
    assert data["expires_in_minutes"] == 5


def test_send_otp_existing_user(existing_user):
    otp_data = {
        "phone": "9876543210",
        "purpose": "REGISTRATION"
    }
    response = client.post("/v1/auth/otp/send", json=otp_data)
    assert response.status_code == 400
    data = response.json()
    assert "already registered" in data["detail"].lower()


def test_send_otp_login():
    otp_data = {
        "phone": "9876543210",
        "purpose": "LOGIN"
    }
    response = client.post("/v1/auth/otp/send", json=otp_data)
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True


def test_verify_otp_success(existing_user):
    otp_send_data = {
        "phone": "9876543210",
        "purpose": "LOGIN"
    }
    send_response = client.post("/v1/auth/otp/send", json=otp_send_data)
    assert send_response.status_code == 200
    
    otp_code = "123456"
    
    verify_data = {
        "phone": "9876543210",
        "otp_code": otp_code,
        "purpose": "LOGIN"
    }
    verify_response = client.post("/v1/auth/otp/verify", json=verify_data)
    assert verify_response.status_code == 200
    data = verify_response.json()
    
    assert data["success"] is True
    assert "tokens" in data["data"]


def test_verify_otp_invalid():
    verify_data = {
        "phone": "9876543210",
        "otp_code": "999999",
        "purpose": "LOGIN"
    }
    response = client.post("/v1/auth/otp/verify", json=verify_data)
    assert response.status_code == 400
    data = response.json()
    assert "Invalid OTP" in data["detail"]


def test_get_current_user(existing_user):
    login_data = {
        "phone": "9876543210",
        "password": "TestPassword123"
    }
    login_response = client.post("/v1/auth/login", json=login_data)
    access_token = login_response.json()["data"]["tokens"]["access_token"]
    
    headers = {"Authorization": f"Bearer {access_token}"}
    response = client.get("/v1/auth/me", headers=headers)
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "user" in data["data"]
    assert data["data"]["user"]["phone"] == "9876543210"


def test_get_current_user_unauthorized():
    response = client.get("/v1/auth/me")
    assert response.status_code == 403


def test_get_current_user_invalid_token():
    headers = {"Authorization": "Bearer invalid_token"}
    response = client.get("/v1/auth/me", headers=headers)
    assert response.status_code == 401


def test_refresh_token_success(existing_user):
    login_data = {
        "phone": "9876543210",
        "password": "TestPassword123"
    }
    login_response = client.post("/v1/auth/login", json=login_data)
    refresh_token = login_response.json()["data"]["tokens"]["refresh_token"]
    
    refresh_data = {"refresh_token": refresh_token}
    response = client.post("/v1/auth/refresh", json=refresh_data)
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "tokens" in data["data"]
    assert "access_token" in data["data"]["tokens"]


def test_refresh_token_invalid():
    refresh_data = {"refresh_token": "invalid_token"}
    response = client.post("/v1/auth/refresh", json=refresh_data)
    assert response.status_code == 401


def test_logout_success(existing_user):
    login_data = {
        "phone": "9876543210",
        "password": "TestPassword123"
    }
    login_response = client.post("/v1/auth/login", json=login_data)
    access_token = login_response.json()["data"]["tokens"]["access_token"]
    
    headers = {"Authorization": f"Bearer {access_token}"}
    response = client.post("/v1/auth/logout", headers=headers)
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Logged out successfully"
