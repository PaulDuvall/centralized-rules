# Centralized AI Development Rules

**Progressive Disclosure for AI Coding Tools**

A centralized repository of development rules that dynamically loads only relevant guidelines based on your project's language, framework, and tooling. Works with Claude Code, Cursor, GitHub Copilot, and other AI coding assistants.

## Overview

Instead of maintaining separate rule files in each project, this repository provides:

- **Universal base rules** - Language-agnostic best practices
- **Language-specific rules** - Python, TypeScript, Go, Java, Ruby, Rust
- **Framework-specific rules** - React, Django, FastAPI, Express, Spring Boot, etc.
- **Progressive disclosure** - Load only what's relevant to your project
- **Multi-tool support** - Generate outputs for Claude, Cursor, Copilot

## Architecture

```
centralized-rules/
├── base/                          # Universal rules (always loaded)
│   ├── git-workflow.md
│   ├── code-quality.md
│   ├── testing-philosophy.md
│   ├── security-principles.md
│   └── development-workflow.md
│
├── languages/                     # Language-specific rules
│   ├── python/
│   │   ├── coding-standards.md
│   │   └── testing.md
│   ├── typescript/
│   │   ├── coding-standards.md
│   │   └── testing.md
│   ├── go/
│   ├── java/
│   ├── ruby/
│   └── rust/
│
├── frameworks/                    # Framework-specific rules
│   ├── react/
│   │   └── best-practices.md
│   ├── django/
│   │   └── best-practices.md
│   ├── fastapi/
│   ├── express/
│   └── springboot/
│
├── tools/                         # Tool-specific templates
│   ├── claude/
│   ├── cursor/
│   └── copilot/
│
└── sync-ai-rules.sh              # Progressive disclosure script
```

## Quick Start

### 1. Add to Your Project

```bash
# Download the sync script
curl -fsSL https://raw.githubusercontent.com/yourusername/centralized-rules/main/sync-ai-rules.sh \
    -o sync-ai-rules.sh

chmod +x sync-ai-rules.sh
```

### 2. Run Sync

```bash
# Auto-detect and sync for all AI tools
./sync-ai-rules.sh

# Or sync for specific tool
./sync-ai-rules.sh --tool claude
./sync-ai-rules.sh --tool cursor
./sync-ai-rules.sh --tool copilot
```

### 3. Use with AI Tools

The script generates tool-specific files:

- **Claude Code:** `.claude/RULES.md`
- **Cursor:** `.cursorrules`
- **GitHub Copilot:** `.github/copilot-instructions.md`

Your AI assistant will automatically use these rules!

## Progressive Disclosure

The sync script automatically detects your project and loads only relevant rules:

### Example: Python + FastAPI Project

**Detected:**
- Language: Python (via `pyproject.toml`)
- Framework: FastAPI (via dependencies)

**Loaded Rules:**
- ✅ Base rules (git, code quality, testing, security)
- ✅ Python rules (type hints, pytest, mypy)
- ✅ FastAPI rules (endpoints, async, validation)
- ❌ TypeScript rules (not loaded)
- ❌ React rules (not loaded)

This prevents overwhelming the AI with irrelevant guidelines!

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

### 🎯 Progressive Disclosure
Load only relevant rules - prevent AI instruction saturation

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

- [ ] Support for more languages (C#, PHP, Swift, Kotlin)
- [ ] Support for more frameworks (Angular, Svelte, Laravel)
- [ ] Domain-specific rules (fintech, healthcare, e-commerce)
- [ ] Compliance frameworks (HIPAA, SOC 2, PCI-DSS)
- [ ] VS Code extension
- [ ] GitHub Action for automatic sync
- [ ] Rule versioning and rollback

## License

MIT License - See LICENSE file for details

## Related Projects

- [AI Development Patterns](https://github.com/PaulDuvall/ai-development-patterns) - Collection of AI-assisted development patterns
- [Codified Rules Examples](https://github.com/PaulDuvall/ai-development-patterns/tree/main/examples/codified-rules) - Per-project rule examples

## Support

- **Issues:** [GitHub Issues](https://github.com/yourusername/centralized-rules/issues)
- **Discussions:** [GitHub Discussions](https://github.com/yourusername/centralized-rules/discussions)
- **Documentation:** See [docs/](./docs/) directory

---

**Made with** ❤️ **for AI-assisted development**
