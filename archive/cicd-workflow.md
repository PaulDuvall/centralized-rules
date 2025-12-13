# 🚦 CI/CD Workflow Guidelines

> **Icon:** 🚦 Used when checking CI/CD status, fixing workflows, or monitoring deployments
>
> **📋 Related:** [testing-overview.md](./testing-overview.md) - Testing requirements
>
> This document defines mandatory CI/CD practices to maintain a healthy deployment pipeline.

## ⚠️ CRITICAL RULE: Never Leave CI/CD in Failed State

**MANDATORY:** GitHub Actions workflows must NEVER remain in a failed state. A failing CI/CD pipeline blocks deployments and indicates broken code.

### The Rule:

- ✅ CI/CD must pass before moving to new tasks
- ✅ Failing workflows must be fixed immediately
- ✅ All tests must pass in CI/CD environment
- ✅ No commits should be pushed that break CI/CD

### Required Actions When CI/CD Fails:

1. **STOP IMMEDIATELY** - Do not proceed to other tasks
2. **INVESTIGATE** - Check the workflow logs to identify the failure
3. **FIX THE ROOT CAUSE** - Address the actual issue, not just symptoms
4. **VERIFY LOCALLY** - Run the same commands locally to confirm fix
5. **PUSH FIX** - Commit and push the fix
6. **MONITOR** - Watch the workflow run to ensure it passes
7. **ONLY THEN** - Proceed to the next task

### What Counts as "Failed CI/CD":

- ❌ Any job with status "failed" (red X)
- ❌ Tests that fail in CI but pass locally
- ❌ Build failures
- ❌ Lint or type-check errors
- ❌ Deployment failures
- ❌ Timeout errors in tests or builds

### Acceptable Exceptions:

- ✅ Workflows that are "skipped" (intentionally not run)
- ✅ Workflows marked as "cancelled" (manually stopped)
- ✅ Preview deployments that fail due to missing secrets (if documented)

### Common CI/CD Failure Causes:

1. **Test Timeouts**
   - Property-based tests with too many iterations
   - Integration tests that are too slow
   - Missing timeout configuration
   - **Fix:** Reduce iterations, increase timeout, optimize tests

2. **Environment Differences**
   - Tests pass locally but fail in CI
   - Missing environment variables
   - Different Node.js versions
   - **Fix:** Match local environment to CI, add missing env vars

3. **Flaky Tests**
   - Tests that pass/fail randomly
   - Race conditions in async code
   - Time-dependent tests
   - **Fix:** Add proper waits, mock time, fix race conditions

4. **Build Errors**
   - TypeScript compilation errors
   - Missing dependencies
   - Import/export issues
   - **Fix:** Run `npm run build` locally, fix errors

5. **Lint/Type Errors**
   - Code style violations
   - Type safety issues
   - Unused imports
   - **Fix:** Run `npm run lint` and `npm run type-check` locally

### Example Workflow:

```
✅ Good Workflow:
Task 1: Implement feature X
  ├─ Write code ✅
  ├─ Write tests ✅
  ├─ Run tests locally ✅ PASSED
  ├─ Commit and push ✅
  ├─ CI/CD runs ✅ PASSED
  └─ Mark task complete ✅

Task 2: Can now proceed ✅
```

```
❌ Bad Workflow:
Task 1: Implement feature X
  ├─ Write code ✅
  ├─ Write tests ✅
  ├─ Run tests locally ✅ PASSED
  ├─ Commit and push ✅
  ├─ CI/CD runs ❌ FAILED (tests timeout)
  └─ Mark task complete ❌ WRONG! CI/CD is broken!

Task 2: Start next task ❌ WRONG! Must fix CI/CD first!
```

```
✅ Correct Response to Failure:
Task 1: Implement feature X
  ├─ Write code ✅
  ├─ Write tests ✅
  ├─ Run tests locally ✅ PASSED
  ├─ Commit and push ✅
  ├─ CI/CD runs ❌ FAILED (tests timeout)
  ├─ STOP - Investigate failure ✅
  ├─ Fix: Reduce test iterations ✅
  ├─ Run tests locally ✅ PASSED (faster)
  ├─ Commit and push fix ✅
  ├─ CI/CD runs ✅ PASSED
  └─ Mark task complete ✅

Task 2: Can now proceed ✅
```

### Monitoring CI/CD Status:

