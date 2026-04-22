from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, date, timezone
from enum import Enum


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


class PlanType(str, Enum):
    FREE = "FREE"
    PAID = "PAID"


class UserRoleEnum(str, Enum):
    SUPER_ADMIN = "SUPER_ADMIN"
    BUSINESS_OWNER = "BUSINESS_OWNER"


class AdminBusinessListItem(BaseModel):
    uuid: str
    business_name: str
    owner_name: str
    phone: str
    email: Optional[str]
    plan: str
    plan_expiry_date: Optional[date]
    subscription_type: Optional[str] = None   # "monthly" | "yearly" | "trial"
    logo_url: Optional[str] = None
    is_active: bool
    created_at: datetime
    total_products: int = 0
    total_orders: int = 0
    total_revenue: float = 0.0
    
    class Config:
        from_attributes = True


class AdminBusinessDetail(BaseModel):
    uuid: str
    business_name: str
    business_type: Optional[str]
    phone: str
    email: Optional[str]
    address: Optional[str]
    city: Optional[str]
    state: Optional[str]
    pincode: Optional[str]
    gstin: Optional[str]
    logo_url: Optional[str]
    plan: str
    plan_expiry_date: Optional[date]
    is_active: bool
    created_at: datetime
    updated_at: datetime
    owner_uuid: str
    owner_name: str
    owner_phone: str
    owner_email: Optional[str]
    total_products: int = 0
    total_orders: int = 0
    total_customers: int = 0
    total_revenue: float = 0.0
    
    class Config:
        from_attributes = True


class AdminUserListItem(BaseModel):
    uuid: str
    full_name: str
    phone: str
    email: Optional[str]
    role: str
    is_active: bool
    is_verified: bool
    last_login: Optional[datetime] = None   # last successful login timestamp
    created_at: datetime
    business_count: int = 0
    
    class Config:
        from_attributes = True


class UpdateBusinessStatusRequest(BaseModel):
    is_active: bool


class UpdateBusinessPlanRequest(BaseModel):
    plan: PlanType
    plan_expiry_date: Optional[date] = None


class UpdateUserStatusRequest(BaseModel):
    is_active: bool


class PlatformStats(BaseModel):
    # Businesses
    total_businesses: int
    active_businesses: int
    inactive_businesses: int
    free_plan_businesses: int
    paid_plan_businesses: int
    trial_plan_businesses: int
    businesses_with_orders: int       # stores that have at least 1 order
    new_businesses_this_month: int

    # Users
    total_users: int
    active_users: int
    super_admins: int
    business_owners: int
    new_users_this_month: int

    # User activity (login tracking)
    active_users_today: int           # logged in within last 24h
    active_users_week: int            # logged in within last 7 days
    active_users_month: int           # logged in within last 30 days

    # Catalogue & transactions
    total_products: int
    total_orders: int
    total_customers: int

    # Revenue metrics
    total_revenue: float
    revenue_this_month: float
    arpu: float                       # avg revenue per paid user
    conversion_rate: float            # % of free users who upgraded to paid


class PaginationMeta(BaseModel):
    page: int
    page_size: int
    total_items: int
    total_pages: int


class AdminBusinessListResponse(BaseModel):
    success: bool = True
    message: str
    data: dict
    timestamp: datetime = Field(default_factory=_utc_now)


class AdminBusinessDetailResponse(BaseModel):
    success: bool = True
    message: str
    data: AdminBusinessDetail
    timestamp: datetime = Field(default_factory=_utc_now)


class AdminUserListResponse(BaseModel):
    success: bool = True
    message: str
    data: dict
    timestamp: datetime = Field(default_factory=_utc_now)


class AdminStatsResponse(BaseModel):
    success: bool = True
    message: str
    data: PlatformStats
    timestamp: datetime = Field(default_factory=_utc_now)


class AdminStatusUpdateResponse(BaseModel):
    success: bool = True
    message: str
    timestamp: datetime = Field(default_factory=_utc_now)
