from typing import Optional
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import date, datetime, timedelta
from decimal import Decimal
from app.models.product import Product
from app.models.order import Order, OrderStatus, PaymentStatus
from app.models.customer import Customer
from app.models.business import Business, BusinessPlan
from app.config import settings


class DashboardService:
    def __init__(self, db: Session):
        self.db = db
    
    def get_dashboard_stats(
        self,
        business_id: int,
        from_date: Optional[date] = None,
        to_date: Optional[date] = None
    ) -> dict:
        business = self.db.query(Business).filter(Business.id == business_id).first()
        if not business:
            return {}
        
        is_paid = business.plan == BusinessPlan.PAID
        
        if not from_date:
            from_date = date.today() - timedelta(days=30)
        if not to_date:
            to_date = date.today()
        
        total_products = self.db.query(func.count(Product.id)).filter(
            Product.business_id == business_id,
            Product.deleted_at.is_(None)
        ).scalar() or 0
        
        active_products = self.db.query(func.count(Product.id)).filter(
            Product.business_id == business_id,
            Product.deleted_at.is_(None),
            Product.is_active == True
        ).scalar() or 0
        
        low_stock_products = self.db.query(func.count(Product.id)).filter(
            Product.business_id == business_id,
            Product.deleted_at.is_(None),
            Product.is_active == True,
            Product.stock_quantity < settings.LOW_STOCK_THRESHOLD
        ).scalar() or 0
        
        total_customers = self.db.query(func.count(Customer.id)).filter(
            Customer.business_id == business_id,
            Customer.deleted_at.is_(None)
        ).scalar() or 0
        
        active_customers = self.db.query(func.count(Customer.id)).filter(
            Customer.business_id == business_id,
            Customer.deleted_at.is_(None),
            Customer.is_active == True
        ).scalar() or 0
        
        order_query = self.db.query(Order).filter(
            Order.business_id == business_id,
            Order.deleted_at.is_(None),
            func.date(Order.order_date) >= from_date,
            func.date(Order.order_date) <= to_date
        )
        
        total_orders = order_query.count()
        
        pending_orders = order_query.filter(
            Order.status == OrderStatus.PENDING
        ).count()
        
        processing_orders = order_query.filter(
            Order.status == OrderStatus.PROCESSING
        ).count()
        
        completed_orders = order_query.filter(
            Order.status == OrderStatus.DELIVERED
        ).count()
        
        cancelled_orders = order_query.filter(
            Order.status == OrderStatus.CANCELLED
        ).count()
        
        total_revenue = order_query.with_entities(
            func.sum(Order.total_amount)
        ).filter(
            Order.payment_status == PaymentStatus.PAID
        ).scalar() or Decimal("0.00")
        
        pending_revenue = order_query.with_entities(
            func.sum(Order.total_amount)
        ).filter(
            Order.payment_status == PaymentStatus.PENDING
        ).scalar() or Decimal("0.00")
        
        base_stats = {
            "period": {
                "from_date": from_date.isoformat(),
                "to_date": to_date.isoformat()
            },
            "products": {
                "total": total_products,
                "active": active_products,
                "low_stock": low_stock_products
            },
            "customers": {
                "total": total_customers,
                "active": active_customers
            },
            "orders": {
                "total": total_orders,
                "pending": pending_orders,
                "processing": processing_orders,
                "completed": completed_orders,
                "cancelled": cancelled_orders
            },
            "revenue": {
                "total": float(total_revenue),
                "pending": float(pending_revenue)
            }
        }
        
        if is_paid:
            daily_sales = self._get_daily_sales(business_id, from_date, to_date)
            top_products = self._get_top_products(business_id, from_date, to_date)
            recent_orders = self._get_recent_orders(business_id, limit=10)
            
            base_stats["daily_sales"] = daily_sales
            base_stats["top_products"] = top_products
            base_stats["recent_orders"] = recent_orders
        
        return base_stats
    
    def _get_daily_sales(
        self,
        business_id: int,
        from_date: date,
        to_date: date
    ) -> list:
        results = self.db.query(
            func.date(Order.order_date).label('date'),
            func.count(Order.id).label('order_count'),
            func.sum(Order.total_amount).label('revenue')
        ).filter(
            Order.business_id == business_id,
            Order.deleted_at.is_(None),
            Order.payment_status == PaymentStatus.PAID,
            func.date(Order.order_date) >= from_date,
            func.date(Order.order_date) <= to_date
        ).group_by(
            func.date(Order.order_date)
        ).order_by(
            func.date(Order.order_date)
        ).all()
        
        return [
            {
                "date": result.date.isoformat(),
                "order_count": result.order_count,
                "revenue": float(result.revenue or 0)
            }
            for result in results
        ]
    
    def _get_top_products(
        self,
        business_id: int,
        from_date: date,
        to_date: date,
        limit: int = 10
    ) -> list:
        from app.models.order import OrderItem
        
        results = self.db.query(
            Product.uuid,
            Product.name,
            Product.sku,
            func.sum(OrderItem.quantity).label('quantity_sold'),
            func.sum(OrderItem.total_price).label('revenue')
        ).join(
            OrderItem, OrderItem.product_id == Product.id
        ).join(
            Order, Order.id == OrderItem.order_id
        ).filter(
            Product.business_id == business_id,
            Product.deleted_at.is_(None),
            Order.deleted_at.is_(None),
            func.date(Order.order_date) >= from_date,
            func.date(Order.order_date) <= to_date
        ).group_by(
            Product.id, Product.uuid, Product.name, Product.sku
        ).order_by(
            func.sum(OrderItem.quantity).desc()
        ).limit(limit).all()
        
        return [
            {
                "product_uuid": result.uuid,
                "product_name": result.name,
                "product_sku": result.sku,
                "quantity_sold": int(result.quantity_sold or 0),
                "revenue": float(result.revenue or 0)
            }
            for result in results
        ]
    
    def _get_recent_orders(self, business_id: int, limit: int = 10) -> list:
        orders = self.db.query(Order).filter(
            Order.business_id == business_id,
            Order.deleted_at.is_(None)
        ).order_by(
            Order.created_at.desc()
        ).limit(limit).all()
        
        return [
            {
                "order_uuid": order.uuid,
                "order_number": order.order_number,
                "status": order.status.value,
                "payment_status": order.payment_status.value,
                "total_amount": float(order.total_amount),
                "order_date": order.order_date.isoformat()
            }
            for order in orders
        ]
