---
inclusion: fileMatch
fileMatchPattern: '**/test_*.py'
---

# ⚠️ DEPRECATED: This File Has Been Restructured

**Date:** 2025-12-10

This file (1123 lines) has been split into **5 focused files** for better progressive disclosure and faster context loading.

## 📚 New Testing Documentation Structure

**Start here:** [testing-overview.md](./testing-overview.md) - Entry point with navigation guide

**Focused guides:**

| What do you need? | Read this file |
|-------------------|----------------|
| How to mock FFmpeg, MoviePy, Whisper, LLMs, TTS | [testing-mocking.md](./testing-mocking.md) (~300 lines) |
| How to test Phase 1-4 pipeline components | [testing-pipeline.md](./testing-pipeline.md) (~300 lines) |
| How to create test videos, audio, fixtures | [testing-fixtures.md](./testing-fixtures.md) (~200 lines) |
| How to configure pytest, run tests, CI/CD | [testing-configuration.md](./testing-configuration.md) (~150 lines) |

## Why This Change?

**Problem:** Loading 1123 lines every time an agent needs testing guidance is inefficient and violates progressive disclosure principles from CLAUDE.md.

**Solution:**
- Load 150-300 lines based on specific need (mocking? fixtures? configuration?)
- Start with overview for navigation, then read specific focused file
- Faster context loading, more precise guidance
- Easier to maintain and update

## Migration Guide

**Old approach:**
```
User: "How do I mock FFmpeg?"
Agent: *reads all 1123 lines of testing-guidelines.md*
```

**New approach:**
```
User: "How do I mock FFmpeg?"
Agent: *reads testing-overview.md (150 lines) → navigates to testing-mocking.md (300 lines)*
```

## Original Content

The original content has been **preserved and reorganized** into the new files. Nothing was lost, it's just better structured.

**Archive location:** `.kiro/steering/archive/testing-guidelines-original.md` (if you need the full original for reference)

## For AI Agents

**DO NOT READ THIS FILE FOR TESTING GUIDANCE.**

Instead:
1. Read [testing-overview.md](./testing-overview.md) first
2. Follow navigation to specific file you need
3. See CLAUDE.md updated table for quick reference

---

**Last Updated:** 2025-12-10
**Deprecated in favor of:** testing-overview.md, testing-mocking.md, testing-pipeline.md, testing-fixtures.md, testing-configuration.md
