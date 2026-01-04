# Architecture Principles
<!-- TIP: Design for change - make it easy to evolve -->

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

## Tracer Bullet Development

**Also known as:** Steel Thread, Walking Skeleton, End-to-End Slice

**Rule:** Build a minimal but complete end-to-end implementation first, then add features incrementally.

### What Are Tracer Bullets?

The term comes from military tracer ammunition: bullets loaded at intervals that leave a visible trail, allowing gunners to see if they're hitting their target and adjust their aim in real-time.

In software development, tracer bullets mean building a **thin vertical slice** that connects all architectural layers immediately:

```
User Interface → API Layer → Business Logic → Data Access → Database
```

**Key Characteristics:**
- **Production Quality:** Not throwaway prototype code
- **End-to-End:** Touches all architectural layers
- **Minimal but Complete:** Simplest possible implementation
- **Incremental:** Foundation that grows with additional features
- **Visible:** Stakeholders can see and interact with real functionality

### Tracer Bullets vs. Prototyping

| Aspect | Tracer Bullets | Prototyping |
|--------|----------------|-------------|
| **Purpose** | Build architectural skeleton | Explore specific questions |
| **Code Quality** | Production-ready | Throwaway code |
| **Scope** | End-to-end through all layers | Focused on one area |
| **Evolution** | Grows into final system | Discarded after learning |
| **Goal** | Validate architecture works | Answer design questions |

### When to Use Tracer Bullets

**Use tracer bullets when:**
- Building new systems with unfamiliar technology
- Architecture or integration points are uncertain
- Need early feedback on technical feasibility
- Working with distributed systems or microservices
- Team needs confidence in the technical approach

**Example scenarios:**
- New mobile app with cloud backend
- Microservices architecture for existing monolith
- Real-time data pipeline integration
- Third-party API integration with complex flows

### Implementation Approach

#### Step 1: Identify the Simplest Path

```python
# Goal: User Dashboard showing account balance
# Tracer Bullet: Hardcoded balance, minimal UI, basic auth

# 1. Database Layer (simplest schema)
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255),
    balance DECIMAL(10,2) DEFAULT 0
);

# 2. Data Access Layer (single query)
class UserRepository:
    def get_balance(self, user_id: str) -> Decimal:
        return db.execute(
            "SELECT balance FROM users WHERE id = %s",
            (user_id,)
        ).scalar()

# 3. Business Logic Layer (no rules yet)
class AccountService:
    def __init__(self, user_repo: UserRepository):
        self.user_repo = user_repo

    def get_user_balance(self, user_id: str) -> Decimal:
        # No business logic yet, direct passthrough
        return self.user_repo.get_balance(user_id)

# 4. API Layer (single endpoint)
from fastapi import FastAPI, Depends

app = FastAPI()

@app.get("/api/balance")
def get_balance(user_id: str, service: AccountService = Depends()):
    balance = service.get_user_balance(user_id)
    return {"balance": float(balance)}

# 5. UI Layer (minimal display)
async function showBalance() {
    const response = await fetch('/api/balance?user_id=123');
    const data = await response.json();
    document.getElementById('balance').textContent = `$${data.balance}`;
}
```

**Result:** Complete end-to-end flow from UI to database and back. Simple, but it works.

#### Step 2: Verify Integration Points

```bash
# Test the entire stack
curl http://localhost:8000/api/balance?user_id=123
# Response: {"balance": 1250.50}

# Validates:
# ✓ Database connection works
# ✓ API routing works
# ✓ Authentication flow works (basic)
# ✓ UI can call API
# ✓ Data serialization works
```

#### Step 3: Incrementally Add Features

