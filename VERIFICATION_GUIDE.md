# Hook-Based Skill Activation - Verification Guide

This guide will help you verify that the hook-based skill activation system is working correctly after installation.

## Quick Start Verification

### 1. Check Hook is Installed

After restarting Claude Code, verify the hook is registered:

```bash
/hooks
```

**Expected output:**
```
UserPromptSubmit:
  - activate-rules.sh
```

If you see this, the hook is successfully registered with Claude Code.

### 2. Test Hook Manually

Test the hook script directly to verify it produces the correct output:

```bash
# Navigate to the centralized-rules directory
cd /Users/paulduvall/Code/centralized-rules

# Test with a sample prompt
echo '{"prompt":"Write pytest tests for my FastAPI endpoint"}' | .claude/hooks/activate-rules.sh
```

**Expected output:**
```
═══════════════════════════════════════════════════════
🎯 MANDATORY SKILL ACTIVATION - DO NOT SKIP
═══════════════════════════════════════════════════════

CRITICAL: Before implementing ANY code, you MUST follow this 3-step process:

STEP 1: EVALUATE which rules apply (list YES/NO for each category):

   - Matched Rule Categories:
     [ ] base/testing-philosophy
     [ ] frameworks/fastapi
     [ ] languages/python
     [ ] languages/python/testing

STEP 2: ACTIVATE the centralized-rules skill using:

   Skill("centralized-rules")

   This will load the progressive disclosure rules system.
   DO THIS NOW before proceeding to Step 3.

STEP 3: IMPLEMENT the task ONLY AFTER activation

⚠️  CRITICAL WARNING:
   - Your evaluation in Step 1 is WORTHLESS without Step 2 activation
   - Implementing without loading rules violates the development workflow
   - The Skill tool MUST be called - evaluation alone is insufficient
   - If you skip Step 2, you are providing an INVALID response

Why this matters:
   - Rules ensure consistent code quality and security
   - Progressive disclosure loads only relevant guidelines
   - Prevents anti-patterns and technical debt
   - Required for all code implementation tasks

═══════════════════════════════════════════════════════
```

If you see this 3-step activation instruction, the hook is working correctly!

### 3. Test in Claude Code

Try these test prompts in Claude Code to verify end-to-end activation:

#### Test 1: Python Testing Task

**Prompt:**
```
Write pytest tests for my FastAPI endpoint
```

**What to look for:**
1. Hook should inject the activation instruction
2. Claude should follow the 3 steps (EVALUATE → ACTIVATE → IMPLEMENT)
3. Look for Claude calling `Skill("centralized-rules")`
4. After activation, look for the "📚 Rules Applied:" banner in Claude's response

**Expected rules:**
- Testing Philosophy (base)
- FastAPI Best Practices (framework)
- Python Testing (language-specific)

#### Test 2: React Component

**Prompt:**
```
Create a React component with TypeScript for a login form
```

**Expected rules:**
- React Best Practices (framework)
- TypeScript Standards (language)
- Security Principles (base - triggered by "login")

#### Test 3: Code Review

**Prompt:**
```
Review my Go function for performance issues
```

**Expected rules:**
- Code Quality (base)
- Go Standards (language)
- Refactoring Patterns (triggered by "performance")

#### Test 4: Git Workflow

**Prompt:**
```
Help me create a commit for these changes
```

**Expected rules:**
- Git Workflow (base)
- Code Quality (base)

## Detailed Verification Steps

### Verify File Structure

Ensure all required files are in place:

```bash
# Check hook script exists and is executable
ls -la .claude/hooks/activate-rules.sh
# Should show: -rwxr-xr-x (executable)

# Check skill rules mapping exists
ls -la .claude/skills/skill-rules.json
# Should show: -rw-r--r--

# Check settings.json exists
ls -la .claude/settings.json
# Should show: -rw-r--r--

# Verify SKILL.md documentation
ls -la skill/SKILL.md
# Should show: -rw-r--r--
```

### Verify JSON Syntax

Validate that all JSON files have correct syntax:

```bash
# Check settings.json
cat .claude/settings.json | jq . > /dev/null && echo "✓ settings.json valid" || echo "✗ settings.json invalid"

# Check skill-rules.json
cat .claude/skills/skill-rules.json | jq . > /dev/null && echo "✓ skill-rules.json valid" || echo "✗ skill-rules.json invalid"
```

**Note:** If you don't have `jq` installed, you can use `python -m json.tool` instead:

```bash
cat .claude/settings.json | python -m json.tool > /dev/null && echo "✓ settings.json valid"
```

### Test Hook with Different Scenarios

