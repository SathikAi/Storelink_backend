import requests
import json

base_url = "http://localhost:8001/v1"

payload = {
    "phone": "9876543210",
    "password": "Password123!",
    "full_name": "Test User",
    "email": "test@example.com",
    "business_name": "Test Business",
    "business_phone": "9876543210",
    "business_email": "biz@example.com",
    "referral_code": None
}

print(f"Post to {base_url}/auth/register")
try:
    response = requests.post(f"{base_url}/auth/register", json=payload)
    print(f"Status Code: {response.status_code}")
    print(f"Response Body: {json.dumps(response.json(), indent=2)}")
except Exception as e:
    print(f"Error: {e}")
