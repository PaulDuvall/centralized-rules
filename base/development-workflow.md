# Development Workflow
<!-- TIP: Ship small, ship often - fast feedback wins -->

> **When to apply:** All development work across any language or framework

## Core Development Cycle

```
1. Plan → 2. Implement → 3. Test → 4. Refactor → 5. Review → 6. Commit → 7. Deploy
```

### Detailed Steps

**1. Plan**
- Understand requirements clearly
- Break down into manageable tasks (1-4 hours)
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
- Keep it simple
- Optimize only if needed

**5. Review**
- Self-review changes
- Run linters/formatters
- Check security implications
- Ensure documentation updated

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

### Breaking Down Work

- **Task size:** Aim for 1-4 hour tasks
- **Too large?** Break into subtasks
- **Dependencies:** Identify what needs to happen first
- **Priorities:** Work on highest impact first

### Task States

- **Todo** - Not started
- **In Progress** - Currently working
- **Blocked** - Waiting on something
- **In Review** - Under review
- **Done** - Completed and deployed

## Code Review

### For Authors

- Self-review first
- Keep changes focused (one logical change per PR)
- Write clear descriptions (what and why)
- Add tests
- Respond to feedback constructively

### For Reviewers

- Be constructive (suggest improvements)
- Focus on substance (logic, security, maintainability)
- Ask questions to understand
- Acknowledge good work
- Review promptly

## Continuous Integration

### Pre-Commit

- Run tests locally
- Run linters/formatters
- Check for secrets
- Verify build succeeds

### CI Pipeline

- Automated tests
- Code quality checks
- Security scanning
- Build verification
- Deployment (if passing)

## Documentation

### What to Document

- **API contracts** - Function signatures and behavior
- **Architecture decisions** - Why choices were made
- **Setup instructions** - How to get started
- **Usage examples** - How to use the code
- **Edge cases** - Non-obvious behavior

### Where to Document

- **Inline comments** - Complex logic
- **Function docs** - All public APIs
- **README** - Project overview and setup
- **Architecture docs** - High-level design
- **Runbooks** - Operational procedures

## Debugging Process

1. **Reproduce** - Consistently trigger the bug
2. **Isolate** - Narrow down where problem is
3. **Understand** - Why is it happening?
4. **Fix** - Address root cause, not symptoms
5. **Test** - Verify fix works, doesn't break others
6. **Prevent** - Add test to catch regression

### Techniques

- Read error messages carefully
- Use debugger to step through code
- Add logging to trace execution
- Simplify to isolate issue
- Ask for help when stuck

## Performance Optimization

### When to Optimize

- **Measure first** - Don't guess at bottlenecks
- **Focus on hot paths** - Optimize what matters
- **After correctness** - Make it work, then make it fast
- **When needed** - Premature optimization wastes time

### Process

1. **Measure** - Profile to find bottlenecks
2. **Optimize** - Improve the hot path
3. **Measure again** - Verify improvement
4. **Test** - Ensure still correct
5. **Document** - Explain optimizations

## Technical Debt

### Managing Debt

- Acknowledge and track known issues
- Prioritize (not all debt is equal)
- Pay down regularly
- Prevent new debt through quality standards
- Refactor continuously

### When to Take On Debt

- Deliberate decision (understand trade-offs)
- Time-boxed (plan to address soon)
- Documented (record what and why)
- Rare (exception, not rule)

## Collaboration

### Working with Team

- Communicate clearly (share context and decisions)
- Ask questions (don't assume)
- Share knowledge (help others learn)
- Give feedback (constructive and timely)
- Be reliable (do what you commit to)

### Pair Programming

- Rotate driver (take turns typing)
- Think aloud (share reasoning)
- Ask questions (understand decisions)
- Take breaks (maintain focus)
- Learn from each other

## Continuous Learning

- Read code to learn from others
- Try new things and experiment
- Follow best practices and patterns
- Get feedback through code reviews
- Share knowledge (teaching reinforces learning)

### Growth Mindset

- Mistakes are learning opportunities
- Always improving
- Seek feedback and embrace criticism
- Challenge yourself
- Help others grow

## Common Pitfalls

### Avoid

- ❌ Skipping tests to go faster
- ❌ Committing failing code
- ❌ Ignoring code review feedback
- ❌ Taking shortcuts on security
- ❌ Not documenting decisions
- ❌ Optimizing prematurely
- ❌ Building without understanding requirements
- ❌ Forgetting to commit/push work

### Do Instead

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

## Success Metrics

- **Velocity** - Delivering features consistently
- **Quality** - Low bug rate, high test coverage
- **Maintainability** - Easy to change code
- **Reliability** - Systems stay up
- **Team satisfaction** - Enjoyable work environment
