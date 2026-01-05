# Beads Issue Tracking

> **Official Tool:** https://github.com/steveyegge/beads/
> **When to apply:** Projects using the `bd` CLI tool from the beads repository for issue tracking and workflow management

**IMPORTANT:** BEADS is a specific git-based issue tracking tool, not a general methodology. Always refer to the official beads repository when implementing or discussing BEADS functionality.

## Maturity Level Indicators

Apply beads practices based on your project's maturity level:

| Practice | MVP/POC | Pre-Production | Production |
|----------|---------|----------------|------------|
| Session start protocol | ✅ Required | ✅ Required | ✅ Required |
| Issue creation with types | ⚠️ Recommended | ✅ Required | ✅ Required |
| Dependency tracking | ❌ Optional | ⚠️ Recommended | ✅ Required |
| Discovered work pattern | ⚠️ Recommended | ✅ Required | ✅ Required |
| Session end protocol | ✅ Required | ✅ Required | ✅ Required |
| Always use --json flag | ✅ Required | ✅ Required | ✅ Required |
| Git hooks installation | ❌ Optional | ⚠️ Recommended | ✅ Required |

**Legend:**
- ✅ Required - Must implement
- ⚠️ Recommended - Should implement when feasible
- ❌ Optional - Can skip or defer

See `base/project-maturity-levels.md` for detailed maturity framework.

## What is Beads?

**Beads** is a specific git-based issue tracking tool created by Steve Yegge. It is **NOT**:
- ❌ A general methodology or pattern
- ❌ A custom format you should create
- ❌ An abstract concept open to interpretation

It **IS**:
- ✅ A concrete CLI tool installed via the repository: https://github.com/steveyegge/beads/
- ✅ Used through the `bd` command (e.g., `bd create`, `bd list`, `bd close`)
- ✅ Stores issues in a `.beads/` directory using SQLite database
- ✅ Designed specifically for AI agents and developers

**If a project uses BEADS, it means they have installed the tool from the official repository and use the `bd` CLI commands.**

## Core Philosophy

