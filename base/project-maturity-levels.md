# Project Maturity Levels: Progressive Rigor Framework

> **When to apply:** All projects - determines which rules and practices to prioritize based on project phase

Apply the right level of rigor at the right time. Different project phases require different levels of discipline, tooling, and process overhead.

## Maturity Levels

### Level 1: MVP/POC/Prototype

**Goal:** Validate assumptions, learn fast, prove viability
**Timeline:** Days to weeks (2-8 weeks)
**Team:** 1-3 developers

**Characteristics:**
- Exploring product-market fit or technical feasibility
- Limited users or internal-only usage
- Acceptable to throw away and rebuild
- No sensitive data or compliance requirements

**Practices:**

| Category | Approach |
|----------|----------|
| **Essential** | AI-assisted development, basic SOLID principles, git with meaningful commits, simple deployment, basic error handling, manual testing + critical unit tests |
| **Simplified** | Happy path testing, monolith architecture, README only, env vars for secrets, console logs |
| **Skip** | Comprehensive test coverage, CI/CD pipelines, observability dashboards, DR planning, performance optimization, complex patterns, security audits, load testing, multi-region deployment |

**Quality Bar:** Readable code, no obvious bugs, basic type safety, no hardcoded credentials, version control

---

### Level 2: Pre-Production/Beta

**Goal:** Prepare for limited production use, establish quality baseline
**Timeline:** Weeks to months (1-3 months)
**Team:** 3-10 developers

**Characteristics:**
- Product-market fit validated, moving toward launch
- Limited external users (beta testers, early adopters)
- Some users depend on the system
- May handle real but non-critical data

**Practices:**

| Category | Approach |
|----------|----------|
| **Add to Essential** | Automated tests for core features, 12-factor config, basic metrics/logging, security fundamentals, CI/CD basics, code review, monitoring/alerting, vulnerability scanning, staging environment |
| **Moderate Rigor** | 60-70% test coverage of critical paths, modular architecture, API documentation, HTTPS + OWASP Top 10, application logs + error tracking, identify obvious bottlenecks |
| **Still Skip** | 90%+ coverage requirements, chaos engineering, distributed tracing, multi-region active-active, formal SLAs/SLOs, 24/7 on-call, enterprise compliance |

**Quality Bar:** All tests pass before merge, no critical vulnerabilities, code review required, documented API contracts, rollback capability, monitor error rates

---

### Level 3: Production

**Goal:** Reliable, secure, scalable system supporting real users and business value
**Timeline:** Ongoing (months to years)

**Characteristics:**
- Live production traffic from paying customers
- Users depend on system availability
- Handles sensitive, regulated, or business-critical data
- Financial or reputational impact from downtime

**Required Capabilities:**
- Automated testing with 80%+ coverage for critical code
- CI/CD with security scanning
- Monitoring, alerting, and on-call rotation
- Secrets management (vault, cloud provider secrets)
- Database backups and recovery procedures
- Staging environment mirroring production
- Deployment rollback capability
- Incident response runbooks
- Regular security updates and patching

**Quality Bar:** Comprehensive coverage, security review for sensitive changes, performance testing for critical paths, API documentation, key metrics monitoring, runbooks for common incidents, regular dependency updates, compliance with relevant standards

---

## Decision Matrix

### By Practice Category

| Practice Category | MVP/POC | Pre-Production | Production |
|------------------|---------|----------------|------------|
| **Testing** | Manual + critical unit tests | Automated, 60-70% coverage | Automated, 80%+ coverage, E2E tests |
| **CI/CD** | Optional, manual OK | Basic automation | Full pipeline with gates |
| **Security** | Env vars, basic validation | HTTPS, OWASP Top 10, scanning | Hardened, audited, compliance |
| **Monitoring** | Console logs | Error tracking, basic metrics | Full observability (metrics/logs/traces) |
| **Documentation** | README only | API docs, deployment guide | Comprehensive (architecture, runbooks, API) |
| **Architecture** | Monolith, simple | Modular, separation of concerns | Scalable, resilient, well-architected |
| **Deployment** | Manual is OK | Automated to staging/prod | Zero-downtime, rollback, blue-green |
| **Performance** | "Fast enough" | Identify bottlenecks | Optimized, load tested |
| **Disaster Recovery** | None needed | Basic backups | Full DR plan, tested regularly |
| **On-Call** | Developer checks email | Alerts to team channel | Rotation with escalation |

### By Base Rule

| Base Rule | MVP/POC | Pre-Production | Production |
|-----------|---------|----------------|------------|
| `ai-assisted-development.md` | ✅ Full | ✅ Full | ✅ Full |
| `architecture-principles.md` | ⚠️ Basics only | ✅ SOLID, DDD lite | ✅ Full patterns |
| `testing-philosophy.md` | ⚠️ Critical paths | ✅ Core features | ✅ Comprehensive |
| `12-factor-app.md` | ⚠️ Config only | ✅ Most factors | ✅ All factors |
| `metrics-standards.md` | ❌ Skip | ⚠️ Basic metrics | ✅ Full observability |
| `security-practices.md` | ⚠️ Fundamentals | ✅ OWASP Top 10 | ✅ Hardened + audited |
| `refactoring-patterns.md` | ⚠️ Simple refactors | ✅ Technical debt paydown | ✅ Continuous improvement |
| `cicd-comprehensive.md` | ❌ Skip | ⚠️ Basic pipeline | ✅ Full automation |
| `chaos-engineering.md` | ❌ Skip | ❌ Skip | ✅ Production only |
| `ai-ethics-governance.md` | ⚠️ Awareness only | ⚠️ Basic policies | ✅ Full governance |
| `operations-automation.md` | ❌ Skip | ⚠️ Deploy automation | ✅ Full IaC + runbooks |
| `specification-driven-development.md` | ❌ Skip | ⚠️ For complex features | ✅ Critical systems |

