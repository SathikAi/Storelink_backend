import os
from pydantic_settings import BaseSettings
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
    
    CORS_ORIGINS: str = "http://localhost:3000,http://localhost:8080"
    
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    
    REDIS_URL: Optional[str] = None
    REDIS_ENABLED: bool = False
    REDIS_TTL: int = 300
    
    RATE_LIMIT_ENABLED: bool = False
    RATE_LIMIT_REQUESTS: int = 100
    RATE_LIMIT_WINDOW: int = 60
    
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
