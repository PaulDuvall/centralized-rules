---
inclusion: fileMatch
fileMatchPattern: '**/test_*.py'
---

# ⚙️ Testing: Configuration and Execution

> **Purpose:** Configure pytest, run tests, check coverage, and integrate with CI/CD
>
> **When to use:** Setting up testing infrastructure, running test suites, debugging test failures
>
> **See also:** [testing-overview.md](./testing-overview.md)

## pytest Configuration

### Option 1: pytest.ini

Create `pytest.ini` in project root:

```ini
[pytest]
# Test discovery
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*

# Output options
addopts =
    -v
    --strict-markers
    --tb=short
    --cov=src
    --cov-report=term-missing
    --cov-report=html
    --cov-fail-under=80

# Markers for test categorization
markers =
    unit: Unit tests (fast, mocked dependencies)
    integration: Integration tests (may use real I/O)
    slow: Slow tests (video processing, real APIs)
    expensive: Tests that make real API calls (cost money)
    requires_api_key: Tests requiring API keys

# Ignore patterns
norecursedirs = .git .tox venv .eggs build dist

[coverage:run]
source = src
omit =
    */tests/*
    */conftest.py
    */__pycache__/*
    */venv/*

[coverage:report]
exclude_lines =
    pragma: no cover
    def __repr__
    raise AssertionError
    raise NotImplementedError
    if __name__ == .__main__.:
    if TYPE_CHECKING:
```

### Option 2: pyproject.toml

Or configure in `pyproject.toml`:

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]

addopts = [
    "-v",
    "--strict-markers",
    "--tb=short",
    "--cov=src",
    "--cov-report=term-missing",
    "--cov-report=html",
    "--cov-fail-under=80",
]

markers = [
    "unit: Unit tests (fast, mocked dependencies)",
    "integration: Integration tests (may use real I/O)",
    "slow: Slow tests (video processing, real APIs)",
    "expensive: Tests that make real API calls (cost money)",
    "requires_api_key: Tests requiring API keys",
]

norecursedirs = [".git", ".tox", "venv", ".eggs", "build", "dist"]

[tool.coverage.run]
source = ["src"]
omit = ["*/tests/*", "*/conftest.py", "*/__pycache__/*", "*/venv/*"]

[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",
    "def __repr__",
    "raise AssertionError",
    "raise NotImplementedError",
    "if __name__ == .__main__.:",
    "if TYPE_CHECKING:",
]
```

---

## Test Markers

### Marking Tests

```python
import pytest

@pytest.mark.unit
def test_pronunciation_rule():
    """Fast unit test."""
    pass

@pytest.mark.integration
def test_phase1_with_real_ffmpeg(minimal_test_video):
    """Integration test using real FFmpeg."""
    pass

@pytest.mark.slow
@pytest.mark.integration
def test_full_video_rendering(minimal_test_video):
    """Slow integration test."""
    pass

@pytest.mark.expensive
@pytest.mark.skipif(not os.getenv("OPENAI_API_KEY"), reason="No API key")
def test_real_whisper_transcription(minimal_test_audio):
    """Expensive test making real API calls."""
    pass
```

### Running Specific Markers

```bash
# Run only unit tests (fast)
pytest -m unit

# Run integration tests
pytest -m integration

# Skip slow tests
pytest -m "not slow"

# Skip expensive tests
pytest -m "not expensive"

# Run only tests that don't need API keys
pytest -m "not requires_api_key"
```

---

## Running Tests

### Basic Commands

```bash
# Run all tests
pytest

# Run with verbose output
pytest -v

# Run specific test file
pytest tests/test_pronunciation.py

# Run specific test class
pytest tests/test_pronunciation.py::TestPronunciationDictionary

# Run specific test function
pytest tests/test_pronunciation.py::test_case_insensitive

# Run tests matching pattern
pytest -k "pronunciation"

