# Testing Philosophy

> **When to apply:** All testing across any language or framework

## Core Testing Principle

**MANDATORY:** Never proceed to the next task or mark work as complete if tests are failing.

### The Rule:

- All tests must pass before moving forward
- All tests must pass before marking a task complete
- All tests must pass before claiming work is done

### What This Means:

- If you write code and tests fail → Fix the code
- If you refactor and tests fail → Fix the refactoring
- If you add a feature and tests fail → Fix the feature
- **Never** say "done" or "complete" with failing tests

## Testing Philosophy

All code should be thoroughly tested with meaningful coverage.

### What to Test

- **Happy paths** - Normal successful execution
- **Edge cases** - Empty input, null values, boundary conditions
- **Error cases** - Invalid input, exceptions, failures
- **Integration points** - APIs, databases, external services
- **Business logic** - Core functionality and rules
- **Security** - Authentication, authorization, input validation

### Coverage Goals

- **Minimum 80% code coverage** as a baseline
- 100% coverage for critical business logic
- 100% coverage for security-sensitive code
- Lower coverage acceptable for UI rendering/formatting
- Focus on meaningful tests, not just coverage numbers

**Why:** High coverage catches regressions and ensures quality, but 100% everywhere is impractical.

## Test Types

### Unit Tests

- Test individual functions/methods in isolation
- Mock external dependencies
- Fast execution (< 100ms per test)
- Located in dedicated test directories

**When to use:** Testing pure logic, individual functions, data transformations

### Integration Tests

- Test multiple components working together
- May use real dependencies (databases, APIs)
- Slower but more realistic
- Test actual workflows

**When to use:** Testing component interactions, end-to-end flows, real operations

### Property-Based Tests

- Test universal properties across many inputs
- Generate random test data
- Find edge cases automatically
- Useful for testing invariants

**When to use:** Testing mathematical properties, data transformations, validation logic

## Test Structure Pattern

Follow the Arrange-Act-Assert (AAA) pattern:

```
1. Arrange - Set up test data and dependencies
2. Act - Execute the code being tested
3. Assert - Verify the results
```

## Test Naming

- Use descriptive test names
- Include the condition being tested
- Be specific about expected outcome
- Make failures self-explanatory

**Examples:**
- ✅ `test_validation_rejects_empty_input`
- ✅ `test_calculation_handles_negative_numbers`
- ✅ `test_api_returns_404_for_missing_resource`
- ❌ `test_function` (too vague)
- ❌ `test_it_works` (not descriptive)

## Common Test Workflows

### Writing a New Test

1. Identify what to test
2. Choose appropriate test type (unit vs integration)
3. Write test following AAA pattern
4. Run test and verify it fails (if TDD)
5. Implement code
6. Run test and verify it passes
7. Check coverage

### Running Tests

- Run all tests frequently during development
- Run specific tests when debugging
- Run full test suite before committing
- Automate tests in CI/CD pipeline

### Debugging Failing Tests

1. Read the error output carefully
2. Run single failing test in isolation
3. Add debugging output if needed
4. Verify test setup is correct
5. Check that mocks match expectations
6. Fix the root cause, not just the symptom

## Critical Rule: Never Proceed with Failing Tests

**MANDATORY:** You must NEVER move to the next task, mark a task as complete, or claim work is finished if ANY tests are failing.

### Required Actions When Tests Fail:

1. **STOP IMMEDIATELY** - Do not proceed to other tasks
2. **INVESTIGATE** - Read the test failure output carefully
3. **FIX THE ROOT CAUSE** - Don't just make tests pass, fix the actual issue
4. **VERIFY** - Run tests again to confirm they pass
5. **ONLY THEN** - Proceed to the next task

### What Counts as "Failing Tests":

- ❌ Any test with status "failed"
- ❌ Tests that error during execution
- ❌ Tests that timeout
- ❌ Coverage below minimum threshold
- ❌ Build/compilation errors that prevent tests from running

### Acceptable Exceptions:

- ✅ Tests marked as `skip` or `todo` (intentionally not run)
- ✅ Integration tests skipped due to missing dependencies (if documented)
- ✅ Tests that pass with warnings (but still pass)

**Remember:** "Working" means "all tests pass", not "code compiles".

## Test Dependencies and Mocking

### When to Mock

- External API calls
- Database operations (in unit tests)
- File system operations
- Time-dependent operations
- Third-party services
- Expensive operations

### When NOT to Mock

- Code you own (use real implementations in integration tests)
- Simple data structures
- Pure functions with no side effects
- Critical integration points (test with real dependencies)

### Mock Best Practices

- Keep mocks simple and focused
- Mock at appropriate boundaries
- Verify mock interactions when relevant
- Don't over-mock (makes tests brittle)
- Use real implementations for integration tests

## Test Data and Fixtures

### Good Test Data:

- Minimal but realistic
- Clearly shows what is being tested
- Easy to understand and maintain
- Reusable across tests (via fixtures)
- Isolated (tests don't depend on each other)

### Fixture Management:

- Create shared fixtures for common data
- Keep fixtures focused and minimal
- Use factory functions for variations
- Clean up after tests (teardown)

## Test Organization

### Directory Structure

```
src/                    # Source code
tests/                  # All tests
  unit/                 # Unit tests
  integration/          # Integration tests
  fixtures/             # Test data and utilities
  conftest.*            # Shared test configuration
```

### File Naming

- Mirror source code structure
- Use clear test file naming (e.g., `test_*` or `*_test`)
- Group related tests together
- Keep test files focused

## Performance Considerations

- Unit tests should be fast (< 100ms each)
- Integration tests can be slower but should still be reasonable
- Run fast tests frequently, slow tests less often
- Optimize slow tests or mark them appropriately
- Consider parallel test execution for large suites

## Test Maintenance

- Update tests when requirements change
- Remove obsolete tests
- Refactor tests when they become unclear
- Keep tests DRY (but not at expense of clarity)
- Treat test code with same quality standards as production code

## Integration with Development Workflow

1. **Write test** (if doing TDD, write before code)
2. **Implement code**
3. **Run tests** - Must pass
4. **Refactor** - Tests ensure nothing breaks
5. **Commit** - Only commit when tests pass
6. **Complete** - Mark task done only when tests pass

## Why Testing Matters

### Benefits:
- **Confidence** - Know your code works
- **Regression Prevention** - Catch breaks early
- **Documentation** - Tests show how code should be used
- **Design Feedback** - Hard to test = bad design
- **Refactoring Safety** - Change code with confidence
- **Bug Prevention** - Catch issues before production

### Costs of Not Testing:
- **More Bugs** - Issues reach production
- **Fear of Change** - Can't refactor safely
- **Slower Development** - Manual testing is slow
- **Technical Debt** - Untested code is risky to change
- **Production Incidents** - Bugs discovered by users
