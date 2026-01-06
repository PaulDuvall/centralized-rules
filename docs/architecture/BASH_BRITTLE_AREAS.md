# Brittle Bash Patterns - Analysis and Refactoring Plan

**Status:** Analysis complete - Refactoring tasks created
**Date:** 2025-12-28
**Related Issues:** centralized-rules-k8v8 (parent), centralized-rules-d0xm, centralized-rules-pnby

## Executive Summary

The centralized-rules Bash implementation has reached ~6,500 lines with increasing complexity in keyword matching and JSON processing. Seven specific brittle areas have been identified that impact maintainability, testability, and reliability.

**Recommendation:** Incremental refactoring to extract complex logic into testable library functions. This preserves the successful `curl | bash` installation while improving code quality.

---

## Brittle Area #1: Repeated jq Calls in Keyword Matching

**Location:** `.claude/hooks/activate-rules.sh:115-219`
**Severity:** High
**Impact:** Performance (O(n*m) complexity), maintainability

### Current Code Pattern

```bash
# Extract all base category keywords and rules
local base_categories
base_categories=$(echo "$SKILL_RULES_JSON" | jq -r '.keywordMappings.base | keys[]' 2>/dev/null)

while IFS= read -r category; do
    [[ -z "$category" ]] && continue

    # Get keywords for this category and escape special characters
    local keywords
    keywords=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.base.${category}.keywords[]?" 2>/dev/null | sed 's/\./\\./g' | tr '\n' '|' | sed 's/|$//')

    # Get slash commands for this category
    local slash_cmds
    slash_cmds=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.base.${category}.slashCommands[]?" 2>/dev/null | tr '\n' '|' | sed 's/|$//' | sed 's|/||g')

    # Get rules for this category
    local category_rules
    category_rules=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.base.${category}.rules[]?" 2>/dev/null)
done <<< "$base_categories"
```

### Problems

1. **Performance:** Each iteration spawns 3+ `jq` processes
2. **Fragile piping:** `jq | sed | tr | sed` chains break on edge cases
3. **No error handling:** Silent failures when jq output is malformed
4. **Repeated pattern:** Same logic duplicated for languages, frameworks, cloud providers

### Proposed Solution

**Task:** centralized-rules-73qt - Extract JSON keyword extraction into `lib/json-utils.sh`

```bash
# lib/json-utils.sh
jq_get_keywords() {
    local json="$1"
    local path="$2"
    echo "$json" | jq -r "${path}.keywords[]?" 2>/dev/null | escape_regex_chars | join_with_pipe
}

jq_get_rules() {
    local json="$1"
    local path="$2"
    echo "$json" | jq -r "${path}.rules[]?" 2>/dev/null
}

escape_regex_chars() {
    sed 's/[.^$*+?[{()|\\]/\\&/g'  # Handles ALL regex special chars
}

join_with_pipe() {
    tr '\n' '|' | sed 's/|$//'
}
```

**Usage:**
```bash
keywords=$(jq_get_keywords "$SKILL_RULES_JSON" ".keywordMappings.base.${category}")
rules=$(jq_get_rules "$SKILL_RULES_JSON" ".keywordMappings.base.${category}")
```

**Benefits:**
- Single `jq` call per category
- Centralized error handling
- Testable functions
- DRY principle

---

## Brittle Area #2: Incomplete Regex Escaping ✓ RESOLVED

**Location:** `.claude/hooks/activate-rules.sh:72-76, 129, 163, 195, 216`
**Severity:** Critical
**Impact:** Security (injection risk), correctness
**Status:** Fixed in commit fa4cd28

### Current Code Pattern

```bash
keywords=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.base.${category}.keywords[]?" 2>/dev/null | sed 's/\./\\./g' | tr '\n' '|' | sed 's/|$//')
```

### Problem

**Only escapes dots (`.`)**, but keywords could contain any regex metacharacter:

```
. * + ? [ ] ( ) { } ^ $ | \
```

**Example failure case:**
```json
{
  "keywords": ["test+coverage", "mock()", "spec[unit]"]
}
```

Current escaping produces:
```
test+coverage|mock()|spec[unit]
```

This is invalid regex! Should be:
```
test\+coverage|mock\(\)|spec\[unit\]
```

### Implemented Solution ✓

**Task:** centralized-rules-d0xm - Fix brittle regex escaping in keyword processing

