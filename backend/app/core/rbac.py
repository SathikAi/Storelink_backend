from functools import wraps
from typing import List, Callable
from fastapi import HTTPException, status
from app.models.user import UserRole


def require_role(allowed_roles: List[UserRole]):
    def decorator(func: Callable):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            current_user = kwargs.get("current_user")
            
            if not current_user:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Authentication required"
                )
            
            if current_user.role not in allowed_roles:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail=f"Access denied. Required role: {', '.join([r.value for r in allowed_roles])}"
                )
            
            return await func(*args, **kwargs)
        return wrapper
    return decorator


def require_super_admin(func: Callable):
    return require_role([UserRole.SUPER_ADMIN])(func)


def require_business_owner(func: Callable):
    return require_role([UserRole.BUSINESS_OWNER])(func)


def require_any_authenticated(func: Callable):
    return require_role([UserRole.SUPER_ADMIN, UserRole.BUSINESS_OWNER])(func)
