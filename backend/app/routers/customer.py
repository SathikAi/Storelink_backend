from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import Optional
from app.database import get_db
from app.schemas.customer import (
    CustomerCreateRequest,
    CustomerUpdateRequest,
    CustomerListResponse,
    CustomerSingleResponse,
    CustomerDeleteResponse,
    CustomerResponse
)
from app.services.customer_service import CustomerService
from app.core.dependencies import get_current_business_id
from app.models.order import Order
from pydantic import BaseModel, Field
from datetime import datetime, timezone
from typing import List
from decimal import Decimal


class OrderHistoryItem(BaseModel):
    uuid: str
    order_number: str
    order_date: datetime
    status: str
    payment_status: str
    total_amount: Decimal
    
    class Config:
        from_attributes = True


class CustomerOrderHistoryResponse(BaseModel):
    success: bool = True
    message: str
    customer_uuid: str
    customer_name: str
    data: List[OrderHistoryItem]
    total_orders: int
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


router = APIRouter(prefix="/customers", tags=["Customers"])


@router.post("", response_model=CustomerSingleResponse, status_code=201)
async def create_customer(
    data: CustomerCreateRequest,
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    customer_service = CustomerService(db)
    customer = customer_service.create_customer(business_id, data)
    
    return CustomerSingleResponse(
        message="Customer created successfully",
        data=CustomerResponse.model_validate(customer)
    )


@router.get("", response_model=CustomerListResponse)
async def get_customers(
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
    is_active: Optional[bool] = None,
    search: Optional[str] = None,
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    customer_service = CustomerService(db)
    customers, total = customer_service.get_customers(
        business_id, page, page_size, is_active, search
    )
    
    return CustomerListResponse(
        message="Customers retrieved successfully",
        data=[CustomerResponse.model_validate(cust) for cust in customers],
        total=total,
        page=page,
        page_size=page_size
    )


@router.get("/{customer_uuid}", response_model=CustomerSingleResponse)
async def get_customer(
    customer_uuid: str,
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    customer_service = CustomerService(db)
    customer = customer_service.get_customer_by_uuid(business_id, customer_uuid)
    
    return CustomerSingleResponse(
        message="Customer retrieved successfully",
        data=CustomerResponse.model_validate(customer)
    )


@router.put("/{customer_uuid}", response_model=CustomerSingleResponse)
async def update_customer(
    customer_uuid: str,
    data: CustomerUpdateRequest,
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    customer_service = CustomerService(db)
    customer = customer_service.update_customer(business_id, customer_uuid, data)
    
    return CustomerSingleResponse(
        message="Customer updated successfully",
        data=CustomerResponse.model_validate(customer)
    )


@router.delete("/{customer_uuid}", response_model=CustomerDeleteResponse)
async def delete_customer(
    customer_uuid: str,
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    customer_service = CustomerService(db)
    customer_service.delete_customer(business_id, customer_uuid)
    
    return CustomerDeleteResponse(
        message="Customer deleted successfully"
    )


@router.get("/{customer_uuid}/orders", response_model=CustomerOrderHistoryResponse)
async def get_customer_orders(
    customer_uuid: str,
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    customer_service = CustomerService(db)
    customer = customer_service.get_customer_by_uuid(business_id, customer_uuid)
    
    orders = db.query(Order).filter(
        Order.customer_id == customer.id,
        Order.business_id == business_id,
        Order.deleted_at.is_(None)
    ).order_by(Order.order_date.desc()).all()
    
    return CustomerOrderHistoryResponse(
        message="Customer order history retrieved successfully",
        customer_uuid=customer.uuid,
        customer_name=customer.name,
        data=[OrderHistoryItem.model_validate(order) for order in orders],
        total_orders=len(orders)
    )