**Beads (https://github.com/steveyegge/beads/)** is a lightweight, git-based issue tracking system designed for AI agents and developers to manage work seamlessly within the repository. This rule describes how to use the `bd` CLI tool from the official beads repository - it is NOT a custom or alternative implementation.

### ⚠️ CRITICAL DATABASE SAFETY WARNING

**NEVER EDIT `.beads/issues.jsonl` OR `.beads/beads.db` DIRECTLY!**

The `.beads/issues.jsonl` file is a **GENERATED EXPORT** from the `beads.db` database.
- ❌ Manually editing JSONL will NOT update the database - changes are silently ignored
- ✅ **ALWAYS use `bd` commands** (`bd create`, `bd update`, `bd close`)
- ✅ **ALWAYS verify** issues were created correctly (see "Verification After Creating Issues" section)

### Key Principles:

- **Always use --json flag** for programmatic parsing by AI agents
- **Always verify after creating** issues using `bd list` or `bd show`
- **Session protocols** ensure clean state transitions and prevent data loss
- **Discovered work pattern** captures bugs and tasks found during other work
- **Dependency tracking** manages relationships between issues
- **Git-native** storage in `.beads/` directory keeps issues with code

## Universal Best-Practices Review

**CRITICAL:** Apply this review checklist to **EVERY** Beads issue before marking it complete. This is **NON-NEGOTIABLE** regardless of issue type, size, or priority.

### Pre-Completion Checklist

Before closing any issue with `bd close`, you **MUST** verify:

#### 1. Security Assessment
- ✅ **No new vulnerabilities introduced** (XSS, SQL injection, command injection, CSRF, etc.)
- ✅ **Input validation** at all system boundaries (user input, external APIs, file uploads)
- ✅ **Authentication/authorization** properly enforced where required
- ✅ **Sensitive data** properly handled (no secrets in logs, proper encryption)
- ✅ **Dependencies** reviewed for known vulnerabilities (run `npm audit`, `pip-audit`, etc.)

**Example:** `npm audit --production && bd close bd-42 --reason "Added auth with input validation, no vulnerabilities" --json`

#### 2. Code Quality Assessment
- ✅ **No code smells** (long methods, large classes, duplicate code, magic numbers)
- ✅ **Cyclomatic complexity reduced** (prefer simple, linear code over nested conditionals)
- ✅ **Single Responsibility Principle** honored (each function/class does one thing)
- ✅ **DRY principle** applied (no copy-paste duplication)
- ✅ **Meaningful names** used (no `x`, `temp`, `data` - use domain terms)

**Example:** `eslint src/ --rule 'complexity: [error, 10]' && bd close bd-42 --reason "Refactored auth from complexity 15 to 6" --json`

#### 3. Correctness Verification
- ✅ **Tests pass** (all unit, integration, and relevant E2E tests)
- ✅ **Edge cases handled** (null, empty, negative, boundary values)
- ✅ **Error handling** appropriate (don't swallow errors, provide useful messages)
- ✅ **Type safety** maintained (proper types in TypeScript, type hints in Python)
- ✅ **Documentation accurate** (comments match behavior, API docs updated)

**Example:** `pytest tests/ --cov && bd close bd-42 --reason "Auth tested: null user, empty token, expired JWT" --json`

#### 4. Simplicity First
- ✅ **Simplest viable change** implemented (no over-engineering)
- ✅ **No premature optimization** (optimize only proven bottlenecks)
- ✅ **No premature abstraction** (three uses rule before extracting)
- ✅ **YAGNI applied** (You Aren't Gonna Need It - no speculative features)
- ✅ **Minimal dependencies** added (prefer standard library)

**Example:** ❌ `"Added configurable factory pattern with strategy injection"` ✅ `"Added JWT middleware in auth.js:45"`

#### 5. Behavior-Preserving Refactoring
- ✅ **Existing tests still pass** (refactoring doesn't change behavior)
- ✅ **API contracts preserved** (public interfaces unchanged)
- ✅ **No silent behavioral changes** (same inputs → same outputs)
- ✅ **Refactoring separate from features** (don't mix refactor + new behavior)

**Example:** `npm test && bd close bd-42 --reason "Refactored auth to extract middleware, all tests pass unchanged" --json`

#### 6. Consistency with Existing Patterns
- ✅ **Follow project conventions** (naming, file structure, error handling)
- ✅ **Match existing architecture** (don't introduce new patterns without reason)
- ✅ **Consistent style** (formatting, imports, logging)
- ✅ **Respect .editorconfig, linting rules** without exceptions

**Example:** `eslint --fix src/ && bd close bd-42 --reason "Auth follows project's Express middleware pattern" --json`

#### 7. No Regressions
- ✅ **Performance not degraded** (no new O(n²) algorithms, inefficient queries)
- ✅ **Readability maintained or improved** (code is easier to understand)
- ✅ **Maintainability not compromised** (no technical debt added)
- ✅ **Accessibility preserved** (for UI changes)
- ✅ **Bundle size monitored** (for frontend changes)

**Example:** `npm run build && ls -lh dist/ && bd close bd-42 --reason "Auth added, bundle +2KB (tree-shaking applied)" --json`

### When to Create Review Issues

If you discover problems during this review, **DO NOT** close the original issue. Instead:

```bash
# Current issue has quality problems
bd create "Reduce cyclomatic complexity in auth handler" \
  --description "auth.js:authenticate() has complexity 18, should be < 10" \
  -t task \
  -p 1 \
  --json

bd dep add bd-46 bd-42 --type blocks  # Blocks closing of original issue

# Fix the quality issue first
bd update bd-46 --status in_progress --json
# ... refactor ...
bd close bd-46 --reason "Reduced authenticate() complexity to 7 by extracting validators" --json

# Now close original issue
bd close bd-42 --reason "Completed auth with quality standards met" --json
```

### Integration with Existing Rules

This universal review **extends** existing practices:

- **Testing philosophy**: Pre-existing requirement, now explicitly part of checklist
- **Security principles**: Codifies security review for every change
- **Refactoring patterns**: Ensures refactoring is behavior-preserving
- **Code quality**: Makes quality gates explicit and mandatory

### Why This Matters

**Without universal review:**
- ❌ Security vulnerabilities slip through
- ❌ Technical debt accumulates
- ❌ Code becomes unmaintainable
- ❌ Performance degrades over time

**With universal review:**
- ✅ Consistent quality across all changes
- ✅ Security baked into workflow
- ✅ Codebase stays maintainable
- ✅ Technical excellence is habitual

### Quick Review Workflow

**Template for closing any issue:**

```bash
# 1. Run quality gates
npm test && npm run lint
pytest && pylint src/
go test ./... && golangci-lint run

# 2. Security scan
npm audit --production
semgrep --config=auto src/

# 3. Complexity check
radon cc src/ --average
eslint src/ --rule 'complexity: [error, 10]'

# 4. Performance baseline
npm run build && ls -lh dist/

# 5. Document and close
bd close bd-42 \
  --reason "Added JWT auth: tests pass, complexity < 8, no vulnerabilities, bundle +2KB" \
  --json
```

**Remember:** If ANY checklist item fails, file a blocking issue and fix it **before** closing.

## Session Start Protocol

**MANDATORY:** Begin every work session with this protocol.

### Steps:

1. **Navigate to project**
   ```bash
   cd /path/to/project
   ```

2. **Check available work**
   ```bash
   bd ready --json
   ```

   This command lists all issues with no open blockers, ready to be claimed.

3. **Verify clean state**
   ```bash
   git status
   ```

   Ensure no uncommitted changes to `.beads/` directory.

### Example Output:

```json
{
  "ready": [
    {
      "id": "bd-42",
      "title": "Add user authentication",
      "type": "feature",
      "priority": 1,
      "status": "ready"
    },
    {
      "id": "bd-44",
      "title": "Fix pagination bug",
      "type": "bug",
      "priority": 0
    }
  ]
}
```

### What This Tells You:

- **id**: Unique issue identifier
- **title**: Brief description of the work
- **type**: Issue classification (bug, feature, task)
- **priority**: 0 (highest) to 4 (lowest)
- **status**: Current state (ready, in_progress, closed)

## Creating Issues

Use `bd create` to add new issues to the tracker.

### Command Syntax:

```bash
bd create "Title" --description "Details" -t TYPE -p PRIORITY --json
```

### Parameters:

- **Title** (required): Brief, actionable description
- **--description, -d**: Detailed explanation of the work
- **--type, -t**: Issue type (bug, feature, task)
- **--priority, -p**: Priority level (0-4)
  - **0**: Critical/P0 - Immediate attention
  - **1**: High/P1 - Important, near-term
  - **2**: Medium/P2 - Normal priority
  - **3**: Low/P3 - Nice to have
  - **4**: Lowest/P4 - Backlog
- **--json**: Output in JSON format for agent parsing

### Examples:

**Creating a bug:**
```bash
bd create "Fix null pointer in login handler" \
  --description "Users experiencing crashes when logging in with empty passwords" \
  -t bug \
  -p 0 \
  --json
```

**Creating a feature:**
```bash
bd create "Add dark mode toggle" \
  --description "Implement dark mode with user preference persistence" \
  -t feature \
  -p 2 \
  --json
```

**Creating a task:**
```bash
bd create "Update dependencies to latest versions" \
  -t task \
  -p 3 \
  --json
```

### When to Create Issues:

- **At session start**: Planning work for the session
- **During work**: Discovered bugs or improvements (see Discovered Work Pattern)
- **At session end**: Filing remaining work for future sessions
- **Code review**: Issues found during review
- **Testing**: Bugs discovered during testing

### ✅ MANDATORY Verification After Creating Issues

**CRITICAL:** After every `bd create` command, you MUST verify the issue was created correctly.

#### Verification Protocol:

1. **Capture the issue ID from output**
   ```bash
   bd create "Task title" -t task -p 1 --json
   # Output: {"id": "centralized-rules-abc", ...}
   ```

2. **Verify using bd list**
   ```bash
   bd list --status open | grep "centralized-rules-abc"
   ```

   **Expected output:**
   ```
   centralized-rules-abc [P1] [task] open - Task title
   ```

3. **Or verify using bd show**
   ```bash
   bd show centralized-rules-abc --json
   ```

   **Expected output:**
   ```json
   {
     "id": "centralized-rules-abc",
     "title": "Task title",
     "status": "open",
     "type": "task",
     "priority": 1
   }
   ```

#### If Issue Doesn't Appear:

**Problem:** `bd list` doesn't show the issue you just created.

**Common causes:**
- ❌ Edited `.beads/issues.jsonl` directly instead of using `bd create`
- ❌ Database not synchronized
- ❌ Wrong status filter (issue is in different status than expected)
- ❌ Daemon not running

**Solution steps:**

1. **Check with all statuses**
   ```bash
   bd list --status all | grep "task title"
   ```

2. **Check daemon status**
   ```bash
   ps aux | grep "bd.*daemon"
   ```

3. **Restart daemon if needed**
   ```bash
   pkill -f "bd.*daemon"
   bd list --json  # Auto-starts daemon
   ```

4. **Check database directly**
   ```bash
   bd export | grep "task title"
   ```

5. **If issue is truly missing, recreate it**
   ```bash
   bd create "Task title" -t task -p 1 --json
   # Verify immediately
   bd list --status open | grep "task title"
   ```

#### Best Practice Pattern:

**Always combine create + verify in sequence:**

```bash
# Create issue
ISSUE_OUTPUT=$(bd create "Implement user authentication" \
  --description "Add JWT-based auth with refresh tokens" \
  -t feature \
  -p 1 \
  --json)

# Extract ID
ISSUE_ID=$(echo "$ISSUE_OUTPUT" | jq -r '.id')

# Verify it exists
bd show "$ISSUE_ID" --json | jq -r '.id, .title, .status'

# Expected output:
# centralized-rules-xyz
# Implement user authentication
# open
```

**This verification is NON-NEGOTIABLE.** If you cannot verify the issue exists, the task has NOT been completed.

## Claiming Work

When you start working on an issue, update its status to `in_progress`.

### Command Syntax:

```bash
bd update <id> --status in_progress --json
```

### Example:

```bash
bd update bd-42 --status in_progress --json
```

### Output:

```json
{
  "id": "bd-42",
  "title": "Add user authentication",
  "status": "in_progress",
  "updated_at": "2024-01-15T14:30:00Z"
}
```

### Critical Rule:

**ONLY ONE ISSUE in_progress at a time** - Focus on completing one task before claiming another.

### Exception:

You may claim a second issue if:
- First issue is blocked waiting for external dependency
- Second issue is directly related (e.g., discovered bug while working on first)

## Discovered Work Pattern

**The Pattern:** When working on one issue, you often discover bugs, improvements, or related tasks.

### Protocol:

1. **Create the discovered issue immediately**
   ```bash
   bd create "Fix validation error handling" \
     --description "Found while implementing bd-42: login form doesn't validate email format" \
     -t bug \
     -p 1 \
     --json
   ```

2. **Link the discovered work to the parent**
   ```bash
   bd dep add <new-issue-id> <parent-issue-id> --type discovered-from
   ```

   Example:
   ```bash
   bd dep add bd-45 bd-42 --type discovered-from
   ```

3. **Decide: Fix now or defer**

   **Fix now if:**
   - Blocking the current work
   - Quick fix (< 15 minutes)
   - Critical bug (P0/P1)

   **Defer if:**
   - Not blocking current work
   - Requires significant effort
   - Lower priority

4. **Update status accordingly**

   **If fixing now:**
   ```bash
   bd update bd-45 --status in_progress --json
   ```

   **If deferring:**
   ```bash
   # Leave as "ready" for future work
   # The dependency link preserves the relationship
   ```

### Benefits:

- **Captures all work** as it's discovered
- **Prevents forgetting** important bugs
- **Creates audit trail** showing how issues were discovered
- **Enables prioritization** of discovered work
- **Maintains focus** by deferring non-critical items

### Example Workflow:

```bash
# Start work on feature
bd update bd-42 --status in_progress --json

# While implementing, discover a bug
bd create "Email validation missing" \
  --description "Found while implementing bd-42: no validation on email field" \
  -t bug \
  -p 1 \
  --json
# Output: {"id": "bd-45", ...}

# Link the discovered bug to the parent feature
bd dep add bd-45 bd-42 --type discovered-from

# Bug is blocking, fix it now
bd update bd-45 --status in_progress --json
# ... fix the bug ...
bd close bd-45 --reason "Added email validation with regex pattern" --json

# Return to original feature
# bd-42 is still in_progress
# ... complete the feature ...
bd close bd-42 --reason "Implemented user authentication with JWT tokens" --json
```

## Dependency Management

Track relationships between issues using dependencies.

### Dependency Types:

- **blocks**: Child blocks parent (parent can't proceed until child is done)
- **related**: Issues are related but not blocking
- **parent-child**: Hierarchical relationship (subtask of parent)
- **discovered-from**: Issue discovered while working on parent

### Command Syntax:

```bash
bd dep add <child-id> <parent-id> --type TYPE
```

### Examples:

**Blocking dependency:**
```bash
# bd-43 blocks bd-42
bd dep add bd-43 bd-42 --type blocks
```

**Related work:**
```bash
# bd-44 is related to bd-42 but not blocking
bd dep add bd-44 bd-42 --type related
```

**Parent-child (subtask):**
```bash
# bd-45 is a subtask of bd-42
bd dep add bd-45 bd-42 --type parent-child
```

### Querying Dependencies:

View issue details including dependencies:
```bash
bd show bd-42 --json
```

Output includes dependency graph:
```json
{
  "id": "bd-42",
  "title": "Add user authentication",
  "dependencies": [
    {
      "id": "bd-43",
      "type": "blocks",
      "status": "in_progress"
    }
  ],
  "blocked_by": ["bd-43"]
}
```

## Completing Work

When you finish an issue, close it with a reason explaining what was done.

### Command Syntax:

```bash
bd close <id> --reason "What was done" --json
```

### Examples:

**Single issue:**
```bash
bd close bd-42 --reason "Implemented JWT-based authentication with token refresh" --json
```

**Multiple issues:**
```bash
bd close bd-42 bd-43 --reason "Completed authentication system" --json
```

### Reason Guidelines:

- **Be specific**: Explain *what* was done, not just "fixed" or "completed"
- **Include details**: Technical approach, files changed, etc.
- **Reference commits**: If applicable, mention commit hashes
- **Note trade-offs**: Document any compromises or limitations

### Good Reasons:

✅ "Implemented JWT authentication with refresh tokens, added middleware for protected routes"
✅ "Fixed null pointer by adding validation in auth.go:145, added tests in auth_test.go"
✅ "Refactored user model to use bcrypt for password hashing, migrated existing passwords"

### Bad Reasons:

❌ "Done"
❌ "Fixed"
❌ "Completed task"
❌ "See commit"

## Session End Protocol

**CRITICAL:** The "Land the Plane" protocol ensures all work is saved and synchronized.

### ⚠️ COMMIT MESSAGE WARNING

**NEVER use `bd sync` without arguments!** It creates useless commit messages like:
```
bd sync: 2026-01-05 12:58:25
```

**ALWAYS use one of these approaches instead:**
- `bd sync -m "meaningful message"` - Quick sync with custom message
- `bd sync --flush-only` + `git commit` - Combine beads with code changes

<!-- TIP: NEVER run bd sync without -m flag or --flush-only - default creates useless timestamp commits -->

### MANDATORY Steps (All Required):

1. **File remaining work**

   Create issues for any unfinished work or future improvements:
   ```bash
   bd create "Add integration tests for auth flow" \
     -t task \
     -p 2 \
     --json
   ```

2. **Run quality gates** (if code changes were made)

   Language-specific tests and linting:
   ```bash
   # Python
   pytest tests/
   pylint src/

   # Go
   go test -short ./...
   golangci-lint run ./...

   # TypeScript
   npm test
   npm run lint
   ```

3. **Update beads issues**

   Close completed work:
   ```bash
   bd close bd-42 bd-43 --reason "Implemented authentication system with JWT tokens" --json
   ```

4. **Sync and push to remote** ⚠️ **NON-NEGOTIABLE**

   **Option 1: Combine beads + code in one commit (BEST)**
   ```bash
   # Pull latest changes
   git pull --rebase

   # If .beads/issues.jsonl conflicts occur:
   git checkout --theirs .beads/issues.jsonl
   bd import -i .beads/issues.jsonl

   # Stage your code changes
   git add <your-files>

   # Export beads changes to JSONL (no git operations)
   bd sync --flush-only

   # Stage beads metadata
   git add .beads/issues.jsonl

   # Commit everything with meaningful message
   git commit -m "feat: completed authentication [bd-42, bd-43]"

   # Push to remote - MANDATORY
   git push

   # Verify clean state
   git status
   ```

   **Option 2: Quick sync with custom message**
   ```bash
   git pull --rebase

   # IMPORTANT: Always provide a meaningful commit message with -m flag
   bd sync -m "feat: completed authentication [bd-42, bd-43]"

   git push
   git status
   ```

   **Expected output:**
   ```
   On branch main
   Your branch is up to date with 'origin/main'.

   nothing to commit, working tree clean
   ```

5. **Clean up** (optional but recommended)

   ```bash
   git stash clear
   git remote prune origin
   ```

6. **Suggest next work**

   Review available work for next session:
   ```bash
   bd ready --json
   bd show bd-44 --json
   ```

### Critical Rule:

**The plane has NOT landed until `git push` completes successfully.**

Never end a session with:
- Uncommitted changes to `.beads/`
- Unpushed commits
- Unresolved merge conflicts
- Failing tests

### Why This Matters:

- **Data preservation**: Beads data is stored in `.beads/`, must be committed
- **Team sync**: Other developers/agents need to see issue updates
- **Audit trail**: Complete history of work requires pushed commits
- **Recovery**: Unpushed work can be lost if system fails

### Understanding Auto-Sync:

Beads automatically syncs the database with **30-second debounce** to batch operations and reduce commits.

**Auto-sync triggers:** Creating/updating/closing issues, adding dependencies
**Batching:** Multiple operations within 30 seconds = single commit

### What `bd sync` Does:

1. **Export**: Database → `.beads/issues.jsonl`
2. **Commit**: Commits JSONL (unless using `--squash` or `--flush-only`)
3. **Pull**: Fetches remote changes
4. **Import**: `.beads/issues.jsonl` → Database
5. **Push**: Sends commits to remote

## Git Hooks (Recommended)

Install beads git hooks for automatic synchronization.

### One-Time Setup:

```bash
bd hooks install
```

### Installed Hooks:

- **pre-commit**: Validates beads database before commit
- **post-merge**: Imports changes after merge/pull
- **pre-push**: Ensures database is synced before push
- **post-checkout**: Updates database after branch switch

### Benefits:

- **Automatic sync**: No manual `bd sync` needed in most cases
- **Conflict prevention**: Early detection of issues
- **Consistency**: Database always matches git state
- **Safety**: Prevents pushing without sync

### Verification:

Check hooks are installed:
```bash
ls -la .git/hooks/
```

Should show:
- `pre-commit`
- `post-merge`
- `pre-push`
- `post-checkout`

## Common Workflows

### Daily Development Flow

```bash
# Morning: Session start
cd /path/to/project
bd ready --json
bd update bd-42 --status in_progress --json

# Work on task
# ... write code ...

# Discover bug while working
bd create "Fix validation error" \
  --description "Found while implementing bd-42" \
  -t bug \
  -p 1 \
  --json
bd dep add bd-45 bd-42 --type discovered-from

# Fix bug first (blocking)
bd update bd-45 --status in_progress --json
# ... fix bug ...
bd close bd-45 --reason "Added email validation" --json

# Complete original task
# ... finish feature ...
bd close bd-42 --reason "Implemented authentication" --json

# Evening: Session end
bd create "Add integration tests" -t task -p 2 --json
pytest tests/

# Recommended: Combine code and beads in one commit
git add <your-files>
bd sync --flush-only
git add .beads/issues.jsonl
git commit -m "feat: implement authentication with bug fixes [bd-42, bd-45]"
git push
git status  # Verify clean
```

### Bug Fix Flow

```bash
# Find available bugs
bd ready --json | jq '.ready[] | select(.type=="bug")'

# Claim high-priority bug
bd update bd-44 --status in_progress --json

# Investigate and fix
# ... debug and fix ...

# Complete with detailed reason
bd close bd-44 \
  --reason "Fixed pagination bug in user list by correcting offset calculation in api.py:234" \
  --json

# Sync and push with meaningful message
git add api.py tests/
bd sync --flush-only
git add .beads/issues.jsonl
git commit -m "fix: correct pagination offset calculation [bd-44]"
git push
```

### Feature Development Flow

```bash
# Create feature issue
bd create "Implement dark mode" \
  --description "Add theme switching with localStorage persistence" \
  -t feature \
  -p 2 \
  --json

# Break into subtasks
bd create "Add theme context provider" -t task -p 2 --json
bd create "Create theme toggle component" -t task -p 2 --json
bd create "Update CSS variables for themes" -t task -p 2 --json

# Link subtasks to feature
bd dep add bd-47 bd-46 --type parent-child
bd dep add bd-48 bd-46 --type parent-child
bd dep add bd-49 bd-46 --type parent-child

# Work through subtasks
bd update bd-47 --status in_progress --json
# ... implement ...
bd close bd-47 --reason "Added ThemeProvider with context API" --json

bd update bd-48 --status in_progress --json
# ... implement ...
bd close bd-48 --reason "Created ThemeToggle button component" --json

bd update bd-49 --status in_progress --json
# ... implement ...
bd close bd-49 --reason "Updated CSS with dark mode variables" --json

# Close parent feature
bd close bd-46 --reason "Completed dark mode feature with all subtasks" --json
```

## Querying and Reporting

### List All Issues

```bash
bd list --json
```

### Show Specific Issue

```bash
bd show bd-42 --json
```

Output includes:
- Issue details
- Audit trail (all status changes)
- Dependencies
- Comments/updates

### Filter by Status

```bash
bd list --json | jq '.issues[] | select(.status=="in_progress")'
```

### Filter by Type

```bash
bd list --json | jq '.issues[] | select(.type=="bug")'
```

### Filter by Priority

```bash
bd list --json | jq '.issues[] | select(.priority<=1)'
```

### Show Dependencies

```bash
bd show bd-42 --json | jq '.dependencies'
```

## Best Practices

### Issue Creation

1. **Use descriptive titles** - Make issues findable and understandable
2. **Set appropriate priority** - P0 for critical, P1-P2 for normal work
3. **Choose correct type** - bug, feature, or task
4. **Add descriptions** - Provide context and details
5. **Always use --json** - Enable programmatic parsing

### Workflow Management

1. **One issue in_progress** - Maintain focus
2. **Close issues promptly** - Don't leave old issues open
3. **File discovered work** - Capture all bugs and improvements
4. **Use dependencies** - Track relationships between issues
5. **Provide detailed close reasons** - Document what was done

### Session Hygiene

1. **Start with bd ready** - Review available work
2. **End with bd sync + git push** - Save all work
3. **Verify git status** - Ensure clean state
4. **Run tests before closing** - Quality gates
5. **Suggest next work** - Plan future sessions

### Database Safety

⚠️ **See "CRITICAL DATABASE SAFETY WARNING" in Core Philosophy section above for complete rules.**

**Key reminder:** NEVER edit `.beads/issues.jsonl` or `.beads/beads.db` directly - always use `bd` commands and verify with `bd list` or `bd show`.

## Integration with Development Workflow

### With Git Workflow (base/git-workflow.md)

**Synergy:** Beads extends git workflow with issue tracking. Reference issues in commits (`[bd-42]`), create feature branches per issue, and push both code + `.beads/` metadata together.

### With Testing Philosophy (base/testing-philosophy.md)

**Synergy:** Tests must pass before closing issues. TDD workflow: create failing test (Red), fix bug (Green), verify passes, then close issue with `bd close`.

### With Task Management (TodoWrite)

**Different purposes:**

| Aspect | TodoWrite | Beads |
|--------|-----------|-------|
| **Scope** | Single session | Cross-session |
| **Persistence** | In-memory | Git-tracked |
| **Granularity** | Fine steps | Cohesive units |
| **Example** | "Update auth.py", "Run tests" | "Implement authentication" |

**Workflow:** Start session with `bd ready`, use TodoWrite to break down beads issue into steps, discover new work → create beads issue, session end → close beads issue.

**Conversion:** If TodoWrite task spans multiple sessions, convert to beads issue.

### Integration Summary

**The complete workflow stack:**

```
┌─────────────────────────────────────┐
│   Beads Issue Tracking              │  ← Strategic: What to work on
│   (Cross-session, persistent)       │
├─────────────────────────────────────┤
│   TodoWrite Task Management         │  ← Tactical: How to break it down
│   (Single-session, ephemeral)       │
├─────────────────────────────────────┤
│   Testing Philosophy                │  ← Quality: Ensure correctness
│   (Before marking work complete)    │
├─────────────────────────────────────┤
│   Git Workflow                      │  ← Foundation: Version control
│   (Commit, push, clean state)       │
└─────────────────────────────────────┘
```

**All four work together:**
1. **Beads** says "Work on bd-42: Add authentication"
2. **TodoWrite** breaks it into steps
3. **Testing** ensures quality at each step
4. **Git** tracks all changes (code + beads metadata)

## Why Beads Matters

**Tool Repository:** https://github.com/steveyegge/beads/

### Benefits:

- **Git-native**: Issues live with code, no external tools needed
- **AI-optimized**: JSON output designed for programmatic use
- **Lightweight**: Simple CLI, no complex UI
- **Offline-capable**: Works without internet connection
- **Audit trail**: Complete history of all issue changes
- **Team sync**: Git-based sharing works with existing workflows

### Use Cases:

- **Solo development**: Track personal work queue
- **Pair programming**: Share task list with collaborator
- **AI assistance**: Agents can read/write issues programmatically
- **Code review**: Track issues found during review
- **Bug tracking**: Lightweight alternative to Jira/GitHub Issues

### Integration:

- **CI/CD**: Reference beads issues in automated workflows
- **Documentation**: Link docs to beads issues for context
- **Metrics**: Parse `.beads/issues.jsonl` for analytics
- **Automation**: Scripts can create/update issues via `bd` CLI

---

## Quick Reference

### Essential Commands

```bash
# Session start
bd ready --json

# Create issue (ALWAYS with verification)
bd create "Title" --description "Details" -t TYPE -p PRIORITY --json
bd list --status open | grep "Title"  # ✅ MANDATORY: Verify it was created

# Claim work
bd update <id> --status in_progress --json

# Add dependency
bd dep add <child-id> <parent-id> --type TYPE

# Close issue
bd close <id> --reason "What was done" --json

# Session end (recommended workflow)
git add <your-files>
bd sync --flush-only           # Export to JSONL without git ops
git add .beads/issues.jsonl
git commit -m "feat: your message [bd-42]"
git push

# Session end (alternative with custom message)
bd sync -m "feat: your message [bd-42]"
git push
```

### Sync Options

```bash
# ❌ NEVER DO THIS - creates useless "bd sync: timestamp" commits
bd sync

# ✅ Custom commit message (RECOMMENDED)
bd sync -m "your custom message here"

# ✅ Export to JSONL only - best for combining with code changes
bd sync --flush-only

# Accumulate changes without committing (during work)
bd sync --squash

# Check sync status without syncing
bd sync --status
```

### Dependency Types

- `blocks` - Child blocks parent
- `related` - Related but not blocking
- `parent-child` - Subtask relationship
- `discovered-from` - Found during parent work

### Priority Levels

- `0` - Critical (P0)
- `1` - High (P1)
- `2` - Medium (P2)
- `3` - Low (P3)
- `4` - Backlog (P4)

### Issue Types

- `bug` - Defects and errors
- `feature` - New functionality
- `task` - Chores and maintenance

### Critical Rules

1. ✅ **Always use --json flag** for agent compatibility
2. ✅ **NEVER edit `.beads/issues.jsonl` directly** - Use `bd` commands only
3. ✅ **ALWAYS verify after creating** - Use `bd list` or `bd show` to confirm issue exists
4. ✅ **NEVER use `bd sync` without -m or --flush-only** - Avoid useless timestamp commits
5. ✅ **Universal best-practices review MANDATORY** - Apply security, quality, correctness checklist before closing ANY issue
6. ✅ **Session start with bd ready** to review work
7. ✅ **Session end with meaningful commit** (use `-m` flag or `--flush-only`)
8. ✅ **One issue in_progress** at a time
9. ✅ **File discovered work** immediately
10. ✅ **Detailed close reasons** document what was done (include quality metrics)
11. ✅ **Tests must pass** before closing issues

---

*For more information, see: https://github.com/steveyegge/beads*
