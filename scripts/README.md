# Scripts Documentation

This directory contains utility scripts for centralized-rules testing and validation.

## test-keyword-validation.sh

Automated testing script that validates keywords in `skill-rules.json` correctly trigger their expected rule categories in the hook script.

### Purpose

Ensures that all keywords defined in `skill-rules.json` reliably activate the correct rules, preventing silent failures when keywords are added or changed.

### Usage

**Basic usage (test 10 random keywords):**
```bash
./scripts/test-keyword-validation.sh
```

**Test specific number of keywords:**
```bash
./scripts/test-keyword-validation.sh --num-tests 20
```

**Test all keywords:**
```bash
./scripts/test-keyword-validation.sh --all
```

**Verbose output (show details for each test):**
```bash
./scripts/test-keyword-validation.sh --verbose
```

**Test specific category:**
```bash
./scripts/test-keyword-validation.sh --category base
./scripts/test-keyword-validation.sh --category languages
./scripts/test-keyword-validation.sh --category cloud
```

**Combine options:**
```bash
./scripts/test-keyword-validation.sh --num-tests 5 --verbose --category base
```

### How It Works

1. **Parse skill-rules.json:** Extracts all keywords from:
   - `keywordMappings.base` (testing, security, git, refactoring, etc.)
   - `keywordMappings.languages` (python, typescript, javascript, go, rust, java + frameworks)
   - `keywordMappings.cloud` (aws, azure, gcp, vercel)

2. **Generate test prompts:** For each selected keyword, creates a test prompt containing that keyword

3. **Run hook script:** Executes the hook script with the test prompt and captures the output

4. **Validate results:** Checks that the expected rule categories were triggered

5. **Report results:** Shows pass/fail for each test with detailed failure information

### Test Scenarios Covered

- ✅ Single keywords trigger correct rules
- ✅ Language-specific keywords activate language rules
- ✅ Framework keywords activate framework rules
- ✅ Cloud provider keywords activate cloud rules
- ✅ JSON parsing and rule matching work correctly

### Example Output

```
═══════════════════════════════════════════════════════
  Centralized Rules - Keyword Validation Testing
═══════════════════════════════════════════════════════

ℹ Checking dependencies...
ℹ Checking required files...
✓ Environment checks passed

ℹ Testing categories: base languages cloud
ℹ Mode: Testing 10 random keywords per category

ℹ Testing category: base
✓ [base/testing] Keyword 'pytest' correctly triggered rules
✓ [base/security] Keyword 'jwt' correctly triggered rules
✓ [base/git] Keyword 'merge' correctly triggered rules
...

═══════════════════════════════════════════════════════
  Test Summary
═══════════════════════════════════════════════════════
Total Tests:  30
Passed:       28
Failed:       2

Failed Keywords:
  - api
  - edge

✗ Some tests failed
```

### CI Integration

This script runs automatically in GitHub Actions on every push and pull request:

```yaml
keyword-validation:
  name: Keyword Validation
  uses: ./.github/workflows/ci-keyword-validation.yml
```

The CI run tests 10 random keywords to ensure broad coverage over time while keeping build times reasonable.

### Interpreting Results

**All tests passed ✅**
- All tested keywords correctly trigger their expected rules
- Hook system is working as designed

**Some tests failed ✗**
- Indicates keywords that don't trigger expected rules
- May reveal:
  - Keywords that are too generic (e.g., "api", "function")
  - Missing keywords in hook script patterns
  - Incorrect rule mappings in skill-rules.json
  - Hook script bugs

### Troubleshooting

**Test fails with "jq not found":**
```bash
brew install jq  # macOS
sudo apt-get install jq  # Linux
```

**Test fails with "Hook script not executable":**
```bash
chmod +x .claude/hooks/activate-rules.sh
```

**Want to see what rules a keyword triggers:**
```bash
echo '{"prompt":"test keyword: YOUR_KEYWORD"}' | ./.claude/hooks/activate-rules.sh | jq -r '.systemMessage'
```

### Maintenance

When adding new keywords to `skill-rules.json`:

1. Run the test script locally:
   ```bash
   ./scripts/test-keyword-validation.sh --all
   ```

2. Fix any failures before committing

3. CI will automatically validate on PR

### Dependencies

- `bash` (4.0+)
- `jq` (JSON processor)
- `.claude/skills/skill-rules.json` (keyword definitions)
- `.claude/hooks/activate-rules.sh` (hook script to test)

### Exit Codes

- `0` - All tests passed
- `1` - Some tests failed or error occurred

### Performance

- Testing 10 keywords per category: ~5-10 seconds
- Testing all keywords (`--all`): ~30-60 seconds
- Depends on number of keywords in skill-rules.json

### Related Files

- `.claude/skills/skill-rules.json` - Keyword definitions and mappings
- `.claude/hooks/activate-rules.sh` - Hook script being tested
- `.github/workflows/ci-keyword-validation.yml` - CI workflow
