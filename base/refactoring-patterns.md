# Refactoring Patterns

Code refactoring guide using Tidy First principles and Martin Fowler's catalog.

## Core Principles

| Principle | Description |
|-----------|-------------|
| **Preserve Behavior** | External behavior unchanged |
| **Small Steps** | Tiny, incremental changes (seconds to minutes) |
| **Test After Each** | Verify nothing broke |
| **Commit Frequently** | Save working state |
| **One at a Time** | Don't mix refactoring with features |

### The Two Hats (Kent Beck)

- **Feature Hat:** Adding functionality
- **Refactoring Hat:** Improving structure
- **Rule:** Never wear both simultaneously

**Workflow:** Refactor → Commit → Feature → Commit

---

## Tidy First Workflow

```
1. List tidyings that make change easier
2. Perform tidyings one at a time
3. Commit after each tidying
4. Implement the feature
5. (Optional) Tidy again if new messes emerged
```

### Quick Tidy Patterns

| Pattern | Before | After |
|---------|--------|-------|
| **Guard Clauses** | `if a: if b: if c: return x` | `if not a: return 0`<br>`if not b: return 0`<br>`if c: return x` |
| **Dead Code** | Comments, unused code | Delete (VCS remembers) |
| **Normalize Symmetries** | `getName()`, `get_email()`, `fetchAddress()` | `get_name()`, `get_email()`, `get_address()` |
| **Reading Order** | Random method order | Top-to-bottom newspaper style |
| **Explaining Variables** | `if user.age > 18 and user.country == 'US'` | `is_adult = user.age > 18`<br>`if is_adult and is_us_resident` |
| **Explaining Constants** | `if risk > 0.75: return base * 1.5` | `HIGH_RISK = 0.75`<br>`MULTIPLIER = 1.5` |

#### Guard Clauses Example

```python
# ❌ Before: Nested
def calculate_discount(customer, order):
    if customer.is_premium:
        if order.total > 1000:
            if customer.loyalty_years > 5:
                return order.total * 0.20

# ✅ After: Guards
def calculate_discount(customer, order):
    if not customer.is_premium:
        return 0
    if order.total <= 1000:
        return order.total * 0.10
    if customer.loyalty_years > 5:
        return order.total * 0.20
    return order.total * 0.15
```

---

## When to Refactor

### Rule of Three

1. **First occurrence:** Write it
2. **Second occurrence:** Notice duplication, but duplicate
3. **Third occurrence:** Refactor to remove duplication

**Rationale:** Premature abstraction worse than duplication.

### Do Refactor

- ✅ Before adding a feature
- ✅ During code review
- ✅ When fixing a bug
- ✅ Scheduled cleanup sessions

### Don't Refactor

- ❌ Code about to be deleted
- ❌ Under extreme time pressure
- ❌ Tests don't exist (write tests first)
- ❌ System unstable (stabilize first)

---

## Code Smells (22 Total)

### Bloaters

| Smell | Solution | Indicator |
|-------|----------|-----------|
| **Long Method** | Extract Method | Method >20 lines |
| **Large Class** | Extract Class | Class >200 lines, many responsibilities |
| **Primitive Obsession** | Extract Class, Parameter Object | Using primitives instead of small objects |
| **Long Parameter List** | Parameter Object | >3-4 parameters |
| **Data Clumps** | Extract Class | Same group of variables together |

### Object-Orientation Abusers

| Smell | Solution | Indicator |
|-------|----------|-----------|
| **Switch Statements** | Replace with Polymorphism | Type codes, case statements on type |
| **Temporary Field** | Extract Class | Fields only set in certain circumstances |
| **Refused Bequest** | Replace Inheritance with Delegation | Subclass doesn't use parent methods |
| **Alternative Classes** | Rename Method, Extract Superclass | Different interfaces, same purpose |

### Change Preventers

| Smell | Solution | Indicator |
|-------|----------|-----------|
| **Divergent Change** | Extract Class | One class changed for multiple reasons |
| **Shotgun Surgery** | Move Method/Field | One change requires edits across many classes |
| **Parallel Hierarchies** | Move Method to collapse | Adding class in A requires adding in B |

