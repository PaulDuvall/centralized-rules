#!/usr/bin/env bash
#
# Unit tests for lib/override.sh
# Tests: merge strategies, pattern matching, exclusions, config validation
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source the library under test
source "$PROJECT_ROOT/lib/override.sh"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Test helpers
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"

    if [[ "$expected" == "$actual" ]]; then
        echo "✓ $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ $message"
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-}"

    if [[ "$haystack" == *"$needle"* ]]; then
        echo "✓ $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ $message"
        echo "  Expected to contain: '$needle'"
        echo "  Actual: '$haystack'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_exit_code() {
    local expected="$1"
    shift
    local message="${*: -1}"
    set -- "${@:1:$(($#-1))}"

    set +e
    "$@" >/dev/null 2>&1
    local actual=$?
    set -e

    if [[ "$expected" == "$actual" ]]; then
        echo "✓ $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ $message"
        echo "  Expected exit code: $expected"
        echo "  Actual exit code:   $actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Setup/teardown
setup_test_env() {
    TEST_DIR=$(mktemp -d)
    mkdir -p "$TEST_DIR/.claude/rules-local/base"
    mkdir -p "$TEST_DIR/.claude/rules/base"
    cd "$TEST_DIR"
}

teardown_test_env() {
    cd "$PROJECT_ROOT"
    rm -rf "$TEST_DIR"
}

# ============================================
# TEST: detect_local_overrides
# ============================================
echo ""
echo "=== Testing detect_local_overrides ==="
echo ""

test_detect_local_overrides_exists() {
    setup_test_env
    local result
    result=$(detect_local_overrides "$TEST_DIR/.claude")
    assert_equals "true" "$result" "Detects existing rules-local directory"
    teardown_test_env
}
test_detect_local_overrides_exists

test_detect_local_overrides_missing() {
    setup_test_env
    rm -rf "$TEST_DIR/.claude/rules-local"
    local result
    result=$(detect_local_overrides "$TEST_DIR/.claude")
    assert_equals "false" "$result" "Returns false for missing rules-local"
    teardown_test_env
}
test_detect_local_overrides_missing

# ============================================
# TEST: load_override_config
# ============================================
echo ""
echo "=== Testing load_override_config ==="
echo ""

test_load_config_valid() {
    setup_test_env
    cat > "$TEST_DIR/.claude/rules-config.local.json" <<'EOF'
{
    "merge_strategy": "extend",
    "overrides": {
        "base/*": "replace"
    },
    "exclude": ["base/chaos-engineering.md"]
}
EOF
    local result
    result=$(load_override_config "$TEST_DIR/.claude")
    assert_contains "$result" '"merge_strategy": "extend"' "Loads valid config"
    teardown_test_env
}
test_load_config_valid

test_load_config_missing() {
    setup_test_env
    local result
    result=$(load_override_config "$TEST_DIR/.claude")
    assert_equals "" "$result" "Returns empty for missing config"
    teardown_test_env
}
test_load_config_missing

# ============================================
# TEST: validate_override_config
# ============================================
echo ""
echo "=== Testing validate_override_config ==="
echo ""

test_validate_config_valid() {
    local config='{"merge_strategy": "extend"}'
    assert_exit_code 0 validate_override_config "$config" "Valid config passes"
}
test_validate_config_valid

test_validate_config_invalid_strategy() {
    local config='{"merge_strategy": "invalid"}'
    assert_exit_code 1 validate_override_config "$config" "Invalid strategy fails"
}
test_validate_config_invalid_strategy

test_validate_config_empty() {
    local config='{}'
    assert_exit_code 0 validate_override_config "$config" "Empty config is valid (uses defaults)"
}
test_validate_config_empty

test_validate_config_malformed_json() {
    local config='not valid json'
    assert_exit_code 1 validate_override_config "$config" "Malformed JSON fails"
}
test_validate_config_malformed_json

# ============================================
# TEST: get_merge_strategy
# ============================================
echo ""
echo "=== Testing get_merge_strategy ==="
echo ""

test_get_strategy_default() {
    local config='{"merge_strategy": "extend"}'
    local result
    result=$(get_merge_strategy "base/testing.md" "$config")
    assert_equals "extend" "$result" "Returns default strategy"
}
test_get_strategy_default

test_get_strategy_exact_match() {
    local config='{"merge_strategy": "extend", "overrides": {"base/testing.md": "replace"}}'
    local result
    result=$(get_merge_strategy "base/testing.md" "$config")
    assert_equals "replace" "$result" "Exact match override"
}
test_get_strategy_exact_match

