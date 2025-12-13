# Migration Guide: From Project-Specific to Centralized Rules

## What Changed

This repository has been updated from project-specific rules to a **centralized, progressive disclosure system** that works across any project and AI tool.

### Before (Project-Specific)

```
centralized-rules/
├── README.md (specific to one project)
├── ai-integration.md (mentions MoviePy, FFmpeg, Whisper)
├── testing-mocking.md (Python-specific)
└── ... (all Python/video-processing specific)
```

**Problems:**
- ❌ Rules contained project-specific references (MoviePy, FFmpeg)
- ❌ Only worked with Python projects
- ❌ Couldn't be reused across different languages/frameworks
- ❌ All rules loaded regardless of relevance

### After (Centralized + Progressive Disclosure)

```
centralized-rules/
├── base/                    # Universal rules (language-agnostic)
├── languages/              # Language-specific (Python, TS, Go, Java...)
├── frameworks/             # Framework-specific (React, Django, FastAPI...)
├── tools/                  # AI tool outputs (Claude, Cursor, Copilot)
├── sync-ai-rules.sh       # Dynamic loader
└── README.md              # Universal usage guide
```

**Benefits:**
- ✅ Works with any language (Python, TypeScript, Go, Java, Ruby, Rust)
- ✅ Works with any framework (React, Django, FastAPI, Express, Spring Boot)
- ✅ Works with any AI tool (Claude Code, Cursor, GitHub Copilot)
- ✅ Progressive disclosure - loads only relevant rules
- ✅ No project-specific references - fully generic

## Key Improvements

### 1. Language-Agnostic Base Rules

**Before:**
```markdown
# Refactoring (Python-specific)
- Run mypy for type checking
- Use pytest for testing
- Use black for formatting
```

**After:**
```markdown
# Refactoring (Universal)
- Run static type checker
- Run test suite
- Run code formatter
```

Language-specific tools are now in `languages/{language}/` directories.

### 2. Progressive Disclosure

**Before:** All rules loaded for every project

**After:** Only relevant rules loaded based on detection

**Example - Python + FastAPI Project:**
```bash
./sync-ai-rules.sh

# Loads:
✓ base/* (universal)
✓ languages/python/*
✓ frameworks/fastapi/*

# Doesn't load:
✗ languages/typescript/*
✗ frameworks/react/*
```

### 3. Multi-Tool Support

**Before:** Rules in `.claude/CLAUDE.md` only

**After:** Generates for multiple tools:
- `.claude/RULES.md` - Claude Code
- `.cursorrules` - Cursor IDE
- `.github/copilot-instructions.md` - GitHub Copilot

### 4. Dynamic Detection

**Before:** Manual rule selection

**After:** Automatic detection based on project files:

| Detected File | Loaded Rules |
|--------------|--------------|
| `pyproject.toml` | Python rules |
| `package.json` with TypeScript | TypeScript rules |
| `go.mod` | Go rules |
| Dependencies with `react` | React framework rules |
| Dependencies with `django` | Django framework rules |

## Migration Steps

### For Existing Projects Using Old Rules

1. **Backup current rules:**
   ```bash
   mv .claude/CLAUDE.md .claude/CLAUDE.md.backup
   ```

2. **Download new sync script:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/yourusername/centralized-rules/main/sync-ai-rules.sh \
       -o sync-ai-rules.sh
   chmod +x sync-ai-rules.sh
   ```

3. **Run sync:**
   ```bash
   ./sync-ai-rules.sh
   ```

4. **Review generated files:**
   - `.claude/RULES.md`
   - `.cursorrules`
   - `.github/copilot-instructions.md`

5. **Commit to git:**
   ```bash
   git add sync-ai-rules.sh .claude/ .cursorrules .github/
   git commit -m "chore: migrate to centralized AI rules"
   ```

### For Organizations

1. **Fork this repository** for your organization

2. **Customize rules** in:
   - `base/` - Organization-wide standards
   - `languages/` - Language-specific standards
   - `frameworks/` - Framework-specific standards

3. **Update sync script** to point to your fork:
   ```bash
   export AI_RULES_REPO="https://raw.githubusercontent.com/your-org/centralized-rules/main"
   ```

4. **Distribute to teams:**
   ```bash
   # In each project
   curl -fsSL https://raw.githubusercontent.com/your-org/centralized-rules/main/sync-ai-rules.sh \
       -o sync-ai-rules.sh
   chmod +x sync-ai-rules.sh
   ./sync-ai-rules.sh
   ```

## What to Do with Old Files

### Archived Files

Old project-specific files are in `archive/` directory:

- `archive/ai-integration.md` - Had MoviePy/FFmpeg references
- `archive/testing-mocking.md` - Python-specific mocking
- `archive/performance-monitoring.md` - Project-specific metrics

**These are kept for reference but should not be used.**

### Equivalent New Files

| Old File | New Location | Notes |
|----------|-------------|-------|
| `git-workflow.md` | `base/git-workflow.md` | Made generic |
| `coding-standards.md` | `languages/python/coding-standards.md` | Python-specific version |
| `testing-overview.md` | `base/testing-philosophy.md` | Universal testing |
| `testing-overview.md` | `languages/python/testing.md` | Python-specific testing |
| `ai-integration.md` | Removed | Project-specific (MoviePy, FFmpeg) |

## Breaking Changes

### 1. File Locations

**Before:**
- `.claude/CLAUDE.md`

**After:**
- `.claude/RULES.md` (different filename)

**Fix:**
Update your `.gitignore` and documentation references.

### 2. Removed Project-Specific Content

**Removed:**
- MoviePy/FFmpeg references
- Whisper API specific code
- ElevenLabs TTS examples
- Video processing pipeline rules

**Why:** These were project-specific and don't belong in universal rules.

**What to do:** Create project-specific rule files separately if needed.

### 3. Sync Required

**Before:** Rules were static files

**After:** Rules must be synced with `sync-ai-rules.sh`

**Fix:** Run sync script regularly (pre-commit hook, CI/CD, weekly cron)

## FAQ

### Q: Can I still use the old rules?

**A:** Yes, old rules are archived in `archive/` directory. However, they contain project-specific references and won't be maintained.

### Q: How do I add project-specific rules?

**A:** Create a local `.claude/CUSTOM_RULES.md` file for project-specific additions. The sync script won't overwrite it.

### Q: What if auto-detection is wrong?

**A:** Create `.ai/sync-config.json` to override:
```json
{
  "languages": ["python"],
  "frameworks": ["fastapi"]
}
```

### Q: Do I need to run sync often?

**A:** Only when:
- Rules are updated in central repository
- Project dependencies change
- Switching between projects

Recommend: Pre-commit hook or monthly sync.

### Q: Can I use both old and new?

**A:** Not recommended. Choose one approach:
- **Centralized:** For org-wide standards
- **Project-specific:** For unique requirements
- **Hybrid:** Centralized base + local overrides

## Support

- **Issues:** Report at [GitHub Issues](https://github.com/yourusername/centralized-rules/issues)
- **Discussions:** [GitHub Discussions](https://github.com/yourusername/centralized-rules/discussions)
- **Migration Help:** Open an issue with `migration` label

## Timeline

- **2025-12-13:** New architecture released
- **2025-12-20:** Migration guide published
- **2026-01-01:** Old format deprecated
- **2026-03-01:** Archive old files, remove from main branch

## Summary

This migration transforms the repository from **project-specific Python rules** to a **universal, multi-language, multi-framework, multi-tool system** with progressive disclosure.

**Key Takeaway:** The new system scales to your entire organization while loading only relevant rules for each project.
