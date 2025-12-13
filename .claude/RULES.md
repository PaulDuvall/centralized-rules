# AI Development Rules

**Last updated:** 2025-12-13 20:55:24 UTC

---

## 🎯 PROGRESSIVE DISCLOSURE: How to Use These Rules

This file contains multiple rule categories. **DO NOT apply all rules to every task.**

### Your Progressive Discovery Process

1. **Identify Task Context**
   - What language is the user working with? (file extensions, imports, syntax)
   - What framework is involved? (imports, config files, patterns)
   - What type of task? (testing, refactoring, new feature, bug fix, code review)

2. **Load ONLY Relevant Sections**
   - For Python code → Read 'Python Coding Standards' + 'Python Testing'
   - For React component → Read 'React Best Practices' + 'Typescript Coding Standards'
   - For testing tasks → Read 'Testing Philosophy' + language-specific testing
   - For code review → Read 'Code Quality' + language-specific standards

3. **Base Rules Application**
   - **Always consider:** Code Quality Standards, Security Principles
   - **Context-dependent:**
     * Git Workflow → Only for commit/PR tasks
     * Testing Philosophy → Only for testing tasks
     * 12-Factor App → Only for architecture/deployment discussions

4. **Discovery Pattern Examples**
   ```
   User: 'Review this Python function'
   → Load: Code Quality + Python Coding Standards

   User: 'Write pytest tests for this FastAPI endpoint'
   → Load: Testing Philosophy + Python Testing + FastAPI Best Practices

   User: 'Fix this React component's rendering'
   → Load: Code Quality + TypeScript Coding Standards + React Best Practices

   User: 'Help me commit these changes'
   → Load: Git Workflow + Code Quality
   ```

### 📋 Rule Index - This Project

**Detected Configuration:**
- Languages: None detected (base rules only)
- Frameworks: None detected

**Available Rules Below:**

| Category | When to Apply | Section Name |
|----------|---------------|--------------|
| Base | Every task | Code Quality |
| Base | Security-relevant tasks | Security Principles |
| Base | Testing tasks | Testing Philosophy |
| Base | Commits/PRs | Git Workflow |
| Base | Development process | Development Workflow |
| Base | Architecture discussions | Architecture Principles |
| Base | Architecture/deployment discussions | 12-Factor App |
| Base | Refactoring tasks | Refactoring Patterns |
| Base | AI-assisted development | Ai Assisted Development |
| Base | Metrics/monitoring tasks | Metrics Standards |

### 💡 Token Efficiency Tips

- **Start narrow**: Load base + specific language/framework only
- **Expand as needed**: Add more sections if task requires
- **Skip irrelevant**: Don't load React rules for Python backend work
- **Typical load**: 2-3 sections per task (not all 8+)

### ⚠️ Important

Loading ALL rules below will consume 30K-50K tokens. Be selective!
Your goal: Load ~10K-15K of relevant rules, leaving context for code.

---

# Development Rules

