# AI-Assisted Development Best Practices

> **When to apply:** All development workflows involving AI coding assistants (Claude, Copilot, ChatGPT, etc.)

Principles and patterns for effective collaboration with AI coding assistants to maximize productivity while maintaining code quality.

## Table of Contents

- [Core Principles](#core-principles)
- [Development Workflow](#development-workflow)
- [Context Management](#context-management)
- [Iterative Refinement](#iterative-refinement)
- [Anti-Patterns to Avoid](#anti-patterns-to-avoid)
- [AI-Specific Best Practices](#ai-specific-best-practices)

---

## Core Principles

### 1. Simplicity First

**Rule:** Always prefer the simplest solution that meets requirements.

AI assistants can generate complex solutions. Your job is to push for simplicity.

**Why:**
- Simple code is easier to understand, test, and maintain
- Reduces bugs and cognitive load
- Faster development iterations
- Better long-term maintainability

**In Practice:**

```python
# ❌ Over-engineered AI suggestion
class UserDataAccessLayerFactory:
    def create_repository(self, db_type: str) -> AbstractUserRepository:
        if db_type == 'postgres':
            return PostgresUserRepository(
                connection_pool=ConnectionPoolFactory().create(),
                query_builder=QueryBuilderFactory().create(),
                cache=CacheFactory().create()
            )
        # ... more complexity

# ✅ Simple, direct solution
class UserRepository:
    def __init__(self, database_url: str):
        self.db = create_connection(database_url)

    def find_by_id(self, user_id: int) -> User:
        return self.db.query(User).filter_by(id=user_id).first()
```

**Guidelines:**
- Start with the minimal implementation
- Add complexity only when proven necessary
- Question every abstraction: "Do we need this now?"
- Prefer composition over deep inheritance
- Avoid premature optimization

### 2. Test-Driven Development with AI

**Rule:** Write tests first, then use AI to implement passing code.

**The TDD Cycle with AI:**

1. **Red** - Write failing test yourself
2. **Green** - Ask AI to implement minimal passing code
3. **Refactor** - Collaborate with AI to improve design
4. **Commit** - Commit working, tested code

**Why:**
- Tests prevent AI from over-engineering
- Clear specification reduces AI ambiguity
- Catches AI mistakes immediately
- Creates comprehensive test coverage
- Ensures code actually solves the problem

**Example Workflow:**

```python
# Step 1: YOU write the test (RED)
def test_calculate_discount_for_premium_users():
    """Premium users get 15% discount on orders over $100"""
    user = User(membership='premium')
    order = Order(total=150.00)

    discount = calculate_discount(user, order)

    assert discount == 22.50  # 15% of $150

# Step 2: ASK AI: "Implement calculate_discount to pass this test"
# AI generates implementation

# Step 3: REFACTOR with AI
# "Can you simplify the discount logic?"
# "Add type hints and docstrings"

# Step 4: COMMIT when tests pass
git commit -m "Add premium user discount calculation"
```

### 3. Progressive Enhancement

**Rule:** Build incrementally, adding features one at a time.

**Why:**
- Easier to verify each change works
- Reduces debugging complexity
- Maintains working system at each step
- AI performs better with focused tasks

**Approach:**

```
❌ Big Bang: "Build complete user authentication system with OAuth, 2FA, password reset, email verification"

✅ Progressive:
1. "Implement basic username/password login"
   → Test, verify, commit
2. "Add password hashing with bcrypt"
   → Test, verify, commit
3. "Add session management"
   → Test, verify, commit
4. "Add password reset flow"
   → Test, verify, commit
```

**Benefits:**
- Each step is testable and demonstrable
- Early detection of design issues
- Can ship partial functionality
- Clear rollback points

### 4. The Five-Try Rule

**Rule:** If AI fails to produce working code after 5 attempts, change your approach.

**Why:**
- Prevents wasted time on bad prompts
- Forces you to reassess the problem
- May indicate design/architecture issues
- Better to rethink than iterate blindly

**When AI Struggles:**

```
Try 1-2: Refine prompt, add examples
Try 3-4: Break problem into smaller pieces
Try 5: STOP and consider:
  - Is the problem too complex?
  - Do I need to redesign the approach?
  - Should I implement this part myself?
  - Do I need more context/understanding first?
```

**Better Alternatives:**
- Break into smaller subtasks
- Implement part manually to unblock
- Research the problem domain first
- Simplify requirements
- Seek human expert guidance

---

## Development Workflow

### Effective AI Prompting

**Clear, Specific Requests:**

```
❌ Vague: "Make this better"
✅ Specific: "Refactor extract_user_data() to use Pydantic models for validation"

❌ Ambiguous: "Add error handling"
✅ Specific: "Add try/except to handle FileNotFoundError when loading config.json, log error and return default config"

❌ Too broad: "Build authentication"
✅ Focused: "Create a login endpoint that accepts email/password and returns JWT token"
```

**Provide Context:**

```python
"""
Context: E-commerce checkout flow
Current: User cart stores items in memory (lost on refresh)
Goal: Persist cart to Redis with 24-hour TTL
Constraints: Must work with existing Cart class interface
"""

# AI can now generate appropriate solution
```

**Include Examples:**

```
"Create a user repository following this pattern:

class ProductRepository:
    def find_by_id(self, id: int) -> Product:
        return self.db.query(Product).filter_by(id=id).first()

    def save(self, product: Product):
        self.db.add(product)
        self.db.commit()

Now create UserRepository with find_by_email and save methods."
```

### Verification Workflow

**Always Verify AI Output:**

1. **Read the code** - Don't blindly accept
2. **Run tests** - Automated verification
3. **Check edge cases** - Test boundary conditions
4. **Review security** - Validate inputs, check for vulnerabilities
5. **Assess simplicity** - Could it be simpler?

**Checklist:**

```markdown
- [ ] Code compiles/runs without errors
- [ ] All tests pass
- [ ] Handles edge cases (null, empty, invalid input)
- [ ] No security vulnerabilities (injection, XSS, etc.)
- [ ] Follows project coding standards
- [ ] Clear variable/function names
- [ ] Includes necessary error handling
- [ ] Performance is acceptable
- [ ] Documentation/comments where needed
```

### Iterative Refinement

**Start Rough, Refine Gradually:**

```
Iteration 1: "Create basic user signup endpoint"
→ Get working implementation

Iteration 2: "Add email validation"
→ Enhance with validation

Iteration 3: "Add password strength requirements"
→ Add security constraints

Iteration 4: "Add rate limiting"
→ Production hardening
```

**Each iteration:**
- Maintains working code
- Adds one improvement
- Tests still pass
- Commitable state

---

## Context Management

### Provide Sufficient Context

**AI needs context to generate appropriate code:**

**Essential Context:**
- **Purpose**: What is this solving?
- **Constraints**: Technical limitations, requirements
- **Existing patterns**: How is similar code structured?
- **Dependencies**: What libraries/frameworks are available?
- **Error conditions**: What can go wrong?

**Example:**

```
Poor: "Create a function to process payments"

Good: "Create a process_payment function for our Django e-commerce app that:
- Accepts Payment object with amount, currency, payment_method
- Integrates with existing Stripe API wrapper (stripe_client)
- Returns PaymentResult with success/failure and transaction_id
- Raises PaymentError for invalid amounts or failed transactions
- Logs all payment attempts to payment_logger
- Follows existing service layer pattern in services/billing.py"
```

### Reference Existing Code

**Point AI to Examples:**

```
"Implement user deletion following the pattern in user_service.py:

See delete_product() in product_service.py for the soft-delete pattern:
- Set deleted_at timestamp
- Keep record in database
- Filter deleted items in queries

Apply the same pattern to User model."
```

### Manage Token Limits

**For Large Codebases:**

1. **Be selective** - Only share relevant files
2. **Use summaries** - Describe structure instead of full code
3. **Extract interfaces** - Share signatures, not implementations
4. **Break into chunks** - Handle one module at a time

---

## Iterative Refinement

### Start with Working Code

**Principle:** Working code > Perfect code

```
Iteration 1: Make it work
Iteration 2: Make it right
Iteration 3: Make it fast
```

**Example:**

```python
# Iteration 1: Working but naive
def search_users(query: str):
    users = User.query.all()  # Load everything
    return [u for u in users if query.lower() in u.name.lower()]

# Iteration 2: More efficient
def search_users(query: str):
    return User.query.filter(
        User.name.ilike(f'%{query}%')
    ).limit(100).all()

# Iteration 3: Production-ready
def search_users(query: str, limit: int = 100):
    if not query or len(query) < 2:
        raise ValueError("Query must be at least 2 characters")

    return User.query.filter(
        User.name.ilike(f'%{query}%'),
        User.deleted_at.is_(None)  # Exclude deleted
    ).order_by(User.name).limit(limit).all()
```

### Refactoring with AI

**Effective Refactoring Requests:**

```
✅ "Extract the email validation logic into a separate function"
✅ "Replace nested if statements with guard clauses"
✅ "Simplify this function - it's doing too many things"
✅ "Make this code more testable by extracting external dependencies"
```

**Anti-patterns:**

```
❌ "Make this code better" (too vague)
❌ "Optimize everything" (premature optimization)
❌ "Use more design patterns" (complexity for complexity's sake)
```

---

## Anti-Patterns to Avoid

### 1. Blindly Accepting AI Code

**Problem:** Accepting generated code without review

**Why It's Bad:**
- AI can generate insecure code
- May not follow project conventions
- Could have subtle bugs
- Might over-engineer solutions

**Solution:**
- Always review AI-generated code
- Test thoroughly
- Verify security implications
- Check for simpler alternatives

### 2. Over-Engineering from AI Suggestions

**Problem:** AI suggests complex enterprise patterns for simple problems

**Example:**

```python
# AI might suggest this for a simple config loader:
class ConfigurationManagementSystemFactory:
    def create_loader(self) -> AbstractConfigurationLoader:
        return ConfigurationLoaderFactory().create(
            validator=ConfigValidatorFactory().create(),
            parser=ConfigParserFactory().create(),
            cache=ConfigCacheFactory().create()
        )

# When you just need:
def load_config():
    with open('config.json') as f:
        return json.load(f)
```

**Solution:**
- Question every abstraction
- Start simple, add complexity only when needed
- Ask: "Can this be simpler?"

### 3. Scope Creep in Prompts

**Problem:** Asking AI to do too much at once

**Example:**

```
❌ "Create a complete user management system with authentication, authorization,
    profile management, password reset, email verification, OAuth integration,
    2FA, session management, and admin dashboard"

✅ "Create a User model with email and hashed password fields"
```

**Solution:**
- Break large tasks into small, focused requests
- Build incrementally
- Test each piece before moving forward

### 4. Ignoring Test Failures

**Problem:** Continuing development despite failing tests

**Why It's Bad:**
- Compounds problems
- Makes debugging harder
- Breaks confidence in test suite
- Can ship broken code

**Solution:**
- **STOP** immediately when tests fail
- Fix root cause before proceeding
- Never mark work complete with failing tests
- Add tests for new bugs found

### 5. Missing Security Review

**Problem:** Not reviewing AI code for security issues

**Common AI Security Mistakes:**
- SQL injection vulnerabilities
- Missing input validation
- Insecure password handling
- Exposed secrets in code
- Missing authentication/authorization
- XSS vulnerabilities

**Example:**

```python
# ❌ AI-generated SQL injection vulnerability
def get_user(username):
    query = f"SELECT * FROM users WHERE username = '{username}'"
    return db.execute(query)

# ✅ Secure parameterized query
def get_user(username):
    query = "SELECT * FROM users WHERE username = ?"
    return db.execute(query, (username,))
```

**Solution:**
- Review all AI code for security
- Use linters/security scanners
- Validate all inputs
- Follow OWASP guidelines

### 6. Lack of Context Leading to Wrong Solutions

**Problem:** Insufficient context causes AI to make wrong assumptions

**Example:**

```
Prompt: "Add caching to user lookup"

AI assumes: In-memory cache (lost on restart)
Reality: Multi-server deployment needs Redis

Result: Code works locally, fails in production
```

**Solution:**
- Provide deployment context
- Mention scaling requirements
- Specify constraints upfront
- Review against actual use case

---

## AI-Specific Best Practices

### Version Control Integration

**Commit Frequently:**

```bash
# After each working AI-generated feature
git add .
git commit -m "Add user email validation

Implemented with AI assistance:
- Email format validation using regex
- Domain validation against allowed list
- Test coverage for edge cases"

# Small, focused commits
git log --oneline
a3f9d2c Add email validation
8e4c1b7 Add user model
c5d2f8e Add database migration
```

### Documentation

**Document AI-Assisted Code:**

```python
def calculate_compound_interest(
    principal: float,
    rate: float,
    time: int,
    compounds_per_year: int = 12
) -> float:
    """
    Calculate compound interest using the formula: A = P(1 + r/n)^(nt)

    Args:
        principal: Initial investment amount
        rate: Annual interest rate (as decimal, e.g., 0.05 for 5%)
        time: Investment period in years
        compounds_per_year: Number of times interest compounds per year

    Returns:
        Final amount including interest

    Example:
        >>> calculate_compound_interest(1000, 0.05, 10, 12)
        1647.01

    Note: Formula verified against financial calculators.
          Implementation assisted by AI, reviewed for accuracy.
    """
    return principal * (1 + rate / compounds_per_year) ** (compounds_per_year * time)
```

### Code Review

**Review AI Code Like Human Code:**

- Check logic correctness
- Verify test coverage
- Assess code clarity
- Look for security issues
- Ensure proper error handling
- Validate edge cases
- Check performance implications

**Checklist:**

```markdown
## AI Code Review Checklist

### Correctness
- [ ] Logic is sound
- [ ] Tests pass
- [ ] Edge cases handled

### Security
- [ ] Inputs validated
- [ ] No injection vulnerabilities
- [ ] Secrets not hardcoded
- [ ] Auth/authz checked

### Quality
- [ ] Follows coding standards
- [ ] Clear naming
- [ ] Appropriate comments
- [ ] Error handling present

### Simplicity
- [ ] Not over-engineered
- [ ] Could it be simpler?
- [ ] Necessary abstractions only
```

### Continuous Learning

**Improve Your AI Collaboration:**

- **Save good prompts** - Build a library of effective patterns
- **Learn from outputs** - Understand what works, what doesn't
- **Iterate on prompts** - Refine based on results
- **Share knowledge** - Document team best practices
- **Stay updated** - AI capabilities evolve rapidly

**Example Prompt Library:**

```markdown
# Effective Prompts

## Refactoring
"Extract {specific functionality} into a separate function with type hints and docstring"

## Testing
"Write pytest tests for {function_name} covering happy path, edge cases, and error conditions"

## Bug Fixing
"Fix the {specific bug} in {function/file}. The issue is that {description}. Expected behavior: {expected}"

## Code Review
"Review this code for security vulnerabilities, particularly {concern area}"
```

---

## Summary: AI-Assisted Development Principles

1. **Simplicity First** - Prefer simple solutions over complex ones
2. **Test-Driven** - Write tests first, use AI for implementation
3. **Progressive** - Build incrementally, one feature at a time
4. **Five-Try Rule** - Change approach after 5 failed attempts
5. **Verify Always** - Review all AI code thoroughly
6. **Provide Context** - Give AI sufficient information
7. **Iterate** - Start working, refine gradually
8. **Avoid Over-Engineering** - Question every abstraction
9. **Security Review** - Check for vulnerabilities
10. **Commit Frequently** - Small, tested, working commits

---

## Related Resources

- See `base/testing-philosophy.md` for testing best practices
- See `base/architecture-principles.md` for design principles
- See `base/refactoring-patterns.md` for code improvement techniques
- See `base/code-quality.md` for quality standards
