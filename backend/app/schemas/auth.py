from pydantic import BaseModel, Field, field_validator
from typing import Optional
from datetime import datetime
import re


class RegisterRequest(BaseModel):
    phone: str = Field(..., min_length=10, max_length=15)
    password: str = Field(..., min_length=8, max_length=100)
    full_name: str = Field(..., min_length=2, max_length=255)
    email: Optional[str] = Field(None, max_length=255)
    business_name: str = Field(..., min_length=2, max_length=255)
    business_phone: str = Field(..., min_length=10, max_length=15)
    business_email: Optional[str] = Field(None, max_length=255)
    
    @field_validator('phone', 'business_phone')
    @classmethod
    def validate_phone(cls, v: str) -> str:
        phone = re.sub(r'\D', '', v)
        if len(phone) < 10:
            raise ValueError('Phone number must be at least 10 digits')
        if not phone.startswith(('6', '7', '8', '9')):
            raise ValueError('Invalid Indian phone number')
        return phone
    
    @field_validator('email', 'business_email')
    @classmethod
    def validate_email(cls, v: Optional[str]) -> Optional[str]:
        if v is None or v == "":
            return None
        email_regex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(email_regex, v):
            raise ValueError('Invalid email format')
        return v.lower()


class LoginRequest(BaseModel):
    phone: str = Field(..., min_length=10, max_length=15)
    password: str = Field(..., min_length=8, max_length=100)
    
    @field_validator('phone')
    @classmethod
    def validate_phone(cls, v: str) -> str:
        phone = re.sub(r'\D', '', v)
        if len(phone) < 10:
            raise ValueError('Phone number must be at least 10 digits')
        return phone


class OTPSendRequest(BaseModel):
    phone: str = Field(..., min_length=10, max_length=15)
    purpose: str = Field(..., pattern="^(LOGIN|REGISTRATION|PASSWORD_RESET)$")
    
    @field_validator('phone')
    @classmethod
    def validate_phone(cls, v: str) -> str:
        phone = re.sub(r'\D', '', v)
        if len(phone) < 10:
            raise ValueError('Phone number must be at least 10 digits')
        if not phone.startswith(('6', '7', '8', '9')):
            raise ValueError('Invalid Indian phone number')
        return phone


class OTPVerifyRequest(BaseModel):
    phone: str = Field(..., min_length=10, max_length=15)
    otp_code: str = Field(..., min_length=6, max_length=6)
    purpose: str = Field(..., pattern="^(LOGIN|REGISTRATION|PASSWORD_RESET)$")
    
    @field_validator('phone')
    @classmethod
    def validate_phone(cls, v: str) -> str:
        phone = re.sub(r'\D', '', v)
        if len(phone) < 10:
            raise ValueError('Phone number must be at least 10 digits')
        return phone
    
    @field_validator('otp_code')
    @classmethod
    def validate_otp(cls, v: str) -> str:
        if not v.isdigit():
            raise ValueError('OTP must be numeric')
        return v


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class UserResponse(BaseModel):
    uuid: str
    phone: str
    email: Optional[str]
    full_name: str
    role: str
    is_active: bool
    is_verified: bool
    created_at: datetime
    
    class Config:
        from_attributes = True


class AuthResponse(BaseModel):
    success: bool = True
    message: str
    data: dict
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class OTPResponse(BaseModel):
    success: bool = True
    message: str
    expires_in_minutes: int
    timestamp: datetime = Field(default_factory=datetime.utcnow)
