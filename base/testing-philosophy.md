# Testing Philosophy

> **When to apply:** All testing across any language or framework

## Maturity Level Indicators

| Practice | MVP/POC | Pre-Production | Production |
|----------|---------|----------------|------------|
| Unit tests | ⚠️ Recommended | ✅ Required | ✅ Required |
| Integration tests | ❌ Optional | ⚠️ Recommended | ✅ Required |
| E2E tests | ❌ Not needed | ❌ Optional | ⚠️ Recommended |
| Coverage threshold | 40%+ | 60%+ | 80%+ |
| Coverage enforcement in CI | ❌ Optional | ⚠️ Recommended | ✅ Required |
| Test-first development (TDD) | ❌ Optional | ⚠️ Recommended | ✅ Required |
| Mutation testing | ❌ Not needed | ❌ Optional | ⚠️ Recommended |
| Performance tests | ❌ Not needed | ❌ Optional | ⚠️ Recommended |

See `base/project-maturity-levels.md` for coverage targets.

---

## Core Testing Rules

### MANDATORY: Never Proceed with Failing Tests

**The Rule:** All tests must pass before moving forward, marking tasks complete, or claiming work is done.

- If tests fail after writing code → Fix the code
- If tests fail after refactoring → Fix the refactoring
- If tests fail after adding features → Fix the features
- **Never** say "done" with failing tests

### What to Test

| Test ✅ | Don't Test ❌ |
|---------|---------------|
| Business logic and algorithms | Third-party library internals |
| Edge cases and boundary conditions | Framework code (unless customized) |
| Error handling | Auto-generated code |
| Integration points between components | Simple getters/setters with no logic |
| Critical user workflows (E2E) | - |

---

## Test Types

| Type | Purpose | Speed | Dependencies | When to Use |
|------|---------|-------|--------------|-------------|
| **Unit** | Test individual functions/methods in isolation | Fast (<1ms) | Mocked | Pure logic, algorithms, data transformations |
| **Integration** | Test components working together | Moderate (<5s) | Real or mixed | Component interactions, DB operations, API calls |
| **E2E** | Test complete user workflows | Slow (>1s) | Full stack | Critical user journeys, acceptance criteria |
| **Property-Based** | Test universal properties across many inputs | Varies | Generated data | Mathematical properties, invariants, transformations |

### Testing Pyramid

```
         ┌─────────┐
         │   E2E   │  ← 10%: Few, slow, high confidence
         └─────────┘
      ┌───────────────┐
      │  Integration  │  ← 20%: Some, moderate speed
      └───────────────┘
 ┌──────────────────────┐
 │        Unit          │  ← 70%: Many, fast, focused
 └──────────────────────┘
```

**Anti-pattern (Ice Cream Cone):** More E2E than unit tests - slow, brittle suite.

---

## Test Structure Pattern (AAA)

```python
def test_user_can_update_profile():
    # ARRANGE - Set up test data
    user = User(name="Alice", email="alice@example.com")
    db.session.add(user)
    db.session.commit()

    # ACT - Perform the action
    result = user.update_profile(name="Alice Smith")

    # ASSERT - Verify the outcome
    assert result is True
    assert user.name == "Alice Smith"
    assert user.email == "alice@example.com"  # Unchanged
```

---

## Test Naming

**Pattern:** `test_<what>_<when>_<expected_result>`

| Good ✅ | Bad ❌ |
|---------|--------|
| `test_add_positive_numbers_returns_sum()` | `test_function_1()` |
| `test_divide_by_zero_raises_error()` | `test_user()` |
| `test_create_user_with_duplicate_email_returns_error()` | `test_it_works()` |

---

## TDD: Red-Green-Refactor

```python
# 1. RED: Write failing test
def test_calculate_total_price():
    cart = ShoppingCart()
    cart.add_item(Item("Book", price=10.00), quantity=2)
    assert cart.calculate_total() == 20.00  # FAILS (method doesn't exist)

# 2. GREEN: Minimal code to pass
class ShoppingCart:
    def __init__(self):
        self.items = []

    def add_item(self, item, quantity):
        self.items.append((item, quantity))

    def calculate_total(self):
        return sum(item.price * qty for item, qty in self.items)

# 3. REFACTOR: Improve design
class ShoppingCart:
    def calculate_total(self):
        return sum(self._item_total(item, qty) for item, qty in self.items)

    def _item_total(self, item, quantity):
        return item.price * quantity
```

---

## Property-Based Testing

Test universal properties that should hold for all inputs, not just specific examples.

