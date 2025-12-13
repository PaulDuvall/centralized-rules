# Usage Examples

## Example 1: Python + FastAPI Project

### Project Structure

```
myapi/
├── pyproject.toml
├── requirements.txt
├── src/
│   └── main.py
└── tests/
    └── test_main.py
```

### Running Sync

```bash
# Download sync script
curl -fsSL https://raw.githubusercontent.com/PaulDuvall/centralized-rules/main/sync-ai-rules.sh \
    -o sync-ai-rules.sh
chmod +x sync-ai-rules.sh

# Run sync (auto-detects Python + FastAPI)
./sync-ai-rules.sh
```

### What Gets Loaded

```
✓ base/git-workflow.md
✓ base/code-quality.md
✓ base/testing-philosophy.md
✓ base/security-principles.md
✓ base/development-workflow.md
✓ languages/python/coding-standards.md
✓ languages/python/testing.md
✓ frameworks/fastapi/best-practices.md
```

### Generated Files

- `.claude/RULES.md` - For Claude Code
- `.cursorrules` - For Cursor
- `.github/copilot-instructions.md` - For GitHub Copilot

---

## Example 2: Full-Stack TypeScript Project

### Project Structure

```
fullstack/
├── package.json          # Dependencies: react, express, typescript
├── tsconfig.json
├── client/
│   └── src/
└── server/
    └── src/
```

### package.json

```json
{
  "dependencies": {
    "react": "^18.0.0",
    "express": "^4.18.0"
  },
  "devDependencies": {
    "typescript": "^5.0.0"
  }
}
```

### Running Sync

```bash
./sync-ai-rules.sh --tool claude
```

### What Gets Loaded

```
✓ base/* (all base rules)
✓ languages/typescript/*
✓ frameworks/react/*
✓ frameworks/express/*
```

---

## Example 3: Custom Configuration

### .ai/sync-config.json

```json
{
  "languages": ["python"],
  "frameworks": ["django"],
  "exclude": ["testing-mocking"],
  "custom_rules": [
    "https://company.com/internal-standards.md"
  ]
}
```

### Running Sync

```bash
./sync-ai-rules.sh
```

This will:
- Load only Python rules (override auto-detection)
- Load only Django framework rules
- Skip testing-mocking.md
- Include custom company standards

---

## Example 4: CI/CD Integration

### GitHub Actions Workflow

```yaml
# .github/workflows/sync-ai-rules.yml
name: Sync AI Rules

on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday
  workflow_dispatch:      # Manual trigger

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Download sync script
        run: |
          curl -fsSL https://raw.githubusercontent.com/PaulDuvall/centralized-rules/main/sync-ai-rules.sh \
            -o sync-ai-rules.sh
          chmod +x sync-ai-rules.sh

      - name: Sync AI rules
        run: ./sync-ai-rules.sh

      - name: Create Pull Request
        uses: peter-evans/create-pull-request@v5
        with:
          commit-message: 'chore: update AI rules'
          title: 'Update AI Development Rules'
          body: 'Automated sync of centralized AI development rules'
          branch: update-ai-rules
```

---

## Example 5: Pre-commit Hook

### .git/hooks/pre-commit

```bash
#!/bin/bash

# Sync AI rules before commit
./sync-ai-rules.sh --tool all

# Stage generated files
git add .claude/RULES.md .cursorrules .github/copilot-instructions.md

echo "✓ AI rules synced"
```

Make it executable:

```bash
chmod +x .git/hooks/pre-commit
```

---

## Example 6: Multi-Language Project

### Project Structure

```
monorepo/
├── backend/
│   ├── go.mod          # Go API
│   └── main.go
├── frontend/
│   ├── package.json    # React TypeScript
│   └── src/
└── sync-ai-rules.sh
```

### What Gets Auto-Detected

```
Detected languages: go typescript
Detected frameworks: react
```

### Loaded Rules

```
✓ base/*
✓ languages/go/*
✓ languages/typescript/*
✓ frameworks/react/*
```

---

## Example 7: Environment-Specific Rules

### Development Environment

```bash
# Use local rules repository during development
export AI_RULES_REPO="http://localhost:8000/rules"
./sync-ai-rules.sh
```

### Production Environment

```bash
# Use production rules from CDN
export AI_RULES_REPO="https://cdn.company.com/ai-rules"
./sync-ai-rules.sh
```

---

## Example 8: Offline Usage

### Initial Sync (Online)

```bash
# Download all rules to cache
./sync-ai-rules.sh
```

### Subsequent Syncs (Offline)

```bash
# Uses cached rules (no network required)
./sync-ai-rules.sh
```

Rules are cached in `.ai-rules/.cache/`

---

## Example 9: Team-Specific Customization

### Team A (Backend Team)

```json
{
  "languages": ["python", "go"],
  "frameworks": ["fastapi", "gin"],
  "custom_rules": [
    "https://company.com/backend-standards.md"
  ]
}
```

### Team B (Frontend Team)

```json
{
  "languages": ["typescript"],
  "frameworks": ["react", "nextjs"],
  "custom_rules": [
    "https://company.com/frontend-standards.md"
  ]
}
```

---

## Example 10: Validation in CI

### .github/workflows/validate-rules.yml

```yaml
name: Validate AI Rules

on: [pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Sync rules
        run: ./sync-ai-rules.sh

      - name: Check for outdated rules
        run: |
          if [[ -n $(git status --porcelain) ]]; then
            echo "❌ AI rules are out of date"
            echo "Run: ./sync-ai-rules.sh"
            exit 1
          fi
          echo "✓ AI rules are up to date"
```

---

## Common Commands

### Sync for Specific Tool

```bash
# Claude only
./sync-ai-rules.sh --tool claude

# Cursor only
./sync-ai-rules.sh --tool cursor

# Copilot only
./sync-ai-rules.sh --tool copilot

# All tools (default)
./sync-ai-rules.sh --tool all
```

### Custom Rules Repository

```bash
# Use custom repository
export AI_RULES_REPO="https://github.com/myorg/our-rules/main"
./sync-ai-rules.sh
```

### Force Refresh

```bash
# Clear cache and re-download
rm -rf .ai-rules/.cache
./sync-ai-rules.sh
```

### Dry Run (See What Would Be Loaded)

```bash
# Add to sync-ai-rules.sh or create wrapper
./sync-ai-rules.sh --dry-run  # (would need to add this feature)
```

---

## Troubleshooting

### Issue: Rules Not Loading

**Check detection:**
```bash
# Add debug output to script
set -x
./sync-ai-rules.sh
```

### Issue: Network Errors

**Use cached rules:**
```bash
# Rules are cached in .ai-rules/.cache/
# Script will use cache if network fails
```

### Issue: Wrong Language Detected

**Use manual configuration:**
```json
{
  "languages": ["python"],  // Override auto-detection
  "frameworks": ["django"]
}
```

---

## Best Practices

1. **Commit generated files** - Include `.claude/RULES.md`, etc. in git
2. **Run sync regularly** - Keep rules up to date (weekly/monthly)
3. **Review updates** - Check changes before committing
4. **Use pre-commit hooks** - Automate sync process
5. **Customize per team** - Use config files for team-specific needs
6. **Cache for offline** - Keep `.ai-rules/.cache/` for offline work
7. **Validate in CI** - Ensure rules stay current in pull requests
