"""
Affiliate programme endpoints.

GET  /affiliate/my-code   → get (or auto-create) the caller's referral code + stats
GET  /affiliate/stats     → same as above, alias
POST /affiliate/validate  → public — check if a referral_code is valid (used at registration)
"""
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session
from typing import Optional

from app.database import get_db
from app.core.dependencies import get_current_user, get_current_business_id
from app.models.user import User
from app.models.business import Business
from app.models.affiliate import Affiliate, Referral, ReferralStatus
from app.utils.logger import logger

router = APIRouter(prefix="/affiliate", tags=["Affiliate"])


# ── Response schemas ──────────────────────────────────────────────────────────

class AffiliateStats(BaseModel):
    referral_code: str
    referral_link: str          # deep-link style  storelink://ref/{code}
    total_referrals: int
    rewarded_referrals: int
    pending_referrals: int
    reward_days_per_referral: int
    total_days_earned: int


class ValidateCodeResponse(BaseModel):
    valid: bool
    message: str


# ── Helpers ───────────────────────────────────────────────────────────────────

def _get_or_create_affiliate(business_id: int, db: Session) -> Affiliate:
    aff = db.query(Affiliate).filter(Affiliate.business_id == business_id).first()
    if not aff:
        aff = Affiliate(business_id=business_id)
        db.add(aff)
        db.commit()
        db.refresh(aff)
    return aff


# ── GET /affiliate/my-code ────────────────────────────────────────────────────

@router.get("/my-code", response_model=AffiliateStats)
async def get_my_referral_code(
    current_user: User = Depends(get_current_user),
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db),
):
    """Return (creating if needed) the caller's affiliate code and stats."""
    aff = _get_or_create_affiliate(business_id, db)

    pending = db.query(Referral).filter(
        Referral.affiliate_id == aff.id,
        Referral.status == ReferralStatus.PENDING,
    ).count()

    return AffiliateStats(
        referral_code=aff.referral_code,
        referral_link=f"storelink://ref/{aff.referral_code}",
        total_referrals=aff.total_referrals,
        rewarded_referrals=aff.rewarded_referrals,
        pending_referrals=pending,
        reward_days_per_referral=aff.reward_days,
        total_days_earned=aff.rewarded_referrals * aff.reward_days,
    )


# Alias
@router.get("/stats", response_model=AffiliateStats)
async def get_affiliate_stats(
    current_user: User = Depends(get_current_user),
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db),
):
    return await get_my_referral_code(current_user, business_id, db)


# ── POST /affiliate/validate ──────────────────────────────────────────────────

@router.post("/validate", response_model=ValidateCodeResponse)
async def validate_referral_code(
    payload: dict,
    db: Session = Depends(get_db),
):
    """
    Public endpoint — called during registration to verify a referral code.
    Expects JSON: {"referral_code": "AB3X7K9Q"}
    """
    code: str = payload.get("referral_code", "").strip().upper()
    if not code:
        return ValidateCodeResponse(valid=False, message="No code provided")

    aff = db.query(Affiliate).filter(
        Affiliate.referral_code == code,
        Affiliate.is_active == True,
    ).first()

    if not aff:
        return ValidateCodeResponse(valid=False, message="Invalid referral code")

    return ValidateCodeResponse(valid=True, message="Valid referral code")
