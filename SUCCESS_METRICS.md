# Success Metrics: Measurable KPIs for Development Practices

> **Purpose:** Define measurable success criteria for development practices
> **Audience:** Engineering leaders, team leads, AI assistants
> **Review Frequency:** Weekly (tactical), Monthly (strategic), Quarterly (trends)

This document defines measurable Key Performance Indicators (KPIs) for tracking the adoption and effectiveness of development practices in the centralized rules framework.

## Table of Contents

1. [Code Quality Metrics](#code-quality-metrics)
2. [Testing Metrics](#testing-metrics)
3. [Security Metrics](#security-metrics)
4. [Performance Metrics](#performance-metrics)
5. [DevOps Metrics](#devops-metrics)
6. [Team Productivity Metrics](#team-productivity-metrics)
7. [AI Development Metrics](#ai-development-metrics)
8. [Business Impact Metrics](#business-impact-metrics)

---

## Code Quality Metrics

### 1. Code Coverage

**Definition:** Percentage of code executed by automated tests.

**Measurement:**
```bash
# TypeScript/JavaScript
npm test -- --coverage

# Python
pytest --cov=src --cov-report=term-missing

# Java
mvn test jacoco:report
```

**Targets by Maturity:**
- **MVP/POC:** 40%+ overall, 60%+ on business logic
- **Pre-Production:** 60%+ overall, 80%+ on business logic
- **Production:** 80%+ overall, 90%+ on business logic

**Collection Frequency:** Every CI build

**Trend:** ↗️ Should steadily increase

**Related Practice:** `base/testing-philosophy.md`

---

### 2. Code Duplication

**Definition:** Percentage of duplicated code blocks.

**Measurement:**
```bash
# JavaScript/TypeScript
npx jscpd src/

# Python
radon raw -s src/

# SonarQube
# Provides duplication metrics in dashboard
```

**Target:** < 3% duplication

**Collection Frequency:** Every CI build

**Trend:** ↘️ Should decrease over time

**Alert Threshold:** > 5% duplication

**Related Practice:** `base/code-quality.md`, `ANTI_PATTERNS.md`

---

### 3. Cyclomatic Complexity

**Definition:** Measure of code complexity based on decision points.

**Measurement:**
```bash
# JavaScript/TypeScript
npx eslint src/ --rule 'complexity: [error, 10]'

# Python
radon cc src/ -s

# Java
# Use SonarQube or PMD
```

**Target:**
- **Average:** < 10 per function
- **Maximum:** < 15 per function

**Collection Frequency:** Every CI build

**Trend:** ↘️ Should decrease or remain stable

**Alert Threshold:** Function with complexity > 15

**Related Practice:** `base/refactoring-patterns.md`

---

### 4. Technical Debt Ratio

**Definition:** Ratio of time needed to fix issues vs. time to develop.

**Measurement:**
```
Technical Debt Ratio = Remediation Cost / Development Cost

# SonarQube provides this metric
# Manual calculation:
TD Ratio = (Hours to fix all issues) / (Total development hours)
```

**Target:**
- **MVP/POC:** < 10%
- **Pre-Production:** < 5%
- **Production:** < 3%

**Collection Frequency:** Weekly

**Trend:** ↘️ Should decrease over time

**Alert Threshold:** > 10% for production projects

**Related Practice:** `base/refactoring-patterns.md`

---

### 5. Code Review Coverage

**Definition:** Percentage of commits that undergo code review.

**Measurement:**
```bash
# GitHub API
curl -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/{owner}/{repo}/pulls?state=all" \
  | jq '[.[] | select(.merged_at != null)] | length'

# Calculate: PRs merged / total commits
```

**Target:** 100% (all code reviewed before merge)

**Collection Frequency:** Daily

**Trend:** → Should remain at 100%

**Alert Threshold:** < 95%

**Related Practice:** `base/git-workflow.md`

---

## Testing Metrics

### 6. Test Pass Rate

**Definition:** Percentage of test runs that pass.

**Measurement:**
```bash
# Calculate from CI/CD pipeline
Pass Rate = (Successful builds) / (Total builds) * 100
```

**Target:** > 95%

**Collection Frequency:** Every CI build

**Trend:** ↗️ Should increase to > 95% and stay there

**Alert Threshold:** < 90%

**Related Practice:** `base/testing-philosophy.md`

---

### 7. Test Execution Time

**Definition:** Time taken to run full test suite.

**Measurement:**
```bash
# Measure in CI/CD
time npm test

# Track P50, P95, P99
```

**Target:**
- **Unit tests:** < 2 minutes
- **Integration tests:** < 10 minutes
- **E2E tests:** < 30 minutes

**Collection Frequency:** Every CI build

**Trend:** → Should remain stable or improve

**Alert Threshold:** > 50% increase from baseline

**Related Practice:** `base/testing-philosophy.md`

---

### 8. Flaky Test Rate

**Definition:** Percentage of tests that fail intermittently.

**Measurement:**
```bash
# Track tests that sometimes pass, sometimes fail
Flaky Rate = (Flaky tests) / (Total tests) * 100
```

**Target:** < 1%

**Collection Frequency:** Weekly analysis

**Trend:** ↘️ Should decrease to near zero

**Alert Threshold:** > 5%

**Related Practice:** `base/testing-philosophy.md`, `ANTI_PATTERNS.md`

---

### 9. Mutation Test Score

**Definition:** Percentage of mutants killed by test suite.

**Measurement:**
```bash
# JavaScript/TypeScript
npx stryker run

# Python
mutmut run

# Java
mvn org.pitest:pitest-maven:mutationCoverage
```

**Target:** > 70%

**Collection Frequency:** Weekly or bi-weekly

**Trend:** ↗️ Should increase over time

**Related Practice:** `base/testing-philosophy.md`

---

## Security Metrics

### 10. Known Vulnerabilities

**Definition:** Count of known security vulnerabilities in dependencies.

**Measurement:**
```bash
# JavaScript/TypeScript
npm audit --json | jq '.metadata.vulnerabilities'

# Python
pip-audit

# Track by severity: critical, high, moderate, low
```

**Target:**
- **Critical:** 0
- **High:** 0
- **Moderate:** < 5
- **Low:** < 20

**Collection Frequency:** Daily

**Trend:** ↘️ Should decrease to zero for critical/high

**Alert Threshold:** Any critical or high vulnerability

**Related Practice:** `base/security-principles.md`

---

### 11. Security Scan Pass Rate

**Definition:** Percentage of scans that pass security checks.

**Measurement:**
```yaml
# CI/CD pipeline
Pass Rate = (Builds passing security scan) / (Total builds) * 100
```

**Target:** 100%

**Collection Frequency:** Every CI build

**Trend:** → Should remain at 100%

**Alert Threshold:** < 100%

**Related Practice:** `base/security-principles.md`

---

### 12. Secret Detection Rate

**Definition:** Number of secrets detected in source code.

**Measurement:**
```bash
# Use git-secrets, TruffleHog, or Gitleaks
gitleaks detect --source . --report-format json

# Count detections
```

**Target:** 0 secrets in source code

**Collection Frequency:** Every commit (pre-commit hook)

**Trend:** → Should remain at 0

**Alert Threshold:** Any secret detected

**Related Practice:** `base/security-principles.md`, `ANTI_PATTERNS.md`

---

### 13. Mean Time to Remediate (MTTR) Security Issues

**Definition:** Average time from vulnerability discovery to fix deployed.

**Measurement:**
```
MTTR = Sum(Fix deployed time - Discovery time) / Number of vulnerabilities
```

**Target:**
- **Critical:** < 24 hours
- **High:** < 7 days
- **Moderate:** < 30 days

**Collection Frequency:** Monthly

**Trend:** ↘️ Should decrease over time

**Related Practice:** `base/security-principles.md`

---

## Performance Metrics

### 14. API Response Time (P95)

**Definition:** 95th percentile of API response times.

**Measurement:**
```typescript
// Using monitoring tools
// Prometheus, DataDog, New Relic, etc.

// Example query (Prometheus)
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

**Target:**
- **MVP/POC:** < 1000ms
- **Pre-Production:** < 500ms
- **Production:** < 200ms

**Collection Frequency:** Continuous

**Trend:** ↘️ Should decrease or remain stable

**Alert Threshold:** > 2x baseline

**Related Practice:** `base/metrics-standards.md`

---

### 15. Database Query Performance

**Definition:** Average and P95 database query execution time.

**Measurement:**
```sql
-- PostgreSQL
SELECT query, mean_exec_time, stddev_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 20;
```

**Target:**
- **Average:** < 100ms
- **P95:** < 500ms

**Collection Frequency:** Daily

**Trend:** ↘️ Should decrease or remain stable

**Alert Threshold:** Query > 1000ms

**Related Practice:** Framework-specific best practices

---

### 16. Cache Hit Rate

**Definition:** Percentage of requests served from cache.

**Measurement:**
```typescript
// Redis
INFO stats
// Look for keyspace_hits and keyspace_misses

Cache Hit Rate = keyspace_hits / (keyspace_hits + keyspace_misses) * 100
```

**Target:** > 80%

**Collection Frequency:** Continuous

**Trend:** ↗️ Should increase to > 80%

**Alert Threshold:** < 70%

**Related Practice:** Framework-specific best practices

---

## DevOps Metrics

### 17. Deployment Frequency

**Definition:** How often code is deployed to production.

**Measurement:**
```bash
# Count deployments per week/month
# From CI/CD logs or deployment tracking system
```

**Target:**
- **MVP/POC:** Weekly
- **Pre-Production:** Daily
- **Production (Elite):** Multiple times per day

**Collection Frequency:** Weekly

**Trend:** ↗️ Should increase over time

**DORA Metric:** Yes (one of the four key metrics)

**Related Practice:** `base/cicd-comprehensive.md`

---

### 18. Lead Time for Changes

**Definition:** Time from commit to production deployment.

**Measurement:**
```
Lead Time = Deployment time - First commit time

# Track P50, P95
```

**Target:**
- **MVP/POC:** < 7 days
- **Pre-Production:** < 1 day
- **Production (Elite):** < 1 hour

**Collection Frequency:** Per deployment

**Trend:** ↘️ Should decrease over time

**DORA Metric:** Yes

**Related Practice:** `base/cicd-comprehensive.md`

---

### 19. Change Failure Rate

**Definition:** Percentage of deployments that cause production issues.

**Measurement:**
```
Change Failure Rate = (Failed deployments + Hotfixes) / Total deployments * 100
```

**Target:**
- **MVP/POC:** < 30%
- **Pre-Production:** < 15%
- **Production (Elite):** < 5%

**Collection Frequency:** Per deployment

**Trend:** ↘️ Should decrease over time

**DORA Metric:** Yes

**Related Practice:** `base/cicd-comprehensive.md`, `base/testing-philosophy.md`

---

### 20. Mean Time to Recovery (MTTR)

**Definition:** Average time to restore service after incident.

**Measurement:**
```
MTTR = Sum(Service restored time - Incident start time) / Number of incidents
```

**Target:**
- **MVP/POC:** < 24 hours
- **Pre-Production:** < 4 hours
- **Production (Elite):** < 1 hour

**Collection Frequency:** Per incident

**Trend:** ↘️ Should decrease over time

**DORA Metric:** Yes

**Related Practice:** `base/operations-automation.md`

---

### 21. Build Success Rate

**Definition:** Percentage of builds that complete successfully.

**Measurement:**
```bash
# From CI/CD
Success Rate = Successful builds / Total builds * 100
```

**Target:** > 90%

**Collection Frequency:** Daily

**Trend:** ↗️ Should increase to > 90%

**Alert Threshold:** < 85%

**Related Practice:** `base/cicd-comprehensive.md`

---

## Team Productivity Metrics

### 22. Pull Request Cycle Time

**Definition:** Time from PR creation to merge.

**Measurement:**
```bash
# GitHub API
PR Cycle Time = PR merged_at - PR created_at

# Calculate median and P95
```

**Target:**
- **Median:** < 4 hours
- **P95:** < 24 hours

**Collection Frequency:** Daily

**Trend:** ↘️ Should decrease or remain stable

**Alert Threshold:** Median > 24 hours

**Related Practice:** `base/git-workflow.md`

---

### 23. Code Review Turnaround Time

**Definition:** Time from review request to first review.

**Measurement:**
```bash
# GitHub API
Review Time = First review timestamp - Review requested timestamp
```

**Target:** < 4 hours during business hours

**Collection Frequency:** Daily

**Trend:** ↘️ Should decrease or remain stable

**Alert Threshold:** > 24 hours

**Related Practice:** `base/git-workflow.md`

---

### 24. Commit Frequency

**Definition:** Number of commits per developer per day.

**Measurement:**
```bash
# Git log analysis
git log --since="1 week ago" --author="<author>" --oneline | wc -l
```

**Target:** 2-5 commits per developer per day

**Collection Frequency:** Weekly

**Trend:** → Should remain stable

**Context:** Too high (>10) might indicate small, non-atomic commits. Too low (<1) might indicate long-lived branches.

**Related Practice:** `base/git-workflow.md`

---

### 25. Work in Progress (WIP)

**Definition:** Number of open pull requests per developer.

**Measurement:**
```bash
# GitHub API
Open PRs = Count of open pull requests by author
```

**Target:** 1-2 per developer

**Collection Frequency:** Daily

**Trend:** → Should remain stable at 1-2

**Alert Threshold:** > 5 per developer

**Context:** High WIP indicates context switching or blocked work.

**Related Practice:** `base/parallel-development.md`

---

## AI Development Metrics

### 26. AI Code Acceptance Rate

**Definition:** Percentage of AI-generated code that passes review and is merged.

**Measurement:**
```
# Manual tracking or commit message analysis
Acceptance Rate = (AI commits merged) / (AI commits proposed) * 100
```

**Target:** > 70%

**Collection Frequency:** Weekly

**Trend:** ↗️ Should increase as AI improves

**Context:** Track separately by task type (feature, bug fix, test, docs)

**Related Practice:** `base/ai-assisted-development.md`

---

### 27. Five-Try Rule Success Rate

**Definition:** Percentage of AI implementations that pass tests within 5 attempts.

**Measurement:**
```
# Track manually or via automated logging
Success Rate = (Tasks passing within 5 tries) / (Total AI tasks) * 100
```

**Target:** > 80%

**Collection Frequency:** Weekly

**Trend:** ↗️ Should increase over time

**Alert Threshold:** < 60%

**Related Practice:** `base/ai-assisted-development.md`

---

### 28. AI Context Effectiveness

**Definition:** Percentage of AI tasks completed without needing additional context.

**Measurement:**
```
# Manual tracking
Effectiveness = (Tasks completed without context requests) / (Total tasks) * 100
```

**Target:** > 70%

**Collection Frequency:** Weekly

**Trend:** ↗️ Should increase as context improves

**Related Practice:** `base/knowledge-management.md`

---

### 29. AI Development Velocity

**Definition:** Story points completed per sprint with AI assistance.

**Measurement:**
```
# Compare to baseline without AI
Velocity Increase = ((AI velocity - Baseline velocity) / Baseline velocity) * 100
```

**Target:** 20-50% increase over baseline

**Collection Frequency:** Per sprint

**Trend:** ↗️ Should increase as team adopts AI

**Related Practice:** `base/ai-assisted-development.md`

---

## Business Impact Metrics

### 30. Customer-Reported Bugs

**Definition:** Number of bugs reported by customers per month.

**Measurement:**
```
# From bug tracking system
Count bugs with source = "customer" per month
```

**Target:**
- **Trend:** ↘️ Should decrease over time
- **Rate:** < 5 per 1000 users per month

**Collection Frequency:** Monthly

**Related Practice:** `base/testing-philosophy.md`, `base/cicd-comprehensive.md`

---

### 31. Production Incidents

**Definition:** Number of production incidents per month.

**Measurement:**
```
# From incident management system
Count incidents with severity >= P2 per month
```

**Target:**
- **P1 (Critical):** < 1 per month
- **P2 (High):** < 5 per month

**Collection Frequency:** Monthly

**Trend:** ↘️ Should decrease over time

**Related Practice:** `base/chaos-engineering.md`, `base/operations-automation.md`

---

### 32. Feature Development Cycle Time

**Definition:** Time from feature ideation to production deployment.

**Measurement:**
```
Cycle Time = Production deployment time - Feature kick-off time
```

**Target:**
- **MVP/POC:** < 4 weeks
- **Pre-Production:** < 2 weeks
- **Production:** < 1 week

**Collection Frequency:** Per feature

**Trend:** ↘️ Should decrease over time

**Related Practice:** `base/lean-development.md`

---

### 33. Customer Satisfaction Score (CSAT)

**Definition:** Customer satisfaction with software quality.

**Measurement:**
```
# Post-interaction survey
CSAT = (Satisfied customers / Total respondents) * 100
```

**Target:** > 80%

**Collection Frequency:** Monthly

**Trend:** ↗️ Should increase over time

**Context:** Correlate with deployment frequency and defect rates

---

## Metric Dashboards

### Recommended Dashboard Layout

#### Executive Dashboard (Monthly Review)

**DORA Metrics:**
- Deployment Frequency
- Lead Time for Changes
- Change Failure Rate
- Mean Time to Recovery

**Quality Overview:**
- Test Coverage
- Customer-Reported Bugs
- Production Incidents
- CSAT Score

#### Team Dashboard (Weekly Review)

**Code Quality:**
- Code Coverage
- Code Duplication
- Cyclomatic Complexity
- Technical Debt Ratio

**Productivity:**
- PR Cycle Time
- Deployment Frequency
- Commit Frequency
- WIP

#### Security Dashboard (Daily Review)

**Vulnerabilities:**
- Known Vulnerabilities (by severity)
- Security Scan Pass Rate
- Secrets Detected
- MTTR for Security Issues

---

## Metric Collection Tools

### Code Quality
- **SonarQube / SonarCloud:** Comprehensive code quality
- **CodeClimate:** Code quality and test coverage
- **Codacy:** Automated code review

### Testing
- **Coverage.py:** Python coverage
- **Istanbul / c8:** JavaScript/TypeScript coverage
- **JaCoCo:** Java coverage
- **Stryker:** Mutation testing

### Security
- **Snyk:** Vulnerability scanning
- **GitHub Dependabot:** Dependency updates
- **git-secrets / Gitleaks:** Secret detection
- **OWASP Dependency-Check:** Security vulnerabilities

### Performance
- **Prometheus:** Metrics collection
- **Grafana:** Visualization
- **DataDog / New Relic:** APM
- **Lighthouse:** Web performance

### DevOps
- **GitHub Insights:** PR and commit metrics
- **GitLab Analytics:** DevOps metrics
- **Jira / Linear:** Sprint velocity and cycle time

---

## Alerts and Thresholds

### Critical Alerts (Immediate Action)

| Metric | Threshold | Action |
|--------|-----------|--------|
| Critical Vulnerability | Any | Fix within 24 hours |
| Secrets Detected | Any | Revoke and rotate immediately |
| Production Incident (P1) | Any | Activate incident response |
| Change Failure Rate | > 50% | Pause deployments, investigate |
| Security Scan Failure | Any | Block deployment |

### Warning Alerts (Investigation Needed)

| Metric | Threshold | Action |
|--------|-----------|--------|
| Code Coverage | < 60% | Review testing strategy |
| Cyclomatic Complexity | > 15 | Refactor flagged functions |
| PR Cycle Time | > 24 hours | Review process bottlenecks |
| API Response Time | > 500ms | Performance investigation |
| Build Success Rate | < 85% | Fix flaky tests |

---

## Metric Improvement Plans

### Improving Code Coverage

**Current:** 45% → **Target:** 80%

1. **Week 1-2:** Add tests for critical business logic (→ 55%)
2. **Week 3-4:** Add integration tests (→ 65%)
3. **Week 5-6:** Add edge case tests (→ 75%)
4. **Week 7-8:** Add remaining unit tests (→ 80%)

**Track:** Coverage increase per sprint

### Improving Deployment Frequency

**Current:** Monthly → **Target:** Daily

1. **Month 1:** Automate build and test (→ Weekly)
2. **Month 2:** Implement feature flags (→ 2x per week)
3. **Month 3:** Add deployment automation (→ Daily)
4. **Month 4:** Optimize pipeline (→ Multiple times per day)

**Track:** Deployments per week

### Reducing Lead Time

**Current:** 7 days → **Target:** < 1 day

1. **Week 1-2:** Reduce PR review time (→ 5 days)
2. **Week 3-4:** Optimize CI/CD pipeline (→ 3 days)
3. **Week 5-6:** Smaller PRs, trunk-based dev (→ 2 days)
4. **Week 7-8:** Continuous deployment (→ < 1 day)

**Track:** Lead time per deployment

---

## Reporting Cadence

### Daily
- Build success rate
- Security scans
- Production incidents

### Weekly
- Code quality metrics
- Team productivity
- Sprint velocity

### Monthly
- DORA metrics
- Business impact metrics
- Trend analysis

### Quarterly
- Strategic review
- Tool evaluation
- Practice refinement

---

## Related Resources

- `IMPLEMENTATION_GUIDE.md` - Phased rollout plan
- `PRACTICE_CROSSREFERENCE.md` - Practice-to-metric mapping
- `base/metrics-standards.md` - Detailed metric definitions
- `base/project-maturity-levels.md` - Maturity-based targets

---

## Continuous Improvement

This metrics framework should evolve based on:

- **Team Feedback:** What metrics are actionable?
- **Tool Changes:** New tools, better measurements
- **Industry Trends:** Updated DORA research, new practices
- **Business Needs:** Changing priorities

**Review Frequency:** Quarterly

**Owner:** Engineering leadership with team input
