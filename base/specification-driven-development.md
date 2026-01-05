# Specification-Driven Development

> **When to apply:** All projects requiring clear requirements, traceability, and AI-assisted development

Write machine-readable specifications with unique identifiers before code. Ensure complete traceability from requirements through implementation to testing.

## Core Principles

1. Write specifications **before** code
2. Each specification has a **unique ID**
3. Code and tests **reference** specification IDs
4. Maintain **complete traceability** from requirement to implementation

**Benefits:** Clear requirements, full traceability, living documentation, AI-friendly, compliance ready, change management

---

## EARS Format

Easy Approach to Requirements Syntax provides templates for unambiguous requirements.

| Template | Format | Example |
|----------|--------|---------|
| **Ubiquitous** | The `<system>` shall `<action>` | The system shall encrypt all data at rest using AES-256 |
| **Event-Driven** | WHEN `<trigger>`, the `<system>` shall `<action>` | WHEN a user submits a form, the system shall validate all required fields |
| **State-Driven** | WHILE `<state>`, the `<system>` shall `<action>` | WHILE a user session is active, the system shall refresh the auth token every 15 minutes |
| **Optional** | WHERE `<condition>`, the `<system>` shall `<action>` | WHERE a user has premium subscription, the system shall enable advanced features |
| **Unwanted** | IF `<condition>`, THEN the `<system>` shall `<action>` | IF invalid credentials are provided, THEN the system shall return a 401 error |

**Example Specification:**
```markdown
[REQ-AUTH-001] The system shall encrypt passwords using bcrypt with cost factor 12

[REQ-AUTH-002] WHEN a user logs in with valid credentials, the system shall create a session token valid for 24 hours

[REQ-AUTH-003] WHEN a user fails login 5 consecutive times, the system shall lock the account for 15 minutes

[REQ-AUTH-004] IF a user attempts to access a protected resource without authentication, THEN the system shall return HTTP 401
```

---

## Specification IDs

**Format:** `[PREFIX-COMPONENT-NUMBER]`

| Prefix | Purpose | Example |
|--------|---------|---------|
| `REQ` | Requirements | `[REQ-AUTH-001]` Authentication requirement |
| `SPEC` | Specifications | `[SPEC-API-042]` API specification |
| `TASK` | Implementation tasks | `[TASK-AUTH-001]` Implement password reset |
| `TEST` | Test cases | `[TEST-AUTH-001]` Test login with valid credentials |

**Specification File Structure:**
```markdown
# Authentication Specifications

## [SPEC-AUTH-001] User Login
**Status:** Implemented | **Priority:** High | **Owner:** @alice

WHEN a user submits valid email and password,
the system shall create a session token and redirect to dashboard.

**Acceptance Criteria:**
- Email validation succeeds
- Password hash matches stored hash
- Session token generated with 24hr expiry
- User redirected to /dashboard

**Related:**
- Implementation: `src/auth/login.py:login_user()`
- Tests: [TEST-AUTH-001], [TEST-AUTH-002]
- Tasks: [TASK-AUTH-001]
```

---

## Traceability Pattern

### 1. Specification
```markdown
## [SPEC-PAY-001] Process Payment

WHEN a user confirms payment,
the system shall charge the payment method and create an order.

**Acceptance Criteria:**
- Payment method charged successfully
- Order created with status "Processing"
- Confirmation email sent
- Inventory updated
```

### 2. Implementation
```python
# src/payments/process.py

async def process_payment(
    user_id: int,
    payment_method_id: str,
    amount: Decimal
) -> Order:
    """
    Process payment and create order.

    Implements: [SPEC-PAY-001]
    """
    # Charge payment method
    charge = await stripe.charges.create(
        amount=int(amount * 100),
        payment_method=payment_method_id,
        customer=user_id
    )  # [SPEC-PAY-001:AC1]

    # Create order
    order = Order(
        user_id=user_id,
        amount=amount,
        status=OrderStatus.PROCESSING
    )
    await db.save(order)  # [SPEC-PAY-001:AC2]

    # Send confirmation
    await send_confirmation_email(user_id, order)  # [SPEC-PAY-001:AC3]

    # Update inventory
    await update_inventory(order.items)  # [SPEC-PAY-001:AC4]

    return order
```

