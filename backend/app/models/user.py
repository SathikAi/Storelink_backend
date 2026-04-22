from sqlalchemy import Column, BigInteger, String, Boolean, TIMESTAMP, Enum
from sqlalchemy.sql import func
from app.database import Base
import enum
import uuid


class UserRole(str, enum.Enum):
    SUPER_ADMIN = "SUPER_ADMIN"
    BUSINESS_OWNER = "BUSINESS_OWNER"


class User(Base):
    __tablename__ = "users"

    id = Column(BigInteger, primary_key=True, autoincrement=True, index=True)
    uuid = Column(String(36), unique=True, nullable=False, default=lambda: str(uuid.uuid4()), index=True)
    phone = Column(String(15), unique=True, nullable=False, index=True)
    email = Column(String(255), unique=True, nullable=True, index=True)
    password_hash = Column(String(255), nullable=False)
    full_name = Column(String(255), nullable=False)
    role = Column(Enum(UserRole), nullable=False, default=UserRole.BUSINESS_OWNER, index=True)
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    failed_login_attempts = Column(BigInteger, default=0)
    locked_until = Column(TIMESTAMP, nullable=True)
    last_login = Column(TIMESTAMP, nullable=True)          # updated on every successful login
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp(), onupdate=func.current_timestamp())
    deleted_at = Column(TIMESTAMP, nullable=True)
