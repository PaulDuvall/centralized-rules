# Refactoring Patterns

Comprehensive guide to code refactoring using Tidy First principles and Martin Fowler's catalog.

## Refactoring Philosophy

**Definition:** Improving code design without changing external behavior.

### Core Principles

1. **Preserve Behavior** - External behavior unchanged
2. **Small Steps** - Tiny, incremental changes
3. **Test After Each Change** - Verify nothing broke
4. **Commit Frequently** - Save working state
5. **One Refactoring at a Time** - Don't mix with feature work

### The Two Hats (Kent Beck)

- **Feature Hat:** Adding functionality
- **Refactoring Hat:** Improving structure

**Rule:** Never wear both simultaneously.

```
1. Refactoring Hat: Make code easy to change → Commit
2. Feature Hat: Add the feature → Commit
```

---

## Tidy First: Incremental Refactoring

**Workflow:**
```
1. List tidyings that would make change easier
2. Perform tidyings one at a time
3. Commit after each tidying
4. Implement the feature
5. (Optional) Tidy again if new messes emerged
```

### Tidy First Patterns

#### 1. Guard Clauses

```python
# ❌ Before: Nested conditions
def calculate_discount(customer, order):
    if customer.is_premium:
        if order.total > 1000:
            if customer.loyalty_years > 5:
                return order.total * 0.20

# ✅ After: Guard clauses
def calculate_discount(customer, order):
    if not customer.is_premium:
        return 0
    if order.total <= 1000:
        return order.total * 0.10
    if customer.loyalty_years > 5:
        return order.total * 0.20
    return order.total * 0.15
```

#### 2. Dead Code Elimination

```python
# ❌ Before
def process_order(order):
    # validate_customer(order.customer)  # Commented out
    calculate_total(order)
    # send_confirmation_email(order)  # Moved to service
    save_order(order)

# ✅ After
def process_order(order):
    calculate_total(order)
    save_order(order)
```

#### 3. Normalize Symmetries

```python
# ❌ Before: Inconsistent naming
class User:
    def getName(self): pass  # camelCase
    def get_email(self): pass  # snake_case
    def fetchAddress(self): pass  # different verb

# ✅ After: Consistent
class User:
    def get_name(self): pass
    def get_email(self): pass
    def get_address(self): pass
```

#### 4. Reading Order

Arrange code top-to-bottom like a newspaper.

```python
# ✅ Good: Reads top to bottom
class OrderProcessor:
    def process(self, order):
        self._validate(order)
        self._calculate_total(order)
        self._save(order)

    def _validate(self, order):
        pass

    def _calculate_total(self, order):
        pass

    def _save(self, order):
        pass
```

#### 5. Explaining Variables

```python
# ❌ Before
if (user.age > 18 and user.country == 'US' and user.has_license):
    allow_rental()

# ✅ After
is_adult = user.age > 18
is_us_resident = user.country == 'US'
has_drivers_license = user.has_license

if is_adult and is_us_resident and has_drivers_license:
    allow_rental()
```

#### 6. Explaining Constants

```python
# ❌ Before
def calculate_premium(base_rate, risk_factor):
    if risk_factor > 0.75:
        return base_rate * 1.5
    return base_rate

# ✅ After
HIGH_RISK_THRESHOLD = 0.75
HIGH_RISK_MULTIPLIER = 1.5

def calculate_premium(base_rate, risk_factor):
    if risk_factor > HIGH_RISK_THRESHOLD:
        return base_rate * HIGH_RISK_MULTIPLIER
    return base_rate
```

---

## When to Refactor

### The Rule of Three

1. **First occurrence:** Just write it
2. **Second occurrence:** Notice duplication, but duplicate
3. **Third occurrence:** Now refactor to remove duplication

**Rationale:** Premature abstraction worse than duplication.

### Refactoring Opportunities

- ✅ Before adding a feature
- ✅ During code review
- ✅ When fixing a bug
- ✅ Scheduled cleanup sessions

### When NOT to Refactor

- ❌ Code about to be deleted
- ❌ Under extreme time pressure
- ❌ Tests don't exist (write tests first)
- ❌ System unstable (stabilize first)

---

## Code Smells

**22 smells in 5 categories:**

### Bloaters

Things grown too large:

| Smell | Solution |
|-------|----------|
| **Long Method** | Extract Method |
| **Large Class** | Extract Class |
| **Primitive Obsession** | Extract Class, Introduce Parameter Object |
| **Long Parameter List** | Introduce Parameter Object |
| **Data Clumps** | Extract Class |

### Object-Orientation Abusers

| Smell | Solution |
|-------|----------|
| **Switch Statements** | Replace with Polymorphism |
| **Temporary Field** | Extract Class |
| **Refused Bequest** | Replace Inheritance with Delegation |
| **Alternative Classes with Different Interfaces** | Rename Method, Extract Superclass |

### Change Preventers

| Smell | Solution |
|-------|----------|
| **Divergent Change** | Extract Class |
| **Shotgun Surgery** | Move Method, Move Field |
| **Parallel Inheritance Hierarchies** | Move Method to collapse |