### 3. Tests
```python
# tests/test_payments.py

async def test_process_payment_success():
    """
    Test: [TEST-PAY-001]
    Spec: [SPEC-PAY-001]

    Verify successful payment processing creates order and sends email.
    """
    # Arrange
    user = await create_test_user()
    payment_method = await create_test_payment_method(user)

    # Act
    order = await process_payment(
        user_id=user.id,
        payment_method_id=payment_method.id,
        amount=Decimal('99.99')
    )

    # Assert
    assert order.status == OrderStatus.PROCESSING  # [SPEC-PAY-001:AC2]
    assert order.amount == Decimal('99.99')

    # Verify payment charged
    charge = await get_latest_charge()
    assert charge.amount == 9999  # [SPEC-PAY-001:AC1]

    # Verify email sent
    assert email_sent_to(user.email)  # [SPEC-PAY-001:AC3]
```

### 4. Traceability Matrix
```markdown
| Spec ID | Description | Status | Implementation | Tests | Coverage |
|---------|-------------|--------|----------------|-------|----------|
| SPEC-AUTH-001 | User Login | Implemented | `src/auth/login.py` | TEST-AUTH-001, TEST-AUTH-002 | 100% |
| SPEC-AUTH-002 | Password Reset | In Progress | `src/auth/reset.py` | TEST-AUTH-010 | 80% |
| SPEC-PAY-001 | Process Payment | Implemented | `src/payments/process.py` | TEST-PAY-001, TEST-PAY-002 | 100% |
```

---

## Machine-Readable Formats

### YAML
```yaml
specifications:
  - id: SPEC-AUTH-001
    title: User Login
    status: implemented
    priority: high
    owner: alice

    description: |
      WHEN a user submits valid email and password,
      the system shall create a session token and redirect to dashboard.

    acceptance_criteria:
      - id: AC1
        description: Email validation succeeds
        implemented: true
        tested: true

      - id: AC2
        description: Password hash matches stored hash
        implemented: true
        tested: true

    implementation:
      files:
        - src/auth/login.py
      functions:
        - login_user
        - validate_credentials

    tests:
      - TEST-AUTH-001
      - TEST-AUTH-002
```

### JSON
```json
{
  "spec_id": "SPEC-PAY-001",
  "title": "Process Payment",
  "status": "implemented",
  "priority": "critical",
  "description": "WHEN a user confirms payment, the system shall charge the payment method and create an order.",
  "acceptance_criteria": [
    {
      "id": "AC1",
      "description": "Payment method charged successfully",
      "implemented": true,
      "tested": true,
      "test_ids": ["TEST-PAY-001"]
    }
  ],
  "implementation": {
    "files": ["src/payments/process.py"],
    "functions": ["process_payment"]
  },
  "tests": ["TEST-PAY-001", "TEST-PAY-002"],
  "coverage": 100
}
```

---

## Workflow

### 1. Specification Phase
Write specifications before coding:
```markdown
## [SPEC-NOTIF-001] Email Notifications

WHEN a user performs an action requiring notification,
the system shall send email within 5 minutes.

**Actions:** User registration, password reset, order confirmation, payment failure

**Requirements:**
- HTML formatted
- Include user name
- Include action-specific content
- Include unsubscribe link
```

### 2. Review Phase
**Stakeholder reviews:**
- Product Owner: Business value correct?
- Developers: Technically feasible?
- QA: Testable and complete?
- Security: Any security concerns?

### 3. Implementation Phase
Code references specifications:
```python
async def send_notification(
    user_id: int,
    event_type: NotificationEvent,
    context: dict
) -> bool:
    """
    Send email notification for user events.

    Implements: [SPEC-NOTIF-001]
    """
    user = await get_user(user_id)  # [SPEC-NOTIF-001:AC1]

    email_html = render_template(
        template=f"notifications/{event_type}.html",
        user_name=user.full_name,  # [SPEC-NOTIF-001:AC2]
        **context
    )  # [SPEC-NOTIF-001:AC3]

    email_html = add_unsubscribe_link(email_html, user.id)  # [SPEC-NOTIF-001:AC4]

    result = await email_service.send(
        to=user.email,
        subject=get_subject(event_type),
        html=email_html
    )

    return result.success
```

### 4. Testing Phase
Tests verify specifications:
```python
@pytest.mark.asyncio
async def test_send_registration_notification():
    """
    Test: [TEST-NOTIF-001]
    Spec: [SPEC-NOTIF-001]
    """
    user = await create_test_user(email='test@example.com', full_name='Test User')

    result = await send_notification(
        user_id=user.id,
        event_type=NotificationEvent.REGISTRATION,
        context={}
    )

    assert result is True

    email = await get_latest_email(user.email)
    assert email.content_type == 'text/html'  # [SPEC-NOTIF-001:AC2]
    assert 'Test User' in email.html_body  # [SPEC-NOTIF-001:AC3]
    assert 'unsubscribe' in email.html_body  # [SPEC-NOTIF-001:AC4]
```

