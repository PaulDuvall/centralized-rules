# Centralized Rules - Hook Installation Guide

## The Problem We're Solving

When working with Claude Code, you want consistent coding standards applied automatically. This hook system detects your project's languages and frameworks, then reminds Claude to follow best practices before writing code.

## One-Command Installation

### For Current Project Only

```bash
cd your-project
curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/main/install-hooks.sh | bash
```

### For ALL Your Projects (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/main/install-hooks.sh | bash -s -- --global
```

That's it. No manual configuration needed.

## What Gets Installed

1. **Hook script** (`.claude/hooks/activate-rules.sh`) - Detects context and suggests standards
2. **Keyword mappings** (`.claude/skills/skill-rules.json`) - Maps keywords to rule categories
3. **Hook configuration** (`.claude/settings.json` or `~/.claude/settings.json`) - Registers the hook

## How It Works

```
You: "Write a Python function with tests"
       ↓
Hook detects: Python + testing keywords
       ↓
Hook suggests: Follow Python standards, include tests, add documentation
       ↓
Claude implements with those guidelines
```

## Verification

After installation:

1. **Restart Claude Code**
2. **Run `/hooks`** - you should see:
   ```
   UserPromptSubmit
     2. $CLAUDE_PROJECT_DIR/.claude/hooks/activate-rules.sh
   ```
3. **Test it**:
   ```
   Write a function to process user data
   ```

## Differences: Claude Desktop vs Claude Code CLI

**This implementation is for Claude Code CLI only.**

| Feature | Claude Desktop | Claude Code CLI |
|---------|---------------|-----------------|
| Hook System | ✅ Supported | ✅ Supported |
| Skill() function | ✅ Works | ❌ Not available |
| Skills | TypeScript-based | Filesystem-based (SKILL.md) |
| Configuration | Multiple locations | settings.json only |

If you're using **Claude Desktop**, you need the full skill implementation (not yet available).

## Troubleshooting

### Hook doesn't show in `/hooks`

**Solution**: Make sure settings.json was created correctly:

```bash
cat .claude/settings.json  # Local
cat ~/.claude/settings.json  # Global
```

Should contain:
```json
{
  "hooks": {
    "UserPromptSubmit": [...]
  }
}
```

### Hook shows but doesn't fire

**Test manually**:
```bash
echo '{"prompt":"test"}' | .claude/hooks/activate-rules.sh
```

Should output the evaluation steps. If not, the script has an error.

### Wrong language/framework detected

Edit `.claude/skills/skill-rules.json` to add your project's keywords:

```json
{
  "keywordMappings": {
    "languages": {
      "your_language": {
        "keywords": ["your", "keywords"],
        "rules": ["languages/your_language"]
      }
    }
  }
}
```

## Uninstallation

### Local (project-only)

```bash
rm -rf .claude/hooks .claude/skills
# Remove hook configuration from .claude/settings.json
```

### Global (all projects)

```bash
rm -rf ~/.claude/hooks ~/.claude/skills
# Remove hook configuration from ~/.claude/settings.json
```

## For Repository Maintainers

### Adding This to Your Project

**Option 1: Copy Files** (Simple)
```bash
mkdir -p .claude/hooks .claude/skills
cp path/to/centralized-rules/.claude/hooks/activate-rules.sh .claude/hooks/
cp path/to/centralized-rules/.claude/skills/skill-rules.json .claude/skills/
chmod +x .claude/hooks/activate-rules.sh
```

Add to `.claude/settings.json`:
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

Commit these files to git.

**Option 2: Submodule** (Advanced)
```bash
git submodule add https://github.com/paulduvall/centralized-rules .centralized-rules
ln -s .centralized-rules/.claude/hooks/activate-rules.sh .claude/hooks/
ln -s .centralized-rules/.claude/skills/skill-rules.json .claude/skills/
```

### Customizing for Your Team

Edit `.claude/skills/skill-rules.json` to add:
- Your company's coding standards
- Framework-specific keywords
- Custom rule categories

The hook will automatically use your customizations.

## What This Doesn't Do

❌ Load actual rule content (would exceed context limits)
❌ Enforce rules (Claude can still ignore them)
❌ Work with Claude Desktop (different system)
❌ Guarantee Claude follows guidelines (it's a reminder, not enforcement)

## What This DOES Do

✅ Detect project context automatically
✅ Remind Claude of relevant standards
✅ Work across all your projects (global mode)
✅ Zero manual configuration
✅ Customizable for your team

## Support

- **Issues**: https://github.com/paulduvall/centralized-rules/issues
- **Discussions**: https://github.com/paulduvall/centralized-rules/discussions
- **Documentation**: Full docs at main README.md

## License

MIT - See LICENSE file

---

**Made with lessons learned from real-world Claude Code usage** 🎯
