# Architecture Principles

Universal architectural guidelines for building maintainable, scalable, and robust software systems.

## SOLID Principles

| Principle | Rule | Good Example | Bad Example |
|-----------|------|--------------|-------------|
| **Single Responsibility (SRP)** | One reason to change | `UserRepository`, `EmailService`, `ReportGenerator` as separate classes | `UserManager` handling users, emails, and reports |
| **Open/Closed (OCP)** | Open for extension, closed for modification | Strategy pattern with `PaymentProcessor` accepting different strategies | Adding if/else for each payment type |
| **Liskov Substitution (LSP)** | Subtypes substitutable for base types | `Rectangle` and `Square` both extend `Shape` independently | `Square` extending `Rectangle` and breaking width/height contract |
| **Interface Segregation (ISP)** | Many specific > one general | `Workable`, `Eatable` interfaces combined as needed | `Worker` interface forcing robots to implement `eat()` |
| **Dependency Inversion (DIP)** | Depend on abstractions | Inject `MessageSender` interface | Hardcode `EmailSender` in constructor |

### SOLID Implementation Examples

```python
# SRP: Single responsibility
class UserRepository:
    def create_user(self, data): pass

class EmailService:
    def send_email(self, user): pass

# OCP: Strategy pattern
class PaymentProcessor:
    def __init__(self, strategy):
        self.strategy = strategy

# LSP: Proper hierarchy
class Shape:
    def area(self): pass

class Rectangle(Shape):
    def __init__(self, width, height):
        self.width = width
        self.height = height

# ISP: Segregated interfaces
class Workable:
    def work(self): pass

class Robot(Workable):  # Only what it needs
    pass

# DIP: Depend on abstraction
class NotificationService:
    def __init__(self, sender: MessageSender):
        self.sender = sender
```

---

## Domain-Driven Design (DDD)

### Core Concepts

| Concept | Purpose | Example |
|---------|---------|---------|
| **Ubiquitous Language** | Code reflects business terminology | `Order.place()`, `Order.fulfill()`, `Order.cancel()` |
| **Bounded Contexts** | Explicit model boundaries | Sales Context (Customer contact, Order pricing) vs Shipping Context (Customer address, Shipment tracking) |
| **Entities** | Identity-driven, mutable, tracked by ID | `User` with unique ID, compared by ID |
| **Value Objects** | Attribute-driven, immutable | `Money(amount, currency)`, compared by value |
| **Aggregates** | Cluster with root entity | `Order` (root) containing `LineItem` objects |
| **Repositories** | Abstract persistence | `OrderRepository.find_by_id()`, `save()` |

### DDD Implementation

```python
# Entity
class User:
    def __init__(self, id, email):
        self.id = id
    def __eq__(self, other):
        return self.id == other.id

# Value Object
@dataclass(frozen=True)
class Money:
    amount: float
    currency: str
    def add(self, other):
        if self.currency != other.currency:
            raise ValueError("Currency mismatch")
        return Money(self.amount + other.amount, self.currency)

# Aggregate Root
class Order:
    def __init__(self, id):
        self.id = id
        self._line_items = []
    def add_item(self, product, quantity):
        if quantity <= 0:
            raise ValueError("Quantity must be positive")
        self._line_items.append(LineItem(product, quantity))

# Repository
class OrderRepository:
    def find_by_id(self, order_id) -> Order: pass
    def save(self, order: Order): pass
```

---

## Architecture Patterns

### Layered Architecture

```
[Presentation] → [Application] → [Domain]
                                     ↑
[Infrastructure] ────────────────────┘
```

**Layers:**
- **Presentation** - UI, API controllers, input validation
- **Application** - Use cases, workflows, transaction boundaries
- **Domain** - Business logic, entities, domain services
- **Infrastructure** - Database, external APIs, file system

### Hexagonal/Clean Architecture

```python
# Port (interface)
class OrderRepository(ABC):
    def save(self, order): pass

# Adapter (implementation)
class PostgresOrderRepository(OrderRepository):
    def save(self, order):
        # Postgres-specific
        pass

# Domain uses port, not adapter
class OrderService:
    def __init__(self, repository: OrderRepository):
        self.repository = repository
```

### Package by Feature, Not Layer

```
# ❌ Bad: By layer
src/controllers/, services/, repositories/

# ✅ Good: By feature
src/users/UserController, UserService, UserRepository
src/orders/OrderController, OrderService, OrderRepository
```

**Benefits:** Related code together, easier to extract modules

---

## Dependency Management

### Dependency Injection

```python
# ✅ Good: Injected
class OrderService:
    def __init__(self, repository: OrderRepository):
        self.repository = repository

# Wire at entry point
repository = PostgresOrderRepository(connection_string)
service = OrderService(repository)
```

### Avoid Circular Dependencies

**Solutions:** Introduce abstraction, merge modules, extract common code, use events

```python
# Use abstraction
class UserInterface(ABC):
    pass

class Order:
    def __init__(self, user: UserInterface):
        pass
```

---

## Design Patterns

### Composition Over Inheritance

```python
# ✅ Good: Composition
class Employee:
    def __init__(self, pay_calculator, role):
        self.pay_calculator = pay_calculator
        self.role = role
```

### Common Patterns

