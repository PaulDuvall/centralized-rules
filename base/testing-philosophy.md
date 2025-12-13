# Testing Philosophy

> **When to apply:** All testing across any language or framework

## Maturity Level Indicators

Apply testing practices based on your project's maturity level:

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

**Legend:**
- ✅ Required - Must implement
- ⚠️ Recommended - Should implement when feasible
- ❌ Optional - Can skip or defer

See `base/project-maturity-levels.md` for coverage targets and `SUCCESS_METRICS.md` for measurement.

## Core Testing Principle

**MANDATORY:** Never proceed to the next task or mark work as complete if tests are failing.

### The Rule:

- All tests must pass before moving forward
- All tests must pass before marking a task complete
- All tests must pass before claiming work is done

### What This Means:

- If you write code and tests fail → Fix the code
- If you refactor and tests fail → Fix the refactoring
- If you add a feature and tests fail → Fix the feature
- **Never** say "done" or "complete" with failing tests

## Testing Philosophy

All code should be thoroughly tested with meaningful coverage.

### What to Test

- **Happy paths** - Normal successful execution
- **Edge cases** - Empty input, null values, boundary conditions
- **Error cases** - Invalid input, exceptions, failures
- **Integration points** - APIs, databases, external services
- **Business logic** - Core functionality and rules
- **Security** - Authentication, authorization, input validation

### Coverage Goals

- **Minimum 80% code coverage** as a baseline
- 100% coverage for critical business logic
- 100% coverage for security-sensitive code
- Lower coverage acceptable for UI rendering/formatting
- Focus on meaningful tests, not just coverage numbers

**Why:** High coverage catches regressions and ensures quality, but 100% everywhere is impractical.

## Test Types

### Unit Tests

- Test individual functions/methods in isolation
- Mock external dependencies
- Fast execution (< 100ms per test)
- Located in dedicated test directories

**When to use:** Testing pure logic, individual functions, data transformations

### Integration Tests

- Test multiple components working together
- May use real dependencies (databases, APIs)
- Slower but more realistic
- Test actual workflows

**When to use:** Testing component interactions, end-to-end flows, real operations

### Property-Based Tests

Property-based testing validates that code satisfies universal properties across a wide range of automatically generated inputs, discovering edge cases that example-based tests miss.

**Core Concept:** Instead of writing specific examples, define properties that should always hold true, then let the framework generate hundreds of test cases.

**When to use:**
- Mathematical properties and algorithms
- Data transformations and serialization
- Validation and parsing logic
- API contracts and invariants
- Anywhere you can express "for all inputs X, property Y holds"

#### Property Testing Frameworks

**Python - Hypothesis:**
```python
from hypothesis import given, strategies as st

@given(st.integers())
def test_reversing_twice_gives_original(x):
    """Property: reverse(reverse(x)) == x"""
    assert reverse(reverse(x)) == x

@given(st.lists(st.integers()))
def test_sorting_is_idempotent(lst):
    """Property: sort(sort(x)) == sort(x)"""
    sorted_once = sorted(lst)
    sorted_twice = sorted(sorted_once)
    assert sorted_once == sorted_twice
```

**TypeScript/JavaScript - fast-check:**
```typescript
import fc from 'fast-check';

test('reversing twice gives original', () => {
  fc.assert(
    fc.property(fc.integer(), (n) => {
      return reverse(reverse(n)) === n;
    })
  );
});

test('concatenating arrays is associative', () => {
  fc.assert(
    fc.property(
      fc.array(fc.integer()),
      fc.array(fc.integer()),
      fc.array(fc.integer()),
      (a, b, c) => {
        const left = a.concat(b).concat(c);
        const right = a.concat(b.concat(c));
        return JSON.stringify(left) === JSON.stringify(right);
      }
    )
  );
});
```

**Go - gopter:**
```go
import "github.com/leanovate/gopter"
import "github.com/leanovate/gopter/prop"

func TestReverseProperty(t *testing.T) {
    properties := gopter.NewProperties(nil)

    properties.Property("reverse(reverse(x)) == x",
        prop.ForAll(
            func(s string) bool {
                return Reverse(Reverse(s)) == s
            },
            gen.AnyString(),
        ))

    properties.TestingRun(t)
}
```

