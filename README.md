# Centralized AI Development Rules

**Progressive Disclosure for AI Coding Tools**

A centralized repository of development rules that dynamically loads only relevant guidelines based on your project's language, framework, and task context. Works with Claude Code CLI, Cursor, GitHub Copilot, and other AI coding assistants.

## 🚀 Quick Start (Claude Code CLI)

Install the automated hook system with one command:

```bash
# Install globally for ALL your projects (recommended)
curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/main/install-hooks.sh | bash -s -- --global

# Or install for current project only
cd your-project
curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/main/install-hooks.sh | bash
```

> **📍 What Actually Happens During Installation**
>
> **Global Install** (recommended):
> - Adds hook to `~/.claude/settings.json`
> - **Automatically applies to ALL projects** that use Claude Code CLI
> - One-time setup, works everywhere instantly
> - No per-project configuration needed
> - **To uninstall**: Remove hooks section from `~/.claude/settings.json` and delete `~/.claude/hooks/`
>
> **Local Install**:
> - Adds hook to `.claude/settings.json` in current project only
> - Only affects this specific project
> - Useful for project-specific customization
> - **To uninstall**: Remove hooks section from `.claude/settings.json` and delete `.claude/hooks/`

**That's it.** No manual configuration needed.

### What You'll See

When you ask Claude to write code, the hook displays evaluation steps showing which coding standards apply:

```
═══════════════════════════════════════════════════════
🎯 MANDATORY SKILL ACTIVATION - DO NOT SKIP
═══════════════════════════════════════════════════════

CRITICAL: Before implementing ANY code, you MUST follow this 3-step process:

STEP 1: EVALUATE which rules apply (list YES/NO for each category):
   - Detected Languages: javascript
   - Detected Frameworks: react

   - Matched Rule Categories:
     [ ] base/code-quality
     [ ] base/testing-philosophy
     [ ] languages/javascript
     [ ] frameworks/react

STEP 2: APPLY relevant coding standards

   Based on the evaluation above, apply these coding principles:
   - Code Quality: Write clean, maintainable code
   - Testing: Include comprehensive tests where appropriate
   - Security: Follow security best practices
   - Language Standards: Follow best practices for the detected languages

STEP 3: IMPLEMENT the task following the identified standards

📋 REMINDER:
   - Follow the coding standards for the detected languages/frameworks
   - Include tests where appropriate
   - Consider security implications
   - Write clear, well-documented code
═══════════════════════════════════════════════════════
```

**Result:** Claude writes higher-quality code with comprehensive tests, input validation, proper error handling, and documentation.

### Verify It's Working

After installation, restart Claude Code and test:

```bash
# 1. Check hook is registered
/hooks

# You should see:
# UserPromptSubmit
#   2. $CLAUDE_PROJECT_DIR/.claude/hooks/activate-rules.sh

# 2. Test with a code request
Write a simple calculator function
```

You should see the evaluation steps displayed above, followed by well-structured code with tests.

## How It Works

```
You type: "Write a Python function with tests"
       ↓
Hook detects: Python language + testing keywords
       ↓
Hook displays: Evaluation steps showing applicable rules
       ↓
Claude implements: Following Python standards, includes pytest tests, adds docstrings
```

**Key Features:**
- ✅ **Auto-detection** - Detects languages/frameworks from your project files
- ✅ **Keyword matching** - Matches your prompt to relevant rule categories
- ✅ **Visible feedback** - Shows which standards are being applied
- ✅ **Progressive disclosure** - Loads only relevant rules, not everything
- ✅ **Zero configuration** - One command installation, works everywhere

## Installation Details

### What Gets Installed

**Local installation** (`.claude/` in current project):
```
your-project/
├── .claude/
│   ├── hooks/
│   │   └── activate-rules.sh       # Hook script
│   ├── skills/
│   │   └── skill-rules.json        # Keyword mappings
│   └── settings.json                # Hook registration
```

**Global installation** (`~/.claude/` for all projects):
```
~/.claude/
├── hooks/
│   └── activate-rules.sh
├── skills/
│   └── skill-rules.json
└── settings.json
```

