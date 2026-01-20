from sqlalchemy import Column, BigInteger, String, Boolean, TIMESTAMP, Enum, Index
from sqlalchemy.sql import func
from app.database import Base
import enum


class OTPPurpose(str, enum.Enum):
    LOGIN = "LOGIN"
    REGISTRATION = "REGISTRATION"
    PASSWORD_RESET = "PASSWORD_RESET"


class OTPVerification(Base):
    __tablename__ = "otp_verifications"

    id = Column(BigInteger, primary_key=True, autoincrement=True, index=True)
    phone = Column(String(15), nullable=False)
    otp_code = Column(String(6), nullable=False)
    purpose = Column(Enum(OTPPurpose), nullable=False)
    is_verified = Column(Boolean, default=False)
    failed_attempts = Column(BigInteger, default=0)
    expires_at = Column(TIMESTAMP, nullable=False, index=True)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())

    __table_args__ = (
        Index('idx_phone_purpose', 'phone', 'purpose'),
    )
