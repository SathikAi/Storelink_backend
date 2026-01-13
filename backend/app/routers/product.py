from fastapi import APIRouter, Depends, Query, UploadFile, File
from sqlalchemy.orm import Session
from typing import Optional
from app.database import get_db
from app.schemas.product import (
    ProductCreateRequest,
    ProductUpdateRequest,
    ProductListResponse,
    ProductSingleResponse,
    ProductDeleteResponse,
    ProductImageUploadResponse,
    ProductToggleResponse,
    ProductResponse
)
from app.services.product_service import ProductService
from app.core.dependencies import get_current_business_id

router = APIRouter(prefix="/products", tags=["Products"])


@router.post("", response_model=ProductSingleResponse, status_code=201)
async def create_product(
    data: ProductCreateRequest,
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    product_service = ProductService(db)
    product = product_service.create_product(business_id, data)
    
    return ProductSingleResponse(
        message="Product created successfully",
        data=ProductResponse.model_validate(product)
    )


@router.get("", response_model=ProductListResponse)
async def get_products(
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
    category_id: Optional[int] = None,
    is_active: Optional[bool] = None,
    search: Optional[str] = None,
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    product_service = ProductService(db)
    products, total = product_service.get_products(
        business_id, page, page_size, category_id, is_active, search
    )
    
    return ProductListResponse(
        message="Products retrieved successfully",
        data=[ProductResponse.model_validate(prod) for prod in products],
        total=total,
        page=page,
        page_size=page_size
    )


@router.get("/{product_uuid}", response_model=ProductSingleResponse)
async def get_product(
    product_uuid: str,
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    product_service = ProductService(db)
    product = product_service.get_product_by_uuid(business_id, product_uuid)
    
    return ProductSingleResponse(
        message="Product retrieved successfully",
        data=ProductResponse.model_validate(product)
    )


@router.put("/{product_uuid}", response_model=ProductSingleResponse)
async def update_product(
    product_uuid: str,
    data: ProductUpdateRequest,
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    product_service = ProductService(db)
    product = product_service.update_product(business_id, product_uuid, data)
    
    return ProductSingleResponse(
        message="Product updated successfully",
        data=ProductResponse.model_validate(product)
    )


@router.delete("/{product_uuid}", response_model=ProductDeleteResponse)
async def delete_product(
    product_uuid: str,
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    product_service = ProductService(db)
    product_service.delete_product(business_id, product_uuid)
    
    return ProductDeleteResponse(
        message="Product deleted successfully"
    )


@router.post("/{product_uuid}/image", response_model=ProductImageUploadResponse)
async def upload_product_image(
    product_uuid: str,
    file: UploadFile = File(...),
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    product_service = ProductService(db)
    image_url = await product_service.upload_product_image(business_id, product_uuid, file)
    
    return ProductImageUploadResponse(
        message="Product image uploaded successfully",
        image_url=image_url
    )


@router.patch("/{product_uuid}/toggle", response_model=ProductToggleResponse)
async def toggle_product_status(
    product_uuid: str,
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    product_service = ProductService(db)
    product = product_service.toggle_product_status(business_id, product_uuid)
    
    return ProductToggleResponse(
        message="Product status toggled successfully",
        is_active=product.is_active
    )