test_get_strategy_glob_match() {
    local config='{"merge_strategy": "extend", "overrides": {"base/*": "prepend"}}'
    local result
    result=$(get_merge_strategy "base/testing.md" "$config")
    assert_equals "prepend" "$result" "Glob pattern match"
}
test_get_strategy_glob_match

test_get_strategy_no_config() {
    local result
    result=$(get_merge_strategy "base/testing.md" "")
    assert_equals "extend" "$result" "Defaults to extend without config"
}
test_get_strategy_no_config

# ============================================
# TEST: should_exclude_rule
# ============================================
echo ""
echo "=== Testing should_exclude_rule ==="
echo ""

test_exclude_exact_match() {
    local config='{"exclude": ["base/chaos-engineering.md"]}'
    local result
    result=$(should_exclude_rule "base/chaos-engineering.md" "$config")
    assert_equals "true" "$result" "Exact exclusion match"
}
test_exclude_exact_match

test_exclude_glob_match() {
    local config='{"exclude": ["base/ai-*"]}'
    local result
    result=$(should_exclude_rule "base/ai-ethics.md" "$config")
    assert_equals "true" "$result" "Glob exclusion match"
}
test_exclude_glob_match

test_exclude_no_match() {
    local config='{"exclude": ["base/chaos-engineering.md"]}'
    local result
    result=$(should_exclude_rule "base/testing.md" "$config")
    assert_equals "false" "$result" "No exclusion match"
}
test_exclude_no_match

test_exclude_empty_list() {
    local config='{"exclude": []}'
    local result
    result=$(should_exclude_rule "base/testing.md" "$config")
    assert_equals "false" "$result" "Empty exclusion list"
}
test_exclude_empty_list

test_exclude_no_config() {
    local result
    result=$(should_exclude_rule "base/testing.md" "")
    assert_equals "false" "$result" "No config means no exclusions"
}
test_exclude_no_config

# ============================================
# TEST: merge_rule_content
# ============================================
echo ""
echo "=== Testing merge_rule_content ==="
echo ""

test_merge_extend() {
    local central="# Central Rule"
    local local_content="# Local Addition"
    local result
    result=$(merge_rule_content "$central" "$local_content" "extend")
    assert_contains "$result" "# Central Rule" "Extend: contains central"
    result=$(merge_rule_content "$central" "$local_content" "extend")
    assert_contains "$result" "# Local Addition" "Extend: contains local"
}
test_merge_extend

test_merge_replace() {
    local central="# Central Rule"
    local local_content="# Local Replacement"
    local result
    result=$(merge_rule_content "$central" "$local_content" "replace")
    assert_equals "# Local Replacement" "$result" "Replace: only local content"
}
test_merge_replace

test_merge_prepend() {
    local central="# Central Rule"
    local local_content="# Local Prefix"
    local result
    result=$(merge_rule_content "$central" "$local_content" "prepend")
    # First line should be local
    local first_line
    first_line=$(echo "$result" | head -1)
    assert_equals "# Local Prefix" "$first_line" "Prepend: local content first"
}
test_merge_prepend

# ============================================
# TEST: process_overrides (integration)
# ============================================
echo ""
echo "=== Testing process_overrides ==="
echo ""

test_process_no_overrides() {
    setup_test_env
    rm -rf "$TEST_DIR/.claude/rules-local"
    echo "# Central content" > "$TEST_DIR/.claude/rules/base/test.md"

    process_overrides "$TEST_DIR/.claude"

    local result
    result=$(cat "$TEST_DIR/.claude/rules/base/test.md")
    assert_equals "# Central content" "$result" "No overrides: content unchanged"
    teardown_test_env
}
test_process_no_overrides

test_process_with_extend() {
    setup_test_env
    mkdir -p "$TEST_DIR/.claude/rules/base"
    echo "# Central content" > "$TEST_DIR/.claude/rules/base/test.md"
    echo "# Local addition" > "$TEST_DIR/.claude/rules-local/base/test.md"

    process_overrides "$TEST_DIR/.claude"

    local result
    result=$(cat "$TEST_DIR/.claude/rules/base/test.md")
    assert_contains "$result" "# Central content" "Extend: has central"
    result=$(cat "$TEST_DIR/.claude/rules/base/test.md")
    assert_contains "$result" "# Local addition" "Extend: has local"
    teardown_test_env
}
test_process_with_extend

