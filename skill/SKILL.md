# Centralized Rules Skill - Progressive Disclosure System

## Overview

The centralized-rules skill uses a **progressive disclosure** approach to intelligently load only the most relevant coding rules for each task. This maximizes context efficiency while ensuring Claude has access to the right guidelines.

## How It Works

### Two-Phase Loading

1. **Project-Level Detection** (Automatic)
   - Detects languages (Python, TypeScript, Go, etc.) from project files
   - Identifies frameworks (React, FastAPI, Django, etc.) from dependencies
   - Happens once when Claude analyzes your project structure

2. **Task-Level Selection** (Context-Aware)
   - Analyzes your specific request/prompt
   - Matches keywords against rule categories
   - Loads only 3-5 most relevant rules (not all 50+)
   - Typical context usage: 10K-15K tokens (not 30K-50K)

### Hook-Based Activation

The skill now uses a **UserPromptSubmit hook** for ~80%+ activation reliability:

```mermaid
User Prompt → Hook Fires → Context Detection → Rule Matching → Activation Instruction → Claude Loads Rules → Implementation
```

**Key Innovation**: The hook injects a mandatory 3-step activation pattern:
1. **EVALUATE**: List which rules apply (YES/NO for each)
2. **ACTIVATE**: Use `Skill("centralized-rules")` tool NOW
3. **IMPLEMENT**: Only proceed after activation

This "forced evaluation" pattern achieves much higher activation rates than simple reminders.

## Available Rule Categories

### Base Rules (Always Available)

| Category | Trigger Keywords | When to Load |
|----------|------------------|--------------|
| Code Quality | (always) | Every task |
| Testing Philosophy | test, pytest, unittest, tdd, coverage | Testing tasks |
| Security Principles | auth, token, password, encrypt, validate | Security tasks |
| Git Workflow | commit, pr, merge, branch | Git operations |
| Refactoring Patterns | refactor, clean, improve, optimize | Code improvements |
| Architecture Principles | architect, design, pattern, scalability | Architecture discussions |
| 12-Factor App | deployment, scalability, config | Cloud/deployment tasks |
| Development Workflow | workflow, ci/cd, pipeline | Process discussions |
| Metrics Standards | metrics, monitoring, logging, observability | Observability tasks |

### Language-Specific Rules

| Language | Trigger Keywords | Available Rules |
|----------|------------------|-----------------|
| Python | python, .py, pip, pyproject | languages/python, languages/python/testing |
| TypeScript | typescript, .ts, .tsx, interface | languages/typescript, languages/typescript/testing |
| JavaScript | javascript, .js, node, npm | languages/javascript, languages/javascript/testing |
| Go | go, golang, .go, goroutine | languages/go, languages/go/testing |
| Rust | rust, .rs, cargo, ownership | languages/rust, languages/rust/testing |
| Java | java, .java, maven, gradle | languages/java, languages/java/testing |

### Framework-Specific Rules

| Framework | Trigger Keywords | Available Rules |
|-----------|------------------|-----------------|
| React | react, component, hook, jsx | frameworks/react |
| Next.js | nextjs, getServerSideProps, app router | frameworks/nextjs |
| FastAPI | fastapi, starlette, pydantic | frameworks/fastapi |
| Django | django, model, orm, queryset | frameworks/django |
| Flask | flask, route, blueprint | frameworks/flask |
| Express | express, middleware, router | frameworks/express |
| NestJS | nestjs, controller, service, module | frameworks/nestjs |

### Cloud Provider Rules

| Provider | Trigger Keywords | Available Rules |
|----------|------------------|-----------------|
| AWS | aws, lambda, s3, cloudformation | cloud/aws |
| Azure | azure, function app, cosmos db | cloud/azure |
| GCP | gcp, cloud function, firestore | cloud/gcp |
| Vercel | vercel, edge function | cloud/vercel |

## Example Usage Patterns

### Example 1: Python Testing Task

**User Prompt:**
```
"Write pytest tests for my FastAPI endpoint"
```

**Hook Detection:**
- Keywords: pytest (testing), FastAPI (framework)
- Project: Python detected via pyproject.toml
- Matched Rules: base/testing-philosophy, languages/python/testing, frameworks/fastapi

