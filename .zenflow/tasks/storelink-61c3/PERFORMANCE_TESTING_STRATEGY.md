# Performance Testing Strategy - StoreLink

## Overview
This document outlines the performance testing strategy for the StoreLink platform to ensure it meets production-grade performance requirements for Indian MSME businesses.

---

## Performance Goals

### Response Time Targets
- **API Endpoints**: < 200ms for 95th percentile
- **Database Queries**: < 100ms for single queries
- **File Uploads**: < 2s for images up to 5MB
- **Report Generation**: < 5s for PDF/CSV exports
- **Dashboard Load**: < 500ms for initial load

### Throughput Targets
- **Concurrent Users**: Support 100 concurrent users per server instance
- **Requests Per Second**: Handle 500 RPS for read operations
- **Write Operations**: Handle 100 RPS for order creation

### Resource Utilization
- **CPU Usage**: < 70% under normal load
- **Memory Usage**: < 1GB per server instance
- **Database Connections**: Max 50 concurrent connections
- **File Storage**: Efficient cleanup of temporary files

---

## Performance Testing Tools

### Recommended Tools
1. **Locust** - Python-based load testing framework
2. **Apache JMeter** - Industry-standard load testing tool
3. **k6** - Modern load testing tool with JavaScript scripting
4. **wrk** - HTTP benchmarking tool for quick tests
5. **py-spy** - Python profiler for identifying bottlenecks

### Database Performance Tools
- **MySQL EXPLAIN** - Query execution plan analysis
- **MySQL Slow Query Log** - Identify slow queries
- **Percona Toolkit** - Advanced MySQL performance analysis

---

## Load Testing Scenarios

### Scenario 1: Normal Business Operations
**Duration**: 30 minutes  
**Users**: 50 concurrent users  
**Operations**:
- 40% Product browsing (GET /v1/products)
- 30% Order creation (POST /v1/orders/)
- 20% Customer lookup (GET /v1/customers)
- 10% Dashboard access (GET /v1/dashboard)

**Success Criteria**:
- 95th percentile response time < 200ms
- Error rate < 0.1%
- No database connection pool exhaustion

### Scenario 2: Peak Load
**Duration**: 15 minutes  
**Users**: 150 concurrent users  
**Operations**: Same distribution as Scenario 1

**Success Criteria**:
- 95th percentile response time < 500ms
- Error rate < 1%
- Graceful degradation under load

### Scenario 3: Report Generation Stress Test
**Duration**: 10 minutes  
**Users**: 20 concurrent users  
**Operations**:
- 50% PDF export (GET /v1/reports/export/pdf)
- 50% CSV export (GET /v1/reports/export/csv)

**Success Criteria**:
- All reports generated successfully
- Report generation time < 10s
- No memory leaks

### Scenario 4: Database Heavy Operations
**Duration**: 20 minutes  
**Users**: 100 concurrent users  
**Operations**:
- 40% Order creation with 5+ items
- 30% Product search with filters
- 30% Customer order history

**Success Criteria**:
- Database CPU < 80%
- No deadlocks or transaction timeouts
- Query response time < 150ms

### Scenario 5: Spike Test
**Duration**: 10 minutes  
**Ramp-up**: 0 to 200 users in 2 minutes  
**Ramp-down**: 200 to 0 users in 2 minutes

**Success Criteria**:
- System remains stable during spike
- No crashes or service unavailability
- Metrics return to normal after spike

---

## Performance Testing Implementation

### Locust Load Test Example

```python
# locustfile.py
from locust import HttpUser, task, between
import random

class StoreLinUser(HttpUser):
    wait_time = between(1, 3)
    
    def on_start(self):
        # Login
        response = self.client.post("/v1/auth/login", json={
            "phone": "9876543210",
            "password": "TestPassword123"
        })
        self.token = response.json()["data"]["tokens"]["access_token"]
        self.headers = {"Authorization": f"Bearer {self.token}"}
    
    @task(4)
    def list_products(self):
        self.client.get("/v1/products", headers=self.headers)
    
    @task(3)
    def create_order(self):
        order_data = {
            "items": [
                {
                    "product_uuid": "test-product-uuid",
                    "quantity": random.randint(1, 5)
                }
            ],
            "payment_method": "Cash",
            "tax_amount": 100.00,
            "discount_amount": 0.00
        }
        self.client.post("/v1/orders/", json=order_data, headers=self.headers)
    
    @task(2)
    def list_customers(self):
        self.client.get("/v1/customers", headers=self.headers)
    
    @task(1)
    def get_dashboard(self):
        self.client.get("/v1/dashboard", headers=self.headers)
```

