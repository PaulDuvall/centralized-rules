# Migration Guide: Claude Skill for Centralized Rules

This guide helps you understand the benefits of using the **centralized-rules Claude Skill** and how to adopt it.

## Why Migrate to the Claude Skill?

The Claude Skill provides significant advantages over manual rule management:

| Feature | Claude Skill | Manual Sync |
|---------|--------------|-------------|
| **Auto-detection** | ✅ Automatic project context detection | ❌ Manual configuration |
| **Smart Selection** | ✅ Intelligent rule selection based on context | ❌ All rules or manual selection |
| **Token Efficiency** | ✅ Only loads relevant rules (~10-15K tokens) | ❌ All rules loaded (~30-50K tokens) |
| **Intent Analysis** | ✅ Analyzes user intent from prompts | ❌ Static rules |
| **Updates** | ✅ Always fetches latest rules from GitHub | ❌ Requires manual re-sync |
| **Caching** | ✅ Built-in caching for performance | ❌ No caching |
| **Setup Time** | ⏱️ One-time install | ⏱️ Per-project setup |
| **Maintenance** | ✅ Automatic | ❌ Manual updates needed |

### Key Benefits

1. **60-80% More Context Available**: By loading only relevant rules, you have 30-35K more tokens available for your actual code.

2. **Zero Configuration**: The skill automatically detects your project's languages, frameworks, cloud providers, and maturity level.

3. **Always Up-to-Date**: Rules are fetched from GitHub, ensuring you always have the latest best practices.

4. **Intelligent Prioritization**: Security-critical rules are prioritized for urgent security issues.

5. **Maturity-Aware**: Rules adapt based on whether you're building an MVP, pre-production app, or production system.

## Installation

### For Claude Code Users (Recommended)

```bash
# Clone or update the repository
cd ~/
git clone https://github.com/paulduvall/centralized-rules.git

# Install and build the skill
cd centralized-rules/skill
npm install
npm run build

# Add to Claude configuration
# Edit ~/.config/claude/claude_desktop_config.json
```

Add the skill to your Claude config:

```json
{
  "skills": [
    {
      "name": "centralized-rules",
      "path": "~/centralized-rules/skill",
      "config": {
        "enableAutoLoad": true,
        "cacheEnabled": true,
        "maxRules": 5,
        "verbose": false
      }
    }
  ]
}
```

### For Non-Claude Tools (Cursor, Copilot, etc.)

If you're using other AI coding assistants, you can still benefit from centralized rules:

#### Option 1: Direct GitHub Reference
Add a comment in your project root referencing the rules:

```markdown
<!-- .ai-rules.md -->
# Coding Rules

This project follows the centralized rules at:
https://github.com/paulduvall/centralized-rules

Relevant rules for this project:
- Base: [Code Quality](https://github.com/paulduvall/centralized-rules/blob/main/base/code-quality.md)
- Language: [Python Coding Standards](https://github.com/paulduvall/centralized-rules/blob/main/languages/python/coding-standards.md)
- Framework: [FastAPI Best Practices](https://github.com/paulduvall/centralized-rules/blob/main/frameworks/fastapi/best-practices.md)
```

#### Option 2: Manual Copy (Not Recommended)
You can manually copy relevant rules to your project, but this requires manual updates.

## Configuration Options

The skill can be configured in `claude_desktop_config.json`:

```json
{
  "rulesRepo": "paulduvall/centralized-rules",  // GitHub repo (owner/repo)
  "rulesBranch": "main",                         // Branch to fetch from
  "enableAutoLoad": true,                        // Auto-inject rules
  "cacheEnabled": true,                          // Enable caching
  "cacheTTL": 3600,                              // Cache time (seconds)
  "maxRules": 5,                                 // Max rules per request
  "maxTokens": 5000,                             // Max tokens for rules
  "verbose": false                               // Enable debug logging
}
```

### Configuration Recommendations

**For MVP/Prototyping:**
```json
{
  "maxRules": 3,
  "maxTokens": 3000,
  "verbose": false
}
```

**For Production Projects:**
```json
{
  "maxRules": 7,
  "maxTokens": 8000,
  "verbose": true
}
```

## How It Works

### 1. Project Detection

When you start a conversation with Claude, the skill automatically:

- Detects programming languages (Python, TypeScript, Go, Java, Rust, C#)
- Identifies frameworks (FastAPI, Django, React, Next.js, Spring Boot, etc.)
- Discovers cloud providers (AWS, Vercel, Azure, GCP)
- Determines project maturity (MVP, Pre-Production, Production)

### 2. Intent Analysis

The skill analyzes your message to understand:

- **Topics**: authentication, testing, security, performance, etc.
- **Action**: implement, fix, refactor, review
- **Urgency**: high (critical/urgent) or normal

### 3. Rule Selection

Based on context and intent, the skill:

1. Scores all available rules
2. Ranks by relevance
3. Applies token budget constraints
4. Selects the top N most relevant rules

### 4. Rule Injection

Selected rules are automatically injected into Claude's context with:

- Project context summary
- List of applicable rules
- Full rule content with best practices

## Migration Steps

### Step 1: Verify Installation

```bash
cd ~/centralized-rules/skill
npm test
```

You should see:
```
✓ All 85 tests passing
```

### Step 2: Test in a Project

Navigate to any project and start a Claude conversation:

```
User: "I need to implement authentication for my API"

Claude: [Will automatically load relevant authentication, security, and API rules]
```

### Step 3: Monitor Performance

Enable verbose mode temporarily to see what's happening:

```json
{
  "verbose": true
}
```

Watch the console output to see:
- Detected project context
- Selected rules
- Execution timing

### Step 4: Optimize Configuration

Based on your usage, adjust:
- `maxRules` for more or fewer rules
- `maxTokens` to control token usage
- `cacheTTL` for cache refresh frequency

## Troubleshooting

### Skill Not Loading

**Problem**: Rules aren't being injected

**Solutions**:
1. Check that `enableAutoLoad: true` in config
2. Verify skill path is correct in Claude config
3. Check console for errors (enable `verbose: true`)

### Too Many Rules Loaded

**Problem**: Too many rules consuming too much context

**Solutions**:
1. Reduce `maxRules` (default: 5, try 3)
2. Set a stricter `maxTokens` limit
3. Be more specific in your prompts

### Rules Out of Date

**Problem**: Rules seem stale

**Solutions**:
1. Clear cache: Restart Claude
2. Reduce `cacheTTL` for more frequent updates
3. Pull latest from GitHub: `cd ~/centralized-rules && git pull`

### GitHub API Rate Limiting

**Problem**: Hitting GitHub API limits

**Solutions**:
1. Enable caching: `cacheEnabled: true`
2. Increase `cacheTTL` (e.g., 7200 for 2 hours)
3. Set `GITHUB_TOKEN` environment variable for higher limits

## FAQs

### Q: Do I need to reinstall for updates?

**A:** No, just pull the latest:
```bash
cd ~/centralized-rules
git pull
cd skill
npm run build
```

### Q: Can I use my own rules repository?

**A:** Yes! Set `rulesRepo` to your `owner/repo`:
```json
{
  "rulesRepo": "mycompany/coding-rules"
}
```

### Q: How do I disable auto-loading temporarily?

**A:** Set `enableAutoLoad: false` in your config, or manually invoke rules using the `get_rules` tool.

### Q: Does this work offline?

**A:** Partially. Cached rules work offline, but new rules require internet access to fetch from GitHub.

### Q: How do I see which rules were loaded?

**A:** Enable verbose mode (`verbose: true`) and check the console output.

## Best Practices

1. **Start with Defaults**: Use default settings initially, then optimize based on your needs.

2. **Enable Caching**: Always keep `cacheEnabled: true` for better performance and reduced API calls.

3. **Use Specific Prompts**: More specific prompts lead to better rule selection.
   - Good: "Implement JWT authentication with token refresh"
   - Less good: "Add login"

4. **Monitor Token Usage**: Check verbose output occasionally to ensure you're not loading too many rules.

5. **Keep Rules Updated**: Run `git pull` periodically to get the latest best practices.

6. **Contribute Back**: If you create project-specific rules, consider contributing them back to the repository.

## Next Steps

- ✅ Install the Claude Skill
- ✅ Test with a sample project
- ✅ Optimize configuration
- ✅ Star the repository for updates
- ✅ Contribute improvements via PRs

## Support

- **Issues**: https://github.com/paulduvall/centralized-rules/issues
- **Discussions**: https://github.com/paulduvall/centralized-rules/issues
- **Contributing**: Open an issue or pull request on GitHub

---

**Welcome to the future of AI-assisted development with context-aware, intelligent coding rules!** 🚀
