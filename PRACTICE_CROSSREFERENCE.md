# Practice Cross-Reference

> **Purpose:** Map best practices to implementation files and vice versa
> **Audience:** AI assistants, developers, architects

This document provides bidirectional mapping between best practices and their implementation locations in the centralized rules repository.

## Practice-to-File Mapping

### Core Workflow Practices

#### Git Workflow
- **Practice:** Atomic commits, conventional commit messages, branch protection
- **Files:**
  - `base/git-workflow.md` - Core workflow patterns
  - `base/parallel-development.md` - Multi-developer workflows
  - All framework files - Testing before commits

#### Code Quality
- **Practice:** Linting, formatting, static analysis, type safety
- **Files:**
  - `base/code-quality.md` - Quality standards
  - `languages/typescript/coding-standards.md` - ESLint, Prettier
  - `languages/python/coding-standards.md` - Ruff, Black, mypy
  - `languages/java/coding-standards.md` - Spotless, Checkstyle
  - `languages/csharp/coding-standards.md` - StyleCop, Roslyn analyzers

#### Testing Philosophy
- **Practice:** Test-first development, comprehensive coverage, test pyramid
- **Files:**
  - `base/testing-philosophy.md` - Testing principles
  - `base/ai-assisted-development.md` - TDD with AI (Five-Try Rule)
  - All `languages/*/testing.md` files - Language-specific testing
  - All `frameworks/*/best-practices.md` - Framework testing patterns

#### Refactoring
- **Practice:** Safe refactoring, code smells detection, incremental improvements
- **Files:**
  - `base/refactoring-patterns.md` - Refactoring catalog
  - `base/code-quality.md` - Code smell detection
  - All coding standards files - When to refactor

### Architecture & Design

#### Architecture Principles
- **Practice:** SOLID, DRY, YAGNI, separation of concerns
- **Files:**
  - `base/architecture-principles.md` - Core architectural patterns
  - `base/12-factor-app.md` - Cloud-native architecture
  - All framework best practices - Framework-specific architecture

#### 12-Factor App
- **Practice:** Cloud-native application design, config, backing services
- **Files:**
  - `base/12-factor-app.md` - 12-Factor methodology
  - `base/configuration-management.md` - Config externalization
  - `cloud/vercel/*.md` - Vercel-specific implementations
  - Framework files - Framework integrations

### Security & Operations

#### Security Principles
- **Practice:** Defense in depth, least privilege, secure defaults
- **Files:**
  - `base/security-principles.md` - Security foundations
  - `base/ai-ethics-governance.md` - AI security and ethics
  - `frameworks/express/best-practices.md` - Express security
  - `frameworks/django/best-practices.md` - Django security
  - `frameworks/springboot/best-practices.md` - Spring Security

#### CI/CD
- **Practice:** Automated pipelines, continuous testing, deployment automation
- **Files:**
  - `base/cicd-comprehensive.md` - CI/CD patterns
  - `base/operations-automation.md` - Deployment automation
  - `cloud/vercel/deployment-best-practices.md` - Vercel deployments

#### Configuration Management
- **Practice:** Environment variables, secrets management, feature flags
- **Files:**
  - `base/configuration-management.md` - Config patterns
  - `base/12-factor-app.md` - Config factor
  - `cloud/vercel/environment-configuration.md` - Vercel env vars

#### Metrics & Observability
- **Practice:** Logging, monitoring, alerting, tracing
- **Files:**
  - `base/metrics-standards.md` - Metrics collection
  - `cloud/vercel/reliability-observability.md` - Vercel observability
  - `base/chaos-engineering.md` - Resilience testing

### AI Development

#### AI-Assisted Development
- **Practice:** Progressive enhancement, AI pair programming, context management
- **Files:**
  - `base/ai-assisted-development.md` - AI development practices
  - `base/knowledge-management.md` - AI context management
  - `base/parallel-development.md` - Multi-AI workflows
  - `base/tool-design.md` - Building AI-friendly tools

#### AI Ethics & Governance
- **Practice:** Fairness, bias mitigation, model cards, responsible AI
- **Files:**
  - `base/ai-ethics-governance.md` - Ethics and governance
  - `base/ai-model-lifecycle.md` - Model management

#### AI Model Lifecycle
- **Practice:** Experimentation, versioning, deployment, monitoring
- **Files:**
  - `base/ai-model-lifecycle.md` - Model lifecycle management
  - `base/metrics-standards.md` - Model metrics

#### Knowledge Management
- **Practice:** Documentation-first, ADRs, context preservation
- **Files:**
  - `base/knowledge-management.md` - Knowledge patterns
  - `base/ai-assisted-development.md` - AI context

