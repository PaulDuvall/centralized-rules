# Centralized AI Rules Architecture

## Overview

This repository implements a **progressive disclosure** system for AI development rules that dynamically loads only relevant guidelines based on project context.

## Core Concepts

### 1. Progressive Disclosure

**Problem:** Loading all rules overwhelms AI assistants and creates instruction saturation.

**Solution:** Dynamically load only rules relevant to the current project's language, framework, and tooling.

**Example:**
```
Python + FastAPI project → loads Python + FastAPI rules only
TypeScript + React project → loads TypeScript + React rules only
```

### 2. Multi-Dimensional Organization

Rules are organized across three dimensions:

#### Dimension 1: Scope (Base vs Specific)
- **Base:** Universal rules (git, testing, security)
- **Language:** Language-specific (Python, TypeScript, Go)
- **Framework:** Framework-specific (React, Django, FastAPI)

#### Dimension 2: Language
- Python
- TypeScript/JavaScript
- Go
- Java
- Ruby
- Rust
- (extensible)

#### Dimension 3: Tool
- Claude Code (`.claude/RULES.md`)
- Cursor (`.cursorrules`)
- GitHub Copilot (`.github/copilot-instructions.md`)
- (extensible)

### 3. Detection-Based Loading

The sync script auto-detects project configuration:

```bash
# Detection logic
if exists("pyproject.toml") → Load Python rules
if exists("package.json") → Load JS/TS rules
if contains("django") → Load Django rules
if contains("react") → Load React rules
```

## Directory Structure

```
centralized-rules/
│
├── base/                          # Universal rules (always loaded)
│   ├── git-workflow.md           # Git best practices
│   ├── code-quality.md           # Universal code quality
│   ├── testing-philosophy.md     # Testing principles
│   ├── security-principles.md    # Security best practices
│   └── development-workflow.md   # Dev lifecycle
│
├── languages/                     # Language-specific rules
│   ├── python/
│   │   ├── coding-standards.md   # Python style, types, mypy
│   │   └── testing.md            # pytest, coverage
│   ├── typescript/
│   │   ├── coding-standards.md   # TS style, types, ESLint
│   │   └── testing.md            # Jest, Vitest
│   ├── go/
│   ├── java/
│   ├── ruby/
│   └── rust/
│
├── frameworks/                    # Framework-specific rules
│   ├── react/
│   │   └── best-practices.md     # Hooks, components, performance
│   ├── django/
│   │   └── best-practices.md     # Models, views, DRF
│   ├── fastapi/
│   │   └── best-practices.md     # Async, Pydantic, endpoints
│   ├── express/
│   ├── nextjs/
│   ├── vue/
│   └── springboot/
│
├── tools/                         # Tool-specific templates
│   ├── claude/
│   ├── cursor/
│   └── copilot/
│
├── examples/                      # Usage examples
│   ├── sync-config.json          # Configuration example
│   └── USAGE_EXAMPLES.md         # Detailed examples
│
├── archive/                       # Old project-specific files
│
├── sync-ai-rules.sh              # Main sync script
├── README.md                      # Main documentation
├── MIGRATION_GUIDE.md            # Migration from old format
└── ARCHITECTURE.md               # This file
```

## Data Flow

```
┌─────────────────┐
│ Project Files   │
│ (pyproject.toml,│
│  package.json,  │
│  go.mod, etc.)  │
└────────┬────────┘
         │
         v
┌─────────────────┐
│ Detection Logic │
│ (sync-ai-rules) │
└────────┬────────┘
         │
         v
┌─────────────────┐      ┌──────────────┐
│ Base Rules      │◄─────┤ Always Load  │
└─────────────────┘      └──────────────┘
         │
         v
┌─────────────────┐      ┌──────────────┐
│ Language Rules  │◄─────┤ If Detected  │
└─────────────────┘      └──────────────┘
         │
         v
┌─────────────────┐      ┌──────────────┐
│ Framework Rules │◄─────┤ If Detected  │
└─────────────────┘      └──────────────┘
         │
         v
┌─────────────────┐
│ Tool Generator  │
│ (Claude/Cursor/ │
│  Copilot)       │
└────────┬────────┘
         │
         v
┌─────────────────┐
│ Generated Files │
│ .claude/RULES.md│
│ .cursorrules    │
│ .github/...     │
└─────────────────┘
```

## Components

### 1. Sync Script (`sync-ai-rules.sh`)

**Responsibilities:**
- Detect project language(s)
- Detect framework(s)
- Download relevant rules
- Cache rules locally
- Generate tool-specific outputs

**Key Functions:**
```bash
detect_language()      # Auto-detect from project files
detect_frameworks()    # Auto-detect from dependencies
load_base_rules()      # Always load universal rules
load_language_rules()  # Load if language detected
load_framework_rules() # Load if framework detected
generate_*_rules()     # Generate tool-specific outputs
```

