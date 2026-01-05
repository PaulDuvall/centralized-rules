# Development Workflow
<!-- TIP: Ship small, ship often - fast feedback wins -->

> **Scope:** All development work across any language or framework

## Core Development Cycle

```
Plan → Implement → Test → Refactor → Review → Commit → Deploy
```

**1. Plan**
- Understand requirements clearly
- Break into 1-4 hour tasks
- Identify dependencies and risks
- Design approach before coding

**2. Implement**
- Write clean, readable code
- Follow language conventions
- Keep functions small and focused
- Handle errors properly

**3. Test**
- Write tests for new code
- Run existing tests
- Achieve adequate coverage
- All tests must pass

**4. Refactor**
- Extract duplicated code
- Improve naming
- Simplify complexity
- Optimize only if needed

**5. Review**
- Self-review changes
- Run linters/formatters
- Check security implications
- Update documentation

**6. Commit**
- Make atomic commits
- Write clear commit messages
- Commit frequently
- Push regularly

**7. Deploy**
- Verify in staging
- Run deployment checks
- Monitor for issues
- Be ready to rollback

## Task Management

**Breaking Down Work:**
- Task size: 1-4 hours
- Too large? Break into subtasks
- Identify dependencies
- Prioritize highest impact

**Task States:**
- Todo, In Progress, Blocked, In Review, Done

## Code Review

**Authors:**
- Self-review first
- Keep changes focused (one logical change per PR)
- Write clear descriptions (what and why)
- Add tests
- Respond constructively

**Reviewers:**
- Be constructive, suggest improvements
- Focus on logic, security, maintainability
- Ask questions to understand
- Acknowledge good work
- Review promptly

## Continuous Integration

**Pre-Commit:**
- Run tests locally
- Run linters/formatters
- Check for secrets
- Verify build succeeds

**CI Pipeline:**
- Automated tests
- Code quality checks
- Security scanning
- Build verification
- Deployment (if passing)

## Documentation

**What to Document:**
- API contracts - Function signatures and behavior
- Architecture decisions - Why choices were made
- Setup instructions - How to get started
- Usage examples - How to use the code
- Edge cases - Non-obvious behavior

**Where to Document:**
- Inline comments - Complex logic
- Function docs - All public APIs
- README - Project overview and setup
- Architecture docs - High-level design
- Runbooks - Operational procedures

## Debugging Process

1. **Reproduce** - Consistently trigger the bug
2. **Isolate** - Narrow down location
3. **Understand** - Determine root cause
4. **Fix** - Address root cause, not symptoms
5. **Test** - Verify fix works, doesn't break others
6. **Prevent** - Add test to catch regression

**Techniques:**
- Read error messages carefully
- Use debugger to step through
- Add logging to trace execution
- Simplify to isolate issue
- Ask for help when stuck

## Performance Optimization

**When to Optimize:**
- Measure first (don't guess at bottlenecks)
- Focus on hot paths (optimize what matters)
- After correctness (make it work, then fast)
- When needed (premature optimization wastes time)

**Process:**
1. Measure - Profile to find bottlenecks
2. Optimize - Improve the hot path
3. Measure again - Verify improvement
4. Test - Ensure still correct
5. Document - Explain optimizations

## Technical Debt

**Managing Debt:**
- Acknowledge and track known issues
- Prioritize (not all debt is equal)
- Pay down regularly
- Prevent new debt through quality standards
- Refactor continuously

**When to Take On Debt:**
- Deliberate decision (understand trade-offs)
- Time-boxed (plan to address soon)
- Documented (record what and why)
- Rare (exception, not rule)

## Common Pitfalls

**Avoid:**
- ❌ Skipping tests to go faster
- ❌ Committing failing code
- ❌ Ignoring code review feedback
- ❌ Taking shortcuts on security
- ❌ Not documenting decisions
- ❌ Optimizing prematurely
- ❌ Building without understanding requirements
- ❌ Forgetting to commit/push work

**Do Instead:**
- ✅ Write tests as you code
- ✅ Commit only passing code
- ✅ Engage with reviewers
- ✅ Security first mindset
- ✅ Document as you go
- ✅ Measure before optimizing
- ✅ Clarify requirements upfront
- ✅ Commit and push frequently

## Golden Rules

1. **Test everything** - All tests must pass
2. **Commit frequently** - Small, focused commits
3. **Refactor always** - Keep code clean
4. **Security first** - Never compromise
5. **Document well** - Code is read more than written
6. **Communicate clearly** - Share context
7. **Learn continuously** - Always improving
