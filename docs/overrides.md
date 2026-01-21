# Local Rule Overrides

Customize centralized rules for your project without forking the repository.

## Quick Start

**1. Create override directory:**
```bash
mkdir -p .claude/rules-local/base
```

**2. Add a local rule:**
```bash
cat > .claude/rules-local/base/security.md << 'EOF'
# Additional Security Requirements

This project requires:
- All API endpoints authenticated
- Rate limiting on public routes
- Input validation using zod schemas
EOF
```

**3. Sync rules:**
```bash
./sync-ai-rules.sh --tool claude
```

Your local rule is now merged with the central security rule.

## How It Works

After syncing central rules, the system:

1. Detects `.claude/rules-local/` directory
2. Loads configuration from `.claude/rules-config.local.json` (optional)
3. Applies exclusions (skip rules you don't want)
4. Merges local overrides using configured strategy
5. Outputs combined rules to `.claude/rules/`

```
Central Rules          Local Overrides
     │                      │
     ▼                      ▼
┌─────────────────────────────────────┐
│           Merge Engine              │
│  • Check exclusions                 │
│  • Apply strategy (extend/replace)  │
└─────────────────────────────────────┘
                │
                ▼
         Final Rules
      (.claude/rules/)
```

## Configuration Reference

Create `.claude/rules-config.local.json`:

```json
{
    "merge_strategy": "extend",
    "overrides": {
        "base/security.md": "replace",
        "base/testing-*": "prepend"
    },
    "exclude": [
        "base/chaos-engineering.md",
        "base/ai-*"
    ]
}
```

### Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `merge_strategy` | string | `"extend"` | Default strategy for all rules |
| `overrides` | object | `{}` | Per-rule strategy overrides (supports globs) |
| `exclude` | array | `[]` | Rules to skip entirely (supports globs) |

## Merge Strategies

### `extend` (default)

Appends local content after central content.

**Central:**
```markdown
# Testing Philosophy
Write tests first.
```

**Local:**
```markdown
# Project-Specific Testing
Use pytest with fixtures.
```

**Result:**
```markdown
# Testing Philosophy
Write tests first.

# Project-Specific Testing
Use pytest with fixtures.
```

**Use when:** Adding project-specific requirements to universal rules.

### `replace`

Local content completely replaces central content.

**Central:**
```markdown
# Git Workflow
Use feature branches.
```

**Local:**
```markdown
# Git Workflow
This project uses trunk-based development.
```

**Result:**
```markdown
# Git Workflow
This project uses trunk-based development.
```

**Use when:** Project has fundamentally different practices.

### `prepend`

Local content appears before central content.

**Central:**
```markdown
# Architecture Principles
Follow 12-factor app guidelines.
```

**Local:**
```markdown
# Project Context
This is a monorepo with shared packages.
```

**Result:**
```markdown
# Project Context
This is a monorepo with shared packages.

# Architecture Principles
Follow 12-factor app guidelines.
```

**Use when:** Adding context that should be read first.

## Common Use Cases

### Stricter Security Requirements

```json
{
    "overrides": {
        "base/security.md": "replace"
    }
}
```

```markdown
<!-- .claude/rules-local/base/security.md -->
# Security Requirements (PCI-DSS Compliance)

- All data encrypted at rest and in transit
- No PII in logs
- Audit trail for all data access
- 90-day password rotation
```

### Exclude Unused Rules

```json
{
    "exclude": [
        "base/chaos-engineering.md",
        "base/ai-model-lifecycle.md",
        "languages/rust/*"
    ]
}
```

### Add Custom Rules

Create new rules that don't exist centrally:

```bash
mkdir -p .claude/rules-local/custom
cat > .claude/rules-local/custom/internal-apis.md << 'EOF'
# Internal API Standards

All internal APIs must:
- Use the company SDK for authentication
- Follow naming convention: /api/v{N}/service-name/
- Include correlation IDs in all responses
EOF
```

### Framework-Specific Overrides

```json
{
    "overrides": {
        "frameworks/react/*": "extend"
    }
}
```

## Command-Line Options

```bash
# Preview what would be merged (no changes made)
./sync-ai-rules.sh --dry-run

# Show detailed processing information
./sync-ai-rules.sh --verbose

# Combine with tool selection
./sync-ai-rules.sh --tool claude --dry-run --verbose
```

### Dry-Run Output

```
ℹ [DRY-RUN] Override preview:
  MERGE (extend): base/security.md
  MERGE (replace): base/git-workflow.md
  SKIP (excluded): base/chaos-engineering.md
  ADD: custom/internal-apis.md
ℹ [DRY-RUN] No changes made
```

## Troubleshooting

### Overrides not applied

1. Check directory exists: `ls -la .claude/rules-local/`
2. Verify file extension is `.md`
3. Run with `--verbose` to see processing
4. Ensure hidden files (`.hidden.md`) are not used

### Invalid configuration error

```
ERROR: Invalid rules-config.local.json
```

Validate your JSON:
```bash
python3 -c "import json; json.load(open('.claude/rules-config.local.json'))"
```

Common issues:
- Trailing commas
- Missing quotes around strings
- Invalid strategy name (must be `extend`, `replace`, or `prepend`)

### Pattern not matching

Glob patterns use `fnmatch` syntax:
- `*` matches anything except `/`
- `**` is NOT supported (use `base/*` not `base/**`)

Examples:
- `base/*` matches `base/security.md`
- `base/ai-*` matches `base/ai-ethics.md`, `base/ai-model-lifecycle.md`
- `frameworks/react/*` matches `frameworks/react/best-practices.md`

### Exclusion not working

Exclusions are checked before merging:
```json
{
    "exclude": ["base/chaos-engineering.md"]
}
```

Verify the path matches exactly (relative to rules directory).

## Best Practices

1. **Start with extend** - Only use replace when truly necessary
2. **Document why** - Add comments explaining project-specific rules
3. **Keep it minimal** - Override only what differs from central
4. **Version control** - Commit `.claude/rules-local/` and config
5. **Review periodically** - Check if overrides are still needed after central updates
