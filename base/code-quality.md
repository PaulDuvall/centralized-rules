# Code Quality Standards

> **When to apply:** All code across any language or framework

## Maturity Level Indicators

Apply code quality practices based on your project's maturity level:

| Practice | MVP/POC | Pre-Production | Production |
|----------|---------|----------------|------------|
| Linting (ESLint, Pylint, etc.) | ⚠️ Recommended | ✅ Required | ✅ Required |
| Auto-formatting (Prettier, Black) | ⚠️ Recommended | ✅ Required | ✅ Required |
| Type checking (TypeScript, mypy) | ❌ Optional | ⚠️ Recommended | ✅ Required |
| Code complexity limits | ❌ Optional | ⚠️ Recommended | ✅ Required |
| Duplication detection | ❌ Optional | ⚠️ Recommended | ✅ Required |
| Static analysis (SonarQube) | ❌ Not needed | ⚠️ Recommended | ✅ Required |
| Pre-commit hooks | ❌ Optional | ⚠️ Recommended | ✅ Required |

**Legend:**
- ✅ Required - Must implement
- ⚠️ Recommended - Should implement when feasible
- ❌ Optional - Can skip or defer

See `base/project-maturity-levels.md` for detailed maturity framework.

## Core Principles

### 1. Function/Method Length

- **Keep functions short and focused** (typically ≤ 20-25 lines)
- Each function should do one thing well
- Extract complex logic into separate functions
- Use descriptive function names that explain intent

**Why:** Short functions are easier to test, understand, and maintain.

**Example (language-agnostic principle):**
```
❌ Bad: One large function doing everything
process_data(input)
  validate input (10 lines)
  transform data (15 lines)
  save to database (10 lines)
  send notification (10 lines)

✅ Good: Focused functions
process_data(input)
  validate_input(input)
  transform_data(input)
  save_data(data)
  send_notification(data)
```

### 2. File Length

- **Keep files manageable** (typically ≤ 300-500 lines)
- Split large files into logical modules
- Group related functionality together
- Use clear module boundaries

**Why:** Large files are hard to navigate and indicate poor separation of concerns.

### 3. Type Safety

- **Use strong typing wherever possible**
- Declare explicit types for function parameters and return values
- Leverage your language's type system
- Use type annotations or interfaces

**Why:** Types catch bugs early and improve code maintainability and IDE support.

### 4. Error Handling

- **All functions that can fail must have error handling**
- Catch specific exceptions/errors (avoid catch-all handlers)
- Provide descriptive, actionable error messages
- Include remediation guidance in errors
- Log errors with context

**Why:** Proper error handling prevents silent failures and aids debugging.

### 5. Code Duplication (DRY Principle)

- **Don't Repeat Yourself**
- Extract common logic into shared functions
- Use constants instead of magic numbers/strings
- Abstract repeated patterns

**Why:** Duplication leads to maintenance nightmares and inconsistencies.

### 6. Documentation

- Document all public APIs
- Add comments for complex logic
- Document edge cases and assumptions
- Provide examples for complex functions
- Keep documentation up-to-date

**Why:** Good documentation reduces onboarding time and prevents misuse.

### 7. Naming Conventions

- Use meaningful, descriptive names
- Follow language-specific conventions
- Functions should use verb phrases
- Boolean variables should use `is`, `has`, `should` prefixes
- Constants should be clearly identifiable

**Why:** Good names make code self-documenting.

### 8. Single Responsibility Principle

- Each function/class should have one reason to change
- Separate concerns clearly
- Avoid "god objects" that do everything
- Keep interfaces focused

**Why:** Single responsibility makes code easier to test and modify.

### 9. Unused Code

- Remove unused imports/dependencies
- Delete commented-out code
- Eliminate dead code paths
- Remove unused variables

**Why:** Dead code creates confusion and maintenance burden.

### 10. Security Best Practices

- Never hardcode secrets or API keys
- Validate and sanitize all user input
- Use parameterized queries (avoid string concatenation)
- Implement proper authentication/authorization
- Follow principle of least privilege

**Why:** Security should be built in, not bolted on.

## Code Review Checklist

Before marking any task complete, verify:

- [ ] All functions are appropriately sized
- [ ] No duplicated code
- [ ] Proper error handling in place
- [ ] Clear, descriptive names used
- [ ] Documentation added where needed
- [ ] Tests pass
- [ ] No security issues
- [ ] No unused code
- [ ] Follows language conventions
- [ ] Type safety enforced

## Refactoring Workflow

### Always Refactor:

- After completing any task
- Before marking a task as complete
- After adding new functionality
- After fixing bugs
- Before committing code

### Refactor Immediately If:

- Function exceeds size limits
- File exceeds size limits
- You see duplicated code
- Missing error handling
- Missing documentation
- Unclear naming

## Quality Metrics

Track these metrics to maintain quality:

- **Test Coverage:** Aim for 80%+ coverage
- **Code Complexity:** Keep cyclomatic complexity low (< 10)
- **Duplication:** Minimize duplicated code blocks
- **Documentation:** All public APIs documented
- **Type Coverage:** Strong typing throughout

## Common Refactoring Patterns

### Extract Function
Break large functions into smaller, focused ones.

### Extract Constant
Replace magic numbers/strings with named constants.

### Add Error Handling
Wrap risky operations in proper error handling.

### Improve Naming
Rename unclear variables and functions.

### Remove Duplication
Extract common code into shared utilities.

## Integration with Development Workflow

1. **Implement** - Write the code
2. **Test** - Write and run tests
3. **Refactor** - Apply quality standards
4. **Verify** - Run tests again
5. **Commit** - Save with descriptive message
6. **Complete** - Mark task done

## Why Quality Matters

### Benefits:
- Maintainability - Clean code is easier to modify
- Fewer Bugs - Simple code has fewer hiding places for bugs
- Readability - Clear code is self-documenting
- Testability - Small functions are easier to test
- Velocity - Clean code speeds up future development
- Collaboration - Consistent code is easier for teams

### Costs of Poor Quality:
- Technical Debt - Accumulates and slows development
- Slower Development - Messy code takes longer to modify
- More Bugs - Complex code hides bugs
- Frustration - Developers hate working with messy code
- Rewrites - Eventually code becomes unmaintainable
