from pydantic import BaseModel, Field, field_validator
from typing import Optional, List
from datetime import datetime
from decimal import Decimal


class ProductCreateRequest(BaseModel):
    category_id: Optional[int] = None
    name: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    sku: Optional[str] = Field(None, max_length=100)
    price: Decimal = Field(..., gt=0)
    cost_price: Optional[Decimal] = Field(None, ge=0)
    stock_quantity: int = Field(default=0, ge=0)
    unit: Optional[str] = Field(None, max_length=50)
    is_active: bool = True


class ProductUpdateRequest(BaseModel):
    category_id: Optional[int] = None
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = None
    sku: Optional[str] = Field(None, max_length=100)
    price: Optional[Decimal] = Field(None, gt=0)
    cost_price: Optional[Decimal] = Field(None, ge=0)
    stock_quantity: Optional[int] = Field(None, ge=0)
    unit: Optional[str] = Field(None, max_length=50)
    is_active: Optional[bool] = None


class ProductResponse(BaseModel):
    uuid: str
    business_id: int
    category_id: Optional[int]
    name: str
    description: Optional[str]
    sku: Optional[str]
    price: Decimal
    cost_price: Optional[Decimal]
    stock_quantity: int
    unit: Optional[str]
    image_url: Optional[str]
    is_active: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class ProductListResponse(BaseModel):
    success: bool = True
    message: str
    data: List[ProductResponse]
    total: int
    page: int
    page_size: int
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class ProductSingleResponse(BaseModel):
    success: bool = True
    message: str
    data: ProductResponse
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class ProductDeleteResponse(BaseModel):
    success: bool = True
    message: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class ProductImageUploadResponse(BaseModel):
    success: bool = True
    message: str
    image_url: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class ProductToggleResponse(BaseModel):
    success: bool = True
    message: str
    is_active: bool
    timestamp: datetime = Field(default_factory=datetime.utcnow)
