# Implementation Guide: Phased Rollout Plan

> **Purpose:** Step-by-step guide for adopting centralized rules in your project
> **Timeline:** 8 weeks (flexible based on project size and maturity)
> **Audience:** Engineering teams, AI assistants, tech leads

This guide provides a practical, phased approach to implementing the centralized rules framework in your project. The rollout is designed to minimize disruption while maximizing value.

## Overview

### Rollout Philosophy

1. **Progressive Enhancement:** Start with high-impact, low-effort practices
2. **Measure Success:** Track metrics before and after each phase
3. **Team Buy-In:** Include team in decision-making
4. **AI-Assisted:** Leverage AI assistants for implementation
5. **Iterative:** Review and adjust based on feedback

### Four-Phase Approach

- **Phase 1 (Weeks 1-2):** Foundation - Essential workflow and quality standards
- **Phase 2 (Weeks 3-4):** Quality & Testing - Comprehensive testing and code quality
- **Phase 3 (Weeks 5-6):** Architecture & Security - Solid foundations for growth
- **Phase 4 (Weeks 7-8):** Advanced Practices - AI, observability, and optimization

---

## Phase 1: Foundation (Weeks 1-2)

### Goal
Establish core development workflow and quality standards that provide immediate value.

### Practices to Implement

#### Week 1: Git Workflow & Code Quality

**Day 1-2: Git Workflow Setup**

1. **Implement Conventional Commits**
   ```bash
   # Install commitlint
   npm install --save-dev @commitlint/{cli,config-conventional}

   # Configure
   echo "module.exports = { extends: ['@commitlint/config-conventional'] };" > commitlint.config.js
   ```

   **Reference:** `base/git-workflow.md`

2. **Set Up Branch Protection**
   - Require pull requests for main branch
   - Require 1 approval before merge
   - Require status checks to pass

3. **Create PR Template**
   ```markdown
   ## Description
   Brief description of changes

   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   - [ ] Documentation update

   ## Testing
   - [ ] Tests pass locally
   - [ ] Added new tests
   - [ ] Updated documentation

   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Self-reviewed code
   - [ ] Commented complex areas
   - [ ] No console.log/debugger statements
   ```

**Day 3-5: Code Quality Tools**

1. **Set Up Linting**

   **TypeScript/JavaScript:**
   ```json
   // .eslintrc.json
   {
     "extends": [
       "eslint:recommended",
       "plugin:@typescript-eslint/recommended"
     ],
     "rules": {
       "no-console": "warn",
       "no-debugger": "error"
     }
   }
   ```

   **Python:**
   ```toml
   # pyproject.toml
   [tool.ruff]
   line-length = 100
   select = ["E", "F", "I", "N"]
   ```

   **Reference:** Language-specific files in `languages/`

2. **Set Up Formatting**
   - **TypeScript:** Prettier
   - **Python:** Black
   - **Java:** Spotless
   - **C#:** dotnet format

3. **Pre-commit Hooks**
   ```yaml
   # .pre-commit-config.yaml
   repos:
     - repo: https://github.com/pre-commit/pre-commit-hooks
       hooks:
         - id: trailing-whitespace
         - id: end-of-file-fixer
         - id: check-yaml
         - id: check-json
   ```

**Success Criteria:**
- ✅ All commits follow conventional commits format
- ✅ PRs require approval
- ✅ Linting passes on all new code
- ✅ Pre-commit hooks prevent bad commits

#### Week 2: Basic Testing & CI/CD

**Day 1-3: Testing Setup**

1. **Choose Testing Framework**
   - TypeScript: Vitest or Jest
   - Python: pytest
   - Java: JUnit 5
   - C#: xUnit

2. **Write First Tests**
   ```typescript
   // Example: Start with critical business logic
   describe('UserService', () => {
     it('should create user with valid email', () => {
       const user = UserService.create({
         email: 'test@example.com',
         name: 'Test User'
       });

       expect(user).toBeDefined();
       expect(user.email).toBe('test@example.com');
     });
   });
   ```

   **Reference:** `base/testing-philosophy.md`

3. **Set Coverage Baseline**
   ```bash
   # Measure current coverage
   npm test -- --coverage

   # Goal: Start where you are, improve by 5% each sprint
   ```

**Day 4-5: Basic CI/CD**

