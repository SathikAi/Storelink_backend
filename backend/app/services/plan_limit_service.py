from sqlalchemy.orm import Session
from app.models.plan_limit import PlanLimit
from app.models.business import Business, BusinessPlan
from typing import Optional, Dict


class PlanLimitService:
    
    FREE_PLAN_LIMITS = {
        "max_products": 10,
        "max_orders": 50,
        "max_customers": 50,
        "features": {
            "reports_enabled": False,
            "export_pdf": False,
            "export_csv": False,
            "advanced_dashboard": False,
            "priority_support": False
        }
    }
    
    PAID_PLAN_LIMITS = {
        "max_products": None,
        "max_orders": None,
        "max_customers": None,
        "features": {
            "reports_enabled": True,
            "export_pdf": True,
            "export_csv": True,
            "advanced_dashboard": True,
            "priority_support": True
        }
    }
    
    @staticmethod
    def create_default_limits(db: Session, business_id: int, plan: BusinessPlan) -> PlanLimit:
        limits = PlanLimitService.FREE_PLAN_LIMITS if plan == BusinessPlan.FREE else PlanLimitService.PAID_PLAN_LIMITS
        
        plan_limit = PlanLimit(
            business_id=business_id,
            max_products=limits["max_products"],
            max_orders=limits["max_orders"],
            max_customers=limits["max_customers"],
            features=limits["features"]
        )
        db.add(plan_limit)
        db.commit()
        db.refresh(plan_limit)
        return plan_limit
    
    @staticmethod
    def get_or_create_limits(db: Session, business_id: int) -> PlanLimit:
        plan_limit = db.query(PlanLimit).filter(PlanLimit.business_id == business_id).first()
        if not plan_limit:
            business = db.query(Business).filter(Business.id == business_id).first()
            if business:
                plan_limit = PlanLimitService.create_default_limits(db, business_id, business.plan)
        return plan_limit
    
    @staticmethod
    def get_limits(db: Session, business_id: int) -> Optional[PlanLimit]:
        return db.query(PlanLimit).filter(PlanLimit.business_id == business_id).first()
    
    @staticmethod
    def update_plan_limits(db: Session, business_id: int, new_plan: BusinessPlan) -> PlanLimit:
        plan_limit = db.query(PlanLimit).filter(PlanLimit.business_id == business_id).first()
        
        limits = PlanLimitService.FREE_PLAN_LIMITS if new_plan == BusinessPlan.FREE else PlanLimitService.PAID_PLAN_LIMITS
        
        if plan_limit:
            plan_limit.max_products = limits["max_products"]
            plan_limit.max_orders = limits["max_orders"]
            plan_limit.max_customers = limits["max_customers"]
            plan_limit.features = limits["features"]
        else:
            plan_limit = PlanLimit(
                business_id=business_id,
                max_products=limits["max_products"],
                max_orders=limits["max_orders"],
                max_customers=limits["max_customers"],
                features=limits["features"]
            )
            db.add(plan_limit)
        
        db.commit()
        db.refresh(plan_limit)
        return plan_limit
    
    @staticmethod
    def check_limit(db: Session, business_id: int, resource_type: str, current_count: int) -> tuple[bool, Optional[int]]:
        plan_limit = PlanLimitService.get_or_create_limits(db, business_id)
        
        limit_value = None
        if resource_type == "products":
            limit_value = plan_limit.max_products
        elif resource_type == "orders":
            limit_value = plan_limit.max_orders
        elif resource_type == "customers":
            limit_value = plan_limit.max_customers
        
        if limit_value is None:
            return True, None
        
        return current_count < limit_value, limit_value
    
    @staticmethod
    def check_feature_access(db: Session, business_id: int, feature_name: str) -> bool:
        plan_limit = PlanLimitService.get_or_create_limits(db, business_id)
        
        if plan_limit.features is None:
            return False
        
        return plan_limit.features.get(feature_name, False)
    
    @staticmethod
    def get_plan_limits_dict(db: Session, business_id: int) -> Dict:
        plan_limit = PlanLimitService.get_or_create_limits(db, business_id)
        
        return {
            "max_products": plan_limit.max_products,
            "max_orders": plan_limit.max_orders,
            "max_customers": plan_limit.max_customers,
            "features": plan_limit.features or {}
        }
