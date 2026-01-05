# Git Workflow Guidelines

> **Scope:** All git operations across any project

## Maturity Requirements

| Practice | MVP/POC | Pre-Production | Production |
|----------|---------|----------------|------------|
| Frequent commits | Required | Required | Required |
| Conventional commit messages | Recommended | Required | Required |
| Branch protection | Optional | Required | Required |
| Required code reviews | Optional | Required (1 approval) | Required (2 approvals) |
| Automated commit hooks | Optional | Recommended | Required |
| GPG signed commits | Not needed | Optional | Recommended |

## Commit Frequency

**MANDATORY:** Commit and push code frequently throughout development, not just at task completion.

### When to Commit

- After completing a logical unit of work
- After writing a new function or component
- After fixing a bug or test
- After refactoring a section
- Before switching to different task
- At end of each work session
- When all tests pass for current changes

### Frequency Guidelines

- **Minimum:** Once per completed subtask
- **Recommended:** Every 15-30 minutes of active development
- **Best Practice:** After each meaningful change that passes tests

## Commit Message Format

### Structure
```
<type>: <short description>

<optional longer description>

<optional footer>
```

### Types
- `feat:` - New feature
- `fix:` - Bug fix
- `test:` - Adding or updating tests
- `refactor:` - Code refactoring
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting)
- `chore:` - Maintenance tasks
- `perf:` - Performance improvements

### Examples

```bash
# Good
git commit -m "feat: add token masking function"
git commit -m "test: add property tests for encryption"
git commit -m "fix: handle null values in validation logic"

# Bad
git commit -m "updates"
git commit -m "wip"
git commit -m "fix stuff"
```

## Push Frequency

- Push immediately after committing (preferred)
- Push at least once per hour during active development
- Always push before ending work session
- Push after completing subtask

## Development Workflow

```
1. Start task
2. Write code (small increment)
3. Run tests
4. Tests pass? → Commit
5. Push to remote
6. Repeat 2-5 until task complete
```

## What NOT to Commit

- ❌ Failing tests (fix them first)
- ❌ Broken/non-compiling code
- ❌ Secrets or API keys
- ❌ Build artifacts or dependencies
- ❌ Personal configuration files
- ❌ Commented-out code blocks
- ❌ Debug statements (unless intentional)

## Branch Strategy

### Main Branches
- `main` - Production-ready code
- `develop` - Integration branch (optional)

### Feature Branches
- Create from `main` or `develop`
- Name format: `feature/description` or `fix/description`
- Keep short-lived (1-3 days max)
- Delete after merging

```bash
git checkout main
git pull origin main
git checkout -b feature/dynamic-categories
# ... work and commit frequently ...
git push origin feature/dynamic-categories
# Create PR when ready
```

## Pre-Push Checklist

- [ ] All tests pass
- [ ] Code compiles without errors
- [ ] No console errors or warnings
- [ ] Commit message is descriptive
- [ ] No secrets or sensitive data included
- [ ] Changes are related and logical

## Integration with Tasks

### During Task Execution

1. **Start task** → Create feature branch (if needed)
2. **Write code** → Commit small increments
3. **Write tests** → Commit tests separately
4. **Fix issues** → Commit fixes
5. **All tests pass** → Final commit and push
6. **Mark task complete** → Ensure all work is pushed

### Never

- ❌ Complete task without pushing code
- ❌ Move to next task with unpushed changes
- ❌ End work session without pushing
- ❌ Leave work uncommitted overnight

## Summary

**Golden Rule:** Commit early, commit often, push regularly.

Small, frequent commits with clear messages create better development experience and safer codebase.
