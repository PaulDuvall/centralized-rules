# Centralized AI Development Rules

Progressive disclosure framework for AI coding tools. Loads only relevant development rules based on project context and task type.

## Features

- **MECE Framework** - Mutually Exclusive, Collectively Exhaustive rule organization
- **Progressive Disclosure** - Load only relevant rules (project + task level)
- **Multi-tool Support** - Claude Code, Cursor, GitHub Copilot, Gemini
- **74.4% Token Savings** - Validated in production testing
- **Four-Dimensional Structure** - Base, Language, Framework, Cloud rules

## Quick Start

Install globally:

```bash
curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/main/install-hooks.sh | bash -s -- --global
```

Start coding - rules load automatically.

## Architecture

```
centralized-rules/
├── base/          # 23 universal rules (all projects)
├── languages/     # 6+ languages (Python, TypeScript, Go, Java, C#, Rust)
├── frameworks/    # 12+ frameworks (React, Django, FastAPI, Spring Boot, etc.)
└── cloud/         # Cloud providers (AWS, Vercel)
```

## Real-World Results

Python + FastAPI project measurements:

| Task Type | Files Loaded | Token Savings |
|-----------|--------------|---------------|
| Code Review | 2 files | 86.4% |
| Write Tests | 2 files | 55.8% |
| FastAPI Endpoint | 3 files | 65.9% |
| Git Commit | 2 files | 89.6% |
| **Average** | **2.25 files** | **74.4%** |

## Documentation

- [Installation Guide](installation.md) - Setup instructions
- [Hook System](hook-system.md) - Automatic rule loading and quality gates
- [Ralph Loop Guide](ralph-loop-guide.md) - Iterative task completion with caffeinate
- [Classification System](architecture/classification-system.md) - Prompt classification architecture
- [Bash Code Quality](architecture/BASH_BRITTLE_AREAS.md) - Engineering analysis

## Supported Technologies

**Languages:** Python, TypeScript, JavaScript, Go, Java, C#, Rust

**Frameworks:** React, Next.js, Django, FastAPI, Flask, Express, Spring Boot, NestJS, Vue, Gin, Fiber

**Cloud:** AWS, Vercel

**AI Tools:** Claude Code, Cursor, GitHub Copilot, Continue.dev, Windsurf, Cody, Gemini

## Contributing

Open issues or pull requests at [github.com/paulduvall/centralized-rules](https://github.com/paulduvall/centralized-rules).

## License

MIT License - See [LICENSE](../LICENSE) for details.
