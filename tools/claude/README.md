# Claude Code Configuration

Claude Code-specific configurations for the centralized rules system.

## Output Formats

### 1. Hierarchical Format (Recommended)

Progressive disclosure system loading rules on-demand based on task context.

**Structure:**
```
.claude/
├── AGENTS.md              # Entry point with discovery instructions
├── rules/                 # Rule directory
│   ├── index.json        # Machine-readable rule index
│   ├── base/             # Base rules
│   ├── languages/        # Language-specific rules
│   ├── frameworks/       # Framework-specific rules
│   └── cloud/            # Cloud provider rules
└── RULES.md              # Legacy monolithic format (deprecated)
```

**Benefits:**
- 74.4% average token savings
- On-demand loading
- Better context utilization
- Task-specific guidance

**Generation:**
```bash
./sync-ai-rules.sh --tool claude
```

### 2. Monolithic Format (Legacy)

Single `.claude/RULES.md` file containing all rules.

**When to use:**
- Older Claude Code versions without hierarchical support
- Simpler single-file approach
- Quick prototypes or small projects

**Limitations:**
- All rules loaded at once (high token usage)
- No progressive disclosure
- Less context for code analysis

**Generation:**
```bash
./sync-ai-rules.sh --tool claude --format all
```

## Environment Detection

Auto-detects Claude Code via:
1. Environment variable: `CLAUDE_CODE_VERSION`
2. Directory presence: `.claude/` exists

## Template Files

- `template-agents.md` - AGENTS.md template with discovery instructions
- `template-index.json` - Rule metadata structure
- `template-rules.md` - Monolithic RULES.md template (legacy)

## Related Documentation

- [Claude Code Hierarchical Rules](https://docs.anthropic.com/claude-code/rules)
- [Progressive Disclosure Architecture](../../ARCHITECTURE.md)
- [Performance Validation](../../ARCHITECTURE.md#performance--validation)