### Dispensables

| Smell | Solution | Indicator |
|-------|----------|-----------|
| **Excessive Comments** | Extract Method, Rename | Comments explain what code does |
| **Duplicate Code** | Extract Method, Pull Up | Same code in multiple places |
| **Speculative Generality** | Collapse Hierarchy, Inline | "Someday we might need..." |
| **Lazy Class** | Inline Class | Class doesn't do enough |
| **Data Class** | Move Method | Only fields, getters, setters |

### Couplers

| Smell | Solution | Indicator |
|-------|----------|-----------|
| **Feature Envy** | Move Method | Method uses another class more than own |
| **Inappropriate Intimacy** | Move Method, Extract Class | Classes too coupled |
| **Message Chains** | Hide Delegate | `a.getB().getC().getD()` |
| **Middle Man** | Remove Middle Man, Inline | Class mostly delegates |
| **Incomplete Library** | Introduce Local Extension | Need to extend library class |

---

## Martin Fowler Refactoring Catalog

### Composing Methods

| Refactoring | When | How |
|-------------|------|-----|
| **Extract Method** | Method too long, needs comment | Create new method, move code |
| **Inline Method** | Method body as clear as name | Replace calls with method body |
| **Extract Variable** | Complex expression | Put in variable with good name |
| **Inline Variable** | Variable as clear as expression | Replace with expression directly |
| **Replace Temp with Query** | Temp used multiple times | Extract to method |
| **Split Temporary Variable** | Variable assigned multiple times | Separate variable for each use |

#### Extract Method

```python
# ❌ Before
def print_owing(self):
    self._print_banner()
    print(f"name: {self.name}")
    print(f"amount: {self.amount}")

# ✅ After
def print_owing(self):
    self._print_banner()
    self._print_details()

def _print_details(self):
    print(f"name: {self.name}")
    print(f"amount: {self.amount}")
```

#### Replace Temp with Query

```python
# ❌ Before
def calculate_total(self):
    base_price = self.quantity * self.item_price
    if base_price > 1000:
        return base_price * 0.95
    return base_price * 0.98

# ✅ After
def calculate_total(self):
    if self._base_price() > 1000:
        return self._base_price() * 0.95
    return self._base_price() * 0.98

def _base_price(self):
    return self.quantity * self.item_price
```

### Moving Features

| Refactoring | When | How |
|-------------|------|-----|
| **Move Method** | Method uses another class more | Move to that class |
| **Move Field** | Field used by another class more | Move to that class |
| **Extract Class** | Class doing work of two | Create new class, move relevant fields/methods |
| **Inline Class** | Class not doing much | Merge into another class |
| **Hide Delegate** | Client calls delegate through server | Create method on server |
| **Remove Middle Man** | Too much delegation | Call delegate directly |

#### Move Method

```python
# ❌ Before: Method uses other class more
class Account:
    def overdraft_charge(self):
        if self.type.is_premium():
            return 10
        return 20

# ✅ After: Move to AccountType
class AccountType:
    def overdraft_charge(self):
        return 10 if self.is_premium() else 20

class Account:
    def overdraft_charge(self):
        return self.type.overdraft_charge()
```

#### Extract Class

```python
# ❌ Before: Too many responsibilities
class Person:
    def __init__(self, name, office_phone, office_ext):
        self.name = name
        self.office_phone = office_phone
        self.office_ext = office_ext

# ✅ After
class Person:
    def __init__(self, name):
        self.name = name
        self.office_phone = TelephoneNumber()

class TelephoneNumber:
    def __init__(self, area_code='', number='', extension=''):
        self.area_code = area_code
        self.number = number
        self.extension = extension
```

### Organizing Data

| Refactoring | When | How |
|-------------|------|-----|
| **Replace Magic Number** | Unexplained literal | Named constant |
| **Encapsulate Field** | Public field | Make private, add getter/setter |
| **Encapsulate Collection** | Field returns collection | Return read-only, provide add/remove |
| **Replace Type Code** | Type code affects behavior | Subclass or State/Strategy |
| **Replace Array** | Array holds different types | Object with named fields |

#### Replace Magic Number

