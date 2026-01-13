from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from datetime import date
from typing import Optional
from app.database import get_db
from app.schemas.dashboard import DashboardResponse, DashboardStatsResponse
from app.services.dashboard_service import DashboardService
from app.core.dependencies import get_current_business_id

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


@router.get("/stats", response_model=DashboardResponse)
async def get_dashboard_stats(
    from_date: Optional[date] = Query(None, description="Start date for statistics (YYYY-MM-DD)"),
    to_date: Optional[date] = Query(None, description="End date for statistics (YYYY-MM-DD)"),
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    dashboard_service = DashboardService(db)
    stats = dashboard_service.get_dashboard_stats(business_id, from_date, to_date)
    
    return DashboardResponse(
        success=True,
        message="Dashboard statistics retrieved successfully",
        data=DashboardStatsResponse(**stats)
    )
