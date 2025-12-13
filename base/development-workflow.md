# Development Workflow

> **When to apply:** All development work across any language or framework

## Core Development Cycle

### Standard Workflow

```
1. Plan
   ↓
2. Implement
   ↓
3. Test
   ↓
4. Refactor
   ↓
5. Review
   ↓
6. Commit
   ↓
7. Deploy
```

### Detailed Steps

#### 1. Plan
- Understand requirements clearly
- Break down into manageable tasks
- Identify dependencies and risks
- Design approach before coding
- Consider edge cases

#### 2. Implement
- Write clean, readable code
- Follow language conventions
- Keep functions small and focused
- Add appropriate documentation
- Handle errors properly

#### 3. Test
- Write tests for new code
- Run existing tests
- Achieve adequate coverage
- Test edge cases
- All tests must pass

#### 4. Refactor
- Review code quality
- Extract duplicated code
- Improve naming
- Optimize if needed
- Keep it simple

#### 5. Review
- Self-review changes
- Run linters/formatters
- Check security implications
- Verify tests pass
- Ensure documentation updated

#### 6. Commit
- Make atomic commits
- Write clear commit messages
- Commit frequently
- Push regularly
- Keep commits focused

#### 7. Deploy
- Verify in staging
- Run deployment checks
- Monitor for issues
- Be ready to rollback
- Document changes

## Task Management

### Breaking Down Work

- **Estimate task size** - Aim for 1-4 hour tasks
- **Too large?** - Break into subtasks
- **Dependencies** - Identify what needs to happen first
- **Priorities** - Work on highest impact first
- **Track progress** - Use todo lists or project management tools

### Task States

- **Todo** - Not started
- **In Progress** - Currently working
- **Blocked** - Waiting on something
- **In Review** - Under review
- **Done** - Completed and deployed

## Code Review Best Practices

### For Authors

- **Self-review first** - Catch obvious issues
- **Keep changes focused** - One logical change per PR
- **Write clear descriptions** - Explain what and why
- **Add tests** - Demonstrate code works
- **Respond to feedback** - Engage constructively

### For Reviewers

- **Be constructive** - Suggest improvements, don't just criticize
- **Focus on substance** - Logic, security, maintainability
- **Ask questions** - Understand before judging
- **Praise good work** - Acknowledge quality
- **Be timely** - Don't block teammates

## Continuous Integration

### Pre-Commit

- Run tests locally
- Run linters/formatters
- Check for secrets
- Verify builds successfully

### CI Pipeline

- Automated tests run
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
- **README files** - Project overview and setup
- **Architecture docs** - High-level design
- **Runbooks** - Operational procedures

## Debugging Process

### When Something Breaks

1. **Reproduce** - Can you consistently trigger the bug?
2. **Isolate** - Narrow down where the problem is
3. **Understand** - Why is it happening?
4. **Fix** - Address root cause, not just symptoms
5. **Test** - Verify fix works and doesn't break other things
6. **Prevent** - Add test to catch regression

### Debugging Techniques

- **Read error messages** - They usually tell you what's wrong
- **Use debugger** - Step through code
- **Add logging** - Trace execution flow
- **Simplify** - Remove complexity to isolate issue
- **Ask for help** - Fresh eyes help

## Performance Optimization

### When to Optimize

- **Measure first** - Don't guess at bottlenecks
- **Focus on hot paths** - Optimize what matters
- **After correctness** - Make it work, then make it fast
- **When needed** - Premature optimization wastes time

### Optimization Process

1. **Measure** - Profile to find bottlenecks
2. **Optimize** - Improve the hot path
3. **Measure again** - Verify improvement
4. **Test** - Ensure still correct
5. **Document** - Explain optimizations

## Technical Debt

### Managing Debt

- **Acknowledge it** - Track known issues
- **Prioritize** - Not all debt is equal
- **Pay down regularly** - Don't let it accumulate
- **Prevent new debt** - Maintain quality standards
- **Refactor continuously** - Small improvements add up

### When to Take On Debt

- **Deliberate decision** - Understand trade-offs
- **Time-boxed** - Plan to address soon
- **Documented** - Record what and why
- **Rare** - Should be exception, not rule

## Collaboration

### Working with Team

- **Communicate clearly** - Share context and decisions
- **Ask questions** - Don't assume
- **Share knowledge** - Help others learn
- **Give feedback** - Constructive and timely
- **Be reliable** - Do what you commit to

### Pair Programming

- **Rotate driver** - Take turns typing
- **Think aloud** - Share your reasoning
- **Ask questions** - Understand decisions
- **Take breaks** - Maintain focus
- **Learn from each other** - Different perspectives valuable

## Continuous Learning

### Stay Current

- **Read code** - Learn from others
- **Try new things** - Experiment and explore
- **Follow best practices** - Learn patterns
- **Get feedback** - Ask for code reviews
- **Share knowledge** - Teaching reinforces learning

### Growth Mindset

- **Mistakes are learning** - Fail forward
- **Always improving** - Never stop learning
- **Seek feedback** - Embrace criticism
- **Challenge yourself** - Push boundaries
- **Help others** - Lift the team

## Common Pitfalls

### Avoid These

- ❌ Skipping tests to go faster
- ❌ Committing failing code
- ❌ Ignoring code review feedback
- ❌ Taking shortcuts on security
- ❌ Not documenting decisions
- ❌ Optimizing prematurely
- ❌ Building without understanding requirements
- ❌ Forgetting to commit/push work

### Do These Instead

- ✅ Write tests as you code
- ✅ Commit only passing code
- ✅ Engage with reviewers
- ✅ Security first mindset
- ✅ Document as you go
- ✅ Measure before optimizing
- ✅ Clarify requirements upfront
- ✅ Commit and push frequently

## Summary

### The Golden Rules

1. **Test everything** - All tests must pass
2. **Commit frequently** - Small, focused commits
3. **Refactor always** - Keep code clean
4. **Security first** - Never compromise on security
5. **Document well** - Code is read more than written
6. **Communicate clearly** - Share context and decisions
7. **Learn continuously** - Always improving

### Success Metrics

- **Velocity** - Delivering features consistently
- **Quality** - Low bug rate, high test coverage
- **Maintainability** - Easy to change code
- **Reliability** - Systems stay up
- **Team satisfaction** - Enjoyable work environment