### Running Load Tests

```bash
# Install Locust
pip install locust

# Run load test
locust -f locustfile.py --host=http://localhost:8000

# Headless mode
locust -f locustfile.py --host=http://localhost:8000 \
  --users 100 --spawn-rate 10 --run-time 30m --headless
```

---

## Database Performance Optimization

### Index Strategy

```sql
-- Products table indexes
CREATE INDEX idx_products_business_id ON products(business_id);
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_is_active ON products(is_active);
CREATE INDEX idx_products_name ON products(name);

-- Orders table indexes
CREATE INDEX idx_orders_business_id ON orders(business_id);
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_payment_status ON orders(payment_status);
CREATE INDEX idx_orders_created_at ON orders(created_at);

-- Customers table indexes
CREATE INDEX idx_customers_business_id ON customers(business_id);
CREATE INDEX idx_customers_phone ON customers(phone);
CREATE INDEX idx_customers_name ON customers(name);

-- Composite indexes for common queries
CREATE INDEX idx_products_business_active ON products(business_id, is_active);
CREATE INDEX idx_orders_business_date ON orders(business_id, created_at DESC);
```

### Query Optimization Checklist
- [ ] All foreign keys have indexes
- [ ] Frequently filtered columns are indexed
- [ ] Composite indexes for multi-column WHERE clauses
- [ ] Use LIMIT for paginated queries
- [ ] Avoid SELECT * - specify required columns
- [ ] Use JOIN instead of multiple queries
- [ ] Batch operations where possible

---

## Caching Strategy

### Redis Caching Implementation

```python
# Cache frequently accessed data
CACHE_CONFIG = {
    "business_profile": 3600,  # 1 hour
    "product_list": 300,       # 5 minutes
    "dashboard_stats": 600,    # 10 minutes
    "plan_limits": 3600        # 1 hour
}

# Cache invalidation on data changes
- Product created/updated/deleted → Clear product_list cache
- Order created → Clear dashboard_stats cache
- Business updated → Clear business_profile cache
```

### Cache Implementation Example

```python
import redis
import json
from functools import wraps

redis_client = redis.Redis(host='localhost', port=6379, db=0)

def cache_result(key_prefix: str, ttl: int = 300):
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            cache_key = f"{key_prefix}:{args}:{kwargs}"
            
            # Try to get from cache
            cached = redis_client.get(cache_key)
            if cached:
                return json.loads(cached)
            
            # Execute function and cache result
            result = await func(*args, **kwargs)
            redis_client.setex(cache_key, ttl, json.dumps(result))
            return result
        
        return wrapper
    return decorator
```

---

## API Rate Limiting

### Configuration
```python
# Rate limiting settings
RATE_LIMITS = {
    "anonymous": "20/minute",
    "authenticated": "100/minute",
    "paid_plan": "500/minute",
    "admin": "1000/minute"
}

# Endpoint-specific limits
ENDPOINT_LIMITS = {
    "/v1/auth/login": "5/minute",
    "/v1/auth/register": "3/minute",
    "/v1/reports/export/*": "10/hour"
}
```

---

## Profiling and Monitoring

### Application Profiling

```bash
# Profile with py-spy
py-spy top --pid <PID>

# Generate flame graph
py-spy record -o profile.svg --pid <PID> --duration 60

# Profile specific endpoint
py-spy record -o endpoint_profile.svg -- python -m uvicorn app.main:app
```

### Monitoring Metrics

**Key Metrics to Track**:
1. **Response Time**: p50, p95, p99 percentiles
2. **Throughput**: Requests per second
3. **Error Rate**: 4xx and 5xx responses
4. **Database Metrics**:
   - Query execution time
   - Connection pool usage
   - Slow query count
5. **System Metrics**:
   - CPU utilization
   - Memory usage
   - Disk I/O
   - Network bandwidth

### Monitoring Tools
- **Prometheus** - Metrics collection
- **Grafana** - Visualization dashboards
- **New Relic** / **DataDog** - APM solutions
- **Sentry** - Error tracking

---

## Performance Benchmarking

### Baseline Performance Tests

