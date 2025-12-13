# Claude Code Tool Configuration

This directory contains Claude Code-specific configurations and templates for the centralized rules system.

## Output Formats

Claude Code supports two output formats:

### 1. Hierarchical Format (Recommended)

Progressive disclosure system that loads rules on-demand based on task context.

**Structure:**
```
.claude/
├── AGENTS.md              # Entry point with discovery instructions
├── rules/                 # Organized rule directory
│   ├── index.json        # Machine-readable rule index
│   ├── base/             # Base rules
│   ├── languages/        # Language-specific rules
│   ├── frameworks/       # Framework-specific rules
│   └── cloud/            # Cloud provider rules
└── RULES.md              # Legacy monolithic format (deprecated)
```

**Benefits:**
- **74.4% average token savings** - Load only relevant rules per task
- **On-demand loading** - AI discovers and loads rules as needed
- **Better context utilization** - More room for code analysis
- **Task-specific guidance** - Only load git rules for commits, testing rules for tests, etc.

**Example AGENTS.md:**
```markdown
# AI Development Assistant

## Rule Discovery

This project uses **progressive disclosure** for AI development rules. Rules are organized hierarchically and loaded on-demand based on task context.

### Available Rule Categories

- **Base Rules** (`rules/base/`) - Universal best practices
- **Language Rules** (`rules/languages/{language}/`) - Language-specific patterns
- **Framework Rules** (`rules/frameworks/{framework}/`) - Framework-specific patterns
- **Cloud Rules** (`rules/cloud/{provider}/`) - Cloud provider patterns

### Loading Rules

**Important:** Only load rules relevant to your current task to maximize context efficiency.

**Examples:**

1. **Code Review Task:**
   - Load: `rules/base/code-quality.md`
   - Load: `rules/languages/{language}/coding-standards.md`
   - Skip: Testing, git, framework rules (not needed)

2. **Writing Tests:**
   - Load: `rules/base/testing-philosophy.md`
   - Load: `rules/languages/{language}/testing.md`
   - Skip: Git, code quality, framework rules (not needed)

3. **Creating Git Commit:**
   - Load: `rules/base/git-workflow.md`
   - Skip: All other rules (not needed)

### Rule Index

Use `rules/index.json` to discover available rules and their metadata.
```

### 2. Monolithic Format (Legacy)

Single `.claude/RULES.md` file containing all rules.

**When to Use:**
- Older Claude Code versions that don't support hierarchical rules
- Projects that prefer simpler single-file approach
- Quick prototypes or small projects

**Limitations:**
- All rules loaded at once (high token usage)
- No progressive disclosure benefits
- Less context available for code analysis

## File Generation

The sync script generates Claude Code files:

```bash
# Generate hierarchical format (default)
./sync-ai-rules.sh --tool claude

# Generate both hierarchical and monolithic
./sync-ai-rules.sh --tool claude --format all
```

## Environment Detection

The sync script auto-detects Claude Code environment via:

1. **Environment Variable:** `CLAUDE_CODE_VERSION`
2. **Directory Presence:** `.claude/` directory exists

If detected, Claude Code is automatically selected as the target tool.

## Template Files

This directory contains:

- `template-agents.md` - AGENTS.md template with discovery instructions
- `template-index.json` - index.json structure for rule metadata
- `template-rules.md` - Monolithic RULES.md template (legacy)

## Related Documentation

- [Claude Code Hierarchical Rules](https://docs.anthropic.com/claude-code/rules)
- [Progressive Disclosure Architecture](../../ARCHITECTURE.md)
- [Performance Validation](../../ARCHITECTURE.md#performance--validation)
