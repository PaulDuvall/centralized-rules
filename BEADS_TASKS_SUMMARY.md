# Beads Tasks Summary: skill-rules.json Improvements

**Created:** 2025-12-20
**Total Tasks:** 24
**Reconciles:** Deep analysis + user feedback recommendations

## Quick Start

```bash
# Make script executable
chmod +x beads-tasks-skill-rules-improvements.sh

# Create all tasks
./beads-tasks-skill-rules-improvements.sh

# Verify tasks were created
bd list --status open | grep "skill-rules" | wc -l
# Expected: 24 tasks

# View ready tasks
bd ready --json
```

---

## Task Organization by Phase

### Phase 1: Critical Fixes (P0-P1) - 4 Tasks

**Priority:** Must complete first - fixes bugs and prevents false positives

| Task | Type | Description | Reconciles |
|------|------|-------------|------------|
| Fix regex patterns in intentPatterns | Bug | Add word boundaries, fix fix_bug pattern, add case-insensitive flags | User feedback |
| Add exclusion patterns | Feature | Prevent 'test data' from triggering testing rules | User feedback |
| Implement priority/weight system | Feature | Resolve conflicts when multiple rules match | User feedback |
| Deduplicate slash commands | Task | Remove from keywords arrays, keep only in slashCommands | User feedback |

**Estimated effort:** 4-6 hours
**Impact:** Prevents incorrect rule activation, improves accuracy

---

### Phase 2: High-Priority Additions (P1) - 6 Tasks

**Priority:** Most commonly used technologies found in rules

| Task | Type | Description | Technologies | Source |
|------|------|-------------|--------------|--------|
| Add modern testing frameworks | Feature | Vitest, Playwright, Cypress, MSW, Testing Library | 10+ tools | Analysis + rules |
| Add Vite and build tools | Feature | Vite, Turborepo, Nx, pnpm | 4 tools | Analysis + rules |
| Add Docker/Kubernetes | Feature | Docker, Kubernetes, Ansible | 3 tools | **Both** (overlap) |
| Enhance React ecosystem | Feature | React Query, Router, Hook Form, Tailwind, Storybook | 15+ tools | Analysis + rules |
| Add data validation | Feature | Zod, Joi, Yup | 3 tools | Analysis + rules |
| Add database/ORM tools | Feature | Prisma, Redis, Celery, SQL databases | 6+ tools | **Both** (overlap) |

**Estimated effort:** 8-12 hours
**Impact:** Covers 50+ most frequently used tools

---

### Phase 3: Medium-Priority Additions (P2) - 6 Tasks

**Priority:** Extend framework and API support

| Task | Type | Description | Technologies | Source |
|------|------|-------------|--------------|--------|
| Add GraphQL and API tech | Feature | GraphQL, gRPC, tRPC, OpenAPI | 4 tools | Analysis + rules |
| Add Vue/Nuxt/Svelte | Feature | Vue, Nuxt, Svelte, Astro | 4 frameworks | Analysis |
| Add Go/Rust frameworks | Feature | Gin, Fiber, Actix, Rocket | 4 frameworks | Analysis + rules |
| Enhance Next.js keywords | Feature | App Router, Server Components, ISR, Edge | 11+ keywords | Analysis + rules |
| Add message queues | Feature | Celery, RabbitMQ, Bull | 3 tools | Analysis + rules |
| Add doc/performance intents | Feature | Documentation and performance intent patterns | 2 patterns | User feedback |

**Estimated effort:** 6-8 hours
**Impact:** Broader framework coverage, modern patterns

---

### Phase 4: Structural Improvements (P2-P3) - 4 Tasks

**Priority:** Enhance robustness and intelligence

| Task | Type | Description | Benefit | Source |
|------|------|-------------|---------|--------|
| Add metadata fields | Feature | priority, aliases, contextRequired | Smarter rule loading | Analysis |
| Add fallback detection | Feature | Strategy for multiple/no framework matches | Handles edge cases | User feedback |
| Add context decay | Feature | Expire keywords from old conversation turns | Multi-turn accuracy | User feedback |
| Add .mjs/.cjs detection | Bug | Modern JavaScript module formats | Better JS detection | User feedback |