# Run tests matching multiple patterns
pytest -k "pronunciation or voice"
```

### Output Control

```bash
# Show print statements (disable output capture)
pytest -s

# Short traceback format
pytest --tb=short

# No traceback (only test results)
pytest --tb=no

# Show local variables in traceback
pytest -l

# Stop on first failure
pytest -x

# Stop after N failures
pytest --maxfail=3
```

### Parallel Execution

```bash
# Install pytest-xdist
pip install pytest-xdist

# Run tests in parallel (auto detect CPU cores)
pytest -n auto

# Run tests on 4 cores
pytest -n 4

# Useful for large test suites
pytest -n auto -m "not slow"
```

---

## Coverage Checking

### Running with Coverage

```bash
# Run tests with coverage report
pytest --cov=src

# Show missing lines
pytest --cov=src --cov-report=term-missing

# Generate HTML coverage report
pytest --cov=src --cov-report=html

# Open HTML report in browser
open htmlcov/index.html

# Fail if coverage below 80%
pytest --cov=src --cov-fail-under=80
```

### Coverage Reports

**Terminal output:**
```bash
pytest --cov=src --cov-report=term-missing

# Output:
# Name                       Stmts   Miss  Cover   Missing
# --------------------------------------------------------
# src/phase1_ingest.py         142     12    92%   45-47, 89-91
# src/phase2_director.py       198     15    92%   156-160, 234-238
# src/phase3_voice.py          125      8    94%   78-82
# src/phase4_assembly.py       256     28    89%   145-152, 234-245
# --------------------------------------------------------
# TOTAL                        721     63    91%
```

**HTML report:**
```bash
pytest --cov=src --cov-report=html
# Opens browser with detailed line-by-line coverage
```

### Coverage Configuration

**Exclude specific code from coverage:**

```python
# Exclude debug code
if DEBUG:  # pragma: no cover
    print("Debug info")

# Exclude abstract methods
def abstract_method(self):
    raise NotImplementedError  # Automatically excluded

# Exclude type checking blocks
if TYPE_CHECKING:  # Automatically excluded
    from typing import Optional
```

---

## CI/CD Integration

### GitHub Actions

Create `.github/workflows/test.yml`:

```yaml
name: Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        python-version: ["3.11", "3.12"]

    steps:
    - uses: actions/checkout@v3

    - name: Set up Python ${{ matrix.python-version }}
      uses: actions/setup-python@v4
      with:
        python-version: ${{ matrix.python-version }}

    - name: Install FFmpeg
      run: |
        sudo apt-get update
        sudo apt-get install -y ffmpeg

    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
        pip install pytest pytest-cov

    - name: Run tests
      run: |
        pytest --cov=src --cov-report=xml --cov-report=term-missing

    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.xml
        fail_ci_if_error: true

    - name: Check coverage threshold
      run: |
        pytest --cov=src --cov-fail-under=80
```

### Skip Tests in CI Without API Keys

```yaml
# In GitHub Actions workflow
- name: Run tests (skip expensive tests)
  run: |
    pytest -m "not expensive"
  env:
    # Don't set API keys for regular CI runs
    CI: true

- name: Run integration tests (with API keys)
  if: github.event_name == 'schedule'  # Only on scheduled runs
  run: |
    pytest -m integration
  env:
    OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
    ELEVENLABS_API_KEY: ${{ secrets.ELEVENLABS_API_KEY }}
```

### Pre-commit Hooks

Create `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: local
    hooks:
      - id: pytest-check
        name: pytest-check
        entry: pytest
        args: ["-m", "unit", "--tb=short"]
        language: system
        pass_filenames: false
        always_run: true

      - id: pytest-coverage
        name: pytest-coverage
        entry: pytest
        args: ["--cov=src", "--cov-fail-under=80", "--tb=no"]
        language: system
        pass_filenames: false
        stages: [push]