```python
# Iteration 1: Add transaction history (extend existing layers)

# Database: Add transactions table
CREATE TABLE transactions (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    amount DECIMAL(10,2),
    created_at TIMESTAMP
);

# Repository: Add method
class UserRepository:
    def get_balance(self, user_id: str) -> Decimal:
        # ... existing code ...

    def get_transactions(self, user_id: str, limit: int = 10):
        return db.execute(
            "SELECT * FROM transactions WHERE user_id = %s ORDER BY created_at DESC LIMIT %s",
            (user_id, limit)
        ).fetchall()

# Service: Add method
class AccountService:
    def get_user_balance(self, user_id: str) -> Decimal:
        # ... existing code ...

    def get_recent_transactions(self, user_id: str):
        return self.user_repo.get_transactions(user_id)

# API: Add endpoint
@app.get("/api/transactions")
def get_transactions(user_id: str, service: AccountService = Depends()):
    transactions = service.get_recent_transactions(user_id)
    return {"transactions": transactions}

# UI: Add display
async function showTransactions() {
    const response = await fetch('/api/transactions?user_id=123');
    const data = await response.json();
    // Render transactions...
}
```

### Tracer Bullet Development Flow

```
Phase 1: Tracer Bullet (Week 1)
├─ Database: Single table, minimal schema
├─ Repository: One query method
├─ Service: Passthrough logic
├─ API: One endpoint
└─ UI: Basic display

Goal: Prove all layers connect and work together

Phase 2: Feature Addition (Week 2)
├─ Database: Add related tables
├─ Repository: Add CRUD operations
├─ Service: Add business logic
├─ API: Add endpoints for new features
└─ UI: Enhanced interface

Goal: Build on proven foundation

Phase 3: Refinement (Week 3+)
├─ Database: Optimize queries, add indexes
├─ Repository: Add caching, error handling
├─ Service: Complex business rules
├─ API: Validation, rate limiting
└─ UI: Polish, accessibility
```

### Real-World Example: E-Commerce Search

**Full Vision:**
- Natural language search
- AI-powered recommendations
- Faceted filtering
- Autocomplete
- Search analytics
- Personalization

**Tracer Bullet (Day 1-2):**

```python
# 1. Database: Minimal product table
CREATE TABLE products (
    id UUID PRIMARY KEY,
    name VARCHAR(255),
    price DECIMAL(10,2)
);

# 2. Repository: Simple keyword search
class ProductRepository:
    def search(self, query: str):
        return db.execute(
            "SELECT * FROM products WHERE name ILIKE %s LIMIT 20",
            (f"%{query}%",)
        ).fetchall()

# 3. Service: No ranking, just return results
class SearchService:
    def __init__(self, product_repo: ProductRepository):
        self.product_repo = product_repo

    def search(self, query: str):
        return self.product_repo.search(query)

# 4. API: Single search endpoint
@app.get("/api/search")
def search(q: str, service: SearchService = Depends()):
    results = service.search(q)
    return {"results": results}

# 5. UI: Basic search box
<input id="search" type="text" />
<div id="results"></div>

<script>
async function search(query) {
    const response = await fetch(`/api/search?q=${query}`);
    const data = await response.json();
    displayResults(data.results);
}
</script>
```

**Tracer Bullet Validates:**
- ✓ Database queries work
- ✓ API handles requests
- ✓ UI can submit searches
- ✓ Results display correctly
- ✓ End-to-end latency is acceptable

**Incremental Enhancement:**

```python
# Week 2: Add relevance ranking
class SearchService:
    def search(self, query: str):
        results = self.product_repo.search(query)
        # Add ranking by sales
        return sorted(results, key=lambda p: p.sales_count, reverse=True)

# Week 3: Add faceted filtering
class SearchService:
    def search(self, query: str, category: str = None, max_price: float = None):
        results = self.product_repo.search(query, category, max_price)
        return self._rank_results(results)

# Week 4: Add autocomplete
@app.get("/api/autocomplete")
def autocomplete(q: str):
    suggestions = search_service.get_suggestions(q)
    return {"suggestions": suggestions}
```

### Benefits of Tracer Bullets

**1. Early Risk Reduction**
- Integration problems discovered immediately
- Technical feasibility validated early
- Architecture proven before heavy investment

**2. Visible Progress**
- Stakeholders see working software from day one
- Demonstrates value quickly
- Builds team confidence

**3. Easier Debugging**
- Problems isolated to single layer
- Clear understanding of what changed
- Incremental additions easier to troubleshoot

**4. Better Estimates**
- Real data on implementation velocity
- Understand actual complexity
- More accurate future planning

