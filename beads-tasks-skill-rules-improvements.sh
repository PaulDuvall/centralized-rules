#!/bin/bash
# Beads Tasks for skill-rules.json Improvements
# Reconciles analysis + user feedback recommendations

set -e

echo "Creating Beads tasks for skill-rules.json improvements..."
echo "=========================================="

# ============================================================================
# PHASE 1: CRITICAL FIXES (P0-P1) - Regex & Robustness
# ============================================================================

echo "Phase 1: Creating critical fix tasks..."

# Task 1: Fix regex patterns (user feedback)
bd create "Fix regex patterns in intentPatterns to prevent false positives" \
  --description "**Problem:** Current regex patterns lack word boundaries and proper escaping, causing false positives.

**Changes needed:**
1. Add word boundaries (\b) to prevent partial matches:
   - 'generate' shouldn't match 'degenerate' or 'regenerate'
   - 'test' shouldn't match 'testing' or 'attest'

2. Fix fix_bug pattern - too restrictive:
   Current: '(fix|debug|resolve|solve)\\s+(bug|issue|error|problem)'
   Better: '(fix|debug|resolve|solve)\\s+(this|the|a|an)?\\s*(bug|issue|error|problem)'

3. Add case-insensitive flags field:
   {
     \"flags\": \"i\"
   }

4. Escape periods in file patterns consistently

**Files:** .claude/skills/skill-rules.json
**Priority:** P1 - Prevents incorrect rule activation" \
  -t bug \
  -p 1 \
  --json

# Task 2: Add negative exclusion patterns (user feedback)
bd create "Add exclusion patterns to reduce false positives" \
  --description "**Goal:** Prevent common phrases from incorrectly triggering rules.