```

Install hooks:
```bash
pip install pre-commit
pre-commit install
```

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
- ❌ Configuration errors (like module import issues)

### Acceptable Exceptions:

- ✅ Tests marked as `skip` or `xfail` (intentionally not run)
- ✅ Integration tests skipped due to missing API keys (if documented with `@pytest.mark.skipif`)
- ✅ Tests that pass with warnings (but still pass)

### Example: Correct Workflow

```
Task 1: Implement feature X
  ├─ Write code ✅
  ├─ Write tests ✅
  ├─ Run tests ❌ FAILED
  ├─ Fix code ✅
  ├─ Run tests ✅ PASSED
  └─ Mark task complete ✅

Task 2: Can now proceed ✅
```

### Example: WRONG Workflow

```
Task 1: Implement feature X
  ├─ Write code ✅
  ├─ Write tests ✅
  ├─ Run tests ❌ FAILED
  └─ Mark task complete ❌ WRONG! Tests are failing!

Task 2: Start next task ❌ WRONG! Previous task not complete!
```

### Reporting Status:

When reporting completion:
- ✅ "Task complete - all tests passing (91% coverage)"
- ❌ "Task complete" (when tests are failing)
- ✅ "Task in progress - fixing test failures in phase2_director.py"
- ✅ "Tests failing due to mock setup issue, investigating..."

### Why This Matters:

- Failing tests indicate broken functionality
- Moving forward with broken code compounds problems
- CI/CD will block deployment anyway
- Wastes time debugging later
- Violates the "fail-fast" principle
- Breaks trust in the codebase

**Remember:** "Working" means "all tests pass", not "code compiles".

---

## Debugging Test Failures

### Common Issues and Solutions

**Import errors:**
```bash
# Ensure src/ is in PYTHONPATH
export PYTHONPATH="${PYTHONPATH}:${PWD}"
pytest

# Or install in editable mode
pip install -e .
pytest
```

**Fixture not found:**
```bash
# Ensure conftest.py is in tests/ directory
# Fixture names must match exactly (case-sensitive)
```

**Mock not working:**
```python
# Check the patch path matches where it's imported, not defined
# Wrong:
@patch('whisper.load_model')  # Where it's defined

# Right:
@patch('src.phase1_ingest.whisper.load_model')  # Where it's imported
```

**Test passes locally but fails in CI:**
```bash
# Common causes:
# - Different Python version
# - Missing system dependency (FFmpeg)
# - Different working directory
# - Missing environment variable
```

### Verbose Debugging

```bash
# Maximum verbosity
pytest -vv -s -l --tb=long

# Show all warnings
pytest -v -W all

# Run in debug mode (drop into pdb on failure)
pytest --pdb

# Show test duration
pytest --durations=10
```

---

## Quick Reference

### Common Test Commands

```bash
# Fast unit tests only
pytest -m unit

# All tests with coverage
pytest --cov=src --cov-report=html

# Skip slow and expensive tests
pytest -m "not slow and not expensive"

# Run specific test
pytest tests/test_pronunciation.py::test_case_insensitive -v

# Stop on first failure, show output
pytest -x -s

# Parallel execution (fast)
pytest -n auto -m "not slow"

# Generate coverage report
pytest --cov=src --cov-report=html && open htmlcov/index.html
```

### Coverage Targets

- **Overall project:** 80% minimum (enforced)
- **Pronunciation rules:** 100%
- **Manifest validation:** 100%
- **Phase logic:** 80-90%
- **CLI formatting:** 60-70% (acceptable)

---

## References

- **pytest documentation**: https://docs.pytest.org
- **pytest-cov documentation**: https://pytest-cov.readthedocs.io
- **Coverage.py**: https://coverage.readthedocs.io
- **Related guides**: [testing-overview.md](./testing-overview.md), [cicd-workflow.md](./cicd-workflow.md)

---

**Last Updated:** 2025-12-10
**Python Version:** 3.11+
**Required:** pytest >= 7.0, pytest-cov >= 4.0
