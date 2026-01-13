from pydantic import BaseModel, Field, field_validator
from typing import Optional, List
from datetime import datetime
import re


class CustomerCreateRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    phone: str = Field(..., min_length=10, max_length=15)
    email: Optional[str] = Field(None, max_length=255)
    address: Optional[str] = None
    city: Optional[str] = Field(None, max_length=100)
    state: Optional[str] = Field(None, max_length=100)
    pincode: Optional[str] = Field(None, max_length=10)
    notes: Optional[str] = None
    is_active: bool = True
    
    @field_validator('phone')
    @classmethod
    def validate_phone(cls, v: str) -> str:
        phone_clean = re.sub(r'[^\d+]', '', v)
        
        if phone_clean.startswith('+91'):
            phone_clean = phone_clean[3:]
        elif phone_clean.startswith('91') and len(phone_clean) == 12:
            phone_clean = phone_clean[2:]
        
        if not re.match(r'^[6-9]\d{9}$', phone_clean):
            raise ValueError('Invalid Indian phone number. Must be 10 digits starting with 6-9')
        
        return phone_clean
    
    @field_validator('email')
    @classmethod
    def validate_email(cls, v: Optional[str]) -> Optional[str]:
        if v is None or v.strip() == '':
            return None
        
        email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(email_pattern, v.strip()):
            raise ValueError('Invalid email format')
        
        return v.strip().lower()
    
    @field_validator('pincode')
    @classmethod
    def validate_pincode(cls, v: Optional[str]) -> Optional[str]:
        if v is None or v.strip() == '':
            return None
        
        pincode_clean = re.sub(r'\D', '', v)
        
        if len(pincode_clean) != 6:
            raise ValueError('Invalid Indian pincode. Must be 6 digits')
        
        return pincode_clean


class CustomerUpdateRequest(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    phone: Optional[str] = Field(None, min_length=10, max_length=15)
    email: Optional[str] = Field(None, max_length=255)
    address: Optional[str] = None
    city: Optional[str] = Field(None, max_length=100)
    state: Optional[str] = Field(None, max_length=100)
    pincode: Optional[str] = Field(None, max_length=10)
    notes: Optional[str] = None
    is_active: Optional[bool] = None
    
    @field_validator('phone')
    @classmethod
    def validate_phone(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        
        phone_clean = re.sub(r'[^\d+]', '', v)
        
        if phone_clean.startswith('+91'):
            phone_clean = phone_clean[3:]
        elif phone_clean.startswith('91') and len(phone_clean) == 12:
            phone_clean = phone_clean[2:]
        
        if not re.match(r'^[6-9]\d{9}$', phone_clean):
            raise ValueError('Invalid Indian phone number. Must be 10 digits starting with 6-9')
        
        return phone_clean
    
    @field_validator('email')
    @classmethod
    def validate_email(cls, v: Optional[str]) -> Optional[str]:
        if v is None or v.strip() == '':
            return None
        
        email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(email_pattern, v.strip()):
            raise ValueError('Invalid email format')
        
        return v.strip().lower()
    
    @field_validator('pincode')
    @classmethod
    def validate_pincode(cls, v: Optional[str]) -> Optional[str]:
        if v is None or v.strip() == '':
            return None
        
        pincode_clean = re.sub(r'\D', '', v)
        
        if len(pincode_clean) != 6:
            raise ValueError('Invalid Indian pincode. Must be 6 digits')
        
        return pincode_clean


class CustomerResponse(BaseModel):
    uuid: str
    business_id: int
    name: str
    phone: str
    email: Optional[str]
    address: Optional[str]
    city: Optional[str]
    state: Optional[str]
    pincode: Optional[str]
    notes: Optional[str]
    is_active: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class CustomerListResponse(BaseModel):
    success: bool = True
    message: str
    data: List[CustomerResponse]
    total: int
    page: int
    page_size: int
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class CustomerSingleResponse(BaseModel):
    success: bool = True
    message: str
    data: CustomerResponse
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class CustomerDeleteResponse(BaseModel):
    success: bool = True
    message: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)
