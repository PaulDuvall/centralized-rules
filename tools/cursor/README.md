# Cursor Tool Configuration

This directory contains Cursor-specific configurations and templates for the centralized rules system.

## Output Format

Cursor uses a single `.cursorrules` file in the project root containing all development rules.

**Structure:**
```
project-root/
└── .cursorrules         # Monolithic markdown file with all rules
```

**Characteristics:**
- **Plain Markdown:** No special formatting or frontmatter required
- **Auto-loaded:** Cursor automatically loads `.cursorrules` when workspace opens
- **Monolithic:** All rules combined into single file (no progressive disclosure)
- **Simple:** Easiest format to understand and debug

## File Format

The `.cursorrules` file is structured as a markdown document with clear sections:

```markdown
# Development Rules

This file contains development standards for this project.
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

[... more base rules ...]

## Language-Specific Rules

### Python
[Content from languages/python/]

### TypeScript
[Content from languages/typescript/]

## Framework-Specific Rules

### FastAPI
[Content from frameworks/fastapi/]

### React
[Content from frameworks/react/]

## Cloud Provider Rules

### Vercel
[Content from cloud/vercel/]
```

## Benefits

**Advantages:**
- **Simple:** Single file, easy to understand
- **Universal:** Works with all Cursor versions
- **Visible:** Easy to view and edit manually
- **Reliable:** No dependencies on Cursor features

**Limitations:**
- **No Progressive Disclosure:** All rules loaded at once
- **Higher Token Usage:** Entire file consumed in context
- **Less Context Available:** More tokens used for rules = fewer tokens for code
- **Harder to Maintain:** Large file can be unwieldy

## File Generation

The sync script generates the `.cursorrules` file:

```bash
# Generate Cursor rules
./sync-ai-rules.sh --tool cursor

# Cursor is included when using --tool all
./sync-ai-rules.sh --tool all
```

## Environment Detection

The sync script auto-detects Cursor environment via:

1. **Environment Variable:** `CURSOR_VERSION`
2. **File Presence:** `.cursorrules` file exists

If detected, Cursor is automatically included in sync targets.

## Customization

You can customize the generated `.cursorrules` file by:

1. **Manual Edits:** Edit `.cursorrules` directly (will be overwritten on next sync)
2. **Sync Config:** Create `.ai/sync-config.json` to exclude specific rules
3. **Custom Rules:** Add custom rule URLs in sync config

Example `.ai/sync-config.json`:
```json
{
  "languages": ["python"],
  "frameworks": ["fastapi"],
  "exclude": ["testing-mocking"],
  "custom_rules": [
    "https://example.com/team-specific-rule.md"
  ]
}
```

## Template Files

This directory contains:

- `template-cursorrules.md` - Template structure for `.cursorrules` file
- `section-header.md` - Standard section header format
- `footer.md` - Standard footer with attribution

## Future Enhancements

Potential improvements for Cursor integration:

1. **Rule Comments:** Special syntax to mark rule sections for selective loading
2. **Workspace Configuration:** Store rule preferences in Cursor workspace settings
3. **Rule Categories:** Tag-based organization within the monolithic file
4. **Update Notifications:** Alert when centralized rules have updates available

## Comparison to Other Tools

| Feature | Cursor | Claude Code | Copilot |
|---------|--------|-------------|---------|
| **File Format** | Monolithic | Hierarchical or Monolithic | Monolithic |
| **Progressive Disclosure** | No | Yes (hierarchical mode) | No |
| **Auto-load** | Yes | Yes | Partial |
| **Token Efficiency** | Medium | High (hierarchical) | Medium |
| **Ease of Use** | High | Medium | High |

**When to use Cursor format:**
- You prefer simplicity over optimization
- Your rule set is small (<10K tokens)
- You want to manually review all rules easily
- You're not concerned about context window usage

**When to consider Claude Code hierarchical:**
- You have many rules (>15K tokens)
- You want maximum context window efficiency
- You work on varied tasks that need different rule subsets
- You want 50-90% token savings on rules

## Related Documentation

- [Cursor Documentation](https://cursor.sh/docs)
- [Centralized Rules Architecture](../../ARCHITECTURE.md)
- [Progressive Disclosure Comparison](../../ARCHITECTURE.md#progressive-disclosure)

## Support

- **Repository:** https://github.com/PaulDuvall/centralized-rules
- **Issues:** https://github.com/PaulDuvall/centralized-rules/issues
- **Cursor Support:** https://cursor.sh/support
