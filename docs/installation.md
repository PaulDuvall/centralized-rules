# Installation

## Prerequisites

- Git
- Bash shell (macOS, Linux, WSL)
- Claude Code, Cursor, GitHub Copilot, Continue.dev, Windsurf, Cody, or Gemini

## Global Installation (Recommended)

Install once, apply to all projects:

```bash
curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/main/install-hooks.sh | bash -s -- --global
```

Adds hook to Claude Code global settings. Every project gets automatic rule loading.

## Local Installation

Install to specific project:

```bash
cd /path/to/your/project
curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/main/install-hooks.sh | bash
```

Creates `.claude/` directory structure with hooks and cached rules.

## Verification

Check installation:

```bash
ls -la .claude/hooks/activate-rules.sh
ls -la ~/.claude/cache/centralized-rules/
```

Start Claude Code - rules load automatically on first prompt.

## Auto-Detection

Hook automatically detects project context and loads relevant rules.

**Languages:** Detected via `pyproject.toml`, `package.json`, `go.mod`, `pom.xml`, `Cargo.toml`

**Frameworks:** Parsed from dependency files (`package.json`, Python requirements, Java build files)

**Cloud Providers:** Identified via `cdk.json`, `vercel.json`, Terraform configs

## Customization

### Override Detection

Create `.ai/sync-config.json`:

```json
{
  "languages": ["python", "typescript"],
  "frameworks": ["fastapi", "react"],
  "exclude": ["testing-mocking"]
}
```

### Custom Rules Repository

```bash
export AI_RULES_REPO="https://raw.githubusercontent.com/your-org/your-rules/main"
curl -fsSL $AI_RULES_REPO/install-hooks.sh | bash -s -- --global
```

## Troubleshooting

**Rules not loading:**
```bash
ls -la .claude/hooks/activate-rules.sh
chmod +x .claude/hooks/activate-rules.sh
```

**Wrong rules detected:**
Create `.ai/sync-config.json` with explicit language/framework settings.

**Network issues:**
```bash
curl -I https://raw.githubusercontent.com/paulduvall/centralized-rules/main/README.md
```

## Uninstall

Remove global hooks:

```bash
rm -rf ~/.claude/hooks/activate-rules.sh
rm -rf ~/.claude/cache/centralized-rules/
```

Remove local installation:

```bash
rm -rf .claude/
```
