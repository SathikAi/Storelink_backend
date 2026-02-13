from typing import List, Dict, Tuple
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, extract
from fastapi import HTTPException, status
from datetime import datetime, date, timezone
from dateutil.relativedelta import relativedelta

from app.models.user import User, UserRole
from app.models.business import Business, BusinessPlan
from app.models.product import Product
from app.models.order import Order
from app.models.customer import Customer
from app.models.plan_limit import PlanLimit
from app.schemas.admin import (
    AdminBusinessListItem,
    AdminBusinessDetail,
    AdminUserListItem,
    PlatformStats,
    UpdateBusinessStatusRequest,
    UpdateBusinessPlanRequest,
    UpdateUserStatusRequest
)
from app.services.plan_limit_service import PlanLimitService


class AdminService:
    def __init__(self, db: Session):
        self.db = db
    
    def get_all_businesses(
        self,
        page: int = 1,
        page_size: int = 20,
        search: str = None,
        plan: str = None,
        is_active: bool = None
    ) -> Tuple[List[AdminBusinessListItem], Dict]:
        query = self.db.query(
            Business,
            User.full_name.label('owner_name')
        ).join(
            User, Business.owner_id == User.id
        ).filter(
            Business.deleted_at.is_(None)
        )
        
        if search:
            search_filter = f"%{search}%"
            query = query.filter(
                (Business.business_name.like(search_filter)) |
                (Business.phone.like(search_filter)) |
                (User.full_name.like(search_filter))
            )
        
        if plan:
            query = query.filter(Business.plan == plan)
        
        if is_active is not None:
            query = query.filter(Business.is_active == is_active)
        
        query = query.order_by(Business.created_at.desc())
        
        total_items = query.count()
        total_pages = (total_items + page_size - 1) // page_size
        
        offset = (page - 1) * page_size
        results = query.offset(offset).limit(page_size).all()
        
        business_list = []
        for business, owner_name in results:
            total_products = self.db.query(func.count(Product.id)).filter(
                Product.business_id == business.id,
                Product.deleted_at.is_(None)
            ).scalar() or 0
            
            total_orders = self.db.query(func.count(Order.id)).filter(
                Order.business_id == business.id,
                Order.deleted_at.is_(None)
            ).scalar() or 0
            
            total_revenue = self.db.query(func.sum(Order.total_amount)).filter(
                Order.business_id == business.id,
                Order.payment_status == "PAID",
                Order.deleted_at.is_(None)
            ).scalar() or 0.0
            
            business_list.append(AdminBusinessListItem(
                uuid=business.uuid,
                business_name=business.business_name,
                owner_name=owner_name,
                phone=business.phone,
                email=business.email,
                plan=business.plan.value,
                plan_expiry_date=business.plan_expiry_date,
                is_active=business.is_active,
                created_at=business.created_at,
                total_products=total_products,
                total_orders=total_orders,
                total_revenue=float(total_revenue)
            ))
        
        pagination = {
            "page": page,
            "page_size": page_size,
            "total_items": total_items,
            "total_pages": total_pages
        }
        
        return business_list, pagination
    
    def get_business_detail(self, business_uuid: str) -> AdminBusinessDetail:
        result = self.db.query(
            Business,
            User.uuid.label('owner_uuid'),
            User.full_name.label('owner_name'),
            User.phone.label('owner_phone'),
            User.email.label('owner_email')
        ).join(
            User, Business.owner_id == User.id
        ).filter(
            Business.uuid == business_uuid,
            Business.deleted_at.is_(None)
        ).first()
        
        if not result:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Business not found"
            )
        
        business = result[0]
        owner_uuid = result[1]
        owner_name = result[2]
        owner_phone = result[3]
        owner_email = result[4]
        
        total_products = self.db.query(func.count(Product.id)).filter(
            Product.business_id == business.id,
            Product.deleted_at.is_(None)
        ).scalar() or 0
        
        total_orders = self.db.query(func.count(Order.id)).filter(
            Order.business_id == business.id,
            Order.deleted_at.is_(None)
        ).scalar() or 0
        
        total_customers = self.db.query(func.count(Customer.id)).filter(
            Customer.business_id == business.id,
            Customer.deleted_at.is_(None)
        ).scalar() or 0
        
        total_revenue = self.db.query(func.sum(Order.total_amount)).filter(
            Order.business_id == business.id,
            Order.payment_status == "PAID",
            Order.deleted_at.is_(None)
        ).scalar() or 0.0
        
        return AdminBusinessDetail(
            uuid=business.uuid,
            business_name=business.business_name,
            business_type=business.business_type,
            phone=business.phone,
            email=business.email,
            address=business.address,
            city=business.city,
            state=business.state,
            pincode=business.pincode,
            gstin=business.gstin,
            logo_url=business.logo_url,
            plan=business.plan.value,
            plan_expiry_date=business.plan_expiry_date,
            is_active=business.is_active,
            created_at=business.created_at,
            updated_at=business.updated_at,
            owner_uuid=owner_uuid,
            owner_name=owner_name,
            owner_phone=owner_phone,
            owner_email=owner_email,
            total_products=total_products,
            total_orders=total_orders,
            total_customers=total_customers,
            total_revenue=float(total_revenue)
        )
    
    def update_business_status(self, business_uuid: str, data: UpdateBusinessStatusRequest) -> None:
        business = self.db.query(Business).filter(
            Business.uuid == business_uuid,
            Business.deleted_at.is_(None)
        ).first()
        
        if not business:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Business not found"
            )
        
        business.is_active = data.is_active
        self.db.commit()
    
    def update_business_plan(self, business_uuid: str, data: UpdateBusinessPlanRequest) -> None:
        business = self.db.query(Business).filter(
            Business.uuid == business_uuid,
            Business.deleted_at.is_(None)
        ).first()
        
        if not business:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Business not found"
            )
        
        old_plan = business.plan
        business.plan = BusinessPlan(data.plan.value)
        business.plan_expiry_date = data.plan_expiry_date
        
        if old_plan != business.plan:
            PlanLimitService.initialize_plan_limits(self.db, business.id, business.plan)
        
        self.db.commit()
    
    def get_all_users(
        self,
        page: int = 1,
        page_size: int = 20,
        search: str = None,
        role: str = None,
        is_active: bool = None
    ) -> Tuple[List[AdminUserListItem], Dict]:
        query = self.db.query(User).filter(
            User.deleted_at.is_(None)
        )
        
        if search:
            search_filter = f"%{search}%"
            query = query.filter(
                (User.full_name.like(search_filter)) |
                (User.phone.like(search_filter)) |
                (User.email.like(search_filter))
            )
        
        if role:
            query = query.filter(User.role == role)
        
        if is_active is not None:
            query = query.filter(User.is_active == is_active)
        
        query = query.order_by(User.created_at.desc())
        
        total_items = query.count()
        total_pages = (total_items + page_size - 1) // page_size
        
        offset = (page - 1) * page_size
        users = query.offset(offset).limit(page_size).all()
        
        user_list = []
        for user in users:
            business_count = self.db.query(func.count(Business.id)).filter(
                Business.owner_id == user.id,
                Business.deleted_at.is_(None)
            ).scalar() or 0
            
            user_list.append(AdminUserListItem(
                uuid=user.uuid,
                full_name=user.full_name,
                phone=user.phone,
                email=user.email,
                role=user.role.value,
                is_active=user.is_active,
                is_verified=user.is_verified,
                created_at=user.created_at,
                business_count=business_count
            ))
        
        pagination = {
            "page": page,
            "page_size": page_size,
            "total_items": total_items,
            "total_pages": total_pages
        }
        
        return user_list, pagination
    
    def update_user_status(self, user_uuid: str, data: UpdateUserStatusRequest) -> None:
        user = self.db.query(User).filter(
            User.uuid == user_uuid,
            User.deleted_at.is_(None)
        ).first()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        if user.role == UserRole.SUPER_ADMIN:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Cannot modify SUPER_ADMIN status"
            )
        
        user.is_active = data.is_active
        
        if not data.is_active:
            businesses = self.db.query(Business).filter(
                Business.owner_id == user.id,
                Business.deleted_at.is_(None)
            ).all()
            
            for business in businesses:
                business.is_active = False
        
        self.db.commit()
    
    def get_platform_statistics(self) -> PlatformStats:
        total_businesses = self.db.query(func.count(Business.id)).filter(
            Business.deleted_at.is_(None)
        ).scalar() or 0
        
        active_businesses = self.db.query(func.count(Business.id)).filter(
            Business.is_active == True,
            Business.deleted_at.is_(None)
        ).scalar() or 0
        
        inactive_businesses = total_businesses - active_businesses
        
        free_plan_businesses = self.db.query(func.count(Business.id)).filter(
            Business.plan == BusinessPlan.FREE,
            Business.deleted_at.is_(None)
        ).scalar() or 0
        
        paid_plan_businesses = self.db.query(func.count(Business.id)).filter(
            Business.plan == BusinessPlan.PAID,
            Business.deleted_at.is_(None)
        ).scalar() or 0
        
        total_users = self.db.query(func.count(User.id)).filter(
            User.deleted_at.is_(None)
        ).scalar() or 0
        
        active_users = self.db.query(func.count(User.id)).filter(
            User.is_active == True,
            User.deleted_at.is_(None)
        ).scalar() or 0
        
        super_admins = self.db.query(func.count(User.id)).filter(
            User.role == UserRole.SUPER_ADMIN,
            User.deleted_at.is_(None)
        ).scalar() or 0
        
        business_owners = self.db.query(func.count(User.id)).filter(
            User.role == UserRole.BUSINESS_OWNER,
            User.deleted_at.is_(None)
        ).scalar() or 0
        
        total_products = self.db.query(func.count(Product.id)).filter(
            Product.deleted_at.is_(None)
        ).scalar() or 0
        
        total_orders = self.db.query(func.count(Order.id)).filter(
            Order.deleted_at.is_(None)
        ).scalar() or 0
        
        total_customers = self.db.query(func.count(Customer.id)).filter(
            Customer.deleted_at.is_(None)
        ).scalar() or 0
        
        total_revenue = self.db.query(func.sum(Order.total_amount)).filter(
            Order.payment_status == "PAID",
            Order.deleted_at.is_(None)
        ).scalar() or 0.0
        
        current_month_start = datetime.now(timezone.utc).replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        
        revenue_this_month = self.db.query(func.sum(Order.total_amount)).filter(
            Order.payment_status == "PAID",
            Order.order_date >= current_month_start,
            Order.deleted_at.is_(None)
        ).scalar() or 0.0
        
        new_businesses_this_month = self.db.query(func.count(Business.id)).filter(
            Business.created_at >= current_month_start,
            Business.deleted_at.is_(None)
        ).scalar() or 0
        
        new_users_this_month = self.db.query(func.count(User.id)).filter(
            User.created_at >= current_month_start,
            User.deleted_at.is_(None)
        ).scalar() or 0
        
        return PlatformStats(
            total_businesses=total_businesses,
            active_businesses=active_businesses,
            inactive_businesses=inactive_businesses,
            free_plan_businesses=free_plan_businesses,
            paid_plan_businesses=paid_plan_businesses,
            total_users=total_users,
            active_users=active_users,
            super_admins=super_admins,
            business_owners=business_owners,
            total_products=total_products,
            total_orders=total_orders,
            total_customers=total_customers,
            total_revenue=float(total_revenue),
            revenue_this_month=float(revenue_this_month),
            new_businesses_this_month=new_businesses_this_month,
            new_users_this_month=new_users_this_month
        )
