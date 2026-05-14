import time
import logging
from typing import Dict, Optional
from fastapi import Request, HTTPException, status
from cache import cache_service, cache_key
from exceptions import RateLimitException

logger = logging.getLogger(__name__)

class RateLimiter:
    """Rate limiter using sliding window algorithm"""
    
    def __init__(self):
        self.window_size = 60  # 1 minute window
        self.max_requests = 100  # Default max requests per window
    
    def is_allowed(
        self, 
        key: str, 
        max_requests: Optional[int] = None,
        window_size: Optional[int] = None
    ) -> bool:
        """Check if request is allowed"""
        if not cache_service.is_available():
            # If cache is not available, allow all requests
            return True
        
        max_req = max_requests or self.max_requests
        window = window_size or self.window_size
        
        current_time = int(time.time())
        window_start = current_time - window
        
        # Get existing requests in the window
        cache_key_value = cache_key("rate_limit", key)
        existing_requests = cache_service.get(cache_key_value) or []
        
        # Filter out old requests
        valid_requests = [req_time for req_time in existing_requests if req_time > window_start]
        
        # Check if we're over the limit
        if len(valid_requests) >= max_req:
            return False
        
        # Add current request
        valid_requests.append(current_time)
        
        # Update cache with expiration
        cache_service.set(cache_key_value, valid_requests, expire=window)
        
        return True
    
    def get_remaining_requests(
        self, 
        key: str,
        max_requests: Optional[int] = None,
        window_size: Optional[int] = None
    ) -> int:
        """Get remaining requests for the key"""
        if not cache_service.is_available():
            return max_requests or self.max_requests
        
        max_req = max_requests or self.max_requests
        window = window_size or self.window_size
        
        current_time = int(time.time())
        window_start = current_time - window
        
        cache_key_value = cache_key("rate_limit", key)
        existing_requests = cache_service.get(cache_key_value) or []
        
        valid_requests = [req_time for req_time in existing_requests if req_time > window_start]
        
        return max(0, max_req - len(valid_requests))
    
    def get_reset_time(
        self, 
        key: str,
        window_size: Optional[int] = None
    ) -> Optional[int]:
        """Get reset time for the rate limit"""
        if not cache_service.is_available():
            return None
        
        window = window_size or self.window_size
        
        cache_key_value = cache_key("rate_limit", key)
        existing_requests = cache_service.get(cache_key_value) or []
        
        if not existing_requests:
            return None
        
        # Return the time when the oldest request will expire
        oldest_request = min(existing_requests)
        return oldest_request + window

# Global rate limiter instance
rate_limiter = RateLimiter()

def create_rate_limit_middleware(
    max_requests: int = 100,
    window_size: int = 60,
    key_func: Optional[callable] = None
):
    """Create rate limiting middleware"""
    
    async def rate_limit_middleware(request: Request, call_next):
        # Generate rate limit key
        if key_func:
            key = key_func(request)
        else:
            # Default: use client IP
            key = f"ip:{request.client.host}"
        
        # Check rate limit
        if not rate_limiter.is_allowed(key, max_requests, window_size):
            remaining = rate_limiter.get_remaining_requests(key, max_requests, window_size)
            reset_time = rate_limiter.get_reset_time(key, window_size)
            
            headers = {
                "X-RateLimit-Limit": str(max_requests),
                "X-RateLimit-Remaining": str(remaining),
                "X-RateLimit-Reset": str(reset_time or int(time.time()) + window_size),
                "Retry-After": str(window_size)
            }
            
            raise RateLimitException(
                message="Rate limit exceeded",
                details={
                    "limit": max_requests,
                    "window": window_size,
                    "remaining": remaining,
                    "reset_time": reset_time
                }
            )
        
        # Add rate limit headers to response
        response = await call_next(request)
        remaining = rate_limiter.get_remaining_requests(key, max_requests, window_size)
        reset_time = rate_limiter.get_reset_time(key, window_size)
        
        response.headers["X-RateLimit-Limit"] = str(max_requests)
        response.headers["X-RateLimit-Remaining"] = str(remaining)
        if reset_time:
            response.headers["X-RateLimit-Reset"] = str(reset_time)
        
        return response
    
    return rate_limit_middleware

# Predefined rate limiters for different endpoints
AUTH_RATE_LIMIT = create_rate_limit_middleware(max_requests=5, window_size=60)  # 5 requests per minute
API_RATE_LIMIT = create_rate_limit_middleware(max_requests=100, window_size=60)  # 100 requests per minute
UPLOAD_RATE_LIMIT = create_rate_limit_middleware(max_requests=10, window_size=300)  # 10 uploads per 5 minutes

def get_user_rate_limit_key(request: Request) -> str:
    """Generate rate limit key based on authenticated user"""
    # Try to get user from request state (set by authentication middleware)
    user = getattr(request.state, 'user', None)
    if user:
        return f"user:{user.id}"
    
    # Fallback to IP
    return f"ip:{request.client.host}"

def get_endpoint_rate_limit_key(request: Request) -> str:
    """Generate rate limit key based on endpoint"""
    return f"endpoint:{request.method}:{request.url.path}:{request.client.host}"
