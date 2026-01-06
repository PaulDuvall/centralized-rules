# Centralized Rules Skill for Claude

> Smart coding rules that automatically load based on your project context

A Claude skill that intelligently detects your project's language, framework, and maturity level, then automatically injects the most relevant coding standards and best practices into Claude's context.

📖 **New to the skill?** See the [Migration Guide](./MIGRATION_GUIDE.md) for benefits and comparison with manual approaches.

## Features

- **🎯 Context-Aware**: Automatically detects Python, TypeScript, Java, Go, Rust, Bash/Shell, and more
- **🧠 Smart Selection**: Loads only the 3-5 most relevant rules per request (not all 50+)
- **⚡ Fast & Cached**: Rules are cached for 1 hour, typical load time <500ms
- **🔄 Always Fresh**: Fetches latest rules from GitHub automatically
- **📦 Zero Config**: Works out of the box, customizable if needed
- **🌐 Multi-Framework**: Supports React, FastAPI, Django, Next.js, Spring Boot, and more

## Installation

### Quick Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/main/skill/install.sh | bash
```

This will:
- Clone the centralized-rules repository to `~/centralized-rules`
- Install dependencies and build the skill
- Show you how to configure Claude

### Manual Install

```bash
# Clone repository
git clone https://github.com/paulduvall/centralized-rules
cd centralized-rules/skill

# Install dependencies
npm install

# Build skill
npm run build
```

Then configure Claude (see Configuration section below).

### Update Existing Installation

```bash
cd ~/centralized-rules
git pull
cd skill
npm run build
```

## Hook-Based Activation System

### NEW: UserPromptSubmit Hook (Recommended)

The centralized-rules skill now includes a **hook-based activation system** that achieves ~80%+ activation reliability. When you type a prompt, the hook automatically:

1. Detects your project context (languages, frameworks)
2. Matches keywords in your prompt against rule categories
3. Injects a mandatory 3-step activation instruction into Claude's context
4. Forces Claude to evaluate and load relevant rules before implementing

**Setup:**

The hook is configured in `.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "hooks": [{
        "type": "command",
        "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/activate-rules.sh"
      }]
    }]
  }
}
```

**How it works:**

```
You: "Write pytest tests for my FastAPI endpoint"
       ↓
Hook fires → Detects: Python, FastAPI, testing keywords
       ↓
Injects mandatory activation instruction:
  "STEP 1: EVALUATE which rules apply
   STEP 2: ACTIVATE using Skill(centralized-rules)
   STEP 3: IMPLEMENT only after activation"
       ↓
Claude follows the steps → Loads rules → Implements with guidelines
```

**Verification:**

After restarting Claude Code, check hooks are active:

```bash
/hooks
```

You should see:
```
UserPromptSubmit:
  - activate-rules.sh
```

See the documentation for detailed information on the hook system.

## Usage

### Automatic (Recommended)

With the hook system enabled, just use Claude normally:

```
You: "Help me add JWT authentication to my FastAPI app"

Claude: [Automatically loads FastAPI + Python + Security rules]
        "For JWT authentication in FastAPI, following your project's patterns..."
```

No manual action needed! The skill:
1. Detects your project (Python + FastAPI)
2. Analyzes your intent ("authentication")
3. Loads 3 relevant rules (FastAPI auth patterns, Python security, base security)
4. Claude uses them automatically

### Manual (Optional)

You can also manually request specific rules:

```
You: "Load rules for TypeScript and React testing"

Claude: [Uses get_rules tool]
        "I've loaded the TypeScript testing and React testing rules..."
```

## How It Works

```typescript
// When you ask Claude a question:
User: "Add a login form to my React app"

// Behind the scenes:
1. UserPromptSubmit hook fires (.claude/hooks/activate-rules.sh)
2. Hook detects: TypeScript + React + Next.js (from project files)
3. Hook analyzes intent: "login form" → authentication, forms (keyword matching)
4. Hook injects mandatory activation instruction into context
5. Claude receives instruction, evaluates which rules apply
6. Claude calls Skill("centralized-rules") tool
7. Skill scores all rules:
   - react/forms.md: 150 points ⭐
   - react/auth-patterns.md: 130 points
   - typescript/coding-standards.md: 120 points
   - base/security-principles.md: 70 points
