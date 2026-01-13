from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import Optional
from app.database import get_db
from app.schemas.category import (
    CategoryCreateRequest,
    CategoryUpdateRequest,
    CategoryListResponse,
    CategorySingleResponse,
    CategoryDeleteResponse,
    CategoryResponse
)
from app.services.category_service import CategoryService
from app.core.dependencies import get_current_business_id

router = APIRouter(prefix="/categories", tags=["Categories"])


@router.post("", response_model=CategorySingleResponse, status_code=201)
async def create_category(
    data: CategoryCreateRequest,
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    category_service = CategoryService(db)
    category = category_service.create_category(business_id, data)
    
    return CategorySingleResponse(
        message="Category created successfully",
        data=CategoryResponse.model_validate(category)
    )


@router.get("", response_model=CategoryListResponse)
async def get_categories(
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
    is_active: Optional[bool] = None,
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    category_service = CategoryService(db)
    categories, total = category_service.get_categories(
        business_id, page, page_size, is_active
    )
    
    return CategoryListResponse(
        message="Categories retrieved successfully",
        data=[CategoryResponse.model_validate(cat) for cat in categories],
        total=total,
        page=page,
        page_size=page_size
    )


@router.get("/{category_uuid}", response_model=CategorySingleResponse)
async def get_category(
    category_uuid: str,
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    category_service = CategoryService(db)
    category = category_service.get_category_by_uuid(business_id, category_uuid)
    
    return CategorySingleResponse(
        message="Category retrieved successfully",
        data=CategoryResponse.model_validate(category)
    )


@router.put("/{category_uuid}", response_model=CategorySingleResponse)
async def update_category(
    category_uuid: str,
    data: CategoryUpdateRequest,
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    category_service = CategoryService(db)
    category = category_service.update_category(business_id, category_uuid, data)
    
    return CategorySingleResponse(
        message="Category updated successfully",
        data=CategoryResponse.model_validate(category)
    )


@router.delete("/{category_uuid}", response_model=CategoryDeleteResponse)
async def delete_category(
    category_uuid: str,
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    category_service = CategoryService(db)
    category_service.delete_category(business_id, category_uuid)
    
    return CategoryDeleteResponse(
        message="Category deleted successfully"
    )
