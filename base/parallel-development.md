# Parallel Development with AI Assistants

> **When to apply:** All AI-assisted development workflows
> **Maturity Level:** All levels (MVP, Pre-Production, Production)

Leverage multiple AI assistants working on different tasks simultaneously to maximize development velocity while maintaining quality and coherence.

## Core Principles

### 1. Independence is Key

Tasks must be genuinely independent with minimal file overlap and clear interface contracts.

**Good: Independent Tasks**
```yaml
Task 1: Add user authentication API
Task 2: Build product recommendation engine
Task 3: Create admin dashboard UI
Task 4: Set up monitoring infrastructure
```

**Bad: Dependent Tasks**
```yaml
Task 1: Design database schema
Task 2: Implement database access layer  # DEPENDS ON TASK 1
Task 3: Build API using database layer   # DEPENDS ON TASK 2
```

### 2. Essential Requirements

| Requirement | Description |
|-------------|-------------|
| Well-defined scope | Clear deliverables and boundaries |
| Minimal file overlap | Distinct file ownership per task |
| Interface contracts | Agreed-upon APIs before work begins |
| Independent tests | Self-contained test coverage |
| Small tasks | 1-4 hours, 3-10 files maximum |

### 3. Merge Early, Merge Often

- Keep tasks small (< 4 hours each)
- Merge completed tasks immediately
- Test integration continuously
- Resolve conflicts early

## Task Decomposition Strategies

### By Layer/Component

```yaml
Feature: User profile management

Task A: Database layer
  Files: src/database/user_profile.py, tests/database/test_user_profile.py
  Interface: UserProfileDB class (CRUD)

Task B: API layer (after Task A)
  Files: src/api/user_profile.py, tests/api/test_user_profile.py
  Interface: REST endpoints /users, /users/{id}

Task C: UI layer (after Task B)
  Files: src/components/ProfilePage.tsx, ProfileForm.tsx
  Interface: React components
```

### By Feature

```yaml
Epic: E-commerce checkout

Task 1: Shopping cart (src/cart/*, tests/cart/*)
Task 2: Payment processing (src/payments/*, tests/payments/*)
Task 3: Order confirmation (src/orders/*, tests/orders/*)
Task 4: Inventory management (src/inventory/*, tests/inventory/*)

# All independent, integrate via checkout coordinator
```

### By Workflow Phase

```yaml
Phase 1 (Sequential): Foundation - Define interfaces
Phase 2 (Parallel): Core components - Build modules
Phase 3 (Sequential): Integration - Connect components
Phase 4 (Parallel): Enhancements - Add features
```

### Task Size Guidelines

| Size | Duration | Files | Risk | Action |
|------|----------|-------|------|--------|
| Too small | < 30 min | 1 file | Low | Combine with other tasks |
| Ideal | 1-4 hours | 3-10 files | Low-Medium | Perfect for parallel work |
| Too large | > 8 hours | 10+ files | High | Break down further |

## Coordination Strategies

### 1. Interface-First Development

Define interfaces before parallel work begins:

```typescript
// interfaces/user-service.ts - DEFINED FIRST

export interface UserService {
  createUser(data: CreateUserDTO): Promise<User>;
  getUser(id: string): Promise<User | null>;
  updateUser(id: string, data: UpdateUserDTO): Promise<User>;
  deleteUser(id: string): Promise<void>;
}

// Now parallel tasks implement this contract:
// Task A: UserService with database
// Task B: API endpoints using UserService
// Task C: UI components using API
// Task D: Integration tests
```

### 2. Branch Strategy

```bash
git checkout main

# Create parallel branches
git checkout -b feature/user-authentication
git checkout -b feature/product-recommendations
git checkout -b feature/admin-dashboard

# Each AI assistant works on separate branch
# Merge to main when complete and tested
```

### 3. Communication Protocol

Maintain a shared tracker:

```markdown
# Parallel Development Tracker

## Active Tasks
- [Task A] User authentication (feature/auth, Claude 1, ETA: 2h)
  - Files: src/auth/*, tests/auth/*
- [Task B] Recommendations (feature/recommendations, Claude 2, ETA: 1h)
  - Files: src/recommendations/*, tests/recommendations/*

## Interface Contracts
- Auth Service: src/interfaces/auth-service.ts
- Recommendation Engine: src/interfaces/recommender.ts

## Shared Standards
- Error handling: src/utils/errors.ts
- Validation: Zod
- Testing: Vitest
```

## Merge Strategies

| Strategy | Approach | Pros | Cons |
|----------|----------|------|------|
| Sequential | Merge one task at a time | Easy to debug issues | Slower, later tasks get conflicts |
| Integration Branch | Merge all to integration branch first | Test together before main | Complex if issues found |
| Feature Flags | Merge incomplete behind flags | Continuous integration | Added complexity, cleanup needed |