### Dispensables

| Smell | Solution |
|-------|----------|
| **Excessive Comments** | Extract Method, Rename Method |
| **Duplicate Code** | Extract Method, Pull Up Method |
| **Speculative Generality** | Collapse Hierarchy, Inline Class |
| **Lazy Class** | Inline Class |
| **Data Class** | Move Method to add behavior |

### Couplers

| Smell | Solution |
|-------|----------|
| **Feature Envy** | Move Method to data's class |
| **Inappropriate Intimacy** | Move Method, Extract Class |
| **Message Chains** | Hide Delegate |
| **Middle Man** | Remove Middle Man, Inline Method |
| **Incomplete Library Class** | Introduce Local Extension |

---

## Refactoring Catalog

### Composing Methods

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

#### Inline Method

```python
# ❌ Before: Method as clear as name
def get_rating(self):
    return 2 if self._more_than_five_late_deliveries() else 1

def _more_than_five_late_deliveries(self):
    return self.late_deliveries > 5

# ✅ After
def get_rating(self):
    return 2 if self.late_deliveries > 5 else 1
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

### Moving Features Between Objects

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

#### Replace Magic Number with Symbolic Constant

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

### Simplifying Conditional Logic

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

#### Replace Nested Conditional with Guard Clauses

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

---

## Bash/Shell Refactoring

Code smells apply universally across paradigms.

### Long Script (Large Class)

```bash
# ❌ SMELL: 800-line god script
#!/usr/bin/env bash
# Everything in one file
setup_database() { ... }
configure_aws() { ... }
build_image() { ... }

# ✅ BETTER: Modular
# deploy.sh
source "$(dirname "$0")/lib/database.sh"
source "$(dirname "$0")/lib/aws.sh"
source "$(dirname "$0")/lib/docker.sh"
```

### Duplicate Code

```bash
# ❌ SMELL: Repeated validation
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

# ✅ BETTER: Extract function
validate_aws_profile() {
    [[ -n "${AWS_PROFILE:-}" ]] || error "AWS_PROFILE not set"
}

deploy_to_staging() {
    validate_aws_profile
    # ...
}
```

### Long if-elif Chain (Switch)

```bash
# ❌ SMELL
handle_command() {
    if [[ "$cmd" == "start" ]]; then
        systemctl start myservice
    elif [[ "$cmd" == "stop" ]]; then
        systemctl stop myservice
    # ... many more conditions
    fi
}

# ✅ BETTER: Case statement + dispatch
cmd_start() { systemctl start myservice; }
cmd_stop() { systemctl stop myservice; }

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

## Safe Refactoring Practices

### The Workflow

```
1. Ensure comprehensive test coverage
2. Make one small change
3. Run tests
4. Commit if tests pass
5. Repeat
```

### Testing Requirements

**Before refactoring:**
- [ ] Comprehensive unit tests exist
- [ ] Integration tests cover critical paths
- [ ] All tests pass

**During refactoring:**
- [ ] Run tests after each micro-step
- [ ] Commit after each successful change

### Automated Refactoring Tools

**Use IDE features:**
- Rename (variable, method, class)
- Extract method/function
- Inline variable/method
- Move class
- Change signature

**Benefits:** Automatic updates, syntax-aware, reduces errors

### Version Control Discipline

```bash
# Commit after each refactoring
git commit -m "refactor: extract calculate_discount method"

# Separate refactoring from features
git commit -m "refactor: simplify conditional in process_order"
git commit -m "feat: add premium user discount"
```

### Refactoring in Legacy Code

**When tests don't exist:**
1. Write characterization tests
2. Add tests for changing area
3. Refactor incrementally
4. Expand coverage gradually

---

## Refactoring Metrics

### Before/After Comparison

Measure:
- **Lines of Code** - Should decrease or stay same
- **Cyclomatic Complexity** - Should decrease
- **Coupling** - Should decrease
- **Cohesion** - Should increase
- **Test Coverage** - Should remain 100% or increase

### Tools

```bash
# Python
pylint myapp/
radon cc myapp/ -a  # Complexity
radon mi myapp/  # Maintainability

# JavaScript
eslint src/
npm run complexity

# General
sonarqube-scanner
```

---

## Summary: Best Practices

1. **Refactor in tiny steps** - Seconds to minutes each
2. **Run tests constantly** - After every micro-refactoring
3. **Commit frequently** - Save working state
4. **One refactoring at a time** - Don't mix patterns
5. **Don't change behavior** - External behavior unchanged
6. **Use automated tools** - IDE refactoring safer than manual
7. **Tidy First** - Clean before adding features
8. **Trust the tests** - Tests enable confident refactoring
9. **Delete dead code** - Version control remembers
10. **Document decisions** - Explain in commit messages

---

## Related Resources

- **Books:** *Refactoring* by Martin Fowler, *Tidy First?* by Kent Beck
- See `base/architecture-principles.md` for design principles
- See `base/code-quality.md` for quality standards
- See `base/testing-philosophy.md` for testing approaches