**5. Flexible Direction**
- Easy to pivot based on feedback
- Architecture adjustments less costly
- Features added based on real needs

### Common Mistakes

**❌ Making the tracer too complex:**
```python
# Bad: Trying to build too much in tracer bullet
class UserService:
    def create_user(self, data):
        # Validation with 20 rules
        # Email verification
        # Password strength checking
        # Profile picture upload
        # Welcome email with templates
        # Analytics tracking
        # ... too much for initial tracer!
```

**✅ Keep it minimal:**
```python
# Good: Simplest possible implementation
class UserService:
    def create_user(self, email: str, password: str):
        # Just prove create user flow works
        user = User(email=email, password_hash=hash(password))
        return self.user_repo.save(user)

# Add validation, emails, etc. in iterations 2, 3, 4...
```

**❌ Building throwaway code:**
```python
# Bad: Prototype mindset
def search(query):
    # Quick hack, will rewrite later
    return [{"name": "Fake Product"}]  # Hardcoded
```

**✅ Production-quality from start:**
```python
# Good: Simple but real implementation
def search(query: str) -> List[Product]:
    # Real database query, simple logic
    return self.product_repo.search(query)
```

### Integration with Other Practices

**Tracer Bullets + TDD:**
```python
# Write tests for tracer bullet first
def test_search_end_to_end():
    """Test complete search flow"""
    # Setup
    product_repo.create(Product(name="Laptop"))

    # Execute: UI → API → Service → Repository → DB
    response = client.get("/api/search?q=laptop")

    # Verify
    assert response.status_code == 200
    assert len(response.json()["results"]) > 0
    assert "Laptop" in response.json()["results"][0]["name"]
```

**Tracer Bullets + Agile:**
```
Sprint 1: Tracer bullet (end-to-end minimal feature)
Sprint 2: Add feature A (extend all layers)
Sprint 3: Add feature B (extend all layers)
Sprint 4: Polish and optimize
```

**Tracer Bullets + Microservices:**
```
Service A (Auth) ──┐
                   ├─→ API Gateway ──→ UI
Service B (Data) ──┘

Tracer: Single request through all services
Iteration: Add endpoints, error handling, retry logic
```

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
12. **Tracer Bullets:** Build end-to-end skeleton first, then enhance
13. **Document Decisions:** Use ADRs for significant choices

---

## Architectural Principles for AI Systems

### SOLID Principles for AI/ML

Traditional SOLID principles apply to AI systems with unique considerations for model lifecycle, data pipelines, and inference services.

#### Single Responsibility in ML

Each component handles one aspect of the ML workflow.

```python
# Bad: God class handling everything
class MLPipeline:
    def load_data(self): pass
    def preprocess(self): pass
    def train_model(self): pass
    def evaluate(self): pass
    def deploy(self): pass
    def monitor(self): pass
    def retrain(self): pass

# Good: Separate responsibilities
class DataLoader:
    """Responsible only for data loading"""
    def load(self, source: str) -> Dataset:
        return Dataset.from_source(source)

class FeatureEngineer:
    """Responsible only for feature transformation"""
    def transform(self, data: Dataset) -> Features:
        return self.pipeline.transform(data)

class ModelTrainer:
    """Responsible only for model training"""
    def train(self, features: Features, labels: Labels) -> Model:
        return self.algorithm.fit(features, labels)

class ModelEvaluator:
    """Responsible only for model evaluation"""
    def evaluate(self, model: Model, test_data: Dataset) -> Metrics:
        predictions = model.predict(test_data.features)
        return calculate_metrics(predictions, test_data.labels)

class ModelDeployer:
    """Responsible only for deployment"""
    def deploy(self, model: Model, environment: str) -> Endpoint:
        return self.deployment_service.deploy(model, environment)
```

#### Open/Closed Principle for ML Models

Design systems extensible to new model types without modifying existing code.

