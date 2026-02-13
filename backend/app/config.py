import os
import warnings
from pydantic_settings import BaseSettings
from pydantic import field_validator
from typing import List, Optional


class Settings(BaseSettings):
    DATABASE_URL: str
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    OTP_EXPIRY_MINUTES: int = 5
    OTP_MOCK: bool = False

    UPLOAD_DIR: str = "uploads"
    MAX_FILE_SIZE: int = 5242880
    ALLOWED_IMAGE_TYPES: str = "image/jpeg,image/png,image/webp"

    CORS_ORIGINS: str = "http://localhost:3000,http://localhost:8080"

    ENVIRONMENT: str = "development"
    DEBUG: bool = True

    REDIS_URL: Optional[str] = None
    REDIS_ENABLED: bool = False
    REDIS_TTL: int = 300

    RATE_LIMIT_ENABLED: bool = False
    RATE_LIMIT_REQUESTS: int = 100
    RATE_LIMIT_WINDOW: int = 60

    LOW_STOCK_THRESHOLD: int = 10

    LOG_LEVEL: str = "INFO"
    LOG_FILE: Optional[str] = None
    LOG_MAX_BYTES: int = 104857600
    LOG_BACKUP_COUNT: int = 10

    SENTRY_DSN: Optional[str] = None
    SENTRY_ENVIRONMENT: str = "development"

    DATABASE_POOL_SIZE: int = 10
    DATABASE_MAX_OVERFLOW: int = 5
    DATABASE_POOL_RECYCLE: int = 3600

    SMTP_HOST: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_USER: Optional[str] = None
    SMTP_PASSWORD: Optional[str] = None
    SMTP_FROM: str = "StoreLink <noreply@storelink.com>"

    @field_validator("SECRET_KEY")
    @classmethod
    def validate_secret_key(cls, v: str) -> str:
        if len(v) < 32:
            raise ValueError("SECRET_KEY must be at least 32 characters")
        return v

    @property
    def allowed_image_types_list(self) -> List[str]:
        return [t.strip() for t in self.ALLOWED_IMAGE_TYPES.split(",")]

    @property
    def cors_origins_list(self) -> List[str]:
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",")]

    @property
    def is_production(self) -> bool:
        return self.ENVIRONMENT == "production"

    @property
    def is_development(self) -> bool:
        return self.ENVIRONMENT == "development"

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()

# Production safety checks
if settings.is_production:
    if settings.OTP_MOCK:
        raise RuntimeError("OTP_MOCK must be disabled in production")
    if settings.DEBUG:
        raise RuntimeError("DEBUG must be disabled in production")
    if not settings.RATE_LIMIT_ENABLED:
        warnings.warn("RATE_LIMIT_ENABLED is False in production", stacklevel=1)
