# Project Maturity Levels: Progressive Rigor Framework

> **When to apply:** All projects - determines which rules and practices to prioritize based on project phase

Apply the right level of rigor at the right time. Different project phases require different levels of discipline, tooling, and process overhead.

## Table of Contents

- [Overview](#overview)
- [Maturity Levels](#maturity-levels)
- [Decision Matrix](#decision-matrix)
- [Graduation Criteria](#graduation-criteria)
- [Configuration](#configuration)
- [Anti-Patterns](#anti-patterns)

---

## Overview

### The Progressive Rigor Principle

**Not all projects need production-grade practices from day one.** Applying full production rigor to an MVP wastes time and slows learning. Conversely, launching to production without proper rigor creates risk and technical debt.

This framework defines three maturity levels, each with appropriate practices:

1. **MVP/POC/Prototype** - Minimize overhead, maximize learning velocity
2. **Pre-Production/Beta** - Add essential quality and security practices
3. **Production** - Apply comprehensive rigor for reliability and scale

### Why This Matters

**Common mistakes:**
- **Over-engineering MVPs** - Implementing comprehensive testing, monitoring, and architecture patterns before validating product-market fit
- **Under-engineering production** - Launching without proper security, observability, or disaster recovery
- **Premature optimization** - Applying production patterns to experimental code

**Benefits of progressive rigor:**
- **Faster iteration** in early phases
- **Reduced waste** on features that may be discarded
- **Clear graduation criteria** for moving between phases
- **Right-sized technical debt** - acceptable in MVP, paid down before production

---

## Maturity Levels

### Level 1: MVP/POC/Prototype

**Goal:** Validate assumptions, learn fast, prove viability

**Timeline:** Days to weeks (typically 2-8 weeks)

**Characteristics:**
- Exploring product-market fit or technical feasibility
- Small team (1-3 developers)
- Limited users or internal-only usage
- Acceptable to throw away and rebuild
- No external dependencies on the system
- No sensitive data or compliance requirements

**Apply These Practices:**

✅ **Essential (Must Have)**
- `base/ai-assisted-development.md` - Use AI to move faster
- `base/architecture-principles.md` - Basic SOLID, avoid spaghetti code
- `base/testing-philosophy.md` - Manual testing OK, basic unit tests for critical paths
- Git version control with meaningful commits
- Simple deployment (manual is OK)
- Basic error handling (don't crash on bad input)

⚠️ **Simplified (Reduced Rigor)**
- Testing: Focus on happy path, skip edge cases
- Architecture: Monolith is fine, avoid microservices
- Documentation: README only, inline comments for complex logic
- Security: Environment variables for secrets, basic input validation
- Monitoring: Console logs are sufficient

❌ **Skip (Too Much Overhead)**
- Comprehensive test coverage
- CI/CD pipelines with gates
- Observability and monitoring dashboards
- Disaster recovery planning
- Performance optimization
- Complex architecture patterns (CQRS, event sourcing, etc.)
- Formal security audits
- Load testing
- Multi-region deployment
- Compliance certifications

**Code Quality Bar:**
- Code should be readable and understandable
- No obvious bugs in core functionality
- Basic type safety (if language supports it)
- No hardcoded credentials
- Version control for all code

---

### Level 2: Pre-Production/Beta

**Goal:** Prepare for limited production use, establish quality baseline

**Timeline:** Weeks to months (typically 1-3 months)

**Characteristics:**
- Product-market fit validated, moving toward launch
- Growing team (3-10 developers)
- Limited external users (beta testers, early adopters)
- Some users depend on the system
- May handle real but non-critical data
- Beginning to think about scale

**Apply These Practices:**

✅ **Add to Essential**
- `base/testing-philosophy.md` - Automated tests for core features
- `base/12-factor-app.md` - External configuration, proper secrets management
- `base/metrics-standards.md` - Basic metrics and logging
- `cloud/*/security-practices.md` - Security fundamentals
- Automated deployment (CI/CD basics)
- Code review process
- Basic monitoring and alerting
- Dependency vulnerability scanning
- Staging environment

⚠️ **Moderate Rigor**
- Testing: 60-70% coverage of critical paths, integration tests
- Architecture: Start modularizing, separation of concerns
- Documentation: API documentation, deployment guide
- Security: HTTPS, input validation, OWASP Top 10 awareness
- Monitoring: Application logs, error tracking (e.g., Sentry)
- Performance: Identify obvious bottlenecks

❌ **Still Skip**
- 90%+ test coverage requirements
- Chaos engineering
- Advanced observability (distributed tracing)
- Multi-region active-active
- Formal SLAs and SLOs
- 24/7 on-call rotation
- Enterprise compliance (SOC2, HIPAA, etc.)

**Code Quality Bar:**
- All tests pass before merge
- No critical security vulnerabilities
- Code review approval required
- Documented API contracts
- Can rollback deployments
- Monitor error rates

---

### Level 3: Production

**Goal:** Reliable, secure, scalable system supporting real users and business value

**Timeline:** Ongoing (months to years)

**Characteristics:**
- Live production traffic from paying customers or critical users
- Team size varies (can be 1 person or 100+)
- Users depend on system availability
- Handles sensitive, regulated, or business-critical data
- Financial or reputational impact from downtime
- May have SLAs or compliance requirements

**Apply These Practices:**

✅ **Full Rigor (All Applicable Rules)**
- All base/ practices that apply to your domain
- Language-specific best practices
- Framework-specific patterns
- Cloud provider best practices (security, reliability, cost optimization)
- Comprehensive testing strategy
- Security hardening and regular audits
- Production observability (metrics, logs, traces)
- Incident response procedures
- Disaster recovery and business continuity
- Performance optimization
- Cost monitoring and optimization

**Required Capabilities:**
- Automated testing with high coverage (80%+ for critical code)
- Continuous Integration/Continuous Deployment
- Monitoring, alerting, and on-call rotation
- Security scanning in CI/CD pipeline
- Secrets management (vault, cloud provider secrets)
- Database backups and recovery procedures
- Staging environment that mirrors production
- Deployment rollback capability
- Incident response runbooks
- Regular security updates and dependency patching

**Code Quality Bar:**
- Comprehensive test coverage
- Security review for sensitive changes
- Performance testing for critical paths
- Documentation for all public APIs
- Monitoring for key metrics
- Runbooks for common incidents
- Regular dependency updates
- Compliance with relevant standards (OWASP, CWE, etc.)

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

**Legend:**
- ✅ Apply fully
- ⚠️ Apply with reduced rigor or subset
- ❌ Skip entirely

---

## Graduation Criteria

### Moving from MVP/POC to Pre-Production

**You should graduate when:**
- ✅ Core value proposition is validated
- ✅ Ready for external users (even if limited)
- ✅ Code will be maintained and evolved (not thrown away)
- ✅ Team is growing beyond 1-2 developers
- ✅ Users will depend on system availability

**Before graduating, implement:**
1. Automated tests for critical user flows
2. CI/CD pipeline for automated deployment
3. Basic monitoring and error tracking
4. Secrets management (no hardcoded credentials)
5. Code review process
6. Staging environment
7. Basic documentation (README, API docs)

**Time investment:** Typically 1-2 weeks to add these foundations

---

### Moving from Pre-Production to Production

**You should graduate when:**
- ✅ Launching to general availability or paying customers
- ✅ Users depend on system for critical workflows
- ✅ Handling sensitive or regulated data
- ✅ Downtime has financial or reputational impact
- ✅ Team commits to maintaining the system long-term

**Before graduating, implement:**
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

**Time investment:** Typically 1-3 months depending on system complexity

---

## Configuration

### Declaring Project Maturity

**Option 1: `.maturity` file in repository root**

```yaml
# .maturity
level: mvp  # or: pre-production, production
declared_at: 2025-12-13
reason: "Validating product-market fit for AI-powered code review tool"
graduation_target: "2026-02-01"  # Optional: planned graduation date
```

**Option 2: `package.json` (for Node.js projects)**

```json
{
  "name": "my-project",
  "version": "0.3.0",
  "maturity": "mvp",
  "description": "..."
}
```

**Option 3: Project README**

```markdown
# My Project

**Project Maturity:** MVP/POC - Validating product-market fit
**Expected Graduation:** February 2026
```

---

## Anti-Patterns

### 1. Gold-Plating the MVP

**Problem:** Implementing production-grade practices before validating the product

**Example:**
```yaml
# DON'T: Full production setup for unvalidated MVP
- Kubernetes cluster with auto-scaling
- Comprehensive E2E test suite
- Multi-region deployment
- 24/7 on-call rotation
- Full disaster recovery plan
```

**Instead:**
```yaml
# DO: Minimal viable infrastructure
- Simple deployment (Vercel, Heroku, single server)
- Manual testing + critical unit tests
- Single region, single instance
- Developer checks errors daily
- Git backups
```

**Why:** You may pivot or rebuild completely. Don't invest in infrastructure for code you might throw away.

---

### 2. Launching Without Production Rigor

**Problem:** Treating production systems like prototypes

**Example:**
```yaml
# DON'T: Production system with MVP practices
- No automated tests
- Manual deployment
- No monitoring or alerting
- Secrets in environment variables on local machine
- No backups
```

**Instead:**
```yaml
# DO: Production-grade practices
- Automated tests (80%+ coverage)
- CI/CD with automated deployment
- Comprehensive monitoring and alerting
- Secrets management (vault, cloud secrets)
- Automated backups with tested recovery
```

**Why:** Production systems need reliability. Users depend on you.

---

### 3. Staying in MVP Mode Too Long

**Problem:** Never graduating to higher rigor despite production traffic

**Symptoms:**
- "We'll add tests later" (for 6+ months)
- Production outages with no visibility into cause
- Manual deployment that breaks frequently
- No code review process with growing team
- Security vulnerabilities ignored

**Solution:** Set explicit graduation criteria and stick to them. Technical debt compounds.

---

### 4. Premature Optimization

**Problem:** Optimizing for scale before achieving product-market fit

**Example:**
```python
# DON'T: Complex optimization in MVP
class CacheManager:
    def __init__(self):
        self.redis_client = RedisClient()
        self.memcached_client = MemcachedClient()
        self.local_cache = LRUCache(size=1000)

    def get(self, key):
        # Check 3 cache layers, implement complex invalidation...
        pass
```

**Instead:**
```python
# DO: Simple solution in MVP
cache = {}  # Or use basic @lru_cache decorator

def get_data(key):
    if key not in cache:
        cache[key] = expensive_operation(key)
    return cache[key]
```

**Why:** Your bottleneck is probably not where you think it is. Measure first, optimize later.

---

### 5. Skipping Security Fundamentals

**Problem:** Treating security as "production only"

**Security is NOT optional at any level:**

**Even MVPs must:**
- ✅ Use environment variables for secrets (never commit credentials)
- ✅ Validate user input (prevent injection attacks)
- ✅ Use HTTPS in production (free with Let's Encrypt)
- ✅ Keep dependencies updated (automated with Dependabot)
- ✅ Basic authentication and authorization

**Scale security with maturity:**
- **MVP:** Fundamentals above
- **Pre-Production:** + OWASP Top 10, dependency scanning, code review
- **Production:** + Security audits, penetration testing, compliance

---

## Related Resources

- See `base/ai-assisted-development.md` for all maturity levels
- See `base/architecture-principles.md` for architectural patterns by maturity
- See `base/testing-philosophy.md` for testing strategies by maturity
- See `base/12-factor-app.md` for production-readiness patterns
- See `cloud/*/production-checklist.md` for cloud-specific graduation criteria

---

## Decision Framework

### "Should I apply this practice now?"

Ask yourself:

1. **What is my project maturity level?** (MVP, Pre-Production, Production)
2. **What is the cost of NOT doing this?**
   - MVP: Learning velocity, time to validate
   - Production: User trust, system reliability, security risk
3. **What is the cost of doing this?**
   - Time investment
   - Complexity added
   - Ongoing maintenance
4. **Can I graduate to the next level without this?**
   - Check graduation criteria above

**Example: "Should I implement distributed tracing?"**

- **MVP:** ❌ No - console logs are sufficient, focus on product validation
- **Pre-Production:** ⚠️ Maybe - if experiencing complex debugging issues
- **Production:** ✅ Yes - essential for debugging distributed systems at scale

**Example: "Should I write tests?"**

- **MVP:** ⚠️ Yes, but minimal - critical paths only, manual testing OK
- **Pre-Production:** ✅ Yes - automated tests for core features
- **Production:** ✅ Yes - comprehensive test coverage (80%+)

---

**Remember:** The goal is not to avoid rigor, but to apply the *right* rigor at the *right* time. Start simple, graduate intentionally, and never compromise on security fundamentals.
