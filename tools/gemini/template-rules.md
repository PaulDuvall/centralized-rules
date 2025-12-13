# Gemini Code Assistant - Development Rules

**Project:** {{PROJECT_NAME}}
**Generated:** {{SYNC_TIMESTAMP}}
**Source:** https://github.com/PaulDuvall/centralized-rules
**Maturity Level:** {{MATURITY_LEVEL}}

---

## Project Configuration

**Technologies:**
- **Languages:** {{DETECTED_LANGUAGES}}
- **Frameworks:** {{DETECTED_FRAMEWORKS}}
- **Cloud Providers:** {{DETECTED_CLOUD}}
- **Package Managers:** {{PACKAGE_MANAGERS}}

**Project Type:** {{PROJECT_TYPE}}
**Maturity Level:** {{MATURITY_LEVEL}}

---

## Instructions for Gemini

When generating, reviewing, or refactoring code for this project, follow these guidelines:

### Primary Objectives
1. **Follow Coding Standards:** Apply the language and framework-specific standards defined below
2. **Ensure Security:** Validate inputs, avoid hardcoded secrets, follow security principles
3. **Include Error Handling:** Add appropriate error handling and logging
4. **Generate Tests:** Create test cases for new functionality
5. **Add Documentation:** Include docstrings/comments for complex logic
6. **Apply Maturity Requirements:** Follow {{MATURITY_LEVEL}} level requirements (see sections below)
7. **Maintain Consistency:** Use established patterns and conventions from this codebase

### Code Generation Checklist

Before outputting generated code, verify:
- [ ] Follows project's naming conventions
- [ ] Includes type hints/annotations where applicable
- [ ] Has appropriate error handling
- [ ] Validates external inputs
- [ ] No hardcoded secrets or credentials
- [ ] Includes unit tests (when creating new functions)
- [ ] Has docstrings/comments for complex logic
- [ ] Respects maximum function length ({{MAX_FUNCTION_LINES}} lines)
- [ ] Uses established patterns from framework rules
- [ ] Meets maturity level requirements

---

## Base Development Rules

These rules apply to all code in this project, regardless of language or framework.

### Git Workflow Standards

{{CONTENT:base/git-workflow.md}}

---

### Code Quality Standards

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

### Additional Base Rules

{{ADDITIONAL_BASE_RULES}}

---

## Language-Specific Guidelines

{{LANGUAGE_RULES_SECTIONS}}

---

## Framework-Specific Patterns

{{FRAMEWORK_RULES_SECTIONS}}

---

## Cloud Provider Guidelines

{{CLOUD_RULES_SECTIONS}}

---

## Code Style Preferences

Based on detected configuration files and project conventions:

### Formatting
- **Indentation:** {{INDENT_SIZE}} spaces
- **Max Line Length:** {{MAX_LINE_LENGTH}} characters
- **Quote Style:** {{QUOTE_STYLE}} quotes
- **Trailing Commas:** {{TRAILING_COMMAS}}

### Naming Conventions
- **Variables:** {{VARIABLE_NAMING}} (e.g., `user_id` or `userId`)
- **Functions:** {{FUNCTION_NAMING}} (e.g., `get_user` or `getUser`)
- **Classes:** {{CLASS_NAMING}} (e.g., `UserService` or `user_service`)
- **Constants:** {{CONSTANT_NAMING}} (e.g., `MAX_RETRIES`)

### Documentation Style
- **Docstring Format:** {{DOCSTRING_FORMAT}}
- **Comment Density:** {{COMMENT_DENSITY}}
- **API Documentation:** {{API_DOC_STYLE}}

---

## Maturity Level Requirements

This project is at **{{MATURITY_LEVEL}}** maturity level. Apply these requirements:

### MVP/POC Requirements
**Focus:** Rapid iteration, basic quality gates

**Required:**
- ✅ Basic error handling
- ✅ No hardcoded secrets
- ✅ Standard commit messages
- ✅ Core functionality tests

**Recommended:**
- ⚠️ Type hints/annotations
- ⚠️ Comprehensive test coverage (>60%)
- ⚠️ Code reviews

**Optional:**
- ❌ Full CI/CD pipeline
- ❌ Monitoring and alerting
- ❌ Performance optimization

### Pre-Production Requirements
**Focus:** Stricter standards, comprehensive testing

**Required:**
- ✅ Type hints/annotations
- ✅ Test coverage >70%
- ✅ Error handling and logging
- ✅ Input validation
- ✅ Code reviews (1 approval)
- ✅ CI/CD pipeline
- ✅ Security scanning

**Recommended:**
- ⚠️ Monitoring and alerting
- ⚠️ Performance testing
- ⚠️ Comprehensive documentation

**Optional:**
- ❌ Advanced optimization
- ❌ Chaos engineering

### Production Requirements
**Focus:** Full compliance, extensive testing, reliability

**Required:**
- ✅ Strict type checking
- ✅ Test coverage >80%
- ✅ Comprehensive error handling
- ✅ Input validation and sanitization
- ✅ Code reviews (2 approvals)
- ✅ Full CI/CD with staging
- ✅ Security scanning (SAST, DAST, dependency)
- ✅ Monitoring and alerting
- ✅ Performance testing
- ✅ Comprehensive documentation
- ✅ Incident response procedures

**Recommended:**
- ⚠️ Chaos engineering
- ⚠️ Advanced performance optimization
- ⚠️ A/B testing framework

---

## Anti-Patterns to Avoid

When generating code, **DO NOT** create these anti-patterns:

### Code Quality Anti-Patterns
1. **God Object:** Large classes that do too many things
2. **Magic Numbers:** Unexplained literal values (use named constants)
3. **Copy-Paste Programming:** Duplicated code instead of reusable functions
4. **Primitive Obsession:** Using primitives instead of domain objects
5. **Long Functions:** Functions exceeding {{MAX_FUNCTION_LINES}} lines

### Security Anti-Patterns
6. **Hardcoded Secrets:** API keys, passwords, tokens in code
7. **SQL Injection:** Direct string concatenation in queries
8. **Missing Input Validation:** Trusting external input without validation
9. **Weak Cryptography:** Using deprecated or weak algorithms
10. **Exposed Sensitive Data:** Logging or returning sensitive information

### Testing Anti-Patterns
11. **Testing Implementation Details:** Tests that break on refactoring
12. **Test Interdependence:** Tests that depend on execution order
13. **Insufficient Coverage:** Critical paths without tests
14. **No Edge Case Testing:** Only testing happy path

### Architecture Anti-Patterns
15. **Big Ball of Mud:** No clear architecture or separation
16. **Monolithic Database:** Single database for all concerns
17. **Vendor Lock-In:** Tight coupling to specific vendors

### AI Development Anti-Patterns
18. **Context Overload:** Loading all rules for every task
19. **Blind AI Acceptance:** Using generated code without review
20. **No Context Management:** Ignoring project-specific context

See [ANTI_PATTERNS.md](https://github.com/PaulDuvall/centralized-rules/blob/main/ANTI_PATTERNS.md) for complete descriptions and solutions.

---

## Common Code Patterns

### Error Handling Pattern

When generating error handling code, follow this pattern:

{{ERROR_HANDLING_EXAMPLE}}

### Logging Pattern

When adding logging, use this pattern:

{{LOGGING_EXAMPLE}}

### Testing Pattern

When generating tests, use this pattern:

{{TESTING_EXAMPLE}}

### API Endpoint Pattern

When creating API endpoints, follow this pattern:

{{API_ENDPOINT_EXAMPLE}}

---

## Task-Specific Guidance

### When Creating New Features
1. Read relevant existing code to understand patterns
2. Create function/class structure following naming conventions
3. Implement core logic with error handling
4. Add input validation for external inputs
5. Include logging for key operations
6. Generate unit tests covering happy path and edge cases
7. Add docstrings/comments for complex logic
8. Ensure maturity level requirements are met

### When Refactoring Code
1. Identify code smells and anti-patterns
2. Ensure tests exist before refactoring (write them if not)
3. Make incremental, focused changes
4. Run tests after each change
5. Maintain backward compatibility (or document breaking changes)
6. Update documentation to reflect changes
7. Add comments explaining complex refactorings

### When Fixing Bugs
1. Understand the root cause
2. Write a failing test that reproduces the bug
3. Implement the minimal fix
4. Verify the test now passes
5. Check for similar bugs elsewhere
6. Add logging to prevent future occurrences
7. Document the fix in commit message

### When Writing Tests
1. Follow the project's testing framework conventions
2. Use descriptive test names (test_should_do_x_when_y)
3. Arrange-Act-Assert pattern
4. Test one thing per test
5. Include edge cases and error conditions
6. Mock external dependencies
7. Aim for {{MIN_COVERAGE}}% coverage

---

## Multimodal Capabilities

As Gemini supports multimodal inputs, you can:

### Image-to-Code
- Convert UI mockups to frontend components
- Generate code from architecture diagrams
- Create data models from ER diagrams

### Code Explanation
- Provide natural language explanations of complex algorithms
- Generate documentation from code
- Create tutorials from implementation

### Code Review
- Analyze code for anti-patterns
- Suggest refactorings with visual diagrams
- Compare implementations side-by-side

---

## Updating These Rules

To update these rules to the latest version:

```bash
./sync-ai-rules.sh --tool gemini
```

This will refresh:
- `.gemini/rules.md` (this file)
- `.gemini/context.json` (project metadata)

To customize which rules are loaded, create `.ai/sync-config.json`:

```json
{
  "languages": ["python"],
  "frameworks": ["fastapi"],
  "cloud_providers": ["vercel"],
  "exclude": ["testing-mocking"]
}
```

---

## Support & Resources

- **Centralized Rules Repository:** https://github.com/PaulDuvall/centralized-rules
- **Architecture Documentation:** [ARCHITECTURE.md](https://github.com/PaulDuvall/centralized-rules/blob/main/ARCHITECTURE.md)
- **Practice Cross-Reference:** [PRACTICE_CROSSREFERENCE.md](https://github.com/PaulDuvall/centralized-rules/blob/main/PRACTICE_CROSSREFERENCE.md)
- **Anti-Patterns Guide:** [ANTI_PATTERNS.md](https://github.com/PaulDuvall/centralized-rules/blob/main/ANTI_PATTERNS.md)
- **Implementation Guide:** [IMPLEMENTATION_GUIDE.md](https://github.com/PaulDuvall/centralized-rules/blob/main/IMPLEMENTATION_GUIDE.md)
- **Success Metrics:** [SUCCESS_METRICS.md](https://github.com/PaulDuvall/centralized-rules/blob/main/SUCCESS_METRICS.md)

---

**Gemini Integration Notes:**
- This file is optimized for Gemini's instruction-following capabilities
- Use `context.json` for structured project metadata
- Future versions will support hierarchical rule loading
- For custom integrations, see `tools/gemini/examples/` in the repository

---

*Generated by centralized-rules sync script*
*Version: {{RULES_VERSION}}*
*For issues or suggestions: https://github.com/PaulDuvall/centralized-rules/issues*
