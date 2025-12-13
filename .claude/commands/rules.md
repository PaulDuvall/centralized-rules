---
description: Discover and apply relevant development rules with visual feedback
---

# Discover Development Rules

You are working with a progressive disclosure rules system located in `.claude/RULES.md`.

## Your Task

1. **Analyze the current user request** to determine:
   - Programming language (check file extensions, imports, syntax)
   - Framework/library (look for imports, config files, dependencies)
   - Task type (testing, refactoring, feature, bug fix, review, commit)

2. **Identify relevant rule sections** from .claude/RULES.md:
   - Check the "Rule Index" table in RULES.md
   - Match task context to "When to Apply" column
   - Select 2-4 relevant sections (not all sections!)

3. **Announce what you're loading** with visual feedback:
   ```
   📚 **Rules Loaded for This Task:**
   ✓ Code Quality (base - always)
   ✓ Python Testing (language-specific)
   ✓ FastAPI Best Practices (framework-specific)

   [Your response continues here...]
   ```

4. **Apply the rules** from only those sections

5. **Optional: Cite rules inline** when making specific recommendations:
   ```
   According to **Python Testing** standards, use pytest fixtures...
   ```

## Visual Feedback Icons

Use these emojis to show rule loading:
- 📚 Rules loaded
- ✓ Rule section active
- 📖 Reading rule file
- 🎯 Applying specific rule
- ⚠️ Rule conflict or exception

## Example Workflows

### Example 1: Python Testing Task

**User**: "Write pytest tests for this FastAPI endpoint"

**Your Response**:
```
📚 **Rules Loaded for This Task:**
✓ Testing Philosophy (base/testing-philosophy.md)
✓ Python Testing (languages/python/testing.md)
✓ FastAPI Best Practices (frameworks/fastapi/best-practices.md)

I'll write comprehensive tests following these guidelines...

[tests code]

✅ Applied rules:
- Test structure (AAA pattern) - per Testing Philosophy
- pytest fixtures - per Python Testing
- TestClient usage - per FastAPI Best Practices
```

### Example 2: Code Review Task

**User**: "Review this Python function"

**Your Response**:
```
📚 **Rules Loaded for This Task:**
✓ Code Quality (base/code-quality.md)
✓ Python Coding Standards (languages/python/coding-standards.md)

Reviewing against loaded standards...

Issues found:
1. ⚠️ Function length: 45 lines (Code Quality: max 25 lines)
2. ⚠️ Missing type hints (Python Coding Standards: PEP 484)
3. ⚠️ No docstring (Python Coding Standards: required)

Recommendations: [...]
```

### Example 3: Multi-Language Task

**User**: "Review this Python API and React frontend"

**Your Response**:
```
📚 **Rules Loaded for This Task:**

**Backend (Python):**
✓ Code Quality
✓ Python Coding Standards
✓ FastAPI Best Practices

**Frontend (React):**
✓ Code Quality
✓ TypeScript Coding Standards
✓ React Best Practices

Analyzing backend... [Python-specific feedback]
Analyzing frontend... [React-specific feedback]
```

## Token Efficiency Report

After completing the task, optionally show:
```
📊 **Token Usage:**
- Rules: ~12K tokens (3 sections)
- Code: ~45K tokens
- Conversation: ~30K tokens
- Total: ~87K / 200K (43% used)
```

## Error Handling

If no rules match the task:
```
⚠️ **No specific rules detected for this task**
Using: Code Quality (base rules only)

[Response continues...]
```

If user explicitly asks for all rules:
```
📚 **Loading ALL Rules (User Requested)**
⚠️ This uses ~45K tokens
✓ All 8 sections loaded

[Response continues...]
```
