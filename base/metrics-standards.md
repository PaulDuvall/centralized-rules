# Metrics and Limits Standards

> **When to apply:** All applications requiring monitoring, observability, and performance tracking

Comprehensive standards for application metrics, performance limits, and monitoring best practices.

## Table of Contents

- [Core Principles](#core-principles)
- [Application Metrics](#application-metrics)
- [Performance Limits](#performance-limits)
- [Code Quality Metrics](#code-quality-metrics)
- [Infrastructure Metrics](#infrastructure-metrics)
- [Business Metrics](#business-metrics)
- [Monitoring and Alerting](#monitoring-and-alerting)

---

## Core Principles

### Why Metrics Matter

**Visibility**: You can't improve what you don't measure
**Accountability**: Metrics drive quality and performance standards
**Debugging**: Essential for troubleshooting production issues
**Capacity Planning**: Inform scaling decisions
**User Experience**: Track and improve customer satisfaction

### Golden Rules

1. **Measure What Matters** - Focus on actionable metrics
2. **Set Baselines** - Establish normal ranges
3. **Alert on Anomalies** - Detect issues automatically
4. **Track Trends** - Monitor changes over time
5. **Act on Data** - Metrics should drive decisions

---

## Application Metrics

### Response Time (Latency)

**Definition:** Time from request initiation to response completion

**Targets:**

| Endpoint Type | p50 | p95 | p99 | Max |
|---------------|-----|-----|-----|-----|
| API (Read) | <100ms | <200ms | <500ms | <2s |
| API (Write) | <200ms | <500ms | <1s | <5s |
| Web Page | <1s | <2s | <3s | <5s |
| Background Job | N/A | N/A | N/A | <30s |

**Why Percentiles:**
- p50 (median): Typical user experience
- p95: Experience for most users
- p99: Worst-case for active users
- Avoid average (hides outliers)

**Measurement:**

```python
import time
from functools import wraps
import logging

def measure_latency(func):
    """Decorator to measure and log function latency"""
    @wraps(func)
    def wrapper(*args, **kwargs):
        start_time = time.time()
        try:
            result = func(*args, **kwargs)
            return result
        finally:
            latency = (time.time() - start_time) * 1000  # Convert to ms
            logging.info(f"{func.__name__} latency: {latency:.2f}ms")
            # Send to metrics system
            metrics.histogram('function.latency',
                            latency,
                            tags={'function': func.__name__})
    return wrapper

@measure_latency
def get_user(user_id: int):
    return User.query.get(user_id)
```

### Throughput (Requests Per Second)

**Definition:** Number of requests processed per unit time

**Targets:**

| Service Type | Target RPS | Peak RPS | Notes |
|--------------|-----------|----------|-------|
| Public API | 1000+ | 5000+ | Must handle traffic spikes |
| Internal API | 100+ | 500+ | More predictable load |
| Background Workers | 10+ | 50+ | Async processing |

**Measurement:**

```python
from collections import Counter
from datetime import datetime, timedelta

class ThroughputTracker:
    def __init__(self, window_seconds=60):
        self.window = window_seconds
        self.requests = Counter()

    def record_request(self, endpoint: str):
        minute_bucket = datetime.utcnow().replace(second=0, microsecond=0)
        self.requests[(endpoint, minute_bucket)] += 1

    def get_rps(self, endpoint: str) -> float:
        """Get requests per second for last minute"""
        current_minute = datetime.utcnow().replace(second=0, microsecond=0)
        count = self.requests[(endpoint, current_minute)]
        return count / self.window

# Usage
tracker = ThroughputTracker()

@app.route('/api/users')
def list_users():
    tracker.record_request('/api/users')
    # ... handler logic
```

### Error Rates

**Definition:** Percentage of failed requests

**Targets:**

- **Success Rate:** >99.9% (three nines)
- **Error Rate:** <0.1%
- **5xx Errors:** <0.01% (server errors)
- **4xx Errors:** <1% (client errors acceptable)

**Error Budget:**

```
Annual Availability Target: 99.9%
Allowed Downtime: 8.76 hours/year = 43.8 minutes/month

Error Budget = (1 - 0.999) × Total Requests
If 1M requests/day: 1,000 failed requests/day allowed
```

**Tracking:**

```python
from prometheus_client import Counter, Gauge

# Define metrics
requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

error_rate = Gauge(
    'http_error_rate',
    'HTTP error rate',
    ['service']
)

def track_request(endpoint, method, status_code):
    """Track request metrics"""
    requests_total.labels(
        method=method,
        endpoint=endpoint,
        status=status_code
    ).inc()

    # Calculate error rate
    if status_code >= 500:
        # Update error rate gauge
        total = requests_total._metrics.values()
        errors = sum(1 for m in total if m._value >= 500)
        error_rate.labels(service='api').set(errors / len(total))
```

### Resource Utilization

**CPU:**
- **Normal:** <70% average
- **Warning:** >70% sustained
- **Critical:** >90% sustained
- **Auto-scale:** >80% for 5 minutes

**Memory:**
- **Normal:** <80% utilization
- **Warning:** >80%
- **Critical:** >90%
- **OOM Risk:** >95%

**Disk:**
- **Normal:** <70% utilization
- **Warning:** >80%
- **Critical:** >90%
- **Alert:** >95%

**Database Connections:**
- **Pool Size:** 20-100 connections
- **Normal:** <70% pool utilization
- **Warning:** >80% pool utilization
- **Critical:** >95% pool utilization

---

## Performance Limits

### API Rate Limits

**Purpose:** Prevent abuse, ensure fair usage, protect infrastructure

**Standard Limits:**

| User Type | Requests/Minute | Requests/Hour | Requests/Day |
|-----------|----------------|---------------|--------------|
| Anonymous | 10 | 100 | 1,000 |
| Authenticated | 60 | 1,000 | 10,000 |
| Premium | 300 | 5,000 | 50,000 |
| Enterprise | Custom | Custom | Custom |

**Implementation:**

```python
from functools import wraps
from flask import request, jsonify
import redis

redis_client = redis.Redis(host='localhost', port=6379, db=0)

def rate_limit(max_requests: int, window_seconds: int):
    """Rate limit decorator"""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Identify user (IP or user_id)
            user_id = get_current_user_id() or request.remote_addr
            key = f"rate_limit:{func.__name__}:{user_id}"

            # Increment counter
            current = redis_client.incr(key)

            # Set expiry on first request
            if current == 1:
                redis_client.expire(key, window_seconds)

            # Check limit
            if current > max_requests:
                return jsonify({
                    'error': 'Rate limit exceeded',
                    'retry_after': redis_client.ttl(key)
                }), 429

            return func(*args, **kwargs)
        return wrapper
    return decorator

@app.route('/api/search')
@rate_limit(max_requests=10, window_seconds=60)
def search():
    # API logic
    pass
```

### Request Size Limits

**HTTP Request:**
- **Headers:** 8 KB maximum
- **URL:** 2 KB maximum
- **JSON Body:** 1 MB maximum
- **File Upload:** 10 MB maximum (configurable)
- **Multipart Form:** 25 MB maximum

**Database:**
- **Query Timeout:** 30 seconds
- **Max Rows Returned:** 1,000 (use pagination)
- **Transaction Timeout:** 60 seconds

**Configuration:**

```python
# Flask example
app.config['MAX_CONTENT_LENGTH'] = 10 * 1024 * 1024  # 10 MB

@app.errorhandler(413)
def request_entity_too_large(error):
    return jsonify({
        'error': 'Request too large',
        'max_size': '10 MB'
    }), 413

# Database query limits
def get_users(limit: int = 100):
    if limit > 1000:
        raise ValueError("Cannot fetch more than 1,000 users at once")

    return User.query.limit(limit).all()
```

### Timeout Standards

| Operation Type | Timeout | Retry Strategy |
|----------------|---------|----------------|
| Database Query | 30s | No retry |
| External API Call | 10s | Retry 3x with backoff |
| Cache Read | 100ms | Fallback to source |
| File I/O | 60s | Retry 2x |
| Background Job | 5min | Retry with exponential backoff |

**Implementation:**

```python
import requests
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry

def create_http_session():
    """Create HTTP session with timeouts and retries"""
    session = requests.Session()

    # Retry strategy
    retry = Retry(
        total=3,
        backoff_factor=0.3,
        status_forcelist=[500, 502, 503, 504]
    )

    adapter = HTTPAdapter(max_retries=retry)
    session.mount('http://', adapter)
    session.mount('https://', adapter)

    return session

# Usage with timeout
session = create_http_session()
response = session.get('https://api.example.com/data', timeout=10)
```

---

## Code Quality Metrics

### Test Coverage

**Targets:**

| Code Type | Minimum Coverage | Target Coverage |
|-----------|-----------------|-----------------|
| Business Logic | 90% | 95%+ |
| API Handlers | 80% | 90% |
| Utilities | 85% | 95% |
| UI Components | 70% | 80% |
| Overall | 80% | 85%+ |

**Configuration:**

```bash
# pytest coverage
pytest --cov=src --cov-report=html --cov-fail-under=80

# Coverage config (pyproject.toml)
[tool.coverage.run]
source = ["src"]
omit = ["*/tests/*", "*/migrations/*"]

[tool.coverage.report]
fail_under = 80
exclude_lines = [
    "pragma: no cover",
    "def __repr__",
    "raise NotImplementedError",
]
```

### Code Complexity

**Cyclomatic Complexity:**
- **Target:** <10 per function
- **Warning:** 10-15
- **Refactor Required:** >15

**Function Length:**
- **Target:** <50 lines
- **Warning:** 50-100 lines
- **Refactor Required:** >100 lines

**Class Size:**
- **Target:** <300 lines
- **Warning:** 300-500 lines
- **Refactor Required:** >500 lines

**Tools:**

```bash
# Python complexity check
pip install radon
radon cc src/ -s  # Cyclomatic complexity
radon mi src/     # Maintainability index

# Fail on high complexity
radon cc src/ --min C  # Warn on complexity > 10
```

### Code Duplication

**Targets:**
- **Duplication:** <5% of codebase
- **Clone Coverage:** <3%

**Tools:**

```bash
# Python
pip install pylint
pylint --disable=all --enable=duplicate-code src/

# JavaScript
npx jscpd src/
```

---

## Infrastructure Metrics

### Database Performance

**Query Performance:**
- **p95 Query Time:** <100ms
- **p99 Query Time:** <500ms
- **Slow Query:** >1s (log and investigate)

**Connection Pool:**
- **Pool Size:** 20 connections (development), 100 (production)
- **Min Idle:** 5 connections
- **Max Wait:** 30 seconds
- **Validation Interval:** 30 seconds

**Monitoring:**

```python
from sqlalchemy import event
from sqlalchemy.engine import Engine
import logging
import time

@event.listens_for(Engine, "before_cursor_execute")
def before_cursor_execute(conn, cursor, statement, parameters, context, executemany):
    conn.info.setdefault('query_start_time', []).append(time.time())

@event.listens_for(Engine, "after_cursor_execute")
def after_cursor_execute(conn, cursor, statement, parameters, context, executemany):
    total = time.time() - conn.info['query_start_time'].pop(-1)

    # Log slow queries
    if total > 1.0:
        logging.warning(f"Slow query ({total:.2f}s): {statement}")

    # Send to metrics
    metrics.histogram('database.query_time', total * 1000)
```

### Cache Performance

**Hit Rate:**
- **Target:** >80% cache hit rate
- **Warning:** <70% hit rate
- **Investigation:** <50% hit rate

**Metrics:**

```python
from functools import wraps
import redis

class CacheMonitor:
    def __init__(self):
        self.hits = 0
        self.misses = 0

    def record_hit(self):
        self.hits += 1

    def record_miss(self):
        self.misses += 1

    def hit_rate(self) -> float:
        total = self.hits + self.misses
        if total == 0:
            return 0.0
        return self.hits / total

cache_monitor = CacheMonitor()

def cached(ttl=3600):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            key = f"{func.__name__}:{args}:{kwargs}"

            # Try cache
            cached_value = redis_client.get(key)
            if cached_value:
                cache_monitor.record_hit()
                return pickle.loads(cached_value)

            # Cache miss
            cache_monitor.record_miss()
            result = func(*args, **kwargs)
            redis_client.setex(key, ttl, pickle.dumps(result))
            return result
        return wrapper
    return decorator
```

### Message Queue Metrics

**Processing Time:**
- **Target:** <1s per message
- **Warning:** >5s per message
- **Critical:** >30s per message

**Queue Depth:**
- **Normal:** <100 messages
- **Warning:** >500 messages
- **Critical:** >1000 messages (backlog)

**Dead Letter Queue:**
- **Target:** 0 messages
- **Investigation:** >10 messages
- **Critical:** >100 messages

---

## Business Metrics

### User Engagement

**Daily Active Users (DAU):**
- Track unique users per day
- Monitor trends week-over-week
- Segment by user cohort

**Session Duration:**
- **Target:** >5 minutes per session
- Track by feature/page
- Identify drop-off points

**Conversion Rates:**
- **Sign-up → Activation:** >40%
- **Free → Paid:** >2%
- **Trial → Paid:** >25%

### Feature Adoption

**New Feature Usage:**
- Track adoption rate
- **Target:** >20% of users try new feature within 30 days
- **Success:** >50% continue using after first week

**Feature Metrics:**

```python
from datetime import datetime

class FeatureMetrics:
    def __init__(self, feature_name: str):
        self.feature_name = feature_name

    def track_usage(self, user_id: str):
        """Track feature usage"""
        metrics.increment(
            'feature.usage',
            tags={
                'feature': self.feature_name,
                'user_id': user_id
            }
        )

    def track_adoption_rate(self):
        """Calculate feature adoption rate"""
        total_users = User.query.filter(
            User.created_at >= datetime.now() - timedelta(days=30)
        ).count()

        feature_users = FeatureUsage.query.filter(
            FeatureUsage.feature == self.feature_name,
            FeatureUsage.first_used >= datetime.now() - timedelta(days=30)
        ).distinct(FeatureUsage.user_id).count()

        adoption_rate = (feature_users / total_users) * 100
        metrics.gauge('feature.adoption_rate',
                     adoption_rate,
                     tags={'feature': self.feature_name})

        return adoption_rate
```

### Revenue Metrics

**Monthly Recurring Revenue (MRR):**
- Track MRR growth
- **Target:** >10% MoM growth
- Segment by plan tier

**Customer Lifetime Value (CLV):**
- Calculate expected revenue per customer
- **Target:** CLV > 3× Customer Acquisition Cost (CAC)
- Monitor by cohort

**Churn Rate:**
- **Target:** <5% monthly churn
- **Warning:** >7% monthly churn
- **Critical:** >10% monthly churn

---

## Monitoring and Alerting

### Alert Severity Levels

| Level | Response Time | Examples |
|-------|--------------|----------|
| **Critical** | Immediate (page on-call) | Service down, data loss |
| **High** | 15 minutes | Error rate spike, slow responses |
| **Medium** | 1 hour | Resource warnings, degraded performance |
| **Low** | Next business day | Trend warnings, capacity planning |

### Alert Configuration

**Good Alert Characteristics:**
- **Actionable**: Clear what to do
- **Specific**: Precise problem description
- **Contextual**: Includes relevant data
- **Timely**: Fires at right threshold
- **Non-flappy**: Avoids false positives

**Example Alert:**

```yaml
# Prometheus alert rules
groups:
  - name: api_alerts
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value }}% for {{ $labels.endpoint }}"

      - alert: SlowResponseTime
        expr: histogram_quantile(0.95, http_request_duration_seconds) > 1
        for: 10m
        labels:
          severity: high
        annotations:
          summary: "Slow API responses"
          description: "p95 latency is {{ $value }}s"
```

### Dashboard Recommendations

**Essential Dashboards:**

1. **Service Health**
   - Request rate
   - Error rate
   - Response time (p50, p95, p99)
   - Apdex score

2. **Infrastructure**
   - CPU, memory, disk utilization
   - Network throughput
   - Database connections
   - Cache hit rate

3. **Business Metrics**
   - Active users
   - Conversion rates
   - Revenue trends
   - Feature adoption

---

## Summary: Metrics Standards

### Application
- **Latency:** p95 <200ms, p99 <500ms
- **Error Rate:** <0.1%
- **Availability:** >99.9%

### Performance
- **API Rate Limit:** 60 req/min authenticated
- **Request Size:** <1 MB JSON
- **Timeout:** 30s database, 10s API

### Code Quality
- **Coverage:** >80%
- **Complexity:** <10 per function
- **Duplication:** <5%

### Infrastructure
- **CPU:** <70% average
- **Memory:** <80%
- **Cache Hit Rate:** >80%

---

## Related Resources

- See `base/testing-philosophy.md` for test coverage standards
- See `base/12-factor-app.md` for application architecture
- See `cloud/aws/well-architected.md` for AWS monitoring
- See `base/architecture-principles.md` for design principles
