# Pre-Commit Quality Gates

## Overview

The centralized-rules hook automatically detects git operations (commits, pushes, PRs) and enforces pre-commit quality gates to ensure code quality before changes are committed.

## How It Works

### Detection Mechanisms

The hook detects git operations through **two methods**:

#### 1. Regular Keywords
When your prompt contains git-related words:
- `commit`
- `push`
- `pull request` / `pr`
- `merge`
- `branch`
- `rebase`
- `cherry-pick`
- `git add`

**Example prompts:**
```
"commit these changes"
"push to remote"
"create a pull request"
"merge this branch"
```

#### 2. Slash Commands
When you invoke git-related skills via slash commands:
- `/xgit`
- `/git`
- `/xcommit`
- `/commit`
- `/push`

**Example prompts:**
```
"/xgit"
"/commit all changes"
"/push to origin"
```

## Quality Gates Triggered

When a git operation is detected, the following pre-commit checks are **automatically enforced**:

### Required Checks (in order):

1. **Run Tests**
   - Execute all unit tests
   - Ensure 100% pass rate
   - Block commit if any test fails

2. **Security Scan**
   - Check for vulnerabilities
   - Scan for secrets/credentials
   - Verify secure coding practices

3. **Code Quality**
   - Run linters (ESLint, Pylint, etc.)
   - Check code complexity
   - Verify code standards compliance

4. **Refactoring Check**
   - Detect code smells
   - Check for anti-patterns
   - Identify improvement opportunities

## Workflow

When you trigger a git operation, Claude will:

1. **Announce** the pre-commit checks
   ```
   Running pre-commit checks...
   ```

2. **Execute each check** in order
   ```
   ✓ Tests: 45 passed, 0 failed
   ✓ Security: No vulnerabilities found
   ✓ Code Quality: All checks passed
   ✓ Refactoring: No code smells detected
   ```

3. **Report results**
   - Show summary of all checks
   - Highlight any failures
   - Provide actionable feedback

4. **Proceed or block**
   - ✅ If all checks pass → proceed with commit/push
   - ❌ If any check fails → block commit, show errors, request fixes

## Example Session

### Scenario 1: Using Keywords

```bash
User: "commit these changes to fix the login bug"

Claude:
🚦 PRE-COMMIT QUALITY GATES DETECTED
───────────────────────────────────
Running pre-commit checks...

1️⃣ Running tests...
   ✓ 45 tests passed

2️⃣ Security scan...
   ✓ No vulnerabilities found

3️⃣ Code quality check...
   ✓ ESLint: 0 errors
   ✓ TypeScript: No type errors

4️⃣ Refactoring check...
   ✓ No code smells detected

All checks passed! ✅
Proceeding with commit...
```

### Scenario 2: Using Slash Commands

```bash
User: "/xgit"

Claude:
🚦 PRE-COMMIT QUALITY GATES DETECTED
───────────────────────────────────
Running pre-commit checks...

[Same workflow as above]
```

### Scenario 3: Check Failure

```bash
User: "commit my changes"

Claude:
🚦 PRE-COMMIT QUALITY GATES DETECTED
───────────────────────────────────
Running pre-commit checks...

1️⃣ Running tests...
   ❌ 3 tests failed:
      - test_authentication.py::test_login_validation
      - test_authentication.py::test_logout_flow
      - test_api.py::test_rate_limiting

⚠️ COMMIT BLOCKED
Cannot proceed with commit due to failing tests.
Please fix the failing tests and try again.
```

## Configuration

### Customizing Checks

You can customize which checks run by modifying the hook script:

**Location:** `.claude/hooks/activate-rules.sh`

**Section:** `generate_activation_instruction()` function

**Example - Add additional check:**

```bash
REQUIRED CHECKS (run in this order):
  1️⃣  Run tests        - Ensure all tests pass
  2️⃣  Security scan    - Check for vulnerabilities
  3️⃣  Code quality     - Verify code meets standards
  4️⃣  Refactoring      - Check for code smells
  5️⃣  Performance      - Run performance benchmarks  # NEW
```

### Disabling Quality Gates

To temporarily disable quality gates, you can:

1. **Skip the hook entirely:**
   ```bash
   # Remove or rename the hook
   mv .claude/hooks/activate-rules.sh .claude/hooks/activate-rules.sh.disabled
   ```

2. **Modify detection logic:**
   Comment out the `is_git_operation` check in `activate-rules.sh`

## Testing

### Run Tests

```bash
# Test slash command detection
./tests/test-slash-command-detection.sh

# Test pre-commit quality gates
./tests/test-precommit-gates.sh
```

### Expected Results

- **16 slash command tests** should pass
- **17 quality gate tests** should pass

## Integration with Other Tools

### Works With

- ✅ `/xgit` skill (external)
- ✅ `/xtest` skill (if available)
- ✅ `/xsecurity` skill (if available)
- ✅ `/xquality` skill (if available)
- ✅ Traditional git commands
- ✅ GitHub CLI (`gh pr create`)

### Does NOT Interfere With

- ❌ Non-git operations (feature implementation, bug fixes, refactoring)
- ❌ Research/exploration tasks
- ❌ Documentation updates (unless committing)

## Benefits

1. **Consistency**
   - Same quality gates apply regardless of invocation method
   - Keywords and slash commands trigger identical checks

2. **Safety**
   - Prevents committing broken code
   - Catches security vulnerabilities early
   - Enforces code quality standards

3. **Transparency**
   - User always knows what checks will run
   - Clear feedback on pass/fail status
   - Actionable error messages

4. **Flexibility**
   - Works with any git workflow
   - Compatible with external skills
   - Customizable check list

## Troubleshooting

### Quality Gates Not Triggering

**Problem:** You type "commit changes" but don't see the quality gates banner

**Solutions:**
1. Verify hook is installed: `ls -la .claude/hooks/activate-rules.sh`
2. Check hook is executable: `chmod +x .claude/hooks/activate-rules.sh`
3. Verify hook is configured in `.claude/settings.json`
4. Run test: `echo '{"prompt":"commit"}' | .claude/hooks/activate-rules.sh`

### Tests Failing

**Problem:** Pre-commit quality gate tests fail

**Solutions:**
1. Check hook syntax: `bash -n .claude/hooks/activate-rules.sh`
2. Verify regex patterns: Test individual prompts manually
3. Review test output for specific failures
4. Check for jq installation: `which jq`

### False Positives

**Problem:** Quality gates trigger when they shouldn't

**Solutions:**
1. Review keyword list in `is_git_operation()` function
2. Make regex patterns more specific
3. Add negative patterns to exclude certain cases
4. Adjust detection logic in `activate-rules.sh`

## Related Documentation

- [Git Workflow Rules](../base/git-workflow.md)
- [Testing Philosophy](../base/testing-philosophy.md)
- [Security Principles](../base/security-principles.md)
- [Code Quality Standards](../base/code-quality.md)
- [Slash Command Detection](./slash-command-detection.md)

## BEADS Task

This feature is tracked in BEADS issue: **centralized-rules-ajq**

View details:
```bash
bd show centralized-rules-ajq
```