1. **GitHub Actions Workflow**
   ```yaml
   # .github/workflows/ci.yml
   name: CI

   on:
     pull_request:
       branches: [main]
     push:
       branches: [main]

   jobs:
     test:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3

         - name: Setup Node
           uses: actions/setup-node@v3
           with:
             node-version: '18'

         - name: Install dependencies
           run: npm ci

         - name: Run linters
           run: npm run lint

         - name: Run tests
           run: npm test

         - name: Check coverage
           run: npm test -- --coverage
   ```

   **Reference:** `base/cicd-comprehensive.md`

**Success Criteria:**
- ✅ Test framework configured
- ✅ At least 10 tests written
- ✅ CI pipeline running on every PR
- ✅ Tests pass before merge

### Phase 1 Checklist

- [ ] Conventional commits enforced
- [ ] Branch protection rules active
- [ ] PR template in use
- [ ] Linting configured and passing
- [ ] Formatting automated
- [ ] Pre-commit hooks working
- [ ] Testing framework set up
- [ ] CI/CD pipeline running
- [ ] Team trained on new workflow

### Phase 1 Metrics

Track these metrics before and after Phase 1:

- **Commit quality:** % of commits following convention (Target: 95%+)
- **PR review time:** Average time from creation to merge (Target: < 24 hours)
- **Build failures:** % of builds that fail (Target: < 10%)
- **Test count:** Number of tests (Target: Increase by 20%)

---

## Phase 2: Quality & Testing (Weeks 3-4)

### Goal
Establish comprehensive testing practices and improve code quality metrics.

### Practices to Implement

#### Week 3: Test Coverage & Quality Gates

**Day 1-3: Increase Test Coverage**

1. **Test Critical Paths**
   - User authentication flows
   - Payment processing
   - Data persistence
   - API endpoints

2. **Add Integration Tests**
   ```typescript
   // Example integration test
   describe('User API Integration', () => {
     it('should create and retrieve user', async () => {
       const response = await request(app)
         .post('/api/users')
         .send({ email: 'test@example.com', name: 'Test' });

       expect(response.status).toBe(201);

       const userId = response.body.id;

       const getResponse = await request(app)
         .get(`/api/users/${userId}`);

       expect(getResponse.status).toBe(200);
       expect(getResponse.body.email).toBe('test@example.com');
     });
   });
   ```

3. **Coverage Gates**
   ```yaml
   # In CI/CD
   - name: Check coverage threshold
     run: |
       npm test -- --coverage
       COVERAGE=$(cat coverage/coverage-summary.json | jq '.total.lines.pct')
       if (( $(echo "$COVERAGE < 60" | bc -l) )); then
         echo "Coverage $COVERAGE% is below 60%"
         exit 1
       fi
   ```

   **Target Coverage:**
   - MVP/POC: 40%+
   - Pre-Production: 60%+
   - Production: 80%+

   **Reference:** `base/project-maturity-levels.md`

**Day 4-5: Code Quality Metrics**

1. **SonarQube or Similar**
   ```yaml
   # SonarCloud integration
   - name: SonarCloud Scan
     uses: SonarSource/sonarcloud-github-action@master
     env:
       GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
       SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
   ```

2. **Quality Gates**
   - **Complexity:** Cyclomatic complexity < 10 per function
   - **Duplication:** < 3% code duplication
   - **Maintainability:** Maintainability rating A or B

   **Reference:** `base/code-quality.md`

**Success Criteria:**
- ✅ Coverage increased by 20%
- ✅ All critical paths have tests
- ✅ Quality gates pass in CI
- ✅ No code smells in new code

#### Week 4: Refactoring & Technical Debt

**Day 1-3: Address Technical Debt**

1. **Identify High-Priority Debt**
   - Use SonarQube/CodeClimate to identify issues
   - Prioritize by business impact and effort

2. **Refactor Incrementally**
   ```typescript
   // Example: Extract method refactoring
   // ❌ Before: Long method
   function processOrder(order) {
     // 100 lines of code doing everything
   }

   // ✅ After: Extracted methods
   function processOrder(order) {
     validateOrder(order);
     calculateTotal(order);
     applyDiscounts(order);
     saveOrder(order);
     sendConfirmation(order);
   }
   ```

   **Reference:** `base/refactoring-patterns.md`

3. **Document Decisions**
   ```markdown
   # ADR 001: Extract Order Processing Logic

   ## Status
   Accepted

   ## Context
   Order processing code was in a single 300-line method, making it hard to test and maintain.

   ## Decision
   Extract order processing into separate functions with single responsibilities.

   ## Consequences
   - Improved testability (can test each step independently)
   - Better readability
   - Easier to add new processing steps
   ```

   **Reference:** `base/knowledge-management.md`

