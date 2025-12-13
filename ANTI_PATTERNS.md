# Anti-Patterns: Detection and Prevention

> **Purpose:** Identify common anti-patterns and provide detection/prevention strategies
> **Audience:** AI assistants, developers, code reviewers

This document catalogs common anti-patterns in software development, particularly in AI-assisted development contexts, with strategies for detection and prevention.

## Table of Contents

1. [Code Quality Anti-Patterns](#code-quality-anti-patterns)
2. [Architecture Anti-Patterns](#architecture-anti-patterns)
3. [Security Anti-Patterns](#security-anti-patterns)
4. [Testing Anti-Patterns](#testing-anti-patterns)
5. [AI Development Anti-Patterns](#ai-development-anti-patterns)
6. [DevOps Anti-Patterns](#devops-anti-patterns)
7. [Team Collaboration Anti-Patterns](#team-collaboration-anti-patterns)

---

## Code Quality Anti-Patterns

### 1. God Object / God Class

**Description:** Single class that knows too much or does too much.

**Detection:**
```python
# ❌ God class with 50+ methods
class UserManager:
    def create_user(self): ...
    def delete_user(self): ...
    def send_email(self): ...
    def generate_report(self): ...
    def process_payment(self): ...
    def manage_inventory(self): ...
    # ... 44 more methods
```

**Prevention:**
```python
# ✅ Separate responsibilities
class UserService:
    def create_user(self): ...
    def delete_user(self): ...

class EmailService:
    def send_email(self): ...

class ReportGenerator:
    def generate_report(self): ...
```

**Automated Detection:**
- **Metric:** Class with > 20 methods or > 500 lines
- **Tools:** Pylint (too-many-public-methods), SonarQube
- **Remediation:** Extract classes following Single Responsibility Principle

### 2. Magic Numbers and Strings

**Description:** Hardcoded values without explanation.

**Detection:**
```typescript
// ❌ Magic numbers
function calculateDiscount(price: number): number {
  if (price > 100) {
    return price * 0.15; // What is 0.15?
  }
  return price * 0.05; // What is 0.05?
}
```

**Prevention:**
```typescript
// ✅ Named constants
const PREMIUM_THRESHOLD = 100;
const PREMIUM_DISCOUNT_RATE = 0.15;
const STANDARD_DISCOUNT_RATE = 0.05;

function calculateDiscount(price: number): number {
  if (price > PREMIUM_THRESHOLD) {
    return price * PREMIUM_DISCOUNT_RATE;
  }
  return price * STANDARD_DISCOUNT_RATE;
}
```

**Automated Detection:**
- **Pattern:** Numbers/strings appearing > once
- **Tools:** ESLint (no-magic-numbers), Pylint (no-magic-numbers)
- **Remediation:** Extract to named constants

### 3. Shotgun Surgery

**Description:** Single change requires modifications across many files.

**Detection:**
- Changing one feature touches > 10 files
- Same pattern duplicated across codebase
- Tight coupling between unrelated modules

**Prevention:**
- **DRY Principle:** Don't Repeat Yourself
- **Encapsulation:** Centralize related logic
- **Abstraction:** Use interfaces and dependency injection

**Automated Detection:**
- **Metric:** Change impact analysis (> 10 files for single feature)
- **Tools:** Git history analysis, dependency graphs
- **Remediation:** Extract common functionality, introduce abstractions

### 4. Primitive Obsession

**Description:** Overuse of primitive types instead of domain objects.

**Detection:**
```java
// ❌ Primitive obsession
public void sendEmail(String to, String from, String subject, String body) {
    // Validation scattered everywhere
    if (!to.contains("@")) throw new Exception("Invalid email");
    // ...
}
```

**Prevention:**
```java
// ✅ Value objects
public class Email {
    private final String address;

    public Email(String address) {
        if (!address.matches("^[A-Za-z0-9+_.-]+@(.+)$")) {
            throw new IllegalArgumentException("Invalid email: " + address);
        }
        this.address = address;
    }
}

public void sendEmail(Email to, Email from, String subject, String body) {
    // Email already validated
}
```

**Automated Detection:**
- **Pattern:** Methods with > 5 string/int parameters
- **Tools:** Static analysis, code reviews
- **Remediation:** Introduce value objects and domain types

### 5. Copy-Paste Programming

**Description:** Code duplication through copy-paste instead of abstraction.

**Detection:**
```python
# ❌ Duplicated logic
def process_user_data(user):
    if not user.email:
        log.error("Missing email")
        return None
    if not validate_email(user.email):
        log.error("Invalid email")
        return None
    # ... process user

def process_admin_data(admin):
    if not admin.email:
        log.error("Missing email")
        return None
    if not validate_email(admin.email):
        log.error("Invalid email")
        return None
    # ... process admin (same logic!)
```

**Prevention:**
```python
# ✅ Extract common logic
def validate_user_email(user) -> bool:
    if not user.email:
        log.error("Missing email")
        return False
    if not validate_email(user.email):
        log.error("Invalid email")
        return False
    return True

def process_user_data(user):
    if not validate_user_email(user):
        return None
    # ... process user

def process_admin_data(admin):
    if not validate_user_email(admin):
        return None
    # ... process admin
```

**Automated Detection:**
- **Metric:** Code duplication > 6 lines
- **Tools:** PMD (Copy Paste Detector), SonarQube, jscpd
- **Remediation:** Extract methods, use composition

---

## Architecture Anti-Patterns

### 6. Big Ball of Mud

**Description:** System with no recognizable structure, random dependencies.

**Detection:**
- No clear separation of concerns
- Circular dependencies
- Files importing from everywhere
- No architectural layers

**Prevention:**
- **Layered Architecture:** Presentation → Business → Data
- **Dependency Rule:** Dependencies point inward only
- **Module Boundaries:** Clear interfaces between modules

**Automated Detection:**
- **Tools:** Dependency analyzers, architecture fitness functions
- **Metrics:** Cyclomatic complexity, coupling metrics
- **Remediation:** Incremental refactoring, strangler fig pattern

### 7. Monolithic Database

**Description:** Single database shared by multiple services.

**Detection:**
- Multiple services directly accessing same database
- Schema changes affect multiple applications
- Cannot deploy services independently

**Prevention:**
- **Database per Service:** Each microservice owns its data
- **API Contracts:** Services communicate via APIs, not shared DB
- **Event-Driven:** Use events for cross-service data needs

**Example:**
```typescript
// ❌ Shared database
class OrderService {
  async createOrder(userId: string) {
    // Directly queries users table owned by UserService
    const user = await db.users.findOne({ id: userId });
  }
}

// ✅ API calls
class OrderService {
  constructor(private userServiceClient: UserServiceClient) {}

  async createOrder(userId: string) {
    // Calls UserService API
    const user = await this.userServiceClient.getUser(userId);
  }
}
```

### 8. Vendor Lock-In

**Description:** Architecture tightly coupled to specific vendor technologies.

**Detection:**
- Vendor-specific code throughout application
- Cannot switch vendors without major rewrite
- No abstraction layer for external services

**Prevention:**
```typescript
// ❌ Vendor lock-in
import AWS from 'aws-sdk';

class FileStorage {
  async upload(file: File) {
    const s3 = new AWS.S3();
    await s3.putObject({ Bucket: 'my-bucket', Key: file.name });
  }
}

// ✅ Abstraction layer
interface StorageProvider {
  upload(file: File): Promise<void>;
  download(key: string): Promise<File>;
}

class S3StorageProvider implements StorageProvider {
  async upload(file: File) { /* AWS-specific */ }
}

class GCSStorageProvider implements StorageProvider {
  async upload(file: File) { /* GCP-specific */ }
}

class FileStorage {
  constructor(private provider: StorageProvider) {}

  async upload(file: File) {
    await this.provider.upload(file); // Vendor-agnostic
  }
}
```

---

## Security Anti-Patterns

### 9. Hardcoded Secrets

**Description:** API keys, passwords, tokens committed to source code.

**Detection:**
```python
# ❌ Hardcoded secrets
API_KEY = "sk-1234567890abcdef"  # NEVER DO THIS!
DATABASE_URL = "postgres://user:password@localhost/db"
```

**Prevention:**
```python
# ✅ Environment variables
import os

API_KEY = os.environ["API_KEY"]
DATABASE_URL = os.environ["DATABASE_URL"]
```

**Automated Detection:**
- **Tools:** git-secrets, TruffleHog, Gitleaks, detect-secrets
- **CI/CD:** Pre-commit hooks, automated scanning
- **Remediation:** Rotate compromised secrets immediately

### 10. SQL Injection Vulnerability

**Description:** User input directly concatenated into SQL queries.

**Detection:**
```python
# ❌ SQL injection vulnerable
def get_user(user_id: str):
    query = f"SELECT * FROM users WHERE id = '{user_id}'"
    return db.execute(query)
```

**Prevention:**
```python
# ✅ Parameterized queries
def get_user(user_id: str):
    query = "SELECT * FROM users WHERE id = ?"
    return db.execute(query, (user_id,))

# ✅ ORM usage
def get_user(user_id: str):
    return User.objects.filter(id=user_id).first()
```

**Automated Detection:**
- **Tools:** Bandit (Python), ESLint Security, SonarQube
- **SAST:** Static Application Security Testing
- **Remediation:** Always use parameterized queries or ORMs

### 11. Missing Input Validation

**Description:** Accepting user input without validation.

**Detection:**
```typescript
// ❌ No validation
app.post('/users', (req, res) => {
  const user = req.body; // Trust user input blindly
  db.users.create(user);
});
```

**Prevention:**
```typescript
// ✅ Schema validation
import { z } from 'zod';

const createUserSchema = z.object({
  email: z.string().email(),
  age: z.number().min(18).max(120),
  name: z.string().min(2).max(100),
});

app.post('/users', (req, res) => {
  const result = createUserSchema.safeParse(req.body);

  if (!result.success) {
    return res.status(400).json({ errors: result.error });
  }

  db.users.create(result.data);
});
```

**Automated Detection:**
- **Pattern:** Request handlers without validation
- **Tools:** Custom linters, security scanners
- **Remediation:** Add validation at all entry points

---

## Testing Anti-Patterns

### 12. Testing Implementation Details

**Description:** Tests coupled to internal implementation, not behavior.

**Detection:**
```typescript
// ❌ Testing implementation
test('Counter increments state', () => {
  const counter = new Counter();
  counter.increment();
  expect(counter._internalState).toBe(1); // Testing private state!
});
```

**Prevention:**
```typescript
// ✅ Testing behavior
test('Counter displays incremented value', () => {
  const counter = new Counter();
  counter.increment();
  expect(counter.getValue()).toBe(1); // Testing public API
});
```

**Impact:** Brittle tests that break with refactoring

### 13. Test Interdependence

**Description:** Tests that depend on execution order or shared state.

**Detection:**
```python
# ❌ Tests depend on each other
class TestUser:
    user_id = None  # Shared state!

    def test_create_user(self):
        user = create_user("test@example.com")
        self.user_id = user.id  # Store for next test

    def test_update_user(self):
        # Depends on test_create_user running first!
        update_user(self.user_id, name="Updated")
```

**Prevention:**
```python
# ✅ Independent tests
class TestUser:
    def test_create_user(self):
        user = create_user("test@example.com")
        assert user.id is not None

    def test_update_user(self):
        # Create own user
        user = create_user("test2@example.com")
        update_user(user.id, name="Updated")
        assert get_user(user.id).name == "Updated"
```

**Automated Detection:**
- **Run tests:** In random order, in isolation
- **Tools:** pytest-randomly, jest --runInBand=false
- **Remediation:** Setup/teardown per test, factories

### 14. Insufficient Test Coverage

**Description:** Critical paths untested, false sense of security.

**Detection:**
- Coverage < 80% on critical modules
- Happy path only, no error cases
- Integration tests missing

**Prevention:**
- **Test Pyramid:** Many unit, some integration, few E2E
- **Error Cases:** Test failure scenarios
- **Edge Cases:** Boundary conditions, null values

**Automated Detection:**
- **Tools:** Coverage.py, Istanbul, JaCoCo
- **CI/CD:** Fail build if coverage drops
- **Target:** 80%+ coverage on business logic

---

## AI Development Anti-Patterns

### 15. Context Overload

**Description:** Providing too much context to AI, reducing effectiveness.

**Detection:**
- Passing entire codebase to AI
- No progressive disclosure
- AI gets confused with information overload

**Prevention:**
- **Progressive Disclosure:** Start small, expand as needed
- **Relevant Context:** Only include related files
- **Summaries:** Provide high-level overviews, not full dumps

**Example:**
```markdown
❌ Bad: "Here are all 50 files in my codebase..."

✅ Good: "I'm adding a user authentication feature. Relevant files:
- src/auth/login.ts (current implementation)
- src/models/User.ts (user model)
- src/middleware/auth.ts (auth middleware)"
```

### 16. Blind AI Acceptance

**Description:** Accepting AI suggestions without review or testing.

**Detection:**
- Committing AI code without running tests
- Not understanding AI-generated code
- Skipping code review

**Prevention:**
- **Five-Try Rule:** AI has 5 attempts to pass tests
- **Always Test:** Run full test suite before committing
- **Understand:** Review and comprehend AI suggestions
- **Human Review:** Code review by humans

**See:** `base/ai-assisted-development.md` for Five-Try Rule

### 17. No AI Context Management

**Description:** Not preserving context for AI assistants across sessions.

**Detection:**
- Repeating same context every session
- AI "forgets" previous decisions
- No Architecture Decision Records

**Prevention:**
- **ADRs:** Document architectural decisions
- **Session Context:** Save `.context/session-YYYY-MM-DD.md`
- **Knowledge Base:** Maintain up-to-date documentation

**See:** `base/knowledge-management.md` for context patterns

---

## DevOps Anti-Patterns

### 18. Snowflake Servers

**Description:** Manually configured servers, not reproducible.

**Detection:**
- "Works on my machine" syndrome
- Cannot recreate server from scratch
- Manual SSH configuration changes

**Prevention:**
```yaml
# ✅ Infrastructure as Code
# terraform/main.tf
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"

  user_data = file("bootstrap.sh")

  tags = {
    Name = "web-server"
  }
}
```

**Automated Detection:**
- **Drift Detection:** Terraform plan, AWS Config
- **Immutable Infrastructure:** Docker, Kubernetes
- **Remediation:** Convert to IaC, use configuration management

### 19. Deployment at 5 PM Friday

**Description:** High-risk changes deployed before weekends/holidays.

**Detection:**
- Deployments scheduled at risky times
- No deployment windows or freeze periods
- Insufficient monitoring

**Prevention:**
- **Deployment Windows:** Tuesday-Thursday mornings
- **Freeze Periods:** Before holidays, weekends
- **Rollback Plan:** Always have rollback strategy
- **Gradual Rollout:** Canary or blue-green deployments

**Automated Detection:**
- **CI/CD Gates:** Block deployments outside windows
- **Approvals:** Require manager approval for Friday deploys

### 20. No Rollback Strategy

**Description:** Deploying without ability to quickly revert.

**Detection:**
- Database migrations with no down migration
- No previous version artifacts
- Stateful deployments

**Prevention:**
```typescript
// ✅ Feature flags for instant rollback
if (featureFlags.isEnabled('new-checkout-flow')) {
  return <NewCheckout />;
} else {
  return <OldCheckout />; // Can switch back instantly
}
```

**Also:**
- **Blue-Green Deployment:** Keep old version running
- **Database Migrations:** Backward-compatible changes
- **Artifact Versioning:** Keep last N versions

---

## Team Collaboration Anti-Patterns

### 21. Long-Lived Feature Branches

**Description:** Branches that live for weeks/months, causing merge hell.

**Detection:**
- Branches open > 2 weeks
- Hundreds of file conflicts
- Integration issues at merge time

**Prevention:**
- **Trunk-Based Development:** Merge to main daily
- **Feature Flags:** Hide incomplete features
- **Small PRs:** Break work into small, mergeable chunks
- **Continuous Integration:** Integrate frequently

**Automated Detection:**
- **Metrics:** Branch age alerts (> 5 days)
- **CI/CD:** Daily integration checks
- **Remediation:** Break down features, use feature flags

**See:** `base/parallel-development.md` for strategies

### 22. Unclear Commit Messages

**Description:** Commit messages that provide no context.

**Detection:**
```bash
# ❌ Bad commit messages
git commit -m "fix"
git commit -m "updates"
git commit -m "wip"
git commit -m "asdf"
```

**Prevention:**
```bash
# ✅ Conventional commits
git commit -m "feat(auth): add JWT token refresh endpoint

- Implements automatic token refresh
- Expires after 7 days
- Includes tests for expiration logic

Closes #123"
```

**Automated Detection:**
- **Pre-commit Hooks:** commitlint, conventional commits
- **CI/CD:** Reject commits without proper format
- **Remediation:** Enforce commit message conventions

**See:** `base/git-workflow.md` for commit standards

### 23. No Code Reviews

**Description:** Merging code without peer review.

**Detection:**
- PRs auto-merged by author
- No review comments
- No approval requirements

**Prevention:**
- **Required Reviews:** 1-2 approvals before merge
- **CODEOWNERS:** Auto-assign relevant reviewers
- **Review Checklist:** Tests, docs, security, performance
- **Pair Programming:** Real-time code review

**Automated Detection:**
- **Branch Protection:** Require approvals in GitHub/GitLab
- **Metrics:** Track review participation

---

## Detection and Prevention Strategy

### Automated Detection Tools

#### Static Analysis
- **Python:** Pylint, Flake8, Bandit, mypy
- **TypeScript/JavaScript:** ESLint, TSLint, SonarQube
- **Java:** SpotBugs, PMD, Checkstyle, SonarQube
- **C#:** Roslyn analyzers, StyleCop
- **Rust:** Clippy

#### Security Scanning
- **Secrets:** git-secrets, TruffleHog, Gitleaks
- **Dependencies:** Dependabot, Snyk, npm audit
- **SAST:** SonarQube, Checkmarx, Fortify
- **DAST:** OWASP ZAP, Burp Suite

#### Code Quality
- **Coverage:** Coverage.py, Istanbul, JaCoCo
- **Complexity:** Radon, SonarQube
- **Duplication:** PMD CPD, jscpd

### Prevention Strategies

#### Pre-commit Hooks
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    hooks:
      - id: check-yaml
      - id: check-json
      - id: detect-private-key

  - repo: https://github.com/psf/black
    hooks:
      - id: black

  - repo: https://github.com/pycqa/flake8
    hooks:
      - id: flake8
```

#### CI/CD Gates
```yaml
# .github/workflows/quality.yml
name: Code Quality
on: [pull_request]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run linters
        run: npm run lint

      - name: Check test coverage
        run: |
          npm test -- --coverage
          if [ $(cat coverage/coverage-summary.json | jq '.total.lines.pct') -lt 80 ]; then
            echo "Coverage below 80%"
            exit 1
          fi

      - name: Security scan
        run: npm audit --audit-level=moderate
```

#### Code Review Checklist

- [ ] Tests pass locally and in CI
- [ ] Code coverage maintained or improved
- [ ] No hardcoded secrets
- [ ] Input validation present
- [ ] Error handling implemented
- [ ] Documentation updated
- [ ] No obvious security vulnerabilities
- [ ] Performance considered
- [ ] Accessibility requirements met

## Related Resources

- `base/code-quality.md` - Quality standards
- `base/refactoring-patterns.md` - Refactoring catalog
- `base/security-principles.md` - Security best practices
- `base/testing-philosophy.md` - Testing principles
- `base/ai-assisted-development.md` - AI development patterns
- `base/git-workflow.md` - Git and commit standards

## Continuous Improvement

This document should be updated when:

- New anti-patterns are discovered in the codebase
- Tools or detection methods improve
- Team learns from production incidents
- Industry best practices evolve

**Review Frequency:** Quarterly

**Owner:** Engineering team, with AI assistant support