### 2. Base Rules

**Characteristics:**
- Language-agnostic
- Framework-agnostic
- Always loaded
- Universal best practices

**Content:**
- Git workflow
- Code quality standards
- Testing philosophy
- Security principles
- Development workflow

### 3. Language Rules

**Characteristics:**
- Language-specific
- Loaded if language detected
- Technology-specific tooling

**Content Examples:**
- Type system usage
- Testing frameworks
- Linting/formatting tools
- Package management
- Language-specific patterns

### 4. Framework Rules

**Characteristics:**
- Framework-specific
- Loaded if framework detected
- Built on language rules

**Content Examples:**
- Framework patterns
- Best practices
- Common pitfalls
- Performance optimization
- Testing strategies

## Extension Points

### Adding a New Language

1. Create `languages/{language}/` directory
2. Add `coding-standards.md`
3. Add `testing.md`
4. Update `detect_language()` in sync script
5. Update documentation

### Adding a New Framework

1. Create `frameworks/{framework}/` directory
2. Add `best-practices.md`
3. Update `detect_frameworks()` in sync script
4. Update documentation

### Adding a New Tool

1. Create `tools/{tool}/` directory
2. Add template files
3. Add `generate_{tool}_rules()` function
4. Update main sync logic
5. Update documentation

## Design Decisions

### Why Bash Script?

- **Portability:** Works on any Unix-like system
- **Simplicity:** No runtime dependencies
- **Transparency:** Easy to read and audit
- **Offline Support:** Can work with cached rules

### Why Markdown?

- **Readability:** Human-readable format
- **Compatibility:** Works with all AI tools
- **Version Control:** Git-friendly
- **Extensibility:** Easy to add metadata

### Why Progressive Disclosure?

- **Reduces Noise:** AI sees only relevant rules
- **Improves Accuracy:** Focused instructions
- **Scales Better:** Works across many projects
- **Faster Loading:** Less data to process

### Why Detection-Based?

- **Zero Configuration:** Works out of the box
- **Automatic Updates:** Adapts as project evolves
- **Consistent:** Same logic across projects
- **Override-able:** Can use config when needed

## Configuration

### Auto-Detection (Default)

```bash
./sync-ai-rules.sh
# Detects: pyproject.toml → Python
# Detects: dependencies → Django, FastAPI
# Loads: base/* + languages/python/* + frameworks/{django,fastapi}/*
```

### Manual Configuration

```json
{
  "languages": ["python", "typescript"],
  "frameworks": ["django", "react"],
  "exclude": ["testing-mocking"],
  "custom_rules": ["https://company.com/custom.md"]
}
```

### Environment Variables

```bash
export AI_RULES_REPO="https://your-org.com/rules"
./sync-ai-rules.sh
```

## Scaling

### Organization-Wide Deployment

1. Fork repository
2. Customize base rules
3. Add organization-specific rules
4. Distribute sync script to teams
5. Automate with CI/CD

### Multi-Project Support

```bash
# Monorepo with multiple languages
monorepo/
├── backend/ (Python + FastAPI)
├── frontend/ (TypeScript + React)
└── sync-ai-rules.sh (detects both)
```

### Caching Strategy

```
.ai-rules/.cache/
├── base/
├── languages/
└── frameworks/

# Downloaded once, used offline
# Re-downloaded on cache miss
```

## Security

### No Code Execution

- Rules are markdown only
- No executable code in rules
- Safe to load from remote sources

### HTTPS by Default

- All downloads use HTTPS
- Validates SSL certificates
- Fails closed on network errors

### Audit Trail

- All downloads logged
- Cache timestamps tracked
- Version information included

## Performance

### Optimization Strategies

1. **Caching:** Download once, use many times
2. **Lazy Loading:** Only load what's needed
3. **Parallel Downloads:** Fetch rules concurrently
4. **Compression:** Minimize network transfer

### Benchmarks

- **Initial sync:** ~2-5 seconds
- **Cached sync:** ~0.5-1 second
- **Generated output:** ~1-2 seconds

## Future Enhancements

### Planned Features

- [ ] Rule versioning
- [ ] Conflict resolution
- [ ] A/B testing for rules
- [ ] Analytics on rule usage
- [ ] VS Code extension
- [ ] GitHub Action
- [ ] Web dashboard

### Extensibility

The architecture supports:
- Domain-specific rules (fintech, healthcare)
- Compliance frameworks (HIPAA, SOC 2)
- Company-specific standards
- Team-level customization

## References

- [README.md](./README.md) - Usage and quick start
- [MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md) - Migrating from old format
- [USAGE_EXAMPLES.md](./examples/USAGE_EXAMPLES.md) - Detailed examples