```bash
# .claude/hooks/activate-rules.sh:72-76
escape_regex() {
    local input="$1"
    # Escape all special regex characters: . * + ? [ ] ( ) { } ^ $ | \
    printf '%s' "$input" | sed 's/[.*+?\[\](){}^$|\\]/\\&/g'
}

# Applied to keyword processing (lines 129, 163, 195, 216)
keywords=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.base.${category}.keywords[]?" 2>/dev/null | while IFS= read -r kw; do escape_regex "$kw"; echo "|"; done | tr -d '\n' | sed 's/|$//')
```

**Benefits:**
- Handles all regex metacharacters
- Prevents injection attacks via malicious keywords
- More predictable behavior
- Applied consistently across all keyword types (base, language, framework, cloud)

---

## Brittle Area #3: Duplicate Logic (JSON vs Fallback)

**Location:** `.claude/hooks/activate-rules.sh:110-289`
**Severity:** High
**Impact:** Maintainability, consistency

### Current Structure

```bash
if load_keyword_mappings "$json_file"; then
    # JSON-driven matching: 110 lines
    # Base categories
    base_categories=$(echo "$SKILL_RULES_JSON" | jq ...)
    while IFS= read -r category; do
        # ... keyword matching logic ...
    done

    # Languages
    languages=$(echo "$SKILL_RULES_JSON" | jq ...)
    while IFS= read -r lang; do
        # ... keyword matching logic ...
    done

    # Frameworks, cloud providers...
else
    # Hardcoded fallback: 67 lines
    if echo "${prompt_lower}" | grep -qE '(test|pytest|...)'; then
        matched_rules+=("base/testing-philosophy")
    fi
    # ... 60 more lines of hardcoded patterns ...
fi
```

### Problems

1. **Duplication:** Logic must be maintained in two places
2. **Drift:** Fallback patterns can become outdated
3. **Testing:** Must test both code paths
4. **Size:** 177 lines for keyword matching

### Proposed Solution

**Task:** centralized-rules-wpj4 - Eliminate duplicate JSON vs fallback logic

```bash
# Strategy: Always use JSON, embed fallback data
ensure_keyword_data() {
    local json_file="$1"

    if [[ -f "$json_file" ]] && command -v jq &>/dev/null; then
        SKILL_RULES_JSON=$(cat "$json_file")
    else
        # Generate minimal JSON from embedded data
        SKILL_RULES_JSON=$(generate_fallback_json)
    fi
}

generate_fallback_json() {
    cat <<'EOF'
{
  "keywordMappings": {
    "base": {
      "testing": {
        "keywords": ["test", "pytest", "jest", "spec", "tdd"],
        "rules": ["base/testing-philosophy"]
      }
    }
  }
}
EOF
}
```

**Benefits:**
- Single code path for matching
- Fallback becomes just a data source
- Easier to maintain
- Reduces code size by ~40%

---

## Brittle Area #4: Nested While Loops

**Location:** `.claude/hooks/activate-rules.sh:117-145, 151-199, 205-219`
**Severity:** Medium
**Impact:** Readability, debuggability

### Current Pattern

```bash
while IFS= read -r category; do
    keywords=$(echo "$SKILL_RULES_JSON" | jq ...)
    if [[ -n "$keywords" ]] && echo "${prompt_lower}" | grep -qE "(${keywords})"; then
        while IFS= read -r rule; do
            [[ -n "$rule" ]] && matched_rules+=("$rule")
        done <<< "$category_rules"
    fi
done <<< "$base_categories"
```

### Problems

1. **Complex control flow:** Hard to follow
2. **Variable scoping:** Easy to accidentally overwrite outer vars
3. **Process substitution:** `<<< "$var"` creates subshells
4. **Debugging:** Setting breakpoints is difficult

### Proposed Solution

**Task:** centralized-rules-0g0r - Create `lib/keyword-matcher.sh` for pattern matching logic

```bash
# lib/keyword-matcher.sh
match_category() {
    local prompt="$1"
    local category="$2"
    local json="$3"

    local keywords rules
    keywords=$(jq_get_keywords "$json" ".keywordMappings.base.${category}")
    rules=$(jq_get_rules "$json" ".keywordMappings.base.${category}")

    if match_any_keyword "$prompt" "$keywords"; then
        echo "$rules"
    fi
}

match_any_keyword() {
    local prompt="$1"
    local keywords="$2"
    echo "$prompt" | grep -qE "(${keywords})"
}
```

**Usage:**
```bash
for category in $(get_categories "$SKILL_RULES_JSON" "base"); do
    matched_rules+=($(match_category "$prompt_lower" "$category" "$SKILL_RULES_JSON"))
done
```

**Benefits:**
- Flat control flow
- Testable functions
- Clear separation of concerns
- Easier to debug

---