```python
# Interface for model abstraction
class ModelInterface:
    def train(self, features, labels): pass
    def predict(self, features): pass
    def save(self, path): pass
    def load(self, path): pass

# Concrete implementations
class RandomForestModel(ModelInterface):
    def __init__(self):
        self.model = RandomForestClassifier()

    def train(self, features, labels):
        self.model.fit(features, labels)

    def predict(self, features):
        return self.model.predict(features)

class NeuralNetworkModel(ModelInterface):
    def __init__(self):
        self.model = self._build_network()

    def train(self, features, labels):
        self.model.fit(features, labels, epochs=10)

    def predict(self, features):
        return self.model.predict(features)

# Model trainer works with any model implementation
class ModelTrainer:
    def __init__(self, model: ModelInterface):
        self.model = model  # Open for extension, closed for modification

    def train_and_evaluate(self, train_data, test_data):
        self.model.train(train_data.features, train_data.labels)
        return self.model.predict(test_data.features)

# Add new models without changing ModelTrainer
trainer = ModelTrainer(RandomForestModel())
# or
trainer = ModelTrainer(NeuralNetworkModel())
# or
trainer = ModelTrainer(GradientBoostingModel())  # New model type
```

#### Dependency Inversion for ML Infrastructure

Depend on abstractions for data sources, model storage, and inference endpoints.

```python
# Abstract interfaces
class DataSource:
    def load(self, query: str) -> DataFrame: pass

class ModelStore:
    def save(self, model, version: str): pass
    def load(self, version: str) -> Model: pass

class FeatureStore:
    def get_features(self, entity_ids: List[str]) -> Features: pass

# Concrete implementations
class S3DataSource(DataSource):
    def __init__(self, bucket: str):
        self.bucket = bucket

    def load(self, query: str) -> DataFrame:
        # S3-specific loading logic
        return pd.read_parquet(f's3://{self.bucket}/{query}')

class PostgresDataSource(DataSource):
    def __init__(self, connection_string: str):
        self.conn = create_connection(connection_string)

    def load(self, query: str) -> DataFrame:
        return pd.read_sql(query, self.conn)

# High-level ML service depends on abstractions
class MLPipeline:
    def __init__(
        self,
        data_source: DataSource,  # Abstraction
        model_store: ModelStore,   # Abstraction
        feature_store: FeatureStore  # Abstraction
    ):
        self.data_source = data_source
        self.model_store = model_store
        self.feature_store = feature_store

    def train(self, query: str, model_version: str):
        # Works with any implementation
        data = self.data_source.load(query)
        features = self.feature_store.get_features(data['id'])
        model = train_model(features, data['labels'])
        self.model_store.save(model, model_version)

# Dependency injection at composition root
pipeline = MLPipeline(
    data_source=S3DataSource('ml-training-data'),
    model_store=MLFlowModelStore(),
    feature_store=FeastFeatureStore()
)
```

### Clean Architecture for AI Systems

Apply hexagonal architecture to isolate ML domain logic from infrastructure concerns.

```
┌─────────────────────────────────────────────────────┐
│                  Presentation Layer                 │
│         (REST API, Batch Jobs, Notebooks)           │
└────────────────────┬────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────┐
│               Application Layer                     │
│     (ML Use Cases, Training Workflows, Inference)   │
└────────────────────┬────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────┐
│                  Domain Layer                       │
│  (ML Algorithms, Feature Engineering, Evaluation)   │
│           ▲                  ▲                      │
│           │                  │                      │
│      ┌────┴──────┐      ┌───┴──────┐               │
│      │   Ports   │      │  Ports   │               │
└──────┴───────────┴──────┴──────────┴───────────────┘
           │                  │
┌──────────▼──────────────────▼───────────────────────┐
│              Infrastructure Layer                    │
│  (S3, DynamoDB, SageMaker, MLFlow, Feature Store)   │
└─────────────────────────────────────────────────────┘
```

**Implementation:**

