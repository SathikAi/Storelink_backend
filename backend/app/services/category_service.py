from typing import List, Tuple, Optional
from datetime import datetime, timezone
from sqlalchemy.orm import Session
from sqlalchemy import func
from fastapi import HTTPException, status
from app.models.category import Category
from app.schemas.category import CategoryCreateRequest, CategoryUpdateRequest
from app.services.plan_limit_service import PlanLimitService


class CategoryService:
    def __init__(self, db: Session):
        self.db = db
    
    def create_category(self, business_id: int, data: CategoryCreateRequest) -> Category:
        # Check category limit for FREE plan
        current_count = self.db.query(func.count(Category.id)).filter(
            Category.business_id == business_id,
            Category.deleted_at.is_(None)
        ).scalar() or 0

        can_create, max_cats = PlanLimitService.check_category_limit(self.db, business_id, current_count)
        if not can_create:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail={
                    "code": "CATEGORY_LIMIT_EXCEEDED",
                    "message": f"Free plan allows only {max_cats} categories. Upgrade to PRO for unlimited.",
                    "current": current_count,
                    "limit": max_cats
                }
            )

        existing = self.db.query(Category).filter(
            Category.business_id == business_id,
            Category.name == data.name,
            Category.deleted_at.is_(None)
        ).first()

        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Category with name '{data.name}' already exists"
            )
        
        category = Category(
            business_id=business_id,
            name=data.name,
            description=data.description,
            is_active=data.is_active
        )
        
        self.db.add(category)
        self.db.commit()
        self.db.refresh(category)
        return category
    
    def get_categories(
        self, 
        business_id: int, 
        page: int = 1, 
        page_size: int = 50,
        is_active: Optional[bool] = None
    ) -> Tuple[List[Category], int]:
        query = self.db.query(Category).filter(
            Category.business_id == business_id,
            Category.deleted_at.is_(None)
        )
        
        if is_active is not None:
            query = query.filter(Category.is_active == is_active)
        
        total = query.count()
        
        categories = query.order_by(Category.created_at.desc()).offset(
            (page - 1) * page_size
        ).limit(page_size).all()
        
        return categories, total
    
    def get_category_by_uuid(self, business_id: int, category_uuid: str) -> Category:
        category = self.db.query(Category).filter(
            Category.uuid == category_uuid,
            Category.business_id == business_id,
            Category.deleted_at.is_(None)
        ).first()
        
        if not category:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Category not found"
            )
        
        return category
    
    def update_category(
        self, 
        business_id: int, 
        category_uuid: str, 
        data: CategoryUpdateRequest
    ) -> Category:
        category = self.get_category_by_uuid(business_id, category_uuid)
        
        update_data = data.model_dump(exclude_unset=True)
        
        if "name" in update_data and update_data["name"] != category.name:
            existing = self.db.query(Category).filter(
                Category.business_id == business_id,
                Category.name == update_data["name"],
                Category.id != category.id,
                Category.deleted_at.is_(None)
            ).first()
            
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Category with name '{update_data['name']}' already exists"
                )
        
        for key, value in update_data.items():
            setattr(category, key, value)
        
        self.db.commit()
        self.db.refresh(category)
        return category
    
    def delete_category(self, business_id: int, category_uuid: str) -> None:
        category = self.get_category_by_uuid(business_id, category_uuid)
        
        category.deleted_at = datetime.now(timezone.utc)
        self.db.commit()
