from fastapi import APIRouter, Depends, Query, UploadFile, File, HTTPException
from sqlalchemy.orm import Session
from typing import Optional, List
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
    low_stock: Optional[bool] = None,
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    product_service = ProductService(db)
    products, total = product_service.get_products(
        business_id, page, page_size, category_id, is_active, search, low_stock
    )
    
    return ProductListResponse(
        message="Products retrieved successfully",
        data=[ProductResponse.model_validate(prod) for prod in products],
        total=total,
        page=page,
        page_size=page_size
    )


@router.patch("/{product_uuid}/stock", response_model=ProductSingleResponse)
async def update_product_stock(
    product_uuid: str,
    quantity_change: int = Query(..., description="Positive to increase, negative to decrease"),
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    product_service = ProductService(db)
    product = product_service.update_stock(business_id, product_uuid, quantity_change)
    
    return ProductSingleResponse(
        message="Stock updated successfully",
        data=ProductResponse.model_validate(product)
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


@router.post("/{product_uuid}/images", response_model=ProductSingleResponse)
async def upload_product_images(
    product_uuid: str,
    files: List[UploadFile] = File(...),
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    from app.services.file_upload_service import FileUploadService
    product_service = ProductService(db)
    product = product_service.get_product_by_uuid(business_id, product_uuid)

    if len(files) > 10:
        raise HTTPException(status_code=400, detail="Maximum 10 images allowed")

    new_urls = []
    for file in files:
        _, relative_path = await FileUploadService.save_image(file, folder="product_images", max_width=800)
        new_urls.append(FileUploadService.get_file_url(relative_path))

    current_images = list(product.image_urls or [])
    current_images.extend(new_urls)
    product.image_urls = current_images[:10]

    # Always sync image_url with first image
    if product.image_urls:
        product.image_url = product.image_urls[0]

    db.commit()
    db.refresh(product)

    return ProductSingleResponse(
        message=f"Uploaded {len(new_urls)} image(s) successfully",
        data=ProductResponse.model_validate(product)
    )


@router.patch("/{product_uuid}/toggle", response_model=ProductSingleResponse)
async def toggle_product_status(
    product_uuid: str,
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    product_service = ProductService(db)
    product = product_service.toggle_product_status(business_id, product_uuid)

    return ProductSingleResponse(
        message="Product status toggled successfully",
        data=ProductResponse.model_validate(product)
    )
