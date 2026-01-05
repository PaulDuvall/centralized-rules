# Lean Development and Progressive Enhancement

> **When to apply:** All development workflows, especially MVPs and AI-assisted projects
> **Maturity Level:** All levels (essential for MVP, refined at higher maturity)

Build incrementally with minimal waste, delivering value early and often through progressive enhancement and lean AI practices.

## Core Lean Principles

### The 7 Wastes in Software

| Waste | Description | Solution |
|-------|-------------|----------|
| **Partially Done Work** | Code written but not deployed | Ship continuously |
| **Extra Features** | Building what customers don't need | Validate first |
| **Relearning** | Knowledge loss, poor documentation | Document as you go |
| **Handoffs** | Context switching, waiting for approvals | Reduce dependencies |
| **Task Switching** | Multitasking reduces productivity | Finish one at a time |
| **Delays** | Waiting for builds, reviews, deployments | Automate pipelines |
| **Defects** | Bugs that escape to production | Build quality in |

**Cost of Defect:** Coding ($1) → Code Review ($10) → QA ($100) → Production ($1,000+)

### 1. Eliminate Waste

**Checklist:**
- [ ] Is this feature validated by users?
- [ ] Can we deliver 80% value with 20% effort?
- [ ] Are we building for hypothetical future needs?
- [ ] Can we use existing solutions instead?

```python
# ❌ WASTE: Building sophisticated features before validation
def build_complete_recommendation_engine():
    # Weeks building ML without validation
    pass

# ✅ LEAN: Start simple, validate, enhance
def show_popular_items():
    return db.query(Product).order_by(Product.view_count.desc()).limit(10).all()
```

### 2. Build Quality In

Shift left - catch defects early when cheap to fix.

```python
from pydantic import BaseModel, validator

class User(BaseModel):
    email: str
    age: int

    @validator('email')
    def validate_email(cls, v):
        if '@' not in v:
            raise ValueError('Invalid email')
        return v
```

### 3. Learn Fast

**Build-Measure-Learn Loop:** Build → Measure → Learn → Iterate

### 4. Deliver Fast

| Approach | Cycle Time | Learning Speed |
|----------|-----------|----------------|
| **Traditional** | 9 weeks | 4x/year |
| **Lean** | 1 week | 52x/year |

**Techniques:** Small batches (1-3 days), continuous deployment, feature flags, parallel development

### 5. Defer Decisions

Decide at the last responsible moment. Defer: Database choice, caching, microservices until proven necessary.

```python
# ✅ LEAN: Abstract database, decide later
class Database(ABC):
    @abstractmethod
    def save(self, data): pass

# Start simple, upgrade when needed
class InMemoryDatabase(Database):
    def save(self, data):
        self.data[data.id] = data
```

---

## Progressive Enhancement

**Principle:** Start basic, enhance incrementally. **Benefits:** Faster value, lower risk, better feedback.

### Enhancement Layers

```python
# Week 1: Core Functionality
def search_products(query: str):
    return db.query(Product).filter(Product.name.contains(query)).all()

# Week 2: Improve UX
def search_products(query: str):
    results = db.query(Product).filter(Product.name.contains(query)).all()
    return sorted(results, key=lambda p: p.sales_count, reverse=True)

# Week 3: Add Intelligence
def search_products(query: str, user_id: Optional[str] = None):
    results = db.query(Product).filter(Product.name.contains(query)).all()
    if user_id:
        results = personalize_results(results, get_user_preferences(user_id))
    return results
```

### Rollout Strategy

| Phase | Timeline | Features | Goal |
|-------|----------|----------|------|
| **Core** | Week 1 | Basic notifications, templates | Validate need |
| **Enhancement** | Week 2 | Preferences, categories, unsubscribe | Reduce fatigue |
| **Intelligence** | Week 3 | Smart batching, optimal timing | Increase engagement |
| **Scale** | Week 4 | In-app, push, SMS channels | Multi-channel |

---

## Lean AI Development

### Progressive AI Enhancement

| Level | Implementation | When to Use | Accuracy |
|-------|---------------|-------------|----------|
| **L1: Heuristics** | Popular items, simple rules | Day 1 - validate concept | 60-70% |
| **L2: Collaborative** | Similar user purchases | Week 2 - if validated | 70-80% |
| **L3: ML Model** | Feature-based predictions | Week 6 - if data available | 75-85% |
| **L4: Deep Learning** | Neural networks, real-time | Month 6 - at scale | 85%+ |

**Example: Support Ticket Categorization**

```python
# ✅ Week 1: Rule-based (70% accuracy - often good enough)
def categorize_support_ticket(ticket: str) -> str:
    ticket_lower = ticket.lower()
    if "password" in ticket_lower or "login" in ticket_lower:
        return "authentication"
    elif "payment" in ticket_lower or "billing" in ticket_lower:
        return "billing"
    return "general"

# Week 3+: Add ML only if 70% insufficient
```

