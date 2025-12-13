# GitHub Copilot Tool Configuration

This directory contains GitHub Copilot-specific configurations and templates for the centralized rules system.

## Output Format

GitHub Copilot uses a markdown file at `.github/copilot-instructions.md` containing development rules and instructions.

**Structure:**
```
project-root/
└── .github/
    └── copilot-instructions.md    # Monolithic markdown file with all rules
```

**Characteristics:**
- **GitHub Directory:** Lives in `.github/` directory with other GitHub configurations
- **Markdown Format:** Standard GitHub-flavored markdown
- **Monolithic:** All rules combined into single file (no progressive disclosure)
- **Integration:** Works with GitHub Copilot in VS Code, JetBrains IDEs, and github.com

## File Format

The `copilot-instructions.md` file follows GitHub's recommended structure:

```markdown
# GitHub Copilot Instructions

This document provides instructions and context for GitHub Copilot when working in this repository.

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

[... additional rules ...]

## Language-Specific Guidelines

### Python
[Content from languages/python/]

### TypeScript
[Content from languages/typescript/]

## Framework Patterns

### FastAPI
[Content from frameworks/fastapi/]

### React
[Content from frameworks/react/]

## Cloud Deployment

### Vercel
[Content from cloud/vercel/]

## Code Generation Preferences

When generating code, GitHub Copilot should:
- Follow the conventions outlined above
- Prioritize type safety and error handling
- Include appropriate tests for new functionality
- Add comments for complex logic
- Follow the project's maturity level requirements
```

## Benefits

**Advantages:**
- **GitHub Native:** Integrates seamlessly with GitHub ecosystem
- **Version Controlled:** Part of repository, tracked in Git
- **Collaborative:** Easy for team members to view and update
- **Discoverable:** Lives in standard `.github/` location

**Limitations:**
- **No Progressive Disclosure:** All rules loaded at once
- **Higher Token Usage:** Entire file consumed in context
- **Less Flexible:** Limited to GitHub Copilot's instruction format
- **Static:** No dynamic rule loading based on task

## File Generation

The sync script generates the `.github/copilot-instructions.md` file:

```bash
# Generate Copilot instructions
./sync-ai-rules.sh --tool copilot

# Copilot is included when using --tool all
./sync-ai-rules.sh --tool all
```

## Environment Detection

The sync script auto-detects GitHub Copilot environment via:

1. **Environment Variable:** `GITHUB_COPILOT`
2. **File Presence:** `.github/copilot-instructions.md` file exists
3. **GitHub Context:** Repository is hosted on GitHub

If detected, Copilot is automatically included in sync targets.

## GitHub Copilot Features

### Code Suggestions

Copilot uses the instructions to:
- Generate code that follows project conventions
- Suggest patterns consistent with framework best practices
- Apply security principles to generated code
- Follow testing philosophy when creating test files

### Chat Mode

In Copilot Chat, you can reference the instructions:
```
@workspace Follow the FastAPI patterns in copilot-instructions.md to create a new user endpoint
```

### Code Reviews

Copilot can review code against the instructions:
```
@workspace Review this code against our security principles
```

## Customization

Customize the generated file by:

1. **Sync Config:** Create `.ai/sync-config.json` to control which rules are included
2. **Manual Additions:** Add project-specific instructions after sync (will be preserved if marked)
3. **Template Customization:** Fork the repository and modify the Copilot template

Example `.ai/sync-config.json`:
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
- Organize by concern (security, testing, etc.)
- Include "why" explanations, not just "what"

**Don't:**
- Make instructions too long (Copilot has context limits)
- Include redundant or conflicting rules
- Use vague language like "should be good" or "try to"
- Forget to update when project conventions change

### Maintenance

**Regular Updates:**
```bash
# Weekly sync to get latest centralized rules
./sync-ai-rules.sh --tool copilot

# Commit the changes
git add .github/copilot-instructions.md
git commit -m "chore: Update Copilot instructions"
```

**Pre-commit Hook:**
```bash
# .git/hooks/pre-commit
#!/bin/bash
./sync-ai-rules.sh --tool copilot
git add .github/copilot-instructions.md
```

## Template Files

This directory contains:

- `template-copilot-instructions.md` - Template structure for instructions file
- `code-generation-preferences.md` - Standard preferences for code generation
- `context-examples.md` - Examples of effective Copilot instructions

## Integration with CI/CD

### Validation in Pull Requests

```yaml
# .github/workflows/validate-copilot-instructions.yml
name: Validate Copilot Instructions

on: [pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Sync rules
        run: ./sync-ai-rules.sh --tool copilot
      - name: Check for drift
        run: |
          if [[ -n $(git status --porcelain .github/copilot-instructions.md) ]]; then
            echo "Copilot instructions are out of sync. Run ./sync-ai-rules.sh --tool copilot"
            exit 1
          fi
```

### Automatic Updates

```yaml
# .github/workflows/auto-sync-rules.yml
name: Auto-sync Copilot Instructions

on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday
  workflow_dispatch:

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Sync rules
        run: ./sync-ai-rules.sh --tool copilot
      - name: Create PR
        uses: peter-evans/create-pull-request@v5
        with:
          commit-message: "chore: Update Copilot instructions"
          title: "Update Copilot instructions from centralized rules"
          body: "Automated sync of Copilot instructions from centralized-rules repository"
```

## Comparison to Other Tools

| Feature | Copilot | Claude Code | Cursor |
|---------|---------|-------------|--------|
| **File Format** | Monolithic | Hierarchical or Monolithic | Monolithic |
| **Progressive Disclosure** | No | Yes (hierarchical mode) | No |
| **GitHub Integration** | Native | Via gh CLI | Manual |
| **Token Efficiency** | Medium | High (hierarchical) | Medium |
| **Team Collaboration** | Excellent | Good | Good |
| **IDE Support** | Wide | CLI-focused | Editor-focused |

**When to use Copilot:**
- Your team primarily uses GitHub
- You want seamless GitHub ecosystem integration
- You work in VS Code or JetBrains IDEs
- You prefer instructions versioned with code

**When to consider alternatives:**
- You need progressive disclosure (→ Claude Code hierarchical)
- You want a simpler single-file approach (→ Cursor)
- You have very large rule sets (→ Claude Code)

## Related Documentation

- [GitHub Copilot Documentation](https://docs.github.com/copilot)
- [Copilot Instructions Best Practices](https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot)
- [Centralized Rules Architecture](../../ARCHITECTURE.md)

## Support

- **Repository:** https://github.com/PaulDuvall/centralized-rules
- **Issues:** https://github.com/PaulDuvall/centralized-rules/issues
- **Copilot Support:** https://github.com/github/copilot-docs/discussions