Check workflow status regularly:
```bash
# View recent workflow runs
gh run list --limit 5

# View specific run details
gh run view <run-id>

# View failed run logs
gh run view <run-id> --log-failed

# Watch current run
gh run watch
```

### Preventing CI/CD Failures:

**Before Pushing:**
1. Run all tests locally: `npm test -- --run`
2. Run type checking: `npm run type-check`
3. Run linting: `npm run lint`
4. Build the project: `npm run build`
5. Check for diagnostics: Use `getDiagnostics` tool

**After Pushing:**
1. Monitor the workflow run
2. Check for any failures immediately
3. Fix failures before moving to next task

### Reporting Status:

When reporting completion:
- ✅ "Task complete - all tests passing, CI/CD green"
- ❌ "Task complete" (when CI/CD is failing)
- ✅ "Task in progress - fixing CI/CD failures"
- ✅ "CI/CD failing due to [specific issue], working on fix"

### Why This Matters:

- **Blocks Deployments** - Failed CI/CD prevents production releases
- **Indicates Broken Code** - Failures mean something is wrong
- **Compounds Problems** - Moving forward with broken CI/CD makes debugging harder
- **Team Impact** - Other developers can't deploy their work
- **Trust** - A green CI/CD pipeline means the codebase is healthy

### Integration with Other Rules:

This rule works together with:
- [testing-overview.md](./testing-overview.md) - Tests must pass locally AND in CI
- [refactoring-workflow.md](./refactoring-workflow.md) - Refactored code must pass CI/CD
- [git-workflow.md](./git-workflow.md) - Don't push code that breaks CI/CD

## CI/CD Configuration

### Test Timeout Configuration

Property-based tests require longer timeouts due to multiple iterations:

```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    testTimeout: 30000, // 30 seconds for property tests
  },
});
```

### Property Test Iterations

Balance between coverage and speed:
- **Local Development:** 10 iterations (fast feedback)
- **CI/CD:** 10 iterations (prevent timeouts)
- **Pre-Release:** Consider 100 iterations (thorough testing)

```typescript
// Property test configuration
fc.assert(
  fc.property(/* ... */),
  { numRuns: 10 } // Optimized for CI/CD
);
```

### GitHub Actions Best Practices

1. **Use Caching** - Cache node_modules for faster builds
2. **Parallel Jobs** - Run tests, lint, and build in parallel
3. **Fail Fast** - Stop on first failure to save time
4. **Timeout Limits** - Set reasonable timeouts for all jobs
5. **Required Checks** - Mark critical jobs as required for merge

---

## Video Processing-Specific CI/CD Guidance

### Challenges with Video Processing in CI

Video processing introduces unique CI/CD challenges:

1. **Large File Sizes** - Video files are too large for git/artifacts
2. **Long Processing Times** - Full pipeline can take 15+ minutes
3. **Resource Intensive** - Rendering requires significant CPU/memory
4. **External Dependencies** - FFmpeg, Whisper models, API keys
5. **Non-Deterministic Outputs** - LLM/TTS outputs vary

### CI/CD Strategy for Video Projects

**Don't test full video processing in CI.** Instead:

✅ **Test logic and structure** (unit tests with mocks)
✅ **Test with minimal fixtures** (1-second test videos)
✅ **Test manifest validation** (JSON structure, no rendering)
✅ **Skip expensive API calls** (mark with `@pytest.mark.skipif`)
✅ **Smoke test imports** (ensure code loads without errors)

❌ **Don't process real videos** in CI
❌ **Don't make real API calls** (unless necessary for integration tests)
❌ **Don't render long videos** (too slow, too resource-intensive)

---

### GitHub Actions Workflow for Video Processing

