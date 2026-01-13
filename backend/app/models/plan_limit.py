from sqlalchemy import Column, BigInteger, Integer, TIMESTAMP, ForeignKey, JSON
from sqlalchemy.sql import func
from app.database import Base


class PlanLimit(Base):
    __tablename__ = "plan_limits"

    id = Column(BigInteger, primary_key=True, autoincrement=True, index=True)
    business_id = Column(BigInteger, ForeignKey('businesses.id', ondelete='CASCADE'), unique=True, nullable=False, index=True)
    max_products = Column(Integer, nullable=True)
    max_orders = Column(Integer, nullable=True)
    max_customers = Column(Integer, nullable=True)
    features = Column(JSON, nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp(), onupdate=func.current_timestamp())
