from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, timezone


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


class CategoryCreateRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    is_active: bool = True


class CategoryUpdateRequest(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = None
    is_active: Optional[bool] = None


class CategoryResponse(BaseModel):
    id: int
    uuid: str
    business_id: int
    name: str
    description: Optional[str]
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class CategoryListResponse(BaseModel):
    success: bool = True
    message: str
    data: List[CategoryResponse]
    total: int
    page: int
    page_size: int
    timestamp: datetime = Field(default_factory=_utc_now)


class CategorySingleResponse(BaseModel):
    success: bool = True
    message: str
    data: CategoryResponse
    timestamp: datetime = Field(default_factory=_utc_now)


class CategoryDeleteResponse(BaseModel):
    success: bool = True
    message: str
    timestamp: datetime = Field(default_factory=_utc_now)