**Estimated effort:** 4-6 hours
**Impact:** More intelligent rule activation

---

### Phase 5: Cleanup & Optimization (P3) - 3 Tasks

**Priority:** Nice to have, improves maintainability

| Task | Type | Description | Source |
|------|------|-------------|--------|
| Consolidate beads keywords | Task | Remove redundant aliases | Analysis |
| Enhance CI/CD keywords | Feature | GitLab CI, Jenkins, CircleCI | User feedback |
| Add linting/formatting slash commands | Feature | /xlint, /xformat | Analysis |

**Estimated effort:** 2-3 hours
**Impact:** Cleaner configuration, better CI/CD support

---

### Phase 6: Verification (P2) - 1 Task

**Priority:** Complete after all implementations

| Task | Type | Description | Blocks |
|------|------|-------------|--------|
| Create test suite | Task | Validate all changes work correctly | All implementation tasks |

**Estimated effort:** 4-6 hours
**Impact:** Ensures quality and prevents regressions

---

## Reconciliation Summary

### Overlap Resolution

**Both analyses identified these gaps:**

1. **Infrastructure tools** (Docker, Kubernetes)
   - **Resolution:** Single task covering both (Phase 2, Task 7)

2. **Database tools** (general + specific ORMs)
   - **Resolution:** Single task with both generic and specific keywords (Phase 2, Task 10)

3. **Structural improvements** (priority systems)
   - **Resolution:** Separated into distinct tasks:
     - Priority/weight system (Phase 1, Task 3)
     - Metadata fields (Phase 4, Task 17)

### Unique Contributions

**From Deep Analysis:**
- 50+ specific technology mappings with exact locations in rules
- React ecosystem enhancements
- Frontend framework expansion (Vue, Svelte, etc.)
- Backend framework additions (Gin, Actix)
- ORM-specific mappings

**From User Feedback:**
- Regex improvements (word boundaries, escaping)
- Exclusion patterns
- Context decay mechanism
- Fallback detection strategy
- File extension additions (.mjs, .cjs)

---

## Execution Strategy

### Recommended Order

```bash
# Week 1: Critical Fixes + Testing Foundations
Phase 1: Tasks 1-4 (Critical fixes)
Phase 2: Task 5 (Modern testing frameworks)

# Week 2: High-Impact Additions
Phase 2: Tasks 6-10 (Build tools, React, validation, databases)

# Week 3: Framework Expansion
Phase 3: Tasks 11-16 (APIs, frameworks, performance)

# Week 4: Polish & Verify
Phase 4: Tasks 17-20 (Structural improvements)
Phase 5: Tasks 21-23 (Cleanup)
Phase 6: Task 24 (Testing)
```

### Parallel Work Opportunities

**Can work simultaneously:**
- Regex fixes (Task 1) + Testing frameworks (Task 5)
- React enhancements (Task 8) + Next.js enhancements (Task 14)
- Infrastructure (Task 7) + Database (Task 10)

**Must be sequential:**
- All implementation tasks → Testing (Task 24)
- Priority system (Task 3) → Metadata fields (Task 17)

---

## Verification Checklist

After running the script, verify:

```bash
# ✅ Check all tasks created
bd list --status open | grep -E "(regex|exclusion|priority|testing|vite|docker|react|validation|database)" | wc -l
# Expected: 24

# ✅ Check priority distribution
bd list --json | jq '.issues[] | select(.status=="open") | .priority' | sort | uniq -c
# Expected:
#   7 tasks at P1
#   10 tasks at P2
#   7 tasks at P3

# ✅ Check task types
bd list --json | jq '.issues[] | select(.status=="open") | .type' | sort | uniq -c
# Expected:
#   2 bugs (regex fixes, .mjs/.cjs)
#   18 features
#   4 tasks

# ✅ Verify detailed descriptions exist
bd show <task-id> --json | jq -r '.description' | wc -l
# Expected: > 10 lines per task
```

