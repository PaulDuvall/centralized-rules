#!/usr/bin/env python3
import json
from datetime import datetime

tasks = [
    {
        'id': 'centralized-rules-cs1',
        'title': 'Setup Claude Skill development environment with TypeScript and testing',
        'description': 'Bootstrap the Claude Skill development environment with modern tooling.\n\n## Deliverables\n\n### 1. Project Structure\n```\ncentralized-rules-skill/\n├── src/\n│   ├── hooks/\n│   ├── tools/\n│   ├── cache/\n│   └── types/\n├── tests/\n├── dist/\n├── skill.json\n├── package.json\n├── tsconfig.json\n└── README.md\n```\n\n### 2. TypeScript Configuration\n- Strict mode enabled\n- ES2022+ target\n- Path aliases (@hooks, @tools, @cache)\n- Source maps for debugging\n- Declaration files (.d.ts)\n\n### 3. Testing Framework\n- Vitest or Jest setup\n- Coverage reporting (>80% target)\n- Unit test structure\n- Integration test structure\n- E2E test helpers\n\n### 4. Development Tooling\n- ESLint + Prettier\n- Husky pre-commit hooks\n- TypeScript compiler\n- Watch mode for development\n- Build scripts (clean, build, test, lint)\n\n### 5. Dependencies\n- @anthropic-ai/skill-sdk (or equivalent)\n- octokit (GitHub API)\n- node-cache (caching)\n- zod (validation)\n- TypeScript devDependencies\n\n## Acceptance Criteria\n- ✅ TypeScript compiles without errors\n- ✅ Tests run successfully\n- ✅ Linting passes\n- ✅ Can build distributable package\n- ✅ Development workflow documented',
        'status': 'open',
        'priority': 1,
        'issue_type': 'task',
        'created_at': '2025-12-13T23:00:00.000000-05:00',
        'updated_at': '2025-12-13T23:00:00.000000-05:00'
    },
    {
        'id': 'centralized-rules-cs2',
        'title': 'Create skill.json manifest with hooks and tools configuration',
        'description': 'Define the Claude Skill manifest that declares capabilities, hooks, tools, and configuration.\n\n## Deliverables\n\n### 1. Skill Metadata\n- Name: centralized-rules\n- Version: 1.0.0\n- Description, Author, License (MIT)\n\n### 2. Hooks Configuration\n- beforeResponse hook declaration\n- Handler path and description\n- Enable/disable flag\n\n### 3. Tools Definition\n- get_rules: Manually fetch specific rules\n- detect_context: Analyze project structure\n- validate_code: Check code against rules (future)\n\n### 4. Configuration Schema\n- rulesRepo: GitHub repository\n- enableAutoLoad: Auto-inject rules\n- cacheEnabled: Enable caching\n- cacheTTL: Cache time-to-live\n- maxRules: Max rules per request\n\n## Acceptance Criteria\n- ✅ Skill manifest is valid JSON\n- ✅ All required fields present\n- ✅ Configuration schema complete\n- ✅ Hooks and tools properly declared',
        'status': 'open',
        'priority': 1,
        'issue_type': 'task',
        'created_at': '2025-12-13T23:01:00.000000-05:00',
        'updated_at': '2025-12-13T23:01:00.000000-05:00'
    },
    {
        'id': 'centralized-rules-cs3',
        'title': 'Implement project context detection tool (languages, frameworks, cloud, maturity)',
        'description': 'Build intelligent project detection that analyzes codebase to determine relevant context.\n\n## Deliverables\n\n### 1. Language Detection\n- Detect: Python, TypeScript, Java, Go, Rust, C#\n- Multi-language support\n- Version detection (package.json, pyproject.toml, go.mod)\n- Confidence scoring\n\n### 2. Framework Detection\n- Python: FastAPI, Django, Flask\n- TypeScript: React, Next.js, Express, Nest.js\n- Java: Spring Boot\n- Go: Gin, Echo\n\n### 3. Cloud Provider Detection\n- AWS: aws-sdk, boto3, terraform\n- Vercel: vercel.json\n- Azure: azure-sdk\n- GCP: google-cloud\n\n### 4. Maturity Level Detection\n- MVP/POC: version 0.x.x, no CI/CD\n- Pre-Production: version 0.9.x+, basic CI/CD\n- Production: version 1.x.x+, comprehensive CI/CD\n\n### 5. Performance\n- Cache detection results\n- Fast re-detection (<100ms)\n\n## Acceptance Criteria\n- ✅ Detects languages with >95% accuracy\n- ✅ Detects frameworks with >90% accuracy\n- ✅ Returns results in <500ms\n- ✅ Comprehensive test coverage',
        'status': 'open',
        'priority': 1,
        'issue_type': 'task',
        'created_at': '2025-12-13T23:02:00.000000-05:00',
        'updated_at': '2025-12-13T23:02:00.000000-05:00'
    },
    {
        'id': 'centralized-rules-cs4',
        'title': 'Implement smart rule selection algorithm with scoring and ranking',
        'description': 'Build intelligent rule selection that chooses most relevant rules based on context and user intent.\n\n## Deliverables\n\n### 1. Scoring Algorithm\nWeight factors:\n- Language match: 100 points\n- Framework match: 100 points\n- Cloud match: 75 points\n- Maturity match: 50 points\n- Topic match: 30 points per topic\n- Base rules: 20 points\n- Urgency boost: +25 for security\n\n### 2. Intent Analysis\nExtract from user prompt:\n- Topics: auth, testing, security, performance, database\n- Action: implement, fix, refactor, review\n- Urgency: high, normal\n\n### 3. Rule Ranking\n- Score all available rules\n- Sort by relevance\n- Return top N (default 5)\n- Filter out low scores\n\n### 4. Token Budget Management\n- Estimate tokens per rule\n- Ensure total < budget (5K tokens)\n- Prioritize higher-scored rules\n\n## Acceptance Criteria\n- ✅ Selects most relevant rules\n- ✅ Scoring algorithm is tunable\n- ✅ Intent analysis works for common prompts\n- ✅ Token budget respected\n- ✅ Fast selection (<100ms)',
        'status': 'open',
        'priority': 1,
        'issue_type': 'task',
        'created_at': '2025-12-13T23:03:00.000000-05:00',
        'updated_at': '2025-12-13T23:03:00.000000-05:00'
    },
    {
        'id': 'centralized-rules-cs5',
        'title': 'Implement get-rules tool to fetch rules from GitHub with caching',
        'description': 'Build tool that fetches rule content from centralized-rules GitHub repository with intelligent caching.\n\n## Deliverables\n\n### 1. GitHub API Integration\n- Use Octokit for GitHub API\n- Fetch raw file contents\n- Support main/master branch\n- Handle API rate limits\n\n### 2. Caching Layer\n- In-memory cache with TTL\n- Cache key: repo + path + version\n- Default TTL: 1 hour\n- Cache invalidation strategy\n- LRU eviction\n\n### 3. Error Handling\n- Network errors: Retry with exponential backoff\n- 404 errors: Log and skip\n- Rate limits: Use cached version\n- Timeout: 5s per request\n- Graceful degradation\n\n### 4. Performance Optimization\n- Parallel fetching (up to 5 concurrent)\n- Batch requests\n- Compression support\n- ETag/conditional requests\n\n## Acceptance Criteria\n- ✅ Fetches rules from GitHub successfully\n- ✅ Caching reduces API calls by >80%\n- ✅ Cache hit latency <10ms\n- ✅ Cache miss latency <2s\n- ✅ Handles errors gracefully',
        'status': 'open',
        'priority': 1,
        'issue_type': 'task',
        'created_at': '2025-12-13T23:04:00.000000-05:00',
        'updated_at': '2025-12-13T23:04:00.000000-05:00'
    },
    {
        'id': 'centralized-rules-cs6',
        'title': 'Implement beforeResponse hook with automatic rule injection',
        'description': 'Build core beforeResponse hook that automatically detects context, selects rules, and injects them.\n\n## Deliverables\n\n### 1. Hook Workflow\n1. Check if auto-load enabled\n2. Get user last message\n3. Detect project context\n4. Analyze user intent\n5. Select relevant rules\n6. Fetch rules from GitHub\n7. Format rules for injection\n8. Return system prompt addition\n\n### 2. Intent Analysis\n- Extract keywords: auth, test, security, performance\n- Extract actions: implement, fix, refactor\n- Extract urgency: urgent, critical, production\n\n### 3. Rule Formatting\nFormat as markdown with:\n- Project context summary\n- List of applicable rules\n- Rule content with headers\n\n### 4. Error Handling\n- Never block Claude on failure\n- Log errors for debugging\n- Return metadata about errors\n- Fallback to empty rules\n\n### 5. Performance\n- Total execution <3s\n- Log timing for each step\n- Warn if slow (>2s)\n\n## Acceptance Criteria\n- ✅ Hook executes successfully\n- ✅ Rules injected into system prompt\n- ✅ Execution time <3s (95th percentile)\n- ✅ Never blocks Claude on errors\n- ✅ Comprehensive logging',
        'status': 'open',
        'priority': 1,
        'issue_type': 'task',
        'created_at': '2025-12-13T23:05:00.000000-05:00',
        'updated_at': '2025-12-13T23:05:00.000000-05:00'
    },
    {
        'id': 'centralized-rules-cs7',
        'title': 'Build comprehensive test suite with unit, integration, and E2E tests',
        'description': 'Create thorough test suite covering all skill components with high coverage.\n\n## Deliverables\n\n### 1. Unit Tests\n- hooks/before-response.test.ts\n- tools/detect-context.test.ts\n- tools/select-rules.test.ts\n- tools/get-rules.test.ts\n- cache/rules-cache.test.ts\n\n### 2. Integration Tests\n- Full hook workflow with mocked GitHub\n- Rule selection with real rule index\n- Cache behavior under load\n- Error scenarios end-to-end\n\n### 3. E2E Tests\nReal project scenarios:\n- Python + FastAPI + AWS\n- TypeScript + React + Next.js\n- Go + Gin + Docker\n- Multi-language projects\n\n### 4. Performance Benchmarks\n- Hook execution time\n- Cache hit/miss latency\n- Rule selection speed\n- Memory usage\n\n### 5. Coverage Requirements\n- Overall: >85%\n- Critical paths: >95%\n- Hooks: 100%\n\n## Acceptance Criteria\n- ✅ >85% code coverage\n- ✅ All critical paths tested\n- ✅ E2E tests pass with real scenarios\n- ✅ Performance benchmarks established\n- ✅ CI pipeline runs tests automatically',
        'status': 'open',
        'priority': 2,
        'issue_type': 'task',
        'created_at': '2025-12-13T23:06:00.000000-05:00',
        'updated_at': '2025-12-13T23:06:00.000000-05:00'
    },
    {
        'id': 'centralized-rules-cs8',
        'title': 'Setup NPM package publishing and Claude Skill registry distribution',
        'description': 'Prepare skill for distribution via NPM and Claude Skill registry.\n\n## Deliverables\n\n### 1. NPM Package Configuration\n- Package name: @yourusername/centralized-rules-skill\n- Main entry point\n- Type definitions\n- Files to include\n- Keywords and metadata\n\n### 2. Build Pipeline\n- Clean build process\n- TypeScript compilation\n- Bundle optimization\n- Source maps generation\n\n### 3. Publishing Scripts\n- prepublishOnly: build + test\n- Version bump scripts (patch/minor/major)\n- Automated publishing\n\n### 4. Documentation\n- README with installation\n- CHANGELOG with versions\n- API documentation\n- Usage examples\n- Configuration guide\n\n### 5. Claude Skill Registry\n- Skill submission\n- Metadata and screenshots\n- Category tags\n\n### 6. CI/CD for Publishing\n- Automated builds on tag\n- Automated NPM publish\n- GitHub releases\n\n## Acceptance Criteria\n- ✅ Package builds successfully\n- ✅ Published to NPM registry\n- ✅ Submitted to Claude Skill registry\n- ✅ Documentation complete\n- ✅ Installation works end-to-end',
        'status': 'open',
        'priority': 2,
        'issue_type': 'task',
        'created_at': '2025-12-13T23:07:00.000000-05:00',
        'updated_at': '2025-12-13T23:07:00.000000-05:00'
    },
    {
        'id': 'centralized-rules-cs9',
        'title': 'Create migration guide and maintain basic sync script for non-Claude tools',
        'description': 'Provide migration path from sync-based approach to Claude Skill, maintain basic sync for other tools.\n\n## Deliverables\n\n### 1. Migration Guide\n- Why migrate\n- Benefits of Claude Skill\n- Step-by-step migration\n- Comparison table\n- FAQs\n\n### 2. Backwards Compatibility\n- Keep sync-ai-rules.sh functional\n- Mark as "basic support for non-Claude tools"\n- Simplify to essential functionality\n- Add deprecation notice for Claude users\n\n### 3. Tool-Specific Instructions\n- Cursor: Use sync script → .cursorrules\n- Copilot: Use sync script → copilot-instructions.md\n- Other tools: Basic sync available\n\n### 4. Communication Strategy\n- Update README with Claude-first messaging\n- Add skill as recommended approach\n- Keep sync documented but secondary\n\n### 5. Deprecation Timeline\n- Phase 1: Both supported (skill recommended)\n- Phase 2: Sync marked as maintenance mode\n- Phase 3: Sync only for non-Claude tools\n\n## Acceptance Criteria\n- ✅ Migration guide complete\n- ✅ Sync script still works for other tools\n- ✅ Clear messaging about recommended approach\n- ✅ Documentation updated',
        'status': 'open',
        'priority': 3,
        'issue_type': 'task',
        'created_at': '2025-12-13T23:08:00.000000-05:00',
        'updated_at': '2025-12-13T23:08:00.000000-05:00'
    }
]

# Add tasks to issues.jsonl
with open('.beads/issues.jsonl', 'a') as f:
    for task in tasks:
        f.write(json.dumps(task) + '\n')

print(f'✓ Created {len(tasks)} new BEADS tasks for Claude Skill implementation')
for task in tasks:
    print(f"  - {task['id']}: {task['title']} (P{task['priority']})")
