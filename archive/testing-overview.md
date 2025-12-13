---
inclusion: fileMatch
fileMatchPattern: '**/test_*.py'
---

# 🧪 Testing Overview

> **Icon:** 🧪 Used when running tests, checking coverage, or writing tests
>
> **📋 Related:** pytest, pytest-cov, hypothesis
>
> This is the **entry point** for testing guidance in the screencast optimizer project.

## Quick Navigation

**Need specific testing guidance? Read the appropriate file:**

| What do you need? | Read this file |
|-------------------|----------------|
| How to mock FFmpeg, MoviePy, Whisper, LLMs, TTS | [testing-mocking.md](./testing-mocking.md) |
| How to test Phase 1-4 pipeline components | [testing-pipeline.md](./testing-pipeline.md) |
| How to create test videos, audio, fixtures | [testing-fixtures.md](./testing-fixtures.md) |
| How to configure pytest, run tests, CI/CD | [testing-configuration.md](./testing-configuration.md) |

**Start here if you're new to the testing approach, then navigate to specific docs as needed.**

---

## Testing Philosophy

All code must be thoroughly tested with a **minimum of 80% coverage**.

### What We Test

- ✅ **Happy paths** - Normal successful execution
- ✅ **Edge cases** - Empty input, None values, boundary conditions
- ✅ **Error cases** - Invalid input, exceptions, subprocess failures
- ✅ **File operations** - Video/audio file handling, manifest I/O
- ✅ **External API calls** - Whisper, GPT-4, ElevenLabs (mocked)
- ✅ **FFmpeg operations** - Video processing, encoding (mocked or with fixtures)

### Coverage Goals

- **Minimum 80% overall coverage** (enforced with pytest-cov)
- 100% coverage for pronunciation rules logic
- 100% coverage for manifest validation
- Lower coverage acceptable for CLI output formatting
- Video rendering can use integration tests instead of full unit coverage

**Why:** High coverage catches regressions and ensures code quality, but 100% everywhere is impractical for video processing.

---

## Test Framework

### pytest

- Primary test framework for unit and integration tests
- Use `pytest --verbose` for detailed output
- Configure in `pyproject.toml` or `pytest.ini`

### Test Structure Pattern

```python
import pytest
from pathlib import Path
from src.phase1_ingest import Phase1Processor

class TestPhase1Processor:
    """Test Phase 1 audio extraction and transcription."""

    @pytest.fixture
    def sample_video(self, tmp_path: Path) -> Path:
        """Create a sample video file for testing."""
        video_path = tmp_path / "sample.mp4"
        # ... create minimal valid video ...
        return video_path

    @pytest.fixture(autouse=True)
    def setup_and_teardown(self):
        """Setup before and teardown after each test."""
        # Setup
        yield
        # Teardown

    def test_extract_audio_success(self, sample_video: Path):
        """Test successful audio extraction from video."""
        # Arrange
        processor = Phase1Processor()

        # Act
        audio_path = processor.extract_audio(sample_video)

        # Assert
        assert audio_path.exists()
        assert audio_path.suffix == '.wav'
```

---

## Test Types

### Unit Tests

- Test individual functions in isolation
- Mock external dependencies (FFmpeg, API calls)
- Fast execution (< 100ms per test)
- Located in `tests/` directory with `test_*.py` naming

**When to use:** Testing pure logic, individual functions, data transformations

### Integration Tests

- Test complete phase workflows (e.g., Phase 1 end-to-end)
- Use test fixtures (small sample videos)
- May make real API calls (skipped if no API key)
- Located in `tests/` with `test_integration_*.py` naming

**When to use:** Testing phase interactions, end-to-end pipeline, real FFmpeg operations

### Property-Based Tests

- Test universal properties across many inputs
- Use `hypothesis` library for Python
- Minimum 100 iterations per property (configurable)
- Useful for testing pronunciation rules, manifest validation

**Example with hypothesis:**
```python
from hypothesis import given, strategies as st

@given(st.text())
def test_pronunciation_preserves_length_approximately(text: str):
    """Test that pronunciation changes don't drastically alter text length."""
    pd = PronunciationDictionary()
    result = pd.apply(text)
    # Allow up to 50% length change for phonetic replacements
    assert len(result) <= len(text) * 1.5
```

**When to use:** Testing invariants, edge cases with many random inputs, pronunciation rules

---

## Test Organization

### Directory Structure

```
tests/
├── conftest.py              # Shared fixtures for all tests
├── fixtures/                # Static test media files
│   ├── sample_1sec.mp4
│   └── sample_5sec.mp4
├── test_pronunciation.py    # Existing pronunciation tests (reference example)
├── test_phase1_ingest.py    # Phase 1 tests
├── test_phase2_director.py  # Phase 2 tests
├── test_phase3_voice.py     # Phase 3 tests
├── test_phase4_assembly.py  # Phase 4 tests
└── test_integration.py      # End-to-end pipeline tests
```

### Test Naming

- Use `test_` prefix (required by pytest)
- Include the condition being tested
- Be specific about expected outcome
- Use underscores for readability

