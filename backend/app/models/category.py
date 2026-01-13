from sqlalchemy import Column, BigInteger, String, Boolean, TIMESTAMP, ForeignKey, Text, UniqueConstraint, Index
from sqlalchemy.sql import func
from app.database import Base
import uuid


class Category(Base):
    __tablename__ = "categories"

    id = Column(BigInteger, primary_key=True, autoincrement=True, index=True)
    uuid = Column(String(36), unique=True, nullable=False, default=lambda: str(uuid.uuid4()))
    business_id = Column(BigInteger, ForeignKey('businesses.id', ondelete='CASCADE'), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True, index=True)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp(), onupdate=func.current_timestamp())
    deleted_at = Column(TIMESTAMP, nullable=True)

    __table_args__ = (
        UniqueConstraint('business_id', 'name', 'deleted_at', name='unique_category_per_business'),
    )