```python
# Domain Layer - Core ML Logic
class MLModel:
    """Domain entity representing an ML model"""
    def __init__(self, version: str, algorithm: str, metrics: dict):
        self.version = version
        self.algorithm = algorithm
        self.metrics = metrics
        self.created_at = datetime.utcnow()

    def is_better_than(self, other: 'MLModel') -> bool:
        """Domain logic for comparing models"""
        return self.metrics['accuracy'] > other.metrics['accuracy']

# Ports - Interfaces
class ModelRepository:
    """Port for model persistence"""
    def save(self, model: MLModel): pass
    def load(self, version: str) -> MLModel: pass
    def list_versions(self) -> List[str]: pass

class TrainingDataSource:
    """Port for training data"""
    def fetch_training_batch(self, size: int) -> TrainingData: pass

# Application Layer - Use Cases
class TrainModelUseCase:
    """Application service orchestrating ML training"""
    def __init__(
        self,
        data_source: TrainingDataSource,
        model_repo: ModelRepository
    ):
        self.data_source = data_source
        self.model_repo = model_repo

    def execute(self, algorithm: str, hyperparams: dict) -> MLModel:
        # Orchestrate domain logic
        training_data = self.data_source.fetch_training_batch(1000)

        # Train model (domain logic)
        model = train_algorithm(algorithm, hyperparams, training_data)

        # Evaluate (domain logic)
        metrics = evaluate_model(model, training_data.validation_set)

        # Create domain entity
        ml_model = MLModel(
            version=generate_version(),
            algorithm=algorithm,
            metrics=metrics
        )

        # Persist through port
        self.model_repo.save(ml_model)

        return ml_model

# Infrastructure Layer - Adapters
class S3ModelRepository(ModelRepository):
    """Adapter for S3 storage"""
    def __init__(self, bucket: str):
        self.bucket = bucket
        self.s3_client = boto3.client('s3')

    def save(self, model: MLModel):
        # S3-specific implementation
        model_bytes = pickle.dumps(model)
        self.s3_client.put_object(
            Bucket=self.bucket,
            Key=f'models/{model.version}.pkl',
            Body=model_bytes
        )

    def load(self, version: str) -> MLModel:
        obj = self.s3_client.get_object(
            Bucket=self.bucket,
            Key=f'models/{version}.pkl'
        )
        return pickle.loads(obj['Body'].read())

class DataWarehouseTrainingDataSource(TrainingDataSource):
    """Adapter for data warehouse"""
    def __init__(self, connection_string: str):
        self.conn = create_connection(connection_string)

    def fetch_training_batch(self, size: int) -> TrainingData:
        query = f"SELECT * FROM training_data ORDER BY RANDOM() LIMIT {size}"
        df = pd.read_sql(query, self.conn)
        return TrainingData.from_dataframe(df)

# Presentation Layer - API
from fastapi import FastAPI

app = FastAPI()

# Dependency injection at composition root
def get_train_use_case() -> TrainModelUseCase:
    data_source = DataWarehouseTrainingDataSource(
        os.environ['DATABASE_URL']
    )
    model_repo = S3ModelRepository(
        os.environ['MODEL_BUCKET']
    )
    return TrainModelUseCase(data_source, model_repo)

@app.post("/models/train")
def train_model(request: TrainRequest):
    use_case = get_train_use_case()
    model = use_case.execute(
        algorithm=request.algorithm,
        hyperparams=request.hyperparams
    )
    return {"version": model.version, "metrics": model.metrics}
```

### Domain-Driven Design for AI Systems

Apply DDD concepts to ML domain modeling.

#### ML Bounded Contexts

```
Bounded Context: Model Training
- Entities: TrainingJob, Experiment, Hyperparameters
- Value Objects: Metrics, DataSplit
- Aggregates: Experiment (root) → TrainingJob
- Repository: ExperimentRepository

Bounded Context: Feature Engineering
- Entities: FeaturePipeline, Transformation
- Value Objects: FeatureDefinition, Statistics
- Aggregates: FeaturePipeline (root) → Transformation
- Repository: FeatureRepository

Bounded Context: Model Serving
- Entities: Endpoint, ModelVersion
- Value Objects: PredictionRequest, PredictionResponse
- Aggregates: Endpoint (root) → ModelVersion
- Repository: EndpointRepository

Bounded Context: Data Quality
- Entities: DataValidation, QualityCheck
- Value Objects: ValidationRule, QualityMetric
- Aggregates: DataValidation (root) → QualityCheck
- Repository: ValidationRepository
```

#### ML Ubiquitous Language

