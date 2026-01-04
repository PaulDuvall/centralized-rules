# Refactoring Patterns
<!-- TIP: Refactor ruthlessly - simple code is maintainable code -->

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

### Code Smell Categories

This catalog contains **22 code smells** organized into **5 categories**:

#### Bloaters (5 smells)
Things that have grown too large or complex:
- Long Method
- Large Class
- Primitive Obsession
- Long Parameter List
- Data Clumps

#### Object-Orientation Abusers (4 smells)
Incomplete or incorrect application of OO principles:
- Switch Statements
- Temporary Field
- Refused Bequest
- Alternative Classes with Different Interfaces

#### Change Preventers (3 smells)
Code that makes changes difficult:
- Divergent Change
- Shotgun Surgery
- Parallel Inheritance Hierarchies

#### Dispensables (5 smells)
Code that can be removed or simplified:
- Comments (Excessive)
- Duplicate Code
- Speculative Generality
- Lazy Class
- Data Class

#### Couplers (5 smells)
Excessive coupling between classes:
- Feature Envy
- Inappropriate Intimacy
- Message Chains
- Middle Man
- Incomplete Library Class

---

### Code Smells Across Programming Paradigms

While code smell terminology originates from object-oriented programming, **the underlying principles apply universally** across all paradigms. The surface indicators differ, but the deeper problems remain the same.

#### Universal Principles

Code smells detect violations of fundamental software engineering principles that transcend paradigm:

