# Centralized AI Development Rules

**Progressive Disclosure for AI Coding Tools**

A centralized repository of development rules that dynamically loads only relevant guidelines based on your project's language, framework, and tooling. Works with Claude Code, Cursor, GitHub Copilot, and other AI coding assistants.

## Overview

Instead of maintaining separate rule files in each project, this repository provides:

- **MECE Framework** - Mutually Exclusive, Collectively Exhaustive organization
- **Four-Dimensional Structure:**
  - **Base rules** (23 files) - Universal, language-agnostic best practices
  - **Language rules** (6+ languages) - Python, TypeScript, Go, Java, C#, Rust
  - **Framework rules** (5+ frameworks) - React, Django, FastAPI, Express, Spring Boot
  - **Cloud rules** (Vercel + extensible) - Provider-specific deployment and operations
- **Progressive Rigor** - Maturity-based requirements (MVP/POC, Pre-Production, Production)
- **Two-phase progressive disclosure** - Load only what's relevant (project + task level)
- **Multi-tool support** - Generate outputs for Claude, Cursor, Copilot
- **74.4% average token savings** - Validated in real-world testing

> **📚 Part of the [AI Development Patterns Experiments](https://github.com/PaulDuvall/ai-development-patterns/tree/main/experiments#centralized-rules)**
> Exploring progressive disclosure as a solution to AI instruction saturation

---

## 🚀 Just Installed? Quick Verification

**Test if it's working** - Try this prompt after installation:

```
"What coding rules are available?"
```

You should see context detection and a list of loaded rules.

**See full verification guide:** [Jump to Verify It's Working →](#-verify-its-working)

---

## Architecture

```
centralized-rules/
├── base/                          # 23 universal rules (always loaded)
│   ├── git-workflow.md           # + maturity indicators
│   ├── code-quality.md           # + maturity indicators
│   ├── testing-philosophy.md     # + maturity indicators
│   ├── security-principles.md    # + maturity indicators
│   ├── cicd-comprehensive.md     # + maturity indicators
│   ├── project-maturity-levels.md
│   ├── ai-assisted-development.md
│   └── ... (16 more)
│
├── languages/                     # 6+ languages supported
│   ├── python/
│   ├── typescript/
│   ├── go/
│   ├── java/
│   ├── csharp/                   # NEW
│   └── rust/                     # NEW
│
├── frameworks/                    # 5+ frameworks supported
│   ├── react/                    # Enriched with advanced patterns
│   ├── django/                   # Enriched with DRF, signals, Celery
│   ├── fastapi/
│   ├── express/                  # NEW
│   └── springboot/               # NEW
│
├── cloud/                         # Cloud provider rules (NEW)
│   └── vercel/                   # 6 comprehensive guides
│       ├── deployment-best-practices.md
│       ├── environment-configuration.md
│       ├── security-practices.md
│       ├── performance-optimization.md
│       ├── reliability-observability.md
│       └── cost-optimization.md
│
├── scripts/                       # NEW
│   └── validate-mece.sh          # MECE compliance checker
│
├── sync-ai-rules.sh              # Progressive disclosure script (enhanced)
├── PRACTICE_CROSSREFERENCE.md    # Practice-to-file mapping (NEW)
├── ANTI_PATTERNS.md              # Common anti-patterns (NEW)
├── IMPLEMENTATION_GUIDE.md       # 8-week rollout plan (NEW)
├── SUCCESS_METRICS.md            # Measurable KPIs (NEW)
├── ARCHITECTURE.md               # Detailed architecture (updated)
└── README.md                      # This file
```

## Repository Structure

### Root-Level Documentation

This repository uses a hybrid documentation structure with key files at root for easy access and detailed guides in `docs/`:

| File | Purpose | When to Read |
|------|---------|--------------|
| **README.md** | Primary documentation, Quick Start, overview of progressive disclosure system | Start here for installation and basic usage |
| **ARCHITECTURE.md** | Technical architecture, design decisions, performance validation, scalability analysis | Read when understanding system internals or extending functionality |
| **ANTI_PATTERNS.md** | Catalog of common anti-patterns with detection strategies and prevention techniques | Reference during code review or when debugging quality issues |
| **PRACTICE_CROSSREFERENCE.md** | Bidirectional mapping between best practices and implementation files | Use to find which file covers a specific practice |
| **IMPLEMENTATION_GUIDE.md** | 8-week phased rollout plan with success criteria and metrics | Follow when adopting centralized rules in your project |
| **SUCCESS_METRICS.md** | Measurable KPIs (DORA metrics, code quality, security, team productivity) | Reference when setting up metrics or tracking improvements |

**Note:** All guides are also accessible through the `docs/` directory for documentation site generation.

## Quick Start

Choose your installation method based on your AI tool:

### Option 1: Claude Skill (Recommended for Claude Users)

**Automatic, hook-based rule loading** - No manual syncing required!

```bash
# One-command installation
curl -fsSL https://raw.githubusercontent.com/PaulDuvall/centralized-rules/main/skill/install.sh | bash
```

This will:
- Clone the repository to `~/centralized-rules`
- Install and build the Claude Skill
- **Auto-detect** which Claude variant you're using:
  - **Claude Code CLI**: Automatically creates symlink in `~/.claude/skills/`
  - **Claude Desktop**: Shows config instructions for `~/.config/claude/claude_desktop_config.json`
- Handle both if you have both installed

**Claude Code CLI** - Ready immediately after restart!

**Claude Desktop** - Add to your config file:

```json
{
  "skills": [
    {
      "name": "centralized-rules",
      "path": "~/centralized-rules/skill"
    }
  ]
}
```

**How it works:**
- Automatically detects your project context (language, framework, cloud provider)
- Intelligently loads only 3-5 relevant rules per request
- No context window bloat - uses progressive disclosure
- Always fetches latest rules from GitHub
- Zero manual sync required

**[Full Skill Documentation →](skill/README.md)**

### 🔄 Updating the Skill

To get the latest features and fixes:

```bash
cd ~/centralized-rules && git pull && cd skill && npm run build
```

Then restart Claude Code. That's it!

**If you get a merge conflict:**
```bash
cd ~/centralized-rules && git reset --hard origin/main && git pull && cd skill && npm run build
```

### ✅ Verify It's Working

After installation and restart, test the skill with these prompts:

#### Quick Test (Any Project)

```
"What coding rules are available?"
```

**Expected Response:**
- **Visible banner** at the top showing active rules and detected context
- Skill detects your project's language and framework
- Lists relevant rule categories (base, language-specific, framework-specific)
- Shows which rules are loaded for your context

#### Example Output:

```
═══════════════════════════════════════════════════════
📋 Centralized Rules Active
═══════════════════════════════════════════════════════

🔍 Context Detected:
   Languages: TypeScript | Frameworks: React
   Maturity: mvp | Confidence: 95%

📖 Rules Loaded: 7 files
   Git Workflow, Code Quality, Testing Philosophy, TypeScript Standards,
   React Patterns, Security Principles, Error Handling
═══════════════════════════════════════════════════════

[Then my actual response to your question...]
```

#### Test With Code Task

```
"Create a React component with a counter button"
```

**What to Look For:**
- ✅ Component follows React functional component patterns
- ✅ Uses proper TypeScript types
- ✅ Includes PropTypes or TypeScript interfaces
- ✅ Has meaningful variable names
- ✅ Suggests writing tests

#### Verify Progressive Disclosure

```
"Write a pytest test for a simple add function"
```

**Expected Behavior:**
- Loads only testing rules (not all rules)
- Applies Python-specific testing patterns
- Suggests pytest best practices
- Doesn't load unrelated rules (git, deployment, etc.)

#### Visual Indicators

When the skill is active, you'll see:
- 🎯 **Context detection** - Mentions detected language/framework
- 📋 **Rule citations** - References specific coding standards
- ✨ **Best practices** - Applies rules automatically without being asked
- 🔍 **Progressive loading** - Only loads relevant rules for the task

#### Troubleshooting

**Skill not loading?**

```bash
# Check symlink (Claude Code CLI)
ls -la ~/.claude/skills/centralized-rules

# Should output:
# centralized-rules -> /Users/you/centralized-rules/skill

# Verify skill.json exists
cat ~/.claude/skills/centralized-rules/skill.json
```

**No context detection?**

The skill requires a project with recognizable files:
- Python: `pyproject.toml`, `requirements.txt`, `setup.py`
- TypeScript/JS: `package.json`, `tsconfig.json`
- Go: `go.mod`
- Java: `pom.xml`, `build.gradle`

Create a test project with one of these files and try again.

### Option 2: Sync Script (For Cursor, Copilot, or Manual Sync)

**Traditional sync-based approach** - Works with any AI tool.

#### 1. Add to Your Project

```bash
# Download the sync script
curl -fsSL https://raw.githubusercontent.com/PaulDuvall/centralized-rules/main/sync-ai-rules.sh \
    -o sync-ai-rules.sh

chmod +x sync-ai-rules.sh
```

#### 2. Run Sync

```bash
# Auto-detect and sync for all AI tools
./sync-ai-rules.sh

# Or sync for specific tool
./sync-ai-rules.sh --tool claude
./sync-ai-rules.sh --tool cursor
./sync-ai-rules.sh --tool copilot
```

#### 3. Use with AI Tools

The script generates tool-specific files:

**Claude Code (Hierarchical - Recommended):**
- `.claude/AGENTS.md` - Entry point with discovery instructions
- `.claude/rules/` - Organized rule directory (on-demand loading)
- `.claude/rules/index.json` - Machine-readable rule index
- `.claude/RULES.md` - Legacy monolithic format (deprecated)

**Cursor:**
- `.cursorrules` - Monolithic format

**GitHub Copilot:**
- `.github/copilot-instructions.md` - Monolithic format

Your AI assistant will automatically use these rules! Claude Code will use progressive disclosure for maximum efficiency.

## Progressive Disclosure

**Two-phase system that maximizes context efficiency:**

### Phase 1: Project-Level Disclosure

The sync script automatically detects your project and loads only relevant rules.

**Example: Python + FastAPI Project**

**Detected:**
- Language: Python (via `pyproject.toml`)
- Framework: FastAPI (via dependencies)

**Loaded Rules:**
- ✅ Base rules (git, code quality, testing, security)
- ✅ Python rules (type hints, pytest, mypy)
- ✅ FastAPI rules (endpoints, async, validation)
- ❌ TypeScript rules (not loaded)
- ❌ React rules (not loaded)

**Result:** 8 relevant files loaded vs 50+ available in repository

### Phase 2: Task-Level Disclosure (Hierarchical Mode)

Within your project, AI loads only rules relevant to the specific task.

**Example: "Write pytest tests for this function"**

**Loaded:**
- ✅ `base/testing-philosophy.md` (testing principles)
- ✅ `languages/python/testing.md` (pytest patterns)
- ❌ Code quality rules (not needed for testing)
- ❌ FastAPI rules (not needed for unit tests)
- ❌ Git workflow (not a commit task)

**Result:** 2 files (~11K tokens) vs all 8 files (~25K tokens) = **55.8% token savings**

### Real-World Results

Tested with Python + FastAPI project:

| Task Type | Files Loaded | Token Savings |
|-----------|-------------|---------------|
| Code Review | 2 files | 86.4% |
| Write Tests | 2 files | 55.8% |
| FastAPI Endpoint | 3 files | 65.9% |
| Git Commit | 2 files | 89.6% |
| **Average** | **2.25 files** | **74.4%** |

**Impact:** 59% more context window available for code analysis!

## Detection Logic

### Languages

The script detects languages based on project files:

| Language   | Detection Files                          |
|------------|------------------------------------------|
| Python     | `pyproject.toml`, `setup.py`, `requirements.txt` |
| TypeScript | `package.json` with `"typescript"`       |
| JavaScript | `package.json` without TypeScript        |
| Go         | `go.mod`                                 |
| Java       | `pom.xml`, `build.gradle`                |
| Ruby       | `Gemfile`                                |
| Rust       | `Cargo.toml`                             |

### Frameworks

The script detects frameworks from dependency files:

| Framework    | Detection Method                   |
|--------------|------------------------------------|
| Django       | `django` in Python dependencies    |
| FastAPI      | `fastapi` in Python dependencies   |
| Flask        | `flask` in Python dependencies     |
| React        | `"react"` in package.json          |
| Next.js      | `"next"` in package.json           |
| Vue          | `"vue"` in package.json            |
| Express      | `"express"` in package.json        |
| Spring Boot  | `spring-boot` in Java build files  |

## Configuration

### Custom Rules Repository

Set your own rules repository URL:

```bash
export AI_RULES_REPO="https://raw.githubusercontent.com/your-org/your-rules/main"
./sync-ai-rules.sh
```

### Manual Configuration

Create `.ai/sync-config.json` to override auto-detection:

```json
{
    "languages": ["python", "typescript"],
    "frameworks": ["fastapi", "react"],
    "exclude": ["testing-mocking"],
    "custom_rules": [
        "https://example.com/custom-rule.md"
    ]
}
```

## Automation

### Pre-commit Hook

Keep rules synced automatically:

```bash
# .git/hooks/pre-commit
#!/bin/bash
./sync-ai-rules.sh --tool all
git add .claude/RULES.md .cursorrules .github/copilot-instructions.md
```

### CI/CD

Validate rules are current in pull requests:

```yaml
# .github/workflows/validate-rules.yml
name: Validate AI Rules

on: [pull_request]

jobs:
  check-rules:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Sync rules
        run: ./sync-ai-rules.sh
      - name: Check for changes
        run: |
          if [[ -n $(git status --porcelain) ]]; then
            echo "AI rules are out of date. Run ./sync-ai-rules.sh"
            exit 1
          fi
```

## Base Rules

Base rules are **always loaded** regardless of language/framework:

1. **Git Workflow** - Commit frequency, message format, branching
2. **Code Quality** - Function size, DRY principle, naming conventions
3. **Testing Philosophy** - Coverage goals, test types, never proceed with failing tests
4. **Security Principles** - No hardcoded secrets, input validation, authentication
5. **Development Workflow** - Plan, implement, test, refactor cycle

These provide universal best practices applicable to any project.

## Language-Specific Rules

Language rules provide technology-specific guidance:

### Python
- Type hints (PEP 484)
- pytest testing patterns
- mypy strict mode
- PEP 8 style guide
- Common security patterns

### TypeScript
- Strict mode configuration
- Type safety best practices
- ESLint + Prettier setup
- Zod validation patterns
- Modern JS features

### Go
- Effective Go patterns
- Testing with testify
- Error handling conventions
- Goroutine best practices

### Java
- Spring Boot patterns
- JUnit testing
- Maven/Gradle conventions
- Lombok usage

## Framework-Specific Rules

Framework rules provide specialized guidance:

### React
- Component patterns
- Hook usage
- State management
- Testing with React Testing Library

### Django
- Model design
- View patterns
- DRF best practices
- Testing with pytest-django

### FastAPI
- Async endpoints
- Pydantic models
- Dependency injection
- Testing with TestClient

## Tool-Specific Outputs

Each AI tool has different file conventions:

### Claude Code
- File: `.claude/RULES.md`
- Format: Markdown with sections
- Auto-loaded on startup

### Cursor
- File: `.cursorrules`
- Format: Plain markdown
- Auto-loaded in workspace

### GitHub Copilot
- File: `.github/copilot-instructions.md`
- Format: Markdown instructions
- Referenced in workflow

## Benefits

### 🎯 Two-Phase Progressive Disclosure
**Phase 1:** Load only relevant languages/frameworks (8-12 files vs 50+)
**Phase 2:** Load only relevant tasks within project (2-3 files vs all 8)
**Result:** 74.4% average token savings, validated in real-world testing

### 📊 Measurable Impact
- **86.4% savings** for code reviews
- **55.8% savings** for testing tasks
- **65.9% savings** for framework work
- **59% more context** available for code analysis

### 🔄 Centralized Maintenance
Update rules once, sync to all projects

### 🌍 Organization-wide Standards
Enforce consistent practices across teams

### 🤖 Multi-Tool Support
Works with Claude, Cursor, Copilot, and more

### 📦 No Infrastructure Required
Just Git and bash - works offline after initial sync

### ⚡ Fast Sync
Incremental updates - only download what changed

### 👁️ Visual Feedback
See which rules are active with inline citations and announcements

## Comparison to Codified Rules

| Feature | Centralized Rules | Codified Rules |
|---------|-------------------|----------------|
| **Scope** | Organization-wide | Per-project |
| **Maintenance** | Central repository | Distributed files |
| **Loading** | Progressive/Dynamic | All or nothing |
| **Customization** | Override via config | Direct file edits |
| **Consistency** | Enforced by sync | Manual maintenance |

**Use Centralized Rules when:** You want organization-wide standards

**Use Codified Rules when:** Project has unique requirements

**Use Both:** Centralized for base, local overrides for specifics

## Examples

### Python Project

```bash
# Project structure
myproject/
├── pyproject.toml       # Detected: Python
├── requirements.txt     # Detected: Django, pytest
└── ...

# Run sync
./sync-ai-rules.sh

# Loads:
# - base/* (always)
# - languages/python/*
# - frameworks/django/*

# Generates:
# .claude/RULES.md
# .cursorrules
# .github/copilot-instructions.md
```

### Full-Stack TypeScript Project

```bash
# Project structure
fullstack/
├── package.json         # Detected: TypeScript, React, Express
├── tsconfig.json
└── ...

# Run sync
./sync-ai-rules.sh

# Loads:
# - base/*
# - languages/typescript/*
# - frameworks/react/*
# - frameworks/express/*
```

## Contributing

### Adding a New Language

1. Create `languages/{language}/`
2. Add `coding-standards.md`
3. Add `testing.md`
4. Update detection logic in `sync-ai-rules.sh`

### Adding a New Framework

1. Create `frameworks/{framework}/`
2. Add `best-practices.md`
3. Update detection logic in `sync-ai-rules.sh`

### Adding a New Tool

1. Create `tools/{tool}/` directory
2. Add template files
3. Add `generate_{tool}_rules()` function to script
4. Update documentation

## Roadmap

### ✅ Completed
- ✅ Phase 1: Project-level progressive disclosure
- ✅ Phase 2: Task-level progressive disclosure (hierarchical structure)
- ✅ Config-driven architecture (rules-config.json)
- ✅ Visual feedback system
- ✅ Real-world validation (74.4% token savings)

### 🔜 Short-Term
- [ ] Extend hierarchical format to Cursor/Copilot
- [ ] GitHub Action for automatic sync
- [ ] Rule versioning and rollback

### 📅 Medium-Term
- [ ] Support for more languages (C#, PHP, Swift, Kotlin)
- [ ] Support for more frameworks (Angular, Svelte, Laravel)
- [ ] VS Code extension
- [ ] Usage analytics

### 🚀 Long-Term
- [ ] Domain-specific rules (fintech, healthcare, e-commerce)
- [ ] Compliance frameworks (HIPAA, SOC 2, PCI-DSS)
- [ ] AI-powered rule suggestions
- [ ] Web dashboard

## License

MIT License - See LICENSE file for details

## Related Projects

- [AI Development Patterns](https://github.com/PaulDuvall/ai-development-patterns) - Collection of AI-assisted development patterns
- [Centralized Rules Experiment](https://github.com/PaulDuvall/ai-development-patterns/tree/main/experiments#centralized-rules) - Exploration of progressive disclosure as a solution to instruction saturation
- [Codified Rules Examples](https://github.com/PaulDuvall/ai-development-patterns/tree/main/examples/codified-rules) - Per-project rule examples

## Documentation

- [ARCHITECTURE.md](./ARCHITECTURE.md) - Technical architecture and design decisions
- [USAGE_EXAMPLES.md](./examples/USAGE_EXAMPLES.md) - Detailed usage examples
- [Real-World Test Results](./ARCHITECTURE.md#performance--validation) - Measured token savings and performance

## Research & Validation

**Progressive Disclosure Effectiveness:**
- ✅ Validated with real Python + FastAPI project
- ✅ Measured 55-90% token reduction across task types
- ✅ 74.4% average savings
- ✅ 59% more context available for code
- ✅ Negligible latency impact (<500ms per task)

See [ARCHITECTURE.md](./ARCHITECTURE.md#performance--validation) for complete test results and methodology.

## Support

- **Issues:** [GitHub Issues](https://github.com/PaulDuvall/centralized-rules/issues)
- **Discussions:** [GitHub Discussions](https://github.com/PaulDuvall/centralized-rules/discussions)
- **Documentation:** See [docs/](./docs/) directory

---

**Made with** ❤️ **for AI-assisted development**