```python
# Code reflects ML domain terminology
class Experiment:
    """An ML experiment tracking model variations"""
    def create_run(self, hyperparameters: Hyperparameters) -> ExperimentRun:
        """Create a new experiment run with given hyperparameters"""
        pass

    def compare_runs(self, metric: str) -> List[ExperimentRun]:
        """Compare runs by performance metric"""
        pass

    def select_best_model(self) -> Model:
        """Select the best performing model from experiment runs"""
        pass

class FeaturePipeline:
    """A pipeline for transforming raw data into features"""
    def add_transformation(self, transform: Transformation):
        """Add a feature transformation step"""
        pass

    def fit(self, training_data: DataFrame):
        """Fit the pipeline on training data"""
        pass

    def transform(self, data: DataFrame) -> Features:
        """Transform data into features"""
        pass

class ModelMonitor:
    """Monitor deployed model for drift and performance"""
    def detect_drift(self, reference_data: Dataset, production_data: Dataset) -> DriftReport:
        """Detect data drift between reference and production"""
        pass

    def track_performance(self, predictions: Predictions, actuals: Actuals) -> Metrics:
        """Track model performance over time"""
        pass
```

#### ML Aggregates and Invariants

```python
class ExperimentAggregate:
    """Aggregate root for ML experiment"""
    def __init__(self, experiment_id: str, objective: str):
        self.id = experiment_id
        self.objective = objective  # 'maximize' or 'minimize'
        self._runs: List[ExperimentRun] = []
        self._best_run: Optional[ExperimentRun] = None

    def add_run(self, hyperparameters: dict, metrics: dict) -> ExperimentRun:
        """Add a run and maintain best_run invariant"""
        run = ExperimentRun(
            id=generate_run_id(),
            hyperparameters=hyperparameters,
            metrics=metrics
        )

        # Enforce business rule: track best run
        if self._is_better_run(run):
            self._best_run = run

        self._runs.append(run)
        return run

    def _is_better_run(self, run: ExperimentRun) -> bool:
        """Business logic for comparing runs"""
        if not self._best_run:
            return True

        metric_value = run.metrics.get('accuracy', 0)
        best_metric = self._best_run.metrics.get('accuracy', 0)

        if self.objective == 'maximize':
            return metric_value > best_metric
        else:
            return metric_value < best_metric

    def get_best_model(self) -> Model:
        """Access best model through aggregate root"""
        if not self._best_run:
            raise ValueError("No runs in experiment")
        return self._best_run.model

class ExperimentRun:
    """Entity within Experiment aggregate"""
    def __init__(self, id: str, hyperparameters: dict, metrics: dict):
        self.id = id
        self.hyperparameters = hyperparameters
        self.metrics = metrics
        self.model: Optional[Model] = None
```

#### ML Domain Services

```python
class ModelComparisonService:
    """Domain service for comparing models"""
    def compare_models(
        self,
        model_a: MLModel,
        model_b: MLModel,
        test_data: Dataset
    ) -> ComparisonReport:
        """Compare two models on the same test data"""
        predictions_a = model_a.predict(test_data.features)
        predictions_b = model_b.predict(test_data.features)

        metrics_a = calculate_metrics(predictions_a, test_data.labels)
        metrics_b = calculate_metrics(predictions_b, test_data.labels)

        return ComparisonReport(
            model_a_id=model_a.version,
            model_b_id=model_b.version,
            metrics_a=metrics_a,
            metrics_b=metrics_b,
            winner=self._determine_winner(metrics_a, metrics_b)
        )

class FeatureImportanceService:
    """Domain service for analyzing feature importance"""
    def calculate_importance(
        self,
        model: MLModel,
        features: Features,
        method: str = 'permutation'
    ) -> FeatureImportance:
        """Calculate feature importance using specified method"""
        if method == 'permutation':
            return self._permutation_importance(model, features)
        elif method == 'shap':
            return self._shap_importance(model, features)
        else:
            raise ValueError(f"Unknown method: {method}")
```

### AI-Specific Architectural Patterns

#### Model Registry Pattern

Centralized model versioning and metadata tracking.