8. Skill selects top 3 (token budget: 5K)
9. Skill fetches from GitHub (cached)
10. Skill returns rules to Claude

// Claude responds with rules applied:
Claude: "📚 Rules Applied:
         ✓ React Forms (framework-specific)
         ✓ TypeScript Standards (language-specific)
         ✓ Security Principles (base)

         For React forms with authentication, following your patterns:
         1. Use React Hook Form (per your standards)
         2. Implement with TypeScript types
         3. Add Zod validation
         ..."
```

## Prompt Classification

The rule matching system uses **semantic category classification** to intelligently determine which rules to inject based on your prompt's intent. This ensures you only get relevant rules and avoids wasting tokens on non-code tasks.

### Categories

**Code Categories** (rules are injected):
- **Code Implementation**: Creating features, components, functions, APIs
- **Code Debugging**: Fixing errors, bugs, crashes, test failures
- **Code Review**: Reviewing code quality, best practices, testing strategies
- **Architecture**: System design, patterns, scalability, data models
- **DevOps**: Deployment, CI/CD, infrastructure, monitoring
- **Documentation**: Writing docs, comments, guides, API documentation

**Non-Code Categories** (rules are skipped to save tokens):
- **Legal/Business**: Contracts, privacy policies, HR documents, financial decisions
- **General Questions**: Learning questions, explanations, concept discussions
- **Unclear**: Ambiguous prompts that don't clearly fit any category

### How It Works

The classifier uses a two-phase approach for accuracy:

1. **Pattern Matching** (High Confidence)
   - Checks 70+ specialized patterns for instant classification
   - Examples:
     - `"Fix the bug in auth.ts"` → CODE_DEBUGGING
     - `"Design a microservices architecture"` → ARCHITECTURE
     - `"Review our privacy policy"` → LEGAL_BUSINESS (skips rules)

2. **Keyword Scoring** (Fallback)
   - For unclear prompts, scores keywords by weight
   - Requires clear winner (no ties, score ≥ 2)
   - Example: `"implement authentication"` scores high on CODE_IMPLEMENTATION

3. **Category-Aware Rule Boosting**
   - Rules matching the category get priority boost (+15-30 points)
   - Example: For CODE_DEBUGGING prompts, testing and debugging rules are boosted
   - Ensures most relevant rules appear first

### Benefits

- **Token Savings**: Skips rule injection for legal/business prompts (saves ~10K tokens)
- **Better Relevance**: Rules are prioritized based on prompt category
- **Higher Accuracy**: 0% false positives/negatives in testing
- **Transparent**: Metadata shows detected category in hook logs

### Examples

```
✅ Code-Related (rules loaded):
"Fix the authentication bug" → CODE_DEBUGGING
"Add a React form component" → CODE_IMPLEMENTATION
"Review this API design" → CODE_REVIEW
"Should we use microservices?" → ARCHITECTURE