#### Common Properties to Test

**1. Inverse Operations**
```python
from hypothesis import given, strategies as st

@given(st.text())
def test_encode_decode_inverse(text):
    """encode and decode are inverses"""
    encoded = base64_encode(text)
    decoded = base64_decode(encoded)
    assert decoded == text

@given(st.integers(min_value=0, max_value=1000000))
def test_serialize_deserialize(value):
    """Serialization round-trip preserves value"""
    json_str = json.dumps(value)
    result = json.loads(json_str)
    assert result == value
```

**2. Invariants**
```python
@given(st.lists(st.integers()))
def test_sorted_list_invariants(lst):
    """Sorted lists maintain ordering invariant"""
    sorted_lst = sorted(lst)

    # Invariant: each element <= next element
    for i in range(len(sorted_lst) - 1):
        assert sorted_lst[i] <= sorted_lst[i + 1]

    # Invariant: contains same elements
    assert sorted(sorted_lst) == sorted(lst)

@given(st.integers(min_value=1, max_value=100))
def test_shopping_cart_total_invariant(item_count):
    """Cart total always >= 0"""
    cart = ShoppingCart()
    for _ in range(item_count):
        cart.add_item(price=st.floats(min_value=0, max_value=1000))

    assert cart.total() >= 0
```

**3. Idempotence**
```python
@given(st.lists(st.integers()))
def test_deduplication_is_idempotent(lst):
    """Applying dedupe multiple times has same effect as once"""
    deduped_once = deduplicate(lst)
    deduped_twice = deduplicate(deduped_once)
    assert deduped_once == deduped_twice

@given(st.text())
def test_normalization_idempotent(text):
    """normalize(normalize(x)) == normalize(x)"""
    normalized = normalize(text)
    assert normalize(normalized) == normalized
```

**4. Commutativity**
```python
@given(st.integers(), st.integers())
def test_addition_commutative(a, b):
    """a + b == b + a"""
    assert a + b == b + a

@given(st.sets(st.integers()), st.sets(st.integers()))
def test_set_union_commutative(set_a, set_b):
    """set union is commutative"""
    assert set_a.union(set_b) == set_b.union(set_a)
```

**5. Associativity**
```python
@given(st.integers(), st.integers(), st.integers())
def test_addition_associative(a, b, c):
    """(a + b) + c == a + (b + c)"""
    assert (a + b) + c == a + (b + c)

@given(st.lists(st.integers()), st.lists(st.integers()), st.lists(st.integers()))
def test_list_concat_associative(a, b, c):
    """List concatenation is associative"""
    assert (a + b) + c == a + (b + c)
```

#### Advanced Strategies

**Constrained Generation:**
```python
from hypothesis import given, strategies as st, assume

@given(st.integers(), st.integers())
def test_division(a, b):
    assume(b != 0)  # Skip cases where b is zero
    result = a / b
    assert result * b == a  # Within floating point precision

@given(st.emails())  # Built-in email strategy
def test_email_validation(email):
    assert is_valid_email(email)

@given(st.dates(min_value=date(2020, 1, 1), max_value=date(2025, 12, 31)))
def test_date_processing(dt):
    assert process_date(dt).year >= 2020
```

**Custom Strategies:**
```python
from hypothesis.strategies import composite

@composite
def valid_users(draw):
    """Generate valid user objects"""
    return User(
        name=draw(st.text(min_size=1, max_size=50)),
        age=draw(st.integers(min_value=18, max_value=120)),
        email=draw(st.emails()),
        role=draw(st.sampled_from(['user', 'admin', 'moderator']))
    )

@given(valid_users())
def test_user_creation(user):
    assert user.age >= 18
    assert '@' in user.email
    assert user.role in ['user', 'admin', 'moderator']
```