| Pattern | Purpose | Use Case |
|---------|---------|----------|
| **Factory** | Create objects without specifying exact class | Creating different payment processors |
| **Builder** | Construct complex objects step by step | Building multi-part configurations |
| **Strategy** | Encapsulate algorithms, make interchangeable | Different sorting/calculation methods |
| **Observer** | Notify multiple objects of state changes | Event handling, pub/sub |
| **Repository** | Abstract data persistence | Database access layer |
| **Adapter** | Make incompatible interfaces compatible | Legacy system integration |

---

## Tracer Bullet Development

**Rule:** Build minimal end-to-end implementation first, then add features.

### Tracer Bullets vs Prototyping

| Aspect | Tracer Bullets | Prototyping |
|--------|----------------|-------------|
| **Purpose** | Build skeleton | Explore questions |
| **Code Quality** | Production | Throwaway |
| **Scope** | End-to-end | One area |
| **Evolution** | Grows into system | Discarded |

### When to Use

- Building new system with unfamiliar tech
- Architecture or integration uncertain
- Distributed systems/microservices
- Need early validation

### Implementation: E-Commerce Search Example

**Tracer Bullet (Day 1-2):**

```python
# 1. Database
CREATE TABLE products (id UUID, name VARCHAR(255), price DECIMAL);

# 2. Repository
class ProductRepository:
    def search(self, query: str):
        return db.execute("SELECT * FROM products WHERE name ILIKE %s LIMIT 20", (f"%{query}%",)).fetchall()

# 3. Service
class SearchService:
    def search(self, query: str):
        return self.product_repo.search(query)

# 4. API
@app.get("/api/search")
def search(q: str):
    return {"results": search_service.search(q)}

# 5. UI
<input id="search" />
<div id="results"></div>
```

**Validates:** DB queries, API works, UI submits, results display

**Incremental Enhancement:**

```python
# Week 2: Relevance ranking
def search(self, query: str):
    results = self.product_repo.search(query)
    return sorted(results, key=lambda p: p.sales_count, reverse=True)

# Week 3: Filtering
def search(self, query: str, category: str = None, max_price: float = None):
    return self.product_repo.search(query, category, max_price)

# Week 4: Autocomplete
@app.get("/api/autocomplete")
def autocomplete(q: str):
    return {"suggestions": search_service.get_suggestions(q)}
```

### Development Flow

```
Phase 1: Tracer Bullet (Week 1)
├─ Database: Minimal schema
├─ Repository: One query
├─ Service: Passthrough logic
├─ API: One endpoint
└─ UI: Basic display
Goal: Prove architecture works

Phase 2: Features (Week 2+)
├─ Add related tables
├─ Add CRUD operations
├─ Add business rules
└─ Enhance interface
Goal: Build on proven foundation
```

### Best Practices

| Do | Don't |
|----|-------|
| Keep minimal | Make tracer too complex |
| Production quality from start | Build throwaway code |
| Touch all layers | Skip layers |
| Test end-to-end | Skip integration validation |

---

## AI/ML Architecture

### ML Bounded Contexts

```
Model Training Context:
  - TrainingJob, Experiment, Hyperparameters, Metrics

Feature Engineering Context:
  - FeaturePipeline, Transformation, FeatureDefinition

Model Serving Context:
  - Endpoint, ModelVersion, PredictionRequest/Response
```

### ML Patterns

```python
# Separate responsibilities
class DataLoader:
    def load(self, source) -> Dataset: pass

class FeatureEngineer:
    def transform(self, data) -> Features: pass

class ModelTrainer:
    def train(self, features, labels) -> Model: pass

# Model Registry
class ModelRegistry:
    def register_model(self, model: Model, metadata: ModelMetadata) -> ModelVersion:
        version = self._generate_version(metadata)
        self.storage.save(model, version)
        self.metadata_db.insert({
            'version': version,
            'metrics': metadata.metrics,
            'training_date': datetime.utcnow(),
        })
        return ModelVersion(version, metadata)

# Feature Store
class FeatureStore:
    def __init__(self, online_store, offline_store):
        self.online_store = online_store  # Low-latency serving
        self.offline_store = offline_store  # Historical training

    def get_online_features(self, entity_ids, feature_names) -> Features:
        return self.online_store.fetch(entity_ids, feature_names)
```

---

## Architectural Decision Records (ADRs)

**Format:**

```markdown
# ADR-001: Use PostgreSQL for Primary Database

## Status
Accepted

## Context
Need database for order management with ACID requirements.

## Decision
Use PostgreSQL as primary relational database.

## Consequences
**Positive:** Strong ACID guarantees, rich query capabilities
**Negative:** Vertical scaling limitations, schema migration management
```

---

## Quick Reference

### Key Principles

1. **Single Responsibility** - One reason to change
2. **Open/Closed** - Open for extension, closed for modification
3. **Liskov Substitution** - Subtypes must be substitutable
4. **Interface Segregation** - Many specific > one general
5. **Dependency Inversion** - Depend on abstractions
6. **Ubiquitous Language** - Code reflects domain
7. **Bounded Contexts** - Explicit model boundaries
8. **Dependency Injection** - Provide from outside
9. **Composition > Inheritance** - Favor has-a over is-a
10. **Package by Feature** - Organize by business capability
11. **Tracer Bullets** - Build end-to-end skeleton first

### Related Resources

- `base/12-factor-app.md` - SaaS architecture
- `base/refactoring-patterns.md` - Improvement techniques
- `base/code-quality.md` - Quality standards
- `base/lean-development.md` - Progressive Enhancement vs Tracer Bullets