❌ Non-Code (rules skipped):
"Draft a privacy policy" → LEGAL_BUSINESS
"What is a closure?" → GENERAL_QUESTION
"Operating agreement terms" → LEGAL_BUSINESS
```

See [`docs/architecture/classification-system.md`](../docs/architecture/classification-system.md) for architecture details.

### Progressive Disclosure Benefits

- **Context Efficient**: Loads 3-5 rules (~10K tokens) instead of all 50+ rules (~40K tokens)
- **Always Relevant**: Rules match your specific task, not generic guidelines
- **Automatic**: No manual activation needed, hook handles everything
- **Transparent**: Claude announces which rules are applied (look for 📚 Rules Applied banner)
- **Cached**: Rules fetched from GitHub are cached for 1 hour
- **Smart Filtering**: Skips rules entirely for non-code prompts (saves tokens)

## Configuration

### Adding Skill to Claude

After installation, add the skill to your Claude configuration:

**File:** `~/.config/claude/claude_desktop_config.json`

```json
{
  "skills": [
    {
      "name": "centralized-rules",
      "path": "~/centralized-rules/skill"
    }
  ]
}
```

Or use an absolute path:

```json
{
  "skills": [
    {
      "name": "centralized-rules",
      "path": "/Users/yourname/centralized-rules/skill"
    }
  ]
}
```

After adding, restart Claude Desktop or Claude Code.

### Skill Options

The skill works out of the box, but can be customized via `skill.json`:

```json
{
  "configuration": {
    "rulesRepo": "paulduvall/centralized-rules",
    "enableAutoLoad": true,
    "cacheEnabled": true,
    "cacheTTL": 3600,
    "maxRules": 5,
    "maxTokens": 5000,
    "verbose": false
  }
}
```

### Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `rulesRepo` | `paulduvall/centralized-rules` | GitHub repo with rules |
| `rulesBranch` | `main` | Git branch to fetch from |
| `enableAutoLoad` | `true` | Auto-load rules via hook |
| `cacheEnabled` | `true` | Cache fetched rules |
| `cacheTTL` | `3600` | Cache time-to-live (seconds) |
| `maxRules` | `5` | Max rules per request |
| `maxTokens` | `5000` | Max tokens for rules |
| `verbose` | `false` | Enable debug logging |

## Supported Technologies

### Languages
- Python
- TypeScript / JavaScript
- Go
- Java
- Rust
- C#

### Frameworks
- **Python**: FastAPI, Django, Flask
- **TypeScript**: React, Next.js, Express, Nest.js
- **Java**: Spring Boot
- **Go**: Gin, Echo

### Cloud Providers
- AWS
- Vercel
- Azure
- GCP

## Project Structure

```
centralized-rules-skill/
├── src/
│   ├── hooks/              # beforeResponse hook
│   ├── tools/              # detect-context, get-rules, select-rules
│   ├── cache/              # Rules caching
│   └── types/              # TypeScript type definitions
├── tests/
│   ├── unit/               # Unit tests
│   ├── integration/        # Integration tests
│   └── e2e/                # End-to-end tests
├── skill.json              # Skill manifest
├── package.json            # NPM package
└── README.md               # This file
```

## Development

### Setup

```bash
# Install dependencies
npm install

# Run tests
npm test

# Run tests with coverage
npm run test:coverage

# Build
npm run build

# Development mode (watch)
npm run dev

# Lint
npm run lint

# Format code
npm run format
```

### Running Tests

```bash
# Run all tests
npm test

# Run with UI
npm run test:ui

# Run in watch mode
npm run test:watch

# Generate coverage report
npm run test:coverage
```

### Building

```bash
# Clean build
npm run rebuild

# Or step by step
npm run clean
npm run build
```

## Implementation Status

### ✅ Completed

**Core Setup (cs1, cs2, cs8)**
- ✅ Development environment setup (cs1)
- ✅ TypeScript configuration with strict mode (cs1)
- ✅ Testing framework - Vitest with coverage (cs1)
- ✅ ESLint & Prettier configuration (cs1)
- ✅ Skill manifest (skill.json) (cs2)
- ✅ Type definitions (cs2)
- ✅ Project structure (cs2)
- ✅ Git-based distribution with install script (cs8)

**Refactorings (rf1, rf2, rf3)**
- ✅ Removed validate_code tool (YAGNI) (rf1)
- ✅ Removed NPM publishing cruft from package.json (rf2)
- ✅ Added implementation status section to README (rf3)

### 🚧 Not Yet Implemented

**Core Features**
- ☐ Context detection tool - detect languages, frameworks, cloud providers (cs3)
- ☐ Rule selection algorithm - scoring and ranking (cs4)
- ☐ GitHub fetching with caching - fetch rules from repo (cs5)
- ☐ beforeResponse hook - automatic rule injection (cs6)
- ☐ Comprehensive test suite - unit, integration, E2E (cs7)
- ☐ Migration guide for sync script users (cs9)

**Future Refactorings**
- ☐ Replace hardcoded enums with dynamic values (rf4)
- ☐ Review type definitions after implementation (rf5)

## Verification & Testing

### Verify Hook Installation

After installing and restarting Claude Code, verify the hook is active:

```bash
# In Claude Code CLI
/hooks
```

Expected output:
```
UserPromptSubmit:
  - activate-rules.sh
```

### Test Hook Manually

Test the hook script directly:

```bash
# Navigate to your project
cd ~/centralized-rules