**Examples:**
- ✅ `test_pronunciation_replaces_router_with_rau_ter`
- ✅ `test_ffmpeg_extraction_fails_with_invalid_file`
- ✅ `test_manifest_validation_rejects_missing_actions`
- ✅ `test_case_insensitive_trigger` (from test_pronunciation.py)
- ❌ `test_function` (too vague)
- ❌ `test_it_works` (not descriptive)

---

## Common Test Workflows

### Writing a New Test

1. **Identify what to test** - Function, class method, or workflow
2. **Choose test type** - Unit (mocked) or integration (real operations)
3. **Read relevant doc**:
   - Need mocks? → [testing-mocking.md](./testing-mocking.md)
   - Testing a phase? → [testing-pipeline.md](./testing-pipeline.md)
   - Need fixtures? → [testing-fixtures.md](./testing-fixtures.md)
4. **Write test** following patterns from reference docs
5. **Run test** - `pytest tests/test_your_file.py -v`
6. **Check coverage** - `pytest --cov=src --cov-report=term-missing`

### Running Tests

```bash
# Run all tests
pytest

# Run specific test file
pytest tests/test_pronunciation.py

# Run tests matching pattern
pytest -k "pronunciation"

# Run with coverage
pytest --cov=src --cov-report=html
```

**See [testing-configuration.md](./testing-configuration.md) for complete pytest commands.**

### Debugging Failing Tests

1. **Read the error output** - pytest provides detailed tracebacks
2. **Run single test** - `pytest tests/test_file.py::test_specific_test -v`
3. **Add print statements** or use `pytest --capture=no` to see stdout
4. **Check mocks** - Verify mock setup matches what code expects
5. **Verify fixtures** - Ensure test data is valid

---

## ⚠️ CRITICAL RULE: Never Proceed with Failing Tests

**MANDATORY:** You must NEVER move to the next task, mark a task as complete, or claim work is finished if ANY tests are failing.

### Required Actions When Tests Fail:

1. **STOP IMMEDIATELY** - Do not proceed to other tasks
2. **INVESTIGATE** - Read the test failure output carefully
3. **FIX THE ROOT CAUSE** - Don't just make tests pass, fix the actual issue
4. **VERIFY** - Run tests again to confirm they pass
5. **ONLY THEN** - Proceed to the next task

### What Counts as "Failing Tests":

- ❌ Any test with status "failed"
- ❌ Tests that error during execution
- ❌ Tests that timeout
- ❌ Coverage below minimum threshold (80%)
- ❌ Build/compilation errors that prevent tests from running

### Acceptable Exceptions:

- ✅ Tests marked as `skip` or `todo` (intentionally not run)
- ✅ Integration tests skipped due to missing API keys (if documented)
- ✅ Tests that pass with warnings (but still pass)

**Remember:** "Working" means "all tests pass", not "code compiles".

---

## Quick Reference

### Test Checklist

When writing tests for video processing code:

- [ ] **Mock external dependencies** (Whisper, GPT-4, ElevenLabs, FFmpeg subprocess)
- [ ] **Use minimal test videos** (1-5 seconds, generated with FFmpeg)
- [ ] **Test both unit and integration** levels (fast unit tests, slower integration)
- [ ] **Skip expensive tests** when API keys unavailable (`@pytest.mark.skipif`)
- [ ] **Use pytest fixtures** for reusable test data (`conftest.py`)
- [ ] **Achieve 80%+ coverage** (enforced by CI)
- [ ] **Test all 4 phases** independently before end-to-end
- [ ] **Never proceed with failing tests** - fix immediately

### Next Steps

Choose the appropriate guide for your current task:

- **Mocking external dependencies?** → [testing-mocking.md](./testing-mocking.md)
- **Testing pipeline phases?** → [testing-pipeline.md](./testing-pipeline.md)
- **Creating test fixtures?** → [testing-fixtures.md](./testing-fixtures.md)
- **Configuring pytest or CI/CD?** → [testing-configuration.md](./testing-configuration.md)

---

## References

**Testing Tools:**
- pytest - Test framework (https://pytest.org)
- pytest-cov - Coverage measurement (https://pytest-cov.readthedocs.io)
- hypothesis - Property-based testing (https://hypothesis.readthedocs.io)
- unittest.mock - Mocking and patching (Python standard library)

**Project Files:**
- `tests/test_pronunciation.py` - Example test patterns (reference implementation)
- `tests/conftest.py` - Shared fixtures (create this)
- `pytest.ini` or `pyproject.toml` - pytest configuration
- `tests/fixtures/` - Static test media files (create as needed)

**Related Guides:**
- [testing-mocking.md](./testing-mocking.md) - Mock external dependencies
- [testing-pipeline.md](./testing-pipeline.md) - Test 4-phase pipeline
- [testing-fixtures.md](./testing-fixtures.md) - Create test data
- [testing-configuration.md](./testing-configuration.md) - Configure and run tests

---

**Last Updated:** 2025-12-10
**Python Version:** 3.11+
**Key Dependencies:** pytest, pytest-cov, hypothesis, ffmpeg, moviepy