**Day 4-5: Anti-Pattern Detection**

1. **Run Anti-Pattern Checks**
   - God objects (> 20 methods)
   - Long methods (> 50 lines)
   - Deep nesting (> 4 levels)
   - Code duplication (> 6 lines)

2. **Create Remediation Plan**
   - Track in project backlog
   - Allocate 20% of sprint to tech debt

   **Reference:** `ANTI_PATTERNS.md`

**Success Criteria:**
- ✅ Technical debt backlog created
- ✅ Top 5 code smells addressed
- ✅ Refactoring documented in ADRs
- ✅ Anti-pattern checks automated

### Phase 2 Checklist

- [ ] Test coverage > 60%
- [ ] Integration tests added
- [ ] Quality gates enforced in CI
- [ ] SonarQube or equivalent integrated
- [ ] Technical debt identified and prioritized
- [ ] Top code smells refactored
- [ ] ADRs documented
- [ ] Anti-pattern detection automated

### Phase 2 Metrics

- **Test coverage:** % (Target: 60%+ for pre-production)
- **Code duplication:** % (Target: < 3%)
- **Cyclomatic complexity:** Average (Target: < 10)
- **Technical debt ratio:** % (Target: < 5%)
- **Refactoring velocity:** Story points/sprint (Target: 20% of capacity)

---

## Phase 3: Architecture & Security (Weeks 5-6)

### Goal
Establish solid architectural foundations and security practices.

### Practices to Implement

#### Week 5: Architecture Patterns

**Day 1-2: Document Current Architecture**

1. **Create Architecture Diagrams**
   - System context diagram
   - Container diagram
   - Component diagram

   **Reference:** `base/architecture-principles.md`

2. **Identify Architectural Principles**
   ```markdown
   # Architectural Principles

   1. **Separation of Concerns:** Each module has a single responsibility
   2. **Dependency Inversion:** Depend on abstractions, not concretions
   3. **YAGNI:** Don't build what you don't need yet
   4. **12-Factor:** Follow 12-factor app principles
   ```

**Day 3-5: Apply Architecture Patterns**

1. **Layered Architecture**
   ```
   Presentation Layer (API/UI)
         ↓
   Business Logic Layer (Services)
         ↓
   Data Access Layer (Repositories)
         ↓
   Database
   ```

2. **Dependency Injection**
   ```typescript
   // Example: Constructor injection
   class UserService {
     constructor(
       private userRepository: IUserRepository,
       private emailService: IEmailService
     ) {}

     async createUser(data: CreateUserDto) {
       const user = await this.userRepository.create(data);
       await this.emailService.sendWelcome(user.email);
       return user;
     }
   }
   ```

   **Reference:** Framework-specific best practices in `frameworks/`

**Success Criteria:**
- ✅ Architecture documented
- ✅ Clear separation of concerns
- ✅ Dependency injection implemented
- ✅ Team understands architecture

#### Week 6: Security Hardening

**Day 1-2: Security Scanning**

1. **Dependency Scanning**
   ```yaml
   # GitHub Actions
   - name: Run Snyk
     uses: snyk/actions/node@master
     env:
       SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
   ```

2. **Secret Scanning**
   ```bash
   # Install git-secrets
   git secrets --install
   git secrets --register-aws
   ```

3. **SAST (Static Application Security Testing)**
   - Use CodeQL, Semgrep, or Bandit

   **Reference:** `base/security-principles.md`

**Day 3-5: Security Hardening**

1. **Input Validation**
   - All API endpoints validate input
   - Use schema validation (Zod, Pydantic, etc.)

2. **Authentication & Authorization**
   - Implement JWT or OAuth
   - Role-based access control

3. **Security Headers**
   ```typescript
   // Express example
   import helmet from 'helmet';

   app.use(helmet({
     contentSecurityPolicy: {
       directives: {
         defaultSrc: ["'self'"],
         styleSrc: ["'self'", "'unsafe-inline'"],
       },
     },
   }));
   ```

4. **Rate Limiting**
   ```typescript
   import rateLimit from 'express-rate-limit';

   const limiter = rateLimit({
     windowMs: 15 * 60 * 1000, // 15 minutes
     max: 100, // limit each IP to 100 requests per windowMs
   });

   app.use('/api/', limiter);
   ```