### Lean AI Principles

**1. Baseline First**
```python
baseline = 25%  # Random
heuristic = 60%  # Rules
ml_model = 75%  # ML
# Is 15% improvement worth complexity, cost, maintenance?
```

**2. Incremental Data**
- Week 1: 1K examples (70%)
- Week 4: 10K examples (80%)
- Month 3: 100K examples (85%)

**3. Human-in-the-Loop**
```python
def ai_with_human_oversight(input_data):
    prediction = ai_model.predict(input_data)
    if prediction.confidence > 0.9:
        return prediction.result  # Automate high confidence
    else:
        return request_human_review(prediction, input_data)
```

---

## Minimum Viable Product (MVP)

**MVP IS:** Smallest version delivering value and enabling learning - focused, functional, reliable

**MVP is NOT:** Buggy product, feature-limited vision, embarrassing to ship

### Feature Prioritization (MoSCoW)

| Priority | Features |
|----------|----------|
| **Must Have (Core)** | Authentication, create/edit/delete, basic editor, save |
| **Should Have (Phase 2)** | Keyboard shortcuts, export PDF, sharing |
| **Could Have (Phase 3)** | Themes, templates, mobile app |
| **Won't Have (Not Now)** | Offline mode, collaboration, AI features |

---

## Eliminating Waste Patterns

| Waste Type | Anti-Pattern | Lean Approach |
|------------|--------------|---------------|
| **Unnecessary Features** | 20+ profile fields nobody uses | Name/email only, add when requested |
| **Premature Optimization** | Multi-layer caching Day 1 | Simple query, measure, optimize if slow |
| **Context Switching** | 3 features in progress | Finish and ship one at a time |

**Examples:**

```python
# ❌ WASTE: Features users don't want
class UserProfile:
    favorite_color = None  # Does anyone care?
    zodiac_sign = None     # Really?

# ✅ LEAN: Essentials only
class UserProfile:
    name = None
    email = None
    # Add more when requested

# ❌ WASTE: Optimizing before measuring
def get_dashboard(user_id):
    # Multi-layer caching before knowing if needed
    pass

# ✅ LEAN: Measure first
def get_dashboard(user_id):
    return db.query(...).all()
    # If slow → measure → optimize
```

---

## Continuous Value Delivery

### Deployment Comparison

| Metric | Traditional | Lean |
|--------|------------|------|
| **Releases** | Quarterly | Multiple/day |
| **Change Size** | 100+ features | 1-3 features |
| **Risk** | High (big bang) | Low (isolated) |
| **Feedback** | 3 months | Hours |
| **Rollback** | Difficult | Easy (feature flag) |

### Feature Flags

```python
class FeatureFlags:
    def __init__(self):
        self.flags = {
            "new_dashboard": False,      # Not ready
            "ai_recommendations": True,  # 10% rollout
            "dark_mode": True,          # Fully launched
        }

    def is_enabled(self, feature: str, user_id: str = None) -> bool:
        if not self.flags.get(feature, False):
            return False

        # Gradual rollout
        if feature == "ai_recommendations":
            return hash(user_id) % 100 < 10  # 10% of users

        return True
```

### Metrics-Driven Development

```python
@dataclass
class FeatureMetrics:
    feature_name: str
    daily_active_users: int
    feature_adoption_rate: float
    conversion_rate: float
    error_rate: float
    p95_latency_ms: float

def review_features():
    """Monthly review - remove low-value features"""
    for feature in all_features:
        metrics = get_feature_metrics(feature)
        if metrics.feature_adoption_rate < 0.05:  # < 5%
            remove_feature(feature)
        if metrics.p95_latency_ms > 500:
            optimize_feature(feature)
```

---

## Progressive Enhancement vs. Tracer Bullets

| Approach | Purpose | When to Use |
|----------|---------|-------------|
| **Progressive Enhancement** | Build features in layers (basic → optimized) | Adding features to existing architecture |
| **Tracer Bullets** | End-to-end skeleton through all layers | Starting new system or unfamiliar tech |

**They complement each other:**
- Week 1: Tracer Bullet (prove architecture)
- Week 2+: Progressive Enhancement (add features)

See `base/architecture-principles.md#tracer-bullet-development` for details.

---

## Related Resources

- `base/architecture-principles.md` - Tracer Bullet Development
- `base/ai-assisted-development.md` - AI workflow patterns
- `base/project-maturity-levels.md` - MVP vs Production rigor
- `base/testing-philosophy.md` - Quality practices
- `base/specification-driven-development.md` - Requirements

---

**Remember:** Lean development is about learning fast and building what matters. Ship small, learn quickly, iterate based on real feedback. The goal is not to build everything, but to build the right things efficiently.
