from typing import List, Tuple, Optional
from sqlalchemy.orm import Session
from sqlalchemy import func, or_
from fastapi import HTTPException, status
from app.models.customer import Customer
from app.schemas.customer import CustomerCreateRequest, CustomerUpdateRequest


class CustomerService:
    def __init__(self, db: Session):
        self.db = db
    
    def create_customer(self, business_id: int, data: CustomerCreateRequest) -> Customer:
        existing = self.db.query(Customer).filter(
            Customer.business_id == business_id,
            Customer.phone == data.phone,
            Customer.deleted_at.is_(None)
        ).first()
        
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Customer with phone '{data.phone}' already exists"
            )
        
        customer = Customer(
            business_id=business_id,
            name=data.name,
            phone=data.phone,
            email=data.email,
            address=data.address,
            city=data.city,
            state=data.state,
            pincode=data.pincode,
            notes=data.notes,
            is_active=data.is_active
        )
        
        self.db.add(customer)
        self.db.commit()
        self.db.refresh(customer)
        return customer
    
    def get_customers(
        self, 
        business_id: int, 
        page: int = 1, 
        page_size: int = 50,
        is_active: Optional[bool] = None,
        search: Optional[str] = None
    ) -> Tuple[List[Customer], int]:
        query = self.db.query(Customer).filter(
            Customer.business_id == business_id,
            Customer.deleted_at.is_(None)
        )
        
        if is_active is not None:
            query = query.filter(Customer.is_active == is_active)
        
        if search:
            search_pattern = f"%{search}%"
            query = query.filter(
                or_(
                    Customer.name.ilike(search_pattern),
                    Customer.phone.ilike(search_pattern),
                    Customer.email.ilike(search_pattern),
                    Customer.city.ilike(search_pattern)
                )
            )
        
        total = query.count()
        
        customers = query.order_by(Customer.created_at.desc()).offset(
            (page - 1) * page_size
        ).limit(page_size).all()
        
        return customers, total
    
    def get_customer_by_uuid(self, business_id: int, customer_uuid: str) -> Customer:
        customer = self.db.query(Customer).filter(
            Customer.uuid == customer_uuid,
            Customer.business_id == business_id,
            Customer.deleted_at.is_(None)
        ).first()
        
        if not customer:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Customer not found"
            )
        
        return customer
    
    def update_customer(
        self, 
        business_id: int, 
        customer_uuid: str, 
        data: CustomerUpdateRequest
    ) -> Customer:
        customer = self.get_customer_by_uuid(business_id, customer_uuid)
        
        update_data = data.model_dump(exclude_unset=True)
        
        if "phone" in update_data and update_data["phone"] != customer.phone:
            existing = self.db.query(Customer).filter(
                Customer.business_id == business_id,
                Customer.phone == update_data["phone"],
                Customer.id != customer.id,
                Customer.deleted_at.is_(None)
            ).first()
            
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Customer with phone '{update_data['phone']}' already exists"
                )
        
        for key, value in update_data.items():
            setattr(customer, key, value)
        
        self.db.commit()
        self.db.refresh(customer)
        return customer
    
    def delete_customer(self, business_id: int, customer_uuid: str) -> None:
        customer = self.get_customer_by_uuid(business_id, customer_uuid)
        
        customer.deleted_at = func.now()
        self.db.commit()
