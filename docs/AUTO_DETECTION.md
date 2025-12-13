# AI Tool Auto-Detection

**Status:** Proposed Enhancement
**Beads Task:** `centralized-rules-vml`
**Goal:** Eliminate the need to specify `--tool` flag by auto-detecting which AI assistant is being used

## Overview

Currently, users must specify which AI tool they're using:

```bash
./sync-ai-rules.sh --tool claude    # Manual specification required
./sync-ai-rules.sh --tool cursor
./sync-ai-rules.sh --tool copilot
```

With auto-detection, the script **just works**:

```bash
./sync-ai-rules.sh                  # Automatically detects and syncs
```

## How It Works

### Detection Strategy

The script scans for AI tool configuration files and directories:

| AI Tool | Detection Pattern | File/Directory |
|---------|------------------|----------------|
| **Claude Code** | `.claude/` directory exists | `.claude/RULES.md` or `.claude/AGENTS.md` |
| **Cursor** | `.cursorrules` file exists | `.cursorrules` |
| **GitHub Copilot** | Copilot instructions exist | `.github/copilot-instructions.md` |
| **Google Gemini** | Gemini directory exists | `.gemini/rules.md` |

> **Note:** Support is focused on the major AI coding assistants. Other tools can be added via manual `--tool` flag.

### Behavior

- **Tools detected** → Sync only for detected tools (efficient)
- **No tools detected** → Sync for all tools (safe fallback)
- **Manual override** → `--tool` flag still works (flexibility)

## Implementation Files

### Created Files

1. **`scripts/detect-ai-tools.sh`**
   Standalone script that detects AI tools and outputs space-separated list

2. **`scripts/demo-auto-detect.sh`**
   Interactive demo showing how auto-detection works in practice

3. **`scripts/auto-detect-integration.patch`**
   Patch file showing required changes to `sync-ai-rules.sh`

4. **`.beads/issues.jsonl`**
   Beads task tracking this enhancement (`centralized-rules-vml`)

### Running the Demo

```bash
# See auto-detection in action
./scripts/demo-auto-detect.sh

# Example output:
# === AI Tool Auto-Detection Demo ===
#
# Scanning project for AI tool configurations...
# ✓ Found Claude Code configuration (.claude/)
# ✓ Found Cursor configuration (.cursorrules)
# ✓ Found GitHub Copilot configuration (.github/copilot-instructions.md)
#
# AI Tools Detected: claude cursor copilot
# Action: Will sync rules for detected tools only
```

## Integration Steps

To integrate auto-detection into `sync-ai-rules.sh`:

### Step 1: Add Detection Function

Add the `detect_ai_tools()` function from `scripts/detect-ai-tools.sh` after the `detect_cloud_providers()` function (around line 154).

### Step 2: Update sync_rules()

Modify the `sync_rules()` function to:
- Accept `"auto"` as a tool parameter (default)
- Call `detect_ai_tools()` when `tool="auto"`
- Generate rules only for detected tools

See `scripts/auto-detect-integration.patch` for detailed changes.

### Step 3: Update CLI Argument Parsing

Change the default tool from `"all"` to `"auto"`:

```bash
# Before
tool="all"

# After
tool="auto"
```

### Step 4: Update Help Text

Update usage examples in help text and file header comments:

```bash
# Usage:
#   ./sync-ai-rules.sh                  # Auto-detect and sync (recommended)
#   ./sync-ai-rules.sh --tool all       # Sync for all tools
#   ./sync-ai-rules.sh --tool claude    # Sync for specific tool
```

## Benefits

### For Users

✓ **Zero configuration** - Works out of the box
✓ **Faster syncs** - Only generates needed rules
✓ **Less clutter** - Doesn't create unused files
✓ **Portable** - Works across different dev environments
✓ **Discoverable** - Script reveals which tools you're using

### For Maintainers

✓ **Better UX** - Reduces cognitive load
✓ **Fewer support questions** - Obvious default behavior
✓ **Backward compatible** - `--tool` flag still works
✓ **Easy to extend** - Add new tools by updating detection function

## Usage Examples

### Default Auto-Detection

```bash
# In a project with .claude/ and .cursorrules
./sync-ai-rules.sh

# Output:
# ℹ Auto-detected AI tools: claude cursor
# ℹ Starting AI rules synchronization...
# ✓ Generated .claude/rules/
# ✓ Generated .cursorrules
# ✓ Synchronization complete!
```

### Manual Override

```bash
# Force sync for all tools (ignore auto-detection)
./sync-ai-rules.sh --tool all

# Force sync for specific tool only
./sync-ai-rules.sh --tool claude
```

### Detecting Only (No Sync)

```bash
# Just see what tools are detected
./scripts/detect-ai-tools.sh

# Output: claude cursor copilot
```

## Testing

### Test Scenarios

1. **Project with Claude only** → Should generate `.claude/` only
2. **Project with Cursor only** → Should generate `.cursorrules` only
3. **Project with multiple tools** → Should generate for all detected tools
4. **Empty project (no tools)** → Should fallback to generating for all tools
5. **Manual override** → Should respect `--tool` flag over auto-detection

### Manual Testing

```bash
# Test detection
./scripts/detect-ai-tools.sh

# Test demo
./scripts/demo-auto-detect.sh

# Test in different project structures
cd /path/to/claude-only-project && ./sync-ai-rules.sh
cd /path/to/cursor-only-project && ./sync-ai-rules.sh
cd /path/to/multi-tool-project && ./sync-ai-rules.sh
```

## Future Enhancements

### Environment Variable Detection

```bash
# Could also detect based on environment variables
if [[ -n "${ANTHROPIC_API_KEY}" ]]; then
    detected_tools+=("claude")
fi
```

### Process Detection

```bash
# Could detect running AI assistant processes
if pgrep -x "claude" > /dev/null; then
    detected_tools+=("claude")
fi
```

### User Preferences

```bash
# Could respect user preferences in .ai-rules/config
# preferred_tool=claude
# fallback_behavior=all|detected|none
```

## Related Tasks

- **Beads Task:** `centralized-rules-vml` - Auto-detect AI tool environment
- **Related:** `centralized-rules-9d4` - Multi-tool generation support
- **Related:** `centralized-rules-c1u` - GitHub Copilot integration
- **Related:** `centralized-rules-vo4` - Cursor integration

## Questions & Answers

**Q: What if I want to sync for all tools regardless of detection?**
A: Use `./sync-ai-rules.sh --tool all`

**Q: What if no tools are detected?**
A: The script falls back to syncing for all supported tools (current behavior)

**Q: Can I force detection to fail if no tools found?**
A: Not yet - could add a `--only-detected` flag that errors if nothing detected

**Q: How do I debug detection?**
A: Run `./scripts/detect-ai-tools.sh` or `./scripts/demo-auto-detect.sh`

**Q: Will this break existing workflows?**
A: No - it's backward compatible. The `--tool` flag still works exactly as before.

---

**Status:** Ready for implementation
**Next Steps:** Review patch, integrate into `sync-ai-rules.sh`, test across multiple project types
