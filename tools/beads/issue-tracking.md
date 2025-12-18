# Beads Issue Tracking

> **When to apply:** Projects using beads (bd) for issue tracking and workflow management

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

## Core Philosophy

Beads is a lightweight, git-based issue tracking system designed for AI agents and developers to manage work seamlessly within the repository.

### Key Principles:

- **Always use --json flag** for programmatic parsing by AI agents
- **Session protocols** ensure clean state transitions and prevent data loss
- **Discovered work pattern** captures bugs and tasks found during other work
- **Dependency tracking** manages relationships between issues
- **Git-native** storage in `.beads/` directory keeps issues with code

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

   ```bash
   # Pull latest changes
   git pull --rebase

   # If .beads/issues.jsonl conflicts occur:
   git checkout --theirs .beads/issues.jsonl
   bd import -i .beads/issues.jsonl

   # Sync beads database
   bd sync

   # Push to remote - MANDATORY
   git push

   # Verify clean state
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

## Database Synchronization

Beads automatically syncs the database with a 30-second debounce, but manual sync is sometimes needed.

### Auto-Sync:

Beads batches operations within 30-second windows to reduce git commits.

**What triggers auto-sync:**
- Creating issues
- Updating status
- Closing issues
- Adding dependencies

**Batching behavior:**
Multiple operations within 30 seconds = single commit

### Manual Sync:

Force immediate synchronization:
```bash
bd sync
```

**When to manually sync:**
- At session end (required)
- Before major operations (recommended)
- After resolving conflicts (required)
- When sharing work with team (recommended)

### Sync Process:

`bd sync` performs:
1. **Export**: Database → `.beads/issues.jsonl`
2. **Commit**: Commits the JSONL file
3. **Pull**: Fetches remote changes
4. **Import**: `.beads/issues.jsonl` → Database
5. **Push**: Sends commits to remote

### Conflict Resolution:

If `.beads/issues.jsonl` has merge conflicts:

```bash
# Accept remote version
git checkout --theirs .beads/issues.jsonl

# Re-import to update local database
bd import -i .beads/issues.jsonl

# Stage and commit
git add .beads/issues.jsonl
git commit -m "Resolved beads conflict"