#### Parallel Development
- **Practice:** Task decomposition, merge strategies, conflict resolution
- **Files:**
  - `base/parallel-development.md` - Parallel workflows
  - `base/git-workflow.md` - Branch strategies

### Advanced Practices

#### Chaos Engineering
- **Practice:** Resilience testing, failure injection, automated recovery
- **Files:**
  - `base/chaos-engineering.md` - Chaos patterns
  - `cloud/vercel/reliability-observability.md` - Production resilience

#### Lean Development
- **Practice:** Eliminate waste, MVP-first, progressive enhancement
- **Files:**
  - `base/lean-development.md` - Lean principles
  - `base/project-maturity-levels.md` - Progressive rigor

#### Operations Automation
- **Practice:** Infrastructure as Code, runbooks, self-service
- **Files:**
  - `base/operations-automation.md` - Automation patterns
  - `base/cicd-comprehensive.md` - Deployment automation

#### Tool Design
- **Practice:** Smart defaults, progressive disclosure, hooks
- **Files:**
  - `base/tool-design.md` - Tool design patterns
  - `base/ai-assisted-development.md` - AI-friendly tools

#### Project Maturity Levels
- **Practice:** Progressive rigor, maturity-based standards
- **Files:**
  - `base/project-maturity-levels.md` - Maturity framework
  - All base files - Maturity indicators

## File-to-Practice Reverse Index

### Base Rules

#### `base/git-workflow.md`
- Atomic commits
- Conventional commit messages
- Branch protection
- Code review processes
- Merge strategies

#### `base/code-quality.md`
- Static analysis
- Linting and formatting
- Type safety
- Code complexity metrics
- Technical debt management

#### `base/testing-philosophy.md`
- Test pyramid
- Test-first development
- Coverage standards
- Test isolation
- Continuous testing

#### `base/refactoring-patterns.md`
- Code smell detection
- Refactoring catalog
- Safe refactoring
- Legacy code patterns

#### `base/architecture-principles.md`
- SOLID principles
- Domain-Driven Design
- Clean Architecture
- Microservices patterns
- Event-driven architecture

#### `base/12-factor-app.md`
- Codebase (one codebase, many deploys)
- Dependencies (explicitly declare)
- Config (store in environment)
- Backing services
- Build, release, run
- Processes (stateless)
- Port binding
- Concurrency
- Disposability
- Dev/prod parity
- Logs (event streams)
- Admin processes

#### `base/security-principles.md`
- Defense in depth
- Least privilege
- Secure defaults
- Input validation
- Authentication & authorization
- Encryption at rest/transit
- Security testing

#### `base/cicd-comprehensive.md`
- Automated builds
- Continuous integration
- Continuous deployment
- Pipeline as code
- Blue-green deployments
- Canary releases
- Rollback strategies

#### `base/configuration-management.md`
- Environment variables
- Secrets management
- Feature flags
- Configuration validation
- Multi-environment support

#### `base/metrics-standards.md`
- RED metrics (Rate, Errors, Duration)
- USE metrics (Utilization, Saturation, Errors)
- Custom business metrics
- SLIs and SLOs
- Alert definitions

#### `base/operations-automation.md`
- Infrastructure as Code
- Automated runbooks
- Self-service operations
- Deployment automation
- Disaster recovery

#### `base/ai-assisted-development.md`
- Progressive AI enhancement
- Five-Try Rule
- Test-first with AI
- Context management
- AI pair programming

#### `base/ai-ethics-governance.md`
- Fairness and bias mitigation
- Model cards
- Privacy by design
- Regulatory compliance
- Responsible AI practices

#### `base/ai-model-lifecycle.md`
- Experimentation tracking
- Model versioning
- A/B testing
- Model monitoring
- Drift detection

#### `base/knowledge-management.md`
- Documentation-first
- ADRs (Architecture Decision Records)
- Visual scaffolding
- Session context
- Knowledge transfer

#### `base/parallel-development.md`
- Task decomposition
- Multi-agent workflows
- Merge strategies
- Conflict resolution
- Integration testing

#### `base/chaos-engineering.md`
- Failure injection
- Resilience testing
- Automated recovery
- Chaos experiments
- Production testing

#### `base/lean-development.md`
- Eliminate waste
- MVP-first
- Progressive enhancement
- Value stream mapping
- Feature prioritization

#### `base/tool-design.md`
- Smart defaults
- Progressive disclosure
- Hook systems
- Self-documenting tools
- Composable commands

