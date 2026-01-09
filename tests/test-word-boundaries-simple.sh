#!/usr/bin/env bash
#
# Simple test for add_word_boundaries function
#

set -euo pipefail

# Define the function inline for testing
add_word_boundaries() {
    local keyword="$1"

    # Count actual characters (excluding escape sequences)
    # Remove backslashes used for escaping to get true length
    local unescaped="${keyword//\\/}"
    local length=${#unescaped}

    # Add word boundaries for short keywords (4 chars or less)
    if [[ $length -le 4 ]]; then
        printf '\\b%s\\b' "$keyword"
    else
        printf '%s' "$keyword"
    fi
}

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
test_it() {
    local name="$1"
    local input="$2"
    local expected="$3"
    local result
    result=$(add_word_boundaries "$input")

    # Use printf to properly compare strings with backslashes
    if printf '%s' "$result" | grep -qFx "$expected"; then
        echo "✓ $name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ $name (expected: $expected, got: $result)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

echo "Testing add_word_boundaries function..."
echo

# Short keywords should get word boundaries
test_it "1-char" "a" "\\ba\\b"
test_it "2-char (go)" "go" "\\bgo\\b"
test_it "3-char (aws)" "aws" "\\baws\\b"
test_it "4-char (rust)" "rust" "\\brust\\b"
test_it "4-char (java)" "java" "\\bjava\\b"

# Longer keywords should NOT get word boundaries
test_it "5-char (react)" "react" "react"
test_it "6-char (python)" "python" "python"
test_it "Long (typescript)" "typescript" "typescript"

echo
echo "Pattern matching tests..."
echo

# Test actual grep matching
test_match() {
    local name="$1"
    local pattern="$2"
    local text="$3"
    local should_match="$4"

    if echo "$text" | grep -qE "$pattern"; then
        if [[ "$should_match" == "yes" ]]; then
            echo "✓ $name (matched as expected)"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo "✗ $name (matched but should not)"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    else
        if [[ "$should_match" == "no" ]]; then
            echo "✓ $name (no match as expected)"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo "✗ $name (no match but should)"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    fi
}

# Test rust vs trust
test_match "rust matches 'rust'" "\\brust\\b" "rust" "yes"
test_match "rust does NOT match 'trust'" "\\brust\\b" "trust" "no"
test_match "rust does NOT match 'trustworthy'" "\\brust\\b" "trustworthy" "no"
test_match "rust matches 'using rust'" "\\brust\\b" "using rust" "yes"

# Test go
test_match "go matches 'go'" "\\bgo\\b" "go" "yes"
test_match "go does NOT match 'golang'" "\\bgo\\b" "golang" "no"
test_match "go does NOT match 'cargo'" "\\bgo\\b" "cargo" "no"

# Test aws
test_match "aws matches 'aws'" "\\baws\\b" "aws" "yes"
test_match "aws does NOT match 'laws'" "\\baws\\b" "laws" "no"

echo
echo "========================================"
echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
echo "========================================"

if [[ $TESTS_FAILED -gt 0 ]]; then
    exit 1
else
    echo "All tests passed!"
    exit 0
fi
