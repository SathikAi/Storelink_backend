from fastapi import Depends, HTTPException, status
from app.models.user import User, UserRole
from app.core.dependencies import get_current_user


def require_super_admin(current_user: User = Depends(get_current_user)) -> User:
    if current_user.role != UserRole.SUPER_ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Super admin access required",
        )
    return current_user


def require_business_owner(current_user: User = Depends(get_current_user)) -> User:
    if current_user.role != UserRole.BUSINESS_OWNER:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Business owner access required",
        )
    return current_user