**Success Criteria:**
- ✅ No high-severity vulnerabilities
- ✅ All endpoints have input validation
- ✅ Security headers configured
- ✅ Rate limiting implemented
- ✅ Secrets not in source code

### Phase 3 Checklist

- [ ] Architecture documented
- [ ] Dependency injection implemented
- [ ] Security scanning automated
- [ ] No secrets in source code
- [ ] Input validation on all endpoints
- [ ] Authentication implemented
- [ ] Security headers configured
- [ ] Rate limiting active
- [ ] Security review completed

### Phase 3 Metrics

- **Security vulnerabilities:** Count (Target: 0 high/critical)
- **API endpoints with validation:** % (Target: 100%)
- **Secrets in source code:** Count (Target: 0)
- **Architecture documentation:** Up-to-date (Target: Yes)

---

## Phase 4: Advanced Practices (Weeks 7-8)

### Goal
Implement advanced practices for AI development, observability, and optimization.

### Practices to Implement

#### Week 7: AI-Assisted Development

**Day 1-3: AI Development Workflow**

1. **Implement Five-Try Rule**
   ```markdown
   ## Five-Try Rule

   1. AI writes test (Red)
   2. AI implements feature to pass test (Green)
   3. If test fails, AI has 4 more attempts
   4. After 5 failures, human intervention required
   5. Always commit with passing tests
   ```

   **Reference:** `base/ai-assisted-development.md`

2. **Context Management**
   - Create `.context/` directory
   - Document session context
   - Maintain ADRs

   **Reference:** `base/knowledge-management.md`

3. **Parallel Development**
   - Use feature flags for concurrent work
   - Implement trunk-based development

   **Reference:** `base/parallel-development.md`

**Day 4-5: AI Ethics & Governance**

1. **Model Cards** (if using ML)
   ```markdown
   # Model Card: User Recommendation Model

   ## Model Details
   - Version: 1.0.0
   - Type: Collaborative Filtering
   - Training Data: User interaction logs (Jan-Mar 2024)

   ## Intended Use
   - Recommend products to users
   - Not for credit decisions or employment

   ## Metrics
   - Precision@10: 0.65
   - Recall@10: 0.42
   - Fairness (demographic parity): 0.92

   ## Limitations
   - Cold start problem for new users
   - Bias toward popular items
   ```

   **Reference:** `base/ai-ethics-governance.md`, `base/ai-model-lifecycle.md`

**Success Criteria:**
- ✅ Five-Try Rule documented and followed
- ✅ Context management in place
- ✅ AI ethics considered (if applicable)
- ✅ Team trained on AI workflows

#### Week 8: Observability & Optimization

**Day 1-3: Observability**

1. **Logging**
   ```typescript
   import winston from 'winston';

   const logger = winston.createLogger({
     level: 'info',
     format: winston.format.json(),
     transports: [
       new winston.transports.File({ filename: 'error.log', level: 'error' }),
       new winston.transports.File({ filename: 'combined.log' }),
     ],
   });

   logger.info('User created', { userId: user.id, email: user.email });
   ```

2. **Metrics**
   - Implement RED metrics (Rate, Errors, Duration)
   - Use Prometheus, DataDog, or similar

3. **Tracing**
   - Add request IDs
   - Distributed tracing if microservices

   **Reference:** `base/metrics-standards.md`

**Day 4-5: Performance Optimization**

1. **Database Optimization**
   - Add indexes
   - Optimize queries (N+1 problem)
   - Connection pooling

2. **Caching**
   - Implement Redis or similar
   - Cache expensive operations

3. **Load Testing**
   - Use k6, Artillery, or JMeter
   - Establish performance baselines

**Success Criteria:**
- ✅ Structured logging implemented
- ✅ Key metrics tracked
- ✅ Performance baselines established
- ✅ Caching strategy in place
- ✅ Database optimized

### Phase 4 Checklist

- [ ] Five-Try Rule implemented
- [ ] Context management active
- [ ] AI workflows documented
- [ ] Structured logging in place
- [ ] Metrics collection automated
- [ ] Performance baselines established
- [ ] Caching implemented
- [ ] Load testing completed
- [ ] Observability dashboard created

### Phase 4 Metrics

- **AI development velocity:** Story points/sprint
- **Log coverage:** % of critical paths logging
- **P95 response time:** ms (Target: < 500ms)
- **Cache hit rate:** % (Target: > 80%)
- **Error rate:** % (Target: < 1%)