**Core Concept:** Replace `assert add(2, 3) == 5` with `assert add(a, b) == add(b, a)` (commutativity).

### Common Property Patterns

| Pattern | Example | Use Case |
|---------|---------|----------|
| **Inverse Operations** | `decode(encode(x)) == x` | Serialization, encoding, compression |
| **Invariants** | `sorted(x)[i] <= sorted(x)[i+1]` | Data structures, algorithms |
| **Idempotency** | `normalize(normalize(x)) == normalize(x)` | Normalization, cleanup operations |
| **Commutativity** | `a + b == b + a` | Mathematical operations |
| **Associativity** | `(a + b) + c == a + (b + c)` | Grouping operations |

### Frameworks by Language

| Language | Framework | Import |
|----------|-----------|--------|
| Python | Hypothesis | `from hypothesis import given, strategies as st` |
| TypeScript/JavaScript | fast-check | `import fc from 'fast-check'` |
| Go | gopter | `github.com/leanovate/gopter` |
| Rust | proptest | `use proptest::prelude::*` |

### Property Testing Examples

**Python - Hypothesis:**
```python
from hypothesis import given, strategies as st

@given(st.lists(st.integers()))
def test_sorting_is_idempotent(lst):
    """Property: sort(sort(x)) == sort(x)"""
    assert sorted(sorted(lst)) == sorted(lst)

@given(st.text())
def test_encode_decode_inverse(text):
    """Property: decode(encode(x)) == x"""
    assert base64_decode(base64_encode(text)) == text

@given(st.integers(), st.integers())
def test_addition_commutative(a, b):
    """Property: a + b == b + a"""
    assert a + b == b + a
```

**TypeScript - fast-check:**
```typescript
import fc from 'fast-check';

test('reversing twice gives original', () => {
  fc.assert(fc.property(fc.integer(), (n) => reverse(reverse(n)) === n));
});

test('list concat is associative', () => {
  fc.assert(fc.property(
    fc.array(fc.integer()),
    fc.array(fc.integer()),
    fc.array(fc.integer()),
    (a, b, c) => {
      const left = a.concat(b).concat(c);
      const right = a.concat(b.concat(c));
      return JSON.stringify(left) === JSON.stringify(right);
    }
  ));
});
```

**Stateful Testing (Advanced):**
```python
from hypothesis.stateful import RuleBasedStateMachine, rule

class ShoppingCartMachine(RuleBasedStateMachine):
    def __init__(self):
        super().__init__()
        self.cart = ShoppingCart()
        self.items = []

    @rule(price=st.floats(min_value=0.01, max_value=1000))
    def add_item(self, price):
        self.cart.add(price)
        self.items.append(price)

    @rule()
    def check_total(self):
        assert abs(sum(self.items) - self.cart.total()) < 0.01

TestShoppingCart = ShoppingCartMachine.TestCase
```

### When to Use Property-Based vs Example-Based

| Property-Based ✅ | Example-Based ✅ |
|-------------------|------------------|
| Mathematical algorithms | Specific business scenarios |
| Data transformations (JSON, XML, binary) | UI interactions and workflows |
| Validation and parsing logic | Integration with external services |
| API contracts and invariants | Known edge cases with specific behavior |
| Code with clear universal properties | Cases where properties are hard to express |

---

## Mocking and Dependencies

### Use Dependency Injection

```python
# ✅ Good: Dependencies injected
class OrderService:
    def __init__(self, payment_gateway, email_service):
        self.payment_gateway = payment_gateway
        self.email_service = email_service

    def process_order(self, order):
        self.payment_gateway.charge(order.total)
        self.email_service.send_confirmation(order.customer_email)

# Easy to test with mocks
def test_process_order():
    mock_payment = Mock()
    mock_email = Mock()
    service = OrderService(mock_payment, mock_email)

    service.process_order(Order(total=100, customer_email="test@example.com"))

    mock_payment.charge.assert_called_once_with(100)
    mock_email.send_confirmation.assert_called_once()
```

### When to Mock vs Use Real Dependencies

| Mock ✅ | Use Real ✅ |
|---------|-------------|
| External API calls | Code you own (in integration tests) |
| Database operations (unit tests) | Simple data structures |
| File system operations | Pure functions with no side effects |
| Time-dependent operations | Critical integration points |
| Third-party services | Database operations (integration tests) |

---

## Test Data and Fixtures

### pytest Fixtures