**Stateful Testing:**
```python
from hypothesis.stateful import RuleBasedStateMachine, rule

class ShoppingCartMachine(RuleBasedStateMachine):
    def __init__(self):
        super().__init__()
        self.cart = ShoppingCart()
        self.items = []

    @rule(item=st.text(), price=st.floats(min_value=0.01, max_value=1000))
    def add_item(self, item, price):
        self.cart.add(item, price)
        self.items.append(price)

    @rule()
    def remove_item(self):
        if self.items:
            self.cart.remove_last()
            self.items.pop()

    @rule()
    def check_total(self):
        expected = sum(self.items)
        actual = self.cart.total()
        assert abs(expected - actual) < 0.01

TestShoppingCart = ShoppingCartMachine.TestCase
```

#### Shrinking and Debugging

Property testing frameworks automatically **shrink** failing test cases to minimal examples:

```python
@given(st.lists(st.integers()))
def test_all_positive(lst):
    """This will fail and shrink to minimal case"""
    assert all(x > 0 for x in lst)

# Hypothesis finds failing case: [1, 2, -5, 3, 4]
# Then shrinks to minimal: [0]  or  [-1]
```

**Debugging Shrunk Examples:**
```python
from hypothesis import given, example

@given(st.lists(st.integers()))
@example([])  # Add specific edge cases
@example([0])
@example([-1, 1])
def test_with_examples(lst):
    # Hypothesis runs given examples first, then generated cases
    result = process_list(lst)
    assert result is not None
```

**Reproducing Failures:**
```python
from hypothesis import given, reproduce_failure, seed

# When test fails, Hypothesis prints: @reproduce_failure('6.14.0', b'...')
@reproduce_failure('6.14.0', b'AAEB')  # Reproduce exact failure
@given(st.integers())
def test_something(n):
    assert n >= 0

# Or use seed for reproducibility
@seed(12345)
@given(st.integers())
def test_with_seed(n):
    # Always generates same sequence
    pass
```

#### Integration with Test Suites

**pytest:**
```python
# pytest automatically discovers hypothesis tests
# Run with: pytest test_properties.py

from hypothesis import given, settings, strategies as st

@given(st.integers())
@settings(max_examples=1000)  # Generate 1000 test cases
def test_property(n):
    assert some_property(n)
```

**Configuration:**
```python
from hypothesis import settings, Phase

# Project-wide settings
settings.register_profile("ci", max_examples=1000, deadline=1000)
settings.register_profile("dev", max_examples=100)

# Activate in conftest.py or environment
settings.load_profile("ci" if os.getenv("CI") else "dev")

# Per-test customization
@given(st.integers())
@settings(
    max_examples=500,
    deadline=None,  # No time limit
    suppress_health_check=[HealthCheck.too_slow]
)
def test_expensive_property(n):
    expensive_computation(n)
```

#### Property Testing Best Practices

**1. Start Simple:**
```python
# Good: Simple, clear property
@given(st.lists(st.integers()))
def test_length_preserved(lst):
    assert len(deduplicate(lst)) <= len(lst)

# Avoid: Too complex to understand
@given(st.lists(st.integers()), st.integers(), st.booleans(), st.text())
def test_everything(lst, n, flag, s):
    # Too many variables, unclear property
    pass
```

**2. Test One Property Per Test:**
```python
# Good: One clear property
@given(st.lists(st.integers()))
def test_sorted_is_ordered(lst):
    sorted_lst = sorted(lst)
    for i in range(len(sorted_lst) - 1):
        assert sorted_lst[i] <= sorted_lst[i + 1]

@given(st.lists(st.integers()))
def test_sorted_preserves_elements(lst):
    assert sorted(sorted(lst)) == sorted(lst)

# Avoid: Multiple properties in one test
@given(st.lists(st.integers()))
def test_sorted(lst):
    result = sorted(lst)
    # Too many assertions - split into separate tests
    assert is_ordered(result)
    assert has_same_elements(result, lst)
    assert is_idempotent(result)
```

**3. Use Appropriate Strategies:**
```python
# Good: Constrained generation
@given(st.text(alphabet=st.characters(whitelist_categories=('Lu', 'Ll'))))
def test_alphabetic(text):
    assert text.isalpha()

# Good: Domain-specific strategies
@given(st.ip_addresses(v=4))
def test_ipv4_parsing(ip):
    assert parse_ip(str(ip)).version == 4
```