---

## AI-Assisted Development

Clear specifications enable AI to generate correct code:

**Specification:**
```markdown
## [SPEC-SEARCH-001] Product Search

WHEN a user enters search query,
the system shall return matching products ranked by relevance.

**Behavior:**
- Match against product name, description, tags
- Case-insensitive matching
- Support partial matches
- Rank by relevance (exact > partial > fuzzy)
- Limit results to 50 per page
- Return results within 200ms
```

**AI-Generated Implementation:**
```python
async def search_products(
    query: str,
    page: int = 1,
    per_page: int = 50
) -> SearchResults:
    """
    Search products by query string.
    Implements: [SPEC-SEARCH-001]
    """
    terms = query.lower().split()  # [SPEC-SEARCH-001:AC1]

    search_query = (
        select(Product)
        .where(
            or_(
                *[Product.name.ilike(f'%{term}%') for term in terms],
                *[Product.description.ilike(f'%{term}%') for term in terms],
                *[Product.tags.contains([term]) for term in terms]
            )
        )  # [SPEC-SEARCH-001:AC2,AC3]
        .order_by(
            case(
                (Product.name.ilike(query), 1),  # Exact match
                (Product.name.ilike(f'%{query}%'), 2),  # Partial match
                else_=3
            )
        )  # [SPEC-SEARCH-001:AC4]
    )

    offset = (page - 1) * min(per_page, 50)
    search_query = search_query.offset(offset).limit(min(per_page, 50))  # [SPEC-SEARCH-001:AC5]

    results = await asyncio.wait_for(
        db.execute(search_query),
        timeout=0.2  # [SPEC-SEARCH-001:AC6]
    )

    return SearchResults(
        products=results.scalars().all(),
        page=page,
        per_page=per_page
    )
```

---

## Tools and Automation

### Specification Coverage Check
```bash
# Find all spec IDs
grep -o '\[SPEC-[A-Z]*-[0-9]*\]' specs.md | sort -u > spec_ids.txt

# Find implemented specs
grep -r '\[SPEC-[A-Z]*-[0-9]*\]' src/ | grep -o '\[SPEC-[A-Z]*-[0-9]*\]' | sort -u > implemented_ids.txt

# Find unimplemented specs
comm -23 spec_ids.txt implemented_ids.txt
```

### Traceability Report
```python
import re
from pathlib import Path

def generate_traceability_report():
    """Generate traceability matrix from specs and code"""
    specs = parse_specifications('specs.md')
    implementations = find_implementations('src/')
    tests = find_tests('tests/')

    report = []
    for spec in specs:
        spec_id = spec['id']
        impl = implementations.get(spec_id, [])
        test_ids = tests.get(spec_id, [])

        report.append({
            'spec_id': spec_id,
            'title': spec['title'],
            'status': spec['status'],
            'implemented': len(impl) > 0,
            'tested': len(test_ids) > 0,
            'files': impl,
            'tests': test_ids
        })

    return report

# Generate markdown report
report = generate_traceability_report()
with open('TRACEABILITY.md', 'w') as f:
    f.write('# Traceability Matrix\n\n')
    f.write('| Spec ID | Title | Implemented | Tested | Files | Tests |\n')
    f.write('|---------|-------|-------------|--------|-------|-------|\n')

    for item in report:
        f.write(f"| {item['spec_id']} | {item['title']} | "
                f"{'✅' if item['implemented'] else '❌'} | "
                f"{'✅' if item['tested'] else '❌'} | "
                f"{', '.join(item['files'])} | {', '.join(item['tests'])} |\n")
```

---

## Best Practices

| Do | Don't |
|----|-------|
| Write specs before code | Write code before specs |
| Use unique IDs for all specs | Use duplicate spec IDs |
| Reference spec IDs in code and tests | Implement without spec references |
| Keep specs updated as requirements change | Let specs diverge from code |
| Use EARS format for clarity | Skip acceptance criteria |
| Maintain traceability matrix | Ignore traceability |

---

## Related Resources

- `base/testing-atdd.md` - Acceptance testing
- `base/ai-assisted-development.md` - AI code generation
- `base/testing-philosophy.md` - Testing strategy
- `/xspec` - Spec-driven workflows
- **EARS Guide:** NASA Requirements Engineering
- **Spec-Kit:** Tools for specification management
