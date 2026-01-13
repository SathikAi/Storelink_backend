from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from app.utils.logger import logger
import time
from typing import Callable


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next: Callable):
        start_time = time.time()
        
        request_id = request.headers.get("X-Request-ID", f"{time.time()}")
        
        logger.info(
            f"Request started: {request.method} {request.url.path}",
            extra={
                "request_id": request_id,
                "method": request.method,
                "path": request.url.path,
                "client_ip": request.client.host if request.client else None
            }
        )
        
        try:
            response = await call_next(request)
            
            duration = time.time() - start_time
            
            logger.info(
                f"Request completed: {request.method} {request.url.path} - Status: {response.status_code} - Duration: {duration:.3f}s",
                extra={
                    "request_id": request_id,
                    "method": request.method,
                    "path": request.url.path,
                    "status_code": response.status_code,
                    "duration": duration
                }
            )
            
            response.headers["X-Request-ID"] = request_id
            response.headers["X-Response-Time"] = f"{duration:.3f}s"
            
            return response
            
        except Exception as e:
            duration = time.time() - start_time
            
            logger.error(
                f"Request failed: {request.method} {request.url.path} - Error: {str(e)} - Duration: {duration:.3f}s",
                extra={
                    "request_id": request_id,
                    "method": request.method,
                    "path": request.url.path,
                    "error": str(e),
                    "duration": duration
                },
                exc_info=True
            )
            
            raise


class ErrorLoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next: Callable):
        try:
            return await call_next(request)
        except Exception as e:
            logger.error(
                f"Unhandled exception in {request.method} {request.url.path}: {str(e)}",
                extra={
                    "method": request.method,
                    "path": request.url.path,
                    "client_ip": request.client.host if request.client else None,
                    "error_type": type(e).__name__
                },
                exc_info=True
            )
            raise


def setup_sentry():
    from app.config import settings
    
    if settings.SENTRY_DSN and settings.is_production:
        try:
            import sentry_sdk
            from sentry_sdk.integrations.fastapi import FastApiIntegration
            from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration
            
            sentry_sdk.init(
                dsn=settings.SENTRY_DSN,
                environment=settings.SENTRY_ENVIRONMENT,
                traces_sample_rate=0.1,
                profiles_sample_rate=0.1,
                integrations=[
                    FastApiIntegration(),
                    SqlalchemyIntegration(),
                ],
                attach_stacktrace=True,
                send_default_pii=False
            )
            
            logger.info("Sentry monitoring initialized")
        except ImportError:
            logger.warning("Sentry SDK not installed. Install with: pip install sentry-sdk")
        except Exception as e:
            logger.error(f"Failed to initialize Sentry: {e}")
