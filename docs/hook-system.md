# Hook System

Automatic rule loading system for Claude Code. Detects git operations and slash commands, loads relevant coding rules, enforces pre-commit quality gates.

## Components

### 1. UserPromptSubmit Hook

**File:** `.claude/hooks/activate-rules.sh`

Executes on every user prompt. Detects project context and loads relevant rules.

**Detection mechanisms:**

1. **Keywords** - git, commit, test, security, refactor terms
2. **Slash commands** - `/xgit`, `/xtest`, `/xsecurity`, `/xrefactor`

**Actions:**

- Scan project for language markers (`package.json`, `pyproject.toml`, `go.mod`)
- Detect frameworks by parsing dependency files
- Identify cloud providers via configuration files
- Inject 2-3 most relevant rules from centralized repository

### 2. Pre-Commit Quality Gates

When git operations are detected (commit, push, PR), enforce quality checks:

1. **Run tests** - 100% pass rate required
2. **Security scan** - No vulnerabilities
3. **Code quality** - Linting, complexity checks
4. **Refactoring check** - Detect code smells

**Triggers:**

- **Keywords:** commit, push, pull request, pr, merge, branch, rebase
- **Slash commands:** `/xgit`, `/git`, `/xcommit`, `/commit`, `/push`

## Slash Command Detection

### Supported Commands

**Git Operations:**
- `/xgit` - External git skill (commit + push)
- `/git` - Git operations
- `/xcommit` - Commit with checks
- `/commit` - Commit changes
- `/push` - Push to remote

**Testing:**
- `/xtest` - Run test suite
- `/test` - Execute tests
- `/xtdd` - TDD workflow

**Security:**
- `/xsecurity` - Security scan
- `/security` - Security audit
- `/xaudit` - Comprehensive audit

**Code Quality:**
- `/xrefactor` - Refactoring assistant
- `/xquality` - Quality checks
- `/xoptimize` - Performance optimization

### Detection Implementation

**Location:** `.claude/hooks/activate-rules.sh`

```bash
# Git/commit keywords (including slash commands)
if echo "${prompt_lower}" | grep -qE '(commit|pull request|pr|merge|branch|push)'; then
    matched_rules+=("base/git-workflow")
# Detect git-related slash commands (e.g., /xgit, /commit, /xcommit, /git)
elif echo "${prompt_lower}" | grep -qE '/(x?git|x?commit|push)(\s|$)'; then
    matched_rules+=("base/git-workflow")
fi
```

**Regex patterns:**
- `/(x?git|x?commit|push)` - Matches `/git`, `/xgit`, `/commit`, `/xcommit`, `/push`
- `x?` - Optional "x" prefix
- `(\s|$)` - Followed by space or end of string (prevents false matches)

## Quality Gate Workflow

When git operation detected:

1. **Announce checks**
   ```
   Running pre-commit checks...
   ```

2. **Execute in order**
   ```
   ✓ Tests: 45 passed, 0 failed
   ✓ Security: No vulnerabilities found
   ✓ Code Quality: All checks passed
   ✓ Refactoring: No code smells detected
   ```

3. **Report results**
   - Show summary of all checks
   - Highlight failures
   - Provide actionable feedback

4. **Proceed or block**
   - ✅ All checks pass → proceed with commit/push
   - ❌ Any check fails → block commit, show errors

## Examples

### Keyword Trigger

**Input:** `"commit these changes to fix the login bug"`

**Output:**
```
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

### Slash Command Trigger

**Input:** `"/xgit"`

**Behavior:** Same as keyword trigger - loads git workflow rules and enforces quality gates.

### Check Failure

**Input:** `"commit my changes"`

**Output:**
```
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
Fix the failing tests and try again.
```

## Configuration

### Add Custom Slash Commands

Edit `.claude/hooks/activate-rules.sh`:

```bash
# Custom slash command detection
if echo "${prompt_lower}" | grep -qE '/(x?custom|my-command)(\s|$)'; then
    matched_rules+=("custom/my-rules")
fi
```

Update `skill-rules.json` keywords:

```json
{
  "keywordMappings": {
    "base": {
      "custom_category": {
        "keywords": ["custom", "my-command"],
        "slashCommands": ["/custom", "/my-command"],
        "rules": ["base/custom-rules.md"]
      }
    }
  }
}
```

### Disable Quality Gates

Temporarily disable:

```bash
# Rename hook
mv .claude/hooks/activate-rules.sh .claude/hooks/activate-rules.sh.disabled
```

## Testing

Run test suites:

```bash
# Slash command detection
./tests/test-slash-command-detection.sh

# Pre-commit quality gates
./tests/test-precommit-gates.sh
```

**Expected:** 16 slash command tests pass, 17 quality gate tests pass.

### Manual Testing

Test specific prompt:

```bash
echo '{"prompt":"/xgit"}' | .claude/hooks/activate-rules.sh | jq -r '.systemMessage'
```

## Integration

### Compatible Skills

- ✅ `/xgit` skill (external)
- ✅ `/xtest` skill (if available)
- ✅ `/xsecurity` skill (if available)
- ✅ `/xquality` skill (if available)
- ✅ Traditional git commands
- ✅ GitHub CLI (`gh pr create`)

### Non-Interfering Operations

- ❌ Non-git operations (feature implementation, bug fixes, refactoring)
- ❌ Research/exploration tasks
- ❌ Documentation updates (unless committing)

## Troubleshooting

### Quality Gates Not Triggering

**Problem:** Type "commit changes" but no quality gates banner appears.

**Solutions:**
1. Verify hook exists: `ls -la .claude/hooks/activate-rules.sh`
2. Check executable: `chmod +x .claude/hooks/activate-rules.sh`
3. Verify configured in `.claude/settings.json`
4. Test: `echo '{"prompt":"commit"}' | .claude/hooks/activate-rules.sh`

### Tests Failing

**Problem:** Pre-commit quality gate tests fail.

**Solutions:**
1. Check syntax: `bash -n .claude/hooks/activate-rules.sh`
2. Verify regex patterns work
3. Review test output for specific failures
4. Check jq installed: `which jq`

### False Positives

**Problem:** Quality gates trigger when they shouldn't.

**Solutions:**
1. Review keyword list in `is_git_operation()` function
2. Make regex patterns more specific
3. Add negative patterns to exclude cases
4. Adjust detection logic in `activate-rules.sh`

## Related Files

- Hook implementation: `.claude/hooks/activate-rules.sh`
- Keyword mappings: `.claude/skills/skill-rules.json`
- Test suites: `tests/test-slash-command-detection.sh`, `tests/test-precommit-gates.sh`
