# Making AI Coding Assistants Context-Aware Without Context Overload

**How Centralized Rules enables AI to generate higher-quality code by loading only the most relevant standards, reducing token usage by 55-90% while improving consistency**

---

## The Problem: When More Instructions Lead to Worse Code

AI coding assistants face a paradox: more coding standards often produce worse code.

**Instruction saturation** occurs when AI models receive too many guidelines at once, causing them to lose focus and miss requirements—like following 50 recipes simultaneously for one dish.

Without guidance, AI assistants don't know your team's standards. They generate Python code that ignores PEP 8, React components that violate state management patterns, or AWS infrastructure with security issues. Hours of review and fixes follow for code that could have been right initially.

The question becomes: **How do you give AI assistants enough context to generate great code without overwhelming them?**

## The Solution: Progressive Disclosure of Development Standards

**Centralized Rules** solves this through context-aware rule loading. Developed from experiments in the [AI Development Patterns repository](https://github.com/PaulDuvall/ai-development-patterns/tree/main/experiments#centralized-rules), it narrows 50+ standards to the 2-3 most relevant based on:

- **Project technology stack** (Python vs TypeScript vs Go)
- **Frameworks** (React vs FastAPI vs Spring Boot)
- **Cloud infrastructure** (AWS vs Vercel vs Azure)
- **Current task** (writing tests vs refactoring vs security)

Your AI assistant receives the right guidance at the right time without cognitive overload.

## How It Works: A Two-Tier Architecture

The system balances instant feedback with deep guidance through two mechanisms:

### Tier 1: Bash Hook (Immediate Feedback)

On each prompt, `activate-rules.sh` executes in 50ms:

1. **Scans project** for language markers (`package.json`, `pyproject.toml`, `go.mod`)
2. **Detects frameworks** by parsing dependency files
3. **Identifies cloud providers** through configuration files
4. **Analyzes prompt** for task keywords ("test", "security", "refactor")
5. **Displays status box** showing applicable rule categories

Uses ~500 tokens (0.25% of Claude's 200K context window) and confirms which standards will load.

### Tier 2: TypeScript Skill (Content Loading)

The TypeScript module then:

1. **Context Detection** - Analyzes project structure
2. **Intent Analysis** - Extracts keywords from your prompt
3. **Relevance Scoring** - Rates rules:
   - Language match: +100 points
   - Framework match: +100 points
   - Topic relevance: +80 points
   - Keywords: +50 points each
4. **Selection** - Top 5 rules within 5K token budget
5. **Caching** - Downloads once, caches 1 hour
6. **Injection** - Adds to Claude's system prompt

Executes in 200-500ms using 0-5K tokens (typically 2-3K). Combined with the hook: **2.75% of context window** for rules vs 40-50% loading everything.

## Impact: Real Numbers from Real Projects

Measurements from a Python FastAPI project:

| Task Type | Rules Loaded | Tokens Used | Tokens Saved vs All Rules |
|-----------|--------------|-------------|---------------------------|
| Code Review | 2 files (git-workflow, code-quality) | 3,440 | 86.4% |
| Write Tests | 2 files (python/testing, testing-philosophy) | 11,163 | 55.8% |
| FastAPI Endpoint | 3 files (fastapi, python, security) | 8,608 | 65.9% |
| Git Commit | 2 files (git-workflow, git-tagging) | 2,618 | 89.6% |

**Average:** 74.4% token savings vs loading all rules.

Beyond token efficiency, code quality improves:

- Tests include edge cases and error handling automatically
- Security best practices are baked into every API endpoint
- Git commits follow conventional commit standards
- Code follows language-specific idioms and patterns
- Documentation is generated in the expected format

## What Makes This Different: The MECE Framework

Most rule systems duplicate content and leave gaps. Security rules repeat Python guides, which overlap API standards, creating precedence confusion.

Centralized Rules follows the **MECE principle** (Mutually Exclusive, Collectively Exhaustive) across four dimensions:

### 1. Base Rules (23 files - Universal Standards)

These apply to all projects regardless of technology:

- **Workflow:** `git-workflow`, `git-tagging`, `development-workflow`
- **Quality:** `code-quality`, `testing-philosophy`, `refactoring-patterns`
- **Architecture:** `architecture-principles`, `12-factor-app`, `configuration-management`
- **Security:** `security-principles`, `cicd-comprehensive`
- **AI Development:** `ai-assisted-development`, `ai-ethics-governance`, `ai-model-lifecycle`
- **Advanced:** `chaos-engineering`, `lean-development`, `tool-design`, `metrics-standards`

### 2. Language Rules (8+ languages × 2 files each)

Language-specific standards without framework assumptions:

- Python: `coding-standards.md`, `testing.md`
- TypeScript: `coding-standards.md`, `testing.md`
- Go: `coding-standards.md`, `testing.md`
- Java, C#, Rust, Ruby, Bash, HTML, CSS...

### 3. Framework Rules (12+ frameworks)

Framework-specific patterns that build on language rules:

- **Python:** Django, FastAPI, Flask
- **JavaScript/TypeScript:** React, Next.js, Express, NestJS, Vue
- **Java:** Spring Boot
- **Go:** Gin, Fiber

### 4. Cloud Provider Rules

Infrastructure-specific best practices:

- **AWS:** Well-Architected Framework, IAM, Security Best Practices
- **Vercel:** Deployment, Security, Performance, Cost Optimization
- **Extensible:** Easy to add Azure, GCP, DigitalOcean

These mutually exclusive, collectively exhaustive dimensions eliminate duplication and gaps.

## Installation: 60 Seconds to Setup

Two installation methods:

### Global Installation (Recommended)

Install once, benefit everywhere:

```bash
curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/main/install-hooks.sh | bash -s -- --global
```

Adds the hook to Claude Code global settings. Every project gets rule loading with zero per-project configuration.

### Local Installation (Project-Specific)

For custom rules or project-specific overrides:

```bash
curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/main/install-hooks.sh | bash
```

Installs into your project's `.claude/` directory for custom rules or project-specific overrides.

### What Gets Installed?

Both methods create this structure:

```
.claude/
├── hooks/
│   └── activate-rules.sh          # UserPromptSubmit hook (instant feedback)
├── skills/
│   └── skill-rules.json           # Keyword mappings (customizable)
└── settings.json                  # Hook registration
```

Plus cached rules in your home directory:

```
~/.claude/cache/centralized-rules/
├── base/                          # Universal standards
├── languages/                     # Language-specific rules
├── frameworks/                    # Framework patterns
└── cloud/                         # Cloud provider guides
```

No configuration files, API keys, or setup wizards required.

## Real-World Use Cases

### Fast-Growing Startups
Five developers across three tech stacks producing inconsistent code. Global deployment ensures every AI assistant follows the same standards, shifting code reviews from style debates to logic.

### Enterprise Organizations
200+ developers, 50 teams, standards scattered across unread Confluence pages. Fork the repository, add company-specific rules (HIPAA compliance, internal APIs), and distribute. Result: organization-wide consistency and compliant code from day one.

### Solo Developers
Twelve projects in four languages means forgetting idiomatic patterns during context switches. Global installation ensures your AI assistant remembers best practices for each language.

### Open Source Maintainers
PRs arrive with different styles, consuming review time. Add Centralized Rules to your contributing guide so Claude Code users automatically follow your standards, producing higher quality PRs.

## Under the Hood: Auto-Detection

The system understands your project without configuration:

### Language Detection

The system scans for language-specific markers:

- **Python:** `pyproject.toml`, `requirements.txt`, `setup.py`, `*.py` files
- **TypeScript/JavaScript:** `package.json`, `tsconfig.json`, `*.ts/*.tsx` files
- **Go:** `go.mod`, `go.sum`, `*.go` files
- **Rust:** `Cargo.toml`, `Cargo.lock`, `*.rs` files
- **Java:** `pom.xml`, `build.gradle`, `*.java` files

Finding even one marker triggers language-specific rules.

### Framework Detection

After identifying languages:

- Parses `package.json` for React, Next.js, Express, NestJS
- Checks Python dependencies for Django, FastAPI, Flask
- Scans for framework config files (`next.config.js`, `fastapi.py`)

### Cloud Provider Detection

Infrastructure patterns are detected through:

- **AWS:** `.aws-sam/`, `cdk.json`, `terraform/` with AWS providers
- **Vercel:** `vercel.json`, `.vercel/` directory
- **Custom:** Extensible patterns in `rules-config.json`

### Intent Analysis

Prompts are analyzed for task-specific terms:

- **Testing:** "test", "pytest", "jest", "coverage", "tdd", "/xtest"
- **Security:** "auth", "password", "encrypt", "validate", "/xsecurity"
- **Refactoring:** "refactor", "clean up", "optimize", "/xrefactor"
- **Git:** "commit", "pull request", "tag", "/xgit"

Recognizes both natural language and Claude Code slash commands to load relevant topic rules alongside language/framework rules.

## Customization

Three customization approaches:

### Local Custom Rules (No Fork Required)

Add project or company rules locally without forking. Custom rules blend with centralized ones.

**Step 1: Create your custom rule file**

```bash
# Create a custom rule in your project's .claude directory
mkdir -p .claude/rules/base
cat > .claude/rules/base/company-api-standards.md << 'EOF'
# Company API Standards

## REST API Design
- All endpoints must use kebab-case URLs
- Versions must be in the URL path: /api/v1/resource
- Authentication required via JWT tokens

## Response Format
All responses must follow this structure:
```json
{
  "data": {...},
  "meta": {"timestamp": "...", "version": "1.0"},
  "error": null
}
```
EOF
```

**Step 2: Register the rule in keyword mappings**

Edit `.claude/skills/skill-rules.json` to add keyword triggers:

```json
{
  "keywordMappings": {
    "base": {
      "company_api": {
        "keywords": ["api", "endpoint", "rest api", "graphql"],
        "rules": ["base/company-api-standards.md"]
      },
      "company_security": {
        "keywords": ["auth", "security", "authentication"],
        "rules": ["base/company-security-policy.md"]
      }
    },
    "languages": {
      "python": {
        "keywords": ["python", ".py"],
        "rules": ["languages/python/coding-standards"],
        "company_rules": ["languages/python/company-python-guide.md"]
      }
    }
  }
}
```

**Step 3: Use immediately**

When you mention "api" or "endpoint", your company-specific standards load alongside centralized rules.

**File Structure for Custom Rules:**

```
your-project/
└── .claude/
    ├── rules/                    # Your custom rules
    │   ├── base/
    │   │   ├── company-api-standards.md
    │   │   └── company-security-policy.md
    │   ├── languages/
    │   │   └── python/
    │   │       └── company-python-guide.md
    │   └── frameworks/
    │       └── react/
    │           └── company-react-patterns.md
    ├── skills/
    │   └── skill-rules.json      # Keyword mappings
    └── hooks/
        └── activate-rules.sh     # Auto-installed
```

**How It Works:**

- Centralized rules are fetched from GitHub (cached for 1 hour)
- Your local custom rules load from `.claude/rules/`
- Both are scored for relevance based on your prompt
- Top 3-5 most relevant rules (from both sources) are injected
- No fork needed, no GitHub account required

### Quick Keyword Customization

To adjust when existing rules load, edit `.claude/skills/skill-rules.json`:

```json
{
  "keywordMappings": {
    "base": {
      "testing": {
        "keywords": ["test", "spec", "tdd", "my-custom-test-trigger"],
        "rules": ["base/testing-philosophy"]
      }
    }
  }
}
```

Changes take effect immediately—no restart required.

### Organization-Wide Customization

To distribute custom rules across all developers, fork and customize:

1. **Add proprietary rules** in the appropriate directory
2. **Update `rules-config.json`** with new categories
3. **Modify keyword mappings** for company-specific terms
4. **Update the install script** to point to your fork

Then distribute:

```bash
export RULES_REPO="https://raw.githubusercontent.com/your-company/centralized-rules/main"
curl -fsSL $RULES_REPO/install-hooks.sh | bash -s -- --global
```

Every developer gets company standards automatically.

## The Progressive Disclosure Strategy

The system implements a two-phase reduction strategy based on experiments documented in the [AI Development Patterns repository](https://github.com/PaulDuvall/ai-development-patterns/tree/main/experiments#progressive-disclosure):

**Phase 1: Project-Level Filtering**
- Starts with 50+ total rule files
- Filters to 8-12 files relevant to your project's stack
- Based on detected languages, frameworks, cloud providers

**Phase 2: Task-Level Selection**
- Narrows 8-12 files to 2-3 for the specific task
- Uses keyword analysis from your prompt
- Applies relevance scoring and token budgets

**Result:** 96% of your 200K context window remains available for analyzing your actual code, not reading documentation.

Compare this to traditional approaches:

| Approach | Rules Loaded | Tokens Used | Context Available |
|----------|--------------|-------------|-------------------|
| Manual Copy-Paste | All relevant (10-15 files) | 40,000-60,000 | 70% |
| Static .claud file | All possible (50+ files) | 100,000+ | 50% |
| **Centralized Rules** | **Task-relevant (2-3 files)** | **5,000-7,000** | **96%** |

## Performance

### Setup Time
- **Global installation:** 5 seconds (one-time)
- **Local installation:** 10 seconds (per project)
- **First rule fetch:** 200-500ms (then cached)

### Per-Request Overhead
- **Hook execution:** ~50ms
- **Rule fetching:** 0ms (cached) to 500ms (network)
- **Total added latency:** <1 second

### Token Usage
- **Hook metadata:** ~500 tokens (0.25% of context)
- **Loaded rules:** 2,000-5,000 tokens (1-2.5% of context)
- **Total:** 2,500-5,500 tokens (1.25-2.75% of context)

### Caching Benefits
- **Cache TTL:** 1 hour
- **Hit rate:** >90% in typical usage
- **Bandwidth saved:** ~1MB per hour per developer

## What It Doesn't Do

Centralized Rules does NOT:

1. **Doesn't enforce rules** - Claude can still ignore them if you explicitly ask
2. **Doesn't slow down responses** - <1 second added latency
3. **Doesn't require constant network** - Cached locally after first fetch
4. **Doesn't work with Claude Desktop** - Only Claude Code CLI (different architecture)
5. **Doesn't guarantee perfect code** - It's guidance, not validation
6. **Doesn't replace code review** - Still need human oversight

## Future Enhancements

Planned additions:

- **Maturity levels:** MVP, Pre-Production, Production rules with different rigor
- **Team-specific rules:** Per-developer customization
- **Multi-repo support:** Shared rules across microservices
- **Analytics:** Track which rules are most useful
- **IDE integration:** Support for VS Code, JetBrains IDEs
- **More languages:** PHP, Swift, Kotlin, Scala
- **More frameworks:** Angular, Svelte, Phoenix, Rails

## Getting Started

**Step 1: Install globally**
```bash
curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/main/install-hooks.sh | bash -s -- --global
```

**Step 2: Start coding**
```bash
cd your-project/
claude
# Rules load automatically
```

**Step 3: Observe results**

A status box shows detected languages and frameworks. Claude generates code following relevant standards.

**Step 4 (Optional): Customize**

Edit `.claude/skills/skill-rules.json` for project-specific keywords or rules.

## Conclusion

AI-assisted development requires the right information at the right time, not more information. Centralized Rules achieves both comprehensive standards and focused guidance through progressive disclosure.

Key metrics:

- **74% average token savings** vs loading all rules
- **96% of context window** available for code analysis
- **2-3 relevant rules** loaded vs 50+ possibilities
- **<1 second latency** per request
- **Zero manual configuration** for most projects

For solo developers maintaining consistency, startups scaling teams, or enterprises enforcing standards, Centralized Rules provides necessary context without cognitive overload.

Result: higher quality code, fewer review cycles, better consistency, and developers focused on problems rather than syntax.

---

## Resources

- **GitHub Repository:** [paulduvall/centralized-rules](https://github.com/paulduvall/centralized-rules)
- **Experimental Foundation:** [AI Development Patterns - Centralized Rules](https://github.com/PaulDuvall/ai-development-patterns/tree/main/experiments#centralized-rules)
- **Progressive Disclosure Research:** [AI Development Patterns - Progressive Disclosure](https://github.com/PaulDuvall/ai-development-patterns/tree/main/experiments#progressive-disclosure)
- **Installation Guide:** [docs/installation.md](installation.md)
- **Auto-Detection Details:** [docs/AUTO_DETECTION.md](AUTO_DETECTION.md)
- **Full Documentation:** [https://paulduvall.github.io/centralized-rules/](https://paulduvall.github.io/centralized-rules/)
