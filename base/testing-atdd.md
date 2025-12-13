# Acceptance Test-Driven Development (ATDD)

> **When to apply:** All feature development, especially when collaborating with stakeholders

Acceptance Test-Driven Development (ATDD) is a collaborative practice where developers, testers, and business stakeholders define acceptance criteria and tests before implementation begins.

## Table of Contents

- [What is ATDD?](#what-is-atdd)
- [ATDD vs TDD vs BDD](#atdd-vs-tdd-vs-bdd)
- [The ATDD Process](#the-atdd-process)
- [Writing Acceptance Criteria](#writing-acceptance-criteria)
- [Given-When-Then Format](#given-when-then-format)
- [Acceptance Testing Frameworks](#acceptance-testing-frameworks)
- [Executable Specifications](#executable-specifications)
- [ATDD Examples by Domain](#atdd-examples-by-domain)
- [Best Practices](#best-practices)

---

## What is ATDD?

### Core Concept

**ATDD** is a development methodology where acceptance criteria are written collaboratively before coding begins, and these criteria drive the development process.

**Key Participants:**
- **Product Owner / Business Analyst:** Defines business value
- **Developer:** Implements functionality
- **Tester / QA:** Ensures quality and edge cases

### ATDD Cycle

```
1. Discuss → Define acceptance criteria collaboratively
2. Distill → Create executable acceptance tests
3. Develop → Implement code to pass tests
4. Demo    → Show working software to stakeholders
```

### Benefits

✅ **Shared Understanding** - Everyone agrees on what "done" means
✅ **Living Documentation** - Tests document expected behavior
✅ **Fewer Defects** - Issues caught before coding
✅ **Faster Feedback** - Stakeholders see working features early
✅ **Reduced Rework** - Clear requirements upfront

---

## ATDD vs TDD vs BDD

### Comparison

| Aspect | ATDD | TDD | BDD |
|--------|------|-----|-----|
| **Focus** | Acceptance criteria | Unit tests | Behavior scenarios |
| **Participants** | Team + stakeholders | Developers | Team + stakeholders |
| **Scope** | Feature/story level | Function/class level | Feature/behavior level |
| **Language** | Business terms | Technical terms | Business + technical |
| **Tests Written By** | Collaborative | Developers | Collaborative |
| **When** | Before development | Before coding | Before development |

### How They Work Together

```
ATDD (Acceptance level)
  └─> BDD (Behavior scenarios)
       └─> TDD (Unit tests)
            └─> Implementation
```

**Example:**
```
ATDD: "User should be able to purchase a product"
  └─> BDD: "Given a user has items in cart, when they checkout, then order is created"
       └─> TDD: test_calculate_order_total() → calculate_order_total()
```

---

## The ATDD Process

### Step 1: Discuss

**Collaborative Meeting** (Three Amigos):
- Product Owner presents user story
- Team asks clarifying questions
- Define acceptance criteria together

**Example Discussion:**

```
Story: As a user, I want to reset my password

Questions:
- How long should reset links be valid?
- What happens if link expires?
- Should users be notified by email?
- Any password complexity requirements?
- Can users reuse old passwords?

Decisions:
- Reset link valid for 1 hour
- Show error message if expired
- Send email with reset link
- Password must be 8+ chars with 1 number, 1 uppercase
- Cannot reuse last 5 passwords
```

### Step 2: Distill

**Convert criteria to executable tests:**

```python
# test_password_reset.py
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

    # Try to use token after 61 minutes
    with time_travel(minutes=61):
        response = reset_password(token, new_password='NewPass123!')

        assert response.status_code == 400
        assert response.json()['error'] == 'Reset link expired'

def test_password_must_meet_complexity_requirements():
    """AC3: Password must be 8+ chars with number and uppercase"""
    user = create_user()
    token = generate_reset_token(user)

    # Test weak passwords
    weak_passwords = [
        'short',          # Too short
        'alllowercase',   # No uppercase or number
        'ALLUPPERCASE',   # No lowercase or number
        'NoNumbers',      # No number
    ]

    for weak_pass in weak_passwords:
        response = reset_password(token, new_password=weak_pass)
        assert response.status_code == 400
        assert 'complexity requirements' in response.json()['error']

    # Test strong password
    response = reset_password(token, new_password='ValidPass123!')
    assert response.status_code == 200
```

### Step 3: Develop

**Red-Green-Refactor:**

```python
# 1. RED: Tests fail (not implemented yet)
$ pytest test_password_reset.py
# All tests fail

# 2. GREEN: Implement minimum code to pass
def request_password_reset(email):
    user = User.get_by_email(email)
    if not user:
        return Response(status=404)

    token = create_reset_token(user, expires_in=3600)  # 1 hour
    send_email(
        to=user.email,
        subject='Password Reset',
        body=f'Click here to reset: {RESET_URL}?token={token}'
    )
    return Response(status=200)

# 3. REFACTOR: Clean up, extract helpers
# Tests still pass
```

### Step 4: Demo

**Show working feature to stakeholders:**
- Run acceptance tests live
- Demonstrate in staging environment
- Get feedback and iterate

---

## Writing Acceptance Criteria

### INVEST Criteria for Stories

**Independent** - Can be developed separately
**Negotiable** - Details can be clarified
**Valuable** - Delivers business value
**Estimable** - Team can estimate effort
**Small** - Fits in one iteration
**Testable** - Has clear acceptance criteria

### Good Acceptance Criteria

**Example: User Login**

```
AC1: User can log in with valid credentials
  - Given a registered user
  - When they enter correct email and password
  - Then they are redirected to dashboard
  - And session is created

AC2: User cannot log in with invalid password
  - Given a registered user
  - When they enter incorrect password
  - Then they see error "Invalid credentials"
  - And session is not created
  - And account is not locked (unless 5+ failed attempts)

AC3: User account locks after 5 failed attempts
  - Given a registered user
  - When they fail login 5 times
  - Then account is temporarily locked for 15 minutes
  - And user receives email notification

AC4: User can log in after lockout period expires
  - Given a locked account
  - When 15 minutes have passed
  - Then user can log in with correct credentials
```

### Acceptance Criteria Template

```
Given [initial context/state]
When [action/event occurs]
Then [expected outcome]
And [additional outcomes]
```

---

## Given-When-Then Format

### Structure

**Given** - Set up the initial state
**When** - Perform the action
**Then** - Verify the outcome
**And** - Additional conditions or outcomes

### Examples

**E-commerce Purchase:**
```gherkin
Feature: Checkout Process

Scenario: Successful purchase with credit card
  Given a user has 3 items in their cart
  And items total $50
  And user has valid credit card on file
  When user clicks "Checkout"
  And enters shipping address
  And confirms payment
  Then order is created with status "Processing"
  And user receives order confirmation email
  And items are removed from cart
  And credit card is charged $50 + tax + shipping
```

**API Authentication:**
```gherkin
Feature: API Authentication

Scenario: Access protected endpoint with valid token
  Given a valid JWT token
  When user makes GET request to /api/profile
  And includes token in Authorization header
  Then response status is 200
  And response contains user profile data

Scenario: Access protected endpoint without token
  Given no authentication token
  When user makes GET request to /api/profile
  Then response status is 401
  And response contains error "Authentication required"
```

---

## Acceptance Testing Frameworks

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
    And new password meets complexity requirements
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

@then('reset link expires in 1 hour')
def step_link_expires(context):
    email = latest_email()
    token = extract_token_from_email(email)
    assert token_expires_in(token) == 3600  # 1 hour in seconds
```

### TypeScript/JavaScript - Cucumber

**features/checkout.feature:**
```gherkin
Feature: Shopping Cart Checkout

  Scenario: Complete purchase
    Given user has items in cart:
      | product  | quantity | price |
      | Widget   | 2        | 10.00 |
      | Gadget   | 1        | 25.00 |
    When user proceeds to checkout
    And enters shipping address
    And confirms payment
    Then order total is $45.00
    And order confirmation is displayed
```

**steps/checkout.steps.ts:**
```typescript
import { Given, When, Then } from '@cucumber/cucumber';
import { expect } from 'chai';

Given('user has items in cart:', async function (dataTable) {
  const items = dataTable.hashes();
  for (const item of items) {
    await this.cart.addItem({
      product: item.product,
      quantity: parseInt(item.quantity),
      price: parseFloat(item.price)
    });
  }
});

When('user proceeds to checkout', async function () {
  this.checkoutPage = await this.cart.checkout();
});

Then('order total is ${amount}', async function (amount: string) {
  const total = await this.checkoutPage.getTotal();
  expect(total).to.equal(parseFloat(amount));
});
```

### pytest with pytest-bdd

```python
# features/user_registration.feature
Feature: User Registration

  Scenario: Register with valid information
    Given registration form is displayed
    When user enters:
      | field    | value               |
      | email    | new@example.com     |
      | username | newuser             |
      | password | SecurePass123!      |
    And clicks "Register"
    Then account is created
    And welcome email is sent

# tests/test_registration.py
from pytest_bdd import scenarios, given, when, then, parsers

scenarios('../features/user_registration.feature')

@given('registration form is displayed')
def registration_form(browser):
    browser.get('/register')

@when(parsers.parse('user enters:\n{data}'))
def enter_user_data(browser, data):
    # Parse data table and fill form
    pass

@then('account is created')
def verify_account_created(db):
    user = db.query(User).filter_by(email='new@example.com').first()
    assert user is not None
```

---

## Executable Specifications

### Specification by Example

**Before (Vague):**
```
The system should handle large files efficiently
```

**After (Specific Examples):**
```
Scenario: Upload 10MB file
  Given a file of size 10MB
  When user uploads file
  Then upload completes within 5 seconds
  And progress indicator shows percentage

Scenario: Upload 100MB file
  Given a file of size 100MB
  When user uploads file
  Then upload uses chunked transfer
  And upload completes within 60 seconds
  And user can pause/resume upload
```

### Living Documentation

**Benefits:**
- Acceptance tests serve as documentation
- Always up-to-date (tests run in CI)
- Executable specifications
- Shared understanding

**Example Documentation Generated from Tests:**
```markdown
# User Authentication

## Feature: Login

### ✅ Successful login with valid credentials
- Status: PASSING
- Last run: 2024-01-15 10:30:00

### ✅ Failed login with invalid password
- Status: PASSING
- Last run: 2024-01-15 10:30:05

### ✅ Account lockout after failed attempts
- Status: PASSING
- Last run: 2024-01-15 10:30:10
```

---

## ATDD Examples by Domain

### E-Commerce

```gherkin
Feature: Product Search

Scenario: Search by product name
  Given products exist:
    | name          | category | price |
    | Blue Shirt    | Clothing | 29.99 |
    | Red Pants     | Clothing | 39.99 |
    | Green Socks   | Clothing | 9.99  |
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
  And account balances remain unchanged
```

### Healthcare

```gherkin
Feature: Appointment Scheduling

Scenario: Book available appointment slot
  Given Dr. Smith has availability:
    | date       | time  | duration |
    | 2024-02-15 | 10:00 | 30 min   |
    | 2024-02-15 | 14:00 | 30 min   |
  When patient books appointment for 2024-02-15 at 10:00
  Then appointment is confirmed
  And patient receives confirmation email
  And slot is no longer available to other patients

Scenario: Cancel appointment with 24hr notice
  Given patient has appointment on 2024-02-15
  When patient cancels 2 days before appointment
  Then appointment is cancelled
  And slot becomes available
  And no cancellation fee is charged
```

---

## Best Practices

### ✅ Do This

**1. Collaborate Early**
```
❌ Developer writes tests alone
✅ Team discusses acceptance criteria together before coding
```

**2. Use Business Language**
```
❌ "When POST request sent to /api/users with valid payload"
✅ "When user completes registration form"
```

**3. Focus on Behavior, Not Implementation**
```
❌ "When user clicks button with id='submit-btn'"
✅ "When user submits the form"
```

**4. One Scenario, One Purpose**
```
❌ Test multiple features in one scenario
✅ Each scenario tests one specific behavior
```

**5. Make Tests Independent**
```
❌ Scenario B depends on Scenario A running first
✅ Each scenario can run independently
```

### ❌ Avoid This

**1. Implementation Details in Scenarios**
```
❌ Given database table "users" has record with id=5
✅ Given a registered user exists
```

**2. Too Many Scenarios**
```
❌ 50 scenarios for one feature
✅ Focus on key examples, use unit tests for edge cases
```

**3. Unclear Expected Outcomes**
```
❌ Then system processes the request
✅ Then order status changes to "Processing" and email is sent
```

---

## ATDD Checklist

Before starting development:
- [ ] Acceptance criteria defined collaboratively
- [ ] Criteria written in business language
- [ ] Examples cover happy path and edge cases
- [ ] Acceptance tests written and failing
- [ ] Team agrees on what "done" means

During development:
- [ ] Implement code to pass acceptance tests
- [ ] Run tests frequently
- [ ] Update tests if requirements change
- [ ] Keep stakeholders informed of progress

After development:
- [ ] All acceptance tests pass
- [ ] Demo working feature to stakeholders
- [ ] Update documentation if needed
- [ ] Acceptance tests run in CI/CD

---

## Related Resources

- See `base/testing-philosophy.md` for overall testing strategy
- See `base/specification-driven-development.md` for spec-driven approach
- See `languages/python/testing.md` for pytest-bdd examples
- See `languages/typescript/testing.md` for Cucumber.js examples
- **Cucumber Documentation:** https://cucumber.io/docs/
- **behave Documentation:** https://behave.readthedocs.io/
- **ATDD by Example (Book):** Markus Gärtner
