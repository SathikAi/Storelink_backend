"""
Billing endpoints — plan upgrade via Dodo Payments.

POST /billing/upgrade   (authenticated) → creates a Dodo Payments payment link
POST /billing/webhook   (public)        → Dodo webhook handler; upgrades plan on payment.succeeded
GET  /billing/status    (authenticated) → returns subscription status
"""
from datetime import date, timedelta
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.config import settings
from app.database import get_db
from app.core.dependencies import get_current_user, get_current_business_id
from app.models.business import Business, BusinessPlan
from app.models.user import User
from app.models.affiliate import Affiliate, Referral, ReferralStatus
from sqlalchemy import func
from app.services.plan_limit_service import PlanLimitService
from app.utils.logger import logger

router = APIRouter(prefix="/billing", tags=["Billing"])

# Plan durations in days
PLAN_DAYS = {"monthly": 30, "yearly": 365}
PLAN_PRICES = {"monthly": 699, "yearly": 6999}


def _dodo_client():
    """Lazily create the Dodo Payments SDK client."""
    from dodopayments import DodoPayments
    return DodoPayments(
        bearer_token=settings.DODO_PAYMENTS_API_KEY,
        environment=settings.DODO_PAYMENTS_ENVIRONMENT,
    )


def _get_product_id(plan_type: str) -> str:
    """Return the correct Dodo product ID for monthly or yearly plan."""
    if plan_type == "yearly" and settings.DODO_PAYMENTS_PRODUCT_ID_YEARLY:
        return settings.DODO_PAYMENTS_PRODUCT_ID_YEARLY
    if plan_type == "monthly" and settings.DODO_PAYMENTS_PRODUCT_ID_MONTHLY:
        return settings.DODO_PAYMENTS_PRODUCT_ID_MONTHLY
    return settings.DODO_PAYMENTS_PRODUCT_ID  # legacy fallback


# ── Request / Response schemas ────────────────────────────────────────────────

class UpgradeRequest(BaseModel):
    plan_type: str = "monthly"  # "monthly" | "yearly"


class UpgradeResponse(BaseModel):
    success: bool
    payment_url: str
    message: str


class SubscriptionStatusResponse(BaseModel):
    plan: str
    subscription_type: Optional[str]
    is_active: bool
    days_remaining: Optional[int]
    expires_at: Optional[str]
    monthly_price: int = 699
    yearly_price: int = 6999


# ── GET /billing/status ───────────────────────────────────────────────────────

@router.get("/status", response_model=SubscriptionStatusResponse)
async def get_subscription_status(
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db),
):
    business = db.query(Business).filter(
        Business.id == business_id,
        Business.deleted_at.is_(None),
    ).first()
    if not business:
        raise HTTPException(status_code=404, detail="Business not found")

    days_remaining = None
    is_active = business.plan == BusinessPlan.PAID
    if business.plan_expiry_date:
        delta = (business.plan_expiry_date - date.today()).days
        days_remaining = max(0, delta)
        if days_remaining == 0:
            is_active = False

    sub_type = getattr(business, 'subscription_type', None)

    return SubscriptionStatusResponse(
        plan=business.plan.value,
        subscription_type=sub_type,
        is_active=is_active,
        days_remaining=days_remaining,
        expires_at=business.plan_expiry_date.isoformat() if business.plan_expiry_date else None,
    )


# ── POST /billing/upgrade ─────────────────────────────────────────────────────

