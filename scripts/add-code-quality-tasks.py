#!/usr/bin/env python3
"""
Add code quality improvement tasks to Beads.
Focus on cyclomatic complexity, code smells, modularity, and maintainability.
"""
import json
from datetime import datetime, timezone

def create_timestamp():
    return datetime.now(timezone.utc).isoformat()

tasks = [
    {
        'id': 'CR-QA-001',
        'title': 'Measure and reduce cyclomatic complexity across codebase',
        'description': '''**Priority:** HIGH
**Scope:** Identify functions/methods with high cyclomatic complexity and refactor
**Impact:** Improve maintainability, testability, and reduce bug risk

## Issue
No automated cyclomatic complexity measurement in place. Complex functions are harder to test, understand, and maintain.

## Target Metrics
- Functions: Complexity ≤ 10 (from base/code-quality.md)
- Methods: Complexity ≤ 10
- Classes: Complexity ≤ 50

## Steps to Implement
1. Add complexity analysis tools to project
   - TypeScript/JavaScript: eslint-plugin-complexity
   - Python: radon or mccabe
   - Shell: Use shellcheck complexity warnings
2. Run baseline complexity analysis across codebase
3. Identify top 10 most complex functions (complexity > 15)
4. Create refactoring tasks for high-complexity code
5. Add complexity checks to CI/CD pipeline
6. Configure complexity thresholds in linting configs

## Example High-Risk Areas
- skill/src/tools/select-rules.ts (analyzeIntent, scoreRule functions)
- scripts/audit-agent/rules_parser.py (parse functions)
- sync-ai-rules.sh (main sync logic)

## Acceptance Criteria
- WHEN analyzing codebase, THEN identify all functions with complexity > 10
- WHEN refactoring complete, THEN 95% of functions have complexity ≤ 10
- WHEN CI runs, THEN fail builds with complexity > 15
- WHEN baseline established, THEN track complexity trends over time''',
        'status': 'open',
        'priority': 1,
        'issue_type': 'task',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },
    {
        'id': 'CR-QA-002',
        'title': 'Detect and refactor code smells using automated analysis',
        'description': '''**Priority:** HIGH
**Scope:** Identify and fix common code smells (long methods, large classes, duplicate code)
**Impact:** Improve code readability and maintainability

## Common Code Smells to Detect
1. **Long Methods** - Functions > 25 lines
2. **Large Classes** - Classes > 300 lines
3. **Duplicate Code** - Copy-paste detection
4. **Dead Code** - Unused functions/variables/imports
5. **Magic Numbers** - Hardcoded values without constants
6. **Long Parameter Lists** - Functions with > 4 parameters
7. **Feature Envy** - Methods using other classes more than their own

## Tools to Use
- **TypeScript/JavaScript:** SonarQube, ESLint with code smell rules
- **Python:** Pylint, flake8, bandit
- **Shell:** ShellCheck (already in use)

## Steps to Implement
1. Set up SonarQube or similar static analysis tool
2. Run initial code smell detection scan
3. Generate prioritized list of smells (by severity/frequency)
4. Create refactoring plan for top 20 smells
5. Fix code smells iteratively (one type at a time)
6. Add code smell checks to CI/CD pipeline
7. Establish code smell budget (max allowed per PR)

## Example Smells to Fix
- Long functions in sync-ai-rules.sh (main sync logic)
- Duplicate error handling patterns across codebase
- Magic strings in configuration files
- Unused imports/functions after refactoring

## Acceptance Criteria
- WHEN scanning codebase, THEN identify all major code smells
- WHEN refactoring, THEN reduce code smells by 80%
- WHEN PR created, THEN block if introducing new critical smells
- WHEN analysis complete, THEN generate smell trend report''',
        'status': 'open',
        'priority': 1,
        'issue_type': 'task',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },
    {
        'id': 'CR-QA-003',
        'title': 'Improve modularity by breaking up large files and functions',
        'description': '''**Priority:** MEDIUM
**Scope:** Split large files (>500 lines) and long functions (>25 lines) into focused modules
**Impact:** Improve code organization, readability, and reusability

## Current Issues
- Large files mixing multiple responsibilities
- Long functions doing too many things
- Poor separation of concerns
- Difficult to locate specific functionality

## Target Metrics (from base/code-quality.md)
- Functions: ≤ 20-25 lines
- Files: ≤ 300-500 lines
- Single Responsibility Principle: One reason to change

## Steps to Implement
1. Identify files > 500 lines across codebase
2. Identify functions > 25 lines
3. Analyze responsibilities and group related code
4. Extract logical modules/utilities
5. Apply Extract Function refactoring pattern
6. Apply Extract Module refactoring pattern
7. Update imports and references
8. Verify tests still pass after refactoring

## Candidate Files for Refactoring
- skill/src/tools/select-rules.ts (if large)
- scripts/audit-agent/audit_agent.py (if large)
- sync-ai-rules.sh (400+ lines, consider extracting functions)

## Refactoring Patterns to Apply
1. **Extract Function** - Break large functions into smaller ones
2. **Extract Constant** - Replace magic numbers/strings
3. **Extract Module** - Split files by responsibility
4. **Introduce Parameter Object** - Replace long parameter lists

## Acceptance Criteria
- WHEN analyzing files, THEN identify all files > 500 lines
- WHEN analyzing functions, THEN identify all functions > 25 lines
- WHEN refactoring complete, THEN 90% of files ≤ 500 lines
- WHEN refactoring complete, THEN 90% of functions ≤ 25 lines
- WHEN tests run, THEN all tests still pass''',
        'status': 'open',
        'priority': 2,
        'issue_type': 'task',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },
    {
        'id': 'CR-QA-004',
        'title': 'Detect and eliminate code duplication',
        'description': '''**Priority:** MEDIUM
**Scope:** Find and remove duplicate code blocks using DRY principle
**Impact:** Reduce maintenance burden and inconsistencies

## Issue
Duplicate code leads to:
- Inconsistent bug fixes (fixed in one place, not others)
- Increased maintenance effort (change in multiple places)
- Larger codebase size
- Higher risk of introducing bugs

## Tools to Use
- **JavaScript/TypeScript:** jscpd (copy-paste detector)
- **Python:** PMD CPD or duppy
- **Multi-language:** SonarQube duplication detection

## Thresholds
- Block duplication: ≥ 6 lines
- Token duplication: ≥ 50 tokens
- Maximum duplication: ≤ 3% of codebase

## Steps to Implement
1. Install and configure copy-paste detection tools
2. Run baseline duplication scan
3. Categorize duplications by severity (tokens/lines)
4. Identify top 10 most duplicated code blocks
5. Extract common logic into shared utilities
6. Apply DRY refactoring patterns
7. Add duplication checks to CI/CD
8. Set duplication budget for PRs

## Common Duplication Patterns to Fix
- Error handling boilerplate
- Logging patterns
- Configuration loading
- File I/O operations
- Input validation

## Acceptance Criteria
- WHEN scanning codebase, THEN detect all duplications ≥ 6 lines
- WHEN refactoring, THEN reduce duplication to ≤ 3% of codebase
- WHEN PR created, THEN warn if adding significant duplication
- WHEN duplicates found, THEN extract to shared utilities''',
        'status': 'open',
        'priority': 2,
        'issue_type': 'task',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },
    {
        'id': 'CR-QA-005',
        'title': 'Remove dead code and unused dependencies',
        'description': '''**Priority:** MEDIUM
**Scope:** Identify and remove unused code, imports, variables, and dependencies
**Impact:** Reduce codebase size, improve clarity, reduce attack surface

## Dead Code Categories
1. **Unused Functions** - Functions never called
2. **Unused Variables** - Variables declared but never used
3. **Unused Imports** - Import statements for unused modules
4. **Unused Dependencies** - package.json/requirements.txt unused deps
5. **Commented Code** - Old code left in comments
6. **Unreachable Code** - Code after returns/breaks

## Tools to Use
- **TypeScript/JavaScript:** ts-unused-exports, depcheck
- **Python:** vulture, autoflake
- **Dependencies:** npm-check-unused, pip-autoremove

## Steps to Implement
1. Run unused code detection across codebase
2. Run unused dependency detection
3. Review commented-out code (git history vs keep)
4. Create prioritized removal list (by impact/risk)
5. Remove dead code incrementally with tests
6. Remove unused dependencies
7. Add unused code checks to CI/CD
8. Configure linters to catch new dead code

## Safety Measures
- Verify through tests that code is truly unused
- Check git history before removing commented code
- Keep deprecation notices for public APIs
- Document removal decisions in commit messages

## Acceptance Criteria
- WHEN scanning codebase, THEN identify all unused code
- WHEN removing code, THEN verify with test suite
- WHEN analyzing dependencies, THEN remove all unused packages
- WHEN CI runs, THEN warn about new unused code
- WHEN cleanup complete, THEN 0% dead code remains''',
        'status': 'open',
        'priority': 2,
        'issue_type': 'task',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },
    {
        'id': 'CR-QA-006',
        'title': 'Standardize error handling patterns across codebase',
        'description': '''**Priority:** MEDIUM
**Scope:** Create consistent error handling strategy with custom error types
**Impact:** Improve debugging, error recovery, and user experience

## Current Issues
- Inconsistent error handling patterns
- Generic error messages without context
- Missing error handling in some code paths
- Difficult to trace error origins

## Error Handling Standards (from base/code-quality.md)
1. **All functions that can fail must have error handling**
2. **Catch specific exceptions** (avoid catch-all handlers)
3. **Provide descriptive, actionable error messages**
4. **Include remediation guidance in errors**
5. **Log errors with context**

## Steps to Implement
1. Define custom error types/classes for domain errors
   - ValidationError
   - ConfigurationError
   - NetworkError
   - GitHubApiError (already exists in skill/)
2. Create error handling utilities
   - Error logger with structured context
   - Error formatter for user messages
   - Error recovery strategies
3. Audit existing error handling patterns
4. Refactor to use consistent error types
5. Add error context (file, line, operation)
6. Implement error boundary patterns
7. Add error handling tests

## Example Error Types Needed
```typescript
class ValidationError extends Error {
  constructor(message: string, field: string, context?: object)
}

class ConfigurationError extends Error {
  constructor(message: string, configPath: string, hint?: string)
}
```

## Acceptance Criteria
- WHEN error occurs, THEN use specific error type
- WHEN catching errors, THEN catch specific types (not generic)
- WHEN reporting error, THEN include actionable message
- WHEN logging error, THEN include context (file, line, operation)
- WHEN auditing code, THEN 100% of fallible functions have error handling''',
        'status': 'open',
        'priority': 2,
        'issue_type': 'task',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },
    {
        'id': 'CR-QA-007',
        'title': 'Improve naming conventions and code clarity',
        'description': '''**Priority:** LOW
**Scope:** Audit and improve variable, function, and class names for clarity
**Impact:** Improve code readability and self-documentation

## Naming Standards (from base/code-quality.md)
1. **Use meaningful, descriptive names**
2. **Follow language-specific conventions**
3. **Functions use verb phrases** (getUser, calculateTotal)
4. **Booleans use is/has/should prefixes** (isValid, hasPermission)
5. **Constants clearly identifiable** (UPPER_SNAKE_CASE)

## Common Naming Issues
- Single-letter variables (except loop counters)
- Abbreviations without context (ctx, cfg, tmp)
- Generic names (data, info, temp, result)
- Misleading names (doesn't match behavior)
- Inconsistent naming patterns

## Steps to Implement
1. Audit variable names across codebase
2. Identify unclear or misleading names
3. Create renaming plan (symbol rename with IDE)
4. Apply systematic renames (batch by file/module)
5. Update documentation to match renames
6. Configure linters for naming conventions
7. Add naming rules to code review checklist

## Example Improvements
```typescript
// Before
function proc(d: any) { ... }
let cfg = loadCfg();

// After
function processUserData(userData: UserData) { ... }
let ruleConfiguration = loadRuleConfiguration();
```

## Acceptance Criteria
- WHEN auditing names, THEN identify all unclear names
- WHEN renaming, THEN use IDE symbol rename (not find-replace)
- WHEN naming booleans, THEN use is/has/should prefix
- WHEN naming functions, THEN use verb phrases
- WHEN tests run, THEN all tests pass after renames''',
        'status': 'open',
        'priority': 3,
        'issue_type': 'task',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },
    {
        'id': 'CR-QA-008',
        'title': 'Add code quality metrics dashboard and tracking',
        'description': '''**Priority:** MEDIUM
**Scope:** Create dashboard to track code quality metrics over time
**Impact:** Visibility into code quality trends and regression prevention

## Metrics to Track (from base/code-quality.md)
1. **Cyclomatic Complexity** - Average and max per function
2. **Code Duplication** - Percentage of duplicated code
3. **Code Smells** - Count by severity
4. **Maintainability Index** - Composite score (0-100)
5. **Technical Debt Ratio** - Estimated hours to fix / development hours
6. **Lines of Code** - Total and per file
7. **Function Length** - Distribution and violations
8. **File Length** - Distribution and violations

## Dashboard Features
- Historical trend charts
- Quality gates (pass/fail thresholds)
- Hotspot visualization (worst files/functions)
- Technical debt heatmap
- Quality score per module/component
- Regression detection alerts

## Tools to Use
- **SonarQube** - Comprehensive quality platform
- **Code Climate** - Maintainability and complexity
- **CodeScene** - Behavioral code analysis
- **Custom scripts** - Project-specific metrics

## Steps to Implement
1. Set up SonarQube or Code Climate
2. Configure quality gates and thresholds
3. Integrate with CI/CD pipeline
4. Create custom metrics collection scripts
5. Build visualization dashboard (Grafana or built-in)
6. Set up automated quality reports
7. Configure alerts for quality regressions

## Quality Gate Thresholds
- Maintainability Rating: A or B
- Reliability Rating: A
- Security Rating: A
- Coverage: ≥ 80%
- Duplications: ≤ 3%
- Code Smells: ≤ 10 per 1000 LOC

## Acceptance Criteria
- WHEN dashboard loads, THEN show all quality metrics
- WHEN quality decreases, THEN alert team
- WHEN PR created, THEN show quality impact
- WHEN tracking over time, THEN visualize trends
- WHEN quality gate fails, THEN block merge''',
        'status': 'open',
        'priority': 2,
        'issue_type': 'task',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },
    {
        'id': 'CR-QA-009',
        'title': 'Add pre-commit hooks for code quality enforcement',
        'description': '''**Priority:** MEDIUM
**Scope:** Configure pre-commit hooks to enforce quality standards before commit
**Impact:** Prevent low-quality code from entering repository

## Quality Checks to Enforce
1. **Linting** - ESLint, Pylint, ShellCheck
2. **Formatting** - Prettier, Black, shfmt
3. **Type Checking** - TypeScript strict mode, mypy
4. **Complexity** - Reject functions with complexity > 15
5. **Duplication** - Warn on copy-paste violations
6. **Code Smells** - Block critical smells
7. **Dead Code** - Warn on unused code

## Implementation Strategy
- Use **pre-commit** framework (supports multiple languages)
- Or **Husky** for Node.js projects
- Configure git hooks in .git/hooks/
- Share configuration in repository

## Steps to Implement
1. Install pre-commit framework
2. Create .pre-commit-config.yaml with hooks
3. Configure linters for all languages
4. Add auto-formatters
5. Configure type checkers
6. Add complexity checks
7. Test hooks on existing codebase
8. Document hook setup in CONTRIBUTING.md
9. Add hook installation to developer setup

## Example Configuration
```yaml
repos:
  - repo: local
    hooks:
      - id: eslint
        name: ESLint
        entry: npm run lint
        language: system
        files: \\.ts$

      - id: prettier
        name: Prettier
        entry: npm run format:check
        language: system
        files: \\.(ts|js|json|md)$

      - id: pylint
        name: Pylint
        entry: pylint
        language: system
        files: \\.py$

      - id: shellcheck
        name: ShellCheck
        entry: shellcheck
        language: system
        files: \\.sh$
```

## Acceptance Criteria
- WHEN committing code, THEN run all quality checks
- WHEN quality checks fail, THEN prevent commit
- WHEN installing repo, THEN hooks auto-installed
- WHEN hooks run, THEN complete in < 10 seconds
- WHEN bypassing needed, THEN support --no-verify flag''',
        'status': 'open',
        'priority': 2,
        'issue_type': 'task',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },
    {
        'id': 'CR-QA-010',
        'title': 'Create code quality documentation and guidelines',
        'description': '''**Priority:** LOW
**Scope:** Document code quality standards, refactoring patterns, and best practices
**Impact:** Align team on quality expectations and provide refactoring guidance

## Documentation to Create
1. **Code Quality Standards** - Expand base/code-quality.md
   - Language-specific guidelines
   - Tooling setup instructions
   - Quality metrics definitions

2. **Refactoring Guide** - Expand base/refactoring-patterns.md
   - Common code smells and fixes
   - Refactoring patterns catalog
   - Safe refactoring procedures
   - Testing during refactoring

3. **Code Review Checklist**
   - Quality criteria for reviewers
   - Common issues to look for
   - When to request changes

4. **Contributing Guide**
   - How to set up quality tools
   - How to run quality checks locally
   - How to fix common quality issues

## Refactoring Patterns to Document
From Martin Fowler's Refactoring Catalog:
- Extract Function
- Extract Variable
- Extract Constant
- Inline Function
- Rename Variable
- Introduce Parameter Object
- Replace Magic Number with Symbolic Constant
- Decompose Conditional
- Consolidate Duplicate Conditional Fragments

## Steps to Implement
1. Expand base/code-quality.md with detailed standards
2. Create refactoring pattern examples for each language
3. Document tool setup (ESLint, Prettier, SonarQube)
4. Create code review checklist template
5. Add quality section to CONTRIBUTING.md
6. Create troubleshooting guide for common quality issues
7. Add examples of good vs bad code

## Acceptance Criteria
- WHEN developer onboards, THEN understand quality standards
- WHEN refactoring code, THEN find pattern examples
- WHEN reviewing code, THEN use checklist
- WHEN quality issue found, THEN find fix in docs
- WHEN setting up project, THEN follow tool setup guide''',
        'status': 'open',
        'priority': 3,
        'issue_type': 'documentation',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    }
]

# Append tasks to issues.jsonl
with open('.beads/issues.jsonl', 'a') as f:
    for task in tasks:
        f.write(json.dumps(task) + '\n')

print(f'✅ Created {len(tasks)} new Code Quality BEADS tasks')
print(f'\n📊 Code Quality Coverage Improvement:')
print(f'  Current: 50%')
print(f'  Target: 100%')
print(f'  New tasks: {len(tasks)}\n')

print('Tasks created:')
for i, task in enumerate(tasks, 1):
    priority_label = {1: 'HIGH', 2: 'MED', 3: 'LOW'}
    print(f"  {i:2d}. [{priority_label[task['priority']]}] {task['title']}")

print('\n🎯 Focus Areas:')
print('  1. Cyclomatic Complexity - Measure and reduce')
print('  2. Code Smells - Detect and refactor')
print('  3. Modularity - Break up large files/functions')
print('  4. Duplication - DRY principle enforcement')
print('  5. Dead Code - Remove unused code')
print('  6. Error Handling - Standardize patterns')
print('  7. Naming - Improve clarity')
print('  8. Metrics - Track quality over time')
print('  9. Pre-commit Hooks - Enforce standards')
print('  10. Documentation - Guidelines and patterns')
