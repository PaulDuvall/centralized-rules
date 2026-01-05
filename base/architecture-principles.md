# Architecture Principles

Universal architectural guidelines for building maintainable, scalable, and robust software systems.

## SOLID Principles

### Single Responsibility Principle (SRP)

**Rule:** A class should have one, and only one, reason to change.

```python
# ❌ Bad: Multiple responsibilities
class UserManager:
    def create_user(self, data): pass
    def send_email(self, user): pass
    def generate_report(self, user): pass

# ✅ Good: Single responsibility each
class UserRepository:
    def create_user(self, data): pass

class EmailService:
    def send_email(self, user): pass

class ReportGenerator:
    def generate_report(self, user): pass
```

### Open/Closed Principle (OCP)

**Rule:** Open for extension, closed for modification.

```python
# ✅ Good: Strategy pattern
class PaymentProcessor:
    def __init__(self, strategy):
        self.strategy = strategy

    def process(self, amount):
        return self.strategy.process(amount)

# Extend without modifying
class CreditCardStrategy:
    def process(self, amount): pass

class PayPalStrategy:
    def process(self, amount): pass
```

### Liskov Substitution Principle (LSP)

**Rule:** Subtypes must be substitutable for their base types.

```python
# ❌ Bad: Square violates LSP
class Square(Rectangle):
    def set_width(self, w):
        self.width = w
        self.height = w  # Unexpected behavior change

# ✅ Good: Separate hierarchies
class Shape:
    def area(self): pass

class Rectangle(Shape):
    def __init__(self, width, height):
        self.width = width
        self.height = height

class Square(Shape):
    def __init__(self, side):
        self.side = side
```

### Interface Segregation Principle (ISP)

**Rule:** Many specific interfaces > one general-purpose interface.

```python
# ❌ Bad: Fat interface
class Worker:
    def work(self): pass
    def eat(self): pass
    def sleep(self): pass

# ✅ Good: Segregated interfaces
class Workable:
    def work(self): pass

class Eatable:
    def eat(self): pass

class Human(Workable, Eatable):
    pass

class Robot(Workable):  # Only what it needs
    pass
```

### Dependency Inversion Principle (DIP)

**Rule:** Depend on abstractions, not concretions.

```python
# ❌ Bad: Hard dependency
class NotificationService:
    def __init__(self):
        self.sender = EmailSender()  # Concrete

# ✅ Good: Depend on abstraction
class MessageSender(ABC):
    def send(self, message): pass

class NotificationService:
    def __init__(self, sender: MessageSender):
        self.sender = sender
```

---

## Domain-Driven Design (DDD)

### Ubiquitous Language

Use the same terminology in code as business stakeholders use.

```python
class Order:
    def place(self): pass
    def fulfill(self): pass
    def cancel(self): pass
```

### Bounded Contexts

Explicitly define boundaries where a domain model applies.

```
Sales Context:
  - Customer (contact, history)
  - Order (items, pricing)

Shipping Context:
  - Customer (delivery address)
  - Shipment (tracking, status)
```

### Entities vs Value Objects

**Entities:** Have identity, mutable, tracked by ID

```python
class User:
    def __init__(self, id, email):
        self.id = id  # Identity

    def __eq__(self, other):
        return self.id == other.id
```

**Value Objects:** Defined by attributes, immutable

```python
@dataclass(frozen=True)
class Money:
    amount: float
    currency: str

    def add(self, other):
        if self.currency != other.currency:
            raise ValueError("Currency mismatch")
        return Money(self.amount + other.amount, self.currency)
```

### Aggregates

Cluster entities with clear boundaries and root entity.

```python
class Order:  # Aggregate Root
    def __init__(self, id):
        self.id = id
        self._line_items = []

    def add_item(self, product, quantity):
        if quantity <= 0:
            raise ValueError("Quantity must be positive")
        self._line_items.append(LineItem(product, quantity))

class LineItem:  # Not accessible outside Order
    pass
```

### Repositories

Abstract data persistence with collection-like interface.

```python
class OrderRepository:
    def find_by_id(self, order_id) -> Order: pass
    def save(self, order: Order): pass
```

---

## Layered Architecture

**Rule:** Organize into layers with one-way dependencies.

```
[Presentation] → [Application] → [Domain]
                                     ↑
[Infrastructure] ────────────────────┘
```

**Layers:**
1. **Presentation** - UI, API controllers, input validation
2. **Application** - Use cases, workflows, transaction boundaries
3. **Domain** - Business logic, entities, domain services
4. **Infrastructure** - Database, external APIs, file system

---

## Clean/Hexagonal Architecture

**Rule:** Isolate business logic using ports and adapters.

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

---

## Package by Feature, Not Layer

**Anti-pattern:**
```
src/
  controllers/
  services/
  repositories/
```

**Better:**
```
src/
  users/
    UserController
    UserService
    UserRepository
  orders/
    OrderController
    OrderService
    OrderRepository
```

**Benefits:** Related code together, easier to extract modules

---

## Dependency Management

### Dependency Injection

**Rule:** Provide dependencies from outside.

```python
# ❌ Bad: Hard dependencies
class OrderService:
    def __init__(self):
        self.repository = PostgresOrderRepository()

# ✅ Good: Injected
class OrderService:
    def __init__(self, repository: OrderRepository):
        self.repository = repository

# Wire at entry point
repository = PostgresOrderRepository(connection_string)
service = OrderService(repository)
```

### Avoid Circular Dependencies

**Solutions:**
1. Introduce abstraction
2. Merge modules
3. Extract common code
4. Use events

