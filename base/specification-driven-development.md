# Specification-Driven Development

> **When to apply:** All projects requiring clear requirements, traceability, and AI-assisted development

Specification-Driven Development uses machine-readable specifications with unique identifiers to drive development, ensuring complete traceability from requirements through implementation to testing.

## Table of Contents

- [What is Specification-Driven Development?](#what-is-specification-driven-development)
- [EARS Format](#ears-format)
- [Specification IDs](#specification-ids)
- [Traceability Patterns](#traceability-patterns)
- [Machine-Readable Specifications](#machine-readable-specifications)
- [Spec-Driven Workflow](#spec-driven-workflow)
- [AI-Assisted Development](#ai-assisted-development)
- [Tools and Automation](#tools-and-automation)

---

## What is Specification-Driven Development?

### Core Concept

**Specification-Driven Development** means:
1. Write specifications **before** code
2. Each specification has a **unique ID**
3. Code and tests **reference** specification IDs
4. Complete **traceability** from requirement to implementation

### Benefits

✅ **Clear Requirements** - Unambiguous, testable specifications
✅ **Full Traceability** - Track requirements through implementation
✅ **Living Documentation** - Specs stay updated with code
✅ **AI-Friendly** - Machine-readable for AI code generation
✅ **Compliance Ready** - Audit trail for regulated industries
✅ **Change Management** - Impact analysis when specs change

---

## EARS Format

### Easy Approach to Requirements Syntax

**EARS** provides templates for writing clear, unambiguous requirements.

### EARS Templates

**1. Ubiquitous Requirements (always true)**
```
Format: The <system> shall <action>

Examples:
- The system shall encrypt all data at rest using AES-256
- The API shall return responses in JSON format
- The application shall log all authentication attempts
```

**2. Event-Driven Requirements**
```
Format: WHEN <trigger>, the <system> shall <action>

Examples:
- WHEN a user submits a form, the system shall validate all required fields
- WHEN authentication fails 5 times, the system shall lock the account for 15 minutes
- WHEN a file upload exceeds 10MB, the system shall reject the upload
```

**3. State-Driven Requirements**
```
Format: WHILE <state>, the <system> shall <action>

Examples:
- WHILE a user session is active, the system shall refresh the auth token every 15 minutes
- WHILE processing a payment, the system shall display a loading indicator
- WHILE in maintenance mode, the system shall return a 503 status code
```

**4. Optional Features**
```
Format: WHERE <condition>, the <system> shall <action>

Examples:
- WHERE a user has premium subscription, the system shall enable advanced features
- WHERE the request includes an API key, the system shall allow higher rate limits
- WHERE geolocation is enabled, the system shall display location-based content
```

**5. Unwanted Behaviors**
```
Format: IF <condition>, THEN the <system> shall <action>

Examples:
- IF invalid credentials are provided, THEN the system shall return a 401 error
- IF a duplicate email is detected, THEN the system shall reject registration
- IF a session expires, THEN the system shall redirect to login page
```

### EARS Examples

**User Authentication:**
```
[REQ-AUTH-001] The system shall encrypt passwords using bcrypt with cost factor 12

[REQ-AUTH-002] WHEN a user logs in with valid credentials, the system shall create a session token valid for 24 hours

[REQ-AUTH-003] WHEN a user fails login 5 consecutive times, the system shall lock the account for 15 minutes

[REQ-AUTH-004] WHILE a user session is active, the system shall validate the token on each authenticated request

[REQ-AUTH-005] IF a user attempts to access a protected resource without authentication, THEN the system shall return HTTP 401
```

**File Upload:**
```
[REQ-UPLOAD-001] The system shall accept files up to 100MB in size

[REQ-UPLOAD-002] The system shall support file types: PNG, JPG, PDF, DOCX

[REQ-UPLOAD-003] WHEN a file upload begins, the system shall display upload progress percentage

[REQ-UPLOAD-004] IF an unsupported file type is uploaded, THEN the system shall return error "File type not supported"

[REQ-UPLOAD-005] WHEN upload completes successfully, the system shall return the file URL
```

---

## Specification IDs

### ID Format

**Structure:** `[PREFIX-COMPONENT-NUMBER]`

**Examples:**
- `[REQ-AUTH-001]` - Requirement for authentication component
- `[SPEC-API-042]` - Specification for API component
- `[TEST-DB-005]` - Test for database component

### ID Categories

**Requirements:**
```
[REQ-{COMPONENT}-{NUMBER}]
- REQ-AUTH-001: Authentication requirement
- REQ-PAY-015: Payment requirement
- REQ-NOTIF-003: Notification requirement
```

**Specifications:**
```
[SPEC-{COMPONENT}-{NUMBER}]
- SPEC-API-001: API specification
- SPEC-DB-010: Database specification
- SPEC-UI-025: UI specification
```

**Tasks:**
```
[TASK-{COMPONENT}-{NUMBER}]
- TASK-AUTH-001: Implement password reset
- TASK-API-042: Add rate limiting
```

**Tests:**
```
[TEST-{COMPONENT}-{NUMBER}]
- TEST-AUTH-001: Test login with valid credentials
- TEST-AUTH-002: Test login with invalid password
```

### ID Management

**Specification File (specs.md):**
```markdown
# Authentication Specifications

## [SPEC-AUTH-001] User Login
**Status:** Implemented
**Priority:** High
**Owner:** @alice

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

---

## [SPEC-AUTH-002] Password Reset
**Status:** Planned
**Priority:** Medium
**Owner:** @bob

WHEN a user requests password reset,
the system shall send email with reset link valid for 1 hour.

**Acceptance Criteria:**
- Reset token generated
- Email sent to user
- Token expires after 1 hour
- Old password invalidated after reset

**Related:**
- Tasks: [TASK-AUTH-002]
- Tests: [TEST-AUTH-010], [TEST-AUTH-011]
```

---

## Traceability Patterns

### Requirement → Code → Test

**1. Specification with ID:**
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

**2. Implementation References Spec:**
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
        amount=int(amount * 100),  # Convert to cents
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

**3. Tests Reference Spec:**
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

### Traceability Matrix

**CSV/Excel Format:**
```csv
Spec ID,Description,Status,Implementation,Tests,Coverage
SPEC-AUTH-001,User Login,Implemented,src/auth/login.py:login_user(),"TEST-AUTH-001,TEST-AUTH-002",100%
SPEC-AUTH-002,Password Reset,In Progress,src/auth/reset.py:reset_password(),"TEST-AUTH-010",80%
SPEC-PAY-001,Process Payment,Implemented,src/payments/process.py:process_payment(),"TEST-PAY-001,TEST-PAY-002,TEST-PAY-003",100%
```

**Markdown Format:**
```markdown
# Traceability Matrix

| Spec ID | Description | Status | Implementation | Tests | Coverage |
|---------|-------------|--------|----------------|-------|----------|
| SPEC-AUTH-001 | User Login | ✅ Implemented | `src/auth/login.py` | TEST-AUTH-001, TEST-AUTH-002 | 100% |
| SPEC-AUTH-002 | Password Reset | 🟡 In Progress | `src/auth/reset.py` | TEST-AUTH-010 | 80% |
| SPEC-PAY-001 | Process Payment | ✅ Implemented | `src/payments/process.py` | TEST-PAY-001, TEST-PAY-002 | 100% |
```

---

## Machine-Readable Specifications

### YAML Specifications

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

      - id: AC3
        description: Session token generated with 24hr expiry
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

    related:
      - SPEC-AUTH-002
      - SPEC-AUTH-003
```

### JSON Specifications

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
    },
    {
      "id": "AC2",
      "description": "Order created with status Processing",
      "implemented": true,
      "tested": true,
      "test_ids": ["TEST-PAY-002"]
    }
  ],
  "implementation": {
    "files": ["src/payments/process.py"],
    "functions": ["process_payment"],
    "lines": [45, 78]
  },
  "tests": ["TEST-PAY-001", "TEST-PAY-002", "TEST-PAY-003"],
  "coverage": 100
}
```

---

## Spec-Driven Workflow

### 1. Specification Phase

**Write specifications before coding:**
```markdown
## [SPEC-NOTIF-001] Email Notifications

WHEN a user performs an action requiring notification,
the system shall send email within 5 minutes.

**Actions triggering notifications:**
- User registration
- Password reset
- Order confirmation
- Payment failure

**Email requirements:**
- HTML formatted
- Include user name
- Include action-specific content
- Include unsubscribe link
```

### 2. Review Phase

**Team reviews specifications:**
- Product Owner: Business value correct?
- Developers: Technically feasible?
- QA: Testable and complete?
- Security: Any security concerns?

### 3. Implementation Phase

**Code references specifications:**
```python
async def send_notification(
    user_id: int,
    event_type: NotificationEvent,
    context: dict
) -> bool:
    """
    Send email notification for user events.

    Implements: [SPEC-NOTIF-001]

    Args:
        user_id: ID of user to notify
        event_type: Type of event (registration, password_reset, etc.)
        context: Event-specific data for email template

    Returns:
        True if email sent successfully, False otherwise
    """
    # [SPEC-NOTIF-001:AC1] - Get user details
    user = await get_user(user_id)

    # [SPEC-NOTIF-001:AC2] - Format HTML email
    email_html = render_template(
        template=f"notifications/{event_type}.html",
        user_name=user.full_name,  # [SPEC-NOTIF-001:AC3]
        **context  # [SPEC-NOTIF-001:AC4]
    )

    # [SPEC-NOTIF-001:AC5] - Include unsubscribe link
    email_html = add_unsubscribe_link(email_html, user.id)

    # Send email
    result = await email_service.send(
        to=user.email,
        subject=get_subject(event_type),
        html=email_html
    )

    return result.success
```

### 4. Testing Phase

**Tests verify specifications:**
```python
@pytest.mark.asyncio
async def test_send_registration_notification():
    """
    Test: [TEST-NOTIF-001]
    Spec: [SPEC-NOTIF-001]

    Verify registration notification sent correctly.
    """
    # Arrange
    user = await create_test_user(
        email='test@example.com',
        full_name='Test User'
    )

    # Act
    result = await send_notification(
        user_id=user.id,
        event_type=NotificationEvent.REGISTRATION,
        context={}
    )

    # Assert
    assert result is True

    # Verify email sent [SPEC-NOTIF-001:AC1]
    email = await get_latest_email(user.email)
    assert email is not None

    # Verify HTML format [SPEC-NOTIF-001:AC2]
    assert email.content_type == 'text/html'

    # Verify user name included [SPEC-NOTIF-001:AC3]
    assert 'Test User' in email.html_body

    # Verify unsubscribe link [SPEC-NOTIF-001:AC5]
    assert 'unsubscribe' in email.html_body
```

---

## AI-Assisted Development

### Specifications for AI Code Generation

**Clear specifications enable AI to generate correct code:**

**Specification:**
```markdown
## [SPEC-SEARCH-001] Product Search

WHEN a user enters search query,
the system shall return matching products ranked by relevance.

**Search behavior:**
- Match against product name, description, tags
- Case-insensitive matching
- Support partial matches
- Rank by relevance (exact > partial > fuzzy)
- Limit results to 50 per page
- Return results within 200ms

**Search query examples:**
- "blue shirt" → matches products with "blue" AND "shirt"
- "laptop" → matches all laptop products
- "shoes size 10" → matches shoes, filtered by size 10
```

**AI-Generated Code:**
```python
async def search_products(
    query: str,
    page: int = 1,
    per_page: int = 50
) -> SearchResults:
    """
    Search products by query string.

    Implements: [SPEC-SEARCH-001]

    Args:
        query: Search query string
        page: Page number (1-indexed)
        per_page: Results per page (max 50)

    Returns:
        SearchResults with matching products ranked by relevance
    """
    # [SPEC-SEARCH-001:AC1] - Parse query
    terms = query.lower().split()

    # [SPEC-SEARCH-001:AC2] - Build search query
    search_query = (
        select(Product)
        .where(
            or_(
                *[Product.name.ilike(f'%{term}%') for term in terms],
                *[Product.description.ilike(f'%{term}%') for term in terms],
                *[Product.tags.contains([term]) for term in terms]
            )
        )
    )

    # [SPEC-SEARCH-001:AC4] - Rank by relevance
    search_query = search_query.order_by(
        case(
            # Exact match highest
            (Product.name.ilike(query), 1),
            # Partial match medium
            (Product.name.ilike(f'%{query}%'), 2),
            # Tag match lowest
            else_=3
        )
    )

    # [SPEC-SEARCH-001:AC5] - Paginate (limit 50)
    offset = (page - 1) * min(per_page, 50)
    search_query = search_query.offset(offset).limit(min(per_page, 50))

    # Execute with timeout [SPEC-SEARCH-001:AC6]
    results = await asyncio.wait_for(
        db.execute(search_query),
        timeout=0.2
    )

    return SearchResults(
        products=results.scalars().all(),
        page=page,
        per_page=per_page
    )
```

---

## Tools and Automation

### Specification Validation

**Check spec coverage:**
```bash
# Find all spec IDs in specs.md
grep -o '\[SPEC-[A-Z]*-[0-9]*\]' specs.md | sort -u > spec_ids.txt

# Find all spec references in code
grep -r '\[SPEC-[A-Z]*-[0-9]*\]' src/ | grep -o '\[SPEC-[A-Z]*-[0-9]*\]' | sort -u > implemented_ids.txt

# Find specs without implementation
comm -23 spec_ids.txt implemented_ids.txt
```

### Traceability Report Generation

**Python script:**
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

### ✅ Do This

1. **Write specs before code**
2. **Use unique IDs for all specs**
3. **Reference spec IDs in code and tests**
4. **Keep specs updated as requirements change**
5. **Use EARS format for clarity**
6. **Maintain traceability matrix**

### ❌ Avoid This

1. **Don't write code before specs**
2. **Don't use duplicate spec IDs**
3. **Don't implement without spec references**
4. **Don't let specs diverge from code**
5. **Don't skip acceptance criteria**
6. **Don't ignore traceability**

---

## Related Resources

- See `base/testing-atdd.md` for acceptance testing
- See `base/ai-assisted-development.md` for AI code generation
- See `base/testing-philosophy.md` for testing strategy
- See `/xspec` slash command for spec-driven workflows
- **EARS Guide:** NASA Requirements Engineering
- **Spec-Kit:** Tools for specification management