# Push
git push
```

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
bd sync
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

# Sync and push
bd sync
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

1. **Never edit .beads/ manually** - Use bd commands only
2. **Always resolve conflicts** - Use `git checkout --theirs` + `bd import`
3. **Install git hooks** - Automatic synchronization
4. **Sync before major operations** - Prevent conflicts
5. **Backup regularly** - `.beads/` is in git, but extra backups don't hurt

## Integration with Development Workflow

### With Git Workflow (base/git-workflow.md)

**Synergy:**
- Beads session end protocol **extends** git workflow's commit/push requirements
- Both emphasize frequent commits and clean working state
- Beads adds issue tracking layer on top of git operations

**How they work together:**

1. **Commit messages**: Reference beads issues
   ```bash
   git commit -m "feat: add JWT authentication [bd-42]"
   ```

2. **Branch strategy**: Create feature branches per beads issue
   ```bash
   git checkout -b feature/bd-42-user-auth
   bd update bd-42 --status in_progress --json
   ```

3. **Session end**: Combined protocol
   ```bash
   # Complete git workflow
   git add .
   git commit -m "feat: complete auth [bd-42]"

   # Complete beads workflow
   bd close bd-42 --reason "Implemented JWT auth" --json
   bd sync
   git push  # Pushes both code and .beads/ metadata
   ```

**Key insight:** Beads `.beads/` directory is tracked by git, so git-workflow rules apply to beads metadata too.

### With Testing Philosophy (base/testing-philosophy.md)

**Synergy:**
- Both require tests to pass before marking work complete
- Testing philosophy's "never proceed with failing tests" applies to closing beads issues
- Beads session end protocol includes running quality gates

**How they work together:**

1. **Before closing issues**: All tests must pass
   ```bash
   # Run tests first
   pytest tests/

   # Only close if tests pass
   bd close bd-42 --reason "Added auth with tests" --json
   ```

2. **Bug workflow**: Create test, fix bug, verify test passes
   ```bash
   # Create failing test (Red)
   # Fix bug (Green)
   pytest tests/test_auth.py  # Verify passes

   # Then close issue
   bd close bd-44 --reason "Fixed auth bug, added regression test" --json
   ```

3. **Test coverage issues**: Track with beads
   ```bash
   bd create "Add integration tests for auth flow" \
     -t task \
     -p 2 \
     --json
   ```

**Key insight:** Beads issue status reflects test status - if tests fail, issue isn't truly "done".

### With Task Management (TodoWrite)

**Different purposes, complementary use:**

| Aspect | TodoWrite | Beads |
|--------|-----------|-------|
| **Scope** | Single session | Cross-session |
| **Persistence** | In-memory, conversation | Git-tracked, persistent |
| **Granularity** | Fine-grained steps | Cohesive work units |
| **Visibility** | AI agent only | Team-wide (via git) |
| **Example** | "Update auth.py", "Run tests", "Commit changes" | "Implement user authentication" |

**How they work together:**

1. **Session start**: Check beads for what to work on
   ```bash
   bd ready --json
   # Output: bd-42 "Add user authentication"

   bd update bd-42 --status in_progress --json
   ```

2. **During session**: Use TodoWrite to break down the beads issue
   ```
   TodoWrite:
   - [pending] Create User model
   - [pending] Add authentication endpoints
   - [pending] Write tests
   - [pending] Update documentation
   ```

3. **As you work**: Mark TodoWrite tasks complete
   ```
   TodoWrite:
   - [completed] Create User model
   - [in_progress] Add authentication endpoints
   - [pending] Write tests
   - [pending] Update documentation
   ```

4. **Discover new work**: Create beads issues immediately
   ```bash
   # While working, discover a bug
   bd create "Fix email validation in User model" \
     -t bug \
     -p 1 \
     --json
   bd dep add bd-45 bd-42 --type discovered-from
   ```

5. **Session end**: All TodoWrite tasks done → Close beads issue
   ```bash
   # All todos completed
   bd close bd-42 --reason "Completed user auth implementation" --json
   ```

**Key insight:** TodoWrite = tactical (how to do the work), Beads = strategic (what work to do).

**Conversion pattern:**
If a TodoWrite task will span multiple sessions, convert it to a beads issue:

```bash
# TodoWrite shows: "Refactor authentication module" is taking longer than expected

# Convert to beads issue:
bd create "Refactor authentication module" \
  --description "Extract middleware, add proper error handling, improve testability" \
  -t task \
  -p 2 \
  --json

# Remove from TodoWrite, track in beads instead
```

### Progressive Disclosure: When to Load This Rule

**Load beads rule when:**
- ✅ User mentions "bd", "beads", "beas" (common misspelling), "session start", or "session end"
- ✅ Beginning or ending a work session
- ✅ User asks about issue tracking or workflow management
- ✅ Creating/closing issues
- ✅ Working with discovered bugs/tasks

**Don't load if:**
- ❌ Just doing normal coding without session context
- ❌ Only using TodoWrite for in-session task management
- ❌ No .beads/ directory exists in project

**Token consideration:**
This rule is ~20KB. Load it selectively at session boundaries or when explicitly needed, not for every coding task.

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

# Create issue
bd create "Title" --description "Details" -t TYPE -p PRIORITY --json

# Claim work
bd update <id> --status in_progress --json

# Add dependency
bd dep add <child-id> <parent-id> --type TYPE

# Close issue
bd close <id> --reason "What was done" --json

# Session end
bd sync
git push
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
2. ✅ **Session start with bd ready** to review work
3. ✅ **Session end with bd sync + git push** (non-negotiable)
4. ✅ **One issue in_progress** at a time
5. ✅ **File discovered work** immediately
6. ✅ **Detailed close reasons** document what was done
7. ✅ **Tests must pass** before closing issues

---

*For more information, see: https://github.com/steveyegge/beads*