```bash
# Simple endpoint benchmark with wrk
wrk -t4 -c100 -d30s --latency \
  -H "Authorization: Bearer <token>" \
  http://localhost:8000/v1/products

# Apache Bench for quick tests
ab -n 1000 -c 10 -H "Authorization: Bearer <token>" \
  http://localhost:8000/v1/dashboard
```

### Expected Baseline Results
- **GET /v1/products**: 1000 req/s, 50ms avg latency
- **GET /v1/dashboard**: 500 req/s, 100ms avg latency
- **POST /v1/orders/**: 200 req/s, 150ms avg latency
- **GET /v1/reports/sales**: 50 req/s, 300ms avg latency

---

## Performance Optimization Checklist

### Code Level
- [ ] Use async/await for I/O operations
- [ ] Batch database queries where possible
- [ ] Implement connection pooling
- [ ] Use lazy loading for relationships
- [ ] Minimize N+1 query problems
- [ ] Implement pagination for all list endpoints
- [ ] Use background tasks for heavy operations

### Database Level
- [ ] Proper indexing on all foreign keys
- [ ] Composite indexes for common queries
- [ ] Query optimization with EXPLAIN
- [ ] Connection pool tuning
- [ ] Regular VACUUM and ANALYZE (if PostgreSQL)
- [ ] Partition large tables if needed

### Infrastructure Level
- [ ] Enable GZIP compression
- [ ] Use CDN for static assets
- [ ] Implement Redis caching
- [ ] Configure proper keep-alive settings
- [ ] Use connection pooling
- [ ] Set up load balancing for multiple instances

### API Level
- [ ] Implement rate limiting
- [ ] Use ETag for cache validation
- [ ] Return only required fields
- [ ] Implement proper pagination
- [ ] Use HTTP/2 if possible
- [ ] Enable CORS caching

---

## Load Testing Schedule

### Pre-Production Testing
1. **Week 1**: Baseline performance tests
2. **Week 2**: Load testing with normal scenarios
3. **Week 3**: Stress testing and peak load scenarios
4. **Week 4**: Endurance testing (24-hour test)

### Production Monitoring
- **Daily**: Automated performance checks
- **Weekly**: Performance trend analysis
- **Monthly**: Full load testing in staging
- **Quarterly**: Capacity planning review

---

## Performance Degradation Response

### Alert Thresholds
- **Critical**: Response time > 1s for 5 minutes
- **Warning**: Response time > 500ms for 10 minutes
- **Info**: Error rate > 1% for 5 minutes

### Response Actions
1. Check application logs for errors
2. Review database slow query log
3. Check system resource utilization
4. Verify external dependencies (Redis, file storage)
5. Scale horizontally if needed
6. Implement temporary rate limiting

---

## Performance Testing Results Template

```
=== Performance Test Results ===

Test Date: [DATE]
Test Duration: [DURATION]
Test Scenario: [SCENARIO NAME]

## Configuration
- Server: [SPECS]
- Database: MySQL 8.0 / [SPECS]
- Redis: [VERSION]
- Load Tool: [TOOL NAME]

## Results

### Response Times
- p50: [VALUE]ms
- p95: [VALUE]ms
- p99: [VALUE]ms
- Max: [VALUE]ms

### Throughput
- Total Requests: [COUNT]
- Requests/Second: [VALUE]
- Success Rate: [VALUE]%
- Error Rate: [VALUE]%

### Resource Utilization
- CPU Average: [VALUE]%
- CPU Peak: [VALUE]%
- Memory Average: [VALUE]MB
- Memory Peak: [VALUE]MB
- Database Connections: [VALUE]

## Issues Identified
1. [ISSUE 1]
2. [ISSUE 2]

## Recommendations
1. [RECOMMENDATION 1]
2. [RECOMMENDATION 2]
```

---

## Continuous Performance Improvement

### Regular Reviews
- Review slow query logs weekly
- Analyze performance metrics monthly
- Update indexes based on query patterns
- Optimize hot code paths
- Review and update caching strategy

### Performance KPIs
- API response time (p95)
- Database query time (p95)
- Error rate
- Throughput (req/s)
- User satisfaction score

---

## Conclusion

Performance testing is an ongoing process. Regular testing, monitoring, and optimization ensure StoreLink remains fast and responsive for Indian MSME businesses as the platform scales.

**Key Takeaways**:
1. Test early and test often
2. Monitor production performance continuously
3. Optimize based on real user patterns
4. Scale proactively before hitting limits
5. Document and share performance insights
