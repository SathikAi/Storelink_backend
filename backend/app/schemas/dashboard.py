from pydantic import BaseModel
from typing import Optional, List
from datetime import date


class PeriodSchema(BaseModel):
    from_date: str
    to_date: str


class ProductStatsSchema(BaseModel):
    total: int
    active: int
    low_stock: int


class CustomerStatsSchema(BaseModel):
    total: int
    active: int


class OrderStatsSchema(BaseModel):
    total: int
    pending: int
    processing: int
    completed: int
    cancelled: int


class RevenueStatsSchema(BaseModel):
    total: float
    pending: float


class DailySalesSchema(BaseModel):
    date: str
    order_count: int
    revenue: float


class TopProductSchema(BaseModel):
    product_uuid: str
    product_name: str
    product_sku: Optional[str]
    quantity_sold: int
    revenue: float


class RecentOrderSchema(BaseModel):
    order_uuid: str
    order_number: str
    status: str
    payment_status: str
    total_amount: float
    order_date: str


class DashboardStatsResponse(BaseModel):
    period: PeriodSchema
    products: ProductStatsSchema
    customers: CustomerStatsSchema
    orders: OrderStatsSchema
    revenue: RevenueStatsSchema
    daily_sales: Optional[List[DailySalesSchema]] = None
    top_products: Optional[List[TopProductSchema]] = None
    recent_orders: Optional[List[RecentOrderSchema]] = None


class DashboardResponse(BaseModel):
    success: bool
    message: str
    data: DashboardStatsResponse
