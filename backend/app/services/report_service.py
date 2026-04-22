from typing import Optional
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, case
from datetime import datetime, date
from decimal import Decimal
from app.models.order import Order, OrderItem, PaymentStatus, OrderStatus
from app.models.product import Product
from app.models.customer import Customer
from app.models.category import Category
from app.models.business import Business
from app.schemas.report import (
    SalesReportResponse,
    SalesReportItem,
    ProductReportResponse,
    ProductReportItem,
    CustomerReportResponse,
    CustomerReportItem
)


class ReportService:
    def __init__(self, db: Session):
        self.db = db
    
    def _parse_date(self, date_str: Optional[str]) -> Optional[date]:
        if not date_str:
            return None
        try:
            return datetime.strptime(date_str, "%Y-%m-%d").date()
        except ValueError:
            return None
    
    def _format_date(self, dt) -> str:
        if isinstance(dt, datetime):
            return dt.strftime("%Y-%m-%d %H:%M:%S")
        elif isinstance(dt, date):
            return dt.strftime("%Y-%m-%d")
        return str(dt) if dt else ""
    
    def get_sales_report(
        self,
        business_id: int,
        from_date: Optional[str] = None,
        to_date: Optional[str] = None
    ) -> SalesReportResponse:
        business = self.db.query(Business).filter(Business.id == business_id).first()
        business_name = business.business_name if business else "Unknown"
        
        query = self.db.query(Order).filter(
            Order.business_id == business_id,
            Order.deleted_at.is_(None)
        )
        
        start_date = self._parse_date(from_date)
        end_date = self._parse_date(to_date)
        
        if start_date:
            query = query.filter(func.date(Order.order_date) >= start_date)
        if end_date:
            query = query.filter(func.date(Order.order_date) <= end_date)
        
        orders = query.order_by(Order.order_date.desc()).all()
        
        total_revenue = Decimal("0.00")
        total_tax = Decimal("0.00")
        total_discount = Decimal("0.00")
        sales_items = []
        
        for order in orders:
            customer = None
            if order.customer_id:
                customer = self.db.query(Customer).filter(Customer.id == order.customer_id).first()
            
            if order.payment_status == PaymentStatus.PAID:
                total_revenue += order.total_amount
            total_tax += order.tax_amount
            total_discount += order.discount_amount
            
            sales_items.append(SalesReportItem(
                order_number=order.order_number,
                customer_name=customer.name if customer else None,
                order_date=self._format_date(order.order_date),
                status=order.status.value,
                payment_status=order.payment_status.value,
                subtotal=order.subtotal,
                tax_amount=order.tax_amount,
                discount_amount=order.discount_amount,
                total_amount=order.total_amount
            ))
        
        return SalesReportResponse(
            business_name=business_name,
            from_date=from_date,
            to_date=to_date,
            total_orders=len(orders),
            total_revenue=total_revenue,
            total_tax=total_tax,
            total_discount=total_discount,
            orders=sales_items
        )
    
    def get_product_report(
        self,
        business_id: int,
        from_date: Optional[str] = None,
        to_date: Optional[str] = None
    ) -> ProductReportResponse:
        business = self.db.query(Business).filter(Business.id == business_id).first()
        business_name = business.business_name if business else "Unknown"
        
        query = self.db.query(
            OrderItem.product_id,
            OrderItem.product_name,
            OrderItem.product_sku,
            func.sum(OrderItem.quantity).label('total_quantity'),
            func.sum(OrderItem.total_price).label('total_revenue'),
            func.count(func.distinct(OrderItem.order_id)).label('orders_count')
        ).join(Order, OrderItem.order_id == Order.id).filter(
            Order.business_id == business_id,
            Order.deleted_at.is_(None)
        )
        
        start_date = self._parse_date(from_date)
        end_date = self._parse_date(to_date)
        
        if start_date:
            query = query.filter(func.date(Order.order_date) >= start_date)
        if end_date:
            query = query.filter(func.date(Order.order_date) <= end_date)
        
        query = query.group_by(
            OrderItem.product_id,
            OrderItem.product_name,
            OrderItem.product_sku
        ).order_by(func.sum(OrderItem.total_price).desc())
        
        results = query.all()
        
        product_items = []
        total_revenue = Decimal("0.00")
        
        for result in results:
            category_name = None
            if result.product_id:
                product = self.db.query(Product).filter(Product.id == result.product_id).first()
                if product and product.category_id:
                    category = self.db.query(Category).filter(Category.id == product.category_id).first()
                    if category:
                        category_name = category.name
            
            revenue = Decimal(str(result.total_revenue)) if result.total_revenue else Decimal("0.00")
            total_revenue += revenue
            
            product_items.append(ProductReportItem(
                product_name=result.product_name,
                product_sku=result.product_sku,
                category_name=category_name,
                total_quantity_sold=int(result.total_quantity) if result.total_quantity else 0,
                total_revenue=revenue,
                orders_count=int(result.orders_count) if result.orders_count else 0
            ))
        
        return ProductReportResponse(
            business_name=business_name,
            from_date=from_date,
            to_date=to_date,
            total_products_sold=len(results),
            total_revenue=total_revenue,
            products=product_items
        )
    
    def get_customer_report(
        self,
        business_id: int,
        from_date: Optional[str] = None,
        to_date: Optional[str] = None
    ) -> CustomerReportResponse:
        business = self.db.query(Business).filter(Business.id == business_id).first()
        business_name = business.business_name if business else "Unknown"
        
        query = self.db.query(
            Order.customer_id,
            func.count(Order.id).label('total_orders'),
            func.sum(
                case(
                    (Order.payment_status == PaymentStatus.PAID, Order.total_amount),
                    else_=0
                )
            ).label('total_spent'),
            func.max(Order.order_date).label('last_order_date')
        ).filter(
            Order.business_id == business_id,
            Order.deleted_at.is_(None),
            Order.customer_id.isnot(None)
        )
        
        start_date = self._parse_date(from_date)
        end_date = self._parse_date(to_date)
        
        if start_date:
            query = query.filter(func.date(Order.order_date) >= start_date)
        if end_date:
            query = query.filter(func.date(Order.order_date) <= end_date)
        
        query = query.group_by(Order.customer_id).order_by(
            func.sum(
                case(
                    (Order.payment_status == PaymentStatus.PAID, Order.total_amount),
                    else_=0
                )
            ).desc()
        )
        
        results = query.all()
        
        customer_items = []
        total_revenue = Decimal("0.00")
        
        for result in results:
            customer = self.db.query(Customer).filter(Customer.id == result.customer_id).first()
            if not customer:
                continue
            
            spent = Decimal(str(result.total_spent)) if result.total_spent else Decimal("0.00")
            total_revenue += spent
            
            customer_items.append(CustomerReportItem(
                customer_name=customer.name,
                customer_phone=customer.phone,
                customer_email=customer.email,
                total_orders=int(result.total_orders) if result.total_orders else 0,
                total_spent=spent,
                last_order_date=self._format_date(result.last_order_date)
            ))
        
        return CustomerReportResponse(
            business_name=business_name,
            from_date=from_date,
            to_date=to_date,
            total_customers=len(customer_items),
            total_revenue=total_revenue,
            customers=customer_items
        )
