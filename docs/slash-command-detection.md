# Slash Command Detection

## Overview

The centralized-rules hook detects both **regular keywords** and **slash commands** to automatically load relevant coding rules and trigger quality gates.

## Supported Slash Commands

### Git Operations
- `/xgit` - External git skill (commit + push)
- `/git` - Git operations
- `/xcommit` - Commit with checks
- `/commit` - Commit changes
- `/push` - Push to remote

**Triggers:** `base/git-workflow` + Pre-commit quality gates

### Testing
- `/xtest` - Run test suite
- `/test` - Execute tests
- `/xtdd` - TDD workflow

**Triggers:** `base/testing-philosophy`

### Security
- `/xsecurity` - Security scan
- `/security` - Security audit
- `/xaudit` - Comprehensive audit

**Triggers:** `base/security-principles`

### Code Quality
- `/xrefactor` - Refactoring assistant
- `/xquality` - Quality checks
- `/xoptimize` - Performance optimization

**Triggers:** `base/refactoring-patterns`

## How It Works

### Detection Flow

1. **User submits prompt**
   ```
   User: "/xgit"
   ```

2. **Hook intercepts prompt**
   - `activate-rules.sh` analyzes the prompt text
   - Checks for slash command patterns using regex

3. **Rules loaded**
   - Detects `/xgit` matches git operations
   - Loads `base/git-workflow` rules
   - Triggers pre-commit quality gates

4. **Claude receives enriched context**
   - Original prompt + coding rules + quality gate instructions
   - Claude follows the rules when generating code

### Implementation

**Location:** `.claude/hooks/activate-rules.sh`

**Detection Code:**
```bash
# Git/commit keywords (including slash commands)
if echo "${prompt_lower}" | grep -qE '(commit|pull request|pr|merge|branch|push)'; then
    matched_rules+=("base/git-workflow")
# Detect git-related slash commands (e.g., /xgit, /commit, /xcommit, /git)
elif echo "${prompt_lower}" | grep -qE '/(x?git|x?commit|push)(\s|$)'; then
    matched_rules+=("base/git-workflow")
fi
```

**Regex Breakdown:**
- `/(x?git|x?commit|push)` - Matches `/git`, `/xgit`, `/commit`, `/xcommit`, `/push`
- `x?` - Optional "x" prefix (supports both `/git` and `/xgit`)
- `(\s|$)` - Must be followed by space or end of string (prevents false matches)

## Examples

### Example 1: Git Operation via Slash Command

**Input:**
```
User: "/xgit"
```

**Detection:**
- ✅ Matches regex `/(x?git|x?commit|push)(\s|$)`
- Loads: `base/git-workflow`
- Triggers: Pre-commit quality gates

**Output:**
```
🚦 PRE-COMMIT QUALITY GATES DETECTED
───────────────────────────────────
⚠️  IMPORTANT: Before committing/pushing, run these checks:

REQUIRED CHECKS (run in this order):
  1️⃣  Run tests        - Ensure all tests pass
  2️⃣  Security scan    - Check for vulnerabilities
  3️⃣  Code quality     - Verify code meets standards
  4️⃣  Refactoring      - Check for code smells
```

### Example 2: Git Operation via Keywords

**Input:**
```
User: "commit these changes"
```

**Detection:**
- ✅ Matches keyword `commit`
- Loads: `base/git-workflow`
- Triggers: Pre-commit quality gates

**Output:** (Same as Example 1)

### Example 3: Testing via Slash Command

**Input:**
```
User: "/xtest"
```

**Detection:**
- ✅ Matches regex `/(x?test|x?tdd)(\s|$)`
- Loads: `base/testing-philosophy`
- No quality gates (only triggered for git operations)

**Output:**
```
📚 Before implementing, follow this 3-step process:

STEP 1: 🔍 EVALUATE which rules apply
   📋 Matched Rule Categories:
     ☐ base/testing-philosophy
```

## Configuration

### Adding New Slash Commands

To add support for new slash commands, edit `.claude/hooks/activate-rules.sh`:

1. **Add detection logic:**

```bash
# Custom slash command detection
if echo "${prompt_lower}" | grep -qE '/(x?custom|my-command)(\s|$)'; then
    matched_rules+=("custom/my-rules")
fi
```

2. **Update documentation:**
   - Add to `skill-rules.json` keywords
   - Document in this file