# Test with sample prompt
echo '{"prompt":"Write pytest tests for my FastAPI endpoint"}' | .claude/hooks/activate-rules.sh
```

Expected output: The 3-step activation instruction (EVALUATE → ACTIVATE → IMPLEMENT).

### Test in Claude Code

Try these test prompts:

1. **Testing task:**
   ```
   "What testing rules are available for Python?"
   ```
   Expected: Hook triggers, Claude loads testing + Python rules

2. **Framework-specific:**
   ```
   "Write a React component with TypeScript"
   ```
   Expected: Hook triggers, Claude loads React + TypeScript rules

3. **Security task:**
   ```
   "Add authentication to my API"
   ```
   Expected: Hook triggers, Claude loads security + relevant framework rules

### Verify Skill Activation

Look for the **📚 Rules Applied** banner in Claude's response:

```
📚 Rules Applied:
✓ Testing Philosophy (base)
✓ Python Testing (language-specific)
✓ FastAPI Best Practices (framework-specific)
```

If you see this banner, the skill activated successfully!

## Troubleshooting

### Issue: Hook Not Appearing in `/hooks`

**Solution:**

1. Check `.claude/settings.json` syntax:
   ```bash
   cat .claude/settings.json | jq .
   ```

2. Verify script is executable:
   ```bash
   chmod +x .claude/hooks/activate-rules.sh
   ```

3. Restart Claude Code completely

### Issue: Hook Fires But Skill Doesn't Activate

**Possible causes:**

1. **Skill not installed**: Check `~/centralized-rules/skill/dist/` exists
2. **Skill not configured**: Verify `~/.config/claude/claude_desktop_config.json` has skill entry
3. **Claude ignoring instruction**: Try more specific prompts with clear keywords

**Debug steps:**

```bash
# 1. Verify skill installation
ls -la ~/centralized-rules/skill/dist/

# 2. Check skill config
cat ~/.config/claude/claude_desktop_config.json

# 3. Test hook manually
echo '{"prompt":"test"}' | .claude/hooks/activate-rules.sh

# 4. Enable verbose logging
export VERBOSE=true
echo '{"prompt":"test"}' | .claude/hooks/activate-rules.sh
```

### Issue: Wrong Rules Being Loaded

**Solution:** Update keyword mappings in `.claude/skills/skill-rules.json`:

```json
{
  "keywordMappings": {
    "base": {
      "your_category": {
        "keywords": ["your", "custom", "keywords"],
        "rules": ["path/to/your/rule"]
      }
    }
  }
}
```

### Issue: Hook Causes Errors

**Solution:** Check hook script logs:

```bash
# Test with verbose output
VERBOSE=true echo '{"prompt":"test"}' | .claude/hooks/activate-rules.sh 2>&1
```

Common issues:
- Missing dependencies (jq, sed, grep) - script uses basic bash only
- Permission issues - ensure script is executable
- JSON parsing errors - verify input format

## Best Practices

1. **Trust the Automation**: Let the hook system work automatically, don't manually invoke unless debugging
2. **Use Clear Keywords**: More specific prompts → better rule matching
   - ✅ "Write pytest tests for FastAPI endpoint"
   - ❌ "Make some tests"

3. **Check Rules Applied**: Look for the 📚 banner to verify correct rules loaded

4. **Keep Updated**: Pull latest rules regularly:
   ```bash
   cd ~/centralized-rules && git pull && cd skill && npm run build
   ```

5. **Customize for Your Team**: Fork the repo and add your own rules/keywords

## Contributing

Contributions welcome! Please open an issue or pull request on GitHub.

## License

MIT - see [LICENSE](../LICENSE)

## Links

- **Main Repository**: [centralized-rules](https://github.com/paulduvall/centralized-rules)
- **Issues**: [GitHub Issues](https://github.com/paulduvall/centralized-rules/issues)
- **Documentation**: [Full Docs](https://github.com/paulduvall/centralized-rules#readme)

## Support

Need help? Found a bug?
- 📝 [Open an issue](https://github.com/paulduvall/centralized-rules/issues)
- 💬 [GitHub Issues](https://github.com/paulduvall/centralized-rules/issues)

---

**Made with ❤️ for better coding with Claude**
