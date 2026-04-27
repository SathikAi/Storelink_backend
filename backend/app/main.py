from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from app.config import settings
from app.routers import auth, business, category, product, customer, order, reports, admin, dashboard, store, billing, affiliate
from app.core.middleware import MultiTenantMiddleware, SecurityHeadersMiddleware
from app.core.rate_limit import RateLimitMiddleware
from app.core.monitoring import RequestLoggingMiddleware, ErrorLoggingMiddleware, setup_sentry
from app.utils.logger import logger
import os

setup_sentry()

from contextlib import asynccontextmanager
from sqlalchemy import text

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: verify DB connectivity
    from app.database import engine
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        logger.info("Database connection verified")
    except Exception as e:
        logger.error(f"Database connection failed: {e}")
    yield
    # Shutdown
    engine.dispose()
    logger.info("Database connections closed")

app = FastAPI(
    lifespan=lifespan,
    title="StoreLink API",
    description="Indian MSME Business Management SaaS Platform",
    version="1.0.0",
    redirect_slashes=False,
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
)

# CORS must be outermost (added last = runs first in Starlette LIFO order)
app.add_middleware(SecurityHeadersMiddleware)
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

_static_dir = os.path.join(os.path.dirname(__file__), "..", "static")
if os.path.exists(_static_dir):
    app.mount("/static", StaticFiles(directory=_static_dir), name="static")


@app.get("/admin-dashboard", include_in_schema=False)
async def admin_dashboard():
    html_path = os.path.join(os.path.dirname(__file__), "..", "static", "admin.html")
    return FileResponse(html_path, media_type="text/html")

app.include_router(auth.router, prefix="/v1")
app.include_router(business.router, prefix="/v1")
app.include_router(category.router, prefix="/v1")
app.include_router(product.router, prefix="/v1")
app.include_router(customer.router, prefix="/v1")
app.include_router(order.router, prefix="/v1")
app.include_router(reports.router, prefix="/v1")
app.include_router(admin.router, prefix="/v1")
app.include_router(dashboard.router, prefix="/v1")
app.include_router(store.router, prefix="/v1")
app.include_router(billing.router, prefix="/v1")
app.include_router(affiliate.router, prefix="/v1")


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