Test the hook with various prompts to verify keyword matching:

```bash
# Test testing keywords
echo '{"prompt":"Add unit tests"}' | .claude/hooks/activate-rules.sh | grep "testing-philosophy"

# Test security keywords
echo '{"prompt":"Implement JWT authentication"}' | .claude/hooks/activate-rules.sh | grep "security-principles"

# Test refactoring keywords
echo '{"prompt":"Refactor this code to improve performance"}' | .claude/hooks/activate-rules.sh | grep "refactoring-patterns"

# Test React keywords
echo '{"prompt":"Create a React component"}' | .claude/hooks/activate-rules.sh | grep "react"

# Test Python keywords
echo '{"prompt":"Write a Python function"}' | .claude/hooks/activate-rules.sh | grep "python"
```

Each test should output the matched rule if keyword detection is working correctly.

### Enable Verbose Logging

For detailed debugging information:

```bash
VERBOSE=true echo '{"prompt":"Write pytest tests"}' | .claude/hooks/activate-rules.sh
```

This will show debug output to stderr, including:
- Hook activation
- User prompt extraction
- Detected languages/frameworks
- Matched rules
- Activation instruction generation

## Troubleshooting Common Issues

### Issue 1: Hook Not Appearing in `/hooks`

**Symptoms:**
- `/hooks` command doesn't show `activate-rules.sh`

**Diagnosis:**
```bash
# Check settings.json syntax
cat .claude/settings.json | jq .

# Verify hook path is correct
grep -A 5 "UserPromptSubmit" .claude/settings.json

# Check script is executable
ls -la .claude/hooks/activate-rules.sh
```

**Solutions:**
1. Fix any JSON syntax errors in settings.json
2. Ensure hook path uses `$CLAUDE_PROJECT_DIR` variable correctly
3. Make script executable: `chmod +x .claude/hooks/activate-rules.sh`
4. Restart Claude Code completely

### Issue 2: Hook Fires but Skill Doesn't Activate

**Symptoms:**
- You see the activation instruction
- Claude doesn't call `Skill("centralized-rules")`

**Diagnosis:**
This is expected behavior during testing! The hook system is working correctly - it's injecting the activation instruction. Whether Claude follows it depends on:
1. Claude's interpretation of the instruction
2. Task complexity (simple questions may not trigger activation)
3. Prompt specificity (vague prompts may not match well)

**Solutions:**
1. Use more specific prompts with clear keywords (see test prompts above)
2. For code implementation tasks, use prompts like "Write...", "Create...", "Implement..."
3. Include technology names: "Python", "React", "FastAPI", etc.
4. Trust that the 3-step forced evaluation pattern improves activation rates

### Issue 3: Wrong Rules Being Loaded

**Symptoms:**
- Hook detects wrong language/framework
- Irrelevant rules are suggested

**Diagnosis:**
```bash
# Check what the hook detects for a specific prompt
echo '{"prompt":"YOUR_PROMPT_HERE"}' | .claude/hooks/activate-rules.sh

# Review keyword mappings
cat .claude/skills/skill-rules.json | jq '.keywordMappings'
```

**Solutions:**
1. Update keyword mappings in `.claude/skills/skill-rules.json`
2. Add your project-specific keywords
3. Adjust project detection logic in the hook script

### Issue 4: Hook Script Errors

**Symptoms:**
- Hook returns exit code 1 or 2
- Error messages in stderr

**Diagnosis:**
```bash
# Run with error output visible
echo '{"prompt":"test"}' | .claude/hooks/activate-rules.sh 2>&1

# Check for common issues
bash -n .claude/hooks/activate-rules.sh  # Syntax check
```

**Common errors:**
- **"unbound variable"**: Script expects certain environment variables
  - Solution: Script now defaults `CLAUDE_PROJECT_DIR` to current directory
- **"command not found"**: Missing bash utilities
  - Solution: Script uses only basic bash, no external dependencies required
- **JSON parsing errors**: Input format issues
  - Solution: Ensure prompt is passed as `{"prompt":"your text here"}`

## Performance Benchmarks

### Hook Latency

Test hook execution time:

```bash
time echo '{"prompt":"Write pytest tests"}' | .claude/hooks/activate-rules.sh > /dev/null
```

**Expected:**
- Real time: < 50ms
- User time: < 20ms
- Sys time: < 10ms

