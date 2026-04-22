"""
Affiliate programme models.

affiliates  — one row per business; stores unique referral_code + earnings
referrals   — one row per (affiliate, referred_business) pair; tracks status
"""
from sqlalchemy import (
    Column, BigInteger, String, Boolean, TIMESTAMP,
    Integer, ForeignKey, Enum as SAEnum,
)
from sqlalchemy.sql import func
from app.database import Base
import enum
import uuid as _uuid


def _gen_code() -> str:
    """8-character uppercase referral code, e.g. 'AB3X7K9Q'."""
    import secrets, string
    return ''.join(
        secrets.choice(string.ascii_uppercase + string.digits)
        for _ in range(8)
    )


class ReferralStatus(str, enum.Enum):
    PENDING  = "PENDING"    # registered but not yet upgraded
    REWARDED = "REWARDED"   # upgraded → referrer already received bonus


class Affiliate(Base):
    """One row per business that participates in the affiliate programme."""
    __tablename__ = "affiliates"

    id            = Column(BigInteger, primary_key=True, autoincrement=True)
    business_id   = Column(BigInteger, ForeignKey("businesses.id", ondelete="CASCADE"),
                           unique=True, nullable=False, index=True)
    referral_code = Column(String(12), unique=True, nullable=False,
                           default=_gen_code, index=True)
    # How many free days a successful referral adds to the referrer's plan
    reward_days   = Column(Integer, nullable=False, default=30)
    total_referrals   = Column(Integer, nullable=False, default=0)
    rewarded_referrals = Column(Integer, nullable=False, default=0)
    is_active     = Column(Boolean, default=True)
    created_at    = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at    = Column(TIMESTAMP, server_default=func.current_timestamp(),
                           onupdate=func.current_timestamp())


class Referral(Base):
    """Tracks each individual referral (affiliate → referred business)."""
    __tablename__ = "referrals"

    id                  = Column(BigInteger, primary_key=True, autoincrement=True)
    affiliate_id        = Column(BigInteger, ForeignKey("affiliates.id", ondelete="CASCADE"),
                                 nullable=False, index=True)
    referred_business_id = Column(BigInteger, ForeignKey("businesses.id", ondelete="CASCADE"),
                                  unique=True, nullable=False, index=True)
    status              = Column(SAEnum(ReferralStatus), default=ReferralStatus.PENDING,
                                 nullable=False, index=True)
    created_at          = Column(TIMESTAMP, server_default=func.current_timestamp())
    rewarded_at         = Column(TIMESTAMP, nullable=True)
