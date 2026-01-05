# ✅ Ralph Wiggum Plugin - Global Installation Complete

## What Was Done

Successfully migrated Ralph Wiggum from a local project-specific installation to a **global Claude Code plugin** that works across ALL your projects.

### Before
```
your-project/.claude/
├── commands/ralph-loop.md      ❌ Only worked in this project
├── commands/cancel-ralph.md
├── hooks/stop-hook.sh
└── scripts/setup-ralph-loop.sh
```

### After
```
~/.config/claude/plugins/ralph-wiggum/
├── README.md                    ✅ Works in ALL projects
├── INSTALL.md
├── plugin.json
├── commands/
│   ├── ralph-loop.md
│   └── cancel-ralph.md
├── hooks/
│   └── stop-hook.sh
└── scripts/
    └── setup-ralph-loop.sh
```

## Available Commands

These commands now work in **any** Claude Code project:

### `/ralph-loop`
Start a self-referential loop for iterative task completion.

**Usage:**
```bash
/ralph-loop PROMPT [--max-iterations N] [--completion-promise 'TEXT']
```

**Examples:**
```bash
/ralph-loop Refactor codebase --completion-promise 'REFACTORED' --max-iterations 20
/ralph-loop Fix all bugs --max-iterations 10
/ralph-loop Build feature X --completion-promise 'COMPLETE'
```

### `/cancel-ralph`
Cancel an active Ralph loop.

## How It Works

1. **Start Loop**: `/ralph-loop YOUR_TASK --completion-promise 'DONE' --max-iterations 20`
2. **Work Begins**: Claude works on the task
3. **Iteration**: When attempting to exit, output becomes next input
4. **Completion**: Stops when you output `<promise>DONE</promise>` or hit max iterations
5. **State Tracking**: Creates `.claude/ralph-loop.local.md` in each project

## Quick Test

To verify it works, go to **any** project and run:

```bash
cd ~/any-project
claude

# In Claude session:
/ralph-loop --help
```

You should see the help message, confirming the plugin is active globally.

## Real-World Example

The Ralph loop we just completed refactored 24 markdown files in `/base`:

```bash
/ralph-loop "Iterate through every file in /base. Rewrite to be concise..." \
  --max-iterations 20 \
  --completion-promise "REFACTORED"
```

**Results:**
- ✅ 22 files refactored
- ✅ 11,627 deletions, 2,871 insertions  
- ✅ Net reduction: ~8,756 lines (46% reduction)
- ✅ All essential content preserved
- ✅ Completed in 4 iterations

## Documentation

Full documentation available at:
```
~/.config/claude/plugins/ralph-wiggum/README.md
~/.config/claude/plugins/ralph-wiggum/INSTALL.md
```

## Key Features

✅ **Global**: Works across all Claude Code projects
✅ **Self-Referential**: Output becomes input for iterative refinement
✅ **Safe Limits**: Max iterations and completion promises prevent infinite loops
✅ **State Management**: Tracks progress per-project
✅ **Monitoring**: Easy to check current iteration
✅ **Cancellable**: `/cancel-ralph` stops active loops

## Completion Promises

When using `--completion-promise 'TEXT'`, Claude will ONLY stop when it outputs:
```xml
<promise>TEXT</promise>
```

**Critical Rules:**
- Must be exact match (case and whitespace sensitive)
- Only output when genuinely complete
- Do not lie to escape the loop
- Multi-word promises need quotes in command

## What Got Cleaned Up

From this project:
- ❌ Removed `.claude/commands/ralph-loop.md` (now global)
- ❌ Removed `.claude/commands/cancel-ralph.md` (now global)
- ❌ Removed `.claude/hooks/stop-hook.sh` (now global)
- ❌ Removed `.claude/scripts/setup-ralph-loop.sh` (now global)
- ✅ Kept `.claude/settings.json` (project-specific config)
- ✅ Kept `.claude/lib/`, `.claude/rules/`, `.claude/skills/` (unrelated)

## Next Steps

1. **Try it in another project**: `cd ~/other-project && claude`
2. **Run a test loop**: `/ralph-loop Test task --max-iterations 3`
3. **Check iteration progress**: `head -10 .claude/ralph-loop.local.md`
4. **Read full docs**: `cat ~/.config/claude/plugins/ralph-wiggum/README.md`

## Troubleshooting

**Commands not found?**
- Check: `ls ~/.config/claude/plugins/ralph-wiggum/`
- Ensure: `plugin.json` exists

**Loop won't stop?**
- Use: `/cancel-ralph`
- Or delete: `rm .claude/ralph-loop.local.md`

**Hook errors?**
- Make executable: `chmod +x ~/.config/claude/plugins/ralph-wiggum/{hooks,scripts}/*`

## Success!

Ralph Wiggum is now a global plugin. Use `/ralph-loop` in any Claude Code project! 🎉
