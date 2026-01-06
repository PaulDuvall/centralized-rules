# Ralph Loop Guide

Iterative task completion with the Ralph Wiggum plugin for Claude Code.

## What is Ralph Loop?

The `/ralph-loop` skill runs iterative workflows with automatic progress tracking. Ideal for multi-step refactoring, documentation updates, and complex migrations.

## Basic Usage

```bash
claude /ralph-loop "Your task description"
```

## Using with Caffeinate (macOS)

Prevent system sleep during long-running tasks:

```bash
caffeinate -i claude /ralph-loop "Your task description"
```

### Simple Example

```bash
caffeinate -i claude /ralph-loop "Refactor all TODO comments into GitHub issues"
```

### Advanced Example with Flags

```bash
caffeinate -i claude /ralph-loop \
  "Update all documentation for consistency" \
  --max-iterations 20 \
  --completion-promise "All docs updated and committed"
```

## Flags

- `--max-iterations N` - Maximum iterations before stopping (default: 10)
- `--completion-promise "text"` - Success criteria for completion

## Caffeinate Options

- `-i` - Prevent idle sleep (recommended)
- `-d` - Prevent display sleep
- `-s` - Prevent system sleep
- `-u` - Simulate user activity

## Example Completion Promises

```bash
# Bug fixes
--completion-promise "Bug fixed, tests pass, regression tests added"

# Features
--completion-promise "Feature implemented, documented, tested, ready for review"

# Refactoring
--completion-promise "Code refactored, all tests pass, no functionality changed"

# Documentation
--completion-promise "All docs updated, examples tested, changes committed and pushed"
```

## References

- [Ralph Wiggum Plugin](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum)
- [caffeinate - macOS man page](https://ss64.com/mac/caffeinate.html)
