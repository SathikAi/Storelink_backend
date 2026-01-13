from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import date
from decimal import Decimal


class SalesReportItem(BaseModel):
    order_number: str
    customer_name: Optional[str]
    order_date: str
    status: str
    payment_status: str
    subtotal: Decimal
    tax_amount: Decimal
    discount_amount: Decimal
    total_amount: Decimal


class SalesReportResponse(BaseModel):
    business_name: str
    from_date: Optional[str]
    to_date: Optional[str]
    total_orders: int
    total_revenue: Decimal
    total_tax: Decimal
    total_discount: Decimal
    orders: List[SalesReportItem]


class ProductReportItem(BaseModel):
    product_name: str
    product_sku: Optional[str]
    category_name: Optional[str]
    total_quantity_sold: int
    total_revenue: Decimal
    orders_count: int


class ProductReportResponse(BaseModel):
    business_name: str
    from_date: Optional[str]
    to_date: Optional[str]
    total_products_sold: int
    total_revenue: Decimal
    products: List[ProductReportItem]


class CustomerReportItem(BaseModel):
    customer_name: str
    customer_phone: str
    customer_email: Optional[str]
    total_orders: int
    total_spent: Decimal
    last_order_date: Optional[str]


class CustomerReportResponse(BaseModel):
    business_name: str
    from_date: Optional[str]
    to_date: Optional[str]
    total_customers: int
    total_revenue: Decimal
    customers: List[CustomerReportItem]


class ExportFormat(BaseModel):
    report_type: str = Field(..., description="Type of report: sales, products, customers")
    from_date: Optional[str] = Field(None, description="Start date (YYYY-MM-DD)")
    to_date: Optional[str] = Field(None, description="End date (YYYY-MM-DD)")
