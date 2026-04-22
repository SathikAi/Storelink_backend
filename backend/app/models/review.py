from sqlalchemy import Column, BigInteger, String, Integer, TIMESTAMP, ForeignKey, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import uuid

class BusinessReview(Base):
    __tablename__ = "business_reviews"

    id = Column(BigInteger, primary_key=True, autoincrement=True, index=True)
    uuid = Column(String(36), unique=True, nullable=False, default=lambda: str(uuid.uuid4()), index=True)
    business_id = Column(BigInteger, ForeignKey("businesses.id"), nullable=False)
    order_id = Column(BigInteger, ForeignKey("orders.id"), nullable=True) # Optional link to a specific order
    customer_name = Column(String(255), nullable=False)
    rating = Column(Integer, nullable=False) # 1 - 5 stars
    comment = Column(Text, nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())

    business = relationship("Business")
    order = relationship("Order")