- **Single Responsibility Principle** - One piece of code should do one thing
- **DRY (Don't Repeat Yourself)** - Avoid duplication
- **High Cohesion** - Related functionality should be together
- **Low Coupling** - Minimize dependencies between components
- **Clear Intent** - Code should be self-documenting

#### OO to Procedural/Scripting Translation

| OO Smell | Bash/Script Equivalent | Universal Problem | Bash Refactoring |
|----------|------------------------|-------------------|------------------|
| **Large Class** | **Long Script / God Script** | Doing too much in one place | Extract to sourced library files |
| **Long Method** | **Long Function** | Function too complex to understand | Extract smaller functions |
| **Primitive Obsession** | **String/Array Obsession** | Missing data structures | Use associative arrays, structured files |
| **Data Class** | **Config-Only Script** | Data without behavior | Add validation/processing functions |
| **Feature Envy** | **External Command Obsession** | Over-reliance on external tools | Move logic into functions |
| **Middle Man** | **Wrapper Script** | Unnecessary indirection | Inline or remove wrapper |
| **Duplicate Code** | **Copy-Paste Functions** | Same logic repeated | Extract to shared library |
| **Long Parameter List** | **Many Function Args** | Too many parameters | Use environment variables or config files |
| **Switch Statements** | **Long if-elif Chains** | Type-based branching | Use associative arrays or case statements |
| **Comments (Excessive)** | **Over-Commented Scripts** | Code needs explanation | Rename variables/functions, extract logic |

#### Bash-Specific Code Smell Examples

##### 1. Long Script (Large Class)

```bash
# ❌ SMELL - 800-line god script doing everything
#!/usr/bin/env bash
# deploy.sh - does EVERYTHING

# Database functions
setup_database() { ... }
migrate_database() { ... }
backup_database() { ... }

# AWS functions
configure_aws() { ... }
deploy_to_s3() { ... }
update_cloudfront() { ... }

# Docker functions
build_image() { ... }
push_image() { ... }
deploy_container() { ... }

# Notification functions
send_slack_notification() { ... }
send_email() { ... }

# Main execution
main() {
    setup_database
    migrate_database
    configure_aws
    build_image
    # ... 50+ more operations
}

main "$@"
```

**Refactored:**
```bash
# ✅ BETTER - Modular scripts with single responsibilities

# deploy.sh - Orchestrator (main script)
#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/database.sh"
source "$(dirname "$0")/lib/aws.sh"
source "$(dirname "$0")/lib/docker.sh"
source "$(dirname "$0")/lib/notifications.sh"

main() {
    setup_database
    migrate_database
    deploy_to_aws
    notify_deployment_complete
}

main "$@"

# lib/database.sh - Database operations only
setup_database() { ... }
migrate_database() { ... }
backup_database() { ... }

# lib/aws.sh - AWS operations only
configure_aws() { ... }
deploy_to_s3() { ... }
update_cloudfront() { ... }

# lib/docker.sh - Docker operations only
build_image() { ... }
push_image() { ... }
deploy_container() { ... }
```

##### 2. Long Function

```bash
# ❌ SMELL - 150-line function
process_user_data() {
    local user_file="$1"

    # Validation (20 lines)
    if [[ ! -f "$user_file" ]]; then
        echo "Error: File not found"
        return 1
    fi
    # ... more validation

    # Parsing (30 lines)
    while IFS=',' read -r name email age city; do
        # ... parsing logic
    done < "$user_file"

    # Transformation (40 lines)
    # ... complex transformations

    # Database operations (30 lines)
    # ... database logic

    # Reporting (30 lines)
    # ... reporting logic
}
```

**Refactored:**
```bash
# ✅ BETTER - Small, focused functions
process_user_data() {
    local user_file="$1"

    validate_user_file "$user_file"
    local parsed_data=$(parse_user_file "$user_file")
    local transformed_data=$(transform_user_data "$parsed_data")
    store_user_data "$transformed_data"
    generate_report "$transformed_data"
}

validate_user_file() {
    local file="$1"
    [[ -f "$file" ]] || error "File not found: $file"
    [[ -r "$file" ]] || error "File not readable: $file"
}

parse_user_file() { ... }
transform_user_data() { ... }
store_user_data() { ... }
generate_report() { ... }
```

##### 3. Duplicate Code

```bash
# ❌ SMELL - Repeated validation logic
deploy_to_staging() {
    if [[ -z "${AWS_PROFILE:-}" ]]; then
        echo "Error: AWS_PROFILE not set" >&2
        return 1
    fi
    if ! aws configure list-profiles | grep -q "^${AWS_PROFILE}$"; then
        echo "Error: Profile not found" >&2
        return 1
    fi
    # Deploy logic...
}

deploy_to_production() {
    if [[ -z "${AWS_PROFILE:-}" ]]; then
        echo "Error: AWS_PROFILE not set" >&2
        return 1
    fi
    if ! aws configure list-profiles | grep -q "^${AWS_PROFILE}$"; then
        echo "Error: Profile not found" >&2
        return 1
    fi
    # Deploy logic...
}
```

**Refactored:**
```bash
# ✅ BETTER - Extract common validation
validate_aws_profile() {
    if [[ -z "${AWS_PROFILE:-}" ]]; then
        error "AWS_PROFILE not set"
    fi
    if ! aws configure list-profiles | grep -q "^${AWS_PROFILE}$"; then
        error "Profile not found: ${AWS_PROFILE}"
    fi
}

deploy_to_staging() {
    validate_aws_profile
    # Deploy logic...
}

deploy_to_production() {
    validate_aws_profile
    # Deploy logic...
}
```

##### 4. Primitive Obsession (String Obsession)

```bash
# ❌ SMELL - Passing many related strings separately
create_user() {
    local name="$1"
    local email="$2"
    local street="$3"
    local city="$4"
    local state="$5"
    local zip="$6"

    echo "Creating user: $name at $street, $city, $state $zip"
}

# Called with many parameters
create_user "John Doe" "john@example.com" "123 Main St" "Springfield" "IL" "62701"
```

**Refactored:**
```bash
# ✅ BETTER - Use associative array or structured format
declare -A user_data=(
    [name]="John Doe"
    [email]="john@example.com"
    [street]="123 Main St"
    [city]="Springfield"
    [state]="IL"
    [zip]="62701"
)

create_user() {
    local -n user=$1  # Name reference to associative array

    echo "Creating user: ${user[name]} at ${user[street]}, ${user[city]}, ${user[state]} ${user[zip]}"
}

create_user user_data

# Or use JSON/YAML for complex data
create_user_from_json() {
    local json_file="$1"
    local name=$(jq -r '.name' "$json_file")
    local email=$(jq -r '.email' "$json_file")
    # ... process structured data
}
```

##### 5. Long if-elif Chain (Switch Statements)

```bash
# ❌ SMELL - Long conditional chain
handle_command() {
    local cmd="$1"

    if [[ "$cmd" == "start" ]]; then
        echo "Starting service..."
        systemctl start myservice
    elif [[ "$cmd" == "stop" ]]; then
        echo "Stopping service..."
        systemctl stop myservice
    elif [[ "$cmd" == "restart" ]]; then
        echo "Restarting service..."
        systemctl restart myservice
    elif [[ "$cmd" == "status" ]]; then
        systemctl status myservice
    elif [[ "$cmd" == "logs" ]]; then
        journalctl -u myservice -f
    else
        echo "Unknown command: $cmd"
        return 1
    fi
}
```

**Refactored:**
```bash
# ✅ BETTER - Use case statement and function dispatch
cmd_start() {
    echo "Starting service..."
    systemctl start myservice
}

cmd_stop() {
    echo "Stopping service..."
    systemctl stop myservice
}

cmd_restart() {
    echo "Restarting service..."
    systemctl restart myservice
}

cmd_status() {
    systemctl status myservice
}

cmd_logs() {
    journalctl -u myservice -f
}

handle_command() {
    local cmd="$1"

    case "$cmd" in
        start|stop|restart|status|logs)
            "cmd_${cmd}"
            ;;
        *)
            error "Unknown command: $cmd"
            ;;
    esac
}

# Or use associative array dispatch (Bash 4+)
declare -A commands=(
    [start]=cmd_start
    [stop]=cmd_stop
    [restart]=cmd_restart
    [status]=cmd_status
    [logs]=cmd_logs
)

handle_command() {
    local cmd="$1"
    local handler="${commands[$cmd]:-}"

    if [[ -n "$handler" ]]; then
        "$handler"
    else
        error "Unknown command: $cmd"
    fi
}
```

##### 6. Comments (Excessive)

```bash
# ❌ SMELL - Code that needs excessive comments
process_order() {
    # Check if user is logged in and has valid session
    # and if the session hasn't expired (> 30 minutes)
    # and if the user has the required permissions
    if [[ -n "${USER_ID:-}" ]] && \
       [[ -n "${SESSION_TOKEN:-}" ]] && \
       (( $(date +%s) - SESSION_START < 1800 )) && \
       [[ "${USER_ROLE}" == "admin" || "${USER_ROLE}" == "user" ]]; then
        process_payment
    fi
}
```

**Refactored:**
```bash
# ✅ BETTER - Self-documenting code
is_valid_session() {
    local current_time=$(date +%s)
    local session_duration=$((current_time - SESSION_START))
    local max_duration=1800  # 30 minutes

    (( session_duration < max_duration ))
}

has_required_role() {
    [[ "${USER_ROLE}" == "admin" || "${USER_ROLE}" == "user" ]]
}

is_authenticated() {
    [[ -n "${USER_ID:-}" ]] && [[ -n "${SESSION_TOKEN:-}" ]]
}

can_process_order() {
    is_authenticated && is_valid_session && has_required_role
}

process_order() {
    if can_process_order; then
        process_payment
    else
        error "Not authorized to process order"
    fi
}
```

#### Language-Specific Refactoring Techniques

**Bash/Shell:**
- Extract Function (not Method)
- Source External Library (`source lib/utils.sh`)
- Use Configuration Files (not objects)
- Associative Arrays (Bash 4+) for structured data
- Case Statements for dispatch
- Here-docs for multi-line strings
- Process Substitution for pipelines

**Python (Procedural Style):**
- Extract Function
- Import from modules
- Use dictionaries/namedtuples
- List comprehensions
- Context managers

**Go:**
- Extract Function
- Use packages
- Structs for data grouping
- Interfaces for polymorphism
- Defer for cleanup

**Rust:**
- Extract Function
- Use modules/crates
- Structs and enums
- Traits for polymorphism
- Pattern matching

#### Key Takeaway

**Code smells are paradigm-agnostic.** The names might reference object-oriented concepts, but the underlying problems—complexity, duplication, poor organization, tight coupling—exist in all programming styles. The refactoring techniques adapt to each language's idioms while addressing the same fundamental issues.

---

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

#### Data Clumps
**Smell:** Same group of data items appearing together in multiple places
**Refactoring:** Extract Class, Introduce Parameter Object, Preserve Whole Object

```python
# Smell - Same data items repeated
def create_range(start_day, start_month, start_year, end_day, end_month, end_year):
    pass

def print_range(start_day, start_month, start_year, end_day, end_month, end_year):
    pass

# Better - Extract to DateRange class
@dataclass
class DateRange:
    start: date
    end: date

def create_range(date_range: DateRange):
    pass

def print_range(date_range: DateRange):
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

#### Refused Bequest
**Smell:** Subclass inherits methods/data it doesn't need or use
**Refactoring:** Replace Inheritance with Delegation, Extract Subclass

```python
# Smell - Stack inherits from List but doesn't use most methods
class Stack(list):
    def push(self, item):
        self.append(item)

    def pop(self):
        return super().pop()
    # But also inherits: insert, remove, sort, etc. (not needed)

# Better - Use composition instead
class Stack:
    def __init__(self):
        self._items = []

    def push(self, item):
        self._items.append(item)

    def pop(self):
        return self._items.pop()
```

#### Alternative Classes with Different Interfaces
**Smell:** Classes do similar things but have different method names
**Refactoring:** Rename Method, Move Method, Extract Superclass

```python
# Smell - Different interfaces for similar behavior
class EmailService:
    def send_message(self, to, subject, body):
        pass

class SmsService:
    def transmit(self, phone, text):
        pass

# Better - Unified interface
class MessageService(ABC):
    @abstractmethod
    def send(self, recipient, content):
        pass

class EmailService(MessageService):
    def send(self, recipient, content):
        # Send email
        pass

class SmsService(MessageService):
    def send(self, recipient, content):
        # Send SMS
        pass
```

### Change Preventers

#### Divergent Change
**Smell:** One class commonly changed in different ways for different reasons
**Refactoring:** Extract Class to give each cause of change its own class

#### Shotgun Surgery
**Smell:** Making one change requires many small changes across many classes
**Refactoring:** Move Method, Move Field to bring related changes together

#### Parallel Inheritance Hierarchies
**Smell:** Every time you create a subclass in one hierarchy, you need to create a matching subclass in another
**Refactoring:** Move Method, Move Field to collapse hierarchies

```python
# Smell - Parallel hierarchies
class Employee:
    pass

class Manager(Employee):
    pass

class Engineer(Employee):
    pass

# Separate parallel hierarchy
class EmployeeRenderer:
    pass

class ManagerRenderer(EmployeeRenderer):  # Mirrors Manager
    pass

class EngineerRenderer(EmployeeRenderer):  # Mirrors Engineer
    pass

# Better - Collapse into single hierarchy using composition/strategy
class Employee:
    def __init__(self, renderer):
        self.renderer = renderer

    def render(self):
        return self.renderer.render(self)

class Manager(Employee):
    pass

class Engineer(Employee):
    pass

# Single renderer that handles all types
class EmployeeRenderer:
    def render(self, employee):
        if isinstance(employee, Manager):
            return self._render_manager(employee)
        elif isinstance(employee, Engineer):
            return self._render_engineer(employee)
```

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

#### Speculative Generality
**Smell:** Code designed for future needs that may never materialize
**Refactoring:** Collapse Hierarchy, Inline Class, Remove Parameter

```python
# Smell - Overly generic for current needs
class AbstractDataProcessorFactoryBuilder:
    """Handles creation of data processors for various formats"""
    def create_processor_factory(self, format_type, version, options):
        # Complex abstraction only used in one place with one format
        pass

# Better - Simple solution for actual needs
class CsvProcessor:
    """Process CSV files"""
    def process(self, file_path):
        # Simple, direct implementation
        pass
```

#### Lazy Class
**Smell:** Class doesn't do enough to justify its existence
**Refactoring:** Inline Class, Collapse Hierarchy

```python
# Smell - Class adds no value
class OrderValidator:
    def validate(self, order):
        return order.total > 0

# Usage
validator = OrderValidator()
if validator.validate(order):
    process_order(order)

# Better - Inline the simple logic
if order.total > 0:
    process_order(order)

# Or if validation is more complex, keep as method
class Order:
    def is_valid(self):
        return self.total > 0
```

#### Data Class
**Smell:** Class has only fields, getters, and setters with no behavior
**Refactoring:** Move Method, Extract Method, Encapsulate Field

```python
# Smell - Anemic data class
class Order:
    def __init__(self):
        self.items = []
        self.discount = 0
        self.tax = 0

    def get_items(self):
        return self.items

    def set_discount(self, discount):
        self.discount = discount

# All business logic lives elsewhere
def calculate_total(order):
    subtotal = sum(item.price for item in order.get_items())
    return subtotal - order.discount + order.tax

# Better - Move behavior into the class
class Order:
    def __init__(self):
        self._items = []
        self._discount = 0

    def add_item(self, item):
        self._items.append(item)

    def apply_discount(self, discount):
        self._discount = discount

    def calculate_total(self):
        subtotal = sum(item.price for item in self._items)
        tax = self._calculate_tax(subtotal)
        return subtotal - self._discount + tax

    def _calculate_tax(self, amount):
        return amount * 0.1
```

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

#### Message Chains
**Smell:** Client navigates through multiple objects to get data (Law of Demeter violation)
**Refactoring:** Hide Delegate, Extract Method

```python
# Smell - Long chain of calls
class Customer:
    def get_discount_rate(self):
        manager = self.get_account_manager()
        department = manager.get_department()
        region = department.get_region()
        return region.get_discount_rate()

# Better - Hide the chain
class Customer:
    def get_discount_rate(self):
        return self.account_manager.discount_rate_for_customer(self)

class AccountManager:
    def discount_rate_for_customer(self, customer):
        return self.department.region_discount_rate()
```

#### Middle Man
**Smell:** Class exists only to delegate to another class
**Refactoring:** Remove Middle Man, Inline Method

```python
# Smell - Person just delegates everything to Department
class Person:
    def __init__(self, department):
        self._department = department

    def get_manager(self):
        return self._department.get_manager()

    def get_budget(self):
        return self._department.get_budget()

    def get_location(self):
        return self._department.get_location()

# Usage requires going through person unnecessarily
manager = person.get_manager()

# Better - Access department directly
class Person:
    def __init__(self, department):
        self.department = department  # Public access

# Direct access
manager = person.department.get_manager()
```

#### Incomplete Library Class
**Smell:** Library doesn't have methods you need, forcing workarounds
**Refactoring:** Introduce Foreign Method, Introduce Local Extension

```python
# Smell - Repeated workaround for missing library method
def process_dates(dates):
    for date in dates:
        # Missing: date.next_business_day()
        next_day = date + timedelta(days=1)
        while next_day.weekday() >= 5:  # Skip weekends
            next_day += timedelta(days=1)
        print(next_day)

# Better - Introduce Local Extension
class BusinessDate(date):
    """Extended date class with business day logic"""

    def next_business_day(self):
        next_day = self + timedelta(days=1)
        while next_day.weekday() >= 5:
            next_day += timedelta(days=1)
        return BusinessDate(next_day.year, next_day.month, next_day.day)

    def previous_business_day(self):
        prev_day = self - timedelta(days=1)
        while prev_day.weekday() >= 5:
            prev_day -= timedelta(days=1)
        return BusinessDate(prev_day.year, prev_day.month, prev_day.day)

# Clean usage
def process_dates(dates):
    for date in dates:
        next_day = date.next_business_day()
        print(next_day)
```

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
