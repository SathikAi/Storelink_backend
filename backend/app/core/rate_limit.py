from fastapi import Request, HTTPException
from starlette.middleware.base import BaseHTTPMiddleware
from app.config import settings
from typing import Dict
import time
from collections import defaultdict
import asyncio


class InMemoryRateLimiter:
    def __init__(self):
        self.requests: Dict[str, list] = defaultdict(list)
        self.lock = asyncio.Lock()
    
    async def is_allowed(self, identifier: str, limit: int, window: int) -> bool:
        async with self.lock:
            current_time = time.time()
            
            if identifier not in self.requests:
                self.requests[identifier] = []
            
            self.requests[identifier] = [
                req_time for req_time in self.requests[identifier]
                if current_time - req_time < window
            ]
            
            if len(self.requests[identifier]) >= limit:
                return False
            
            self.requests[identifier].append(current_time)
            return True
    
    async def cleanup(self):
        while True:
            await asyncio.sleep(60)
            async with self.lock:
                current_time = time.time()
                for identifier in list(self.requests.keys()):
                    self.requests[identifier] = [
                        req_time for req_time in self.requests[identifier]
                        if current_time - req_time < settings.RATE_LIMIT_WINDOW
                    ]
                    if not self.requests[identifier]:
                        del self.requests[identifier]


class RedisRateLimiter:
    def __init__(self):
        from app.utils.redis_cache import cache
        self.cache = cache
    
    async def is_allowed(self, identifier: str, limit: int, window: int) -> bool:
        if not self.cache.is_available():
            return True
        
        try:
            key = f"rate_limit:{identifier}"
            current = self.cache.client.get(key)
            
            if current is None:
                self.cache.client.setex(key, window, 1)
                return True
            
            current_count = int(current)
            if current_count >= limit:
                return False
            
            self.cache.client.incr(key)
            return True
        except Exception:
            return True


class RateLimitMiddleware(BaseHTTPMiddleware):
    def __init__(self, app):
        super().__init__(app)
        from app.utils.redis_cache import cache
        
        if cache.is_available():
            self.limiter = RedisRateLimiter()
        else:
            self.limiter = InMemoryRateLimiter()
            asyncio.create_task(self.limiter.cleanup())
    
    async def dispatch(self, request: Request, call_next):
        if not settings.RATE_LIMIT_ENABLED:
            return await call_next(request)
        
        if request.url.path in ["/health", "/", "/docs", "/redoc", "/openapi.json"]:
            return await call_next(request)
        
        client_ip = request.headers.get("x-forwarded-for")
        if client_ip:
            client_ip = client_ip.split(",")[0].strip()
        else:
            client_ip = request.client.host if request.client else "unknown"

        identifier = f"ip:{client_ip}"

        if hasattr(request.state, "user_id") and request.state.user_id:
            identifier = f"user:{request.state.user_id}"
        
        is_allowed = await self.limiter.is_allowed(
            identifier,
            settings.RATE_LIMIT_REQUESTS,
            settings.RATE_LIMIT_WINDOW
        )
        
        if not is_allowed:
            raise HTTPException(
                status_code=429,
                detail="Too many requests. Please try again later."
            )
        
        response = await call_next(request)
        response.headers["X-RateLimit-Limit"] = str(settings.RATE_LIMIT_REQUESTS)
        response.headers["X-RateLimit-Window"] = str(settings.RATE_LIMIT_WINDOW)
        
        return response
