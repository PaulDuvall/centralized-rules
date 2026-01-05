# AI-Assisted Development Best Practices

> **When to apply:** All development workflows involving AI coding assistants (Claude, Copilot, ChatGPT, etc.)

Principles for effective collaboration with AI coding assistants while maintaining code quality.

## Core Principles

### 1. Simplicity First

- Prefer the simplest solution that meets requirements
- Start with minimal implementation
- Add complexity only when proven necessary
- Question every abstraction: "Do we need this now?"
- Avoid premature optimization

### 2. Test-Driven Development with AI

**TDD Cycle:**
1. **Red** - Write failing test yourself
2. **Green** - Ask AI to implement minimal passing code
3. **Refactor** - Collaborate with AI to improve design
4. **Commit** - Commit working, tested code

**Why:**
- Tests prevent AI over-engineering
- Clear specification reduces ambiguity
- Catches AI mistakes immediately
- Creates comprehensive coverage

### 3. Progressive Enhancement

- Build incrementally, one feature at a time
- Test and commit each step
- Maintain working system throughout
- Break large tasks into focused requests

### 4. The Five-Try Rule

If AI fails to produce working code after 5 attempts, change your approach:

- Try 1-2: Refine prompt, add examples
- Try 3-4: Break problem into smaller pieces
- Try 5: STOP and reassess (simplify, research, or implement manually)

## Development Workflow

### Effective AI Prompting

**Clear, Specific Requests:**

```
❌ Vague: "Make this better"
✅ Specific: "Refactor extract_user_data() to use Pydantic models for validation"

❌ Too broad: "Build authentication"
✅ Focused: "Create login endpoint that accepts email/password and returns JWT"
```

**Provide Context:**
- Purpose: What is this solving?
- Constraints: Technical limitations, requirements
- Existing patterns: How is similar code structured?
- Dependencies: Available libraries/frameworks
- Error conditions: What can go wrong?

**Include Examples:**

Point AI to existing code patterns to follow.

### Verification Workflow

**Always verify AI output:**

1. Read the code - Don't blindly accept
2. Run tests - Automated verification
3. Check edge cases - Test boundary conditions
4. Review security - Validate inputs, check vulnerabilities
5. Assess simplicity - Could it be simpler?

**Checklist:**
- [ ] Code compiles/runs without errors
- [ ] All tests pass
- [ ] Handles edge cases (null, empty, invalid)
- [ ] No security vulnerabilities
- [ ] Follows project standards
- [ ] Clear names
- [ ] Proper error handling
- [ ] Performance acceptable
- [ ] Documentation where needed

## Context Management

### Provide Sufficient Context

**Essential:**
- Purpose and constraints
- Existing patterns to follow
- Available dependencies
- Error conditions

**Example:**

```
Poor: "Create a function to process payments"

Good: "Create process_payment for Django e-commerce app that:
- Accepts Payment object with amount, currency, payment_method
- Integrates with stripe_client wrapper
- Returns PaymentResult with success/failure and transaction_id
- Raises PaymentError for invalid amounts
- Logs to payment_logger
- Follows pattern in services/billing.py"
```

### Manage Token Limits

For large codebases:
- Be selective - only share relevant files
- Use summaries instead of full code
- Share interfaces, not implementations
- Handle one module at a time

## Anti-Patterns to Avoid

### 1. Blindly Accepting AI Code

- Always review generated code
- Test thoroughly
- Verify security implications
- Check for simpler alternatives

### 2. Over-Engineering

AI often suggests complex enterprise patterns for simple problems.

**Solution:**
- Question every abstraction
- Start simple, add complexity only when needed
- Ask: "Can this be simpler?"

### 3. Scope Creep in Prompts

```
❌ "Create complete user management with auth, OAuth, 2FA, email verification, admin dashboard"
✅ "Create User model with email and hashed password fields"
```

### 4. Ignoring Test Failures

- STOP immediately when tests fail
- Fix root cause before proceeding
- Never mark work complete with failing tests
- Add tests for new bugs

### 5. Missing Security Review

**Common AI mistakes:**
- SQL injection vulnerabilities
- Missing input validation
- Insecure password handling
- Exposed secrets
- Missing authentication/authorization
- XSS vulnerabilities

**Solution:**
- Review all AI code for security
- Use linters/security scanners
- Validate all inputs
- Follow OWASP guidelines

### 6. Insufficient Context

Provide deployment context, scaling requirements, and constraints upfront.

## Best Practices

### Commit Frequently

Small, focused commits after each working feature:

```bash
git commit -m "Add user email validation

- Email format validation using regex
- Domain validation against allowed list
- Test coverage for edge cases"
```

### Document AI-Assisted Code

Add clear docstrings and comments, noting any AI-specific considerations.

### Code Review Checklist

**Correctness:**
- [ ] Logic is sound
- [ ] Tests pass
- [ ] Edge cases handled

**Security:**
- [ ] Inputs validated
- [ ] No injection vulnerabilities
- [ ] Secrets not hardcoded
- [ ] Auth/authz checked

**Quality:**
- [ ] Follows coding standards
- [ ] Clear naming
- [ ] Appropriate comments
- [ ] Error handling present

**Simplicity:**
- [ ] Not over-engineered
- [ ] Could it be simpler?
- [ ] Necessary abstractions only

### Continuous Learning

- Save good prompts - build a library
- Learn from outputs - understand patterns
- Iterate on prompts - refine based on results
- Share knowledge - document team practices
- Stay updated - capabilities evolve

## Summary

1. **Simplicity First** - Prefer simple solutions
2. **Test-Driven** - Write tests first
3. **Progressive** - Build incrementally
4. **Five-Try Rule** - Change approach after 5 failures
5. **Verify Always** - Review all AI code
6. **Provide Context** - Give sufficient information
7. **Iterate** - Start working, refine gradually
8. **Avoid Over-Engineering** - Question abstractions
9. **Security Review** - Check for vulnerabilities
10. **Commit Frequently** - Small, tested commits
