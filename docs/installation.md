# Installation Guide

This guide covers detailed installation instructions for all supported AI tools.

## Prerequisites

- Git installed
- Bash shell (macOS, Linux, or WSL on Windows)
- One of the supported AI tools:
  - Claude Code
  - Cursor
  - GitHub Copilot
  - Continue.dev
  - Windsurf
  - Sourcegraph Cody
  - Google Gemini/Codegemma

## Installation Methods

Choose the installation method that best fits your workflow:

### Method 1: Claude Skill (Recommended for Claude Users)

**Automatic, hook-based rule loading** - No manual syncing required!

#### Step 1: Run the Installation Script

```bash
curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/main/skill/install.sh | bash
```

This script will:
- Clone the repository to `~/centralized-rules`
- Install and build the Claude Skill
- Show you how to configure Claude

#### Step 2: Configure Claude

Add to your Claude configuration (`~/.config/claude/claude_desktop_config.json`):

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

#### Step 3: Restart Claude

Restart Claude Code for the skill to take effect.

#### How It Works

- Automatically detects your project context (language, framework, cloud provider)
- Intelligently loads only 3-5 relevant rules per request
- No context window bloat - uses progressive disclosure
- Always fetches latest rules from GitHub
- Zero manual sync required

**[Full Skill Documentation →](../skill/README.md)**

---

### Method 2: Sync Script (All AI Tools)

**Traditional sync-based approach** - Works with any AI tool.

#### Step 1: Download the Sync Script

```bash
# Navigate to your project directory
cd /path/to/your/project

# Download the sync script
curl -fsSL https://raw.githubusercontent.com/PaulDuvall/centralized-rules/main/sync-ai-rules.sh \
    -o sync-ai-rules.sh

# Make it executable
chmod +x sync-ai-rules.sh
```

#### Step 2: Run the Sync Script

```bash
# Auto-detect and sync for all AI tools
./sync-ai-rules.sh

# Or sync for specific tool
./sync-ai-rules.sh --tool claude
./sync-ai-rules.sh --tool cursor
./sync-ai-rules.sh --tool copilot
```

#### Step 3: Verify Generated Files

The script generates tool-specific files:

**Claude Code (Hierarchical - Recommended):**
- `.claude/AGENTS.md` - Entry point with discovery instructions
- `.claude/rules/` - Organized rule directory (on-demand loading)
- `.claude/rules/index.json` - Machine-readable rule index

**Cursor:**
- `.cursorrules` - Monolithic format

**GitHub Copilot:**
- `.github/copilot-instructions.md` - Monolithic format

Your AI assistant will automatically use these rules!

---

## Auto-Detection

The sync script automatically detects your project and loads only relevant rules.

### Languages Detected

| Language   | Detection Files                          |
|------------|------------------------------------------|
| Python     | `pyproject.toml`, `setup.py`, `requirements.txt` |
| TypeScript | `package.json` with `"typescript"`       |
| JavaScript | `package.json` without TypeScript        |
| Go         | `go.mod`                                 |
| Java       | `pom.xml`, `build.gradle`                |
| Ruby       | `Gemfile`                                |
| Rust       | `Cargo.toml`                             |

### Frameworks Detected

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

### Cloud Providers Detected

| Provider | Detection Method                        |
|----------|-----------------------------------------|
| AWS      | AWS CDK, CloudFormation, SAM templates  |
| Vercel   | `vercel.json`, Vercel environment vars  |
| Azure    | Azure-specific config files             |
| GCP      | GCP-specific config files               |

---

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

---

## Automation

### Pre-commit Hook

Keep rules synced automatically:

```bash
# .git/hooks/pre-commit
#!/bin/bash
./sync-ai-rules.sh --tool all
git add .claude/RULES.md .cursorrules .github/copilot-instructions.md
```

Make it executable:

```bash
chmod +x .git/hooks/pre-commit
```

### CI/CD Validation

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

---

## Troubleshooting

### Rules Not Loading

1. **Check file existence:**
   ```bash
   ls -la .claude/RULES.md .cursorrules .github/copilot-instructions.md
   ```

2. **Re-run sync script:**
   ```bash
   ./sync-ai-rules.sh --tool all
   ```

3. **Verify detection:**
   ```bash
   ./sync-ai-rules.sh --dry-run
   ```

### Wrong Rules Loaded

1. **Check detection logic:**
   ```bash
   ./sync-ai-rules.sh --verbose
   ```

2. **Override with config:**
   Create `.ai/sync-config.json` with explicit settings

### Sync Script Fails

1. **Check network connectivity:**
   ```bash
   curl -I https://raw.githubusercontent.com/PaulDuvall/centralized-rules/main/README.md
   ```

2. **Check permissions:**
   ```bash
   chmod +x sync-ai-rules.sh
   ```

3. **Check bash version:**
   ```bash
   bash --version
   ```

---

## Updating Rules

### Manual Update

```bash
./sync-ai-rules.sh
```

### Automatic Update (Pre-commit Hook)

See [Automation](#automation) section above.

### Check for Updates

The sync script always downloads the latest rules from GitHub. To see what changed:

```bash
git diff .claude/RULES.md
git diff .cursorrules
```

---

## Uninstallation

### Remove Generated Files

```bash
rm -rf .claude/RULES.md .claude/rules/ .cursorrules .github/copilot-instructions.md
```

### Remove Sync Script

```bash
rm sync-ai-rules.sh
```

### Remove Claude Skill

```bash
# Remove from Claude config
nano ~/.config/claude/claude_desktop_config.json

# Remove repository
rm -rf ~/centralized-rules
```

---

## Next Steps

- [Usage Examples](../examples/USAGE_EXAMPLES.md) - See real-world examples
- [Architecture Overview](../ARCHITECTURE.md) - Understand how it works
- [Implementation Guide](../IMPLEMENTATION_GUIDE.md) - Plan your rollout
- [Contributing](https://github.com/PaulDuvall/centralized-rules/issues) - Contribute improvements

---

## Support

- **Issues:** [GitHub Issues](https://github.com/PaulDuvall/centralized-rules/issues)
- **Discussions:** [GitHub Discussions](https://github.com/PaulDuvall/centralized-rules/issues)
- **Documentation:** See the docs directory in the repository
