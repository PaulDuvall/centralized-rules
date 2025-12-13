# Parallel Development with AI Assistants

> **When to apply:** All AI-assisted development workflows
> **Maturity Level:** All levels (MVP, Pre-Production, Production)

Leverage multiple AI assistants working on different tasks simultaneously to maximize development velocity while maintaining quality and coherence.

## Table of Contents

- [Overview](#overview)
- [Core Principles](#core-principles)
- [Task Decomposition](#task-decomposition)
- [Coordination Strategies](#coordination-strategies)
- [Merge Strategies](#merge-strategies)
- [Quality Control](#quality-control)
- [Anti-Patterns](#anti-patterns)

---

## Overview

### What is Parallel Development?

**Parallel development** means working on multiple independent tasks simultaneously, often with different AI assistants or sessions, then integrating the results.

**Traditional Serial Development:**
```
Task 1 → Task 2 → Task 3 → Task 4 (16 hours total)
```

**Parallel Development:**
```
Task 1 → Merge
Task 2 → Merge   (4 hours total + merge time)
Task 3 → Merge
Task 4 → Merge
```

**Benefits:**
- **Faster delivery** - Complete multiple tasks simultaneously
- **Reduced context switching** - Each session focuses on one concern
- **Better separation of concerns** - Clean boundaries between tasks
- **Easier debugging** - Isolated changes are easier to test

**Challenges:**
- **Merge conflicts** - Changes may overlap
- **Integration complexity** - Pieces must work together
- **Coordination overhead** - Need clear task boundaries
- **Quality control** - Ensuring consistency across parallel work

---

## Core Principles

### 1. Independence is Key

**Good: Independent Tasks**
```yaml
Parallel Task 1: Add user authentication API
Parallel Task 2: Build product recommendation engine
Parallel Task 3: Create admin dashboard UI
Parallel Task 4: Set up monitoring infrastructure

# These can be developed completely independently
# Minimal overlap in files or logic
```

**Bad: Dependent Tasks**
```yaml
Parallel Task 1: Design database schema
Parallel Task 2: Implement database access layer  # DEPENDS ON TASK 1
Parallel Task 3: Build API using database layer    # DEPENDS ON TASK 2

# These MUST be done sequentially, not in parallel
```

### 2. Clear Boundaries

**Each parallel task should have:**
- ✅ Well-defined scope and deliverables
- ✅ Minimal file overlap with other tasks
- ✅ Clear interface contracts
- ✅ Independent test coverage
- ✅ Self-contained changes

### 3. Merge Early, Merge Often

**Don't:**
- Work in isolation for days/weeks
- Build up massive changesets
- Defer integration testing

**Do:**
- Merge completed tasks immediately
- Keep tasks small (< 4 hours each)
- Test integration continuously
- Resolve conflicts early

### 4. Maintain Coherence

**Ensure consistency across parallel work:**
- Coding style and patterns
- API design conventions
- Testing approach
- Documentation format
- Naming conventions

---

## Task Decomposition

### How to Split Work for Parallel Development

#### Strategy 1: By Layer/Component

```yaml
Feature: User profile management

Parallel Tasks:
  Task A: "Database layer - User profile CRUD operations"
    Files: src/database/user_profile.py, tests/database/test_user_profile.py
    Interface: UserProfileDB class with create/read/update/delete methods

  Task B: "API layer - User profile endpoints"
    Files: src/api/user_profile.py, tests/api/test_user_profile.py
    Interface: REST endpoints /users, /users/{id}
    Depends on: Task A interface contract

  Task C: "UI layer - Profile page components"
    Files: src/components/ProfilePage.tsx, src/components/ProfileForm.tsx
    Interface: React components
    Depends on: Task B API contract

# Task A completed first, B and C can then proceed in parallel
```

#### Strategy 2: By Feature

```yaml
Epic: E-commerce checkout flow

Parallel Tasks:
  Task 1: "Shopping cart management"
    Scope: Add/remove items, update quantities, cart persistence
    Files: src/cart/*, tests/cart/*

  Task 2: "Payment processing integration"
    Scope: Stripe integration, payment validation, error handling
    Files: src/payments/*, tests/payments/*

  Task 3: "Order confirmation flow"
    Scope: Order summary, email notifications, order tracking
    Files: src/orders/*, tests/orders/*

  Task 4: "Inventory management"
    Scope: Stock checking, reservation, release on cancellation
    Files: src/inventory/*, tests/inventory/*

# All features are independent, integrate in final checkout coordinator
```

#### Strategy 3: By Workflow Phase

```yaml
New Feature: Content recommendation system

Phase 1 (Sequential): Foundation
  Task: Define data models and interfaces
  Deliverable: src/models/recommendation.py with type definitions

Phase 2 (Parallel): Core Components
  Task A: Data collection service
  Task B: ML model training pipeline
  Task C: Recommendation scoring engine
  Task D: Caching layer

Phase 3 (Sequential): Integration
  Task: Integrate components into unified API

Phase 4 (Parallel): Enhancements
  Task X: A/B testing framework
  Task Y: Performance monitoring
  Task Z: Admin dashboard
```

### Task Size Guidelines

**Ideal parallel task:**
- ⏱️ **Duration:** 1-4 hours of focused work
- 📄 **Scope:** 3-10 files modified
- 🧪 **Testing:** Self-contained test suite
- 🔀 **Conflicts:** Low risk of overlap with other tasks

**Too small:**
- < 30 minutes
- Single file, trivial change
- Overhead of task management exceeds value

**Too large:**
- > 8 hours
- Touches many files across codebase
- High risk of conflicts
- Consider breaking down further

---

## Coordination Strategies

### 1. Interface-First Development

**Define interfaces before parallel work begins:**

```typescript
// interfaces/user-service.ts
// DEFINED FIRST - All parallel tasks follow this contract

export interface UserService {
  createUser(data: CreateUserDTO): Promise<User>;
  getUser(id: string): Promise<User | null>;
  updateUser(id: string, data: UpdateUserDTO): Promise<User>;
  deleteUser(id: string): Promise<void>;
}

export interface CreateUserDTO {
  email: string;
  name: string;
  password: string;
}

export interface User {
  id: string;
  email: string;
  name: string;
  createdAt: Date;
  updatedAt: Date;
}
```

**Now parallel tasks can proceed:**
- Task A: Implement UserService with database
- Task B: Build API endpoints using UserService interface
- Task C: Create UI components using API client
- Task D: Write integration tests

### 2. Branch-Per-Task Strategy

```bash
# Main branch
git checkout main

# Create parallel feature branches
git checkout -b feature/user-authentication
git checkout -b feature/product-recommendations
git checkout -b feature/admin-dashboard
git checkout -b feature/monitoring-setup

# Each AI assistant works on separate branch
# Merge to main when complete and tested
```

### 3. Communication Protocol

**Shared context document:**

```markdown
# Parallel Development Tracker

## Active Tasks
- [Task A] User authentication (Branch: feature/auth, Owner: Claude Session 1)
  - Status: In Progress
  - Files: src/auth/*, tests/auth/*
  - ETA: 2 hours

- [Task B] Product recommendations (Branch: feature/recommendations, Owner: Claude Session 2)
  - Status: Testing
  - Files: src/recommendations/*, tests/recommendations/*
  - ETA: 1 hour

## Completed & Merged
- [Task 0] Database schema migration (Merged: 2025-12-13 10:00)

## Interface Contracts
- Auth Service: src/interfaces/auth-service.ts
- Recommendation Engine: src/interfaces/recommender.ts

## Shared Concerns
- All tasks use same error handling pattern (see src/utils/errors.ts)
- All tasks use Zod for validation
- All tests use Vitest
```

### 4. Dependency Management

**Lock files to prevent dependency conflicts:**

```bash
# Before starting parallel tasks
npm install  # Lock dependencies in package-lock.json
git add package-lock.json
git commit -m "Lock dependencies before parallel development"

# Each parallel task uses locked dependencies
# Avoids "works on my machine" issues during merge
```

---

## Merge Strategies

### 1. Sequential Merging

**Merge one task at a time:**

```bash
# Merge Task A first
git checkout main
git merge feature/task-a
npm test
git push

# Then merge Task B
git checkout feature/task-b
git rebase main  # Resolve any conflicts
npm test
git checkout main
git merge feature/task-b
git push

# Continue for remaining tasks
```

**Pros:**
- Easy to identify which merge introduced issues
- Can pause if problems arise

**Cons:**
- Slower than batch merging
- Later tasks may have more conflicts

### 2. Integration Branch

**Merge all parallel work to integration branch first:**

```bash
# Create integration branch
git checkout -b integration/feature-set-1 main

# Merge all parallel tasks
git merge feature/task-a
git merge feature/task-b
git merge feature/task-c
git merge feature/task-d

# Run comprehensive tests
npm test
npm run e2e-test

# If all tests pass, merge to main
git checkout main
git merge integration/feature-set-1 --ff-only
git push
```

**Pros:**
- Test all changes together before main
- Easier to identify integration issues

**Cons:**
- More complex if issues found
- Integration branch can become long-lived

### 3. Feature Flags

**Merge incomplete features behind flags:**

```typescript
// Merge Task A even if not fully complete
export function getRecommendations(userId: string) {
  if (featureFlags.isEnabled('new-recommendation-engine')) {
    return newRecommendationEngine.get(userId);  // Parallel Task A
  } else {
    return legacyRecommendations.get(userId);  // Existing code
  }
}

// Enable flag when all parallel tasks complete and integrate
```

**Pros:**
- Merge code continuously
- Reduce large merge complexity
- Control feature rollout independently

**Cons:**
- Added code complexity
- Need to clean up flags eventually

---

## Quality Control

### 1. Pre-Merge Checklist

**Before merging any parallel task:**

```yaml
Code Quality:
  - [ ] All tests pass (unit + integration)
  - [ ] Lint checks pass
  - [ ] Type checks pass (TypeScript)
  - [ ] Code review completed (human or AI)
  - [ ] No commented-out code or debug statements
  - [ ] Documentation updated

Integration:
  - [ ] Rebase on latest main
  - [ ] Resolve all merge conflicts
  - [ ] Run full test suite after merge
  - [ ] Verify interfaces match contracts
  - [ ] No breaking changes to shared code

Coordination:
  - [ ] Update parallel development tracker
  - [ ] Notify other parallel task owners
  - [ ] Check for dependency impacts
```

### 2. Integration Testing

**Test parallel tasks together:**

```typescript
// tests/integration/parallel-features.test.ts

describe('Integration: Parallel Features', () => {
  it('should allow user to authenticate and get recommendations', async () => {
    // Task A: Authentication
    const user = await createUser({
      email: 'test@example.com',
      password: 'secure123'
    });

    const session = await login('test@example.com', 'secure123');

    // Task B: Recommendations (using authenticated session)
    const recommendations = await getRecommendations(session.userId);

    expect(recommendations).toHaveLength(10);
    expect(recommendations[0]).toHaveProperty('productId');
  });

  it('should show recommendations in admin dashboard', async () => {
    // Task B: Recommendations
    const recommendations = await getRecommendations('user123');

    // Task C: Admin Dashboard
    const dashboard = await renderAdminDashboard();
    const recommendationWidget = dashboard.getWidget('recommendations');

    // Verify integration
    expect(recommendationWidget.data).toEqual(recommendations);
  });
});
```

### 3. Automated Validation

**CI pipeline for parallel branches:**

```yaml
# .github/workflows/parallel-tasks.yml

name: Parallel Task Validation

on:
  push:
    branches:
      - 'feature/**'

jobs:
  validate-task:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install dependencies
        run: npm ci

      - name: Run linting
        run: npm run lint

      - name: Run type checking
        run: npm run type-check

      - name: Run unit tests
        run: npm test

      - name: Check for interface changes
        run: |
          # Fail if shared interfaces modified without approval
          git diff main...HEAD --name-only | grep "src/interfaces/" && exit 1 || exit 0

      - name: Test merge with main
        run: |
          git fetch origin main
          git merge origin/main --no-commit --no-ff
          npm test  # Ensure tests still pass after merge

  integration-check:
    runs-on: ubuntu-latest
    needs: validate-task
    steps:
      - name: Create integration branch
        run: |
          git checkout -b test-integration
          git merge ${{ github.ref }}

      - name: Run integration tests
        run: npm run test:integration
```

---

## Anti-Patterns

### ❌ 1. Parallel Work on Same Files

**Problem:** Multiple tasks modifying the same file

```yaml
# BAD: High conflict risk
Task A: Add authentication to src/app.ts
Task B: Add logging to src/app.ts
Task C: Add rate limiting to src/app.ts

# Guaranteed merge conflicts in src/app.ts
```

**Solution:**
```yaml
# GOOD: Each task owns distinct files
Task A: Create src/middleware/auth.ts, import in src/app.ts
Task B: Create src/middleware/logging.ts, import in src/app.ts
Task C: Create src/middleware/rate-limit.ts, import in src/app.ts

# src/app.ts changes minimal and can be merged last
```

### ❌ 2. Undefined Interfaces

**Problem:** Starting parallel work without agreeing on contracts

```typescript
// Task A implementation
function getUser(userId) {  // Returns user object
  return database.query(`SELECT * FROM users WHERE id = ${userId}`);
}

// Task B implementation (incompatible!)
function getUser(email) {  // Expects email, not userId!
  return fetch(`/api/users?email=${email}`);
}

// Integration fails because signatures don't match
```

**Solution:**
```typescript
// DEFINE INTERFACES FIRST
interface UserService {
  getUserById(id: string): Promise<User>;
  getUserByEmail(email: string): Promise<User | null>;
}

// Both tasks implement this interface
```

### ❌ 3. Long-Lived Branches

**Problem:** Working in isolation for days/weeks

```bash
# Task A branch created Monday
# Task A continues development Tuesday, Wednesday, Thursday
# Task A finally merges Friday
# Result: Massive merge conflicts with main branch
```

**Solution:**
```bash
# Keep tasks small and merge frequently
# Monday: Create branch, complete Task A, merge same day
# Tuesday: Create new branch for Task B, complete and merge
# Daily merges = minimal conflicts
```

### ❌ 4. Ignoring Merge Conflicts

**Problem:** Accepting "theirs" or "ours" without understanding

```bash
# During merge
<<<<<<< HEAD
function calculateTotal(items) {
  return items.reduce((sum, item) => sum + item.price, 0);
}
=======
function calculateTotal(items) {
  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
}
>>>>>>> feature/task-b

# DON'T just accept one version without thinking
# Understand why both changes were made
# Combine them if necessary
```

**Solution:**
```typescript
// Understand both changes, merge thoughtfully
function calculateTotal(items) {
  return items.reduce((sum, item) => {
    // Feature/task-b added quantity support (keep this)
    const itemTotal = item.price * (item.quantity || 1);
    // HEAD had tax calculation (keep this too)
    const itemWithTax = itemTotal * (1 + item.taxRate);
    return sum + itemWithTax;
  }, 0);
}
```

### ❌ 5. Skipping Integration Tests

**Problem:** Only testing tasks in isolation

```yaml
# Task A: Authentication - tests pass ✅
# Task B: Recommendations - tests pass ✅
# Task C: Admin Dashboard - tests pass ✅

# Integration: Nothing works because components don't communicate ❌
```

**Solution:**
```yaml
# After merging parallel tasks:
- Run full test suite
- Add integration tests
- Manual end-to-end testing
- Verify user workflows work across components
```

---

## Related Resources

- See `base/ai-assisted-development.md` for general AI development practices
- See `base/testing-philosophy.md` for testing strategies
- See `base/refactoring-patterns.md` for managing technical debt from parallel work
- See `base/tool-design.md` for designing modular, parallel-friendly systems

---

**Remember:** Parallel development accelerates delivery but requires discipline. Clear boundaries, early merging, and integration testing are essential for success.