```python
class ModelRegistry:
    """Central registry for all models"""
    def __init__(self, storage: ModelStore, metadata_db: MetadataStore):
        self.storage = storage
        self.metadata_db = metadata_db

    def register_model(
        self,
        model: Model,
        metadata: ModelMetadata
    ) -> ModelVersion:
        """Register a new model version with metadata"""
        # Generate semantic version
        version = self._generate_version(metadata)

        # Store model artifact
        self.storage.save(model, version)

        # Store metadata
        self.metadata_db.insert({
            'version': version,
            'algorithm': metadata.algorithm,
            'training_date': datetime.utcnow(),
            'metrics': metadata.metrics,
            'dataset_version': metadata.dataset_version,
            'hyperparameters': metadata.hyperparameters,
            'status': 'registered'
        })

        return ModelVersion(version, metadata)

    def promote_to_production(self, version: str):
        """Promote model version to production"""
        # Business rule: only models with sufficient accuracy
        metadata = self.metadata_db.get(version)
        if metadata['metrics']['accuracy'] < 0.9:
            raise ValueError("Model accuracy below production threshold")

        self.metadata_db.update(version, {'status': 'production'})
        self._deploy_to_production(version)
```

#### Feature Store Pattern

Centralized feature management for training and serving.

```python
class FeatureStore:
    """Centralized feature repository"""
    def __init__(self, online_store: OnlineStore, offline_store: OfflineStore):
        self.online_store = online_store  # Low-latency serving
        self.offline_store = offline_store  # Historical training data

    def register_feature(self, feature_def: FeatureDefinition):
        """Register a new feature with its computation logic"""
        self._validate_feature(feature_def)
        self.online_store.create_table(feature_def)
        self.offline_store.create_table(feature_def)

    def get_online_features(
        self,
        entity_ids: List[str],
        feature_names: List[str]
    ) -> Features:
        """Get features for real-time inference"""
        return self.online_store.fetch(entity_ids, feature_names)

    def get_historical_features(
        self,
        entity_ids: List[str],
        feature_names: List[str],
        timestamp: datetime
    ) -> Features:
        """Get point-in-time features for training"""
        return self.offline_store.fetch_as_of(
            entity_ids,
            feature_names,
            timestamp
        )
```

#### ML Pipeline Pattern

Orchestrate complex ML workflows with clear stages.

```python
class MLPipelineStage:
    """Base class for pipeline stages"""
    def execute(self, input_data: Any) -> Any: pass
    def rollback(self): pass

class DataValidationStage(MLPipelineStage):
    def execute(self, raw_data: DataFrame) -> DataFrame:
        # Validate data quality
        self._check_schema(raw_data)
        self._check_data_quality(raw_data)
        return raw_data

class FeatureEngineeringStage(MLPipelineStage):
    def execute(self, validated_data: DataFrame) -> Features:
        # Transform data to features
        return self.feature_pipeline.transform(validated_data)

class ModelTrainingStage(MLPipelineStage):
    def execute(self, features: Features) -> Model:
        # Train model
        return self.trainer.train(features)

class ModelEvaluationStage(MLPipelineStage):
    def execute(self, model: Model) -> Metrics:
        # Evaluate model
        return self.evaluator.evaluate(model, self.test_data)

# Compose pipeline from stages
class MLPipeline:
    def __init__(self, stages: List[MLPipelineStage]):
        self.stages = stages

    def run(self, input_data: Any) -> Any:
        """Execute pipeline stages in order"""
        data = input_data
        for stage in self.stages:
            try:
                data = stage.execute(data)
            except Exception as e:
                self._handle_failure(stage, e)
                raise

        return data

# Usage
pipeline = MLPipeline([
    DataValidationStage(),
    FeatureEngineeringStage(),
    ModelTrainingStage(),
    ModelEvaluationStage()
])

result = pipeline.run(raw_data)
```

---

**Related Rules:**
- See `base/12-factor-app.md` for SaaS architecture principles
- See `base/refactoring-patterns.md` for code improvement techniques
- See `base/code-quality.md` for general quality standards
- See `base/ai-assisted-development.md` for AI development best practices
- See `cloud/aws/well-architected.md` for AWS Well-Architected Framework for ML
