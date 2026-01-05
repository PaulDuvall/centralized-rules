# Acceptance Test-Driven Development (ATDD)

> **When to apply:** All feature development, especially when collaborating with stakeholders

ATDD is a collaborative practice where developers, testers, and business stakeholders define acceptance criteria and executable tests before implementation.

## Table of Contents

- [Core Concepts](#core-concepts)
- [The ATDD Process](#the-atdd-process)
- [Writing Acceptance Criteria](#writing-acceptance-criteria)
- [Frameworks & Implementation](#frameworks--implementation)
- [Examples by Domain](#examples-by-domain)
- [Best Practices](#best-practices)

---

## Core Concepts

### The 4D Cycle

```
1. Discuss → Define acceptance criteria collaboratively
2. Distill → Create executable acceptance tests
3. Develop → Implement code to pass tests
4. Demo    → Show working software to stakeholders
```

### Key Participants

| Role | Responsibility |
|------|---------------|
| **Product Owner/BA** | Defines business value and requirements |
| **Developer** | Implements functionality |
| **Tester/QA** | Ensures quality and edge cases |

### ATDD vs TDD vs BDD

| Aspect | ATDD | TDD | BDD |
|--------|------|-----|-----|
| **Focus** | Acceptance criteria | Unit tests | Behavior scenarios |
| **Participants** | Team + stakeholders | Developers | Team + stakeholders |
| **Scope** | Feature/story level | Function/class level | Feature/behavior level |
| **Language** | Business terms | Technical terms | Business + technical |
| **When** | Before development | Before coding | Before development |

**Relationship:**
```
ATDD (Feature) → BDD (Behavior) → TDD (Unit) → Implementation
```

### Benefits

- **Shared Understanding** - Team alignment on "done"
- **Living Documentation** - Tests document behavior
- **Fewer Defects** - Issues caught before coding
- **Faster Feedback** - Early stakeholder validation
- **Reduced Rework** - Clear requirements upfront

---

## The ATDD Process

### 1. Discuss (Three Amigos Meeting)

Collaborative definition of acceptance criteria:

```
Story: As a user, I want to reset my password

Key Questions:
- Reset link validity period? → 1 hour
- Expired link behavior? → Error message
- Email notification? → Yes, with reset link
- Password requirements? → 8+ chars, 1 number, 1 uppercase
- Password reuse policy? → Cannot reuse last 5
```

### 2. Distill (Write Executable Tests)

```python
def test_password_reset_link_sent():
    """AC1: User receives email with reset link"""
    user = create_user(email='test@example.com')
    response = request_password_reset(user.email)

    assert response.status_code == 200
    assert email_sent_to(user.email)
    assert 'reset link' in latest_email().body

def test_password_reset_link_expires_after_one_hour():
    """AC2: Reset link expires after 1 hour"""
    user = create_user()
    token = generate_reset_token(user)

    with time_travel(minutes=61):
        response = reset_password(token, new_password='NewPass123!')
        assert response.status_code == 400
        assert 'expired' in response.json()['error'].lower()

def test_password_complexity_requirements():
    """AC3: Password validation"""
    user, token = create_user(), generate_reset_token(user)

    # Invalid passwords
    for pwd in ['short', 'alllowercase', 'NoNumbers']:
        response = reset_password(token, new_password=pwd)
        assert response.status_code == 400

    # Valid password
    response = reset_password(token, new_password='ValidPass123!')
    assert response.status_code == 200
```

### 3. Develop (Red-Green-Refactor)

```python
# RED: Tests fail
$ pytest test_password_reset.py  # All fail

# GREEN: Implement minimum code
def request_password_reset(email):
    user = User.get_by_email(email)
    if not user:
        return Response(status=404)

    token = create_reset_token(user, expires_in=3600)
    send_email(
        to=user.email,
        subject='Password Reset',
        body=f'Reset link: {RESET_URL}?token={token}'
    )
    return Response(status=200)

# REFACTOR: Clean up while tests pass
```

### 4. Demo

- Run acceptance tests live
- Demonstrate in staging environment
- Gather feedback and iterate

---

## Writing Acceptance Criteria

### INVEST Criteria

User stories should be:
- **I**ndependent - Developed separately
- **N**egotiable - Details can be clarified
- **V**aluable - Delivers business value
- **E**stimable - Effort can be estimated
- **S**mall - Fits in one iteration
- **T**estable - Clear acceptance criteria

### Given-When-Then Format

```
Given [initial context/state]
When [action/event occurs]
Then [expected outcome]
And [additional outcomes]
```

**Example: User Login**

```gherkin
AC1: Successful login
  Given a registered user
  When they enter correct email and password
  Then they are redirected to dashboard
  And session is created

AC2: Invalid password
  Given a registered user
  When they enter incorrect password
  Then they see error "Invalid credentials"
  And session is not created

AC3: Account lockout
  Given a registered user
  When they fail login 5 times
  Then account is locked for 15 minutes
  And user receives email notification

AC4: Lockout expiration
  Given a locked account
  When 15 minutes have passed
  Then user can log in with correct credentials
```

---

## Frameworks & Implementation

### Python - behave (Gherkin)

**features/password_reset.feature:**
```gherkin
Feature: Password Reset

  Scenario: User requests password reset
    Given a user with email "alice@example.com" exists
    When user requests password reset for "alice@example.com"
    Then user receives email with reset link
    And reset link expires in 1 hour

  Scenario: User resets password with valid token
    Given a user with valid reset token
    When user submits new password "NewPass123!"
    Then password is updated
    And user can log in with new password
```

**features/steps/password_reset_steps.py:**
```python
from behave import given, when, then
import requests

@given('a user with email "{email}" exists')
def step_user_exists(context, email):
    context.user = create_user(email=email)

@when('user requests password reset for "{email}"')
def step_request_reset(context, email):
    context.response = requests.post(
        f'{API_BASE}/auth/reset-password',
        json={'email': email}
    )

@then('user receives email with reset link')
def step_email_sent(context):
    assert email_was_sent_to(context.user.email)
    assert 'reset' in latest_email().subject.lower()
```

### TypeScript/JavaScript - Cucumber

**features/checkout.feature:**
```gherkin
Feature: Shopping Cart Checkout

  Scenario: Complete purchase
    Given user has items in cart:
      | product | quantity | price |
      | Widget  | 2        | 10.00 |
      | Gadget  | 1        | 25.00 |
    When user proceeds to checkout
    And confirms payment
    Then order total is $45.00
    And order confirmation is displayed
```

**steps/checkout.steps.ts:**
```typescript
import { Given, When, Then } from '@cucumber/cucumber';
import { expect } from 'chai';

Given('user has items in cart:', async function (dataTable) {
  for (const item of dataTable.hashes()) {
    await this.cart.addItem({
      product: item.product,
      quantity: parseInt(item.quantity),
      price: parseFloat(item.price)
    });
  }
});

Then('order total is ${amount}', async function (amount: string) {
  const total = await this.checkoutPage.getTotal();
  expect(total).to.equal(parseFloat(amount));
});
```

### pytest-bdd

```python
# features/user_registration.feature
Feature: User Registration

  Scenario: Register with valid information
    Given registration form is displayed
    When user enters valid email, username, and password
    And clicks "Register"
    Then account is created
    And welcome email is sent

# tests/test_registration.py
from pytest_bdd import scenarios, given, when, then

scenarios('../features/user_registration.feature')

@given('registration form is displayed')
def registration_form(browser):
    browser.get('/register')

@then('account is created')
def verify_account_created(db):
    user = db.query(User).filter_by(email='new@example.com').first()
    assert user is not None
```

---

## Examples by Domain

### E-Commerce

```gherkin
Feature: Product Search

Scenario: Search by product name
  Given products exist:
    | name        | category | price |
    | Blue Shirt  | Clothing | 29.99 |
    | Red Pants   | Clothing | 39.99 |
    | Green Socks | Clothing | 9.99  |
  When user searches for "shirt"
  Then 1 product is displayed
  And product is "Blue Shirt"

Scenario: Filter by price range
  Given user is on search results page
  When user sets price filter to $10-$30
  Then 2 products are displayed
  And all products are within price range
```

### Banking

```gherkin
Feature: Money Transfer

Scenario: Transfer between own accounts
  Given checking account has balance $1000
  And savings account has balance $500
  When user transfers $200 from checking to savings
  Then checking account balance is $800
  And savings account balance is $700
  And transaction is recorded in history

Scenario: Insufficient funds
  Given checking account has balance $50
  When user attempts to transfer $100
  Then transfer is rejected
  And error message is "Insufficient funds"
  And balances remain unchanged
```

### Healthcare

```gherkin
Feature: Appointment Scheduling

Scenario: Book available appointment
  Given Dr. Smith has availability on 2024-02-15 at 10:00
  When patient books appointment for that slot
  Then appointment is confirmed
  And patient receives confirmation email
  And slot is no longer available

Scenario: Cancel with advance notice
  Given patient has appointment on 2024-02-15
  When patient cancels 2 days before
  Then appointment is cancelled
  And slot becomes available
  And no cancellation fee is charged
```

---

## Best Practices

### Do This

| Practice | Bad | Good |
|----------|-----|------|
| **Collaborate Early** | Developer writes tests alone | Team discusses criteria together before coding |
| **Use Business Language** | "POST /api/users with valid payload" | "User completes registration form" |
| **Focus on Behavior** | "Click button with id='submit-btn'" | "User submits the form" |
| **Single Purpose** | Test multiple features in one scenario | Each scenario tests one specific behavior |
| **Independence** | Scenario B depends on Scenario A | Each scenario runs independently |

### Avoid This

| Anti-Pattern | Example |
|--------------|---------|
| **Implementation Details** | ❌ `Given database table "users" has record with id=5`<br>✅ `Given a registered user exists` |
| **Too Many Scenarios** | ❌ 50 scenarios for one feature<br>✅ Key examples in ATDD, edge cases in unit tests |
| **Vague Outcomes** | ❌ `Then system processes the request`<br>✅ `Then order status is "Processing" and email is sent` |

### ATDD Checklist

**Before Development:**
- [ ] Acceptance criteria defined collaboratively
- [ ] Criteria written in business language
- [ ] Examples cover happy path and edge cases
- [ ] Acceptance tests written and failing
- [ ] Team agrees on "done"

**During Development:**
- [ ] Implement to pass acceptance tests
- [ ] Run tests frequently
- [ ] Update tests if requirements change

**After Development:**
- [ ] All acceptance tests pass
- [ ] Demo to stakeholders
- [ ] Tests integrated into CI/CD

---

## Related Resources

- `base/testing-philosophy.md` - Overall testing strategy
- `base/specification-driven-development.md` - Spec-driven approach
- `languages/python/testing.md` - pytest-bdd examples
- `languages/typescript/testing.md` - Cucumber.js examples
- **Cucumber:** https://cucumber.io/docs/
- **behave:** https://behave.readthedocs.io/
- **ATDD by Example:** Markus Gärtner