## Brittle Area #5: Manual JSON Output Escaping ✓ RESOLVED

**Location:** `.claude/hooks/activate-rules.sh:485-512`
**Severity:** Critical
**Impact:** Correctness, security
**Status:** Fixed in commit fa4cd28

### Current Code (Fallback Path)

```bash
# Fallback: Manual JSON escaping (basic but functional)
local escaped_output
escaped_output=$(printf '%s' "${output}" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed '$ s/\\n$//')

cat <<EOF
{
    "systemMessage": "${escaped_output}",
    "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "${escaped_output}"
    }
}
EOF
```

### Problems

1. **Incomplete escaping:** Only handles `\` and `"`
2. **Missing cases:** Doesn't escape:
   - Control characters (`\t`, `\r`, `\f`, `\b`)
   - Unicode characters
   - Newlines within strings (creates invalid JSON)
3. **Order dependency:** Must escape `\` before `"`
4. **Fragile:** Easy to break with edge cases

**Example failure:**
```bash
output="Line 1\nLine 2\tTabbed"
# Current escaping produces invalid JSON with literal \n and \t
```

### Implemented Solution ✓

**Task:** centralized-rules-pnby - Improve JSON output escaping fallback

```bash
# .claude/hooks/activate-rules.sh:475-512
if command -v jq &> /dev/null; then
    # Use jq for proper JSON escaping
    echo "${output}" | jq -Rs . | jq -s -c "{...}"
elif command -v python3 &> /dev/null; then
    # Fallback: Use Python for proper JSON escaping
    python3 -c "import json, sys; output = sys.stdin.read(); print(json.dumps({...}))" <<< "${output}"
elif command -v python &> /dev/null; then
    # Fallback: Use Python 2 for proper JSON escaping
    python -c "import json, sys; output = sys.stdin.read(); print json.dumps({...})" <<< "${output}"
else
    # Last resort: Manual JSON escaping with improved edge case handling
    escaped_output=$(printf '%s' "${output}" | \
        sed 's/\\/\\\\/g' | \
        sed 's/"/\\"/g' | \
        sed 's/\t/\\t/g' | \
        sed 's/\r/\\r/g' | \
        awk '{printf "%s\\n", $0}' | \
        sed '$ s/\\n$//')
fi
```

**Benefits:**
- Robust fallback chain (jq → python3 → python → sed)
- Handles control characters (\t, \r)
- Prevents JSON parsing errors
- More reliable output across different environments

---

## Brittle Area #6: File Read Caching

**Location:** `lib/detection.sh:28-92`
**Severity:** Low
**Impact:** Performance (minor)

### Current Pattern

```bash
detect_frameworks() {
    local frameworks=()

    # JavaScript/TypeScript frameworks
    if [[ -f "package.json" ]]; then
        grep -q '"react"' package.json 2>/dev/null && frameworks+=("react")
        grep -q '"next"' package.json 2>/dev/null && frameworks+=("nextjs")
        grep -q '"vue"' package.json 2>/dev/null && frameworks+=("vue")
        grep -q '"express"' package.json 2>/dev/null && frameworks+=("express")
        grep -q '"nestjs"' package.json 2>/dev/null && frameworks+=("nestjs")
    fi
}
```

### Problem

**`package.json` is read 5 times** with separate `grep` calls. For large files, this is inefficient.

### Proposed Solution

**Task:** centralized-rules-lm9q - Cache file reads in detection.sh

```bash
# lib/detection.sh
_FILE_CACHE=()

read_file_cached() {
    local file="$1"
    local cache_key="CACHE_${file//\//_}"

    if [[ -z "${!cache_key}" ]]; then
        declare -g "$cache_key"="$(cat "$file" 2>/dev/null)"
    fi

    echo "${!cache_key}"
}

detect_frameworks() {
    local frameworks=()

    if [[ -f "package.json" ]]; then
        local pkg_json
        pkg_json=$(read_file_cached "package.json")

        echo "$pkg_json" | grep -q '"react"' && frameworks+=("react")
        echo "$pkg_json" | grep -q '"next"' && frameworks+=("nextjs")
        # ... rest of checks use cached content
    fi
}
```

**Benefits:**
- 1 file read instead of 5
- Faster execution on large package.json files
- Pattern reusable for other files

---

## Brittle Area #7: Lack of Unit Tests

**Location:** All keyword matching and detection logic
**Severity:** High
**Impact:** Reliability, confidence in refactoring

### Current State

- Integration tests exist (`tests/test-precommit-gates.sh`, `tests/test-slash-command-detection.sh`)
- No unit tests for individual functions
- Manual testing required for changes
- Refactoring is risky