**Recommended workflow** (`.github/workflows/test.yml`):

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
    timeout-minutes: 15  # Prevent runaway tests

    strategy:
      matrix:
        python-version: ["3.11", "3.12"]

    steps:
    - uses: actions/checkout@v3

    - name: Set up Python ${{ matrix.python-version }}
      uses: actions/setup-python@v4
      with:
        python-version: ${{ matrix.python-version }}

    - name: Cache dependencies
      uses: actions/cache@v3
      with:
        path: |
          ~/.cache/pip
          venv
        key: ${{ runner.os }}-pip-${{ hashFiles('requirements.txt') }}
        restore-keys: |
          ${{ runner.os }}-pip-

    - name: Install system dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y ffmpeg

    - name: Install Python dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
        pip install pytest pytest-cov ruff black mypy

    - name: Lint with ruff
      run: ruff check src/

    - name: Format check with black
      run: black --check src/

    - name: Type check with mypy
      run: mypy src/ --ignore-missing-imports

    - name: Run unit tests (fast, mocked)
      run: |
        pytest tests/ -m "unit" --cov=src --cov-report=xml --cov-report=term-missing -v

    - name: Run integration tests (skip expensive)
      run: |
        pytest tests/ -m "integration and not expensive" --cov=src --cov-append --cov-report=xml -v
      env:
        CI: true

    - name: Check coverage threshold
      run: |
        pytest --cov=src --cov-fail-under=80 --cov-report=term

    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      if: matrix.python-version == '3.11'  # Only upload once
      with:
        file: ./coverage.xml
        fail_ci_if_error: false  # Don't fail on upload errors

  smoke-test:
    runs-on: ubuntu-latest
    timeout-minutes: 5

    steps:
    - uses: actions/checkout@v3

    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: "3.11"

    - name: Install dependencies
      run: |
        pip install -r requirements.txt

    - name: Smoke test - Import all modules
      run: |
        python -c "from src.pipeline import ScreencastOptimizer"
        python -c "from src.phase1_ingest import Phase1Processor"
        python -c "from src.phase2_director import DirectorAgent"
        python -c "from src.phase3_voice import VoiceGenerator"
        python -c "from src.phase4_assembly import VideoAssembler"

    - name: Smoke test - CLI loads
      run: |
        python -m src.cli --help
```

---

### Handling Large Video Files

**Problem:** Videos are too large for git, CI artifacts, or quick testing.

**Solutions:**

#### 1. Generate Test Videos in CI

```yaml
- name: Generate minimal test video
  run: |
    ffmpeg -f lavfi -i testsrc=duration=1:size=1920x1080:rate=30 \
           -f lavfi -i sine=frequency=440:duration=1 \
           -c:v libx264 -preset ultrafast -c:a aac -t 1 \
           tests/fixtures/test_1sec.mp4
```

#### 2. Use Cached Test Fixtures

```yaml
- name: Cache test fixtures
  uses: actions/cache@v3
  with:
    path: tests/fixtures/
    key: test-fixtures-v1
```

#### 3. Skip Video Processing Tests

```python
# tests/test_phase4_assembly.py
import pytest
import os

@pytest.mark.skipif(
    os.getenv("CI") == "true",
    reason="Skip full video rendering in CI (too slow)"
)
def test_full_video_rendering(test_video):
    """Full rendering test - only runs locally."""
    pass
```

---

### Caching Strategies

**Cache FFmpeg/System Dependencies:**

```yaml
- name: Cache FFmpeg
  uses: actions/cache@v3
  with:
    path: /usr/bin/ffmpeg
    key: ffmpeg-${{ runner.os }}
```

**Cache Python Dependencies:**

```yaml
- name: Cache pip packages
  uses: actions/cache@v3
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('requirements.txt') }}
```

**Cache Whisper Models (if needed):**

```yaml
- name: Cache Whisper models
  uses: actions/cache@v3
  with:
    path: ~/.cache/whisper
    key: whisper-models-base
```

---

### Test Markers for CI/CD

**Configure pytest markers** for CI-friendly testing:

```ini
# pytest.ini
[pytest]
markers =
    unit: Fast unit tests with mocked dependencies
    integration: Integration tests (may use FFmpeg)
    slow: Slow tests (> 10 seconds)
    expensive: Tests requiring API keys and costing money
    ci: Tests safe to run in CI
```

**Use in tests:**

```python
import pytest

@pytest.mark.unit
@pytest.mark.ci
def test_pronunciation_logic():
    """Fast, safe for CI."""
    pass

@pytest.mark.integration
def test_phase1_with_real_ffmpeg():
    """Uses real FFmpeg, but with 1-sec video."""
    pass

@pytest.mark.expensive
@pytest.mark.skipif(not os.getenv("OPENAI_API_KEY"), reason="No API key")
def test_real_whisper_api():
    """Skip in CI - costs money."""
    pass
```

**Run in CI:**

```yaml
- name: Run CI-safe tests
  run: pytest -m "ci or (integration and not expensive)"
```

---

### Handling API Keys in CI

**Never commit API keys.** Use GitHub Secrets:

```yaml
env:
  OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
  ELEVENLABS_API_KEY: ${{ secrets.ELEVENLABS_API_KEY }}
