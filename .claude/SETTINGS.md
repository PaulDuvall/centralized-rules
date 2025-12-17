# Claude Code Settings Configuration

This document explains the correct format for `.claude/settings.json` to prevent breaking the configuration.

## Critical: Hook Format

### ✅ CORRECT Format (Current)

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/activate-rules.sh",
            "description": "Activate centralized-rules skill"
          }
        ]
      }
    ]
  }
}
```

### ❌ INCORRECT Format (Old/Broken)

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "type": "command",
        "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/activate-rules.sh",
        "description": "Activate centralized-rules skill"
      }
    ]
  }
}
```

## Key Differences

The new hook format requires **two levels of nesting**:

1. **Outer level**: Hook configuration object with optional `matcher` field
2. **Inner level**: `hooks` array containing the actual hook definitions

```
UserPromptSubmit: [
  {
    "matcher": {...},     // Optional: specify when to run
    "hooks": [            // Required: array of hook definitions
      {
        "type": "command",
        "command": "...",
        "description": "..."
      }
    ]
  }
]
```

## Why This Matters

The nested structure allows for:
- **Matchers**: Conditionally run hooks based on tools used, file patterns, etc.
- **Multiple hooks**: Run several hooks for the same event
- **Better organization**: Group related hooks together

## Common Mistakes

1. **Missing nested `hooks` array**: The most common error
   - Error: `hooks: Expected array, but received undefined`
   - Fix: Wrap hook objects in a `hooks` array

2. **Missing schema reference**: Helps catch errors early
   - Add: `"$schema": "https://json.schemastore.org/claude-code-settings.json"`

## Example with Matcher

If you want to run hooks only for specific tools:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": {
          "tools": ["BashTool"]
        },
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Bash tool was used'"
          }
        ]
      }
    ]
  }
}
```

## Validation

Before committing changes to `settings.json`:

1. Include the `$schema` reference at the top
2. Verify the nested structure: `hooks` → array → object → `hooks` array → hook objects
3. Test with `claude --dangerously-skip-permissions` to see if validation passes

## References

- [Claude Code Hooks Documentation](https://code.claude.com/docs/en/hooks)
- [Settings Schema](https://json.schemastore.org/claude-code-settings.json)

---

**Last Updated**: 2025-12-17
**Reason**: Fixed hook format migration from old to new nested structure
