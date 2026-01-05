# GitHub Copilot Configuration

GitHub Copilot-specific configurations for the centralized rules system.

## Output Format

Markdown file at `.github/copilot-instructions.md` containing development rules.

**Structure:**
```
project-root/
└── .github/
    └── copilot-instructions.md    # Monolithic markdown file
```

**Characteristics:**
- **GitHub Directory:** Lives in `.github/` with other GitHub configurations
- **Markdown Format:** Standard GitHub-flavored markdown
- **Monolithic:** All rules combined (no progressive disclosure)
- **Integration:** Works with Copilot in VS Code, JetBrains IDEs, github.com

## File Format

```markdown
# GitHub Copilot Instructions

**Auto-synced from:** https://github.com/PaulDuvall/centralized-rules
**Last synced:** YYYY-MM-DD HH:MM:SS

## Project Context
**Languages:** Python, TypeScript
**Frameworks:** FastAPI, React
**Cloud Providers:** Vercel
**Maturity Level:** Production

## Development Standards

### Git Workflow
[Content from base/git-workflow.md]

### Code Quality
[Content from base/code-quality.md]

### Testing
[Content from base/testing-philosophy.md]

## Language-Specific Guidelines
### Python
[Content from languages/python/]

## Framework Patterns
### FastAPI
[Content from frameworks/fastapi/]

## Cloud Deployment
### Vercel
[Content from cloud/vercel/]
```

## Benefits & Limitations

**Advantages:**
- GitHub native integration
- Version controlled with repository
- Team collaborative editing
- Discoverable in `.github/` location

**Limitations:**
- No progressive disclosure
- Higher token usage (all rules loaded)
- Limited to Copilot's instruction format
- Static (no dynamic loading)

## File Generation

```bash
# Generate Copilot instructions
./sync-ai-rules.sh --tool copilot

# Included when using --tool all
./sync-ai-rules.sh --tool all
```

## Environment Detection

Auto-detects GitHub Copilot via:
1. Environment variable: `GITHUB_COPILOT`
2. File presence: `.github/copilot-instructions.md` exists
3. GitHub context: Repository hosted on GitHub

## Copilot Features

### Code Suggestions
Uses instructions to:
- Generate code following project conventions
- Suggest framework-consistent patterns
- Apply security principles
- Follow testing philosophy

### Chat Mode
Reference instructions in chat:
```
@workspace Follow the FastAPI patterns in copilot-instructions.md to create a new endpoint
```

### Code Reviews
Review code against instructions:
```
@workspace Review this code against our security principles
```

## Customization

Create `.ai/sync-config.json`:

```json
{
  "languages": ["python", "typescript"],
  "frameworks": ["fastapi", "react"],
  "cloud_providers": ["vercel"],
  "exclude": ["testing-mocking"],
  "copilot_preferences": {
    "code_style": "functional",
    "comment_density": "high",
    "test_generation": "always"
  }
}
```

## Best Practices

### Writing Instructions

**Do:**
- Be specific and actionable
- Use examples to illustrate patterns
- Organize by concern
- Include "why" explanations

**Don't:**
- Make instructions too long
- Include redundant or conflicting rules
- Use vague language
- Forget to update when conventions change

### Maintenance

```bash
# Weekly sync
./sync-ai-rules.sh --tool copilot

# Commit changes
git add .github/copilot-instructions.md
git commit -m "chore: Update Copilot instructions"
```

## Template Files

- `template-copilot-instructions.md` - Template structure
- `code-generation-preferences.md` - Standard preferences
- `context-examples.md` - Effective instruction examples

## CI/CD Integration

### Validation in PRs

```yaml
# .github/workflows/validate-copilot-instructions.yml
name: Validate Copilot Instructions
on: [pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: ./sync-ai-rules.sh --tool copilot
      - run: |
          if [[ -n $(git status --porcelain .github/copilot-instructions.md) ]]; then
            echo "Instructions out of sync. Run ./sync-ai-rules.sh --tool copilot"
            exit 1
          fi
```

### Automatic Updates

```yaml
# .github/workflows/auto-sync-rules.yml
name: Auto-sync Copilot Instructions
on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly Sunday
  workflow_dispatch:
jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: ./sync-ai-rules.sh --tool copilot
      - uses: peter-evans/create-pull-request@v5
        with:
          commit-message: "chore: Update Copilot instructions"
          title: "Update Copilot instructions from centralized rules"
```

## Comparison

| Feature | Copilot | Claude Code | Cursor |
|---------|---------|-------------|--------|
| **File Format** | Monolithic | Hierarchical/Mono | Monolithic |
| **Progressive Disclosure** | No | Yes (hierarchical) | No |
| **GitHub Integration** | Native | Via gh CLI | Manual |
| **Token Efficiency** | Medium | High | Medium |
| **Team Collaboration** | Excellent | Good | Good |
| **IDE Support** | Wide | CLI-focused | Editor-focused |

**When to use Copilot:**
- Team primarily uses GitHub
- Want seamless GitHub integration
- Work in VS Code or JetBrains IDEs
- Prefer instructions versioned with code

**When to consider alternatives:**
- Need progressive disclosure → Claude Code hierarchical
- Want simpler single-file → Cursor
- Have very large rule sets → Claude Code

## Related Documentation

- [GitHub Copilot Documentation](https://docs.github.com/copilot)
- [Copilot Instructions Best Practices](https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot)
- [Centralized Rules Architecture](../../ARCHITECTURE.md)

## Support

- **Repository:** https://github.com/PaulDuvall/centralized-rules
- **Issues:** https://github.com/PaulDuvall/centralized-rules/issues
- **Copilot Support:** https://github.com/github/copilot-docs/discussions
