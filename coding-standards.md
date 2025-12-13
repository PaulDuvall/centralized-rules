---
inclusion: fileMatch
fileMatchPattern: '**/*.py'
---

# 📐 Coding Standards

> **Icon:** 📐 Used when checking types, error handling, or code organization
>
> **📋 Related:** PEP 8, PEP 257 (docstrings), mypy type checking
>
> This document defines coding standards for Python code in the screencast optimizer project.

This project follows strict coding standards for consistency and quality.

## Python Standards

### Type Safety
- **All functions must have type hints** (severity: error) - Use Python 3.11+ type syntax
- **NO bare `Exception` catches** - Catch specific exception types
- Remove unused imports (severity: error) - Use ruff to detect
- Use mypy for static type checking in strict mode

**Why:** Type hints catch bugs early and improve code maintainability and IDE support.

### Code Structure

- **Maximum 20 lines per function** (severity: warning) - Break larger functions into smaller, focused ones
- **Maximum 300 lines per file** (severity: warning) - Split large files into modules
- **Single Responsibility Principle** - Each function/class should do one thing well
- Use meaningful variable and function names (PEP 8 naming conventions)
- Use docstrings for all public functions, classes, and modules (PEP 257)

**Example:**
```python
# ❌ Too long (>20 lines)
def process_video(video_path: str) -> dict:
    # 50 lines of validation, FFmpeg, audio extraction, AI calls...
    pass

# ✅ Broken into focused functions
def validate_video_path(video_path: str) -> Path:
    """Validate and return a Path object for the video file."""
    pass

def extract_audio(video_path: Path) -> Path:
    """Extract audio track from video file using FFmpeg."""
    pass

def transcribe_audio(audio_path: Path) -> list[dict]:
    """Transcribe audio using Whisper and return segments."""
    pass
```

### Error Handling

- **All functions that can fail must have error handling** (severity: error) - Use try/except blocks
- **Catch specific exceptions** - Avoid bare `except:` clauses
- Error messages must be descriptive and actionable (severity: warning)
- Include remediation guidance in error messages
- Use custom exception classes for domain-specific errors

**Example:**
```python
# ❌ Poor error handling
def extract_audio(video_path: Path) -> Path:
    result = subprocess.run(['ffmpeg', '-i', str(video_path), 'audio.wav'])
    return Path('audio.wav')

# ✅ Proper error handling with remediation
def extract_audio(video_path: Path) -> Path:
    """Extract audio from video file using FFmpeg.

    Args:
        video_path: Path to input video file

    Returns:
        Path to extracted audio file

    Raises:
        VideoProcessingError: If FFmpeg extraction fails
    """
    try:
        result = subprocess.run(
            ['ffmpeg', '-i', str(video_path), '-vn', 'audio.wav'],
            capture_output=True,
            check=True,
            timeout=300
        )
        return Path('audio.wav')
    except subprocess.CalledProcessError as e:
        raise VideoProcessingError(
            f"FFmpeg audio extraction failed: {e.stderr.decode()} | "
            f"Remediation: Check video file format and FFmpeg installation"
        ) from e
    except subprocess.TimeoutExpired:
        raise VideoProcessingError(
            "FFmpeg extraction timed out after 5 minutes | "
            "Remediation: Video file may be too large or corrupted"
        )
```

### Documentation
- Add docstrings for all public functions, classes, and modules (PEP 257)
- Use Google-style or NumPy-style docstrings for consistency
- Include `Args:`, `Returns:`, and `Raises:` sections
- Provide examples for complex functions using `Examples:` section
- Document edge cases and assumptions

**Example:**
```python
def calculate_video_duration(manifest: dict) -> float:
    """Calculate total duration from video manifest.

    Args:
        manifest: Video manifest dictionary with 'actions' key containing
                 edit actions with 'start_time' and 'end_time' fields.

    Returns:
        Total duration in seconds as a float.

    Raises:
        ValueError: If manifest is missing required fields.

    Examples:
        >>> manifest = {'actions': [{'start_time': 0.0, 'end_time': 10.5}]}
        >>> calculate_video_duration(manifest)
        10.5
    """
    pass
```

## Python CLI Conventions

### CLI Commands (Typer)
- Use Typer for CLI command structure
- Validate all input with proper error messages
- Use Rich for formatted console output
- Provide helpful `--help` text for all commands
- Use type hints for all command parameters

### Progress Reporting
- Use Rich progress bars for long-running operations
- Log to console with clear status messages
- Report phase completion (Phase 1/4, Phase 2/4, etc.)
- Show estimated time remaining when possible

## Security Standards

### Never Hardcode Secrets

- Use environment variables for all secrets (severity: error)
- Never commit API keys, passwords, or tokens to git
- Use `.env` file for local development (gitignored)
- Document required environment variables in `.env.example`
- Consider AWS SSM Parameter Store for production secrets

**Example:**
```python
# ❌ Hardcoded secret
OPENAI_API_KEY = 'sk-1234567890abcdef'

# ✅ Environment variable with validation
import os

OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')
if not OPENAI_API_KEY:
    raise ValueError(
        'OPENAI_API_KEY not set | '
        'Remediation: Add to .env file or set environment variable'
    )
```

### Input Validation

- Validate and sanitize all user input (severity: error)
- Use Path validation for file paths (Path.resolve, Path.exists)
- Validate video file formats before processing
- Sanitize filenames to prevent path traversal attacks

**Example:**
```python
from pathlib import Path

# ❌ No validation
def process_video(video_path: str) -> None:
    with open(video_path, 'rb') as f:
        # Process video...
        pass

# ✅ With validation
def process_video(video_path: str) -> None:
    """Process video file with path validation."""
    path = Path(video_path).resolve()

    # Validate file exists
    if not path.exists():
        raise FileNotFoundError(f"Video file not found: {path}")

    # Validate file is actually a file (not directory)
    if not path.is_file():
        raise ValueError(f"Path is not a file: {path}")

    # Validate file extension
    if path.suffix.lower() not in ['.mp4', '.mov', '.avi', '.mkv']:
        raise ValueError(f"Unsupported video format: {path.suffix}")

    with open(path, 'rb') as f:
        # Process video...
        pass
```

### Subprocess Security

- Use list arguments instead of shell=True (prevents command injection)
- Set timeouts for all subprocess operations
- Validate and sanitize paths before passing to subprocess
- Capture output instead of allowing unbuffered stdout/stderr

**Example:**
```python
# ❌ Unsafe shell execution
def convert_video(input_path: str, output_path: str) -> None:
    os.system(f'ffmpeg -i {input_path} {output_path}')  # Command injection risk!

# ✅ Safe subprocess execution
def convert_video(input_path: Path, output_path: Path) -> None:
    """Safely convert video using FFmpeg."""
    subprocess.run(
        ['ffmpeg', '-i', str(input_path), str(output_path)],
        capture_output=True,
        check=True,
        timeout=600,
        # shell=False is the default - never set shell=True!
    )
```

## Python Linting and Formatting

### Required Tools
- **ruff** - Fast Python linter (replaces flake8, isort, etc.)
- **black** - Code formatter for consistent style
- **mypy** - Static type checker

### Pre-commit Workflow
```bash
# Format code
black src/ tests/

# Lint code
ruff check src/ tests/

# Type check
mypy src/
```

### Configuration
- `pyproject.toml` - Central configuration for all tools
- `ruff.toml` or `[tool.ruff]` in pyproject.toml
- `[tool.black]` in pyproject.toml
- `[tool.mypy]` in pyproject.toml

## ⚠️ CRITICAL: Test-Driven Development Rule

**MANDATORY:** Never proceed to the next task or mark work as complete if tests are failing.

### The Rule:
- ✅ All tests must pass before moving forward
- ✅ All tests must pass before marking a task complete
- ✅ All tests must pass before claiming work is done

### What This Means:
- If you write code and tests fail → Fix the code
- If you refactor and tests fail → Fix the refactoring
- If you add a feature and tests fail → Fix the feature
- **Never** say "done" or "complete" with failing tests

### See Also:
- [testing-overview.md](./testing-overview.md) - Detailed testing rules and the "Never Proceed with Failing Tests" section

## References

**Python Style Guides:**
- PEP 8 - Python code style guide
- PEP 257 - Docstring conventions
- Google Python Style Guide - Additional best practices

**Project Documentation:**
- [ARCHITECTURE.md](../../docs/ARCHITECTURE.md) - 4-phase pipeline architecture
- [USAGE.md](../../docs/USAGE.md) - Usage examples and patterns

**Related Steering Files:**
- [testing-overview.md](./testing-overview.md) - Comprehensive testing guidelines
- [refactoring-workflow.md](./refactoring-workflow.md) - Mandatory refactoring workflow
- [metrics-and-limits.md](./metrics-and-limits.md) - Code quality thresholds
- [security.md](./security.md) - Security best practices
- [data-conventions.md](./data-conventions.md) - JSON manifest patterns