**Activation Flow:**
```
Hook Output → "STEP 1: EVALUATE... STEP 2: ACTIVATE... STEP 3: IMPLEMENT"
Claude → Calls Skill("centralized-rules")
Skill → Loads 3 relevant rules (~8K tokens)
Claude → Implements tests using loaded guidelines
```

### Example 2: React Component

**User Prompt:**
```
"Add a login form component to my Next.js app"
```

**Hook Detection:**
- Keywords: component (React), Next.js (framework), login (security)
- Project: TypeScript + Next.js detected
- Matched Rules: frameworks/react, frameworks/nextjs, base/security-principles

**Activation Flow:**
```
Hook → Injects activation instruction
Claude → Evaluates rules, activates skill, implements component
```

### Example 3: Code Review

**User Prompt:**
```
"Review this Go function for performance issues"
```

**Hook Detection:**
- Keywords: review, Go, performance
- Project: Go detected via go.mod
- Matched Rules: base/code-quality, languages/go, base/refactoring-patterns

## Hook Configuration

The hook system is configured in `.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "description": "Activate centralized-rules skill",
      "hooks": [{
        "type": "command",
        "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/activate-rules.sh"
      }]
    }]
  }
}
```

### Hook Behavior

- **Input**: Receives user prompt as JSON on stdin
- **Processing**: Detects context, matches keywords, generates activation instruction
- **Output**: Mandatory 3-step activation message injected into Claude's context
- **Exit Code**: 0 for success, 2 to block (currently always allows)

### Customization

You can customize the hook's behavior by:

1. **Edit keyword mappings** in `.claude/skills/skill-rules.json`
2. **Modify detection logic** in `.claude/hooks/activate-rules.sh`
3. **Enable verbose logging**: Set `VERBOSE=true` environment variable
4. **Adjust activation thresholds** in `skill-rules.json`

## Skill Tools

The skill provides these tools (when activated):

### 1. detect_context

Analyzes the current project and conversation to determine:
- Programming languages in use
- Frameworks detected
- Task intent (testing, refactoring, security, etc.)
- Confidence level for each detection

**Usage:**
```typescript
// Automatically called by the skill
detect_context({
  workingDirectory: "/path/to/project",
  recentMessages: ["user prompt", "..."]
})
```

### 2. select_rules

Scores and ranks rules based on context:
- Keyword matching (50 points per match)
- Pattern matching (30 points per pattern)
- File context (20 points per file match)
- Returns top N rules within token budget

**Usage:**
```typescript
select_rules({
  context: detectedContext,
  maxRules: 5,
  maxTokens: 5000
})
```

### 3. get_rules

Fetches rule content from GitHub:
- Cached for 1 hour (configurable)
- Supports multiple branches
- Returns markdown content ready for injection

**Usage:**
```typescript
get_rules({
  rules: ["base/code-quality", "languages/python"],
  repo: "paulduvall/centralized-rules",
  branch: "main"
})
```

## Progressive Disclosure Pattern

The key insight of progressive disclosure:

**Traditional Approach (Inefficient):**
```
Load all 50 rules → 40K tokens → Little room for code
```

**Progressive Disclosure (Efficient):**
```
Load 3-5 relevant rules → 10K tokens → Plenty of room for code + conversation
```

### Selection Algorithm

Rules are scored based on:

1. **Direct keyword match**: +50 points
   - User says "pytest" → base/testing-philosophy
   - User says "fastapi" → frameworks/fastapi

2. **Pattern match**: +30 points
   - Regex: "(write|create).*test" → testing rules
   - Regex: "(refactor|improve)" → refactoring rules

3. **File context**: +20 points
   - Working on *.test.py → testing rules
   - Working on *.tsx → React rules

4. **Always-load rules**: +100 points
   - base/code-quality (always included)

**Example Scoring:**
```
User: "Write pytest tests for my FastAPI endpoint"

Scores:
- base/testing-philosophy: 150 (always-testing + keyword "pytest" + pattern match)
- frameworks/fastapi: 130 (keyword "fastapi" + file context)
- languages/python/testing: 120 (keyword "pytest" + file context *.py)
- base/code-quality: 100 (always-load)
- languages/python: 70 (file context)

Selected (top 3): testing-philosophy, fastapi, python/testing
```

## Installation & Setup

### 1. Install the Skill

