# AI Development Assistant

## Progressive Disclosure System

This project uses **centralized development rules** with **two-phase progressive disclosure** to maximize context efficiency.

### Phase 1: Project-Level Detection (Automatic)

The sync script automatically detected this project configuration:

- **Languages:** {{DETECTED_LANGUAGES}}
- **Frameworks:** {{DETECTED_FRAMEWORKS}}
- **Cloud Providers:** {{DETECTED_CLOUD}}
- **Maturity Level:** {{MATURITY_LEVEL}}

Only rules relevant to these technologies are synced to this project.

### Phase 2: Task-Level Loading (On-Demand)

**⚠️ IMPORTANT:** Load only rules relevant to your current task. This maximizes context window efficiency.

## Rule Categories

### Base Rules (`rules/base/`)

Universal best practices - **always relevant** regardless of task:

- `git-workflow.md` - Commit messages, branching, frequency
- `code-quality.md` - Function size, naming, DRY principle
- `testing-philosophy.md` - Coverage, test types, TDD
- `security-principles.md` - Secrets, validation, authentication
- `cicd-comprehensive.md` - CI/CD pipeline best practices
- `architecture-principles.md` - System design, patterns
- `development-workflow.md` - Plan → Implement → Test → Refactor
- `error-handling.md` - Exception handling patterns
- `logging-monitoring.md` - Observability practices
- `documentation.md` - Code comments, README, API docs
- `performance-optimization.md` - Profiling, caching, optimization
- `dependency-management.md` - Version control, security updates
- `database-best-practices.md` - Schema design, queries, migrations
- `api-design-principles.md` - RESTful design, versioning
- `code-review-guidelines.md` - Review process, standards
- `refactoring-guidelines.md` - When and how to refactor
- `project-maturity-levels.md` - MVP/POC, Pre-Production, Production criteria

### Language Rules (`rules/languages/{{language}}/`)

Language-specific patterns for detected languages only.

### Framework Rules (`rules/frameworks/{{framework}}/`)

Framework-specific patterns for detected frameworks only.

### Cloud Rules (`rules/cloud/{{provider}}/`)

Cloud provider-specific patterns for detected providers only.

## Task-Specific Loading Guidelines

**Load ONLY what you need for the current task:**

### Code Review
```
Load:
- rules/base/code-quality.md
- rules/languages/{language}/coding-standards.md
Skip: Testing, git, framework, cloud rules
Savings: ~86% fewer tokens
```

### Writing Tests
```
Load:
- rules/base/testing-philosophy.md
- rules/languages/{language}/testing.md
Skip: Code quality, git, framework, cloud rules
Savings: ~56% fewer tokens
```

### Framework Development
```
Load:
- rules/base/code-quality.md
- rules/languages/{language}/coding-standards.md
- rules/frameworks/{framework}/best-practices.md
Skip: Testing, git, cloud rules
Savings: ~66% fewer tokens
```

### Git Commits
```
Load:
- rules/base/git-workflow.md
Skip: All other rules
Savings: ~90% fewer tokens
```

### Security Review
```
Load:
- rules/base/security-principles.md
- rules/languages/{language}/security.md
Skip: Testing, git, framework, cloud rules
Savings: ~70% fewer tokens
```

## Rule Discovery

Use the rule index to discover available rules:

```bash
cat .claude/rules/index.json
```

This JSON file contains metadata for all available rules including:
- Category (base/language/framework/cloud)
- Description
- When to apply
- Related rules

## Measured Performance

**Real-world validation** with Python + FastAPI project:

| Task Type | Rules Loaded | Token Savings |
|-----------|-------------|---------------|
| Code Review | 2 files | 86.4% |
| Write Tests | 2 files | 55.8% |
| FastAPI Endpoint | 3 files | 65.9% |
| Git Commit | 2 files | 89.6% |
| **Average** | **2.25 files** | **74.4%** |

**Result:** 59% more context available for code analysis!

## Best Practices

1. **Start narrow:** Load only rules for the immediate task
2. **Add as needed:** Load additional rules only if task scope expands
3. **Check index:** Use `rules/index.json` to find relevant rules quickly
4. **Cite rules:** Reference specific rule files when making suggestions
5. **Report issues:** If rules conflict or are unclear, note it in your response

## Maturity-Aware Guidance

Rules include maturity level indicators:

- **MVP/POC:** Rapid iteration, basic quality
- **Pre-Production:** Stricter standards, more testing
- **Production:** Full compliance, comprehensive testing

This project is at **{{MATURITY_LEVEL}}** maturity. Apply requirements accordingly.

## Support

- **Repository:** https://github.com/PaulDuvall/centralized-rules
- **Issues:** https://github.com/PaulDuvall/centralized-rules/issues
- **Documentation:** See `ARCHITECTURE.md` and `README.md` in repository

---

**Progressive Disclosure = Better Context Utilization = Better Code Assistance**
