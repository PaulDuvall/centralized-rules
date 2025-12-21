# Centralized AI Development Rules

**Progressive Disclosure for AI Coding Tools**

A centralized repository of development rules that dynamically loads only relevant guidelines based on your project's language, framework, and tooling. Works with Claude Code, Cursor, GitHub Copilot, and other AI coding assistants.

## 🎯 Key Features

- **MECE Framework** - Mutually Exclusive, Collectively Exhaustive organization
- **Progressive Disclosure** - Load only what's relevant (project + task level)
- **Multi-tool Support** - Generate outputs for Claude, Cursor, Copilot
- **74.4% Average Token Savings** - Validated in real-world testing
- **Four-Dimensional Structure** - Base, Language, Framework, and Cloud rules

## 🚀 Why Progressive Disclosure?

**The Problem:** Loading all development rules overwhelms AI assistants and creates instruction saturation.

**The Solution:** Two-phase progressive disclosure that loads only relevant rules:

1. **Project-Level** - Detect language/framework, load only relevant rules (8-12 files vs 50+)
2. **Task-Level** - Within project, load only rules for the specific task (2-3 files vs all 8)

**Result:** 59% more context window available for analyzing your code!

## 📊 Real-World Results

Tested with Python + FastAPI project:

| Task Type | Files Loaded | Token Savings |
|-----------|-------------|---------------|
| Code Review | 2 files | 86.4% |
| Write Tests | 2 files | 55.8% |
| FastAPI Endpoint | 3 files | 65.9% |
| Git Commit | 2 files | 89.6% |
| **Average** | **2.25 files** | **74.4%** |

## 🎨 Architecture

```
centralized-rules/
├── base/                          # 23 universal rules (always loaded)
│   ├── git-workflow.md
│   ├── code-quality.md
│   ├── testing-philosophy.md
│   └── ... (20 more)
│
├── languages/                     # 6+ languages supported
│   ├── python/
│   ├── typescript/
│   ├── go/
│   ├── java/
│   ├── csharp/
│   └── rust/
│
├── frameworks/                    # 5+ frameworks supported
│   ├── react/
│   ├── django/
│   ├── fastapi/
│   ├── express/
│   └── springboot/
│
└── cloud/                         # Cloud provider rules
    ├── aws/
    └── vercel/
```

## 🔗 Quick Links

- [**Quick Start**](README.md) - Get started in 5 minutes
- [**Installation**](installation.md) - Detailed installation guide
- [**Architecture**](ARCHITECTURE.md) - Technical deep dive
- [**Usage Examples**](examples/USAGE_EXAMPLES.md) - Real-world examples
- [**Implementation Guide**](IMPLEMENTATION_GUIDE.md) - 8-week rollout plan
- [**Claude Skill**](skill/README.md) - Automatic rule loading for Claude

## 💡 Two Installation Options

### Option 1: Claude Skill (Recommended for Claude Users)

Automatic, hook-based rule loading - no manual syncing required!

```bash
curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/main/skill/install.sh | bash
```

### Option 2: Sync Script (For Cursor, Copilot, or Manual Sync)

Traditional sync-based approach - works with any AI tool.

```bash
# Download the sync script
curl -fsSL https://raw.githubusercontent.com/PaulDuvall/centralized-rules/main/sync-ai-rules.sh \
    -o sync-ai-rules.sh

chmod +x sync-ai-rules.sh

# Auto-detect and sync
./sync-ai-rules.sh
```

## 🌟 What's Different?

Unlike traditional rule files that load everything at once, this system:

- ✅ **Detects** your project context automatically
- ✅ **Loads** only relevant rules (8-12 vs 50+ files)
- ✅ **Adapts** to specific tasks within your project (2-3 files)
- ✅ **Updates** automatically with latest best practices
- ✅ **Saves** 74% of context window on average

## 📚 Supported Technologies

**Languages:** Python, TypeScript, JavaScript, Go, Java, C#, Rust

**Frameworks:** React, Next.js, Django, FastAPI, Flask, Express, Spring Boot

**Cloud:** AWS, Vercel (Azure and GCP coming soon)

**AI Tools:** Claude Code, Cursor, GitHub Copilot, Continue.dev, Windsurf, Cody, Gemini

## 🤝 Contributing

We welcome contributions! Open an issue or pull request on [GitHub](https://github.com/PaulDuvall/centralized-rules).

## 📖 Documentation

- [Architecture Overview](ARCHITECTURE.md)
- [Implementation Guide](IMPLEMENTATION_GUIDE.md)
- [Anti-Patterns to Avoid](ANTI_PATTERNS.md)
- [Success Metrics](SUCCESS_METRICS.md)
- [Practice Cross-Reference](PRACTICE_CROSSREFERENCE.md)

## 📄 License

MIT License - See [LICENSE](LICENSE.md) for details

---

**Part of the [AI Development Patterns Experiments](https://github.com/PaulDuvall/ai-development-patterns/tree/main/experiments#centralized-rules)**