```bash
curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/main/skill/install.sh | bash
```

### 2. Configure Claude Code

Add to `~/.config/claude/claude_desktop_config.json` (or Claude Code config):

```json
{
  "skills": [{
    "name": "centralized-rules",
    "path": "~/centralized-rules/skill"
  }]
}
```

### 3. Restart Claude Code

```bash
# Restart Claude Code CLI for hooks to take effect
claude-code restart
# Or restart Claude Desktop app
```

### 4. Test Activation

Try any of these prompts:

```
"What coding rules are available?"
"Write a Python function with tests"
"Review my React component"
"Help me commit these changes"
```

You should see the 3-step activation instruction appear, then Claude will call the skill.

## Verification

### Check Hook is Active

```bash
# In Claude Code CLI
/hooks

# Should show:
# UserPromptSubmit:
#   - activate-rules.sh
```

### Test Hook Output

```bash
# Manually test the hook
echo '{"prompt":"Write pytest tests"}' | .claude/hooks/activate-rules.sh

# Should output the activation instruction
```

### Verify Skill Activation

In Claude Code, type:
```
"Load rules for Python testing"
```

Expected response:
```
📚 Rules Applied:
✓ Testing Philosophy (base)
✓ Python Testing (language-specific)

[Rule content follows...]
```

## Troubleshooting

### Hook Not Firing

1. Check hooks are enabled:
   ```bash
   /hooks
   ```

2. Verify settings.json syntax:
   ```bash
   cat .claude/settings.json | jq .
   ```

3. Make script executable:
   ```bash
   chmod +x .claude/hooks/activate-rules.sh
   ```

4. Restart Claude Code

### Skill Not Activating

1. Check skill is installed:
   ```bash
   ls -la ~/centralized-rules/skill/dist/
   ```

2. Verify skill configuration:
   ```bash
   cat ~/.config/claude/claude_desktop_config.json
   ```

3. Test skill manually:
   ```
   Use the Skill("centralized-rules") tool
   ```

### Verbose Logging

Enable debug output:

```bash
export VERBOSE=true
echo '{"prompt":"test"}' | .claude/hooks/activate-rules.sh
```

## Advanced Configuration

### Custom Rule Repository

Edit `.claude/settings.json`:

```json
{
  "skill": {
    "configuration": {
      "rulesRepo": "your-org/your-rules-repo",
      "rulesBranch": "main"
    }
  }
}
```

### Adjust Token Budget

```json
{
  "skill": {
    "configuration": {
      "maxRules": 3,
      "maxTokens": 8000
    }
  }
}
```

### Custom Keyword Mappings

Edit `.claude/skills/skill-rules.json` to add your own:

```json
{
  "keywordMappings": {
    "base": {
      "your_category": {
        "keywords": ["keyword1", "keyword2"],
        "rules": ["path/to/your/rule"]
      }
    }
  }
}
```

## Performance Characteristics

- **Hook Latency**: <50ms (bash script)
- **Rule Fetch**: <500ms (GitHub API, cached)
- **Cache TTL**: 1 hour (configurable)
- **Context Usage**: 10K-15K tokens (vs 40K+ without progressive disclosure)
- **Activation Rate**: ~80%+ (with forced evaluation pattern)

## Best Practices

1. **Trust the Hook**: Let it automatically activate, don't manually invoke unless needed
2. **Be Specific**: More specific prompts → better rule matching
3. **Check Loaded Rules**: Look for the "Rules Applied" banner to verify correct rules loaded
4. **Update Regularly**: Pull latest rules to stay current
   ```bash
   cd ~/centralized-rules && git pull && cd skill && npm run build
   ```

## Migration from Manual Sync

If you previously used the sync script:

**Old Way:**
```bash
./sync-rules.sh  # Manual sync before every session
```

**New Way:**
```
Just use Claude normally → Hook auto-activates → Rules auto-load
```

See `MIGRATION_GUIDE.md` for detailed transition steps.

## Support

- **Issues**: [GitHub Issues](https://github.com/paulduvall/centralized-rules/issues)
- **Discussions**: [GitHub Discussions](https://github.com/paulduvall/centralized-rules/discussions)
- **Documentation**: [Main README](../README.md)

---

**Made with ❤️ for efficient AI-assisted coding**