**4. Combine with Example-Based Tests:**
```python
from hypothesis import given, example

@given(st.integers())
@example(0)  # Important edge case
@example(-1)
@example(sys.maxsize)
def test_with_examples_and_properties(n):
    """Combines specific examples with property testing"""
    result = process_number(n)
    assert isinstance(result, int)
```

#### Real-World Property Testing Examples

**JSON Serialization:**
```python
@given(st.recursive(
    st.none() | st.booleans() | st.floats() | st.text(),
    lambda children: st.lists(children) | st.dictionaries(st.text(), children)
))
def test_json_roundtrip(obj):
    """Any JSON-serializable object survives roundtrip"""
    json_str = json.dumps(obj)
    result = json.loads(json_str)
    assert result == obj
```

**URL Parsing:**
```python
from hypothesis.provisional import urls

@given(urls())
def test_url_parsing(url):
    """All valid URLs can be parsed and reconstructed"""
    parsed = urlparse(url)
    reconstructed = urlunparse(parsed)
    # Should be equivalent (may differ in normalization)
    assert urlparse(reconstructed) == parsed
```

**Database Operations:**
```python
@given(st.text(min_size=1), st.integers(min_value=0))
def test_database_insert_select(name, age):
    """Insert then select returns same data"""
    user_id = db.insert_user(name, age)
    retrieved = db.get_user(user_id)

    assert retrieved.name == name
    assert retrieved.age == age
```

**Compression:**
```python
@given(st.binary())
def test_compression_roundtrip(data):
    """Compression followed by decompression preserves data"""
    compressed = compress(data)
    decompressed = decompress(compressed)
    assert decompressed == data

    # Additional property: compression shouldn't expand much
    if len(data) > 100:
        assert len(compressed) <= len(data) * 2
```

#### Why Property Testing Matters

**Advantages over Example-Based Testing:**
- **Discovers edge cases** you didn't think of
- **Tests thousands of cases** automatically
- **Shrinks failures** to minimal reproducible examples
- **Expresses intent** through properties, not examples
- **Catches regressions** with broader coverage

**When to Use Property Testing:**
- Business logic with clear invariants
- Data transformations and parsers
- API contracts and protocols
- Mathematical algorithms
- Any code where "for all X, Y should hold" applies

**When Example-Based Tests Are Better:**
- Specific business scenarios
- UI interactions and workflows
- Integration with external services
- Cases where properties are hard to express

## Test Structure Pattern

Follow the Arrange-Act-Assert (AAA) pattern:

```
1. Arrange - Set up test data and dependencies
2. Act - Execute the code being tested
3. Assert - Verify the results
```

## Test Naming

- Use descriptive test names
- Include the condition being tested
- Be specific about expected outcome
- Make failures self-explanatory

**Examples:**
- ✅ `test_validation_rejects_empty_input`
- ✅ `test_calculation_handles_negative_numbers`
- ✅ `test_api_returns_404_for_missing_resource`
- ❌ `test_function` (too vague)
- ❌ `test_it_works` (not descriptive)

## Common Test Workflows

### Writing a New Test

1. Identify what to test
2. Choose appropriate test type (unit vs integration)
3. Write test following AAA pattern
4. Run test and verify it fails (if TDD)
5. Implement code
6. Run test and verify it passes
7. Check coverage

### Running Tests

- Run all tests frequently during development
- Run specific tests when debugging
- Run full test suite before committing
- Automate tests in CI/CD pipeline

### Debugging Failing Tests

1. Read the error output carefully
2. Run single failing test in isolation
3. Add debugging output if needed
4. Verify test setup is correct
5. Check that mocks match expectations
6. Fix the root cause, not just the symptom

## Critical Rule: Never Proceed with Failing Tests

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
- ❌ Coverage below minimum threshold
- ❌ Build/compilation errors that prevent tests from running

### Acceptable Exceptions:

- ✅ Tests marked as `skip` or `todo` (intentionally not run)
- ✅ Integration tests skipped due to missing dependencies (if documented)
- ✅ Tests that pass with warnings (but still pass)