```python
# ❌ Before
def potential_energy(mass, height):
    return mass * 9.81 * height

# ✅ After
GRAVITATIONAL_CONSTANT = 9.81

def potential_energy(mass, height):
    return mass * GRAVITATIONAL_CONSTANT * height
```

#### Encapsulate Field

```python
# ❌ Before
class Person:
    def __init__(self, name):
        self.name = name  # Public

# ✅ After
class Person:
    def __init__(self, name):
        self._name = name

    @property
    def name(self):
        return self._name

    @name.setter
    def name(self, value):
        self._name = value
```

### Simplifying Conditionals

| Refactoring | When | How |
|-------------|------|-----|
| **Decompose Conditional** | Complex if/else | Extract condition and branches to methods |
| **Consolidate Conditional** | Multiple conditions, same result | Combine with logical operators |
| **Consolidate Duplicates** | Same code in if/else | Move outside conditional |
| **Replace Nested** | Deep nesting | Guard clauses |
| **Replace Conditional** | Conditional based on type | Polymorphism |
| **Introduce Null Object** | Checking for null | Null object pattern |
| **Introduce Assertion** | Assumption about state | Assertion |

#### Decompose Conditional

```python
# ❌ Before
if date.before(SUMMER_START) or date.after(SUMMER_END):
    charge = quantity * winter_rate + winter_service_charge
else:
    charge = quantity * summer_rate

# ✅ After
if is_winter(date):
    charge = winter_charge(quantity)
else:
    charge = summer_charge(quantity)
```

#### Replace Nested Conditional with Guards

```python
# ❌ Before
def pay_amount(self):
    if self.is_dead:
        result = dead_amount()
    else:
        if self.is_separated:
            result = separated_amount()
        else:
            result = normal_amount()
    return result

# ✅ After
def pay_amount(self):
    if self.is_dead:
        return dead_amount()
    if self.is_separated:
        return separated_amount()
    return normal_amount()
```

### Making Method Calls Simpler

| Refactoring | When | How |
|-------------|------|-----|
| **Rename Method** | Name doesn't reveal purpose | Better name |
| **Add Parameter** | Method needs more info | Add parameter |
| **Remove Parameter** | Parameter not used | Remove it |
| **Separate Query from Modifier** | Method returns value AND changes state | Split into two |
| **Parameterize Method** | Similar methods differ only by value | One method with parameter |
| **Replace Parameter with Method** | Getting value from parameter | Call method instead |
| **Introduce Parameter Object** | Group of parameters always together | New object |
| **Preserve Whole Object** | Getting multiple values from object | Pass object |

### Dealing with Generalization

| Refactoring | When | How |
|-------------|------|-----|
| **Pull Up Field** | Subclasses have same field | Move to superclass |
| **Pull Up Method** | Subclasses have identical method | Move to superclass |
| **Pull Up Constructor** | Subclasses have similar constructors | Superclass constructor |
| **Push Down Method** | Method only relevant to some subclasses | Move to those subclasses |
| **Push Down Field** | Field only used by some subclasses | Move to those subclasses |
| **Extract Subclass** | Features used only in some instances | Subclass |
| **Extract Superclass** | Two classes have similar features | Common superclass |
| **Extract Interface** | Multiple clients use same subset | Interface for subset |
| **Collapse Hierarchy** | Subclass not different enough | Merge into parent |
| **Form Template Method** | Subclasses do similar steps | Template method in superclass |
| **Replace Inheritance** | Subclass uses small part of parent | Delegation |
| **Replace Delegation** | Too much simple delegation | Inheritance |

---

## Bash/Shell Refactoring

### Common Smells

| Smell | Before | After |
|-------|--------|-------|
| **Long Script** | 800-line god script | Modular: `source lib/*.sh` |
| **Duplicate Code** | Same validation in 5 functions | Extract to shared function |
| **Long if-elif** | 20 elif conditions | Case statement + dispatch table |
| **Magic Numbers** | `sleep 300` | `TIMEOUT_SECONDS=300; sleep $TIMEOUT_SECONDS` |
| **Unclear Names** | `process()`, `do_it()` | `deploy_to_staging()`, `validate_config()` |

