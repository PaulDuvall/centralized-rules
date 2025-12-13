# Python Coding Standards

> **Language:** Python 3.11+
> **Applies to:** All Python projects

## Python-Specific Standards

### Type Safety

- **All functions must have type hints** (PEP 484)
- Use modern Python 3.11+ type syntax: `list[T]`, `dict[K, V]` (not `List[T]`, `Dict[K, V]`)
- Use `mypy` for static type checking in strict mode
- **NO bare `Exception` catches** - Catch specific exception types

**Example:**
```python
# ❌ No type hints
def process_data(items):
    return [x * 2 for x in items]

# ✅ With type hints
def process_data(items: list[int]) -> list[int]:
    """Double all values in the input list."""
    return [x * 2 for x in items]

# ✅ Complex types
from typing import Optional
from pathlib import Path

def load_config(path: Path) -> dict[str, Any]:
    """Load configuration from file."""
    pass
```

### Code Structure

- **Maximum 20 lines per function** (severity: warning)
- **Maximum 300 lines per file** (severity: warning)
- **Single Responsibility Principle** - Each function/class does one thing
- Use docstrings for all public functions, classes, and modules (PEP 257)

**Example:**
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

- **All functions that can fail must have error handling**
- Catch specific exceptions (avoid bare `except:`)
- Error messages must be descriptive and actionable
- Include remediation guidance
- Use custom exception classes for domain-specific errors

**Example:**
```python
class DataProcessingError(Exception):
    """Raised when data processing fails."""
    pass

def process_file(file_path: Path) -> dict[str, Any]:
    """Process file and return data.

    Args:
        file_path: Path to input file

    Returns:
        Processed data dictionary

    Raises:
        DataProcessingError: If processing fails
    """
    try:
        with open(file_path) as f:
            data = json.load(f)
        return data
    except FileNotFoundError:
        raise DataProcessingError(
            f"File not found: {file_path} | "
            "Remediation: Check file path exists"
        )
    except json.JSONDecodeError as e:
        raise DataProcessingError(
            f"Invalid JSON in {file_path}: {e} | "
            "Remediation: Validate JSON format"
        )
```

### Documentation

- Google-style or NumPy-style docstrings
- Include `Args:`, `Returns:`, and `Raises:` sections
- Provide examples for complex functions using `Examples:` section

**Example:**
```python
def calculate_score(
    base_score: int,
    multiplier: float,
    bonus: int = 0
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
        >>> calculate_score(50, 2.0)
        100.0
    """
    if base_score < 0:
        raise ValueError("base_score must be non-negative")
    return (base_score * multiplier) + bonus
```

## Python Style Guidelines

### Naming Conventions (PEP 8)

- **Functions and variables:** `snake_case`
- **Classes:** `PascalCase`
- **Constants:** `UPPER_SNAKE_CASE`
- **Private attributes:** `_leading_underscore`
- **Boolean variables:** Use `is_`, `has_`, `should_` prefixes

**Example:**
```python
# Constants
MAX_RETRIES = 3
DEFAULT_TIMEOUT = 30

# Class
class DataProcessor:
    def __init__(self):
        self._cache = {}  # Private attribute

    def process_item(self, item: dict) -> None:
        """Process a single item."""
        is_valid = self._validate(item)
        if is_valid:
            self._store(item)
```

### Import Organization

```python
# Standard library imports
import os
import sys
from pathlib import Path
from typing import Any, Optional

# Third-party imports
import requests
from pydantic import BaseModel

# Local imports
from myapp.config import settings
from myapp.utils import helpers
```

### String Formatting

Use f-strings (Python 3.6+) for string formatting:

```python
# ❌ Old style
message = "Hello, %s" % name

# ❌ .format() method
message = "Hello, {}".format(name)

# ✅ f-strings
message = f"Hello, {name}"
```

## Python Security

### Never Hardcode Secrets

```python
import os

# ❌ Hardcoded secret
API_KEY = 'sk-1234567890abcdef'

# ✅ Environment variable with validation
API_KEY = os.getenv('API_KEY')
if not API_KEY:
    raise ValueError(
        'API_KEY not set | '
        'Remediation: Add to .env file or set environment variable'
    )
```

### Path Validation

```python
from pathlib import Path

def read_file(file_path: str) -> str:
    """Read file with path validation."""
    path = Path(file_path).resolve()

    # Validate file exists
    if not path.exists():
        raise FileNotFoundError(f"File not found: {path}")

    # Validate is actually a file
    if not path.is_file():
        raise ValueError(f"Path is not a file: {path}")

    # Validate extension if needed
    if path.suffix not in ['.txt', '.json', '.csv']:
        raise ValueError(f"Unsupported file type: {path.suffix}")

    return path.read_text()
```

### Subprocess Security

```python
import subprocess
from pathlib import Path

# ❌ Unsafe shell execution
def unsafe_convert(input_path: str, output_path: str) -> None:
    os.system(f'convert {input_path} {output_path}')  # Command injection risk!

# ✅ Safe subprocess execution
def safe_convert(input_path: Path, output_path: Path) -> None:
    """Safely convert file using subprocess."""
    subprocess.run(
        ['convert', str(input_path), str(output_path)],
        capture_output=True,
        check=True,
        timeout=60,
        # shell=False is the default - never set shell=True!
    )
```

## Python Linting and Formatting

### Required Tools

- **ruff** - Fast Python linter (replaces flake8, isort)
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

### Configuration (pyproject.toml)

```toml
[tool.black]
line-length = 100
target-version = ['py311']

[tool.ruff]
line-length = 100
select = ["E", "F", "I", "N", "W"]
ignore = []

[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_configs = true
```

## Python Best Practices

### Use Context Managers

```python
# ✅ Always use context managers for files
with open('file.txt') as f:
    content = f.read()

# ✅ Use pathlib for file operations
from pathlib import Path

path = Path('data/file.txt')
content = path.read_text()
```

### Use Comprehensions

```python
# ❌ Verbose loop
result = []
for item in items:
    if item > 0:
        result.append(item * 2)

# ✅ List comprehension
result = [item * 2 for item in items if item > 0]
```

### Use dataclasses or Pydantic

```python
from dataclasses import dataclass
from typing import Optional

# ✅ Using dataclass
@dataclass
class User:
    name: str
    email: str
    age: Optional[int] = None

# ✅ Or use Pydantic for validation
from pydantic import BaseModel, EmailStr

class User(BaseModel):
    name: str
    email: EmailStr
    age: Optional[int] = None
```

### Avoid Mutable Default Arguments

```python
# ❌ Mutable default
def append_to_list(item, lst=[]):
    lst.append(item)
    return lst

# ✅ Use None and create new list
def append_to_list(item, lst=None):
    if lst is None:
        lst = []
    lst.append(item)
    return lst
```

## Python Testing

See [testing.md](./testing.md) for detailed Python testing guidelines.

## References

- **PEP 8** - Python code style guide
- **PEP 257** - Docstring conventions
- **PEP 484** - Type hints
- **Google Python Style Guide** - Additional best practices