**Remember:** "Working" means "all tests pass", not "code compiles".

## Test Dependencies and Mocking

### When to Mock

- External API calls
- Database operations (in unit tests)
- File system operations
- Time-dependent operations
- Third-party services
- Expensive operations

### When NOT to Mock

- Code you own (use real implementations in integration tests)
- Simple data structures
- Pure functions with no side effects
- Critical integration points (test with real dependencies)

### Mock Best Practices

- Keep mocks simple and focused
- Mock at appropriate boundaries
- Verify mock interactions when relevant
- Don't over-mock (makes tests brittle)
- Use real implementations for integration tests

## Test Data and Fixtures

### Good Test Data:

- Minimal but realistic
- Clearly shows what is being tested
- Easy to understand and maintain
- Reusable across tests (via fixtures)
- Isolated (tests don't depend on each other)

### Fixture Management:

- Create shared fixtures for common data
- Keep fixtures focused and minimal
- Use factory functions for variations
- Clean up after tests (teardown)

## Test Organization

### Directory Structure

```
src/                    # Source code
tests/                  # All tests
  unit/                 # Unit tests
  integration/          # Integration tests
  fixtures/             # Test data and utilities
  conftest.*            # Shared test configuration
```

### File Naming

- Mirror source code structure
- Use clear test file naming (e.g., `test_*` or `*_test`)
- Group related tests together
- Keep test files focused

## Performance Considerations

- Unit tests should be fast (< 100ms each)
- Integration tests can be slower but should still be reasonable
- Run fast tests frequently, slow tests less often
- Optimize slow tests or mark them appropriately
- Consider parallel test execution for large suites

## Test Maintenance

- Update tests when requirements change
- Remove obsolete tests
- Refactor tests when they become unclear
- Keep tests DRY (but not at expense of clarity)
- Treat test code with same quality standards as production code

## Integration with Development Workflow

1. **Write test** (if doing TDD, write before code)
2. **Implement code**
3. **Run tests** - Must pass
4. **Refactor** - Tests ensure nothing breaks
5. **Commit** - Only commit when tests pass
6. **Complete** - Mark task done only when tests pass

## Why Testing Matters

### Benefits:
- **Confidence** - Know your code works
- **Regression Prevention** - Catch breaks early
- **Documentation** - Tests show how code should be used
- **Design Feedback** - Hard to test = bad design
- **Refactoring Safety** - Change code with confidence
- **Bug Prevention** - Catch issues before production

### Costs of Not Testing:
- **More Bugs** - Issues reach production
- **Fear of Change** - Can't refactor safely
- **Slower Development** - Manual testing is slow
- **Technical Debt** - Untested code is risky to change
- **Production Incidents** - Bugs discovered by users

---

## Advanced Testing Practices

### Test-Driven Development (TDD)

**The Red-Green-Refactor Cycle:**

1. **Red** - Write a failing test first
2. **Green** - Write minimal code to make it pass
3. **Refactor** - Improve code while keeping tests green

**Benefits of TDD:**
- Forces clear requirements before coding
- Ensures testability from the start
- Creates comprehensive test suite organically
- Reduces debugging time
- Improves design through testability pressure

**TDD Example:**

```python
# Step 1: RED - Write failing test
def test_calculate_total_with_discount():
    cart = ShoppingCart()
    cart.add_item(Product(price=100), quantity=2)
    cart.apply_discount(percentage=10)

    assert cart.calculate_total() == 180  # Test fails - method doesn't exist

# Step 2: GREEN - Minimal implementation
class ShoppingCart:
    def __init__(self):
        self.items = []
        self.discount = 0

    def add_item(self, product, quantity):
        self.items.append({'product': product, 'quantity': quantity})

    def apply_discount(self, percentage):
        self.discount = percentage

    def calculate_total(self):
        subtotal = sum(item['product'].price * item['quantity']
                      for item in self.items)
        return subtotal * (1 - self.discount / 100)

# Step 3: REFACTOR - Improve while keeping tests green
class ShoppingCart:
    def __init__(self):
        self._items: List[CartItem] = []
        self._discount_rate: float = 0.0

    def add_item(self, product: Product, quantity: int):
        self._items.append(CartItem(product, quantity))

    def apply_discount(self, percentage: float):
        if not 0 <= percentage <= 100:
            raise ValueError("Discount must be between 0 and 100")
        self._discount_rate = percentage / 100

    def calculate_total(self) -> Decimal:
        subtotal = sum(item.total_price for item in self._items)
        return subtotal * (Decimal(1) - Decimal(str(self._discount_rate)))
```

### Behavior-Driven Development (BDD)

Focus on behavior and business value rather than implementation details.

**Given-When-Then Pattern:**

```python
# BDD-style test
def test_user_login_with_valid_credentials():
    # Given a user exists with email and password
    user = create_user(email='test@example.com', password='secret123')

    # When the user attempts to log in with correct credentials
    result = login_service.authenticate(
        email='test@example.com',
        password='secret123'
    )

    # Then authentication succeeds and returns a token
    assert result.success is True
    assert result.token is not None
    assert result.user.email == 'test@example.com'
```

**BDD Tools:**
- Python: `pytest-bdd`, `behave`
- JavaScript: `cucumber.js`, `jest-cucumber`
- Ruby: `rspec`, `cucumber`

### Testing Pyramid

Balance different test types for optimal coverage and speed.

```
                 ┌─────────┐
                 │   E2E   │  ← Few, slow, brittle
                 └─────────┘     High confidence
              ┌───────────────┐
              │  Integration  │  ← Some, moderate speed
              └───────────────┘     Test interactions
         ┌──────────────────────┐
         │        Unit          │  ← Many, fast, focused
         └──────────────────────┘     Test logic
```

**Ideal Distribution:**
- **70% Unit Tests** - Fast, focused, testing individual components
- **20% Integration Tests** - Testing component interactions
- **10% E2E Tests** - Testing complete user flows

**Anti-pattern (Ice Cream Cone):** More E2E than unit tests - slow, brittle suite

### Contract Testing

Verify integration points without full integration tests.

```python
# Provider contract test
def test_user_api_contract():
    """Verify API returns expected structure"""
    response = api_client.get('/users/123')

    # Contract: API must return user with these fields
    assert response.status_code == 200
    assert 'id' in response.json()
    assert 'email' in response.json()
    assert 'created_at' in response.json()

# Consumer contract test
def test_user_service_handles_api_contract():
    """Verify service can handle expected API response"""
    mock_api_response = {
        'id': '123',
        'email': 'test@example.com',
        'created_at': '2024-01-01T00:00:00Z'
    }

    user = UserService.from_api_response(mock_api_response)

    assert user.id == '123'
    assert user.email == 'test@example.com'
```

### Mutation Testing

Test your tests by introducing bugs (mutations) and verifying tests catch them.

```bash
# Python mutation testing with mutmut
pip install mutmut
mutmut run

# Results show "mutation score" - % of mutations caught by tests
# High mutation score (>80%) indicates strong test suite
```

**What Mutation Testing Does:**
- Changes `>` to `>=`, `<` to `<=`
- Changes constants (0 to 1, True to False)
- Removes statements
- Changes operators (+, -, *, /)

**If tests still pass after mutation:** Tests are insufficient or weak

### Snapshot Testing

Capture expected output and detect unintended changes.

```python
# Pytest snapshot testing
def test_render_user_profile(snapshot):
    user = User(name='John', email='john@example.com')
    html = render_template('profile.html', user=user)

    # First run: creates snapshot
    # Subsequent runs: compares to snapshot
    snapshot.assert_match(html, 'user_profile.html')

# Update snapshots with: pytest --snapshot-update
```

**When to Use:**
- UI rendering
- API response formats
- Generated output (reports, exports)
- Configuration files

**When NOT to Use:**
- Dynamic data (timestamps, IDs)
- Non-deterministic output
- Frequently changing outputs

### Flaky Test Management

Handle non-deterministic tests that pass/fail intermittently.

**Common Causes:**
- Race conditions in concurrent code
- Time-dependent logic
- External service dependencies
- Shared state between tests
- Test execution order dependencies

**Solutions:**

```python
# Problem: Time-dependent test
def test_session_expires():
    session = create_session()
    time.sleep(61)  # Flaky! Timing may vary
    assert session.is_expired()

# Solution: Control time with mocking
def test_session_expires(freeze_time):
    session = create_session()
    freeze_time.tick(delta=timedelta(minutes=61))
    assert session.is_expired()

# Problem: Order dependency
def test_user_count():
    assert User.count() == 5  # Depends on previous tests

# Solution: Isolate with fixtures
@pytest.fixture(autouse=True)
def clean_database():
    db.clear()
    yield
    db.clear()

def test_user_count():
    create_users(5)
    assert User.count() == 5

# Problem: Race condition
def test_concurrent_updates():
    # Flaky due to timing
    thread1.start()
    thread2.start()
    assert final_value == expected

# Solution: Use synchronization primitives
def test_concurrent_updates():
    barrier = threading.Barrier(2)
    thread1.start(barrier)
    thread2.start(barrier)
    barrier.wait()  # Ensure both threads reach sync point
    assert final_value == expected
```

**Quarantine Strategy:**
```python
# Mark flaky tests for investigation
@pytest.mark.flaky(reruns=3)
def test_external_api():
    # Retry up to 3 times before failing
    pass

# Or quarantine completely
@pytest.mark.skip(reason="Flaky test - under investigation")
def test_problematic_feature():
    pass
```

### Testing Best Practices Summary

**Test Independence:**
- Each test should run in isolation
- No shared state between tests
- Tests should pass in any order
- Use fixtures/setup for test data

**Test Clarity:**
- One assertion concept per test
- Clear test names describing behavior
- Self-documenting tests
- Minimal setup complexity

**Test Speed:**
- Fast unit tests (< 100ms)
- Moderate integration tests (< 5s)
- Slower E2E tests (< 60s)
- Parallel execution when possible

**Test Maintainability:**
- DRY principle for test utilities
- But duplicate test data for clarity
- Refactor tests like production code
- Remove obsolete tests promptly

---

## Testing in Continuous Integration

### CI/CD Test Strategy

**Stages:**
1. **Pre-commit** - Fast unit tests (< 10s)
2. **PR/Merge** - Full unit + integration (< 5min)
3. **Post-merge** - Complete suite + E2E (< 30min)
4. **Nightly** - Extended tests, performance, security

**Example GitHub Actions:**

```yaml
name: Test Suite

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install pytest pytest-cov

      - name: Run unit tests
        run: pytest tests/unit -v --cov=src --cov-report=xml

      - name: Run integration tests
        run: pytest tests/integration -v

      - name: Check coverage threshold
        run: |
          coverage report --fail-under=80

      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

### Test Reporting

**Coverage Reports:**
```bash
# Generate HTML coverage report
pytest --cov=src --cov-report=html

# Coverage badge in README
# Shows current coverage percentage
![Coverage](https://img.shields.io/codecov/c/github/user/repo)
```

**Test Results:**
- Track test count over time
- Monitor test execution time
- Alert on test failures
- Track flaky test rate

---

## Testing AI/ML Systems

### ML Model Testing

**Model Validation Tests:**

```python
def test_model_shape_consistency():
    """Verify model input/output shapes"""
    model = load_model('v1.0.0')
    test_input = create_test_features(batch_size=10)

    predictions = model.predict(test_input)

    assert test_input.shape == (10, 784)  # Expected input shape
    assert predictions.shape == (10, 10)  # Expected output shape

def test_model_prediction_range():
    """Verify predictions are in valid range"""
    model = load_model('v1.0.0')
    test_input = create_test_features()

    predictions = model.predict(test_input)

    # For classification, probabilities should sum to 1
    assert np.allclose(predictions.sum(axis=1), 1.0)
    assert (predictions >= 0).all() and (predictions <= 1).all()

def test_model_determinism():
    """Verify model produces consistent results"""
    model = load_model('v1.0.0')
    test_input = create_test_features()

    pred1 = model.predict(test_input)
    pred2 = model.predict(test_input)

    np.testing.assert_array_almost_equal(pred1, pred2)
```

**Performance Tests:**

```python
def test_model_latency():
    """Verify inference latency meets SLA"""
    model = load_model('v1.0.0')
    test_input = create_test_features(batch_size=1)

    start = time.time()
    model.predict(test_input)
    latency = time.time() - start

    assert latency < 0.1, f"Latency {latency:.3f}s exceeds 100ms SLA"

def test_model_accuracy_threshold():
    """Verify model meets minimum accuracy on test set"""
    model = load_model('v1.0.0')
    test_data, test_labels = load_test_dataset()

    predictions = model.predict(test_data)
    accuracy = calculate_accuracy(predictions, test_labels)

    assert accuracy >= 0.95, f"Accuracy {accuracy:.2%} below 95% threshold"
```

**Data Validation Tests:**

```python
def test_feature_schema():
    """Verify features match expected schema"""
    features = load_features('user_123')

    assert 'age' in features
    assert 'income' in features
    assert isinstance(features['age'], (int, float))
    assert features['age'] >= 0
    assert features['age'] <= 120

def test_data_drift_detection():
    """Detect drift in input distribution"""
    production_data = load_production_data(days=7)
    reference_data = load_reference_data()

    drift_score = calculate_drift(production_data, reference_data)

    assert drift_score < 0.1, f"Data drift {drift_score:.2f} exceeds threshold"
```

### Testing Data Pipelines

```python
def test_feature_transformation_pipeline():
    """Test complete feature engineering pipeline"""
    raw_data = pd.DataFrame({
        'age': [25, 30, None, 40],
        'income': [50000, 60000, 70000, 80000]
    })

    features = feature_pipeline.transform(raw_data)

    # Verify transformations
    assert 'age_normalized' in features.columns
    assert features['age_normalized'].notna().all()  # NaN handling
    assert (features['age_normalized'] >= 0).all()
    assert (features['age_normalized'] <= 1).all()

def test_data_quality_checks():
    """Validate data quality metrics"""
    data = load_training_data()

    # Check for missing values
    assert data.isnull().sum().sum() == 0, "Found null values in training data"

    # Check for duplicates
    assert data.duplicated().sum() == 0, "Found duplicate rows"

    # Check value ranges
    assert (data['age'] >= 0).all() and (data['age'] <= 120).all()

    # Check class balance
    class_distribution = data['label'].value_counts(normalize=True)
    assert (class_distribution > 0.1).all(), "Severe class imbalance detected"
```

---

## Test Maintenance and Debt

### Test Code Quality

Treat test code with same standards as production code:

- **Code review** - Review tests like production code
- **Refactoring** - Improve test structure and clarity
- **Documentation** - Comment complex test logic
- **DRY principle** - Extract common test utilities
- **Type hints** - Use type annotations in tests

### Technical Test Debt

**Signs of Test Debt:**
- Low test coverage on critical code
- Many flaky tests
- Slow test suite (>10min)
- Tests frequently skipped
- Hard-to-understand test failures

**Addressing Test Debt:**
```python
# Before: Hard to understand
def test_user():
    u = User('a@b.c', 'pwd')
    r = u.login('pwd')
    assert r == True

# After: Clear and maintainable
def test_user_login_with_correct_password_succeeds():
    """Verify that a user can successfully log in with correct credentials"""
    # Arrange
    email = 'alice@example.com'
    password = 'secure_password_123'
    user = User(email=email, password=password)

    # Act
    login_result = user.login(password=password)

    # Assert
    assert login_result.success is True, "Login should succeed with correct password"
```

---

## Language-Specific Testing Guides

For detailed testing practices in specific languages:

- **Python**: See `languages/python/testing.md` for pytest, mocking, fixtures
- **TypeScript**: See `languages/typescript/testing.md` for Jest, Vitest, React Testing Library
- **Go**: See `languages/go/testing.md` for testing package, testify, table-driven tests

For framework-specific testing:

- **Django**: See `frameworks/django/best-practices.md` for Django test client, fixtures
- **React**: See `frameworks/react/best-practices.md` for component testing, hooks
- **FastAPI**: See `frameworks/fastapi/best-practices.md` for TestClient, async testing
