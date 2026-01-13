from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.config import settings
from app.routers import auth, business, category, product, customer, order, reports, admin, dashboard
from app.core.middleware import MultiTenantMiddleware
from app.core.rate_limit import RateLimitMiddleware
from app.core.monitoring import RequestLoggingMiddleware, ErrorLoggingMiddleware, setup_sentry
from app.utils.logger import logger
import os

setup_sentry()

app = FastAPI(
    title="StoreLink API",
    description="Indian MSME Business Management SaaS Platform",
    version="1.0.0",
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
)

app.add_middleware(ErrorLoggingMiddleware)
app.add_middleware(RequestLoggingMiddleware)
app.add_middleware(RateLimitMiddleware)
app.add_middleware(MultiTenantMiddleware)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

logger.info(f"Starting StoreLink API - Environment: {settings.ENVIRONMENT}")

if not os.path.exists(settings.UPLOAD_DIR):
    os.makedirs(settings.UPLOAD_DIR)

app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")

app.include_router(auth.router, prefix="/v1")
app.include_router(business.router, prefix="/v1")
app.include_router(category.router, prefix="/v1")
app.include_router(product.router, prefix="/v1")
app.include_router(customer.router, prefix="/v1")
app.include_router(order.router, prefix="/v1")
app.include_router(reports.router, prefix="/v1")
app.include_router(admin.router, prefix="/v1")
app.include_router(dashboard.router, prefix="/v1")


@app.get("/")
async def root():
    return {
        "success": True,
        "message": "StoreLink API v1.0.0",
        "status": "running"
    }


@app.get("/health")
async def health_check():
    return {
        "success": True,
        "status": "healthy"
    }
