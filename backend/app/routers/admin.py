from fastapi import APIRouter, Depends, Query, HTTPException, status
from sqlalchemy.orm import Session
from typing import Optional

from app.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User, UserRole
from app.schemas.admin import (
    AdminBusinessListResponse,
    AdminBusinessDetailResponse,
    AdminUserListResponse,
    AdminStatsResponse,
    AdminStatusUpdateResponse,
    UpdateBusinessStatusRequest,
    UpdateBusinessPlanRequest,
    UpdateUserStatusRequest
)
from app.services.admin_service import AdminService

router = APIRouter(prefix="/admin", tags=["Admin"])


def require_super_admin(current_user: User = Depends(get_current_user)) -> User:
    if current_user.role != UserRole.SUPER_ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied. SUPER_ADMIN role required."
        )
    return current_user


@router.get("/businesses", response_model=AdminBusinessListResponse)
async def list_all_businesses(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    search: Optional[str] = Query(None, description="Search by business name, phone, or owner name"),
    plan: Optional[str] = Query(None, description="Filter by plan (FREE or PAID)"),
    is_active: Optional[bool] = Query(None, description="Filter by active status"),
    current_user: User = Depends(require_super_admin),
    db: Session = Depends(get_db)
):
    admin_service = AdminService(db)
    businesses, pagination = admin_service.get_all_businesses(
        page=page,
        page_size=page_size,
        search=search,
        plan=plan,
        is_active=is_active
    )
    
    return AdminBusinessListResponse(
        success=True,
        message="Businesses retrieved successfully",
        data={
            "items": [business.model_dump() for business in businesses],
            "pagination": pagination
        }
    )


@router.get("/businesses/{uuid}", response_model=AdminBusinessDetailResponse)
async def get_business_detail(
    uuid: str,
    current_user: User = Depends(require_super_admin),
    db: Session = Depends(get_db)
):
    admin_service = AdminService(db)
    business_detail = admin_service.get_business_detail(uuid)
    
    return AdminBusinessDetailResponse(
        success=True,
        message="Business details retrieved successfully",
        data=business_detail
    )


@router.patch("/businesses/{uuid}/status", response_model=AdminStatusUpdateResponse)
async def update_business_status(
    uuid: str,
    data: UpdateBusinessStatusRequest,
    current_user: User = Depends(require_super_admin),
    db: Session = Depends(get_db)
):
    admin_service = AdminService(db)
    admin_service.update_business_status(uuid, data)
    
    status_text = "activated" if data.is_active else "deactivated"
    return AdminStatusUpdateResponse(
        success=True,
        message=f"Business {status_text} successfully"
    )


@router.patch("/businesses/{uuid}/plan", response_model=AdminStatusUpdateResponse)
async def update_business_plan(
    uuid: str,
    data: UpdateBusinessPlanRequest,
    current_user: User = Depends(require_super_admin),
    db: Session = Depends(get_db)
):
    admin_service = AdminService(db)
    admin_service.update_business_plan(uuid, data)
    
    return AdminStatusUpdateResponse(
        success=True,
        message=f"Business plan updated to {data.plan.value} successfully"
    )


@router.get("/users", response_model=AdminUserListResponse)
async def list_all_users(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    search: Optional[str] = Query(None, description="Search by name, phone, or email"),
    role: Optional[str] = Query(None, description="Filter by role (SUPER_ADMIN or BUSINESS_OWNER)"),
    is_active: Optional[bool] = Query(None, description="Filter by active status"),
    current_user: User = Depends(require_super_admin),
    db: Session = Depends(get_db)
):
    admin_service = AdminService(db)
    users, pagination = admin_service.get_all_users(
        page=page,
        page_size=page_size,
        search=search,
        role=role,
        is_active=is_active
    )
    
    return AdminUserListResponse(
        success=True,
        message="Users retrieved successfully",
        data={
            "items": [user.model_dump() for user in users],
            "pagination": pagination
        }
    )


@router.patch("/users/{uuid}/status", response_model=AdminStatusUpdateResponse)
async def update_user_status(
    uuid: str,
    data: UpdateUserStatusRequest,
    current_user: User = Depends(require_super_admin),
    db: Session = Depends(get_db)
):
    admin_service = AdminService(db)
    admin_service.update_user_status(uuid, data)
    
    status_text = "activated" if data.is_active else "deactivated"
    return AdminStatusUpdateResponse(
        success=True,
        message=f"User {status_text} successfully"
    )


@router.get("/stats", response_model=AdminStatsResponse)
async def get_platform_statistics(
    current_user: User = Depends(require_super_admin),
    db: Session = Depends(get_db)
):
    admin_service = AdminService(db)
    stats = admin_service.get_platform_statistics()
    
    return AdminStatsResponse(
        success=True,
        message="Platform statistics retrieved successfully",
        data=stats
    )
