# GitHub Copilot Instructions

This document provides instructions and context for GitHub Copilot when working in this repository.

**Auto-synced from:** https://github.com/PaulDuvall/centralized-rules
**Last synced:** {{SYNC_TIMESTAMP}}

---

## Project Overview

**Project Type:** {{PROJECT_TYPE}}
**Maturity Level:** {{MATURITY_LEVEL}}

**Technologies:**
- **Languages:** {{DETECTED_LANGUAGES}}
- **Frameworks:** {{DETECTED_FRAMEWORKS}}
- **Cloud Providers:** {{DETECTED_CLOUD}}
- **Package Manager:** {{PACKAGE_MANAGER}}

---

## General Principles

When generating code for this project, GitHub Copilot should:

1. **Follow Project Conventions:** Use the coding standards defined in this document
2. **Prioritize Type Safety:** Use type hints/annotations where applicable
3. **Include Error Handling:** Add appropriate try-catch blocks and error messages
4. **Write Tests:** Generate test cases for new functionality
5. **Add Documentation:** Include docstrings/comments for complex logic
6. **Consider Maturity Level:** Apply {{MATURITY_LEVEL}} requirements (see below)
7. **Security First:** Validate inputs, avoid hardcoded secrets, follow security principles

---

## Development Standards

### Git Workflow

{{CONTENT:base/git-workflow.md}}

---

### Code Quality

{{CONTENT:base/code-quality.md}}

---

### Testing Philosophy

{{CONTENT:base/testing-philosophy.md}}

---

### Security Principles

{{CONTENT:base/security-principles.md}}

---

### CI/CD Best Practices

{{CONTENT:base/cicd-comprehensive.md}}

---

### Additional Base Standards

{{ADDITIONAL_BASE_RULES}}

---

## Language-Specific Guidelines

{{LANGUAGE_RULES_SECTIONS}}

---

## Framework Patterns

{{FRAMEWORK_RULES_SECTIONS}}

---

## Cloud Provider Guidelines

{{CLOUD_RULES_SECTIONS}}

---

## Code Generation Preferences

### Naming Conventions

- **Variables:** {{VARIABLE_NAMING}} (e.g., `user_id`, `userId`, `UserID`)
- **Functions:** {{FUNCTION_NAMING}} (e.g., `get_user`, `getUser`, `GetUser`)
- **Classes:** {{CLASS_NAMING}} (e.g., `UserService`, `user_service`)
- **Constants:** {{CONSTANT_NAMING}} (e.g., `MAX_RETRIES`, `MAX_RETRIES`)

### Code Style

- **Indentation:** {{INDENT_SIZE}} spaces
- **Line Length:** Maximum {{MAX_LINE_LENGTH}} characters
- **Quotes:** Prefer {{QUOTE_STYLE}} quotes
- **Trailing Commas:** {{TRAILING_COMMAS}}

### Comment Density

**{{COMMENT_DENSITY}} Comments:**
- Always comment complex algorithms
- Document public APIs
- Explain "why" not "what" for non-obvious code
- Include TODO/FIXME with issue numbers

### Test Generation

When creating a new function, Copilot should:
1. Generate the function implementation
2. Create corresponding test file (if not exists)
3. Add test cases covering:
   - Happy path
   - Edge cases
   - Error conditions
4. Use appropriate mocking for external dependencies

---

## Maturity-Level Requirements

This project is at **{{MATURITY_LEVEL}}** maturity. Apply these requirements:

### MVP/POC Level
- ⚠️ **Recommended but not required:** Type hints, comprehensive tests, full documentation
- ✅ **Required:** Basic error handling, no hardcoded secrets, commit message standards
- ❌ **Optional:** Code reviews, CI/CD, monitoring

### Pre-Production Level
- ✅ **Required:** Type hints, >70% test coverage, error handling, input validation
- ✅ **Required:** Code reviews (1 approval), CI/CD pipeline, security scanning
- ⚠️ **Recommended:** Monitoring, performance testing, documentation

### Production Level
- ✅ **Required:** Strict type checking, >80% test coverage, comprehensive error handling
- ✅ **Required:** Code reviews (2 approvals), full CI/CD, security scanning, monitoring
- ✅ **Required:** Performance testing, comprehensive documentation, incident response

---

## Common Patterns

### Error Handling Pattern

{{ERROR_HANDLING_EXAMPLE}}

### Logging Pattern

{{LOGGING_EXAMPLE}}

### Testing Pattern

{{TESTING_EXAMPLE}}

### API Endpoint Pattern

{{API_ENDPOINT_EXAMPLE}}

---

## Anti-Patterns to Avoid

Copilot should **NOT** generate code with these anti-patterns:

1. **Hardcoded Secrets:** No API keys, passwords, or tokens in code
2. **Magic Numbers:** Use named constants instead of literal values
3. **God Objects:** Keep classes focused and single-purpose
4. **Copy-Paste:** Refactor duplicated code into reusable functions
5. **Primitive Obsession:** Use proper domain objects instead of primitives
6. **Shotgun Surgery:** Changes should be localized, not scattered
7. **Long Functions:** Keep functions under {{MAX_FUNCTION_LINES}} lines
8. **Deep Nesting:** Maximum {{MAX_NESTING_DEPTH}} levels of nesting
9. **SQL Injection:** Always use parameterized queries
10. **Missing Input Validation:** Validate all external inputs

See [ANTI_PATTERNS.md](https://github.com/PaulDuvall/centralized-rules/blob/main/ANTI_PATTERNS.md) for complete list.

---

## Useful Context

### Project Structure

{{PROJECT_STRUCTURE_OVERVIEW}}

### Key Dependencies

{{KEY_DEPENDENCIES}}

### Environment Variables

Common environment variables used in this project:
{{COMMON_ENV_VARS}}

---

## Updating These Instructions

To update these instructions to the latest centralized rules:

```bash
./sync-ai-rules.sh --tool copilot
git add .github/copilot-instructions.md
git commit -m "chore: Update Copilot instructions"
```

To customize which rules are loaded, create `.ai/sync-config.json`:

```json
{
  "languages": ["python"],
  "frameworks": ["fastapi"],
  "exclude": ["testing-mocking"]
}
```

---

## Support & Resources

- **Centralized Rules Repository:** https://github.com/PaulDuvall/centralized-rules
- **Architecture Documentation:** See ARCHITECTURE.md in repository
- **Practice Cross-Reference:** See PRACTICE_CROSSREFERENCE.md
- **Anti-Patterns:** See ANTI_PATTERNS.md
- **Implementation Guide:** See IMPLEMENTATION_GUIDE.md

---

*Generated by centralized-rules sync script*
*For issues or suggestions, visit: https://github.com/PaulDuvall/centralized-rules/issues*