**Legend:** ✅ Apply fully | ⚠️ Apply with reduced rigor or subset | ❌ Skip entirely

---

## Graduation Criteria

### MVP/POC → Pre-Production

**Graduate when:**
- Core value proposition validated
- Ready for external users (even if limited)
- Code will be maintained and evolved (not thrown away)
- Team growing beyond 1-2 developers
- Users will depend on system availability

**Pre-requisites:**
1. Automated tests for critical user flows
2. CI/CD pipeline for automated deployment
3. Basic monitoring and error tracking
4. Secrets management (no hardcoded credentials)
5. Code review process
6. Staging environment
7. Basic documentation (README, API docs)

**Time investment:** 1-2 weeks

### Pre-Production → Production

**Graduate when:**
- Launching to general availability or paying customers
- Users depend on system for critical workflows
- Handling sensitive or regulated data
- Downtime has financial or reputational impact
- Team commits to long-term maintenance

**Pre-requisites:**
1. Comprehensive automated testing (80%+ coverage for critical paths)
2. Security hardening and vulnerability scanning
3. Production monitoring, logging, and alerting
4. Incident response procedures and on-call rotation
5. Disaster recovery and backup procedures
6. Performance testing and optimization
7. Comprehensive documentation (architecture, runbooks)
8. Compliance requirements (if applicable)
9. Load testing to validate capacity
10. Zero-downtime deployment capability

**Time investment:** 1-3 months

---

## Configuration

Declare project maturity using one of these methods:

**Option 1: `.maturity` file**
```yaml
level: mvp  # or: pre-production, production
declared_at: 2025-12-13
reason: "Validating product-market fit for AI-powered code review tool"
graduation_target: "2026-02-01"  # Optional
```

**Option 2: `package.json`**
```json
{
  "name": "my-project",
  "maturity": "mvp"
}
```

**Option 3: README**
```markdown
**Project Maturity:** MVP/POC - Validating product-market fit
```

---

## Anti-Patterns

### 1. Gold-Plating the MVP
Implementing production-grade practices before validating the product.

**Don't:** Kubernetes with auto-scaling, comprehensive E2E tests, multi-region deployment, 24/7 on-call, full DR plan
**Do:** Simple deployment (Vercel/Heroku), manual testing + critical unit tests, single region, developer checks errors daily

### 2. Launching Without Production Rigor
Treating production systems like prototypes.

**Don't:** No automated tests, manual deployment, no monitoring, secrets in env vars on local machine, no backups
**Do:** 80%+ test coverage, CI/CD automation, comprehensive monitoring/alerting, secrets management, automated backups with tested recovery

### 3. Staying in MVP Mode Too Long
Never graduating to higher rigor despite production traffic.

**Symptoms:** "We'll add tests later" (6+ months), production outages with no visibility, manual deployment breaking frequently, no code review with growing team, ignored security vulnerabilities

**Solution:** Set explicit graduation criteria and stick to them. Technical debt compounds.

### 4. Premature Optimization
Optimizing for scale before achieving product-market fit.

**Don't:**
```python
class CacheManager:
    def __init__(self):
        self.redis_client = RedisClient()
        self.memcached_client = MemcachedClient()
        self.local_cache = LRUCache(size=1000)
```

**Do:**
```python
cache = {}  # Or use @lru_cache
def get_data(key):
    if key not in cache:
        cache[key] = expensive_operation(key)
    return cache[key]
```

### 5. Skipping Security Fundamentals
Security is NOT optional at any level.

**Even MVPs must:**
- Use environment variables for secrets (never commit credentials)
- Validate user input (prevent injection attacks)
- Use HTTPS in production
- Keep dependencies updated
- Implement basic authentication and authorization

**Scale security with maturity:**
- **MVP:** Fundamentals above
- **Pre-Production:** + OWASP Top 10, dependency scanning, code review
- **Production:** + Security audits, penetration testing, compliance

---

## Decision Framework

**"Should I apply this practice now?"**

1. What is my project maturity level?
2. What is the cost of NOT doing this?
3. What is the cost of doing this?
4. Can I graduate to the next level without this?

**Examples:**

| Practice | MVP | Pre-Production | Production |
|----------|-----|----------------|------------|
| Distributed tracing | ❌ Console logs sufficient | ⚠️ Maybe if complex debugging | ✅ Essential for distributed systems |
| Write tests | ⚠️ Minimal - critical paths only | ✅ Automated for core features | ✅ Comprehensive 80%+ coverage |

---

**Remember:** The goal is not to avoid rigor, but to apply the *right* rigor at the *right* time. Start simple, graduate intentionally, and never compromise on security fundamentals.