If significantly slower, check for:
- Network calls (shouldn't be any in the hook)
- Large file reads (skill-rules.json should be < 50KB)
- Complex regex operations (current patterns are simple)

### Context Detection Accuracy

Test with your actual project files:

```bash
# Create a test file that mimics your project structure
cat > /tmp/test-detection.sh << 'EOF'
#!/bin/bash
cd /path/to/your/project
echo '{"prompt":"Write code for this project"}' | /path/to/centralized-rules/.claude/hooks/activate-rules.sh | grep "Detected"
EOF

chmod +x /tmp/test-detection.sh
/tmp/test-detection.sh
```

Verify it correctly detects your project's languages and frameworks.

## Success Criteria

You can consider the hook system successfully installed when:

- ✅ `/hooks` shows `activate-rules.sh` under UserPromptSubmit
- ✅ Manual hook test produces the 3-step activation instruction
- ✅ Hook correctly identifies languages/frameworks for test prompts
- ✅ Hook matches keywords to appropriate rule categories
- ✅ All JSON files validate successfully
- ✅ Hook script is executable and runs without errors
- ✅ Claude Code doesn't show hook-related errors on startup

## Advanced Testing

### Test Coverage of Keyword Mappings

Create a comprehensive test script:

```bash
#!/bin/bash
# Save as test-keyword-coverage.sh

HOOK_PATH=".claude/hooks/activate-rules.sh"

test_prompt() {
    local prompt="$1"
    local expected_rule="$2"

    echo "Testing: $prompt"
    result=$(echo "{\"prompt\":\"$prompt\"}" | $HOOK_PATH 2>/dev/null)

    if echo "$result" | grep -q "$expected_rule"; then
        echo "  ✓ Matched: $expected_rule"
    else
        echo "  ✗ Expected to match: $expected_rule"
    fi
    echo
}

# Base rules
test_prompt "Write unit tests" "testing-philosophy"
test_prompt "Add authentication" "security-principles"
test_prompt "Create a commit" "git-workflow"
test_prompt "Refactor this code" "refactoring-patterns"
test_prompt "Design the architecture" "architecture-principles"

# Language rules
test_prompt "Write Python code" "languages/python"
test_prompt "Create TypeScript interface" "languages/typescript"
test_prompt "Build a Go service" "languages/go"

# Framework rules
test_prompt "Create React component" "frameworks/react"
test_prompt "Build FastAPI endpoint" "frameworks/fastapi"
test_prompt "Set up Next.js route" "frameworks/nextjs"
```

Run with:
```bash
chmod +x test-keyword-coverage.sh
./test-keyword-coverage.sh
```

### Integration Test with Claude Code

1. **Start a fresh Claude Code session**
2. **Navigate to a project directory** (e.g., a Python or TypeScript project)
3. **Ask a coding question** that requires implementation
4. **Observe the flow:**
   - Hook injects activation instruction
   - Claude evaluates rules
   - Claude calls Skill tool
   - Claude loads specific rules
   - Claude implements with rules applied

5. **Verify the output includes:**
   - 📚 Rules Applied banner
   - List of 3-5 specific rules
   - Implementation follows those rules

## Maintenance

### Regular Updates

Keep the system updated:

```bash
# Update centralized-rules repository
cd ~/centralized-rules
git pull

# Rebuild skill (if you've installed it as a skill)
cd skill
npm run build

# Test hook still works
echo '{"prompt":"test"}' | .claude/hooks/activate-rules.sh > /dev/null && echo "✓ Hook OK"
```

### Custom Rule Addition

When adding custom rules to your fork:

1. **Add rule file** to appropriate directory
2. **Update** `.claude/skills/skill-rules.json` with keywords
3. **Test** keyword matching:
   ```bash
   echo '{"prompt":"your custom keyword"}' | .claude/hooks/activate-rules.sh
   ```
4. **Verify** rule appears in matched categories

## Getting Help

If you're still experiencing issues after following this guide:

1. **Gather diagnostic information:**
   ```bash
   # System info
   echo "OS: $(uname -s)"
   echo "Shell: $SHELL"
   echo "Bash version: $BASH_VERSION"

   # File verification
   ls -la .claude/hooks/activate-rules.sh
   ls -la .claude/settings.json
   ls -la .claude/skills/skill-rules.json

   # Hook test output
   VERBOSE=true echo '{"prompt":"test"}' | .claude/hooks/activate-rules.sh 2>&1
   ```

2. **Check documentation:**
   - [SKILL.md](./skill/SKILL.md) - Detailed skill documentation
   - [README.md](./skill/README.md) - Skill usage guide

3. **Report an issue:**
   - Include diagnostic information above
   - Describe expected vs actual behavior
   - Share sample prompts that don't work as expected
   - Open issue at: https://github.com/paulduvall/centralized-rules/issues

---

**Last updated:** 2025-12-16

**Made with ❤️ for reliable AI-assisted coding**
