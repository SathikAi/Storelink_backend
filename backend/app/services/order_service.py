from typing import List, Tuple, Optional
from sqlalchemy.orm import Session
from sqlalchemy import func, or_, and_
from fastapi import HTTPException, status
from datetime import datetime, date
from decimal import Decimal
from app.models.order import Order, OrderItem, OrderStatus, PaymentStatus
from app.models.product import Product
from app.models.customer import Customer
from app.schemas.order import OrderCreateRequest, OrderUpdateRequest
from app.services.plan_limit_service import PlanLimitService


class OrderService:
    def __init__(self, db: Session):
        self.db = db
    
    def _generate_order_number(self, business_id: int) -> str:
        today = datetime.now().strftime("%Y%m%d")
        
        count = self.db.query(func.count(Order.id)).filter(
            Order.business_id == business_id,
            func.date(Order.order_date) == date.today()
        ).scalar() or 0
        
        sequence = count + 1
        return f"ORD{today}{sequence:04d}"
    
    def create_order(self, business_id: int, data: OrderCreateRequest) -> Order:
        current_count = self.db.query(func.count(Order.id)).filter(
            Order.business_id == business_id,
            Order.deleted_at.is_(None)
        ).scalar() or 0
        
        can_create, limit = PlanLimitService.check_limit(
            self.db, business_id, "orders", current_count
        )
        
        if not can_create:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail={
                    "code": "ORDER_LIMIT_EXCEEDED",
                    "message": f"Free plan allows only {limit} orders. Upgrade to PAID plan.",
                    "current": current_count,
                    "limit": limit
                }
            )
        
        customer_id = None
        if data.customer_uuid:
            customer = self.db.query(Customer).filter(
                Customer.uuid == data.customer_uuid,
                Customer.business_id == business_id,
                Customer.deleted_at.is_(None)
            ).first()
            
            if not customer:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Customer not found"
                )
            customer_id = customer.id
        
        try:
            self.db.begin_nested()
            
            order_items_data = []
            subtotal = Decimal("0.00")
            
            for item_data in data.items:
                product = self.db.query(Product).filter(
                    Product.uuid == item_data.product_uuid,
                    Product.business_id == business_id,
                    Product.deleted_at.is_(None),
                    Product.is_active == True
                ).first()
                
                if not product:
                    raise HTTPException(
                        status_code=status.HTTP_404_NOT_FOUND,
                        detail=f"Product {item_data.product_uuid} not found or inactive"
                    )
                
                if product.stock_quantity < item_data.quantity:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail=f"Insufficient stock for {product.name}. Available: {product.stock_quantity}, Required: {item_data.quantity}"
                    )
                
                product.stock_quantity -= item_data.quantity
                
                item_total = product.price * item_data.quantity
                subtotal += item_total
                
                order_items_data.append({
                    "product_id": product.id,
                    "product_name": product.name,
                    "product_sku": product.sku,
                    "quantity": item_data.quantity,
                    "unit_price": product.price,
                    "total_price": item_total
                })
            
            total_amount = subtotal + data.tax_amount - data.discount_amount
            
            if total_amount < 0:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Total amount cannot be negative"
                )
            
            order = Order(
                business_id=business_id,
                customer_id=customer_id,
                order_number=self._generate_order_number(business_id),
                status=OrderStatus.PENDING,
                payment_status=PaymentStatus.PENDING,
                subtotal=subtotal,
                tax_amount=data.tax_amount,
                discount_amount=data.discount_amount,
                total_amount=total_amount,
                payment_method=data.payment_method,
                notes=data.notes
            )
            
            self.db.add(order)
            self.db.flush()
            
            for item_data in order_items_data:
                order_item = OrderItem(
                    order_id=order.id,
                    **item_data
                )
                self.db.add(order_item)
            
            self.db.commit()
            self.db.refresh(order)
            
            return self.get_order_by_uuid(business_id, order.uuid)
        
        except HTTPException:
            self.db.rollback()
            raise
        except Exception as e:
            self.db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to create order: {str(e)}"
            )
    
    def get_orders(
        self,
        business_id: int,
        page: int = 1,
        page_size: int = 50,
        customer_uuid: Optional[str] = None,
        status: Optional[str] = None,
        payment_status: Optional[str] = None,
        search: Optional[str] = None,
        from_date: Optional[date] = None,
        to_date: Optional[date] = None
    ) -> Tuple[List[Order], int]:
        query = self.db.query(Order).filter(
            Order.business_id == business_id,
            Order.deleted_at.is_(None)
        )
        
        if customer_uuid:
            customer = self.db.query(Customer).filter(
                Customer.uuid == customer_uuid,
                Customer.business_id == business_id
            ).first()
            if customer:
                query = query.filter(Order.customer_id == customer.id)
        
        if status:
            query = query.filter(Order.status == status)
        
        if payment_status:
            query = query.filter(Order.payment_status == payment_status)
        
        if search:
            search_pattern = f"%{search}%"
            query = query.filter(Order.order_number.ilike(search_pattern))
        
        if from_date:
            query = query.filter(func.date(Order.order_date) >= from_date)
        
        if to_date:
            query = query.filter(func.date(Order.order_date) <= to_date)
        
        total = query.count()
        
        orders = query.order_by(Order.created_at.desc()).offset(
            (page - 1) * page_size
        ).limit(page_size).all()
        
        for order in orders:
            order.items = self.db.query(OrderItem).filter(
                OrderItem.order_id == order.id
            ).all()
        
        return orders, total
    
    def get_order_by_uuid(self, business_id: int, order_uuid: str) -> Order:
        order = self.db.query(Order).filter(
            Order.uuid == order_uuid,
            Order.business_id == business_id,
            Order.deleted_at.is_(None)
        ).first()
        
        if not order:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Order not found"
            )
        
        order.items = self.db.query(OrderItem).filter(
            OrderItem.order_id == order.id
        ).all()
        
        return order
    
    def update_order(
        self,
        business_id: int,
        order_uuid: str,
        data: OrderUpdateRequest
    ) -> Order:
        order = self.get_order_by_uuid(business_id, order_uuid)
        
        update_data = data.model_dump(exclude_unset=True)
        
        if "status" in update_data:
            try:
                OrderStatus(update_data["status"])
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Invalid status: {update_data['status']}"
                )
        
        if "payment_status" in update_data:
            try:
                PaymentStatus(update_data["payment_status"])
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Invalid payment status: {update_data['payment_status']}"
                )
        
        for key, value in update_data.items():
            setattr(order, key, value)
        
        self.db.commit()
        self.db.refresh(order)
        
        return self.get_order_by_uuid(business_id, order.uuid)
    
    def cancel_order(self, business_id: int, order_uuid: str) -> Order:
        order = self.get_order_by_uuid(business_id, order_uuid)
        
        if order.status in [OrderStatus.DELIVERED, OrderStatus.CANCELLED]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot cancel order with status {order.status}"
            )
        
        try:
            self.db.begin_nested()
            
            order_items = self.db.query(OrderItem).filter(
                OrderItem.order_id == order.id
            ).all()
            
            for item in order_items:
                if item.product_id:
                    product = self.db.query(Product).filter(
                        Product.id == item.product_id,
                        Product.deleted_at.is_(None)
                    ).first()
                    
                    if product:
                        product.stock_quantity += item.quantity
            
            order.status = OrderStatus.CANCELLED
            
            self.db.commit()
            self.db.refresh(order)
            
            return self.get_order_by_uuid(business_id, order.uuid)
        
        except Exception as e:
            self.db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to cancel order: {str(e)}"
            )
    
    def delete_order(self, business_id: int, order_uuid: str) -> None:
        order = self.get_order_by_uuid(business_id, order_uuid)
        
        order.deleted_at = func.now()
        self.db.commit()
    
    def get_order_stats(
        self,
        business_id: int,
        from_date: Optional[date] = None,
        to_date: Optional[date] = None
    ) -> dict:
        query = self.db.query(Order).filter(
            Order.business_id == business_id,
            Order.deleted_at.is_(None)
        )
        
        if from_date:
            query = query.filter(func.date(Order.order_date) >= from_date)
        
        if to_date:
            query = query.filter(func.date(Order.order_date) <= to_date)
        
        total_orders = query.count()
        
        total_revenue = query.with_entities(
            func.sum(Order.total_amount)
        ).filter(
            Order.payment_status == PaymentStatus.PAID
        ).scalar() or Decimal("0.00")
        
        pending_orders = query.filter(
            Order.status == OrderStatus.PENDING
        ).count()
        
        completed_orders = query.filter(
            Order.status == OrderStatus.DELIVERED
        ).count()
        
        return {
            "total_orders": total_orders,
            "total_revenue": total_revenue,
            "pending_orders": pending_orders,
            "completed_orders": completed_orders
        }
