# Python Testing Standards

> **Language:** Python 3.11+
> **Framework:** pytest
> **Applies to:** All Python projects

## pytest Framework

**Installation:**
```bash
pip install pytest pytest-cov pytest-mock
```

**Essential commands:**
```bash
pytest                                        # Run all tests
pytest tests/test_module.py::test_name       # Run specific test
pytest --cov=src --cov-report=term-missing   # Coverage with missing lines
```

## Test Structure

### Organization

```
project/
├── src/mymodule/
│   ├── __init__.py
│   └── core.py
├── tests/
│   ├── conftest.py
│   └── test_core.py
└── pyproject.toml
```

### Test Naming

- Test files: `test_*.py`, mirror source structure
- Test functions: `test_<what>_<condition>_<expected_result>`

```python
def test_validation_rejects_empty_input():
    """Validation raises ValueError for empty input."""
    pass

def test_api_returns_404_for_missing_resource():
    """API returns 404 for non-existent resource."""
    pass
```

## Test Patterns

### Arrange-Act-Assert

```python
def test_calculate_score():
    """Calculate score with multiplier."""
    # Arrange
    base_score = 100
    multiplier = 1.5
    # Act
    result = calculate_score(base_score, multiplier)
    # Assert
    assert result == 150.0
```

### Exception Testing

```python
def test_validation_raises_on_negative():
    """Validation raises ValueError for negative input."""
    with pytest.raises(ValueError, match="must be positive"):
        validate_score(-10)
```

### Fixtures

```python
@pytest.fixture
def sample_user() -> dict:
    """Sample user data."""
    return {"name": "Test User", "email": "test@example.com"}

@pytest.fixture
def temp_file(tmp_path: Path) -> Path:
    """Temporary test file."""
    f = tmp_path / "test.txt"
    f.write_text("test content")
    return f

def test_load_data(sample_user):
    assert sample_user["name"] == "Test User"
```

### Parametrized Tests

```python
@pytest.mark.parametrize("input,expected", [
    (0, 0),
    (1, 2),
    (5, 10),
    (-3, -6),
])
def test_double(input, expected):
    """Double function produces correct output."""
    assert double(input) == expected
```

## Mocking

### Mock External Services

```python
def test_api_call_with_mock(mocker):
    """Fetch data from mocked API."""
    mock_get = mocker.patch('requests.get')
    mock_get.return_value.json.return_value = {"status": "success"}

    result = fetch_data("https://api.example.com")

    assert result["status"] == "success"
    mock_get.assert_called_once_with("https://api.example.com")
```

### Mock File Operations

```python
def test_file_read_with_mock(mocker):
    """Load JSON from mocked file."""
    mocker.patch('builtins.open', mocker.mock_open(
        read_data='{"key": "value"}'
    ))
    result = load_json_file("config.json")
    assert result == {"key": "value"}
```

### Mock Database Fixture

```python
@pytest.fixture
def mock_database(mocker):
    """Mock database connection."""
    mock_db = mocker.MagicMock()
    mock_db.query.return_value = [{"id": 1, "name": "Test"}]
    return mock_db

def test_fetch_users(mock_database):
    """Fetch users from mocked database."""
    users = fetch_users(mock_database)
    assert users[0]["name"] == "Test"
```

## Coverage

**Command:**
```bash
pytest --cov=src --cov-report=term-missing --cov-fail-under=80
```

**Configuration (pyproject.toml):**
```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_functions = ["test_*"]
addopts = [
    "--strict-markers",
    "--cov=src",
    "--cov-report=term-missing",
    "--cov-fail-under=80",
]

[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",
    "raise NotImplementedError",
    "if TYPE_CHECKING:",
]
```

## Property-Based Testing

**Use Hypothesis for property-based tests:**

```python
from hypothesis import given, strategies as st

@given(st.integers())
def test_double_preserves_sign(x):
    """Doubling preserves number sign."""
    result = double(x)
    if x >= 0:
        assert result >= 0
    else:
        assert result < 0

@given(st.lists(st.integers()))
def test_sort_idempotent(lst):
    """Sorting twice equals sorting once."""
    assert sorted(lst) == sorted(sorted(lst))
```

## Integration Testing

### Marking and Skipping Tests

```python
@pytest.mark.integration
def test_database_integration():
    """Database integration test."""
    pass

@pytest.mark.skipif(
    not os.getenv("DATABASE_URL"),
    reason="No DATABASE_URL configured"
)
def test_database_connection():
    """Database connection test (requires DATABASE_URL)."""
    pass
```

**Run only unit tests:** `pytest -m "not integration"`
**Run only integration tests:** `pytest -m integration`

## Best Practices

### Test One Thing Per Test

```python
# ❌ Multiple assertions testing different behaviors
def test_user_creation():
    user = create_user("test@example.com")
    assert user.email == "test@example.com"
    assert user.is_active == True
    assert user.created_at is not None

# ✅ Separate tests for each behavior
def test_user_created_with_email():
    user = create_user("test@example.com")
    assert user.email == "test@example.com"

def test_user_active_by_default():
    user = create_user("test@example.com")
    assert user.is_active == True
```

### Cleanup After Tests

```python
@pytest.fixture
def temp_database():
    """Create temporary database for testing."""
    db = create_test_database()
    yield db
    db.drop_all_tables()  # Cleanup after test
```

### Common Test Patterns

**Async tests:**
```python
@pytest.mark.asyncio
async def test_async_function():
    """Async function test."""
    result = await async_fetch_data()
    assert result is not None
```

**Temporary files:**
```python
def test_file_processing(tmp_path):
    """File processing with temporary directory."""
    input_file = tmp_path / "input.txt"
    input_file.write_text("test data")
    result = process_file(input_file)
    assert result is not None
```

**Environment variables:**
```python
def test_with_env_var(monkeypatch):
    """Test using environment variable."""
    monkeypatch.setenv("API_KEY", "test-key")
    result = get_api_client()
    assert result.api_key == "test-key"
```

## References

- **pytest documentation:** https://docs.pytest.org
- **pytest-cov:** https://pytest-cov.readthedocs.io
- **Hypothesis:** https://hypothesis.readthedocs.io
- **unittest.mock:** https://docs.python.org/3/library/unittest.mock.html
