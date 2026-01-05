# Cursor Configuration

Cursor-specific configurations for the centralized rules system.

## Output Format

Single `.cursorrules` file in project root containing all development rules.

**Structure:**
```
project-root/
└── .cursorrules         # Monolithic markdown file
```

**Characteristics:**
- **Plain Markdown:** No special formatting required
- **Auto-loaded:** Cursor loads `.cursorrules` when workspace opens
- **Monolithic:** All rules combined (no progressive disclosure)
- **Simple:** Easiest format to understand and debug

## File Format

Markdown document with clear sections:

```markdown
# Development Rules

Auto-synced from: https://github.com/PaulDuvall/centralized-rules
Last synced: YYYY-MM-DD HH:MM:SS

## Project Configuration
- Languages: Python, TypeScript
- Frameworks: FastAPI, React
- Cloud Providers: Vercel
- Maturity Level: Production

## Base Rules
### Git Workflow
[Content from base/git-workflow.md]

### Code Quality
[Content from base/code-quality.md]

## Language-Specific Rules
### Python
[Content from languages/python/]

## Framework-Specific Rules
### FastAPI
[Content from frameworks/fastapi/]

## Cloud Provider Rules
### Vercel
[Content from cloud/vercel/]
```

## Benefits & Limitations

**Advantages:**
- Simple single file, easy to understand
- Works with all Cursor versions
- Easy to view and edit manually
- No dependencies on Cursor features

**Limitations:**
- All rules loaded at once (high token usage)
- No progressive disclosure
- Less context for code
- Large files unwieldy

## File Generation

```bash
# Generate Cursor rules
./sync-ai-rules.sh --tool cursor

# Included when using --tool all
./sync-ai-rules.sh --tool all
```

## Environment Detection

Auto-detects Cursor via:
1. Environment variable: `CURSOR_VERSION`
2. File presence: `.cursorrules` exists

## Customization

**Manual Edits:** Edit `.cursorrules` directly (overwritten on next sync)
**Sync Config:** Create `.ai/sync-config.json` to exclude rules
**Custom Rules:** Add custom rule URLs in sync config

Example `.ai/sync-config.json`:
```json
{
  "languages": ["python"],
  "frameworks": ["fastapi"],
  "exclude": ["testing-mocking"],
  "custom_rules": ["https://example.com/team-rule.md"]
}
```

## Template Files

- `template-cursorrules.md` - Template structure for `.cursorrules`
- `section-header.md` - Standard section header format
- `footer.md` - Standard footer with attribution

## Comparison

| Feature | Cursor | Claude Code | Copilot |
|---------|--------|-------------|---------|
| **File Format** | Monolithic | Hierarchical/Mono | Monolithic |
| **Progressive Disclosure** | No | Yes (hierarchical) | No |
| **Auto-load** | Yes | Yes | Partial |
| **Token Efficiency** | Medium | High | Medium |
| **Ease of Use** | High | Medium | High |

**When to use Cursor format:**
- Prefer simplicity over optimization
- Rule set < 10K tokens
- Want to manually review all rules
- Not concerned about context window usage

**When to consider Claude Code hierarchical:**
- Many rules (> 15K tokens)
- Want maximum context efficiency
- Varied tasks needing different rule subsets
- Want 50-90% token savings

## Related Documentation

- [Cursor Documentation](https://cursor.sh/docs)
- [Centralized Rules Architecture](../../ARCHITECTURE.md)
- [Progressive Disclosure Comparison](../../ARCHITECTURE.md#progressive-disclosure)

## Support

- **Repository:** https://github.com/PaulDuvall/centralized-rules
- **Issues:** https://github.com/PaulDuvall/centralized-rules/issues
- **Cursor Docs:** https://docs.cursor.com