---

## Benefits Summary

### Accuracy Improvements
- ✅ Word boundary regex prevents false positives
- ✅ Exclusion patterns filter out noise
- ✅ Priority system resolves conflicts
- ✅ Context decay improves multi-turn accuracy

### Coverage Improvements
- ✅ 50+ new technologies from actual rule files
- ✅ Modern testing tools (Vitest, Playwright)
- ✅ Build tools and monorepo managers
- ✅ Infrastructure and DevOps tools
- ✅ Modern frontend frameworks
- ✅ API technologies (GraphQL, tRPC)

### Intelligence Improvements
- ✅ Metadata fields enable smarter loading
- ✅ Fallback detection handles edge cases
- ✅ Context-aware file detection
- ✅ Better multi-turn conversation handling

### Maintainability Improvements
- ✅ Removed redundant entries
- ✅ Consistent structure
- ✅ Comprehensive test coverage
- ✅ Clear documentation

---

## File Modifications

**Primary file:** `.claude/skills/skill-rules.json`

**Estimated changes:**
- **Lines added:** ~500-700
- **Sections modified:** 8 major sections
- **New sections:** 5 (tools, database, infrastructure, async, api)
- **Keywords added:** ~200+
- **JSON size increase:** ~30-40%

**Backup recommended:**
```bash
cp .claude/skills/skill-rules.json .claude/skills/skill-rules.json.backup
```

---

## Success Metrics

After implementation, measure:

1. **Keyword match rate:** % of prompts that trigger relevant rules
2. **False positive rate:** % of incorrect rule activations (should decrease)
3. **Coverage:** % of technologies in rules that have keyword mappings (target: 90%+)
4. **Response quality:** Subjective improvement in rule activation accuracy

**Baseline (current):**
- Coverage: ~40% (20/50 major technologies)
- False positives: Moderate (regex issues)

**Target (after implementation):**
- Coverage: 90%+ (45/50 major technologies)
- False positives: Low (fixed regex, exclusions)

---

## Questions & Considerations

### Open Questions

1. **Token budget impact:** How much will 500+ new lines affect context usage?
   - **Mitigation:** Use priority fields to selectively load rules

2. **Maintenance burden:** Who updates when new frameworks emerge?
   - **Solution:** Add to contributing guidelines

3. **Testing strategy:** How to validate regex patterns at scale?
   - **Solution:** Task 24 creates comprehensive test suite

### Trade-offs

**Pro: Comprehensive coverage**
- ✅ Detects wide range of technologies
- ✅ Reduces "why didn't my rule load?" confusion

**Con: Larger configuration file**
- ❌ More lines to maintain
- ❌ Slightly slower parsing (negligible)

**Decision:** Benefits outweigh costs - better to have comprehensive coverage with smart loading.

---

## Next Steps

1. **Review tasks:** Read through all 24 task descriptions
2. **Run script:** Execute `./beads-tasks-skill-rules-improvements.sh`
3. **Verify creation:** Check all tasks appear in `bd list`
4. **Prioritize:** Decide which phase to start with
5. **Claim work:** `bd update <task-id> --status in_progress --json`
6. **Implement:** Follow task descriptions
7. **Test:** Run validation suite (Task 24)
8. **Document:** Update README with new capabilities

---

## Support & Context

**Related files:**
- `.claude/skills/skill-rules.json` - Main configuration
- `skill/src/config/detection-patterns.json` - TypeScript implementation
- `docs/slash-command-detection.md` - Detection documentation
- `ARCHITECTURE.md` - System design

**Reference rules:**
- `base/testing-philosophy.md`
- `frameworks/react/best-practices.md`
- `languages/typescript/testing.md`
- `cloud/vercel/deployment-best-practices.md`

---

**Total estimated effort:** 28-41 hours
**Complexity:** Medium-High
**Risk:** Low (all changes are additive, easily reversible)
**Impact:** High (major improvement in rule activation accuracy)