test_process_with_replace_config() {
    setup_test_env
    mkdir -p "$TEST_DIR/.claude/rules/base"
    echo "# Central content" > "$TEST_DIR/.claude/rules/base/test.md"
    echo "# Replacement content" > "$TEST_DIR/.claude/rules-local/base/test.md"
    cat > "$TEST_DIR/.claude/rules-config.local.json" <<'EOF'
{"merge_strategy": "replace"}
EOF

    process_overrides "$TEST_DIR/.claude"

    local result
    result=$(cat "$TEST_DIR/.claude/rules/base/test.md")
    assert_equals "# Replacement content" "$result" "Replace strategy applied"
    teardown_test_env
}
test_process_with_replace_config

test_process_with_exclusion() {
    setup_test_env
    mkdir -p "$TEST_DIR/.claude/rules/base"
    echo "# Should remain" > "$TEST_DIR/.claude/rules/base/keep.md"
    echo "# Should be excluded" > "$TEST_DIR/.claude/rules/base/exclude.md"
    echo "# Local keep" > "$TEST_DIR/.claude/rules-local/base/keep.md"
    echo "# Local exclude" > "$TEST_DIR/.claude/rules-local/base/exclude.md"
    cat > "$TEST_DIR/.claude/rules-config.local.json" <<'EOF'
{"exclude": ["base/exclude.md"]}
EOF

    process_overrides "$TEST_DIR/.claude"

    local keep_result exclude_result
    keep_result=$(cat "$TEST_DIR/.claude/rules/base/keep.md")
    exclude_result=$(cat "$TEST_DIR/.claude/rules/base/exclude.md")

    assert_contains "$keep_result" "# Local keep" "Non-excluded file merged"
    assert_equals "# Should be excluded" "$exclude_result" "Excluded file unchanged"
    teardown_test_env
}
test_process_with_exclusion

# ============================================
# TEST: Edge cases
# ============================================
echo ""
echo "=== Testing Edge Cases ==="
echo ""

test_hidden_files_skipped() {
    setup_test_env
    mkdir -p "$TEST_DIR/.claude/rules/base"
    echo "# Central" > "$TEST_DIR/.claude/rules/base/test.md"
    echo "# Hidden" > "$TEST_DIR/.claude/rules-local/base/.hidden.md"
    echo "# Visible" > "$TEST_DIR/.claude/rules-local/base/test.md"

    process_overrides "$TEST_DIR/.claude"

    # Hidden file should not create a new rule
    if [[ ! -f "$TEST_DIR/.claude/rules/base/.hidden.md" ]]; then
        echo "✓ Hidden files are skipped"
        ((TESTS_PASSED++))
    else
        echo "✗ Hidden files should be skipped"
        ((TESTS_FAILED++))
    fi
    teardown_test_env
}
test_hidden_files_skipped

test_non_md_files_skipped() {
    setup_test_env
    mkdir -p "$TEST_DIR/.claude/rules/base"
    echo "# Central" > "$TEST_DIR/.claude/rules/base/test.md"
    echo "not markdown" > "$TEST_DIR/.claude/rules-local/base/test.txt"

    process_overrides "$TEST_DIR/.claude"

    if [[ ! -f "$TEST_DIR/.claude/rules/base/test.txt" ]]; then
        echo "✓ Non-.md files are skipped"
        ((TESTS_PASSED++))
    else
        echo "✗ Non-.md files should be skipped"
        ((TESTS_FAILED++))
    fi
    teardown_test_env
}
test_non_md_files_skipped

test_local_only_file_added() {
    setup_test_env
    mkdir -p "$TEST_DIR/.claude/rules/base"
    echo "# Central" > "$TEST_DIR/.claude/rules/base/existing.md"
    echo "# New local rule" > "$TEST_DIR/.claude/rules-local/base/new-rule.md"

    process_overrides "$TEST_DIR/.claude"

    if [[ -f "$TEST_DIR/.claude/rules/base/new-rule.md" ]]; then
        local content
        content=$(cat "$TEST_DIR/.claude/rules/base/new-rule.md")
        assert_equals "# New local rule" "$content" "Local-only files are added"
    else
        echo "✗ Local-only files should be added"
        ((TESTS_FAILED++))
    fi
    teardown_test_env
}
test_local_only_file_added

# ============================================
# Results
# ============================================
echo ""
echo "========================================"
echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
echo "========================================"

if [[ $TESTS_FAILED -gt 0 ]]; then
    exit 1
else
    echo "All tests passed!"
    exit 0
fi
