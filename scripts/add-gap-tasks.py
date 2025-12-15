#!/usr/bin/env python3
"""
Add gap-focused implementation tasks to Beads based on comprehensive codebase analysis.
Only includes tasks for actual gaps, not already-completed work.

Analysis showed:
- Claude Skill: 92% complete (needs tests)
- Sync Script: 65% complete (needs tool formats, integration)
- Audit Agent: 78% complete (needs Beads integration)
- Beads Integration: 35% complete (needs most features)
- Progressive Disclosure: 62% complete (needs docs)
"""
import json
from datetime import datetime, timezone

def create_timestamp():
    return datetime.now(timezone.utc).isoformat()

tasks = [
    # ========== PHASE 1: FOUNDATION (5 tasks, 26 hours) ==========
    {
        'id': 'centralized-rules-gap-r001',
        'title': 'Integrate AI tool auto-detection into sync script main flow',
        'description': '''**Scope:** Auto-detect AI tools and generate outputs without requiring --tool flag
**Effort:** Small (4 hours)
**Gap:** detect-ai-tools.sh exists but not integrated into sync-ai-rules.sh main workflow

## What's Missing
- Auto-detection not called in main sync flow
- --only-detected flag not implemented
- Verbose mode showing detection reasoning missing
- Fallback to all tools when none detected not present

## Steps
1. Call detect-ai-tools.sh from sync-ai-rules.sh main flow
2. Add --only-detected flag to limit to detected tools
3. Implement verbose mode with detection reasoning
4. Add fallback to all common tools when none detected
5. Update help/usage text

## Acceptance Criteria
- WHEN sync runs without flags, THEN auto-detect AI tools
- WHEN --only-detected used, THEN sync only detected tools
- WHEN --verbose used, THEN show detection reasoning
- WHEN no tools detected, THEN fallback to all common tools''',
        'status': 'open',
        'priority': 2,
        'issue_type': 'task',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },
    {
        'id': 'centralized-rules-gap-r002',
        'title': 'Generate tool-specific output formats (Cursor, Copilot, Gemini)',
        'description': '''**Scope:** Implement output generation for Cursor, Copilot, Continue.dev, Windsurf, Cody, Gemini
**Effort:** Medium (8 hours)
**Gap:** Only Claude hierarchical format implemented, other formats missing

## What's Missing
- Cursor .cursorrules generation incomplete
- Copilot .github/copilot-instructions.md generation incomplete
- Continue.dev, Windsurf, Cody, Gemini formats not implemented
- Monolithic .claude/RULES.md fallback not working

## Steps
1. Implement Cursor .cursorrules generator (concatenated format)
2. Build Copilot .github/copilot-instructions.md generator
3. Add Continue.dev plugin format generator
4. Create Windsurf, Cody, Gemini format generators
5. Implement monolithic .claude/RULES.md fallback

## Acceptance Criteria
- WHEN Cursor detected, THEN generate .cursorrules file
- WHEN Copilot detected, THEN generate .github/copilot-instructions.md
- WHEN Continue.dev detected, THEN generate plugin format
- WHEN other tools detected, THEN generate appropriate formats
- WHEN --monolithic flag used, THEN generate .claude/RULES.md''',
        'status': 'open',
        'priority': 2,
        'issue_type': 'task',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },
    {
        'id': 'centralized-rules-gap-r003',
        'title': 'Enhance sync script error handling',
        'description': '''**Scope:** Add network retry, rate limit detection, permission guidance
**Effort:** Small (4 hours)
**Gap:** Basic colored output exists, comprehensive error handling missing

## What's Missing
- Network error retry suggestions not present
- GitHub rate limit detection and GITHUB_TOKEN guidance missing
- File permission error explanations missing
- sync-config.json schema validation not implemented

## Steps
1. Add network error detection with retry suggestions
2. Implement GitHub rate limit detection with GITHUB_TOKEN setup guidance
3. Create file permission error handler with fix commands
4. Build sync-config.json schema validator
5. Enhance help/usage documentation

## Acceptance Criteria
- WHEN network fails, THEN show retry suggestions
- WHEN rate limited, THEN show GITHUB_TOKEN setup instructions
- WHEN permission denied, THEN show chmod commands
- WHEN sync-config.json invalid, THEN show specific errors''',
        'status': 'open',
        'priority': 2,
        'issue_type': 'task',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },
    {
        'id': 'centralized-rules-gap-r004',
        'title': 'Create sync script test suite',
        'description': '''**Scope:** Shell script tests for AI detection, project detection, output generation
**Effort:** Medium (6 hours)
**Gap:** No tests exist for sync-ai-rules.sh

## Steps
1. Set up shell script testing framework (bats or shunit2)
2. Write tests for AI tool detection with mock filesystems
3. Create tests for project detection (Python+FastAPI, TypeScript+React, Go+Gin)
4. Build tests for all tool-specific output formats
5. Add E2E test with full sync workflow

## Acceptance Criteria
- WHEN tests run, THEN AI tool detection cases pass (7 tools)
- WHEN tests run, THEN project detection achieves 95%/90% accuracy
- WHEN tests run, THEN all 7 output formats validate
- WHEN E2E test runs, THEN complete sync succeeds
- WHEN tests run in CI, THEN add to GitHub Actions workflow''',
        'status': 'open',
        'priority': 2,
        'issue_type': 'task',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },
    {
        'id': 'centralized-rules-gap-r005',
        'title': 'Document progressive disclosure pattern',
        'description': '''**Scope:** Create design document for progressive disclosure as architectural pattern
**Effort:** Small (4 hours)
**Gap:** Spec file exists but is empty (1 line)

## Steps
1. Document progressive disclosure pattern definition
2. Explain context detection → intent analysis → rule selection flow
3. Define token budget management best practices
4. Provide implementation examples from Claude Skill and Audit Agent
5. Create decision tree for when to apply pattern

## Acceptance Criteria
- WHEN developer reads spec, THEN understand progressive disclosure concept
- WHEN implementing feature, THEN apply pattern correctly
- WHEN managing tokens, THEN follow budget principles (5000 token max)
- WHEN planning feature, THEN use decision tree''',
        'status': 'open',
        'priority': 3,
        'issue_type': 'documentation',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },

    # ========== PHASE 2: TESTING & VALIDATION (6 tasks, 40 hours) ==========
    {
        'id': 'centralized-rules-gap-r006',
        'title': 'Write Claude Skill unit tests',
        'description': '''**Scope:** Tests for context detection, intent analysis, rule scoring, caching
**Effort:** Medium (8 hours)
**Gap:** Test fixtures exist in skill/tests/fixtures/ but no actual test files

## Steps
1. Set up Jest testing framework for TypeScript skill
2. Write unit tests for context detection (language/framework/cloud/maturity)
3. Create tests for user intent analysis (topics, action, urgency)
4. Build tests for rule scoring algorithm (all weight combinations)
5. Add tests for caching (LRU eviction, TTL expiration, hit/miss)

## Acceptance Criteria
- WHEN tests run, THEN achieve 85%+ code coverage
- WHEN testing language detection, THEN verify 95% accuracy
- WHEN testing framework detection, THEN verify 90% accuracy
- WHEN testing scoring, THEN verify weighted algorithm (100/100/75/50/30/25)
- WHEN testing cache, THEN verify LRU eviction and TTL expiration''',
        'status': 'open',
        'priority': 1,
        'issue_type': 'task',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },
    {
        'id': 'centralized-rules-gap-r007',
        'title': 'Write Claude Skill integration tests',
        'description': '''**Scope:** E2E hook execution tests for Python+FastAPI, TypeScript+React, Go+Gin
**Effort:** Medium (8 hours)
**Gap:** No integration tests exist

## Steps
1. Create mock GitHub API for consistent testing
2. Build E2E test for Python+FastAPI project (security fix intent)
3. Add E2E test for TypeScript+React project (new feature intent)
4. Create E2E test for Go+Gin project (refactoring intent)
5. Validate 3-second hook execution performance target

## Acceptance Criteria
- WHEN E2E test runs for Python+FastAPI, THEN select Python/FastAPI/security rules
- WHEN E2E test runs for TypeScript+React, THEN select TypeScript/React/feature rules
- WHEN E2E test runs for Go+Gin, THEN select Go/Gin/refactoring rules
- WHEN tests run, THEN hook execution < 3 seconds
- WHEN tests run, THEN achieve 85%+ total coverage''',
        'status': 'open',
        'priority': 1,
        'issue_type': 'task',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },
    {
        'id': 'centralized-rules-gap-r008',
        'title': 'Create Claude Skill performance benchmarks',
        'description': '''**Scope:** Benchmark hook execution, cache performance, GitHub fetches
**Effort:** Small (4 hours)
**Gap:** No performance benchmarks exist

## Steps
1. Build benchmark for beforeResponse hook (target < 3s)
2. Create benchmark for cache hit latency (target < 10ms)
3. Add benchmark for GitHub fetch time (target < 2s per rule)
4. Build benchmark for rule selection algorithm latency
5. Create performance regression test suite for CI

## Acceptance Criteria
- WHEN benchmarking hook, THEN verify < 3 seconds (99th percentile)
- WHEN benchmarking cache hits, THEN verify < 10ms (99th percentile)
- WHEN benchmarking GitHub fetches, THEN verify < 2 seconds per rule
- WHEN running regression tests, THEN detect performance degradation''',
        'status': 'open',
        'priority': 2,
        'issue_type': 'task',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },
    {
        'id': 'centralized-rules-gap-r009',
        'title': 'Validate 21 Claude Skill design properties',
        'description': '''**Scope:** Automated validation script for all design properties from spec
**Effort:** Medium (6 hours)
**Gap:** No validation script exists for 21 design properties from .kiro/specs/claude-skill-completion/design.md

## Steps
1. Create validation script for language detection (95% accuracy)
2. Add validation for framework detection (90% accuracy)
3. Build validation for hook execution performance (< 3s)
4. Add validation for cache hit performance (< 10ms)
5. Implement validation for all 21 design properties

## Acceptance Criteria
- WHEN validating, THEN language detection achieves 95% accuracy
- WHEN validating, THEN framework detection achieves 90% accuracy
- WHEN validating, THEN hook execution < 3 seconds
- WHEN validating, THEN cache hits < 10ms
- WHEN validating all properties, THEN 21/21 pass''',
        'status': 'open',
        'priority': 2,
        'issue_type': 'task',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },
    {
        'id': 'centralized-rules-gap-r010',
        'title': 'Create Claude Skill CI/CD pipeline',
        'description': '''**Scope:** GitHub Actions for testing, building, coverage, releases
**Effort:** Small (4 hours)
**Gap:** General CI exists but no skill-specific pipeline

## Steps
1. Create GitHub Actions workflow for skill PR checks
2. Add automated test execution (unit, integration, E2E, benchmarks)
3. Build TypeScript compilation and ESLint checks
4. Implement code coverage reporting with threshold enforcement
5. Add automated npm package release workflow

## Acceptance Criteria
- WHEN PR opened, THEN run all skill tests automatically
- WHEN PR opened, THEN compile TypeScript and run ESLint
- WHEN tests complete, THEN report code coverage
- WHEN coverage < 85%, THEN fail build
- WHEN release tagged, THEN publish to npm automatically''',
        'status': 'open',
        'priority': 2,
        'issue_type': 'task',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },
    {
        'id': 'centralized-rules-gap-r011',
        'title': 'Write comprehensive Claude Skill documentation',
        'description': '''**Scope:** README, installation, configuration, troubleshooting, API reference
**Effort:** Medium (10 hours)
**Gap:** skill.json documented but no comprehensive README/docs

## Steps
1. Write comprehensive README with features, benefits, quick start
2. Create installation guide with step-by-step instructions
3. Build configuration reference documenting all skill-config.json options
4. Add troubleshooting guide for common issues
5. Create examples for Python+FastAPI, TypeScript+React, Go+Gin
6. Generate API documentation from TypeScript types

## Acceptance Criteria
- WHEN user reads README, THEN understand features and complete quick start
- WHEN user installs, THEN follow guide successfully in < 2 minutes
- WHEN user needs configuration, THEN find all options
- WHEN user encounters issue, THEN find solution
- WHEN developer integrates, THEN find API reference''',
        'status': 'open',
        'priority': 2,
        'issue_type': 'documentation',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },

    # ========== PHASE 3: BEADS INTEGRATION (7 tasks, 57 hours) ==========
    {
        'id': 'centralized-rules-gap-r012',
        'title': 'Implement audit-to-Beads task generation',
        'description': '''**Scope:** Connect audit agent findings to Beads task creation
**Effort:** Medium (8 hours)
**Gap:** AuditConfig has enable_beads_generation flag but not wired up

## What's Missing
- Task creation from MECE violations not implemented
- Task creation from accuracy audit findings not implemented
- Task creation from file disposition recommendations not implemented

## Steps
1. Implement task generator for MECE violations (merge/split/rename/delete/archive)
2. Build task generator for accuracy issues (verification and correction)
3. Create task generator for file disposition (cleanup/archival)
4. Wire up generators to AuditResult.beads_tasks field
5. Integrate with .beads/issues.jsonl

## Acceptance Criteria
- WHEN MECE violations found, THEN create tasks with specific actions
- WHEN accuracy issues found, THEN create verification/correction tasks
- WHEN file disposition issues found, THEN create cleanup/archival tasks
- WHEN audit completes, THEN AuditResult.beads_tasks populated
- WHEN tasks generated, THEN write to .beads/issues.jsonl''',
        'status': 'open',
        'priority': 1,
        'issue_type': 'task',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },
    {
        'id': 'centralized-rules-gap-r013',
        'title': 'Build Beads task classification system',
        'description': '''**Scope:** Automated priority scoring, effort estimation, type categorization
**Effort:** Medium (8 hours)
**Gap:** Task schema exists but no automated classification

## What's Missing
- Priority scoring algorithm (impact × urgency) not implemented
- Effort estimation (Small/Medium/Large) not automated
- Task type categorization manual only
- Dependency linking not present

## Steps
1. Implement priority scoring: impact (1-5) × urgency (1-5) → priority (1=high, 2=medium, 3=low)
2. Create effort estimator (Small <4hr, Medium 4-16hr, Large >16hr)
3. Build task type auto-categorizer from keywords
4. Add dependency linker to identify prerequisite tasks
5. Create measurable completion condition generator

## Acceptance Criteria
- WHEN classifying task, THEN calculate priority from impact × urgency
- WHEN estimating effort, THEN categorize as Small/Medium/Large
- WHEN categorizing, THEN assign type from keywords
- WHEN analyzing dependencies, THEN link prerequisite tasks''',
        'status': 'open',
        'priority': 1,
        'issue_type': 'task',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },
    {
        'id': 'centralized-rules-gap-r014',
        'title': 'Implement Beads context enhancement system',
        'description': '''**Scope:** Enrich task descriptions with file paths, code sections, standards, examples
**Effort:** Medium (7 hours)
**Gap:** Task descriptions are basic, not enriched

## What's Missing
- File paths and line numbers not automatically included
- Code sections from findings not extracted
- Coding standards references not linked
- Example code/patterns not included
- Testing procedures not generated

## Steps
1. Build file path and line number extraction from audit findings
2. Create code section extractor (surrounding context for changes)
3. Implement coding standards reference linker (from rules)
4. Add similar code pattern finder for examples
5. Create testing procedure generator based on task type

## Acceptance Criteria
- WHEN enhancing task, THEN include relevant file paths with line numbers
- WHEN enhancing task, THEN extract code sections showing issue
- WHEN enhancing task, THEN link applicable coding standards
- WHEN enhancing task, THEN include similar code patterns as examples
- WHEN enhancing task, THEN generate testing/verification procedures''',
        'status': 'open',
        'priority': 1,
        'issue_type': 'task',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },
    {
        'id': 'centralized-rules-gap-r015',
        'title': 'Build Beads rules integration',
        'description': '''**Scope:** Auto-select and inject relevant rules into task context
**Effort:** Medium (8 hours)
**Gap:** No connection between centralized rules and Beads tasks

## What's Missing
- Rule selection for task context not implemented
- Progressive disclosure for task-specific rules not present
- Work validation against coding standards not automated
- Rule change impact on tasks not tracked

## Steps
1. Adapt rule selection algorithm from Claude Skill for task context
2. Implement progressive disclosure to load only task-relevant rules
3. Build validation system to check completed work against standards
4. Create rule change detector to identify affected tasks
5. Add rule compliance verification section to task templates

## Acceptance Criteria
- WHEN creating task, THEN auto-select relevant rules using scoring
- WHEN loading rules for task, THEN apply progressive disclosure
- WHEN completing task, THEN validate work against applicable rules
- WHEN rules change, THEN identify and flag affected tasks''',
        'status': 'open',
        'priority': 1,
        'issue_type': 'task',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },
    {
        'id': 'centralized-rules-gap-r016',
        'title': 'Create Beads workflow automation engine',
        'description': '''**Scope:** Notifications, triggers, dependency management, reminders, auto-close
**Effort:** Large (10 hours)
**Gap:** No workflow automation exists

## What's Missing
- Team member notification system not present
- Status change triggers not implemented
- Dependency unblocking not automated
- Deadline reminders not present
- Auto-close not implemented

## Steps
1. Build notification system for task assignment
2. Implement action triggers on status changes
3. Create dependency resolver to unblock tasks
4. Add deadline tracking with reminder system
5. Implement auto-close checker for tasks meeting criteria

## Acceptance Criteria
- WHEN task assigned, THEN notify assignee
- WHEN status changes to in_progress, THEN trigger actions
- WHEN prerequisite completes, THEN auto-unblock dependent tasks
- WHEN deadline approaches (3 days), THEN send reminder
- WHEN task meets acceptance criteria, THEN auto-close''',
        'status': 'open',
        'priority': 1,
        'issue_type': 'task',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },
    {
        'id': 'centralized-rules-gap-r017',
        'title': 'Enhance Beads CLI for AI integration',
        'description': '''**Scope:** JSON output, rich filtering, batch operations, git sync
**Effort:** Medium (8 hours)
**Gap:** Beads CLI exists but not exposed for programmatic use

## What's Missing
- Structured JSON output not present
- Rich filtering not implemented
- Schema validation not present
- Batch operations not supported
- Git workflow sync not automated

## Steps
1. Implement beads query --json for structured output
2. Build rich filtering: --priority, --type, --assignee, --status
3. Add schema validation with immediate feedback
4. Create batch operations: beads batch create/update/close
5. Implement git hooks for automatic task sync

## Acceptance Criteria
- WHEN running beads query --json, THEN output structured JSON
- WHEN filtering with flags, THEN return matching tasks
- WHEN creating invalid task, THEN show schema validation errors
- WHEN running beads batch update, THEN update multiple tasks
- WHEN committing to git, THEN auto-sync task status''',
        'status': 'open',
        'priority': 2,
        'issue_type': 'task',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },
    {
        'id': 'centralized-rules-gap-r018',
        'title': 'Write Beads integration tests',
        'description': '''**Scope:** Tests for classification, enhancement, rules, workflow, CLI
**Effort:** Medium (8 hours)
**Gap:** No tests for Beads integration features

## Steps
1. Write tests for task classification (priority, effort, type, dependencies)
2. Create tests for context enhancement (all enrichment types)
3. Build tests for rules integration and progressive disclosure
4. Add tests for workflow triggers and automation
5. Create E2E test for full task lifecycle

## Acceptance Criteria
- WHEN testing classification, THEN verify priority/effort/type/dependency logic
- WHEN testing enhancement, THEN verify all context enrichment types
- WHEN testing rules integration, THEN verify progressive disclosure
- WHEN testing workflow, THEN verify triggers and notifications
- WHEN running E2E test, THEN complete task lifecycle succeeds''',
        'status': 'open',
        'priority': 2,
        'issue_type': 'task',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },

    # ========== PHASE 4: CROSS-SYSTEM INTEGRATION (3 tasks, 24 hours) ==========
    {
        'id': 'centralized-rules-gap-r019',
        'title': 'Create end-to-end workflow integration tests',
        'description': '''**Scope:** Test complete workflows across sync → skill → audit → beads
**Effort:** Large (10 hours)
**Gap:** Individual systems tested but no cross-system E2E tests

## Steps
1. Create E2E test: sync script → Claude Skill rule loading
2. Build E2E test: audit agent → Beads task generation → enrichment
3. Add E2E test: full workflow (sync → skill → audit → tasks → workflow)
4. Implement CI for all E2E tests
5. Create smoke tests for quick validation

## Acceptance Criteria
- WHEN testing sync → skill, THEN verify rule hierarchy and loading
- WHEN testing audit → beads, THEN verify task generation and enrichment
- WHEN testing full workflow, THEN verify end-to-end integration
- WHEN running in CI, THEN all E2E tests pass
- WHEN running smoke tests, THEN complete in < 2 minutes''',
        'status': 'open',
        'priority': 2,
        'issue_type': 'task',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },
    {
        'id': 'centralized-rules-gap-r020',
        'title': 'Build monitoring and observability',
        'description': '''**Scope:** Structured logging, metrics, alerting, dashboards
**Effort:** Medium (8 hours)
**Gap:** Logging exists but no comprehensive monitoring/observability

## What Exists
- Claude Skill has structured logging (logger.ts)
- Basic logging in sync script and audit agent

## Steps
1. Standardize structured logging across all systems (JSON format)
2. Implement metrics collection for KPIs
3. Build alerting for failures and performance degradation
4. Create dashboards for system health monitoring
5. Add distributed tracing for cross-system workflows

## Acceptance Criteria
- WHEN systems run, THEN emit structured JSON logs
- WHEN collecting metrics, THEN track latency, errors, throughput, cache
- WHEN failures occur, THEN alerts fire
- WHEN viewing dashboard, THEN see system health
- WHEN tracing workflow, THEN see complete execution path''',
        'status': 'open',
        'priority': 2,
        'issue_type': 'task',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    },
    {
        'id': 'centralized-rules-gap-r021',
        'title': 'Create master documentation hub',
        'description': '''**Scope:** Central portal with architecture, guides, API references, tutorials
**Effort:** Medium (6 hours)
**Gap:** Documentation scattered across systems, no central hub

## Steps
1. Create documentation portal structure (docs/ directory or GitHub Pages)
2. Add architecture overview with system diagrams and dependencies
3. Consolidate user guides from all systems
4. Build searchable API documentation
5. Create comprehensive tutorials and examples
6. Add troubleshooting index with common issues

## Acceptance Criteria
- WHEN accessing portal, THEN find organized navigation
- WHEN reading architecture, THEN understand system design
- WHEN following guides, THEN successfully complete tasks
- WHEN searching API, THEN find all functions and parameters
- WHEN learning system, THEN find step-by-step tutorials
- WHEN troubleshooting, THEN find issues indexed across systems''',
        'status': 'open',
        'priority': 3,
        'issue_type': 'documentation',
        'created_at': create_timestamp(),
        'updated_at': create_timestamp()
    }
]

# Append tasks to issues.jsonl
with open('.beads/issues.jsonl', 'a') as f:
    for task in tasks:
        f.write(json.dumps(task) + '\n')

print(f'✅ Created {len(tasks)} new gap-focused BEADS tasks')
print(f'\n📊 Summary:')
print(f'  Phase 1 - Foundation: 5 tasks (26 hours)')
print(f'  Phase 2 - Testing & Validation: 6 tasks (40 hours)')
print(f'  Phase 3 - Beads Integration: 7 tasks (57 hours)')
print(f'  Phase 4 - Cross-System Integration: 3 tasks (24 hours)')
print(f'  Total: 21 tasks, 147 hours\n')

print('Tasks created:')
for i, task in enumerate(tasks, 1):
    priority_label = {1: 'HIGH', 2: 'MED', 3: 'LOW'}
    print(f"  {i:2d}. [{priority_label[task['priority']]}] {task['title']}")
