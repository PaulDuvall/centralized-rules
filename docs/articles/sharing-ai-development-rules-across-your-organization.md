# Sharing AI Development Rules Across Your Organization

Every developer on your team has their own AI rules file. One person's `CLAUDE.md` says "always write tests." Another's says "use TypeScript strict mode." A third developer just copies whatever worked on their last project. Meanwhile, your AI coding assistants—Claude Code, Cursor, GitHub Copilot, Gemini—are getting inconsistent instructions across every project and every person.

This is the AI rules governance problem, and at scale, it's costing you tokens, consistency, and quality.

I built [centralized-rules](https://github.com/PaulDuvall/centralized-rules) to solve it. The result: **74.4% token savings** and consistent AI behavior across teams of 100+ developers.

## The Enterprise AI Rules Problem

AI coding tools have become standard equipment for development teams. But each tool needs configuration to perform well—Claude Code uses `CLAUDE.md` and `.claude/` directories, Cursor uses `.cursorrules`, GitHub Copilot reads context from your codebase structure.

Without centralization, you get:

- **Tribal knowledge**: Best practices live in individual developers' heads (and their personal config files)
- **Copy-paste chaos**: Teams share rules via Slack, and they drift immediately
- **Onboarding friction**: New developers spend days figuring out "how we do AI here"
- **Token waste**: Loading 25,000+ tokens of rules when you only need 3,000

With hundreds of developers across teams, this becomes ungovernable. You can't audit what instructions your AI tools are receiving. You can't ensure security rules are consistently applied. You can't measure whether your AI development standards are actually being followed.

## The Solution: Centralized Rules with Progressive Disclosure

The core insight is simple: **one source of truth, versioned in Git, with context-aware loading**.

Instead of every developer maintaining their own rules, you maintain a single repository of AI development rules. But here's the key—you don't load all of them all the time. That would overwhelm the AI and waste tokens.

Instead, the system uses **progressive disclosure**:

1. **Detect context**: Scan the project for language markers (`package.json`, `pyproject.toml`, `go.mod`)
2. **Match keywords**: Analyze the prompt for task-specific terms (test, security, refactor)
3. **Display banner**: Show which rules apply (~500-5000 tokens overhead)
4. **Apply rules**: AI follows only the relevant coding standards

The rules themselves are organized in a **four-dimensional structure**:

- **Base**: Universal rules that apply to all projects (git workflow, code quality, security principles)
- **Language**: Language-specific rules (Python, TypeScript, Go, Java, C#, Rust)
- **Framework**: Framework-specific rules (React, Django, FastAPI, Express, Spring Boot)
- **Cloud**: Cloud provider rules (AWS, Vercel, with Azure and GCP extensible)

This follows the **MECE principle** (Mutually Exclusive, Collectively Exhaustive)—no duplication across dimensions, complete coverage of common scenarios.

## How It Works

The install script auto-detects your project configuration:

```
# Language detection
pyproject.toml → Load Python rules
package.json → Load JavaScript/TypeScript rules
go.mod → Load Go rules

# Framework detection
"fastapi" in dependencies → Load FastAPI rules
"react" in dependencies → Load React rules

# Cloud detection
vercel.json → Load Vercel rules
```

At runtime, a hook analyzes each prompt and injects only relevant rules. Here's what you see:

```
═══════════════════════════════════════════════════════════
🎯 Centralized Rules Active | Source: paulduvall/centralized-rules@16c0aa5 | 📊 Rules: ~2.0K t
🔍 Rules: base/code-quality
💡 Follow standards • Write tests • Ensure security • Refactor
═══════════════════════════════════════════════════════════
```

For git operations, pre-commit quality gates trigger automatically:

```
═══════════════════════════════════════════════════════════
🎯 Centralized Rules Active | Source: paulduvall/centralized-rules@16c0aa5 | ⚠️ Rules: ~5.1K t
⚠ PRE-COMMIT: Tests → Security → Quality → Refactor
🔍 Rules: base/git-tagging, base/git-workflow
💡 Small commits, clear messages – your future self will thank you
═══════════════════════════════════════════════════════════
```

### Token Efficiency

Here's the measured impact across different task types:

| Task Type | Files Loaded | Tokens Used | Tokens Saved | Savings |
|-----------|--------------|-------------|--------------|---------|
| Code Review | 2 files | 3,440 | 21,796 | 86.4% |
| Write Tests | 2 files | 11,163 | 14,073 | 55.8% |
| FastAPI Endpoint | 3 files | 8,608 | 16,628 | 65.9% |
| Git Commit | 2 files | 2,618 | 22,618 | 89.6% |
| **Average** | **2.25 files** | **6,457** | **18,779** | **74.4%** |

Before: 25K tokens for rules → 75K available for code.
After: 6K tokens for rules → 94K available for code.

That's **59% more context available for actual code analysis**.

## Quick Start

Installation is one command, and it's idempotent (safe to run multiple times):

```bash
# Global installation (all projects)
curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/main/install-hooks.sh | bash

# Project-specific installation
curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/main/install-hooks.sh | bash -s -- --local
```

That's it. The installer:

- Detects your project's languages and frameworks
- Downloads only the relevant rule files
- Sets up hooks for Claude Code, Cursor, and other tools
- Configures pre-commit quality gates

Already installed? Running it again safely updates to the latest version. No prompts, no conflicts.

## Multi-Tool Support

Currently, centralized-rules works with **Claude Code** via the `.claude/` directory structure and hooks. Support for additional agentic coding tools—including Cursor, GitHub Copilot, and Gemini—is planned for future releases.

## Customization

Enterprises need project-specific overrides without maintaining a full fork. The centralized-rules system now supports this through local overrides, merge strategies, and selective exclusion.

### Local Rule Overrides

Create project-specific rules that layer on top of centralized rules without forking:

```bash
# Create override directory
mkdir -p .claude/rules-local/base

# Add project-specific security requirements
cat > .claude/rules-local/base/security.md << 'EOF'
# Additional Security Requirements
- All API endpoints require authentication
- Rate limiting on public routes
EOF

# Sync with overrides applied
./sync-ai-rules.sh --tool claude
```

### Merge Strategies

Configure how local rules combine with central rules in `.claude/rules-config.local.json`:

```json
{
  "merge_strategy": "extend",
  "overrides": {
    "base/security.md": "replace"
  },
  "exclude": ["base/chaos-engineering.md"]
}
```

Three strategies are available: `extend` (default) appends local rules after central rules, `replace` uses local rules instead of central rules, and `prepend` inserts local rules before central rules.

Preview changes before applying with `./sync-ai-rules.sh --dry-run`.

### Keyword Detection

Add custom keywords to trigger specific rules by editing `.claude/skills/skill-rules.json`:

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

Changes take effect immediately—no restart required.

### Organization Deployment

For enterprise-wide rollout, fork the repository and point installations to your fork:

```bash
export RULES_REPO="https://raw.githubusercontent.com/your-org/centralized-rules/main"
curl -fsSL $RULES_REPO/install-hooks.sh | bash -s -- --global
```

## Versioning

Enterprise teams need predictable, auditable deployments. The centralized-rules system now uses GitHub Releases with semantic versioning, giving you control over which version runs in production.

### Installation Options

By default, installations pull from the latest stable GitHub release:

```bash
# Install latest stable release (default)
curl -fsSL https://github.com/paulduvall/centralized-rules/releases/latest/download/install-hooks.sh | bash
```

Pin to a specific version for reproducible builds:

```bash
# Install specific version
curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/main/install-hooks.sh | bash -s -- --version v0.1.0
```

For developers testing new features before release:

```bash
# Install from main branch (bleeding edge)
curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/main/install-hooks.sh | bash -s -- --edge
```

### Version Strategy

The project follows semantic versioning: MAJOR.MINOR.PATCH where breaking changes increment MAJOR (after v1.0.0), new features increment MINOR, and bug fixes increment PATCH. Pre-1.0 releases (v0.x.x) may include breaking changes in MINOR versions.

For production environments, pin to a specific version and update deliberately. For development environments, `--edge` provides access to the latest features. The system falls back to main branch automatically if no releases exist yet.

## Get Started

The repository is open source under MIT license:

**[github.com/PaulDuvall/centralized-rules](https://github.com/PaulDuvall/centralized-rules)**

Star it, try it, and let me know what rules your team needs.

For enterprise teams looking to implement AI development standards at scale, I offer hands-on workshops through [Redacted Ventures](https://redacted.ventures). We'll help you set up centralized rules, train your team on AI-native development patterns, and measure the impact on code quality and velocity.

---

*Paul Duvall is the founder of Redacted Ventures and author of Continuous Integration. He helps enterprise teams adopt AI-native development practices.*