```python
import pytest

@pytest.fixture
def db_session():
    """Provide clean database session for each test"""
    session = create_test_database()
    yield session
    session.rollback()
    session.close()

@pytest.fixture
def sample_user():
    """Provide test user"""
    return User(name="Test User", email="test@example.com")

def test_save_user(db_session, sample_user):
    db_session.add(sample_user)
    db_session.commit()
    assert db_session.query(User).count() == 1
```

### Factory Pattern

```python
from factory import Factory, Faker

class UserFactory(Factory):
    class Meta:
        model = User

    name = Faker('name')
    email = Faker('email')
    created_at = Faker('date_time_this_year')

# Use in tests
def test_user_creation():
    user = UserFactory.create()
    assert '@' in user.email
```

---

## Test Organization

### Directory Structure

```
project/
├── src/
│   ├── users/
│   │   ├── models.py
│   │   └── services.py
│   └── orders/
│       └── services.py
└── tests/
    ├── unit/
    │   ├── test_user_models.py
    │   └── test_order_services.py
    ├── integration/
    │   └── test_user_order_integration.py
    └── e2e/
        └── test_checkout_flow.py
```

**Naming Conventions:**
- Mirror source structure in tests/
- Prefix test files with `test_`
- Group by test type (unit/integration/e2e)

---

## Coverage Guidelines

### Coverage Targets

| Project Stage | Minimum | Goal |
|--------------|---------|------|
| MVP/POC | 40% | 50% |
| Pre-Production | 60% | 70% |
| Production | 80% | 90%+ |

### Running Coverage

```bash
# Python (pytest + coverage)
pytest --cov=src --cov-report=html --cov-report=term

# JavaScript (Jest)
jest --coverage

# Go
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

---

## Testing in CI/CD

### Test Strategy by Stage

| Stage | Tests | Duration | When |
|-------|-------|----------|------|
| **Pre-commit** | Fast unit tests | <10s | Before commit |
| **PR/Merge** | Full unit + integration | <5min | On pull request |
| **Post-merge** | Complete suite + E2E | <30min | After merge |
| **Nightly** | Extended, performance, security | >30min | Scheduled |

### GitHub Actions Example

```yaml
name: Test
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: pip install -r requirements.txt

      - name: Run tests
        run: pytest --cov=src --cov-fail-under=80

      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

---

## Advanced Testing Practices

### Mutation Testing

Test your tests by introducing bugs and verifying tests catch them.

```bash
# Python
pip install mutmut
mutmut run

# High mutation score (>80%) indicates strong test suite
```

**What it does:** Changes operators (`>` to `>=`), constants (0 to 1), removes statements.

### Snapshot Testing

```python
def test_render_user_profile(snapshot):
    user = User(name='John', email='john@example.com')
    html = render_template('profile.html', user=user)
    snapshot.assert_match(html, 'user_profile.html')

# Update snapshots: pytest --snapshot-update
```

**Use for:** UI rendering, API responses, generated reports.
**Avoid for:** Dynamic data (timestamps, IDs), non-deterministic output.

### Contract Testing

```python
# Provider contract test
def test_user_api_contract():
    """Verify API returns expected structure"""
    response = api_client.get('/users/123')
    assert response.status_code == 200
    assert all(key in response.json() for key in ['id', 'email', 'created_at'])

# Consumer contract test
def test_user_service_handles_api_contract():
    """Verify service can handle expected API response"""
    mock_response = {'id': '123', 'email': 'test@example.com', 'created_at': '2024-01-01T00:00:00Z'}
    user = UserService.from_api_response(mock_response)
    assert user.id == '123'
```

---

## Testing AI/ML Systems

### Model Testing

```python
def test_model_accuracy_above_threshold():
    model = load_trained_model()
    X_test, y_test = load_test_data()
    accuracy = model.score(X_test, y_test)
    assert accuracy >= 0.85, f"Model accuracy {accuracy} below threshold"

def test_model_predictions_deterministic():
    model = load_trained_model()
    X = [[1, 2, 3]]
    pred1 = model.predict(X)
    pred2 = model.predict(X)
    assert np.array_equal(pred1, pred2)

def test_model_shape_consistency():
    """Verify model input/output shapes"""
    model = load_model('v1.0.0')
    test_input = create_test_features(batch_size=10)
    predictions = model.predict(test_input)
    assert test_input.shape == (10, 784)
    assert predictions.shape == (10, 10)
```

### Data Pipeline Testing

