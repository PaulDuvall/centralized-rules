# Architecture Principles

Universal architectural guidelines for building maintainable, scalable, and robust software systems.

## Table of Contents

- [SOLID Principles](#solid-principles)
- [Domain-Driven Design (DDD)](#domain-driven-design-ddd)
- [Modularity and Separation of Concerns](#modularity-and-separation-of-concerns)
- [Dependency Management](#dependency-management)
- [Design Patterns](#design-patterns)

---

## SOLID Principles

### Single Responsibility Principle (SRP)

**Rule:** A class should have one, and only one, reason to change.

- Each module, class, or function should be responsible for a single part of the functionality
- High cohesion within modules, low coupling between modules
- Easier to understand, test, and maintain

**Example (Anti-pattern):**
```python
# Bad: UserManager handles too many responsibilities
class UserManager:
    def create_user(self, data): pass
    def send_email(self, user): pass
    def generate_report(self, user): pass
    def validate_password(self, password): pass
```

**Example (Good):**
```python
# Good: Each class has single responsibility
class UserRepository:
    def create_user(self, data): pass

class EmailService:
    def send_email(self, user): pass

class ReportGenerator:
    def generate_report(self, user): pass

class PasswordValidator:
    def validate(self, password): pass
```

### Open/Closed Principle (OCP)

**Rule:** Software entities should be open for extension but closed for modification.

- Design modules that can be extended without modifying existing code
- Use abstraction, interfaces, and composition
- New functionality through new code, not changes to existing code

**Example:**
```python
# Good: Strategy pattern allows extension without modification
class PaymentProcessor:
    def __init__(self, strategy):
        self.strategy = strategy

    def process(self, amount):
        return self.strategy.process(amount)

# Extend with new payment methods without modifying PaymentProcessor
class CreditCardStrategy:
    def process(self, amount): pass

class PayPalStrategy:
    def process(self, amount): pass
```

### Liskov Substitution Principle (LSP)

**Rule:** Objects of a superclass should be replaceable with objects of its subclasses without breaking the application.

- Subtypes must be behaviorally compatible with their base types
- Preconditions cannot be strengthened in subtypes
- Postconditions cannot be weakened in subtypes

**Example:**
```python
# Bad: Square violates LSP when inheriting from Rectangle
class Rectangle:
    def set_width(self, w): self.width = w
    def set_height(self, h): self.height = h
    def area(self): return self.width * self.height

class Square(Rectangle):
    def set_width(self, w):
        self.width = w
        self.height = w  # Violates LSP: changes behavior unexpectedly

# Good: Use composition or separate hierarchies
class Shape:
    def area(self): pass

class Rectangle(Shape):
    def __init__(self, width, height):
        self.width = width
        self.height = height
    def area(self): return self.width * self.height

class Square(Shape):
    def __init__(self, side):
        self.side = side
    def area(self): return self.side ** 2
```

### Interface Segregation Principle (ISP)

**Rule:** Clients should not be forced to depend on interfaces they don't use.

- Many specific interfaces are better than one general-purpose interface
- Split large interfaces into smaller, more focused ones
- Avoid "fat" interfaces with unrelated methods

**Example:**
```python
# Bad: Fat interface forces clients to implement unused methods
class Worker:
    def work(self): pass
    def eat(self): pass
    def sleep(self): pass

# Good: Segregated interfaces
class Workable:
    def work(self): pass

class Eatable:
    def eat(self): pass

class Sleepable:
    def sleep(self): pass

class Human(Workable, Eatable, Sleepable):
    def work(self): pass
    def eat(self): pass
    def sleep(self): pass

class Robot(Workable):  # Only implements what it needs
    def work(self): pass
```

### Dependency Inversion Principle (DIP)

**Rule:** High-level modules should not depend on low-level modules. Both should depend on abstractions.

- Depend on abstractions (interfaces), not concretions (implementations)
- Abstractions should not depend on details; details should depend on abstractions
- Use dependency injection to wire dependencies at runtime

**Example:**
```python
# Bad: High-level module depends on low-level implementation
class EmailSender:
    def send(self, message): pass

class NotificationService:
    def __init__(self):
        self.sender = EmailSender()  # Hard dependency on concrete class

# Good: Depend on abstraction
class MessageSender:  # Abstract interface
    def send(self, message): pass

class EmailSender(MessageSender):
    def send(self, message): pass

class SMSSender(MessageSender):
    def send(self, message): pass

class NotificationService:
    def __init__(self, sender: MessageSender):  # Depends on abstraction
        self.sender = sender
```

---

## Domain-Driven Design (DDD)

### Ubiquitous Language

**Rule:** Use the same terminology in code as business stakeholders use.

- Bridge the gap between technical and domain experts
- Classes, methods, variables reflect domain concepts
- Reduces translation errors and misunderstandings

**Example:**
```python
# Good: Code reflects business domain
class Order:
    def place(self): pass
    def fulfill(self): pass
    def cancel(self): pass
    def calculate_total(self): pass

class Customer:
    def place_order(self, order): pass
    def has_credit_limit(self): pass
```

### Bounded Contexts

**Rule:** Explicitly define boundaries where a particular domain model applies.

- Different contexts may have different models for the same concept
- Clear boundaries prevent model pollution
- Enable autonomous teams and microservices

**Example:**
```
Bounded Context: Sales
- Customer (contact info, purchase history)
- Order (items, pricing, payment)

Bounded Context: Shipping
- Customer (delivery address)
- Shipment (tracking, carrier, status)

Bounded Context: Support
- Customer (support tickets, satisfaction)
```

### Entities and Value Objects

**Entities:**
- Have identity that persists over time
- Mutable
- Tracked by unique identifier

```python
class User:
    def __init__(self, id, email):
        self.id = id  # Identity
        self.email = email

    def __eq__(self, other):
        return self.id == other.id  # Equality by identity
```

**Value Objects:**
- Defined by their attributes, not identity
- Immutable
- Interchangeable if attributes match

```python
from dataclasses import dataclass

@dataclass(frozen=True)  # Immutable
class Money:
    amount: float
    currency: str

    def add(self, other):
        if self.currency != other.currency:
            raise ValueError("Cannot add different currencies")
        return Money(self.amount + other.amount, self.currency)
```

### Aggregates

**Rule:** Cluster entities and value objects into aggregates with clear boundaries and a root entity.

- Only the aggregate root is accessible from outside
- Enforce invariants and business rules
- Transaction boundaries align with aggregate boundaries

```python
class Order:  # Aggregate Root
    def __init__(self, id):
        self.id = id
        self._line_items = []

    def add_item(self, product, quantity):
        # Enforce business rules
        if quantity <= 0:
            raise ValueError("Quantity must be positive")
        self._line_items.append(LineItem(product, quantity))

    def remove_item(self, item_id):
        # All modifications go through the root
        self._line_items = [i for i in self._line_items if i.id != item_id]

class LineItem:  # Not accessible outside Order
    def __init__(self, product, quantity):
        self.product = product
        self.quantity = quantity
```

### Repositories

**Rule:** Use repositories to abstract data persistence and retrieval.

- Provide collection-like interface for aggregates
- Separate domain logic from persistence concerns
- One repository per aggregate root

```python
class OrderRepository:
    def find_by_id(self, order_id) -> Order: pass
    def save(self, order: Order): pass
    def find_by_customer(self, customer_id) -> List[Order]: pass
```

### Domain Services

**Rule:** When an operation doesn't naturally belong to an entity or value object, use a domain service.

- Stateless operations
- Operate on multiple domain objects
- Implement domain logic, not infrastructure concerns

```python
class PricingService:
    def calculate_order_total(self, order: Order, discount_policy: DiscountPolicy) -> Money:
        subtotal = sum(item.calculate_price() for item in order.items)
        discount = discount_policy.calculate_discount(order)
        return subtotal - discount
```

---

## Modularity and Separation of Concerns

### Layered Architecture

**Rule:** Organize code into layers with clear responsibilities and dependencies flowing in one direction.

**Standard Layers:**
1. **Presentation Layer** (UI, API controllers)
   - User interaction
   - Input validation
   - Response formatting

2. **Application Layer** (Use cases, application services)
   - Orchestrate domain logic
   - Transaction boundaries
   - Application-specific workflows

3. **Domain Layer** (Business logic)
   - Core business rules
   - Domain entities, value objects
   - Domain services

4. **Infrastructure Layer** (Data access, external services)
   - Database access
   - External API clients
   - File system operations
   - Message queues

**Dependency Rule:** Inner layers should not depend on outer layers.

```
[Presentation] → [Application] → [Domain]
                                     ↑
[Infrastructure] ────────────────────┘
```

### Clean Architecture / Hexagonal Architecture

**Rule:** Isolate business logic from external concerns using ports and adapters.

- **Core Domain:** Business logic, independent of frameworks
- **Ports:** Interfaces defining how to interact with core
- **Adapters:** Implementations connecting core to external systems

```python
# Port (interface)
class OrderRepository:
    def save(self, order): pass
    def find_by_id(self, id): pass

# Adapter (implementation)
class PostgresOrderRepository(OrderRepository):
    def save(self, order):
        # Postgres-specific implementation
        pass

    def find_by_id(self, id):
        # Postgres-specific implementation
        pass

# Domain layer uses port, not adapter
class OrderService:
    def __init__(self, repository: OrderRepository):
        self.repository = repository  # Depends on abstraction
```

### Package by Feature, Not Layer

**Rule:** Organize code by business capabilities, not technical layers.

**Anti-pattern (package by layer):**
```
src/
  controllers/
    UserController
    OrderController
  services/
    UserService
    OrderService
  repositories/
    UserRepository
    OrderRepository
```

**Better (package by feature):**
```
src/
  users/
    UserController
    UserService
    UserRepository
    User (entity)
  orders/
    OrderController
    OrderService
    OrderRepository
    Order (entity)
```

**Benefits:**
- Related code stays together
- Easier to find everything about a feature
- Facilitates modular extraction (e.g., to microservices)
- Clearer bounded contexts

---

## Dependency Management

### Dependency Injection

**Rule:** Provide dependencies from the outside rather than creating them internally.

**Benefits:**
- Loose coupling
- Easier testing (inject mocks/stubs)
- Runtime flexibility

```python
# Bad: Hard dependencies
class OrderService:
    def __init__(self):
        self.repository = PostgresOrderRepository()  # Hard-coded
        self.email = SmtpEmailService()

# Good: Dependencies injected
class OrderService:
    def __init__(self, repository: OrderRepository, email: EmailService):
        self.repository = repository
        self.email = email

# Wiring at application entry point
repository = PostgresOrderRepository(connection_string)
email = SmtpEmailService(smtp_config)
service = OrderService(repository, email)
```

### Circular Dependencies

**Rule:** Avoid circular dependencies between modules.

**Detection:** If module A imports B and B imports A, you have a circular dependency.

**Solutions:**
1. **Introduce abstraction:** Create an interface both can depend on
2. **Merge modules:** If they're tightly coupled, make them one module
3. **Extract common code:** Move shared logic to a third module
4. **Use events:** Decouple with pub/sub pattern

```python
# Bad: Circular dependency
# user.py
from order import Order
class User:
    def place_order(self): return Order(self)

# order.py
from user import User
class Order:
    def __init__(self, user: User): pass

# Good: Use abstraction
# interfaces.py
class UserInterface:
    pass

# user.py
from interfaces import UserInterface
class User(UserInterface):
    pass

# order.py
from interfaces import UserInterface
class Order:
    def __init__(self, user: UserInterface): pass
```

---

## Design Patterns

### Prefer Composition Over Inheritance

**Rule:** Favor object composition (has-a) over class inheritance (is-a).

- Inheritance creates tight coupling
- Composition provides flexibility
- Avoid deep inheritance hierarchies

```python
# Bad: Inheritance hierarchy becomes rigid
class Employee:
    def calculate_pay(self): pass

class Manager(Employee):
    def calculate_pay(self): pass
    def manage_team(self): pass

# What if we need a TemporaryManager?
# What if an Employee becomes a Manager?

# Good: Composition
class Employee:
    def __init__(self, pay_calculator, role):
        self.pay_calculator = pay_calculator
        self.role = role

    def calculate_pay(self):
        return self.pay_calculator.calculate(self)

class ManagerRole:
    def manage_team(self): pass

# Flexible: change pay calculator or role at runtime
employee = Employee(SalaryCalculator(), ManagerRole())
```

### Use Design Patterns Appropriately

**Common Patterns:**

- **Factory:** Create objects without specifying exact class
- **Builder:** Construct complex objects step by step
- **Singleton:** Ensure only one instance exists (use sparingly)
- **Strategy:** Encapsulate algorithms, make them interchangeable
- **Observer:** Notify multiple objects of state changes
- **Repository:** Abstract data persistence
- **Adapter:** Make incompatible interfaces compatible

**Anti-pattern:** Don't force patterns where they don't fit. Use them to solve specific problems, not as a goal.

---

## Architectural Decision Records (ADRs)

**Rule:** Document significant architectural decisions.

**Format:**
```markdown
# ADR-001: Use PostgreSQL for Primary Database

## Status
Accepted

## Context
Need to choose a database for order management system with ACID requirements.

## Decision
Use PostgreSQL as the primary relational database.

## Consequences
**Positive:**
- Strong ACID guarantees
- Rich query capabilities
- Mature ecosystem

**Negative:**
- Vertical scaling limitations
- Need to manage schema migrations

## Alternatives Considered
- MongoDB: Rejected due to weak consistency guarantees
- MySQL: Close second, chose Postgres for better JSON support
```

---

## Key Principles Summary

1. **Single Responsibility:** One reason to change
2. **Open/Closed:** Open for extension, closed for modification
3. **Liskov Substitution:** Subtypes must be substitutable for base types
4. **Interface Segregation:** Many specific interfaces over one general
5. **Dependency Inversion:** Depend on abstractions, not implementations
6. **Ubiquitous Language:** Code reflects domain terminology
7. **Bounded Contexts:** Explicit boundaries for domain models
8. **Layered Architecture:** Clear separation with one-way dependencies
9. **Dependency Injection:** Provide dependencies from outside
10. **Composition over Inheritance:** Favor has-a over is-a
11. **Package by Feature:** Organize by business capability
12. **Document Decisions:** Use ADRs for significant choices

---

**Related Rules:**
- See `base/12-factor-app.md` for SaaS architecture principles
- See `base/refactoring-patterns.md` for code improvement techniques
- See `base/code-quality.md` for general quality standards