@router.post("/upgrade", response_model=UpgradeResponse)
async def create_upgrade_payment(
    body: UpgradeRequest = UpgradeRequest(),
    current_user: User = Depends(get_current_user),
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db),
):
    """
    Create a Dodo Payments payment link for monthly (₹699) or yearly (₹6,999) plan.
    Returns a `payment_url` the Flutter app opens in-browser.
    """
    plan_type = body.plan_type if body.plan_type in ("monthly", "yearly") else "monthly"

    business = db.query(Business).filter(
        Business.id == business_id,
        Business.deleted_at.is_(None),
    ).first()
    if not business:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")

    return_url = f"{settings.DODO_PAYMENTS_RETURN_URL}?business_uuid={business.uuid}&plan_type={plan_type}"

    if not settings.DODO_PAYMENTS_API_KEY or not _get_product_id(plan_type):
        # Mock mode for testing UI flow if keys are not configured
        if settings.ENVIRONMENT == "development":
            logger.info(f"Mocking {plan_type} upgrade payment link for business {business.uuid}")
            return UpgradeResponse(
                success=True,
                payment_url=return_url,
                message=f"MOCK MODE: ₹{PLAN_PRICES[plan_type]} {plan_type} plan. Using test link.",
            )
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Payment service is not configured. Please contact support.",
        )

    # Already on active PAID plan — skip
    if (
        business.plan == BusinessPlan.PAID
        and business.plan_expiry_date
        and business.plan_expiry_date > date.today()
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Your PAID plan is already active until {business.plan_expiry_date}.",
        )

    try:
        client = _dodo_client()
        product_id = _get_product_id(plan_type)
        payment = client.payments.create(
            payment_link=True,
            product_cart=[{"product_id": product_id, "quantity": 1}],
            customer={"email": current_user.email or "", "name": business.business_name},
            metadata={"business_uuid": business.uuid, "plan_type": plan_type},
            return_url=return_url,
        )
        payment_url: str = payment.payment_link
    except Exception as exc:
        logger.error(f"Dodo Payments create payment error: {exc}")
        if settings.ENVIRONMENT == "development":
            return UpgradeResponse(
                success=True,
                payment_url=return_url,
                message=f"DEV FALLBACK: ₹{PLAN_PRICES[plan_type]} {plan_type} plan. Using test link.",
            )
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Failed to create payment link. Please try again later.",
        )

    logger.info(f"Upgrade payment link created for business {business.uuid} ({plan_type})")
    return UpgradeResponse(
        success=True,
        payment_url=payment_url,
        message=f"Payment link created. Complete ₹{PLAN_PRICES[plan_type]} payment to activate PRO.",
    )


# ── POST /billing/webhook ─────────────────────────────────────────────────────