### Sequential Merging Pattern

```bash
git checkout main && git merge feature/task-a && npm test && git push
git checkout feature/task-b && git rebase main && npm test
git checkout main && git merge feature/task-b && git push
```

### Integration Branch Pattern

```bash
git checkout -b integration/feature-set main
git merge feature/task-a && git merge feature/task-b
npm test && npm run e2e-test
git checkout main && git merge integration/feature-set --ff-only
```

## Quality Control

### Pre-Merge Checklist

```yaml
Code Quality:
  - [ ] All tests pass (unit + integration)
  - [ ] Lint and type checks pass
  - [ ] Code review completed
  - [ ] Documentation updated

Integration:
  - [ ] Rebased on latest main
  - [ ] Conflicts resolved
  - [ ] Interfaces match contracts
  - [ ] No breaking changes to shared code

Coordination:
  - [ ] Tracker updated
  - [ ] Other task owners notified
```

### Integration Testing

```typescript
// tests/integration/parallel-features.test.ts
describe('Integration: Parallel Features', () => {
  it('should integrate authentication and recommendations', async () => {
    // Task A: Authentication
    const user = await createUser({ email: 'test@example.com', password: 'secure123' });
    const session = await login('test@example.com', 'secure123');

    // Task B: Recommendations (using authenticated session)
    const recommendations = await getRecommendations(session.userId);

    expect(recommendations).toHaveLength(10);
    expect(recommendations[0]).toHaveProperty('productId');
  });
});
```

### CI Pipeline

```yaml
# .github/workflows/parallel-tasks.yml
name: Parallel Task Validation
on:
  push:
    branches: ['feature/**']

jobs:
  validate-task:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: npm ci
      - run: npm run lint && npm run type-check && npm test
      - name: Check interface changes
        run: git diff main...HEAD --name-only | grep "src/interfaces/" && exit 1 || exit 0
      - name: Test merge
        run: git fetch origin main && git merge origin/main --no-commit && npm test
```

## Anti-Patterns

### 1. Parallel Work on Same Files

| Bad | Good |
|-----|------|
| Task A: Add auth to src/app.ts<br>Task B: Add logging to src/app.ts<br>Task C: Add rate limiting to src/app.ts | Task A: Create src/middleware/auth.ts<br>Task B: Create src/middleware/logging.ts<br>Task C: Create src/middleware/rate-limit.ts<br>Final: Import all in src/app.ts |

### 2. Undefined Interfaces

**Problem:** Starting parallel work without agreed contracts leads to incompatible implementations.

**Solution:** Define interfaces first, then implement in parallel.

```typescript
// DEFINE FIRST
interface UserService {
  getUserById(id: string): Promise<User>;
  getUserByEmail(email: string): Promise<User | null>;
}
// Both parallel tasks implement this interface
```

### 3. Long-Lived Branches

| Bad | Good |
|-----|------|
| Branch created Monday<br>Work continues 4 days<br>Merge Friday with massive conflicts | Monday: Create branch, complete task, merge<br>Tuesday: New branch, complete, merge<br>Daily merges = minimal conflicts |

### 4. Ignoring Merge Conflicts

**Don't:** Accept "theirs" or "ours" blindly

**Do:** Understand both changes and merge thoughtfully

```typescript
// Understand both changes, combine if needed
function calculateTotal(items) {
  return items.reduce((sum, item) => {
    const itemTotal = item.price * (item.quantity || 1);  // From task-b
    const itemWithTax = itemTotal * (1 + item.taxRate);    // From HEAD
    return sum + itemWithTax;
  }, 0);
}
```

### 5. Skipping Integration Tests

| Risk | Solution |
|------|----------|
| Tasks pass individually but fail together | Run full test suite after merging |
| Components don't communicate | Add integration tests |
| User workflows broken | Manual end-to-end testing |

## Comparison: Serial vs Parallel

| Aspect | Serial Development | Parallel Development |
|--------|-------------------|---------------------|
| Time | Task1 → Task2 → Task3 (16h) | All tasks simultaneously (4h + merge) |
| Context switching | Frequent | Minimal (one focus per session) |
| Merge conflicts | Rare | Requires management |
| Debugging | Simpler | Isolated changes easier to test |
| Coordination | None needed | Clear boundaries essential |

---

## Related Resources

- `base/ai-assisted-development.md` - General AI development practices
- `base/testing-philosophy.md` - Testing strategies
- `base/refactoring-patterns.md` - Managing technical debt
- `base/tool-design.md` - Designing modular systems

**Remember:** Parallel development accelerates delivery but requires discipline. Clear boundaries, early merging, and integration testing are essential for success.
