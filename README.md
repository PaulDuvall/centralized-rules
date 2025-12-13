# Steering Rules - Quick Reference

**Purpose:** Concise, actionable guidance for active development.

## 📍 Quick Navigation

### 📊 Active Reference Files

**Core Development:**
- **metrics-and-limits.md** - Numeric thresholds (coverage %, file size, complexity, API costs)
- **coding-standards.md** - Python patterns, type hints, error handling, PEP 8
- **refactoring-workflow.md** - When and how to refactor (mandatory after each task)
- **git-workflow.md** - Branch strategy, commit messages, PR workflow

**Testing (5 focused files):**
- **testing-overview.md** - Entry point, test philosophy, navigation guide
- **testing-mocking.md** - Mock FFmpeg, MoviePy, Whisper, LLMs, TTS
- **testing-pipeline.md** - Test Phase 1-4 video processing pipeline
- **testing-fixtures.md** - Create test videos/audio, pytest fixtures
- **testing-configuration.md** - pytest config, running tests, CI/CD integration

**Infrastructure & Performance:**
- **cicd-workflow.md** - GitHub Actions, video processing in CI, deployment
- **performance-monitoring.md** - Track performance, API costs, benchmarking
- **ai-integration.md** - Whisper, GPT-4, Claude, TTS integration patterns

**Data & Security:**
- **data-conventions.md** - JSON manifests, Pydantic models, config files
- **security.md** - API key management, AWS SSM, user data privacy

### 📦 Archived/Deprecated
- **testing-guidelines.md** - DEPRECATED: Split into 5 focused files (see Testing above)

## 🎯 Quick Context Detection

### Starting a new feature
→ Read: `refactoring-workflow.md`, `coding-standards.md`
→ Reference: `metrics-and-limits.md`, `testing-overview.md`

### Writing tests
→ Read: `testing-overview.md` (then navigate to specific testing file)
→ Reference: `metrics-and-limits.md` (80% coverage requirement)

### Mocking external dependencies
→ Read: `testing-mocking.md`
→ Reference: `ai-integration.md` (for real AI service patterns)

### Refactoring code
→ Read: `refactoring-workflow.md`
→ Reference: `coding-standards.md`, `metrics-and-limits.md`

### Working with AI services (Whisper, GPT, TTS)
→ Read: `ai-integration.md`
→ Reference: `performance-monitoring.md` (API costs), `testing-mocking.md` (mocking)

### Performance optimization
→ Read: `performance-monitoring.md`
→ Reference: `ai-integration.md` (API cost optimization)

### CI/CD and GitHub Actions
→ Read: `cicd-workflow.md`
→ Reference: `testing-configuration.md` (pytest markers for CI)

### Working with manifests/data
→ Read: `data-conventions.md`
→ Reference: `coding-standards.md`

## 🔧 Kiro Multi-Agent Context

**Current project phase:** Active Development
**Active contexts:** `video_processing`, `ai_integration`, `testing`
**Project type:** Python CLI tool for video optimization

## Icon System

When working on tasks, these icons show which rules are being applied:

- 🧪 **Testing** - Running tests, checking coverage (see testing-overview.md)
- 🔧 **Refactoring** - Checking complexity, splitting files (see refactoring-workflow.md)
- 📝 **Git** - Committing, pushing changes (see git-workflow.md)
- 🚦 **CI/CD** - GitHub Actions, builds (see cicd-workflow.md)
- 📐 **Coding Standards** - Type safety, error handling (see coding-standards.md)
- 🔒 **Security** - API keys, secrets management (see security.md)
- 📄 **Data** - JSON manifests, Pydantic models (see data-conventions.md)
- 📊 **Performance** - Performance tracking, costs (see performance-monitoring.md)
- 🤖 **AI Integration** - Whisper, LLMs, TTS (see ai-integration.md)

See individual steering files for detailed icon usage examples.

## 📏 Philosophy

**Steering files answer:** "What do I do right now?"
**Docs answer:** "How does this work in depth?"

**Current focus:** Ship high-quality video processing features with comprehensive testing and monitoring.

## 🎓 Progressive Disclosure

**New to the codebase?** Start here:
1. Read `metrics-and-limits.md` - Understand quality gates
2. Read `testing-overview.md` - Understand testing approach
3. Read `refactoring-workflow.md` - Understand mandatory workflow
4. Explore topic-specific files as needed

**Working on specific features?** Use the Quick Context Detection above to find the right file.

## 📋 Key Metrics Summary

From `metrics-and-limits.md`:

**Code Quality:**
- Function max: 20 lines
- File max: 300 lines
- Coverage min: 80%
- Complexity max: 10

**Performance (30-min video):**
- Total pipeline: ~15 minutes
- Phase 1: ~2 min | Phase 2: ~20 sec | Phase 3: ~90 sec | Phase 4: ~12 min

**API Costs (30-min video):**
- Expensive path: $2.60 (Whisper API + GPT-4o + ElevenLabs)
- Budget path: $0.26 (Local Whisper + GPT-4o-mini + OpenAI TTS)

**See metrics-and-limits.md for complete details.**

---

**Last Updated:** 2025-12-10
**Python Version:** 3.11+
**Total Steering Files:** 16 files (7,000+ lines of guidance)