#### `base/project-maturity-levels.md`
- MVP/POC level
- Pre-Production level
- Production level
- Progressive rigor framework

### Language Standards

#### `languages/typescript/coding-standards.md`
- Strict mode
- ESLint configuration
- Prettier formatting
- Naming conventions
- Type safety patterns
- Error handling

#### `languages/typescript/testing.md`
- Vitest/Jest patterns
- Component testing
- Integration testing
- E2E testing
- Coverage requirements

#### `languages/python/coding-standards.md`
- Type hints
- Ruff linting
- Black formatting
- Error handling
- Pydantic validation

#### `languages/python/testing.md`
- pytest patterns
- Fixtures
- Mocking
- Parametrized tests
- Coverage with pytest-cov

#### `languages/java/coding-standards.md`
- Java 17+ features
- Naming conventions
- Optional for null safety
- Pattern matching
- Records and sealed classes

#### `languages/java/testing.md`
- JUnit 5
- Mockito
- AssertJ
- Parametrized tests

#### `languages/csharp/coding-standards.md`
- C# 12+ features
- Nullable reference types
- Records and init-only properties
- Pattern matching
- LINQ patterns

#### `languages/csharp/testing.md`
- xUnit patterns
- Moq for mocking
- FluentAssertions
- Async testing

#### `languages/rust/coding-standards.md`
- Ownership and borrowing
- Result/Option types
- Error handling with thiserror
- Type safety

#### `languages/rust/testing.md`
- Built-in test framework
- Async testing with tokio
- Property-based testing

### Framework Best Practices

#### `frameworks/fastapi/best-practices.md`
- Async/await patterns
- Dependency injection
- Pydantic models
- Router organization
- Testing with TestClient

#### `frameworks/express/best-practices.md`
- Middleware ordering
- Router organization
- Error handling
- Security headers
- Rate limiting
- Validation with Zod

#### `frameworks/springboot/best-practices.md`
- Dependency injection
- Spring Data JPA
- REST controllers
- Exception handling
- Security configuration
- Integration testing

#### `frameworks/django/best-practices.md`
- Model design
- QuerySet optimization
- Django REST Framework
- Middleware patterns
- Signals
- Celery tasks
- Admin customization

#### `frameworks/react/best-practices.md`
- Hooks patterns
- Component composition
- State management
- Performance optimization
- Forms handling
- Data fetching (SWR, React Query)
- Server components (RSC)
- Testing with RTL

### Cloud Providers

#### `cloud/vercel/deployment-best-practices.md`
- Build configuration
- Deployment strategies
- Preview deployments
- Production checklist

#### `cloud/vercel/environment-configuration.md`
- Environment variables
- Secrets management
- Multi-environment setup

#### `cloud/vercel/security-practices.md`
- Security headers
- Deployment protection
- Authentication
- CORS configuration

#### `cloud/vercel/performance-optimization.md`
- Core Web Vitals
- Edge caching
- ISR (Incremental Static Regeneration)
- Image optimization

#### `cloud/vercel/reliability-observability.md`
- Analytics integration
- Error tracking
- Logging patterns
- Uptime monitoring

#### `cloud/vercel/cost-optimization.md`
- Bandwidth reduction
- Function optimization
- Caching strategies
- Spend monitoring

## Usage Patterns

### For AI Assistants

When implementing a feature:

1. **Identify the practice category** (workflow, architecture, security, AI)
2. **Check practice-to-file mapping** for relevant guidelines
3. **Apply maturity-appropriate standards** from project-maturity-levels.md
4. **Follow language-specific patterns** from languages/
5. **Apply framework patterns** from frameworks/
6. **Consider cloud-specific optimizations** from cloud/

### For Developers

When reviewing code:

1. **Check file-to-practice index** for the file being modified
2. **Verify compliance** with listed practices
3. **Reference linked files** for detailed guidance
4. **Apply progressive rigor** based on project maturity

### For Architects

When designing systems:

1. **Review architecture practices** (architecture-principles, 12-factor-app)
2. **Check security practices** for compliance requirements
3. **Review AI practices** if using AI/ML
4. **Consider operations practices** for deployment and monitoring

## Maintenance

This cross-reference should be updated when:

- New base rules are added
- New language support is added
- New framework best practices are created
- New cloud providers are documented
- Practices are reorganized or renamed

## Related Resources

- `ARCHITECTURE.md` - Repository organization
- `README.md` - Getting started guide
- `IMPLEMENTATION_GUIDE.md` - Rollout strategy
- `base/project-maturity-levels.md` - Progressive rigor framework
