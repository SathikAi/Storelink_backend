from pydantic import BaseModel, Field, field_validator
from typing import Optional, List
from datetime import datetime
from decimal import Decimal


class OrderItemCreate(BaseModel):
    product_uuid: str = Field(..., description="Product UUID")
    quantity: int = Field(..., gt=0, description="Quantity must be greater than 0")


class OrderItemResponse(BaseModel):
    id: int
    order_id: int
    product_id: Optional[int]
    product_name: str
    product_sku: Optional[str]
    quantity: int
    unit_price: Decimal
    total_price: Decimal
    created_at: datetime

    class Config:
        from_attributes = True


class OrderCreateRequest(BaseModel):
    customer_uuid: Optional[str] = Field(None, description="Customer UUID (optional)")
    items: List[OrderItemCreate] = Field(..., min_length=1, description="At least one item required")
    payment_method: Optional[str] = Field(None, max_length=50)
    notes: Optional[str] = None
    tax_amount: Decimal = Field(default=Decimal("0.00"), ge=0)
    discount_amount: Decimal = Field(default=Decimal("0.00"), ge=0)

    @field_validator('items')
    @classmethod
    def validate_items(cls, v):
        if not v or len(v) == 0:
            raise ValueError("At least one item is required")
        return v


class OrderUpdateRequest(BaseModel):
    status: Optional[str] = None
    payment_status: Optional[str] = None
    payment_method: Optional[str] = Field(None, max_length=50)
    notes: Optional[str] = None


class OrderResponse(BaseModel):
    id: int
    uuid: str
    order_number: str
    business_id: int
    customer_id: Optional[int]
    order_date: datetime
    status: str
    subtotal: Decimal
    tax_amount: Decimal
    discount_amount: Decimal
    total_amount: Decimal
    payment_method: Optional[str]
    payment_status: str
    notes: Optional[str]
    created_at: datetime
    updated_at: datetime
    items: List[OrderItemResponse] = []

    class Config:
        from_attributes = True


class OrderListResponse(BaseModel):
    orders: List[OrderResponse]
    total: int
    page: int
    page_size: int
    total_pages: int


class OrderStatsResponse(BaseModel):
    total_orders: int
    total_revenue: Decimal
    pending_orders: int
    completed_orders: int