**Implementation:**
Add new 'exclusions' section to intentPatterns:
\`\`\`json
\"exclusions\": [
  {
    \"name\": \"test_data_not_testing\",
    \"regex\": \"test\\s*(data|file|input|case)\",
    \"excludes_rules\": [\"base/testing-philosophy\"]
  }
]
\`\`\`

**Examples to prevent:**
- 'test data' → should NOT trigger testing rules
- 'test file' → should NOT trigger testing rules
- 'test input' → should NOT trigger testing rules

**Files:** .claude/skills/skill-rules.json" \
  -t feature \
  -p 1 \
  --json

# Task 3: Add priority/weight system (user feedback)
bd create "Implement priority/weight system for conflicting rules" \
  --description "**Goal:** Resolve conflicts when multiple rules match.

**Implementation:**
Add to activationThresholds:
\`\`\`json
\"rulePriority\": {
  \"explicit_slash_command\": 100,
  \"file_context\": 80,
  \"intent_pattern\": 60,
  \"keyword_match\": 40
}
\`\`\`

**Logic:**
- Slash commands (/xtest) should always win
- File context (working on .test.ts file) is strong signal
- Intent patterns (regex matches) are medium confidence
- Keyword matches are lowest confidence

**Files:** .claude/skills/skill-rules.json" \
  -t feature \
  -p 1 \
  --json

# Task 4: Deduplicate slash commands (user feedback)
bd create "Remove slash command duplication from keywords arrays" \
  --description "**Problem:** Slash commands appear in both keywords and slashCommands arrays.

**Current (redundant):**
\`\`\`json
\"testing\": {
  \"keywords\": [\"test\", \"/xtest\", \"/test\"],
  \"slashCommands\": [\"/xtest\", \"/test\"]
}
\`\`\`

**Should be:**
\`\`\`json
\"testing\": {
  \"keywords\": [\"test\", \"pytest\", \"jest\"],
  \"slashCommands\": [\"/xtest\", \"/test\"]
}
\`\`\`

**Action:** Remove all slash commands from keywords arrays, keep only in slashCommands.

**Files:** .claude/skills/skill-rules.json" \
  -t task \
  -p 1 \
  --json

# ============================================================================
# PHASE 2: HIGH-PRIORITY ADDITIONS (P1) - Modern Testing & Build Tools
# ============================================================================

echo "Phase 2: Creating high-priority addition tasks..."

# Task 5: Add modern testing frameworks
bd create "Add modern testing framework keywords (Vitest, Playwright, Cypress)" \
  --description "**Goal:** Add high-usage testing tools mentioned in rules but missing from keywords.

**Add to testing.keywords:**
- vitest
- playwright
- cypress
- e2e
- integration test
- testing library
- render
- screen
- userEvent
- msw
- mock service worker
- testcontainers
- snapshot test

**Found in:** frameworks/react/best-practices.md, languages/typescript/testing.md

**Files:** .claude/skills/skill-rules.json" \
  -t feature \
  -p 1 \
  --json

# Task 6: Add Vite and modern build tools
bd create "Add Vite, Turborepo, Nx, pnpm build tool keywords" \
  --description "**Goal:** Support modern build tools and monorepo managers.

**Add new tools section:**
\`\`\`json
\"tools\": {
  \"vite\": {
    \"keywords\": [\"vite\", \"vite.config\", \"vite build\"],
    \"rules\": [\"tools/vite\"]
  },
  \"turborepo\": {
    \"keywords\": [\"turborepo\", \"turbo\", \"turbo.json\", \"monorepo\"],
    \"rules\": [\"tools/turborepo\", \"base/parallel-development\"]
  },
  \"nx\": {
    \"keywords\": [\"nx\", \"nx workspace\", \"nx.json\"],
    \"rules\": [\"tools/nx\", \"base/parallel-development\"]
  },
  \"pnpm\": {
    \"keywords\": [\"pnpm\", \"pnpm-workspace\"],
    \"rules\": [\"tools/pnpm\"]
  }
}
\`\`\`

**Files:** .claude/skills/skill-rules.json" \
  -t feature \
  -p 1 \
  --json

# Task 7: Add Docker/Kubernetes infrastructure (reconciles both analyses)
bd create "Add Docker, Kubernetes, and infrastructure tool keywords" \
  --description "**Goal:** Add infrastructure tools mentioned in both user feedback and analysis.

**Add new infrastructure section:**
\`\`\`json
\"infrastructure\": {
  \"docker\": {
    \"keywords\": [\"docker\", \"container\", \"dockerfile\", \"docker-compose\", \"image\"],
    \"rules\": [\"infrastructure/docker\", \"base/12-factor-app\"]
  },
  \"kubernetes\": {
    \"keywords\": [\"kubernetes\", \"k8s\", \"kubectl\", \"helm\", \"pod\", \"deployment\"],
    \"rules\": [\"infrastructure/kubernetes\"]
  },
  \"ansible\": {
    \"keywords\": [\"ansible\", \"playbook\"],
    \"rules\": [\"infrastructure/ansible\"]
  }
}
\`\`\`

**Found in:** base/12-factor-app.md, base/cicd-comprehensive.md
**User feedback:** Requested as missing coverage

**Files:** .claude/skills/skill-rules.json" \
  -t feature \
  -p 1 \
  --json

# Task 8: Add React ecosystem tools
bd create "Enhance React keywords with Query, Router, Hook Form, Tailwind" \
  --description "**Goal:** Add widely-used React ecosystem tools found in frameworks/react/best-practices.md.

**Add to react.keywords:**
- react query
- @tanstack/react-query
- useMutation
- useQuery
- swr
- useSWR
- react router
- useNavigate
- Route
- react hook form
- useForm
- styled-components
- tailwind
- tailwindcss
- storybook

**Files:** .claude/skills/skill-rules.json" \
  -t feature \
  -p 1 \
  --json

# Task 9: Add data validation keywords (Zod, Joi)
bd create "Add data validation keyword mappings (Zod, Joi, Yup)" \
  --description "**Goal:** Support schema validation libraries found in rule files.

**Add new dataValidation section:**
\`\`\`json
\"dataValidation\": {
  \"keywords\": [\"zod\", \"schema\", \"validate\", \"parse\", \"joi\", \"yup\"],
  \"rules\": [\"base/data-validation\"]
}
\`\`\`

**Found in:** frameworks/express/best-practices.md, frameworks/fastapi/best-practices.md

**Files:** .claude/skills/skill-rules.json" \
  -t feature \
  -p 1 \
  --json

# Task 10: Add database and ORM keywords (reconciles both)
bd create "Add database and ORM tool keywords (Prisma, Redis, etc.)" \
  --description "**Goal:** Add database tools from both user feedback and analysis.

**User feedback requested:**
- sql, postgres, mysql, mongodb, redis, migration, schema

**Analysis found in rules:**
- Prisma (frameworks/fastapi/best-practices.md)
- Redis (mentioned in config context)
- Celery (frameworks/django/best-practices.md)
- SQLAlchemy (frameworks/fastapi/best-practices.md)

**Add new database section:**
\`\`\`json
\"database\": {
  \"prisma\": {
    \"keywords\": [\"prisma\", \"@prisma/client\", \"prisma migrate\"],
    \"rules\": [\"tools/prisma\"]
  },
  \"redis\": {
    \"keywords\": [\"redis\", \"cache\", \"redis-py\", \"ioredis\"],
    \"rules\": [\"tools/redis\"]
  },
  \"general\": {
    \"keywords\": [\"sql\", \"postgres\", \"mysql\", \"mongodb\", \"migration\", \"schema\"],
    \"rules\": [\"base/database-patterns\"]
  }
}
\`\`\`

**Files:** .claude/skills/skill-rules.json" \
  -t feature \
  -p 1 \
  --json

# ============================================================================
# PHASE 3: MEDIUM-PRIORITY ADDITIONS (P2) - Frameworks & APIs
# ============================================================================

echo "Phase 3: Creating medium-priority addition tasks..."

# Task 11: Add GraphQL and API technologies
bd create "Add GraphQL, gRPC, tRPC, OpenAPI keyword mappings" \
  --description "**Goal:** Support modern API technologies mentioned in rules.

**Add new api section:**
\`\`\`json
\"api\": {
  \"graphql\": {
    \"keywords\": [\"graphql\", \"apollo\", \"resolver\", \"mutation\"],
    \"rules\": [\"api/graphql\"]
  },
  \"grpc\": {
    \"keywords\": [\"grpc\", \"protobuf\", \".proto\"],
    \"rules\": [\"api/grpc\"]
  },
  \"trpc\": {
    \"keywords\": [\"trpc\", \"t.procedure\"],
    \"rules\": [\"api/trpc\"]
  },
  \"openapi\": {
    \"keywords\": [\"openapi\", \"swagger\"],
    \"rules\": [\"api/openapi\"]
  }
}
\`\`\`

**Found in:** PRACTICE_CROSSREFERENCE.md, node_modules

**Files:** .claude/skills/skill-rules.json" \
  -t feature \
  -p 2 \
  --json

# Task 12: Add Vue, Nuxt, Svelte frameworks
bd create "Add Vue, Nuxt, Svelte, Astro framework keyword mappings" \
  --description "**Goal:** Extend framework support beyond React/Next.js.

**Add to frameworks:**
\`\`\`json
\"vue\": {
  \"keywords\": [\"vue\", \"vuejs\", \"composition api\", \"pinia\"],
  \"rules\": [\"frameworks/vue\"]
},
\"nuxt\": {
  \"keywords\": [\"nuxt\", \"nuxtjs\", \"nuxt3\"],
  \"rules\": [\"frameworks/nuxt\"]
},
\"svelte\": {
  \"keywords\": [\"svelte\", \"sveltekit\"],
  \"rules\": [\"frameworks/svelte\"]
},
\"astro\": {
  \"keywords\": [\"astro\", \"island architecture\"],
  \"rules\": [\"frameworks/astro\"]
}
\`\`\`

**Found in:** ARCHITECTURE.md mentions as extensible

**Files:** .claude/skills/skill-rules.json" \
  -t feature \
  -p 2 \
  --json

# Task 13: Add Go and Rust backend frameworks
bd create "Add Gin, Fiber, Actix, Rocket backend framework keywords" \
  --description "**Goal:** Support popular Go and Rust web frameworks.

**Enhance go.frameworks:**
\`\`\`json
\"gin\": {
  \"keywords\": [\"gin\", \"gin-gonic\", \"router.GET\"],
  \"rules\": [\"frameworks/gin\"]
}
\`\`\`

**Enhance rust.frameworks:**
\`\`\`json
\"actix\": {
  \"keywords\": [\"actix\", \"actix-web\", \"HttpServer\"],
  \"rules\": [\"frameworks/actix\"]
},
\"rocket\": {
  \"keywords\": [\"rocket\", \"#[get]\"],
  \"rules\": [\"frameworks/rocket\"]
}
\`\`\`

**Found in:** .github/workflows/README.md (Gin), skill/README.md (Actix)

**Files:** .claude/skills/skill-rules.json" \
  -t feature \
  -p 2 \
  --json

# Task 14: Enhance Next.js keywords
bd create "Enhance Next.js keywords with App Router, Server Components, ISR" \
  --description "**Goal:** Add Next.js 13+ features and Vercel-specific patterns.

**Add to nextjs.keywords:**
- server component
- client component
- use client
- use server
- generateStaticParams
- generateMetadata
- middleware.ts
- route.ts
- isr (incremental static regeneration)
- edge runtime
- server actions

**Found in:** cloud/vercel/performance-optimization.md, cloud/vercel/deployment-best-practices.md

**Files:** .claude/skills/skill-rules.json" \
  -t feature \
  -p 2 \
  --json

# Task 15: Add message queue and async tools
bd create "Add Celery, RabbitMQ, Bull message queue keywords" \
  --description "**Goal:** Support async task processing tools.

**Add new async section:**
\`\`\`json
\"async\": {
  \"celery\": {
    \"keywords\": [\"celery\", \"@task\", \"celery worker\"],
    \"rules\": [\"tools/celery\"]
  },
  \"rabbitmq\": {
    \"keywords\": [\"rabbitmq\", \"amqp\", \"message queue\"],
    \"rules\": [\"tools/rabbitmq\"]
  },
  \"bull\": {
    \"keywords\": [\"bull\", \"bullmq\", \"queue\"],
    \"rules\": [\"tools/bull\"]
  }
}
\`\`\`

**Found in:** frameworks/django/best-practices.md (Celery)

**Files:** .claude/skills/skill-rules.json" \
  -t feature \
  -p 2 \
  --json

# Task 16: Add documentation and performance intents (user feedback)
bd create "Add documentation and performance intent patterns" \
  --description "**Goal:** Detect documentation and performance tasks from user feedback.

**Add to intentPatterns.patterns:**
\`\`\`json
{
  \"name\": \"documentation\",
  \"regex\": \"(document|explain|add (comments|docstring|jsdoc)|readme)\",
  \"rules\": [\"base/documentation-standards\"]
},
{
  \"name\": \"performance\",
  \"regex\": \"(performance|optimize|slow|fast|profil|benchmark|latency|throughput)\",
  \"rules\": [\"base/performance-optimization\"]
}
\`\`\`

**User feedback:** Requested as missing coverage

**Files:** .claude/skills/skill-rules.json" \
  -t feature \
  -p 2 \
  --json

# ============================================================================
# PHASE 4: STRUCTURAL IMPROVEMENTS (P2-P3)
# ============================================================================

echo "Phase 4: Creating structural improvement tasks..."

# Task 17: Add structural metadata fields
bd create "Add priority, aliases, contextRequired metadata fields" \
  --description "**Goal:** Enhance rule entries with metadata for smarter loading.

**Add to each keyword mapping entry:**

1. **priority field:**
\`\`\`json
\"priority\": \"high\" | \"medium\" | \"low\"
\`\`\`

2. **aliases field:**
\`\`\`json
\"aliases\": [\"@tanstack/react-query\", \"tanstack query\"]
\`\`\`

3. **contextRequired field:**
\`\`\`json
\"contextRequired\": [\"Dockerfile\", \"docker-compose.yml\"]
\`\`\`

**Benefits:**
- priority: Helps with token budget allocation
- aliases: Improves keyword matching accuracy
- contextRequired: Only activate if specific files exist

**Files:** .claude/skills/skill-rules.json" \
  -t feature \
  -p 2 \
  --json

# Task 18: Add fallback framework detection (user feedback)
bd create "Add fallback/default framework detection strategy" \
  --description "**Goal:** Handle cases where no framework is detected or multiple match.

**Add to root level:**
\`\`\`json
\"frameworkDetection\": {
  \"strategy\": \"first_match\",
  \"fallback\": \"base/code-quality\"
}
\`\`\`

**Strategies:**
- first_match: Use first detected framework
- highest_confidence: Use framework with most signals
- all_matches: Load all matching frameworks

**Files:** .claude/skills/skill-rules.json" \
  -t feature \
  -p 2 \
  --json

# Task 19: Add context decay for multi-turn conversations (user feedback)
bd create "Add context decay settings for multi-turn conversations" \
  --description "**Goal:** Prevent stale keywords from previous turns affecting current context.

**Add to root level:**
\`\`\`json
\"contextSettings\": {
  \"keywordDecayTurns\": 3,
  \"fileContextPersistTurns\": 5,
  \"slashCommandPersistTurns\": 1
}
\`\`\`

**Logic:**
- Keywords from 3+ turns ago are ignored
- File context persists for 5 turns
- Slash commands only affect current turn

**User feedback:** Requested as robustness improvement

**Files:** .claude/skills/skill-rules.json" \
  -t feature \
  -p 3 \
  --json

# Task 20: Add missing JavaScript file extensions (user feedback)
bd create "Add .mjs and .cjs to JavaScript file detection patterns" \
  --description "**Goal:** Detect modern ES module and CommonJS extensions.

**Update javascript.files:**
\`\`\`json
\"files\": [\"package.json\", \"*.js\", \"*.mjs\", \"*.cjs\"]
\`\`\`

**User feedback:** .mjs (ES modules) and .cjs (CommonJS) are common

**Files:** .claude/skills/skill-rules.json" \
  -t bug \
  -p 3 \
  --json

# ============================================================================
# PHASE 5: CLEANUP & OPTIMIZATION (P3)
# ============================================================================

echo "Phase 5: Creating cleanup tasks..."

# Task 21: Remove redundant beads keywords
bd create "Consolidate redundant beads keyword aliases" \
  --description "**Goal:** Reduce clutter in beads keyword mappings.

**Current:**
\`\`\`json
\"keywords\": [\"beads\", \"beas\", \"bd\", \"bd-\", \"issue tracking\", ...]
\`\`\`

**Proposed:**
\`\`\`json
\"keywords\": [\"beads\", \"bd\", \"bd-\"]
\`\`\`

**Remove:**
- 'beas' (typo, low value)
- 'issue tracking' (too generic)
- 'session start', 'session end' (covered by intentPatterns)

**Files:** .claude/skills/skill-rules.json" \
  -t task \
  -p 3 \
  --json

# Task 22: Add CI/CD platform keywords
bd create "Enhance CI/CD keywords with GitLab CI, Jenkins, CircleCI" \
  --description "**Goal:** Support multiple CI/CD platforms beyond GitHub Actions.

**Add to development.keywords:**
- github actions
- .github/workflows
- gitlab ci
- .gitlab-ci.yml
- jenkins
- Jenkinsfile
- circleci

**Found in:** base/cicd-comprehensive.md

**Files:** .claude/skills/skill-rules.json" \
  -t feature \
  -p 3 \
  --json

# Task 23: Add linting and formatting slash commands
bd create "Add /xlint and /xformat slash commands with keywords" \
  --description "**Goal:** Support code quality tooling detection.

**Add to base section:**
\`\`\`json
\"linting\": {
  \"keywords\": [\"lint\", \"eslint\", \"prettier\", \"black\", \"ruff\", \"pylint\"],
  \"slashCommands\": [\"/xlint\"],
  \"rules\": [\"base/code-quality\"]
},
\"formatting\": {
  \"keywords\": [\"format\", \"prettier\", \"black\", \"rustfmt\", \"gofmt\"],
  \"slashCommands\": [\"/xformat\"],
  \"rules\": [\"base/code-quality\"]
}
\`\`\`

**Files:** .claude/skills/skill-rules.json" \
  -t feature \
  -p 3 \
  --json

# ============================================================================
# VERIFICATION & DOCUMENTATION
# ============================================================================

echo "Phase 6: Creating verification task..."

# Task 24: Create comprehensive test suite
bd create "Create test suite to validate skill-rules.json changes" \
  --description "**Goal:** Ensure all changes work correctly and don't break existing functionality.

**Test coverage needed:**
1. JSON schema validation
2. Regex pattern testing (word boundaries, escaping)
3. Keyword matching with new entries
4. Priority system logic
5. Exclusion pattern filtering
6. Context decay behavior
7. Framework detection fallback

**Test files to create:**
- tests/skill-rules-validation.test.ts
- tests/keyword-matching.test.ts
- tests/regex-patterns.test.ts

**Files:** skill/tests/

**Blockers:** All implementation tasks must complete first" \
  -t task \
  -p 2 \
  --json

echo ""
echo "=========================================="
echo "✅ All Beads tasks created successfully!"
echo ""
echo "Summary:"
echo "  - Phase 1 (P0-P1): 4 critical fixes"
echo "  - Phase 2 (P1): 6 high-priority additions"
echo "  - Phase 3 (P2): 6 medium-priority features"
echo "  - Phase 4 (P2-P3): 4 structural improvements"
echo "  - Phase 5 (P3): 3 cleanup tasks"
echo "  - Phase 6: 1 verification task"
echo "  Total: 24 tasks"
echo ""
echo "Next steps:"
echo "  1. Review tasks: bd list --json"
echo "  2. Start with Phase 1: bd ready --json"
echo "  3. Verify tasks were created: bd list --status open | wc -l"
echo ""