### How Detection Works

**Language Detection:**
| Language | Detected From |
|----------|---------------|
| Python | `pyproject.toml`, `requirements.txt`, `setup.py` |
| JavaScript/TypeScript | `package.json`, `tsconfig.json` |
| Go | `go.mod` |
| Rust | `Cargo.toml` |
| Java | `pom.xml`, `build.gradle` |

**Framework Detection:**
| Framework | Detected From |
|-----------|---------------|
| React | `"react"` in package.json |
| Next.js | `"next"` in package.json |
| FastAPI | `fastapi` in Python dependencies |
| Django | `django` in Python dependencies |
| Express | `"express"` in package.json |

**Keyword Matching:**
- Testing: `test`, `pytest`, `jest`, `spec`, `tdd`, `coverage`
- Security: `auth`, `password`, `token`, `encrypt`, `validate`
- Git: `commit`, `pull request`, `branch`, `merge`
- Refactoring: `refactor`, `clean`, `improve`, `optimize`

## Troubleshooting

### Hook doesn't appear in `/hooks`

**Check settings file:**
```bash
cat .claude/settings.json  # Local
cat ~/.claude/settings.json  # Global
```

Should contain:
```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "hooks": [{
        "type": "command",
        "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/activate-rules.sh"
      }]
    }]
  }
}
```

**Solution:** Re-run the install script.

### Hook appears but doesn't fire

**Test manually:**
```bash
echo '{"prompt":"Write a test function"}' | .claude/hooks/activate-rules.sh
```

Should output the evaluation steps. If you see an error:

**Common issue:** Script permissions
```bash
chmod +x .claude/hooks/activate-rules.sh
```

**Debug mode:**
```bash
claude --debug
# Then try a code request and check the logs
```

### Wrong language/framework detected

**Check project files:**
```bash
# Python projects need one of:
ls pyproject.toml requirements.txt setup.py

# JavaScript/TypeScript projects need:
ls package.json

# Go projects need:
ls go.mod
```

Create the appropriate marker file and restart Claude Code.

### No evaluation steps appear

