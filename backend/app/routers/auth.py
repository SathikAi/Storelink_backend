from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.auth import (
    RegisterRequest,
    LoginRequest,
    OTPSendRequest,
    OTPVerifyRequest,
    RefreshTokenRequest,
    AuthResponse,
    OTPResponse,
    UserResponse,
    TokenResponse
)
from app.services.auth_service import AuthService
from app.core.dependencies import get_current_user
from app.models.user import User
from app.config import settings

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
async def register(data: RegisterRequest, db: Session = Depends(get_db)):
    auth_service = AuthService(db)
    user, business = auth_service.register_user(data)
    tokens = auth_service.generate_tokens(user, business)
    
    return AuthResponse(
        success=True,
        message="Registration successful",
        data={
            "user": UserResponse.model_validate(user).model_dump(),
            "business": {
                "uuid": business.uuid,
                "business_name": business.business_name,
                "plan": business.plan.value
            },
            "tokens": tokens
        }
    )


@router.post("/login", response_model=AuthResponse)
async def login(data: LoginRequest, db: Session = Depends(get_db)):
    auth_service = AuthService(db)
    user, business = auth_service.login_user(data)
    tokens = auth_service.generate_tokens(user, business)
    
    return AuthResponse(
        success=True,
        message="Login successful",
        data={
            "user": UserResponse.model_validate(user).model_dump(),
            "business": {
                "uuid": business.uuid,
                "business_name": business.business_name,
                "plan": business.plan.value
            } if business else None,
            "tokens": tokens
        }
    )


@router.post("/otp/send", response_model=OTPResponse)
async def send_otp(data: OTPSendRequest, db: Session = Depends(get_db)):
    auth_service = AuthService(db)
    otp_record = auth_service.send_otp(data)
    
    message = f"OTP sent to {data.phone}"
    if settings.OTP_MOCK:
        message = f"OTP: {otp_record.otp_code} (Mock mode)"
    
    return OTPResponse(
        success=True,
        message=message,
        expires_in_minutes=settings.OTP_EXPIRY_MINUTES
    )


@router.post("/otp/verify", response_model=AuthResponse)
async def verify_otp(data: OTPVerifyRequest, db: Session = Depends(get_db)):
    auth_service = AuthService(db)
    
    if data.purpose == "LOGIN":
        user, business = auth_service.login_with_otp(data)
        tokens = auth_service.generate_tokens(user, business)
        
        return AuthResponse(
            success=True,
            message="OTP verified successfully",
            data={
                "user": UserResponse.model_validate(user).model_dump(),
                "business": {
                    "uuid": business.uuid,
                    "business_name": business.business_name,
                    "plan": business.plan.value
                } if business else None,
                "tokens": tokens
            }
        )
    else:
        auth_service.verify_otp(data)
        return AuthResponse(
            success=True,
            message="OTP verified successfully",
            data={}
        )


@router.post("/refresh", response_model=AuthResponse)
async def refresh_token(data: RefreshTokenRequest, db: Session = Depends(get_db)):
    auth_service = AuthService(db)
    tokens = auth_service.refresh_access_token(data.refresh_token)
    
    return AuthResponse(
        success=True,
        message="Token refreshed successfully",
        data={"tokens": tokens}
    )


@router.get("/me", response_model=AuthResponse)
async def get_current_user_info(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    from app.models.business import Business
    
    business = None
    if current_user.role.value == "BUSINESS_OWNER":
        business = db.query(Business).filter(
            Business.owner_id == current_user.id,
            Business.deleted_at.is_(None)
        ).first()
    
    return AuthResponse(
        success=True,
        message="User information retrieved",
        data={
            "user": UserResponse.model_validate(current_user).model_dump(),
            "business": {
                "uuid": business.uuid,
                "business_name": business.business_name,
                "plan": business.plan.value,
                "is_active": business.is_active
            } if business else None
        }
    )


@router.post("/logout", response_model=AuthResponse)
async def logout(current_user: User = Depends(get_current_user)):
    return AuthResponse(
        success=True,
        message="Logged out successfully",
        data={}
    )
