# Python Coding Standards

> **Language:** Python 3.11+
> **Applies to:** All Python projects

## Python-Specific Standards

### Type Safety

- **All functions must have type hints** (PEP 484)
- Use modern syntax: `list[T]`, `dict[K, V]` (not `List[T]`, `Dict[K, V]`)
- Run `mypy --strict` for static type checking
- **Catch specific exceptions only** - Never bare `except:`

```python
def process_data(items: list[int]) -> list[int]:
    """Double all values in the input list."""
    return [x * 2 for x in items]
```

### Code Structure

- **Maximum 20 lines per function** (warning)
- **Maximum 300 lines per file** (warning)
- **Single Responsibility Principle** per function/class
- Docstrings for all public functions, classes, and modules (PEP 257)

```python
def validate_input(data: dict[str, Any]) -> None:
    """Validate input data structure.

    Args:
        data: Input data dictionary

    Raises:
        ValueError: If data is invalid
    """
    if 'required_field' not in data:
        raise ValueError("Missing required_field")
```

### Error Handling

- All functions that can fail **must have error handling**
- Catch specific exceptions with descriptive, actionable messages
- Use custom exception classes for domain-specific errors

```python
class DataProcessingError(Exception):
    """Raised when data processing fails."""
    pass

try:
    data = json.load(f)
except FileNotFoundError as e:
    raise DataProcessingError(
        f"File not found: {path} | Remediation: Verify path exists"
    ) from e
except json.JSONDecodeError as e:
    raise DataProcessingError(
        f"Invalid JSON in {path}: {e} | Remediation: Validate format"
    ) from e
```

### Documentation

- Google-style docstrings: `Args:`, `Returns:`, `Raises:` sections
- Include `Examples:` section only for complex functions

```python
def calculate_score(
    base_score: int, multiplier: float, bonus: int = 0
) -> float:
    """Calculate final score with multiplier and bonus.

    Args:
        base_score: Initial score value
        multiplier: Score multiplier factor
        bonus: Additional bonus points (default: 0)

    Returns:
        Final calculated score

    Raises:
        ValueError: If base_score is negative

    Examples:
        >>> calculate_score(100, 1.5, 10)
        160.0
    """
    if base_score < 0:
        raise ValueError("base_score must be non-negative")
    return (base_score * multiplier) + bonus
```

## Python Style Guidelines

### Naming Conventions (PEP 8)

- **Functions/variables:** `snake_case`
- **Classes:** `PascalCase`
- **Constants:** `UPPER_SNAKE_CASE`
- **Private attributes:** `_leading_underscore`
- **Boolean variables:** `is_`, `has_`, `should_` prefixes

```python
MAX_RETRIES = 3

class DataProcessor:
    def __init__(self):
        self._cache = {}

    def process_item(self, item: dict) -> None:
        is_valid = self._validate(item)
```

### Import Organization

```python
# Standard library
import os
from pathlib import Path
from typing import Any

# Third-party
import requests

# Local
from myapp.config import settings
```

### String Formatting

Use f-strings only:

```python
message = f"Hello, {name}"
```

## Python Security

### Secrets Management

- Load secrets from environment variables only
- Validate on startup

```python
API_KEY = os.getenv('API_KEY')
if not API_KEY:
    raise ValueError('API_KEY not set | Remediation: Set environment variable')
```

### Path Validation

- Always use `Path.resolve()` to prevent traversal attacks
- Validate file exists and type before processing

```python
path = Path(file_path).resolve()
if not path.is_file():
    raise FileNotFoundError(f"File not found: {path}")
if path.suffix not in ['.json', '.csv']:
    raise ValueError(f"Unsupported file type: {path.suffix}")
```

### Subprocess Execution

- Always use list form with `shell=False` (the default)
- Never use `os.system()` or `shell=True`

```python
subprocess.run(
    ['convert', str(input_path), str(output_path)],
    check=True,
    timeout=60,
)
```

## Python Linting and Formatting

### Required Tools

- **ruff** - Linter and import sorter
- **black** - Code formatter
- **mypy** - Static type checker

```bash
black src/ tests/
ruff check src/ tests/
mypy src/
```

### Configuration (pyproject.toml)

```toml
[tool.black]
line-length = 100
target-version = ['py311']

[tool.ruff]
line-length = 100
select = ["E", "F", "I", "N", "W"]

[tool.mypy]
python_version = "3.11"
strict = true
```

## Python Best Practices

### Context Managers and Comprehensions

```python
# File operations
with open('file.txt') as f:
    content = f.read()

# List comprehension (not loops)
result = [item * 2 for item in items if item > 0]
```

### Data Structures

Use `dataclasses` for simple structures, `Pydantic` for validation:

```python
@dataclass
class User:
    name: str
    email: str
    age: int | None = None
```

### Mutable Default Arguments

```python
# ❌ WRONG
def append_to_list(item, lst=[]):
    lst.append(item)

# ✅ CORRECT
def append_to_list(item, lst: list[int] | None = None) -> list[int]:
    if lst is None:
        lst = []
    lst.append(item)
    return lst
```

## Testing

See [testing.md](./testing.md) for Python testing standards.

## References

- **PEP 8** - Python code style guide
- **PEP 257** - Docstring conventions
- **PEP 484** - Type hints
- **Google Python Style Guide** - Additional best practices
