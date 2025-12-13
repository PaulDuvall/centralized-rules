# Development Agent Configuration

**Last updated:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## 🎯 Progressive Disclosure Rule System

This directory contains development rules organized hierarchically for **on-demand loading**.

**DO NOT load all rule files at once.** Use progressive disclosure to load only relevant rules.

---

## 📁 Directory Structure

```
.claude/rules/
├── base/              # Universal rules (language-agnostic)
├── languages/         # Language-specific rules
├── frameworks/        # Framework-specific rules
├── cloud/             # Cloud provider rules
└── index.json         # Machine-readable rule index
```

---

## 🔍 Discovery Process

### Step 1: Analyze User Request

Identify from the user's question:
- **Language**: Python (.py), TypeScript (.ts/.tsx), Go (.go), etc.
- **Framework**: React, FastAPI, Django, Express, etc.
- **Task type**: Testing, refactoring, code review, new feature, etc.

### Step 2: Load Relevant Rules

Use the **Read tool** to load specific rule files:

**For every task:**
```
Read .claude/rules/base/code-quality.md
```

**For language-specific tasks:**
```
Python code → Read .claude/rules/languages/python/coding-standards.md
TypeScript  → Read .claude/rules/languages/typescript/coding-standards.md
Go code     → Read .claude/rules/languages/go/coding-standards.md
```

**For framework-specific tasks:**
```
FastAPI → Read .claude/rules/frameworks/fastapi/best-practices.md
React   → Read .claude/rules/frameworks/react/best-practices.md
Django  → Read .claude/rules/frameworks/django/best-practices.md
```

**For testing tasks:**
```
Read .claude/rules/base/testing-philosophy.md
Read .claude/rules/languages/{language}/testing.md
```

### Step 3: Announce What You Loaded

Show visual feedback:

```markdown
📚 **Rules Loaded for This Task:**
✓ Code Quality (.claude/rules/base/code-quality.md)
✓ Python Coding Standards (.claude/rules/languages/python/coding-standards.md)
✓ FastAPI Best Practices (.claude/rules/frameworks/fastapi/best-practices.md)
```

---

## 📋 Rule Index - This Project

**Detected Configuration:**
- Languages:  

**Available Rules:**

### Base Rules (Always Available)

| Rule | File | When to Use |
|------|------|-------------|
| Code Quality | `base/code-quality.md` | Every task |
| Testing Philosophy | `base/testing-philosophy.md` | Testing tasks |
| Security Principles | `base/security-principles.md` | Security-relevant tasks |
| Git Workflow | `base/git-workflow.md` | Commits/PRs |
| Architecture Principles | `base/architecture-principles.md` | Architecture discussions |
| 12-Factor App | `base/12-factor-app.md` | Deployment/SaaS |
| Refactoring Patterns | `base/refactoring-patterns.md` | Refactoring tasks |

### Language-Specific Rules


---

## 💡 Usage Examples

### Example 1: Python Testing Task

**User**: "Write pytest tests for this function"

**Your workflow**:
1. Identify: Python + Testing task
2. Load rules:
   ```
   Read .claude/rules/base/testing-philosophy.md
   Read .claude/rules/languages/python/testing.md
   ```
3. Announce:
   ```
   📚 Rules Loaded: Testing Philosophy + Python Testing
   ```
4. Apply rules and write tests

**Token usage**: ~15K (vs 45K if loading all rules)

---

### Example 2: React Component Review

**User**: "Review this React component"

**Your workflow**:
1. Identify: TypeScript + React + Code Review
2. Load rules:
   ```
   Read .claude/rules/base/code-quality.md
   Read .claude/rules/languages/typescript/coding-standards.md
   Read .claude/rules/frameworks/react/best-practices.md
   ```
3. Announce:
   ```
   📚 Rules Loaded: Code Quality + TypeScript Standards + React Best Practices
   ```
4. Review against loaded rules

**Token usage**: ~18K (60% savings)

---

### Example 3: Multi-Language Project

**User**: "Review the Python API and React frontend"

**Your workflow**:
1. Identify: Python + TypeScript + FastAPI + React
2. Load rules:
   ```
   # Backend
   Read .claude/rules/base/code-quality.md
   Read .claude/rules/languages/python/coding-standards.md
   Read .claude/rules/frameworks/fastapi/best-practices.md

   # Frontend
   Read .claude/rules/languages/typescript/coding-standards.md
   Read .claude/rules/frameworks/react/best-practices.md
   ```
3. Announce what's loaded for each part
4. Apply appropriate rules to each codebase

---

## 📊 Token Efficiency

**Before (monolithic .claude/RULES.md):**
- All rules loaded: ~45K tokens
- Available for code: ~55K tokens

**After (hierarchical .claude/rules/):**
- Selective loading: ~12-18K tokens (2-3 files)
- Available for code: ~82-88K tokens
- **Improvement: 60-80% more context for code!**

---

## 🔧 Advanced: Using index.json

For programmatic rule discovery:

```bash
# See all available rules
cat .claude/rules/index.json | jq '.rules'

# Find rules for a specific language
cat .claude/rules/index.json | jq '.rules.languages.python'

# List all base rules
cat .claude/rules/index.json | jq '.rules.base[] | .name'
```

---

## ⚠️ Important Guidelines

1. **Start Narrow**: Load base + 1-2 specific rules
2. **Expand as Needed**: Add more if task requires
3. **Always Announce**: Show which rules you loaded
4. **Cite Sources**: Reference specific rules when making recommendations
5. **Stay Focused**: Don't load unrelated rules

**Goal**: Load ~10-15K of relevant rules, leaving 85-90K for code analysis.

---

## 🆘 Troubleshooting

**Q: What if no rules match the task?**
A: Load `base/code-quality.md` as a safe default.

**Q: Should I load all base rules?**
A: No! Only load relevant base rules for the task type.

**Q: What about commits/git tasks?**
A: Load `base/git-workflow.md` specifically for those tasks.

**Q: Can I load multiple language rules?**
A: Yes, for multi-language projects, load rules for each language used.

---

*Generated by progressive disclosure sync system*
