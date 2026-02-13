import json
import redis
from typing import Optional, Any
from app.config import settings
from app.utils.logger import logger
from functools import wraps
import hashlib


class RedisCache:
    def __init__(self):
        self.client: Optional[redis.Redis] = None
        if settings.REDIS_ENABLED and settings.REDIS_URL:
            try:
                self.client = redis.from_url(
                    settings.REDIS_URL,
                    decode_responses=True,
                    socket_connect_timeout=5,
                    socket_timeout=5,
                    retry_on_timeout=True,
                )
                self.client.ping()
                logger.info("Redis connection established")
            except Exception as e:
                logger.warning(f"Redis connection failed: {e}")
                self.client = None

    def is_available(self) -> bool:
        return self.client is not None

    def get(self, key: str) -> Optional[Any]:
        if not self.is_available():
            return None
        try:
            value = self.client.get(key)
            if value:
                return json.loads(value)
            return None
        except Exception as e:
            logger.error(f"Redis GET error: {e}")
            return None

    def set(self, key: str, value: Any, ttl: Optional[int] = None) -> bool:
        if not self.is_available():
            return False
        try:
            ttl = ttl or settings.REDIS_TTL
            serialized = json.dumps(value, default=str)
            self.client.setex(key, ttl, serialized)
            return True
        except Exception as e:
            logger.error(f"Redis SET error: {e}")
            return False

    def delete(self, key: str) -> bool:
        if not self.is_available():
            return False
        try:
            self.client.delete(key)
            return True
        except Exception as e:
            logger.error(f"Redis DELETE error: {e}")
            return False

    def delete_pattern(self, pattern: str) -> int:
        """Use SCAN instead of KEYS to avoid blocking Redis."""
        if not self.is_available():
            return 0
        try:
            deleted = 0
            cursor = 0
            while True:
                cursor, keys = self.client.scan(cursor=cursor, match=pattern, count=100)
                if keys:
                    deleted += self.client.delete(*keys)
                if cursor == 0:
                    break
            return deleted
        except Exception as e:
            logger.error(f"Redis DELETE_PATTERN error: {e}")
            return 0

    def flush_all(self) -> bool:
        if not self.is_available():
            return False
        try:
            self.client.flushdb()
            return True
        except Exception as e:
            logger.error(f"Redis FLUSH error: {e}")
            return False


cache = RedisCache()


def cache_key(*args, **kwargs) -> str:
    key_parts = [str(arg) for arg in args]
    key_parts.extend([f"{k}={v}" for k, v in sorted(kwargs.items())])
    key_string = ":".join(key_parts)
    return hashlib.md5(key_string.encode()).hexdigest()


def cached(prefix: str, ttl: Optional[int] = None):
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            if not cache.is_available():
                return await func(*args, **kwargs)
            
            key = f"{prefix}:{cache_key(*args, **kwargs)}"
            
            cached_result = cache.get(key)
            if cached_result is not None:
                return cached_result
            
            result = await func(*args, **kwargs)
            
            cache.set(key, result, ttl)
            
            return result
        
        return wrapper
    return decorator


def invalidate_cache(prefix: str, *args, **kwargs):
    if cache.is_available():
        key = f"{prefix}:{cache_key(*args, **kwargs)}"
        cache.delete(key)


def invalidate_cache_pattern(pattern: str):
    if cache.is_available():
        cache.delete_pattern(pattern)
