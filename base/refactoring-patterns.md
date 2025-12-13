# Refactoring Patterns

A comprehensive guide to code refactoring using Tidy First principles and Martin Fowler's catalog of refactoring patterns.

## Table of Contents

- [Refactoring Philosophy](#refactoring-philosophy)
- [Tidy First: Incremental Refactoring](#tidy-first-incremental-refactoring)
- [When to Refactor](#when-to-refactor)
- [Code Smells](#code-smells)
- [Refactoring Catalog](#refactoring-catalog)
  - [Composing Methods](#composing-methods)
  - [Moving Features Between Objects](#moving-features-between-objects)
  - [Organizing Data](#organizing-data)
  - [Simplifying Conditional Logic](#simplifying-conditional-logic)
  - [Making Method Calls Simpler](#making-method-calls-simpler)
  - [Dealing with Generalization](#dealing-with-generalization)
- [Safe Refactoring Practices](#safe-refactoring-practices)

---

## Refactoring Philosophy

**Definition:** Refactoring is the process of improving the design of existing code without changing its external behavior.

### Core Principles

1. **Preserve Behavior:** External behavior must remain unchanged
2. **Small Steps:** Make tiny, incremental changes
3. **Test After Each Change:** Verify nothing broke
4. **Commit Frequently:** Save working state often
5. **One Refactoring at a Time:** Don't mix refactoring with feature work

### The Two Hats

**Kent Beck's Metaphor:**

- **Feature Hat:** Adding new functionality
- **Refactoring Hat:** Improving structure

**Rule:** Never wear both hats simultaneously.

```
Adding Feature:
  1. Put on Refactoring Hat: Make code easy to change
  2. Commit
  3. Put on Feature Hat: Add the feature
  4. Commit
```

---

## Tidy First: Incremental Refactoring

**Philosophy:** Make a series of small, safe refactorings before adding a feature.

### The Tidy First Workflow

```
Before implementing a feature:
1. List tidyings that would make the change easier
2. Perform tidyings one at a time
3. Commit after each tidying
4. Implement the feature
5. (Optional) Tidy again if new messes emerged
```

### Tidy First Patterns

#### 1. Guard Clauses

**Before:**
```python
def calculate_discount(customer, order):
    if customer.is_premium:
        if order.total > 1000:
            if customer.loyalty_years > 5:
                return order.total * 0.20
            else:
                return order.total * 0.15
        else:
            return order.total * 0.10
    else:
        return 0
```

**After:**
```python
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

**Before:**
```python
def process_order(order):
    # validate_customer(order.customer)  # No longer needed after auth refactor
    calculate_total(order)
    # send_confirmation_email(order)  # Moved to separate service
    save_order(order)
```

**After:**
```python
def process_order(order):
    calculate_total(order)
    save_order(order)
```

**Rule:** Delete code immediately when it's no longer used. Version control remembers it.

#### 3. Normalize Symmetries

**Before:**
```python
# Inconsistent naming
class User:
    def getName(self):  # camelCase
        return self.name

    def get_email(self):  # snake_case
        return self.email

    def fetchAddress(self):  # different verb
        return self.address
```

**After:**
```python
class User:
    def get_name(self):  # Consistent: snake_case, same verb
        return self.name

    def get_email(self):
        return self.email

    def get_address(self):
        return self.address
```

#### 4. New Interface, Old Implementation

**Pattern:** Add a new, better interface while keeping old implementation working.

```python
# Old interface (deprecated)
def calculateTotal(items):
    return sum(item['price'] * item['qty'] for item in items)

# New interface (preferred)
def calculate_total(items: List[Item]) -> Decimal:
    """Calculate total price for items.

    Args:
        items: List of Item objects

    Returns:
        Total price as Decimal
    """
    return sum(item.price * item.quantity for item in items)
```

#### 5. Reading Order

**Principle:** Arrange code so it reads top-to-bottom, like a newspaper.

**Before:**
```python
class OrderProcessor:
    def process(self, order):
        self._validate(order)
        self._calculate_total(order)
        self._save(order)

    def _save(self, order):
        # Implementation
        pass

    def _validate(self, order):
        # Implementation
        pass

    def _calculate_total(self, order):
        # Implementation
        pass
```

**After:**
```python
class OrderProcessor:
    def process(self, order):
        """Main entry point - reads top to bottom"""
        self._validate(order)
        self._calculate_total(order)
        self._save(order)

    def _validate(self, order):
        """First step in reading order"""
        pass

    def _calculate_total(self, order):
        """Second step in reading order"""
        pass

    def _save(self, order):
        """Final step in reading order"""
        pass
```

#### 6. Cohesion Order

**Principle:** Keep related code together.

**Before:**
```python
class ShoppingCart:
    def add_item(self, item): pass
    def calculate_shipping(self): pass
    def remove_item(self, item): pass
    def calculate_tax(self): pass
    def clear(self): pass
    def calculate_total(self): pass
```

**After:**
```python
class ShoppingCart:
    # Item management (cohesive group)
    def add_item(self, item): pass
    def remove_item(self, item): pass
    def clear(self): pass

    # Calculations (cohesive group)
    def calculate_total(self): pass
    def calculate_tax(self): pass
    def calculate_shipping(self): pass
```

#### 7. Explaining Variables

**Before:**
```python
if (user.age > 18 and user.country == 'US' and user.has_license):
    allow_rental()
```

**After:**
```python
is_adult = user.age > 18
is_us_resident = user.country == 'US'
has_drivers_license = user.has_license

if is_adult and is_us_resident and has_drivers_license:
    allow_rental()
```

#### 8. Explaining Constants

**Before:**
```python
def calculate_premium(base_rate, risk_factor):
    if risk_factor > 0.75:
        return base_rate * 1.5
    return base_rate
```

**After:**
```python
HIGH_RISK_THRESHOLD = 0.75
HIGH_RISK_MULTIPLIER = 1.5

def calculate_premium(base_rate, risk_factor):
    if risk_factor > HIGH_RISK_THRESHOLD:
        return base_rate * HIGH_RISK_MULTIPLIER
    return base_rate
```

#### 9. Explicit Parameters

**Before:**
```python
class Report:
    def __init__(self):
        self.start_date = None
        self.end_date = None

    def generate(self):
        # Uses instance variables
        data = fetch_data(self.start_date, self.end_date)
        return format_report(data)
```

**After:**
```python
class Report:
    def generate(self, start_date, end_date):
        # Explicit parameters make dependencies clear
        data = fetch_data(start_date, end_date)
        return format_report(data)
```

#### 10. Chunk Statements

**Principle:** Group related statements with blank lines, like paragraphs.

**Before:**
```python
def process_order(order):
    customer = get_customer(order.customer_id)
    validate_customer(customer)
    items = get_items(order.item_ids)
    validate_items(items)
    total = calculate_total(items)
    tax = calculate_tax(total, customer.state)
    final_total = total + tax
    save_order(order, final_total)
    send_confirmation(customer.email, order)
    log_order(order)
```

**After:**
```python
def process_order(order):
    # Validate customer
    customer = get_customer(order.customer_id)
    validate_customer(customer)

    # Validate and calculate items
    items = get_items(order.item_ids)
    validate_items(items)

    # Calculate totals
    total = calculate_total(items)
    tax = calculate_tax(total, customer.state)
    final_total = total + tax

    # Persist and notify
    save_order(order, final_total)
    send_confirmation(customer.email, order)
    log_order(order)
```

---

## When to Refactor

### The Rule of Three

**Rule:** First time, do it. Second time, duplicate. Third time, refactor.

1. **First occurrence:** Just write the code
2. **Second occurrence:** Notice duplication, but duplicate anyway
3. **Third occurrence:** Now refactor to remove duplication

**Rationale:** Premature abstraction is often worse than duplication.

### Refactoring Opportunities

1. **Before Adding a Feature:** Tidy First to make the change easier
2. **During Code Review:** Clean up before merging
3. **When Fixing a Bug:** Refactor to make the bug impossible
4. **Regular Cleanup:** Scheduled refactoring sessions

### When NOT to Refactor

- ❌ When code is about to be deleted
- ❌ When under extreme time pressure (unless refactoring saves time)
- ❌ When tests don't exist (write tests first)
- ❌ When the system is unstable (stabilize first)

---

## Code Smells

**Code Smell:** A surface indication that usually corresponds to a deeper problem.

### Bloaters

#### Long Method
**Smell:** Method is too long (>20-30 lines)
**Refactoring:** Extract Method, Replace Temp with Query

#### Large Class
**Smell:** Class has too many responsibilities
**Refactoring:** Extract Class, Extract Subclass

#### Primitive Obsession
**Smell:** Using primitives instead of small objects
```python
# Smell
def create_user(name, email, street, city, state, zip):
    pass

# Better
@dataclass
class Address:
    street: str
    city: str
    state: str
    zip_code: str

def create_user(name, email, address: Address):
    pass
```

#### Long Parameter List
**Smell:** Function has >3 parameters
**Refactoring:** Replace Parameter with Method Call, Introduce Parameter Object

```python
# Smell
def create_report(start_date, end_date, format, include_summary, include_details, sort_by):
    pass

# Better
@dataclass
class ReportConfig:
    start_date: date
    end_date: date
    format: str
    include_summary: bool = True
    include_details: bool = False
    sort_by: str = 'date'

def create_report(config: ReportConfig):
    pass
```

### Object-Orientation Abusers

#### Switch Statements
**Smell:** Repeated switch/if-elif chains
**Refactoring:** Replace Conditional with Polymorphism

```python
# Smell
def calculate_shipping(order_type, weight):
    if order_type == 'standard':
        return weight * 0.5
    elif order_type == 'express':
        return weight * 1.5
    elif order_type == 'overnight':
        return weight * 3.0

# Better
class ShippingStrategy:
    def calculate(self, weight): pass

class StandardShipping(ShippingStrategy):
    def calculate(self, weight):
        return weight * 0.5

class ExpressShipping(ShippingStrategy):
    def calculate(self, weight):
        return weight * 1.5
```

#### Temporary Field
**Smell:** Instance variable only set in certain cases
**Refactoring:** Extract Class, Replace Method with Method Object

### Change Preventers

#### Divergent Change
**Smell:** One class commonly changed in different ways for different reasons
**Refactoring:** Extract Class to give each cause of change its own class

#### Shotgun Surgery
**Smell:** Making one change requires many small changes across many classes
**Refactoring:** Move Method, Move Field to bring related changes together

### Dispensables

#### Comments (Excessive)
**Smell:** Code needs comments to be understandable
**Refactoring:** Extract Method, Rename Method, Introduce Assertion

```python
# Smell
# Check if user is eligible for discount:
# - Must be over 18
# - Must have account for > 1 year
# - Must have > 5 purchases
if user.age > 18 and (datetime.now() - user.created_at).days > 365 and user.purchase_count > 5:
    apply_discount()

# Better
def is_eligible_for_discount(user):
    return (user.is_adult() and
            user.has_account_longer_than(years=1) and
            user.has_minimum_purchases(5))

if is_eligible_for_discount(user):
    apply_discount()
```

#### Duplicate Code
**Smell:** Same code structure in multiple places
**Refactoring:** Extract Method, Pull Up Method

### Couplers

#### Feature Envy
**Smell:** Method uses data from another object more than its own
**Refactoring:** Move Method to the object with the data

```python
# Smell
class ShoppingCart:
    def calculate_total_price(self, pricing_service):
        total = 0
        for item in self.items:
            total += pricing_service.get_base_price(item)
            total += pricing_service.get_tax(item)
            total -= pricing_service.get_discount(item)
        return total

# Better: Move pricing logic to PricingService
class PricingService:
    def calculate_item_price(self, item):
        base = self.get_base_price(item)
        tax = self.get_tax(item)
        discount = self.get_discount(item)
        return base + tax - discount

class ShoppingCart:
    def calculate_total_price(self, pricing_service):
        return sum(pricing_service.calculate_item_price(item)
                   for item in self.items)
```

#### Inappropriate Intimacy
**Smell:** Classes access each other's internal fields
**Refactoring:** Move Method, Extract Class, Hide Delegate

---

## Refactoring Catalog

### Composing Methods

#### Extract Method

**When:** Code fragment can be grouped together

**Before:**
```python
def print_owing(self):
    self._print_banner()

    # Print details
    print(f"name: {self.name}")
    print(f"amount: {self.amount}")
```

**After:**
```python
def print_owing(self):
    self._print_banner()
    self._print_details()

def _print_details(self):
    print(f"name: {self.name}")
    print(f"amount: {self.amount}")
```

#### Inline Method

**When:** Method body is as clear as the name

**Before:**
```python
def get_rating(self):
    return 2 if self._more_than_five_late_deliveries() else 1

def _more_than_five_late_deliveries(self):
    return self.late_deliveries > 5
```

**After:**
```python
def get_rating(self):
    return 2 if self.late_deliveries > 5 else 1
```

#### Replace Temp with Query

**Before:**
```python
def calculate_total(self):
    base_price = self.quantity * self.item_price
    if base_price > 1000:
        return base_price * 0.95
    return base_price * 0.98
```

**After:**
```python
def calculate_total(self):
    if self._base_price() > 1000:
        return self._base_price() * 0.95
    return self._base_price() * 0.98

def _base_price(self):
    return self.quantity * self.item_price
```

### Moving Features Between Objects

#### Move Method

**When:** Method uses features of another class more than its own

**Before:**
```python
class Account:
    def overdraft_charge(self):
        if self.type.is_premium():
            return 10
        return 20

class AccountType:
    def is_premium(self):
        return self.name == 'Premium'
```

**After:**
```python
class Account:
    def overdraft_charge(self):
        return self.type.overdraft_charge()

class AccountType:
    def is_premium(self):
        return self.name == 'Premium'

    def overdraft_charge(self):
        return 10 if self.is_premium() else 20
```

#### Extract Class

**When:** Class doing work of two or more classes

**Before:**
```python
class Person:
    def __init__(self, name, office_phone, office_ext):
        self.name = name
        self.office_phone = office_phone
        self.office_ext = office_ext

    def telephone_number(self):
        return f"{self.office_phone} x{self.office_ext}"
```

**After:**
```python
class Person:
    def __init__(self, name):
        self.name = name
        self.office_phone = TelephoneNumber()

    def telephone_number(self):
        return self.office_phone.full_number()

class TelephoneNumber:
    def __init__(self, area_code='', number='', extension=''):
        self.area_code = area_code
        self.number = number
        self.extension = extension

    def full_number(self):
        return f"{self.number} x{self.extension}"
```

### Organizing Data

#### Replace Magic Number with Symbolic Constant

**Before:**
```python
def potential_energy(mass, height):
    return mass * 9.81 * height
```

**After:**
```python
GRAVITATIONAL_CONSTANT = 9.81

def potential_energy(mass, height):
    return mass * GRAVITATIONAL_CONSTANT * height
```

#### Encapsulate Field

**Before:**
```python
class Person:
    def __init__(self, name):
        self.name = name  # Public field
```

**After:**
```python
class Person:
    def __init__(self, name):
        self._name = name  # Private field

    @property
    def name(self):
        return self._name

    @name.setter
    def name(self, value):
        self._name = value
```

### Simplifying Conditional Logic

#### Decompose Conditional

**Before:**
```python
if date.before(SUMMER_START) or date.after(SUMMER_END):
    charge = quantity * winter_rate + winter_service_charge
else:
    charge = quantity * summer_rate
```

**After:**
```python
if is_winter(date):
    charge = winter_charge(quantity)
else:
    charge = summer_charge(quantity)

def is_winter(date):
    return date.before(SUMMER_START) or date.after(SUMMER_END)

def winter_charge(quantity):
    return quantity * winter_rate + winter_service_charge

def summer_charge(quantity):
    return quantity * summer_rate
```

#### Consolidate Conditional Expression

**Before:**
```python
def disability_amount(self):
    if self.seniority < 2:
        return 0
    if self.months_disabled > 12:
        return 0
    if self.is_part_time:
        return 0
    # Calculate disability
```

**After:**
```python
def disability_amount(self):
    if self._is_not_eligible_for_disability():
        return 0
    # Calculate disability

def _is_not_eligible_for_disability(self):
    return (self.seniority < 2 or
            self.months_disabled > 12 or
            self.is_part_time)
```

#### Replace Nested Conditional with Guard Clauses

**Before:**
```python
def pay_amount(self):
    if self.is_dead:
        result = dead_amount()
    else:
        if self.is_separated:
            result = separated_amount()
        else:
            if self.is_retired:
                result = retired_amount()
            else:
                result = normal_amount()
    return result
```

**After:**
```python
def pay_amount(self):
    if self.is_dead:
        return dead_amount()
    if self.is_separated:
        return separated_amount()
    if self.is_retired:
        return retired_amount()
    return normal_amount()
```

---

## Safe Refactoring Practices

### The Refactoring Workflow

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

**Use IDE refactoring features:**
- Rename (variable, method, class)
- Extract method/function
- Inline variable/method
- Move class
- Change signature

**Benefits:**
- Automatic updates of all references
- Syntax-aware transformations
- Reduces manual errors

### Version Control Discipline

```bash
# Commit after each refactoring
git add .
git commit -m "refactor: extract calculate_discount method"

# Separate refactoring commits from feature commits
git commit -m "refactor: simplify conditional in process_order"
git commit -m "feat: add premium user discount"
```

### Refactoring in Legacy Code

**When tests don't exist:**
1. Write characterization tests (document current behavior)
2. Add tests for the area you're changing
3. Refactor incrementally
4. Expand test coverage gradually

---

## Refactoring Metrics

### Before/After Comparison

Measure improvements:
- **Lines of Code:** Should decrease or stay same
- **Cyclomatic Complexity:** Should decrease
- **Coupling:** Should decrease
- **Cohesion:** Should increase
- **Test Coverage:** Should remain 100% (or increase)

### Code Quality Tools

```bash
# Python
pylint myapp/
radon cc myapp/ -a  # Cyclomatic complexity
radon mi myapp/     # Maintainability index

# JavaScript
eslint src/
npm run complexity

# General
sonarqube-scanner
```

---

## Summary: Refactoring Best Practices

1. **Refactor in tiny steps** - Each change should take seconds to minutes
2. **Run tests constantly** - After every micro-refactoring
3. **Commit frequently** - Save working state often
4. **One refactoring at a time** - Don't mix multiple patterns
5. **Don't change behavior** - External observable behavior must stay the same
6. **Use automated tools** - IDE refactoring is safer than manual editing
7. **Tidy First** - Clean code before adding features
8. **Trust the tests** - Comprehensive tests enable confident refactoring
9. **Delete dead code** - Version control remembers it
10. **Document decisions** - Explain non-obvious refactorings in commit messages

---

## Related Resources

- **Books:**
  - *Refactoring* by Martin Fowler
  - *Tidy First?* by Kent Beck
  - *Working Effectively with Legacy Code* by Michael Feathers

- **Related Rules:**
  - See `base/architecture-principles.md` for design principles
  - See `base/code-quality.md` for quality standards
  - See `base/testing-philosophy.md` for testing approaches
