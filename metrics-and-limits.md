# Metrics and Limits - Single Source of Truth

**Purpose:** Define all numeric thresholds, limits, and quality gates in ONE place to prevent contradictions.

**Cross-reference from:** `pyproject.toml`, `pytest.ini`, all steering files

---

## Task Breakdown

**Ideal task duration:** 1-3 hours
**Maximum task duration:** 4-8 hours for complex work
**Rule:** If a task exceeds 8 hours, break it into smaller atomic units

**Source:** Based on atomic task methodology - small, testable, shippable increments

---

## Code Quality Limits

### File and Function Size

| Metric | Limit | Rationale |
|--------|-------|-----------|
| **Function length** | ≤ 20 lines | Readability, testability |
| **File length** | ≤ 300 lines | Single responsibility |
| **Class length** | ≤ 250 lines | Focused responsibility |
| **Cyclomatic complexity** | ≤ 10 per function | Maintainability |
| **Nesting depth** | ≤ 4 levels | Cognitive load |

**Enforcement:** ruff (complexity), manual code review, refactoring workflow

---

## Test Coverage

| Metric | Threshold | Notes |
|--------|-----------|-------|
| **Unit test coverage** | ≥ 80% | Minimum for all new code |
| **Branch coverage** | ≥ 90% | Critical paths covered |
| **Integration coverage** | ≥ 70% | Video processing, API interactions |

**Important:**
- Coverage of exactly 80% is passing (≥ not >)
- Coverage < 80% blocks PR merge
- Exceptions require explicit approval

**Enforcement:** pytest-cov coverage reports, GitHub Actions gate

---

## Build and CI/CD Performance

| Metric | Limit | Impact if exceeded |
|--------|-------|-------------------|
| **Commit stage build** | < 10 minutes | Breaks fast feedback loop |
| **Full test suite** | < 20 minutes | Developer friction |
| **Deploy to preview** | N/A | CLI tool, no deployment |

**Note:** This is a CLI tool, not a web application. Build times are for test execution.

**Source:** Continuous delivery best practices

---

## Security and Type Safety

| Rule | Enforcement |
|------|-------------|
| **Type hints required** | mypy strict mode, code review |
| **Parameterized queries** | Code review (if database added) |
| **No hardcoded secrets** | Pre-commit hook, secret scanner |
| **Error handling on async** | Code review, testing |

**See:** `pyproject.toml` for mypy configuration

---

## Error Handling

**Requirement:** All async functions and external API calls must have explicit error handling

**Pattern:**
```python
import logging

logger = logging.getLogger(__name__)

try:
    result = await external_api.call()
except APIError as e:
    logger.error("API call failed", extra={"error": str(e), "context": context})
    raise ApplicationError("User-friendly message") from e
```

**See:** `.kiro/steering/coding-standards.md` for patterns

---

## Python-Specific Limits

### Type Checking

| Rule | Tool | Configuration |
|------|------|---------------|
| **Strict type hints** | mypy | `pyproject.toml` |
| **No `Any` types** | mypy | `--disallow-any-explicit` |
| **Check untyped defs** | mypy | `--check-untyped-defs` |

### Code Style

| Rule | Tool | Configuration |
|------|------|---------------|
| **Black formatting** | black | `pyproject.toml` |
| **Import sorting** | ruff | `pyproject.toml` |
| **Linting** | ruff | `pyproject.toml` |
| **Line length** | black | 100 characters |

### Testing

| Rule | Tool | Configuration |
|------|------|---------------|
| **Coverage minimum** | pytest-cov | 80% |
| **Test markers** | pytest | `pytest.ini` |
| **Timeout** | pytest | 30s default |

---

## Video Processing Performance Targets

### Phase Performance (30-minute input video)

| Phase | Target Time | Acceptable Range |
|-------|-------------|------------------|
| **Phase 1 (Ingest)** | ~2 minutes | 1-5 minutes |
| **Phase 2 (Director)** | ~20 seconds | 10-60 seconds |
| **Phase 3 (Voice)** | ~90 seconds | 30-180 seconds |
| **Phase 4 (Assembly)** | ~12 minutes | 5-20 minutes |
| **Total Pipeline** | ~15 minutes | 10-25 minutes |

**Note:** Times vary based on hardware, video complexity, and API latency.

**See:** `.kiro/steering/performance-monitoring.md` for details

---

## API Cost Limits (per 30-minute video)

| Service | Cost | Budget-Friendly Alternative |
|---------|------|----------------------------|
| **Whisper API** | $0.18 | Local Whisper: $0 |
| **GPT-4o** | $0.32 | GPT-4o-mini: $0.05 |
| **ElevenLabs** | $2.10 | OpenAI TTS: $0.21 |
| **Total (expensive)** | $2.60 | **Total (cheap): $0.26** |

**Budget Recommendation:** < $0.50 per video for sustainable operation

**See:** `.kiro/steering/ai-integration.md` for cost optimization

---

## Usage Notes

**When defining a new metric:**
1. Add it to this file FIRST
2. Reference this file from other docs (don't duplicate the value)
3. Update `pyproject.toml` or `pytest.ini` if it needs automated enforcement

**When metrics conflict:**
- This file is the source of truth
- Update this file, then propagate changes
- Don't update scattered files independently

**Cross-references:**
- `pyproject.toml` - Python project configuration (mypy, black, ruff, pytest)
- `pytest.ini` - pytest-specific configuration (markers, coverage)
- `.kiro/steering/coding-standards.md` - Detailed coding patterns
- `.kiro/steering/testing-configuration.md` - Test execution details
- `.kiro/steering/performance-monitoring.md` - Performance metrics and tracking
- `.kiro/steering/ai-integration.md` - API cost optimization

---

**Last Updated:** 2025-12-10
**Python Version:** 3.11+
**Project Type:** CLI tool for video processing
