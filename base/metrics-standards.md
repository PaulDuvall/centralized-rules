# Metrics and Limits Standards
<!-- TIP: Measure what matters - you can't improve what you don't measure -->

> **When to apply:** All applications requiring monitoring, observability, and performance tracking

## Core Principles

1. **Measure What Matters** - Focus on actionable metrics
2. **Set Baselines** - Establish normal ranges
3. **Alert on Anomalies** - Detect issues automatically
4. **Track Trends** - Monitor changes over time
5. **Act on Data** - Metrics should drive decisions

---

## Application Metrics

### Response Time and Throughput

| Metric | p50 | p95 | p99 | Max | Target RPS |
|--------|-----|-----|-----|-----|------------|
| API Read | <100ms | <200ms | <500ms | <2s | 1000+ |
| API Write | <200ms | <500ms | <1s | <5s | 1000+ |
| Web Page | <1s | <2s | <3s | <5s | N/A |
| Background Job | N/A | N/A | N/A | <30s | 10+ |

**Why Percentiles:** p50 shows typical experience, p95 covers most users, p99 catches worst-case scenarios. Never use averages (hide outliers).

**Measurement:**

```python
import time
from functools import wraps

def measure_latency(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        start_time = time.time()
        try:
            return func(*args, **kwargs)
        finally:
            latency = (time.time() - start_time) * 1000
            metrics.histogram('function.latency', latency, tags={'function': func.__name__})
    return wrapper
```

### Error Rates and Availability

| Metric | Target | Notes |
|--------|--------|-------|
| Success Rate | >99.9% | Three nines availability |
| Error Rate | <0.1% | Overall failure rate |
| 5xx Errors | <0.01% | Server errors |
| 4xx Errors | <1% | Client errors acceptable |

**Error Budget:** 99.9% uptime = 43.8 minutes downtime/month

```python
from prometheus_client import Counter

requests_total = Counter('http_requests_total', 'Total HTTP requests',
                        ['method', 'endpoint', 'status'])

def track_request(endpoint, method, status_code):
    requests_total.labels(method=method, endpoint=endpoint, status=status_code).inc()
```

### Resource Utilization

| Resource | Normal | Warning | Critical | Action |
|----------|--------|---------|----------|--------|
| CPU | <70% | >70% | >90% | Auto-scale >80% for 5min |
| Memory | <80% | >80% | >90% | Alert >95% (OOM risk) |
| Disk | <70% | >80% | >90% | Alert >95% |
| DB Connections | <70% pool | >80% pool | >95% pool | Pool: 20-100 connections |

---

## Performance Limits

### Rate Limits and Request Size

| User Type | Req/Min | Req/Hour | Req/Day |
|-----------|---------|----------|---------|
| Anonymous | 10 | 100 | 1,000 |
| Authenticated | 60 | 1,000 | 10,000 |
| Premium | 300 | 5,000 | 50,000 |
| Enterprise | Custom | Custom | Custom |

| Limit Type | Size/Timeout |
|------------|-------------|
| HTTP Headers | 8 KB max |
| URL | 2 KB max |
| JSON Body | 1 MB max |
| File Upload | 10 MB max |
| Multipart Form | 25 MB max |

**Implementation:**

```python
from functools import wraps
import redis

redis_client = redis.Redis()

def rate_limit(max_requests: int, window_seconds: int):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            user_id = get_current_user_id() or request.remote_addr
            key = f"rate_limit:{func.__name__}:{user_id}"
            current = redis_client.incr(key)
            if current == 1:
                redis_client.expire(key, window_seconds)
            if current > max_requests:
                return jsonify({'error': 'Rate limit exceeded',
                              'retry_after': redis_client.ttl(key)}), 429
            return func(*args, **kwargs)
        return wrapper
    return decorator
```

### Timeout Standards

| Operation | Timeout | Retry Strategy |
|-----------|---------|----------------|
| Database Query | 30s | No retry |
| External API | 10s | 3x with exponential backoff |
| Cache Read | 100ms | Fallback to source |
| File I/O | 60s | 2x retry |
| Background Job | 5min | Exponential backoff |

**Implementation:**

```python
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

def create_http_session():
    session = requests.Session()
    retry = Retry(total=3, backoff_factor=0.3, status_forcelist=[500, 502, 503, 504])
    session.mount('http://', HTTPAdapter(max_retries=retry))
    session.mount('https://', HTTPAdapter(max_retries=retry))
    return session

# Usage
session = create_http_session()
response = session.get('https://api.example.com/data', timeout=10)
```

---

## Code Quality Metrics