### Regex Pattern Guide

**Pattern:** `/(x?COMMAND)(\s|$)`

- `/` - Literal slash character
- `x?` - Optional "x" prefix (0 or 1 occurrence)
- `COMMAND` - The command name
- `(\s|$)` - Must be followed by whitespace OR end of string

**Examples:**
- `/(x?test)(\s|$)` - Matches `/test`, `/xtest`
- `/(x?git|x?commit)(\s|$)` - Matches `/git`, `/xgit`, `/commit`, `/xcommit`
- `/(deploy|release)(\s|$)` - Matches `/deploy`, `/release` (no x- prefix)

## Testing

### Run Slash Command Tests

```bash
./tests/test-slash-command-detection.sh
```

**Expected Output:**
```
All tests passed!
Total tests run: 16
Passed: 16
```

### Manual Testing

```bash
# Test a specific prompt
echo '{"prompt":"/xgit"}' | .claude/hooks/activate-rules.sh | jq -r '.systemMessage'
```

### Test Cases

The test suite covers:
- ✅ All git slash commands (`/xgit`, `/git`, `/xcommit`, `/commit`, `/push`)
- ✅ All test slash commands (`/xtest`, `/test`, `/xtdd`)
- ✅ All security slash commands (`/xsecurity`, `/security`, `/xaudit`)
- ✅ All refactoring slash commands (`/xrefactor`, `/xquality`, `/xoptimize`)
- ✅ Traditional keywords still work (`commit`, `test`, etc.)

## Integration with Skills

### External Skills

Slash commands often invoke **external skills** (not part of centralized-rules). The hook detects these commands and loads relevant rules.

**Example Flow:**

1. User types `/xgit` (external skill)
2. Hook detects slash command
3. Hook loads `base/git-workflow` rules
4. Claude executes `/xgit` skill **with** git workflow rules applied
5. Quality gates ensure best practices are followed

### Benefits

- ✅ Works with any skill (even ones you don't control)
- ✅ Enforces coding standards regardless of invocation method
- ✅ No skill modifications required
- ✅ Transparent to the user

## Keyword vs Slash Command

Both trigger the same rules and quality gates:

| Method | Example | Rules Loaded | Quality Gates |
|--------|---------|--------------|---------------|
| **Keyword** | `"commit changes"` | `base/git-workflow` | ✅ Yes |
| **Slash Command** | `"/xgit"` | `base/git-workflow` | ✅ Yes |

**Takeaway:** It doesn't matter how you invoke git operations - the same quality gates apply!

## Advanced Features

### Multiple Command Detection

If a prompt contains multiple slash commands or keywords, all relevant rules are loaded:

**Input:**
```
User: "/xtest then /xgit"
```

**Detection:**
- Matches `/xtest` → loads `base/testing-philosophy`
- Matches `/xgit` → loads `base/git-workflow` + quality gates

### Case Insensitivity

All detection is case-insensitive:

```
"/XGIT" → matches
"/XGit" → matches
"/xgit" → matches
```

### Partial Matches Prevented

The regex requires whitespace or end-of-string after the command:

```
"/xgit" → ✅ matches
"/xgit " → ✅ matches
"/xgitfoo" → ❌ doesn't match (prevents false positives)
```

## Troubleshooting

### Command Not Detected

**Problem:** Slash command doesn't trigger rules

**Solution:**
1. Check regex pattern: `grep -E '/(x?git|x?commit)(\s|$)' <<< "/xgit"`
2. Verify case: Detection is case-insensitive
3. Check for typos: `/xgit` not `/x-git` or `/xGit`
4. Run test: `./tests/test-slash-command-detection.sh`

### Wrong Rules Loaded

**Problem:** Different rules loaded than expected

**Solution:**
1. Check keyword overlap: A keyword might also match
2. Review `match_keywords()` function logic
3. Test manually: `echo '{"prompt":"YOUR_PROMPT"}' | .claude/hooks/activate-rules.sh`

## Related Documentation

- [Pre-Commit Quality Gates](./pre-commit-quality-gates.md)
- [Keyword Mappings](../.claude/skills/skill-rules.json)
- [Git Workflow Rules](../base/git-workflow.md)
- [Hook Implementation](../.claude/hooks/activate-rules.sh)

## BEADS Task

Tracked in: **centralized-rules-ajq**

```bash
bd show centralized-rules-ajq
```
