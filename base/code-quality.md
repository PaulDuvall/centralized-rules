# Code Quality Standards

> **When to apply:** All code across any language or framework

## Maturity Level Indicators

| Practice | MVP/POC | Pre-Production | Production |
|----------|---------|----------------|------------|
| Linting (ESLint, Pylint, etc.) | Recommended | Required | Required |
| Auto-formatting (Prettier, Black) | Recommended | Required | Required |
| Type checking (TypeScript, mypy) | Optional | Recommended | Required |
| Code complexity limits | Optional | Recommended | Required |
| Duplication detection | Optional | Recommended | Required |
| Static analysis (SonarQube) | Not needed | Recommended | Required |
| Pre-commit hooks | Optional | Recommended | Required |

## Core Standards

### Function/Method Length
- Keep functions ≤ 20-25 lines
- Each function does one thing
- Extract complex logic into separate functions

### File Length
- Keep files ≤ 300-500 lines
- Split large files into logical modules

### Type Safety
- Declare explicit types for parameters and return values
- Use type annotations or interfaces
- Leverage language's type system

### Error Handling
- All functions that can fail must handle errors
- Catch specific exceptions (avoid catch-all)
- Provide actionable error messages
- Log errors with context

### Code Duplication (DRY)
- Extract common logic into shared functions
- Use constants instead of magic numbers/strings
- Abstract repeated patterns

### Documentation
- Document all public APIs
- Comment complex logic and edge cases
- Keep documentation current

### Naming Conventions
- Use meaningful, descriptive names
- Functions use verb phrases
- Booleans use `is`, `has`, `should` prefixes
- Follow language-specific conventions

### Single Responsibility
- Each function/class has one reason to change
- Separate concerns clearly
- Avoid "god objects"

### Remove Unused Code
- Delete unused imports, variables, dead code paths
- Remove commented-out code

### Security
- Never hardcode secrets
- Validate and sanitize all user input
- Use parameterized queries
- Implement proper authentication/authorization
- Follow principle of least privilege

## Code Review Checklist

- [ ] Functions appropriately sized
- [ ] No duplicated code
- [ ] Proper error handling
- [ ] Clear, descriptive names
- [ ] Documentation complete
- [ ] Tests pass
- [ ] No security issues
- [ ] No unused code
- [ ] Follows language conventions
- [ ] Type safety enforced

## Refactoring Triggers

**Refactor immediately if:**
- Function/file exceeds size limits
- Duplicated code exists
- Missing error handling or documentation
- Unclear naming

## Quality Metrics

- **Test Coverage:** 80%+
- **Cyclomatic Complexity:** < 10
- **Duplication:** Minimal
- **Documentation:** All public APIs
- **Type Coverage:** Strong typing throughout

## Development Workflow

1. Implement code
2. Write and run tests
3. Refactor to meet standards
4. Verify tests pass
5. Commit with descriptive message
6. Mark task complete
