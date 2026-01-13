from typing import Optional, Dict
from sqlalchemy.orm import Session
from sqlalchemy import func
from fastapi import HTTPException, status, UploadFile
from app.models.business import Business
from app.models.product import Product
from app.models.order import Order
from app.models.customer import Customer
from app.schemas.business import BusinessUpdateRequest
from app.services.plan_limit_service import PlanLimitService
from app.services.file_upload_service import FileUploadService


class BusinessService:
    def __init__(self, db: Session):
        self.db = db
    
    def get_business_by_id(self, business_id: int) -> Business:
        business = self.db.query(Business).filter(
            Business.id == business_id,
            Business.deleted_at.is_(None)
        ).first()
        
        if not business:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Business not found"
            )
        
        return business
    
    def get_business_by_uuid(self, business_uuid: str) -> Business:
        business = self.db.query(Business).filter(
            Business.uuid == business_uuid,
            Business.deleted_at.is_(None)
        ).first()
        
        if not business:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Business not found"
            )
        
        return business
    
    def update_business_profile(self, business_id: int, data: BusinessUpdateRequest) -> Business:
        business = self.get_business_by_id(business_id)
        
        update_data = data.model_dump(exclude_unset=True)
        
        if "phone" in update_data and update_data["phone"] != business.phone:
            existing = self.db.query(Business).filter(
                Business.phone == update_data["phone"],
                Business.id != business_id,
                Business.deleted_at.is_(None)
            ).first()
            
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Phone number already in use by another business"
                )
        
        if "email" in update_data and update_data["email"]:
            existing = self.db.query(Business).filter(
                Business.email == update_data["email"],
                Business.id != business_id,
                Business.deleted_at.is_(None)
            ).first()
            
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Email already in use by another business"
                )
        
        for key, value in update_data.items():
            setattr(business, key, value)
        
        self.db.commit()
        self.db.refresh(business)
        return business
    
    async def upload_logo(self, business_id: int, file: UploadFile) -> str:
        business = self.get_business_by_id(business_id)
        
        if business.logo_url:
            old_logo_path = business.logo_url.replace("/uploads/", "")
            FileUploadService.delete_file(old_logo_path)
        
        file_path, relative_path = await FileUploadService.save_image(file, folder="logos", max_width=500)
        
        business.logo_url = FileUploadService.get_file_url(relative_path)
        self.db.commit()
        self.db.refresh(business)
        
        return business.logo_url
    
    def get_business_stats(self, business_id: int) -> Dict:
        business = self.get_business_by_id(business_id)
        
        total_products = self.db.query(func.count(Product.id)).filter(
            Product.business_id == business_id,
            Product.deleted_at.is_(None)
        ).scalar() or 0
        
        active_products = self.db.query(func.count(Product.id)).filter(
            Product.business_id == business_id,
            Product.is_active == True,
            Product.deleted_at.is_(None)
        ).scalar() or 0
        
        total_orders = self.db.query(func.count(Order.id)).filter(
            Order.business_id == business_id,
            Order.deleted_at.is_(None)
        ).scalar() or 0
        
        total_customers = self.db.query(func.count(Customer.id)).filter(
            Customer.business_id == business_id,
            Customer.deleted_at.is_(None)
        ).scalar() or 0
        
        total_revenue = self.db.query(func.sum(Order.total_amount)).filter(
            Order.business_id == business_id,
            Order.payment_status == "PAID",
            Order.deleted_at.is_(None)
        ).scalar() or 0.0
        
        plan_limits = PlanLimitService.get_plan_limits_dict(self.db, business_id)
        
        return {
            "total_products": total_products,
            "active_products": active_products,
            "total_orders": total_orders,
            "total_customers": total_customers,
            "total_revenue": float(total_revenue),
            "plan": business.plan.value,
            "plan_limits": plan_limits
        }