This is normal if:
- No keywords match (generic prompts won't trigger rules)
- No project context detected (not in a recognized project directory)

To force detection, include keywords: "Write a Python function **with tests**"

## Alternative: Sync Script (For Other Tools)

If you use **Cursor**, **GitHub Copilot**, or want file-based rules:

```bash
# Download sync script
curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/main/sync-ai-rules.sh \
    -o sync-ai-rules.sh
chmod +x sync-ai-rules.sh

# Run sync
./sync-ai-rules.sh

# Or sync for specific tool
./sync-ai-rules.sh --tool cursor
./sync-ai-rules.sh --tool copilot
```

**Generates:**
- `.claude/AGENTS.md` - Entry point with progressive disclosure
- `.claude/rules/` - Organized rule directory
- `.cursorrules` - Cursor format
- `.github/copilot-instructions.md` - Copilot format

## Rule Architecture

```
centralized-rules/
├── base/                          # Universal rules (always considered)
│   ├── git-workflow.md
│   ├── code-quality.md
│   ├── testing-philosophy.md
│   ├── security-principles.md
│   └── ... (19 more)
│
├── languages/                     # Language-specific standards
│   ├── python/
│   │   ├── coding-standards.md
│   │   └── testing.md
│   ├── typescript/
│   ├── go/
│   ├── java/
│   ├── csharp/
│   └── rust/
│
├── frameworks/                    # Framework-specific patterns
│   ├── react/
│   ├── django/
│   ├── fastapi/
│   ├── express/
│   └── springboot/
│
└── cloud/                         # Cloud provider guidelines
    └── vercel/
```

**Total:** 50+ rule files organized by concern

**Hook approach:** Suggests 3-5 relevant categories per request
**Sync approach:** Loads 8-12 files based on project context

## Progressive Disclosure Benefits

### Two-Phase System

**Phase 1: Project-Level**
- Detects your project's languages/frameworks
- Loads only relevant rules to `.claude/rules/`
- Reduces 50+ files to 8-12 relevant files

**Phase 2: Task-Level** (via hook)
- Matches keywords in your prompt
- Suggests only applicable rule categories
- Reduces 8-12 files to 3-5 categories per request

### Measured Results

Tested with Python + FastAPI project:

| Task Type | Categories Suggested | Token Efficiency |
|-----------|---------------------|------------------|
| Write tests | 2 (testing, python) | 86.4% savings |
| Code review | 2 (code-quality, security) | 86.4% savings |
| API endpoint | 3 (fastapi, security, testing) | 65.9% savings |
| Git commit | 2 (git-workflow, code-quality) | 89.6% savings |
| **Average** | **2-3 categories** | **74.4% savings** |

**Impact:** 59% more context window available for analyzing your code!

## Customization

### Add Custom Keywords

Edit `.claude/skills/skill-rules.json`:

```json
{
  "keywordMappings": {
    "languages": {
      "python": {
        "keywords": ["python", ".py", "pip", "your-custom-keyword"],
        "rules": ["languages/python"]
      }
    }
  }
}
```

### Add Custom Rule Categories

Create your own rules in the hook output by editing `.claude/hooks/activate-rules.sh`.

### Organization-Wide Deployment

**Option 1: Fork this repository**
```bash
# Fork on GitHub, then:
export RULES_REPO="https://raw.githubusercontent.com/your-org/centralized-rules/main"
curl -fsSL $RULES_REPO/install-hooks.sh | bash -s -- --global
```

**Option 2: Commit to projects**
```bash
# Copy hook files to your project template
cp -r .claude/ your-project-template/
git add .claude/
git commit -m "Add centralized rules hook"
```

## Uninstallation

### Local (project only)
```bash
rm -rf .claude/hooks .claude/skills
# Remove hooks section from .claude/settings.json
```

### Global (all projects)
```bash
rm -rf ~/.claude/hooks ~/.claude/skills
# Remove hooks section from ~/.claude/settings.json
```

## What This Does and Doesn't Do

### ✅ Does

- Detects project context automatically (languages, frameworks)
- Matches prompt keywords to relevant rule categories
- Displays evaluation steps showing applicable standards
- Reminds Claude to follow best practices
- Works across all your projects (global mode)
- Improves code quality, testing, security, documentation

### ❌ Doesn't

- Enforce rules (Claude can still ignore them)
- Load actual rule content (would exceed context limits)
- Guarantee perfect code (it's a reminder system)
- Work with Claude Desktop (different hook system)
- Require network access (works offline after install)

## Related Projects

- [AI Development Patterns](https://github.com/PaulDuvall/ai-development-patterns) - Collection of AI-assisted development patterns
- [Centralized Rules Experiment](https://github.com/PaulDuvall/ai-development-patterns/tree/main/experiments#centralized-rules) - Research on progressive disclosure

## Architecture Documentation

For deep technical details:
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Design decisions, performance validation
- [PRACTICE_CROSSREFERENCE.md](./PRACTICE_CROSSREFERENCE.md) - Practice-to-file mapping
- [ANTI_PATTERNS.md](./ANTI_PATTERNS.md) - Common anti-patterns catalog

## Contributing

Contributions welcome! To add:

**New Language:**
1. Create `languages/{language}/coding-standards.md`
2. Add detection logic to install script
3. Update keyword mappings in `skill-rules.json`

**New Framework:**
1. Create `frameworks/{framework}/best-practices.md`
2. Add framework detection logic
3. Update keyword mappings

**New Rule Category:**
1. Create `base/{category}.md`
2. Add keyword patterns to hook script

## Support

- **Issues:** [GitHub Issues](https://github.com/PaulDuvall/centralized-rules/issues)
- **Discussions:** [GitHub Discussions](https://github.com/PaulDuvall/centralized-rules/discussions)

## License

MIT License - See LICENSE file for details

---

**Made with lessons learned from real-world Claude Code usage** 🎯