```python
def test_feature_engineering_pipeline():
    raw_data = pd.DataFrame({'age': [25], 'income': [50000]})
    features = feature_pipeline.transform(raw_data)

    assert 'age_normalized' in features.columns
    assert 0 <= features['age_normalized'].iloc[0] <= 1

def test_data_quality_checks():
    """Validate data quality metrics"""
    data = load_training_data()
    assert data.isnull().sum().sum() == 0, "Found null values"
    assert data.duplicated().sum() == 0, "Found duplicates"

    # Check class balance
    class_distribution = data['label'].value_counts(normalize=True)
    assert (class_distribution > 0.1).all(), "Severe class imbalance"
```

---

## Performance and Flaky Tests

### Keep Tests Fast

| Test Type | Speed Target | Strategy |
|-----------|--------------|----------|
| Unit | <100ms each | Mock all external dependencies |
| Integration | <5s each | Use lightweight test databases |
| E2E | <60s each | Test critical paths only |
| Full suite | <10min | Parallel execution |

### Handling Flaky Tests

| Cause | Solution |
|-------|----------|
| Race conditions | Use synchronization primitives (barriers, locks) |
| Time-dependent logic | Mock time with `freeze_time` or similar |
| External dependencies | Mock external services |
| Shared state | Isolate with fixtures and cleanup |
| Order dependencies | Use `autouse` fixtures to reset state |

```python
# Problem: Time-dependent test
def test_session_expires():
    session = create_session()
    time.sleep(61)  # Flaky!
    assert session.is_expired()

# Solution: Control time
def test_session_expires(freeze_time):
    session = create_session()
    freeze_time.tick(delta=timedelta(minutes=61))
    assert session.is_expired()

# Quarantine strategy
@pytest.mark.flaky(reruns=3)
def test_external_api():
    """Retry up to 3 times before failing"""
    pass
```

---

## Test Maintenance

### Refactor Tests Like Production Code

```python
# ❌ Bad: Duplicated setup
def test_user_can_login():
    user = User(email="test@example.com", password="hashed")
    db.save(user)
    assert login("test@example.com", "password") is True

def test_user_can_update_profile():
    user = User(email="test@example.com", password="hashed")
    db.save(user)
    assert user.update_profile(name="New") is True

# ✅ Good: Shared fixture
@pytest.fixture
def test_user(db):
    user = User(email="test@example.com", password="hashed")
    db.save(user)
    return user

def test_user_can_login(test_user):
    assert login("test@example.com", "password") is True

def test_user_can_update_profile(test_user):
    assert test_user.update_profile(name="New") is True
```

### Signs of Test Debt

| Symptom | Action |
|---------|--------|
| Low coverage on critical code | Prioritize adding tests |
| Many flaky tests | Fix or quarantine |
| Slow test suite (>10min) | Optimize or parallelize |
| Tests frequently skipped | Fix or remove |
| Hard-to-understand failures | Refactor test clarity |

---

## Language-Specific Examples

### Python (pytest)

```python
import pytest

@pytest.mark.parametrize("input,expected", [(2, 4), (3, 9), (4, 16)])
def test_square(input, expected):
    assert square(input) == expected

def test_error_handling():
    with pytest.raises(ValueError):
        process_invalid_data()
```

### JavaScript (Jest)

```javascript
test('adds 1 + 2 to equal 3', () => {
  expect(add(1, 2)).toBe(3);
});

test('user creation', async () => {
  const user = await createUser('test@example.com');
  expect(user.email).toBe('test@example.com');
});
```

### Go

```go
func TestAdd(t *testing.T) {
    tests := []struct {
        a, b, want int
    }{
        {2, 3, 5},
        {0, 0, 0},
        {-1, 1, 0},
    }

    for _, tt := range tests {
        got := Add(tt.a, tt.b)
        if got != tt.want {
            t.Errorf("Add(%d, %d) = %d; want %d", tt.a, tt.b, got, tt.want)
        }
    }
}
```

---

## Critical Testing Checklist

**Before committing:**
- [ ] All tests pass locally
- [ ] New features have tests
- [ ] Bug fixes have regression tests
- [ ] Coverage meets minimum threshold
- [ ] No skipped/ignored tests without justification

**Before deploying:**
- [ ] All CI tests pass
- [ ] Integration tests pass
- [ ] E2E tests pass (if applicable)
- [ ] No flaky tests failing intermittently

---

## Related Resources

- See `base/tdd-comprehensive.md` for detailed TDD workflows
- See `base/code-quality.md` for quality standards
- See `base/project-maturity-levels.md` for coverage requirements
- See `base/cicd-comprehensive.md` for CI/CD integration

---

**Remember:** Tests are your safety net. Write them first, run them often, and never commit failing tests.