@router.post("/webhook", status_code=200)
async def dodo_webhook(request: Request, db: Session = Depends(get_db)):
    """
    Dodo Payments webhook handler — no JWT auth, verified by signature.

    Handles:
      • payment.succeeded  → upgrades business plan to PAID for 1 year
      • payment.failed     → logged only
    """
    if not settings.DODO_PAYMENTS_WEBHOOK_KEY:
        logger.warning("Dodo webhook received but DODO_PAYMENTS_WEBHOOK_KEY is not set")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Webhook not configured",
        )

    payload_bytes = await request.body()
    webhook_headers = {
        "webhook-id":        request.headers.get("webhook-id", ""),
        "webhook-signature": request.headers.get("webhook-signature", ""),
        "webhook-timestamp": request.headers.get("webhook-timestamp", ""),
    }

    # ── Verify signature ──────────────────────────────────────────────────
    try:
        client = _dodo_client()
        event = client.webhooks.unwrap(
            payload_bytes, webhook_headers, secret=settings.DODO_PAYMENTS_WEBHOOK_KEY
        )
    except Exception as exc:
        logger.warning(f"Dodo webhook signature verification failed: {exc}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid webhook signature",
        )

    event_type: str = event.type
    logger.info(f"Dodo webhook event received: {event_type}")

    # ── payment.succeeded → upgrade plan ──────────────────────────────────
    if event_type == "payment.succeeded":
        try:
            data = event.data
            metadata: dict = getattr(data, "metadata", None) or {}
            business_uuid: str = metadata.get("business_uuid", "")

            if not business_uuid:
                logger.warning("payment.succeeded webhook missing business_uuid in metadata — skipping")
                return {"success": True}

            business = db.query(Business).filter(
                Business.uuid == business_uuid,
                Business.deleted_at.is_(None),
            ).first()

            if not business:
                logger.warning(f"Webhook: no business found for uuid={business_uuid}")
                return {"success": True}

            plan_type: str = metadata.get("plan_type", "yearly")
            if plan_type not in ("monthly", "yearly"):
                plan_type = "yearly"
            days_to_add = PLAN_DAYS[plan_type]

            old_plan = business.plan
            business.plan = BusinessPlan.PAID
            business.subscription_type = plan_type

            # Extend from today OR from existing expiry (whichever is later)
            if business.plan_expiry_date and business.plan_expiry_date > date.today():
                base_date = business.plan_expiry_date
            else:
                base_date = date.today()
            business.plan_expiry_date = base_date + timedelta(days=days_to_add)

            if old_plan != BusinessPlan.PAID:
                PlanLimitService.update_plan_limits(db, business.id, BusinessPlan.PAID)

            # ── Reward affiliate referrer (30 free days) ───────────────
            referral = db.query(Referral).filter(
                Referral.referred_business_id == business.id,
                Referral.status == ReferralStatus.PENDING,
            ).first()
            if referral:
                aff = db.query(Affiliate).filter(
                    Affiliate.id == referral.affiliate_id
                ).first()
                if aff:
                    referrer_biz = db.query(Business).filter(
                        Business.id == aff.business_id,
                        Business.deleted_at.is_(None),
                    ).first()
                    if referrer_biz:
                        # Extend referrer's plan by reward_days
                        from datetime import date as _date
                        ref_base = (
                            referrer_biz.plan_expiry_date
                            if referrer_biz.plan_expiry_date
                               and referrer_biz.plan_expiry_date > _date.today()
                            else _date.today()
                        )
                        referrer_biz.plan_expiry_date = (
                            ref_base + timedelta(days=aff.reward_days)
                        )
                        # If referrer is still FREE, upgrade to PAID
                        if referrer_biz.plan != BusinessPlan.PAID:
                            referrer_biz.plan = BusinessPlan.PAID
                            PlanLimitService.update_plan_limits(
                                db, referrer_biz.id, BusinessPlan.PAID
                            )
                        aff.rewarded_referrals += 1
                    referral.status = ReferralStatus.REWARDED
                    referral.rewarded_at = func.current_timestamp()
                    logger.info(
                        f"Affiliate {aff.referral_code} rewarded "
                        f"+{aff.reward_days} days for referring {business_uuid}"
                    )

            db.commit()
            logger.info(
                f"Business {business_uuid} upgraded to PAID, expires {business.plan_expiry_date}"
            )

        except Exception as exc:
            db.rollback()
            logger.error(f"Error processing payment.succeeded webhook: {exc}")
            raise HTTPException(status_code=500, detail="Internal error processing payment event")

    elif event_type == "payment.failed":
        data = event.data
        metadata: dict = getattr(data, "metadata", None) or {}
        logger.warning(f"Payment failed for business_uuid={metadata.get('business_uuid', 'unknown')}")

    return {"success": True}


# ── GET /upgrade-success ──────────────────────────────────────────────────────

@router.get("/upgrade-success")
async def upgrade_success(
    business_uuid: str,
    plan_type: str = "yearly",
    db: Session = Depends(get_db),
):
    """
    Landing page after a successful Dodo payment.
    In development mode, we also perform the upgrade here (normally done by webhook).
    """
    business = db.query(Business).filter(
        Business.uuid == business_uuid,
        Business.deleted_at.is_(None),
    ).first()

    if not business:
        return {"error": "Business not found"}

    # Mock the upgrade in development mode
    if settings.ENVIRONMENT == "development":
        if plan_type not in ("monthly", "yearly"):
            plan_type = "yearly"
        days = PLAN_DAYS[plan_type]
        business.plan = BusinessPlan.PAID
        business.subscription_type = plan_type
        business.plan_expiry_date = date.today() + timedelta(days=days)
        PlanLimitService.update_plan_limits(db, business.id, BusinessPlan.PAID)
        db.commit()
        logger.info(f"MOCK UPGRADE: Business {business_uuid} upgraded to PAID ({plan_type}) via success landing page")

    return {
        "success": True,
        "message": "Congratulations! Your premium plan is now active.",
        "plan": "PAID",
        "expires_at": business.plan_expiry_date.isoformat() if business.plan_expiry_date else None
    }