```python
# ✅ Good: Use abstraction
class UserInterface(ABC):
    pass

class User(UserInterface):
    pass

class Order:
    def __init__(self, user: UserInterface):
        pass
```

---

## Design Patterns

### Prefer Composition Over Inheritance

```python
# ❌ Bad: Rigid inheritance
class Manager(Employee):
    pass

# ✅ Good: Composition
class Employee:
    def __init__(self, pay_calculator, role):
        self.pay_calculator = pay_calculator
        self.role = role
```

### Common Patterns

- **Factory** - Create objects without specifying exact class
- **Builder** - Construct complex objects step by step
- **Strategy** - Encapsulate algorithms, make interchangeable
- **Observer** - Notify multiple objects of state changes
- **Repository** - Abstract data persistence
- **Adapter** - Make incompatible interfaces compatible

---

## Tracer Bullet Development

**Also known as:** Steel Thread, Walking Skeleton

**Rule:** Build minimal end-to-end implementation first, then add features.

### What Are Tracer Bullets?

Build a **thin vertical slice** connecting all layers:

```
UI → API → Business Logic → Data Access → Database
```

**Characteristics:**
- Production quality (not throwaway)
- End-to-end (touches all layers)
- Minimal but complete
- Foundation that grows

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
- Need early feedback on feasibility
- Distributed systems/microservices
- Team needs technical confidence

### Implementation Approach

**Step 1: Simplest Path**

```python
# Goal: User dashboard showing balance
# Tracer Bullet: Hardcoded balance, minimal UI, basic auth

# 1. Database
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255),
    balance DECIMAL(10,2) DEFAULT 0
);

# 2. Data Access
class UserRepository:
    def get_balance(self, user_id: str) -> Decimal:
        return db.execute("SELECT balance FROM users WHERE id = %s", (user_id,)).scalar()

# 3. Business Logic
class AccountService:
    def get_user_balance(self, user_id: str) -> Decimal:
        return self.user_repo.get_balance(user_id)

# 4. API
@app.get("/api/balance")
def get_balance(user_id: str):
    balance = service.get_user_balance(user_id)
    return {"balance": float(balance)}

# 5. UI
async function showBalance() {
    const response = await fetch('/api/balance?user_id=123');
    const data = await response.json();
    document.getElementById('balance').textContent = `$${data.balance}`;
}
```

**Result:** Complete flow from UI to DB. Simple, but works.

**Step 2: Verify Integration**

```bash
curl http://localhost:8000/api/balance?user_id=123
# Validates: DB connection, API routing, auth, UI calls, serialization
```

**Step 3: Incremental Enhancement**

```python
# Week 2: Add transaction history
class UserRepository:
    def get_transactions(self, user_id: str, limit: int = 10):
        return db.execute("SELECT * FROM transactions...").fetchall()

# Week 3: Add filtering, pagination
# Week 4: Add export, analytics
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
├─ Add endpoints
└─ Enhance interface
Goal: Build on proven foundation
```

### Real Example: E-Commerce Search

**Vision:** NLP search, AI recommendations, faceted filtering, autocomplete

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

**Validates:** DB queries, API works, UI submits, results display, latency acceptable

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

### Benefits

1. **Early Risk Reduction** - Integration problems found immediately
2. **Visible Progress** - Working software from day one
3. **Easier Debugging** - Problems isolated to single layer
4. **Better Estimates** - Real data on velocity
5. **Flexible Direction** - Easy to pivot

### Common Mistakes

❌ Making tracer too complex
❌ Building throwaway code
❌ Skipping layers
❌ Not validating integration

✅ Keep minimal
✅ Production quality from start
✅ Touch all layers
✅ Test end-to-end

---

## AI-Specific Architecture

### SOLID for ML

```python
# ❌ Bad: God class
class MLPipeline:
    def load_data(self): pass
    def preprocess(self): pass
    def train(self): pass
    def deploy(self): pass

# ✅ Good: Separate responsibilities
class DataLoader:
    def load(self, source) -> Dataset: pass

class FeatureEngineer:
    def transform(self, data) -> Features: pass

class ModelTrainer:
    def train(self, features, labels) -> Model: pass
```

### ML Bounded Contexts

```
Model Training Context:
  - TrainingJob, Experiment, Hyperparameters
  - Metrics, DataSplit

Feature Engineering Context:
  - FeaturePipeline, Transformation
  - FeatureDefinition, Statistics

Model Serving Context:
  - Endpoint, ModelVersion
  - PredictionRequest, PredictionResponse
```

### Model Registry Pattern

```python
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
```

### Feature Store Pattern

```python
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
**Positive:**
- Strong ACID guarantees
- Rich query capabilities

**Negative:**
- Vertical scaling limitations
- Schema migration management
```

---

## Key Principles Summary

1. **Single Responsibility** - One reason to change
2. **Open/Closed** - Open for extension, closed for modification
3. **Liskov Substitution** - Subtypes must be substitutable
4. **Interface Segregation** - Many specific > one general
5. **Dependency Inversion** - Depend on abstractions
6. **Ubiquitous Language** - Code reflects domain
7. **Bounded Contexts** - Explicit model boundaries
8. **Layered Architecture** - Clear separation, one-way dependencies
9. **Dependency Injection** - Provide from outside
10. **Composition > Inheritance** - Favor has-a over is-a
11. **Package by Feature** - Organize by business capability
12. **Tracer Bullets** - Build end-to-end skeleton first
13. **Document Decisions** - Use ADRs

---

## Related Resources

- See `base/12-factor-app.md` for SaaS architecture
- See `base/refactoring-patterns.md` for improvement techniques
- See `base/code-quality.md` for quality standards
- See `base/lean-development.md` for Progressive Enhancement vs Tracer Bullets
