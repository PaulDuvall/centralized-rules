# Git Workflow Guidelines

> **When to apply:** All git operations across any project

## Maturity Level Indicators

This document contains practices applicable to different project maturity levels. Apply practices based on your project's current phase:

| Practice | MVP/POC | Pre-Production | Production |
|----------|---------|----------------|------------|
| Frequent commits | ✅ Required | ✅ Required | ✅ Required |
| Conventional commit messages | ⚠️ Recommended | ✅ Required | ✅ Required |
| Branch protection | ❌ Optional | ✅ Required | ✅ Required |
| Required code reviews | ❌ Optional | ✅ Required (1 approval) | ✅ Required (2 approvals) |
| Automated commit hooks | ❌ Optional | ⚠️ Recommended | ✅ Required |
| GPG signed commits | ❌ Not needed | ❌ Optional | ⚠️ Recommended |

**Legend:**
- ✅ Required - Must implement this practice
- ⚠️ Recommended - Should implement when feasible
- ❌ Optional - Can skip or defer

See `base/project-maturity-levels.md` for detailed maturity framework.

## Commit Frequency

### Rule: Commit and Push Often

**MANDATORY:** Commit and push code frequently throughout development, not just at task completion.

### When to Commit:

- After completing a logical unit of work (even if small)
- After writing a new function or component
- After fixing a bug or test
- After refactoring a section of code
- Before switching to a different task or feature
- At the end of each work session
- When all tests pass for the current changes

### Commit Frequency Guidelines:

- **Minimum:** Commit at least once per completed subtask
- **Recommended:** Commit every 15-30 minutes of active development
- **Best Practice:** Commit after each meaningful change that passes tests

### Why Commit Often:

- Provides a safety net if something breaks
- Creates a clear history of changes
- Makes code review easier
- Enables easier rollback if needed
- Prevents loss of work
- Facilitates collaboration
- Shows progress incrementally

## Commit Message Format

### Structure:
```
<type>: <short description>

<optional longer description>

<optional footer>
```

### Types:
- `feat:` - New feature
- `fix:` - Bug fix
- `test:` - Adding or updating tests
- `refactor:` - Code refactoring
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `chore:` - Maintenance tasks
- `perf:` - Performance improvements

### Examples:

```bash
# Good commit messages
git commit -m "feat: add token masking function"
git commit -m "test: add property tests for encryption"
git commit -m "fix: handle null values in validation logic"
git commit -m "refactor: extract validation into separate function"

# Bad commit messages
git commit -m "updates"
git commit -m "wip"
git commit -m "fix stuff"
```

## Push Frequency

### Rule: Push After Each Commit (or Group of Related Commits)

- Push immediately after committing (preferred)
- Push at least once per hour during active development
- Always push before ending a work session
- Push after completing a subtask

### Why Push Often:

- Backs up work to remote repository
- Makes work visible to team/CI
- Triggers automated tests and checks
- Prevents conflicts from accumulating
- Enables collaboration

## Workflow Pattern

### Recommended Development Cycle:

```
1. Start task
2. Write code (small increment)
3. Run tests
4. Tests pass? → Commit
5. Push to remote
6. Repeat steps 2-5 until task complete
7. Mark task complete
```

### Example Session:

```bash
# Start working on a feature
git checkout -b feature/token-masking

# Write implementation
# ... code ...
# Run tests
git add <files>
git commit -m "feat: add token masking function"
git push origin feature/token-masking

# Write tests
# ... test code ...
# Run tests
git add <test files>
git commit -m "test: add tests for token masking"
git push origin feature/token-masking

# Update dependent code
# ... code ...
# Run tests
git add <files>
git commit -m "feat: integrate token masking in main workflow"
git push origin feature/token-masking

# Task complete!
```

## What NOT to Commit

- ❌ Failing tests (fix them first!)
- ❌ Broken/non-compiling code
- ❌ Secrets or API keys
- ❌ Build artifacts or dependencies
- ❌ Personal configuration files
- ❌ Commented-out code blocks
- ❌ Debug statements (unless intentional)

## Branch Strategy

### Main Branches:
- `main` - Production-ready code
- `develop` - Integration branch (if used)

### Feature Branches:
- Create from `main` or `develop`
- Name format: `feature/description` or `fix/description`
- Keep branches short-lived (1-3 days max)
- Delete after merging

### Example:
```bash
git checkout main
git pull origin main
git checkout -b feature/dynamic-categories
# ... work and commit frequently ...
git push origin feature/dynamic-categories
# Create PR when ready
```

## Before Pushing Checklist

- [ ] All tests pass
- [ ] Code compiles without errors
- [ ] No console errors or warnings
- [ ] Commit message is descriptive
- [ ] No secrets or sensitive data included
- [ ] Changes are related and logical

## Integration with Task Workflow

### During Task Execution:

1. **Start task** → Create feature branch (if needed)
2. **Write code** → Commit small increments
3. **Write tests** → Commit tests separately
4. **Fix issues** → Commit fixes
5. **All tests pass** → Final commit and push
6. **Mark task complete** → Ensure all work is pushed

### Never:

- ❌ Complete a task without pushing code
- ❌ Move to next task with unpushed changes
- ❌ End work session without pushing
- ❌ Leave work uncommitted overnight

## Summary

**The Golden Rule:** Commit early, commit often, push regularly.

Small, frequent commits with clear messages create a better development experience and safer codebase than large, infrequent commits.
