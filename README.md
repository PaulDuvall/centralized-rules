# Centralized AI Development Rules

Progressive disclosure framework for AI coding tools. Loads only relevant development rules based on project context and task type.

## Features

- **MECE Framework** - Mutually Exclusive, Collectively Exhaustive rule organization
- **Progressive Disclosure** - Load only relevant rules (project + task level)
- **Multi-tool Support** - Claude Code, Cursor, GitHub Copilot, Gemini
- **74.4% Token Savings** - Validated in production testing
- **Four-Dimensional Structure** - Base, Language, Framework, Cloud rules

## Quick Start

**Installation (one command, idempotent):**

```bash
curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/main/install-hooks.sh | bash
```

This installs globally (all projects). Safe to run multiple times - it updates in place.

**For project-specific installation:**

```bash
curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/main/install-hooks.sh | bash -s -- --local
```

**Idempotent behavior:**
- Already installed? → Updates it in place
- Not installed? → Installs fresh
- Running it again? → Safely updates to latest version

No prompts, no conflicts, just works.

### What You'll See

Hook displays concise banner showing detected rules:

```
═══════════════════════════════════════════════════════
🎯 Centralized Rules Active | Source: paulduvall/centralized-rules@16c0aa5 | 📊 Rules: ~2.0K tokens (~1%)
🔍 Rules: base/code-quality
💡 Follow standards • Write tests • Ensure security • Refactor
═══════════════════════════════════════════════════════
```

For git operations, pre-commit quality gates trigger:

```
═══════════════════════════════════════════════════════
🎯 Centralized Rules Active | Source: paulduvall/centralized-rules@16c0aa5 | ⚠️ Rules: ~5.1K tokens (~2%)
⚠️ PRE-COMMIT: Tests → Security → Quality → Refactor
🔍 Rules: base/git-tagging, base/git-workflow
💡 Small commits, clear messages - your future self will thank you
═══════════════════════════════════════════════════════
```

### Verify Installation

Check hook is registered:

```bash
/hooks
```

Should show:
```
UserPromptSubmit
  2. $CLAUDE_PROJECT_DIR/.claude/hooks/activate-rules.sh
```

Test with code request - banner appears, Claude follows standards.

## How It Works

Hook script runs on every prompt:

1. **Detect context** - Scans project for language markers (`package.json`, `pyproject.toml`, `go.mod`)
2. **Match keywords** - Analyzes prompt for task-specific terms (test, security, refactor)
3. **Display banner** - Shows which rules apply (~500-5000 tokens overhead)
4. **Claude applies** - Follows detected coding standards

## Architecture

```
centralized-rules/
├── base/          # 23 universal rules (all projects)
├── languages/     # 6+ languages (Python, TypeScript, Go, Java, C#, Rust)
├── frameworks/    # 12+ frameworks (React, Django, FastAPI, Spring Boot, etc.)
└── cloud/         # Cloud providers (AWS, Vercel)
```

## Auto-Detection

**Languages:** Detected via `pyproject.toml`, `package.json`, `go.mod`, `pom.xml`, `Cargo.toml`

**Frameworks:** Parsed from dependency files

**Keywords:**
- Testing: `test`, `pytest`, `jest`, `tdd`
- Security: `auth`, `encrypt`, `validate`
- Git: `commit`, `push`, `pull request`
- Refactoring: `refactor`, `optimize`

## Real-World Results

Python + FastAPI project measurements:

| Task Type | Files Loaded | Token Savings |
|-----------|--------------|---------------|
| Code Review | 2 files | 86.4% |
| Write Tests | 2 files | 55.8% |
| FastAPI Endpoint | 3 files | 65.9% |
| Git Commit | 2 files | 89.6% |
| **Average** | **2.25 files** | **74.4%** |

## Troubleshooting

**Duplicate banner appearing (hook runs twice):**

You've installed both globally AND locally. Remove one installation:

```bash
# Option 1: Remove global hook (keep local)
jq 'del(.hooks.UserPromptSubmit[] | select(.hooks[]?.command | contains("activate-rules.sh")))' \
   ~/.claude/settings.json > ~/.claude/settings.json.tmp && \
   mv ~/.claude/settings.json.tmp ~/.claude/settings.json

# Option 2: Remove local hook (keep global)
jq 'del(.hooks.UserPromptSubmit[] | select(.hooks[]?.command | contains("activate-rules.sh")))' \
   .claude/settings.json > .claude/settings.json.tmp && \
   mv .claude/settings.json.tmp .claude/settings.json
```

Without `jq`:
```bash
# Manually edit the settings file and remove the UserPromptSubmit hook
vim ~/.claude/settings.json  # For global
# OR
vim .claude/settings.json    # For local
```

**Hook not appearing:**
```bash
/hooks  # Check registered hooks
chmod +x .claude/hooks/activate-rules.sh  # Fix permissions
```

**Wrong language detected:**
Create appropriate marker file (`package.json`, `pyproject.toml`, `go.mod`)

**No banner displayed:**
Include keywords in prompt: "Write a Python function **with tests**"

## Customization

Edit `.claude/skills/skill-rules.json` to add keywords:

```json
{
  "keywordMappings": {
    "languages": {
      "python": {
        "keywords": ["python", ".py", "your-keyword"],
        "rules": ["languages/python"]
      }
    }
  }
}
```

Changes take effect immediately.

## Organization Deployment

**Fork repository:**
```bash
export RULES_REPO="https://raw.githubusercontent.com/your-org/centralized-rules/main"
curl -fsSL $RULES_REPO/install-hooks.sh | bash -s -- --global
```

**Commit to projects:**
```bash
cp -r .claude/ your-project-template/
git add .claude/
```

## Documentation

- [Installation Guide](docs/installation.md) - Setup instructions
- [Hook System](docs/hook-system.md) - Automatic rule loading and quality gates
- [Classification System](docs/architecture/classification-system.md) - Prompt classification
- [Bash Code Quality](docs/architecture/BASH_BRITTLE_AREAS.md) - Engineering analysis

## Supported Technologies

**Languages:** Python, TypeScript, JavaScript, Go, Java, C#, Rust

**Frameworks:** React, Next.js, Django, FastAPI, Flask, Express, Spring Boot, NestJS, Vue

**Cloud:** AWS, Vercel

**AI Tools:** Claude Code, Cursor, GitHub Copilot, Continue.dev, Windsurf, Cody, Gemini

## Contributing

Open issues or pull requests at [github.com/paulduvall/centralized-rules](https://github.com/paulduvall/centralized-rules).

## License

MIT License - See LICENSE for details.