#### Extract Function

```bash
# ❌ Before: Duplicate validation
deploy_to_staging() {
    if [[ -z "${AWS_PROFILE:-}" ]]; then
        echo "Error: AWS_PROFILE not set" >&2
        return 1
    fi
    # ...
}

deploy_to_production() {
    if [[ -z "${AWS_PROFILE:-}" ]]; then
        echo "Error: AWS_PROFILE not set" >&2
        return 1
    fi
    # ...
}

# ✅ After: Extract function
validate_aws_profile() {
    [[ -n "${AWS_PROFILE:-}" ]] || error "AWS_PROFILE not set"
}

deploy_to_staging() {
    validate_aws_profile
    # ...
}

deploy_to_production() {
    validate_aws_profile
    # ...
}
```

#### Replace if-elif with Case

```bash
# ❌ Before
handle_command() {
    if [[ "$cmd" == "start" ]]; then
        systemctl start myservice
    elif [[ "$cmd" == "stop" ]]; then
        systemctl stop myservice
    elif [[ "$cmd" == "restart" ]]; then
        systemctl restart myservice
    # ... many more
    fi
}

# ✅ After: Case + dispatch
cmd_start() { systemctl start myservice; }
cmd_stop() { systemctl stop myservice; }
cmd_restart() { systemctl restart myservice; }

handle_command() {
    case "$cmd" in
        start|stop|restart|status)
            "cmd_${cmd}"
            ;;
        *)
            error "Unknown command: $cmd"
            ;;
    esac
}
```

---

## Safe Refactoring Workflow

### The Process

```
1. Ensure comprehensive test coverage
2. Make one small change
3. Run tests
4. Commit if tests pass
5. Repeat
```

### Pre-Refactoring Checklist

- [ ] Comprehensive unit tests exist
- [ ] Integration tests cover critical paths
- [ ] All tests pass
- [ ] Understand code behavior

### During Refactoring

- [ ] One refactoring at a time
- [ ] Run tests after each micro-step
- [ ] Commit after each successful change
- [ ] Use IDE automated refactoring tools

### Automated Tools

**Use IDE features for safety:**
- Rename (variable, method, class)
- Extract method/function
- Inline variable/method
- Move class
- Change signature

**Benefits:** Automatic updates, syntax-aware, reduces errors

### Version Control

```bash
# Commit after each refactoring
git commit -m "refactor: extract calculate_discount method"

# Separate refactoring from features
git commit -m "refactor: simplify conditional in process_order"
git commit -m "feat: add premium user discount"
```

### Legacy Code (No Tests)

1. Write characterization tests (document current behavior)
2. Add tests for area you're changing
3. Refactor incrementally
4. Expand coverage gradually

---

## Refactoring Metrics

### Measure Impact

| Metric | Goal |
|--------|------|
| **Lines of Code** | Decrease or stay same |
| **Cyclomatic Complexity** | Decrease |
| **Coupling** | Decrease |
| **Cohesion** | Increase |
| **Test Coverage** | Remain 100% or increase |

### Tools

```bash
# Python
pylint myapp/
radon cc myapp/ -a      # Complexity
radon mi myapp/         # Maintainability
pytest --cov=myapp

# JavaScript
eslint src/
npm run complexity
jest --coverage

# Multi-language
sonarqube-scanner
```

---

## Best Practices Summary

1. **Tiny steps** - Seconds to minutes each
2. **Test constantly** - After every micro-refactoring
3. **Commit frequently** - Save working state
4. **One at a time** - Don't mix patterns or with features
5. **Preserve behavior** - External behavior unchanged
6. **Use automated tools** - IDE refactoring safer than manual
7. **Tidy First** - Clean before adding features
8. **Trust tests** - Tests enable confident refactoring
9. **Delete dead code** - Version control remembers
10. **Document decisions** - Explain in commit messages

---

## Related Resources

- **Books:** *Refactoring* by Martin Fowler, *Tidy First?* by Kent Beck
- See `base/architecture-principles.md` for design principles
- See `base/code-quality.md` for quality standards
- See `base/testing-philosophy.md` for testing approaches