### Proposed Solution

**Task:** centralized-rules-g6v8 - Add unit tests for keyword matching functions

```bash
#!/usr/bin/env bash
# tests/unit/test-keyword-matching.sh

source "$(dirname "$0")/../../lib/json-utils.sh"
source "$(dirname "$0")/../../lib/keyword-matcher.sh"

# Test framework (simple but effective)
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    if [[ "$expected" == "$actual" ]]; then
        echo "✓ $test_name"
    else
        echo "✗ $test_name"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        return 1
    fi
}

# Test cases
test_escape_regex_special_chars() {
    local input="test+coverage"
    local expected="test\\+coverage"
    local actual
    actual=$(echo "$input" | escape_regex_chars)

    assert_equals "$expected" "$actual" "escape_regex_chars handles +"
}

test_match_category_with_matching_keyword() {
    local json='{"keywordMappings":{"base":{"testing":{"keywords":["test","tdd"],"rules":["base/testing"]}}}}'
    local prompt="write a test function"
    local result

    result=$(match_category "$prompt" "testing" "$json")
    assert_equals "base/testing" "$result" "match_category finds matching keyword"
}

test_json_escape_handles_newlines() {
    local input=$'Line 1\nLine 2'
    local result
    result=$(json_escape "$input")

    # Result should be valid JSON
    echo "$result" | jq . >/dev/null 2>&1
    assert_equals "0" "$?" "json_escape produces valid JSON with newlines"
}

# Run all tests
test_escape_regex_special_chars
test_match_category_with_matching_keyword
test_json_escape_handles_newlines
```

**Benefits:**
- Fast feedback on changes
- Documents expected behavior
- Enables safe refactoring
- Catches regressions early

---

## Refactoring Strategy

### Phase 1: Foundation (Week 1)

1. **centralized-rules-ptqx** - Document brittle patterns ✓ (this doc)
2. **centralized-rules-d0xm** - Fix regex escaping (critical bug) ✓ COMPLETED
3. **centralized-rules-pnby** - Fix JSON escaping (critical bug) ✓ COMPLETED

### Phase 2: Library Extraction (Week 2)

4. **centralized-rules-k8v8** - Create refactoring plan
5. **centralized-rules-73qt** - Create `lib/json-utils.sh`
6. **centralized-rules-0g0r** - Create `lib/keyword-matcher.sh`

### Phase 3: Consolidation (Week 3)

7. **centralized-rules-wpj4** - Eliminate JSON vs fallback duplication
8. **centralized-rules-lm9q** - Add file read caching
9. **centralized-rules-g6v8** - Create unit test suite

### Success Criteria

- [x] Brittle Area #2: Regex escaping (COMPLETED)
- [x] Brittle Area #5: JSON output escaping (COMPLETED)
- [ ] Brittle Area #1: Repeated jq calls
- [ ] Brittle Area #3: Duplicate JSON vs fallback logic
- [ ] Brittle Area #4: Nested while loops
- [ ] Brittle Area #6: File read caching
- [ ] Brittle Area #7: Unit tests
- [ ] Code size reduced by 30%+
- [ ] Test coverage > 80% for new libraries
- [ ] Zero regressions in existing behavior
- [x] Installation remains simple (`curl | bash`)

---

## Expected Improvements

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Lines in `match_keywords()` | 203 | ~60 | 70% reduction |
| jq calls per prompt | 15-30 | 3-5 | 80% reduction |
| Test coverage | 0% | 80%+ | New capability |
| Regex edge cases handled | 10% | 100% | 10x improvement |
| Maintainability (subjective) | 5/10 | 8/10 | 60% improvement |

---

## Related Tasks

- **Parent:** centralized-rules-k8v8 - Refactor keyword matching into modular functions
- **Critical bugs:** centralized-rules-d0xm, centralized-rules-pnby
- **Libraries:** centralized-rules-73qt, centralized-rules-0g0r
- **Optimization:** centralized-rules-lm9q
- **Testing:** centralized-rules-g6v8
- **Documentation:** centralized-rules-ptqx (this document)

---

## Conclusion

The current Bash implementation is **functional but reaching complexity limits**. The proposed refactoring:

✅ Keeps the successful `curl | bash` installation
✅ Improves code quality and testability
✅ Fixes critical security/correctness bugs
✅ Makes future enhancements easier
❌ Does NOT require rewriting in Go (yet)

**Next step:** Start with Phase 1 critical bugs (centralized-rules-d0xm, centralized-rules-pnby) to build momentum and demonstrate value.
