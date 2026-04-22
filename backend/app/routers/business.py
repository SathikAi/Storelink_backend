from typing import List
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.business import (
    BusinessProfileResponse,
    BusinessUpdateRequest,
    BusinessStatsResponse,
    BusinessResponse,
)
from app.services.business_service import BusinessService
from app.core.dependencies import get_current_user, get_current_business_id
from app.models.user import User

router = APIRouter(prefix="/business", tags=["Business"])


@router.get("/profile", response_model=BusinessResponse)
async def get_business_profile(
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    business_service = BusinessService(db)
    business = business_service.get_business_by_id(business_id)
    
    return BusinessResponse(
        success=True,
        message="Business profile retrieved successfully",
        data=BusinessProfileResponse.model_validate(business)
    )


@router.put("/profile", response_model=BusinessResponse)
async def update_business_profile(
    data: BusinessUpdateRequest,
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    business_service = BusinessService(db)
    business = business_service.update_business_profile(business_id, data)
    
    return BusinessResponse(
        success=True,
        message="Business profile updated successfully",
        data=BusinessProfileResponse.model_validate(business)
    )


@router.post("/logo", response_model=BusinessResponse)
async def upload_business_logo(
    file: UploadFile = File(...),
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    business_service = BusinessService(db)
    business = await business_service.upload_logo(business_id, file)

    return BusinessResponse(
        success=True,
        message="Logo uploaded successfully",
        data=BusinessProfileResponse.model_validate(business)
    )


@router.post("/banner", response_model=BusinessResponse)
async def upload_business_banner(
    file: UploadFile = File(...),
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    business_service = BusinessService(db)
    business = await business_service.upload_banner(business_id, file)

    return BusinessResponse(
        success=True,
        message="Banner uploaded successfully",
        data=BusinessProfileResponse.model_validate(business)
    )


@router.post("/images", response_model=BusinessResponse)
async def upload_business_images(
    files: List[UploadFile] = File(...),
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    business_service = BusinessService(db)
    business = await business_service.upload_images(business_id, files)

    return BusinessResponse(
        success=True,
        message=f"Images uploaded successfully",
        data=BusinessProfileResponse.model_validate(business)
    )


@router.get("/stats", response_model=dict)
async def get_business_stats(
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    business_service = BusinessService(db)
    stats = business_service.get_business_stats(business_id)
    
    return {
        "success": True,
        "message": "Business statistics retrieved successfully",
        "data": stats,
        "timestamp": datetime.now(timezone.utc)
    }
