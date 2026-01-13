from fastapi import APIRouter, Depends, Query, HTTPException, status
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from typing import Optional
from app.database import get_db
from app.core.dependencies import get_current_business_id
from app.schemas.report import (
    SalesReportResponse,
    ProductReportResponse,
    CustomerReportResponse
)
from app.services.report_service import ReportService
from app.services.plan_limit_service import PlanLimitService
from app.utils.pdf_generator import PDFGenerator
from app.utils.csv_generator import CSVGenerator
from datetime import datetime

router = APIRouter(prefix="/reports", tags=["Reports"])


def check_paid_plan_access(
    business_id: int = Depends(get_current_business_id),
    db: Session = Depends(get_db)
):
    has_access = PlanLimitService.check_feature_access(db, business_id, "reports_enabled")
    if not has_access:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "code": "PAID_PLAN_REQUIRED",
                "message": "Reports are available only for PAID plan. Upgrade to access this feature.",
                "feature": "reports_enabled"
            }
        )
    return business_id


@router.get("/sales", response_model=SalesReportResponse)
def get_sales_report(
    from_date: Optional[str] = Query(None, description="Start date (YYYY-MM-DD)"),
    to_date: Optional[str] = Query(None, description="End date (YYYY-MM-DD)"),
    business_id: int = Depends(check_paid_plan_access),
    db: Session = Depends(get_db)
):
    service = ReportService(db)
    return service.get_sales_report(business_id, from_date, to_date)


@router.get("/products", response_model=ProductReportResponse)
def get_product_report(
    from_date: Optional[str] = Query(None, description="Start date (YYYY-MM-DD)"),
    to_date: Optional[str] = Query(None, description="End date (YYYY-MM-DD)"),
    business_id: int = Depends(check_paid_plan_access),
    db: Session = Depends(get_db)
):
    service = ReportService(db)
    return service.get_product_report(business_id, from_date, to_date)


@router.get("/customers", response_model=CustomerReportResponse)
def get_customer_report(
    from_date: Optional[str] = Query(None, description="Start date (YYYY-MM-DD)"),
    to_date: Optional[str] = Query(None, description="End date (YYYY-MM-DD)"),
    business_id: int = Depends(check_paid_plan_access),
    db: Session = Depends(get_db)
):
    service = ReportService(db)
    return service.get_customer_report(business_id, from_date, to_date)


@router.get("/export/pdf")
def export_report_pdf(
    report_type: str = Query(..., description="Type of report: sales, products, customers"),
    from_date: Optional[str] = Query(None, description="Start date (YYYY-MM-DD)"),
    to_date: Optional[str] = Query(None, description="End date (YYYY-MM-DD)"),
    business_id: int = Depends(check_paid_plan_access),
    db: Session = Depends(get_db)
):
    has_pdf_access = PlanLimitService.check_feature_access(db, business_id, "export_pdf")
    if not has_pdf_access:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "code": "PAID_PLAN_REQUIRED",
                "message": "PDF export is available only for PAID plan.",
                "feature": "export_pdf"
            }
        )
    
    service = ReportService(db)
    
    if report_type == "sales":
        report_data = service.get_sales_report(business_id, from_date, to_date)
        pdf_buffer = PDFGenerator.generate_sales_report(report_data)
        filename = f"sales_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
    elif report_type == "products":
        report_data = service.get_product_report(business_id, from_date, to_date)
        pdf_buffer = PDFGenerator.generate_product_report(report_data)
        filename = f"product_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
    elif report_type == "customers":
        report_data = service.get_customer_report(business_id, from_date, to_date)
        pdf_buffer = PDFGenerator.generate_customer_report(report_data)
        filename = f"customer_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid report_type. Must be: sales, products, or customers"
        )
    
    return StreamingResponse(
        pdf_buffer,
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )


@router.get("/export/csv")
def export_report_csv(
    report_type: str = Query(..., description="Type of report: sales, products, customers"),
    from_date: Optional[str] = Query(None, description="Start date (YYYY-MM-DD)"),
    to_date: Optional[str] = Query(None, description="End date (YYYY-MM-DD)"),
    business_id: int = Depends(check_paid_plan_access),
    db: Session = Depends(get_db)
):
    has_csv_access = PlanLimitService.check_feature_access(db, business_id, "export_csv")
    if not has_csv_access:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "code": "PAID_PLAN_REQUIRED",
                "message": "CSV export is available only for PAID plan.",
                "feature": "export_csv"
            }
        )
    
    service = ReportService(db)
    
    if report_type == "sales":
        report_data = service.get_sales_report(business_id, from_date, to_date)
        csv_buffer = CSVGenerator.generate_sales_report(report_data)
        filename = f"sales_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
    elif report_type == "products":
        report_data = service.get_product_report(business_id, from_date, to_date)
        csv_buffer = CSVGenerator.generate_product_report(report_data)
        filename = f"product_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
    elif report_type == "customers":
        report_data = service.get_customer_report(business_id, from_date, to_date)
        csv_buffer = CSVGenerator.generate_customer_report(report_data)
        filename = f"customer_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid report_type. Must be: sales, products, or customers"
        )
    
    return StreamingResponse(
        csv_buffer,
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )
