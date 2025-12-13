# Python Testing Standards

> **Language:** Python 3.11+
> **Framework:** pytest
> **Applies to:** All Python projects

## Python Testing Framework

### pytest

Primary test framework for Python projects.

**Installation:**
```bash
pip install pytest pytest-cov pytest-mock
```

**Basic usage:**
```bash
# Run all tests
pytest

# Run specific test file
pytest tests/test_module.py

# Run with coverage
pytest --cov=src --cov-report=html

# Run with verbose output
pytest -v

# Run specific test
pytest tests/test_module.py::test_function_name
```

## Test Structure

### File Organization

```
project/
├── src/
│   └── mymodule/
│       ├── __init__.py
│       └── core.py
├── tests/
│   ├── __init__.py
│   ├── conftest.py          # Shared fixtures
│   ├── test_core.py         # Tests for core.py
│   └── integration/
│       └── test_integration.py
└── pyproject.toml
```

### Test File Naming

- Prefix test files with `test_`
- Mirror source code structure
- Example: `src/core.py` → `tests/test_core.py`

### Test Function Naming

```python
import pytest

# ✅ Descriptive test names
def test_validation_rejects_empty_input():
    """Test that validation raises ValueError for empty input."""
    pass

def test_calculation_handles_negative_numbers():
    """Test calculation works with negative inputs."""
    pass

def test_api_returns_404_for_missing_resource():
    """Test API returns 404 status for non-existent resource."""
    pass

# ❌ Vague test names
def test_function():
    pass

def test_it_works():
    pass
```

## Test Patterns

### Basic Test Structure (Arrange-Act-Assert)

```python
def test_calculate_score():
    """Test score calculation with standard inputs."""
    # Arrange
    base_score = 100
    multiplier = 1.5

    # Act
    result = calculate_score(base_score, multiplier)

    # Assert
    assert result == 150.0
```

### Testing Exceptions

```python
import pytest

def test_validation_raises_on_invalid_input():
    """Test that invalid input raises ValueError."""
    with pytest.raises(ValueError, match="must be positive"):
        validate_score(-10)

def test_file_not_found_error():
    """Test FileNotFoundError is raised for missing file."""
    with pytest.raises(FileNotFoundError):
        load_config(Path("nonexistent.json"))
```

### Using Fixtures

```python
import pytest
from pathlib import Path

@pytest.fixture
def sample_data():
    """Provide sample test data."""
    return {
        "name": "Test User",
        "email": "test@example.com",
        "age": 25
    }

@pytest.fixture
def temp_file(tmp_path: Path):
    """Create a temporary test file."""
    file_path = tmp_path / "test.txt"
    file_path.write_text("test content")
    return file_path

def test_load_data(sample_data):
    """Test loading data works with fixture."""
    assert sample_data["name"] == "Test User"

def test_read_file(temp_file):
    """Test reading from temporary file."""
    content = temp_file.read_text()
    assert content == "test content"
```

### Parametrized Tests

```python
import pytest

@pytest.mark.parametrize("input,expected", [
    (0, 0),
    (1, 2),
    (5, 10),
    (-3, -6),
])
def test_double(input, expected):
    """Test doubling function with multiple inputs."""
    assert double(input) == expected

@pytest.mark.parametrize("value,is_valid", [
    ("valid@email.com", True),
    ("invalid-email", False),
    ("", False),
    ("test@", False),
])
def test_email_validation(value, is_valid):
    """Test email validation with various inputs."""
    assert validate_email(value) == is_valid
```

## Mocking

### Using pytest-mock

```python
import pytest
from unittest.mock import MagicMock

def test_api_call_with_mock(mocker):
    """Test function that calls external API."""
    # Mock the requests.get function
    mock_get = mocker.patch('requests.get')
    mock_response = MagicMock()
    mock_response.json.return_value = {"status": "success"}
    mock_response.status_code = 200
    mock_get.return_value = mock_response

    # Call function that uses requests.get
    result = fetch_data("https://api.example.com")

    # Verify
    assert result["status"] == "success"
    mock_get.assert_called_once_with("https://api.example.com")
```

### Mocking File Operations

```python
def test_file_read_with_mock(mocker):
    """Test file reading with mocked open."""
    mock_open = mocker.patch('builtins.open', mocker.mock_open(
        read_data='{"key": "value"}'
    ))

    result = load_json_file("config.json")

    assert result == {"key": "value"}
    mock_open.assert_called_once_with("config.json")
```

### Mocking External Services

```python
@pytest.fixture
def mock_database(mocker):
    """Mock database connection."""
    mock_db = mocker.MagicMock()
    mock_db.query.return_value = [{"id": 1, "name": "Test"}]
    return mock_db

def test_fetch_users(mock_database):
    """Test fetching users from mocked database."""
    users = fetch_users(mock_database)
    assert len(users) == 1
    assert users[0]["name"] == "Test"
```

## Coverage

### Running with Coverage

```bash
# Generate coverage report
pytest --cov=src --cov-report=html

# Show missing lines
pytest --cov=src --cov-report=term-missing

# Fail if coverage below threshold
pytest --cov=src --cov-fail-under=80
```

### Coverage Configuration (pyproject.toml)

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
addopts = [
    "--strict-markers",
    "--cov=src",
    "--cov-report=term-missing",
    "--cov-fail-under=80",
]

[tool.coverage.run]
source = ["src"]
omit = [
    "*/tests/*",
    "*/test_*.py",
]

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

## Property-Based Testing

### Using Hypothesis

```python
from hypothesis import given, strategies as st

@given(st.integers())
def test_double_property(x):
    """Test that doubling preserves sign."""
    result = double(x)
    if x >= 0:
        assert result >= 0
    else:
        assert result < 0

@given(st.text())
def test_uppercase_length_preserved(text):
    """Test that uppercasing preserves length."""
    result = text.upper()
    assert len(result) == len(text)

@given(st.lists(st.integers()))
def test_sort_idempotent(lst):
    """Test that sorting twice gives same result."""
    sorted_once = sorted(lst)
    sorted_twice = sorted(sorted_once)
    assert sorted_once == sorted_twice
```

## Integration Testing

### Marking Tests

```python
import pytest

@pytest.mark.integration
def test_database_integration():
    """Integration test requiring database."""
    pass

@pytest.mark.slow
def test_expensive_operation():
    """Slow test that processes large dataset."""
    pass

# Run only unit tests (skip integration)
# pytest -m "not integration"

# Run only integration tests
# pytest -m integration
```

### Skip Tests Conditionally

```python
import pytest
import os

@pytest.mark.skipif(
    not os.getenv("DATABASE_URL"),
    reason="No database URL configured"
)
def test_database_connection():
    """Test database connection (requires DATABASE_URL)."""
    pass

@pytest.mark.skipif(
    not os.getenv("API_KEY"),
    reason="No API key configured"
)
def test_api_call():
    """Test API call (requires API_KEY)."""
    pass
```

## Best Practices

### 1. Test One Thing

```python
# ❌ Testing multiple things
def test_user_creation():
    user = create_user("test@example.com")
    assert user.email == "test@example.com"
    assert user.is_active == True
    assert user.created_at is not None

# ✅ Separate tests
def test_user_created_with_email():
    user = create_user("test@example.com")
    assert user.email == "test@example.com"

def test_user_active_by_default():
    user = create_user("test@example.com")
    assert user.is_active == True

def test_user_has_creation_timestamp():
    user = create_user("test@example.com")
    assert user.created_at is not None
```

### 2. Use Descriptive Assertions

```python
# ❌ Generic assertion
assert result == expected

# ✅ Descriptive assertion
assert result == expected, f"Expected {expected}, got {result}"

# ✅ Or use pytest's assert rewriting (automatically descriptive)
assert user.email == "test@example.com"  # pytest shows both values on failure
```

### 3. Clean Up After Tests

```python
import pytest

@pytest.fixture
def temp_database():
    """Create temporary database for testing."""
    db = create_test_database()
    yield db
    # Cleanup happens after yield
    db.drop_all_tables()
    db.close()

def test_with_database(temp_database):
    """Test that uses temporary database."""
    # Database automatically cleaned up after test
    pass
```

## Common Patterns

### Testing Async Code

```python
import pytest

@pytest.mark.asyncio
async def test_async_function():
    """Test asynchronous function."""
    result = await async_fetch_data()
    assert result is not None
```

### Testing with Temp Files

```python
def test_file_processing(tmp_path):
    """Test file processing with temporary directory."""
    # Create temp file
    input_file = tmp_path / "input.txt"
    input_file.write_text("test data")

    # Process file
    result = process_file(input_file)

    # Verify output
    output_file = tmp_path / "output.txt"
    assert output_file.exists()
```

### Testing with Environment Variables

```python
def test_with_env_var(monkeypatch):
    """Test function that uses environment variable."""
    monkeypatch.setenv("API_KEY", "test-key")

    result = get_api_client()

    assert result.api_key == "test-key"
```

## References

- **pytest documentation:** https://docs.pytest.org
- **pytest-cov:** https://pytest-cov.readthedocs.io
- **Hypothesis:** https://hypothesis.readthedocs.io
- **unittest.mock:** https://docs.python.org/3/library/unittest.mock.html