```

**Skip tests requiring keys:**

```python
@pytest.mark.skipif(
    not os.getenv("OPENAI_API_KEY"),
    reason="No OpenAI API key - skipping integration test"
)
def test_real_transcription():
    pass
```

**Optional: Run expensive tests on schedule:**

```yaml
# .github/workflows/integration.yml
name: Integration Tests

on:
  schedule:
    - cron: '0 2 * * 0'  # Weekly on Sunday at 2 AM

jobs:
  integration:
    runs-on: ubuntu-latest
    steps:
      - name: Run expensive integration tests
        run: pytest -m expensive
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
          ELEVENLABS_API_KEY: ${{ secrets.ELEVENLABS_API_KEY }}
```

---

### Pre-commit Hooks

**Install pre-commit hooks** to catch issues before CI:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: ruff
        name: ruff
        entry: ruff check --fix
        language: system
        types: [python]

      - id: black
        name: black
        entry: black
        language: system
        types: [python]

      - id: mypy
        name: mypy
        entry: mypy
        language: system
        types: [python]
        pass_filenames: false
        args: [src/, --ignore-missing-imports]

      - id: pytest-quick
        name: pytest-quick
        entry: pytest
        language: system
        pass_filenames: false
        args: [-m, unit, --tb=short]
```

**Install:**

```bash
pip install pre-commit
pre-commit install
```

---

### Deployment Considerations

**This project doesn't deploy traditionally** (it's a CLI tool), but if distributing:

#### PyPI Package Publishing

```yaml
# .github/workflows/publish.yml
name: Publish to PyPI

on:
  release:
    types: [published]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: "3.11"
      - name: Install dependencies
        run: |
          pip install build twine
      - name: Build package
        run: python -m build
      - name: Publish to PyPI
        env:
          TWINE_USERNAME: __token__
          TWINE_PASSWORD: ${{ secrets.PYPI_TOKEN }}
        run: twine upload dist/*
```

#### Docker Image Publishing

```yaml
# .github/workflows/docker.yml
name: Build Docker Image

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]

jobs:
  docker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build Docker image
        run: docker build -t screencast-optimizer .
      - name: Test Docker image
        run: docker run screencast-optimizer --help
```

---

### Performance Testing in CI

**Track performance regressions:**

```yaml
- name: Benchmark tests
  run: |
    pytest tests/benchmarks/ --benchmark-only

- name: Check for performance regression
  run: |
    python scripts/check_performance.py baseline.json current.json
```

---

### Common CI/CD Issues for Video Projects

#### Issue 1: FFmpeg Not Found

```yaml
# Solution: Install FFmpeg in CI
- name: Install FFmpeg
  run: |
    sudo apt-get update
    sudo apt-get install -y ffmpeg
```

#### Issue 2: Test Video Generation Fails

```python
# Solution: Check FFmpeg is available before generating
def create_test_video():
    if not shutil.which("ffmpeg"):
        pytest.skip("FFmpeg not available")
    # Generate video...
```

#### Issue 3: Tests Timeout

```yaml
# Solution: Set reasonable timeouts
jobs:
  test:
    timeout-minutes: 15  # Prevent hanging tests
```

#### Issue 4: Out of Disk Space

```yaml
# Solution: Clean up after tests
- name: Clean up test artifacts
  if: always()
  run: |
    rm -rf tests/fixtures/*.mp4
    rm -rf output/
```

#### Issue 5: Inconsistent Test Results

```python
# Solution: Use deterministic test data
@pytest.fixture
def deterministic_transcript():
    """Return same transcript every time."""
    return [
        {"start": 0.0, "end": 5.0, "text": "Fixed text"}
    ]
```

---

## Summary

**The Golden Rule:** Green CI/CD is non-negotiable. Fix failures immediately before proceeding.

**Video Processing Addendum:** Test logic, not videos. Use minimal fixtures, mock external APIs, and skip expensive operations in CI.

A healthy CI/CD pipeline is the foundation of reliable software delivery. Never compromise on this.

---

## References

- **Testing configuration**: [testing-configuration.md](./testing-configuration.md) - pytest markers, CI integration
- **Performance monitoring**: [performance-monitoring.md](./performance-monitoring.md) - Track CI/CD performance
- **Testing mocking**: [testing-mocking.md](./testing-mocking.md) - Mock expensive video operations
- **Security**: [security.md](./security.md) - API key management in CI

---

**Last Updated:** 2025-12-10
**Python Version:** 3.11+
**CI/CD Platform:** GitHub Actions (examples adaptable to other platforms)