| Metric | Minimum | Target | Refactor At |
|--------|---------|--------|-------------|
| **Test Coverage** | | | |
| Business Logic | 90% | 95%+ | N/A |
| API Handlers | 80% | 90% | N/A |
| Overall | 80% | 85%+ | N/A |
| **Complexity** | | | |
| Cyclomatic Complexity | <10 | <10 | >15 |
| Function Length | <50 lines | <50 lines | >100 lines |
| Class Size | <300 lines | <300 lines | >500 lines |
| **Duplication** | | | |
| Code Duplication | <5% | <3% | N/A |

**Tools:**

```bash
# Coverage
pytest --cov=src --cov-report=html --cov-fail-under=80

# Complexity
radon cc src/ --min C  # Warn on complexity > 10
radon mi src/          # Maintainability index

# Duplication
pylint --disable=all --enable=duplicate-code src/
```

---

## Infrastructure Metrics

### Database Performance

| Metric | Target | Warning | Notes |
|--------|--------|---------|-------|
| p95 Query Time | <100ms | >100ms | Log queries >1s |
| p99 Query Time | <500ms | >500ms | Investigate slow queries |
| Pool Size | 20-100 | N/A | 5 min idle connections |
| Max Wait Time | <30s | >30s | Connection timeout |

**Monitoring:**

```python
from sqlalchemy import event
import time

@event.listens_for(Engine, "before_cursor_execute")
def before_cursor_execute(conn, cursor, statement, parameters, context, executemany):
    conn.info.setdefault('query_start_time', []).append(time.time())

@event.listens_for(Engine, "after_cursor_execute")
def after_cursor_execute(conn, cursor, statement, parameters, context, executemany):
    total = time.time() - conn.info['query_start_time'].pop(-1)
    if total > 1.0:
        logging.warning(f"Slow query ({total:.2f}s): {statement}")
    metrics.histogram('database.query_time', total * 1000)
```

### Cache and Queue Performance

| System | Metric | Target | Warning | Critical |
|--------|--------|--------|---------|----------|
| **Cache** | Hit Rate | >80% | <70% | <50% |
| **Queue** | Processing Time | <1s/msg | >5s/msg | >30s/msg |
| **Queue** | Queue Depth | <100 msgs | >500 msgs | >1000 msgs |
| **DLQ** | Messages | 0 | >10 msgs | >100 msgs |

---

## Business Metrics

### User Engagement and Conversion

| Metric | Target | Notes |
|--------|--------|-------|
| Session Duration | >5 min | Track by feature/page |
| Sign-up → Activation | >40% | First meaningful action |
| Free → Paid | >2% | Conversion rate |
| Trial → Paid | >25% | After trial period |
| New Feature Adoption | >20% in 30 days | % of users trying feature |
| Feature Retention | >50% after week 1 | Continued usage |

### Revenue Health

| Metric | Target | Warning | Notes |
|--------|--------|---------|-------|
| MRR Growth | >10% MoM | <5% | Monthly recurring revenue |
| CLV/CAC Ratio | >3:1 | <2:1 | Lifetime value vs acquisition cost |
| Monthly Churn | <5% | >7% | Critical: >10% |

---

## Monitoring and Alerting

### Alert Severity

| Level | Response Time | Examples |
|-------|--------------|----------|
| Critical | Immediate (page) | Service down, data loss |
| High | 15 minutes | Error spike, slow responses |
| Medium | 1 hour | Resource warnings, degraded performance |
| Low | Next business day | Trends, capacity planning |

### Alert Best Practices

**Good alerts are:**
- **Actionable**: Clear what to do
- **Specific**: Precise problem
- **Contextual**: Include relevant data
- **Timely**: Fire at right threshold
- **Non-flappy**: Avoid false positives

**Example Prometheus Rules:**

```yaml
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

### Essential Dashboards

1. **Service Health**: Request rate, error rate, response time (p50/p95/p99), Apdex score
2. **Infrastructure**: CPU/memory/disk, network throughput, DB connections, cache hit rate
3. **Business Metrics**: Active users, conversions, revenue, feature adoption

---

## Quick Reference

| Category | Key Metrics | Targets |
|----------|-------------|---------|
| **Performance** | API latency (p95), throughput | <200ms, >1000 RPS |
| **Reliability** | Error rate, availability | <0.1%, >99.9% |
| **Resources** | CPU, memory, disk | <70%, <80%, <70% |
| **Quality** | Test coverage, complexity | >80%, <10 |
| **Business** | DAU, conversion, churn | Track trends, <5% churn |

---

## Related Resources

- `base/testing-philosophy.md` - Test coverage standards
- `base/12-factor-app.md` - Application architecture
- `cloud/aws/well-architected.md` - AWS monitoring
- `base/architecture-principles.md` - Design principles
