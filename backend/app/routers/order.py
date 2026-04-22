from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from typing import Optional
from datetime import date
from app.database import get_db
from app.core.dependencies import get_current_business_id
from app.schemas.order import (
    OrderCreateRequest,
    OrderUpdateRequest,
    OrderResponse,
    OrderListResponse,
    OrderStatsResponse
)
from app.services.order_service import OrderService
import math

router = APIRouter(prefix="/orders", tags=["Orders"])


@router.post("", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
def create_order(
    data: OrderCreateRequest,
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    service = OrderService(db)
    return service.create_order(business_id, data)


@router.get("", response_model=OrderListResponse)
def get_orders(
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
    customer_uuid: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    payment_status: Optional[str] = Query(None),
    search: Optional[str] = Query(None),
    from_date: Optional[date] = Query(None),
    to_date: Optional[date] = Query(None),
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    service = OrderService(db)
    orders, total = service.get_orders(
        business_id,
        page=page,
        page_size=page_size,
        customer_uuid=customer_uuid,
        status=status,
        payment_status=payment_status,
        search=search,
        from_date=from_date,
        to_date=to_date
    )
    
    return OrderListResponse(
        orders=orders,
        total=total,
        page=page,
        page_size=page_size,
        total_pages=math.ceil(total / page_size) if total > 0 else 0
    )


@router.get("/stats", response_model=OrderStatsResponse)
def get_order_stats(
    from_date: Optional[date] = Query(None),
    to_date: Optional[date] = Query(None),
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    service = OrderService(db)
    stats = service.get_order_stats(
        business_id,
        from_date=from_date,
        to_date=to_date
    )
    return OrderStatsResponse(**stats)


@router.get("/{order_uuid}", response_model=OrderResponse)
def get_order(
    order_uuid: str,
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    service = OrderService(db)
    return service.get_order_by_uuid(business_id, order_uuid)


@router.patch("/{order_uuid}", response_model=OrderResponse)
def update_order(
    order_uuid: str,
    data: OrderUpdateRequest,
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    service = OrderService(db)
    return service.update_order(business_id, order_uuid, data)


@router.post("/{order_uuid}/cancel", response_model=OrderResponse)
def cancel_order(
    order_uuid: str,
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    service = OrderService(db)
    return service.cancel_order(business_id, order_uuid)


@router.delete("/{order_uuid}", status_code=status.HTTP_204_NO_CONTENT)
def delete_order(
    order_uuid: str,
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    service = OrderService(db)
    service.delete_order(business_id, order_uuid)
    return None