---

## Ongoing Practices

After completing the 8-week rollout, maintain these practices:

### Weekly

- **Code Reviews:** All PRs reviewed within 24 hours
- **Test Runs:** Full test suite on every PR
- **Security Scans:** Automated on every commit

### Bi-Weekly

- **Retrospectives:** Review what's working, what's not
- **Tech Debt Review:** Prioritize top technical debt items
- **Metrics Review:** Check quality and performance metrics

### Monthly

- **Architecture Review:** Ensure architecture still meets needs
- **Security Audit:** Review security posture
- **Dependency Updates:** Update and test dependencies

### Quarterly

- **Anti-Pattern Review:** Update `ANTI_PATTERNS.md`
- **Maturity Assessment:** Reassess project maturity level
- **Practice Review:** Add/remove practices as needed

---

## Success Metrics Summary

### Phase 1 (Weeks 1-2)
- ✅ 95%+ commits follow conventional commits
- ✅ < 24 hour PR review time
- ✅ < 10% build failures
- ✅ 20% increase in test count

### Phase 2 (Weeks 3-4)
- ✅ 60%+ test coverage
- ✅ < 3% code duplication
- ✅ < 10 average cyclomatic complexity
- ✅ < 5% technical debt ratio

### Phase 3 (Weeks 5-6)
- ✅ 0 high/critical security vulnerabilities
- ✅ 100% API endpoints validated
- ✅ 0 secrets in source code
- ✅ Architecture documentation complete

### Phase 4 (Weeks 7-8)
- ✅ Five-Try Rule documented
- ✅ < 500ms P95 response time
- ✅ > 80% cache hit rate
- ✅ < 1% error rate

---

## Common Challenges and Solutions

### Challenge 1: Team Resistance

**Symptom:** "This is too much process! It slows us down."

**Solution:**
- Start with high-value, low-effort practices
- Show metrics improvement
- Automate everything possible
- Celebrate wins

### Challenge 2: Tool Overload

**Symptom:** Too many tools, too much configuration.

**Solution:**
- Use integrated platforms (GitHub Actions, GitLab CI)
- Start with basics, add tools incrementally
- Document tool purposes clearly
- Provide training

### Challenge 3: Low Test Coverage

**Symptom:** Hard to write tests for legacy code.

**Solution:**
- Start with new code (100% coverage requirement)
- Add tests when touching legacy code
- Use characterization tests for legacy
- Incremental improvement (5% per sprint)

**Reference:** `base/refactoring-patterns.md`

### Challenge 4: AI Over-Reliance

**Symptom:** Team accepts AI suggestions without understanding.

**Solution:**
- Require human review of all AI code
- Enforce Five-Try Rule with tests
- Code review checklist includes "I understand this code"
- Training on AI limitations

**Reference:** `base/ai-assisted-development.md`

---

## Customizing for Your Project

### For MVP/POC Projects

**Focus on:**
- Phase 1 (Foundation)
- Basic testing (40% coverage)
- Minimal security (secrets, basic validation)

**Skip/Defer:**
- Advanced architecture patterns
- Comprehensive observability
- Performance optimization

**Reference:** `base/project-maturity-levels.md`

### For Pre-Production Projects

**Focus on:**
- Phases 1-3 (Foundation, Quality, Architecture)
- 60%+ test coverage
- Security hardening
- Basic observability

**Skip/Defer:**
- Advanced AI practices
- Complex optimization

### For Production Projects

**Implement All Phases:**
- 80%+ test coverage
- Full security compliance
- Comprehensive observability
- All advanced practices

---

## Related Resources

- `PRACTICE_CROSSREFERENCE.md` - Practice-to-file mapping
- `ANTI_PATTERNS.md` - Common anti-patterns
- `SUCCESS_METRICS.md` - Detailed metrics definitions
- `base/project-maturity-levels.md` - Maturity framework
- All `base/*.md` files - Detailed practice guidelines

## Conclusion

This 8-week rollout plan provides a structured approach to adopting best practices. Remember:

1. **Be Pragmatic:** Adapt the timeline and practices to your context
2. **Measure Success:** Track metrics to show improvement
3. **Iterate:** Review and adjust based on team feedback
4. **Automate:** Use tools and AI assistants to reduce manual effort
5. **Celebrate:** Recognize team achievements along the way

**Questions or feedback?** Update this guide based on your experience!
