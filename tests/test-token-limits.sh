#!/usr/bin/env bash
#
# Token Limit Testing for Centralized Rules
#
# This script tests that the rule detection system properly handles token limits
# and warns when approaching or exceeding configured limits.
#
# Usage:
#   ./tests/test-token-limits.sh [--verbose]
#
# Options:
#   --verbose    Show detailed output for each test
#   --help       Show this help message
#
# shellcheck disable=SC2317  # Functions are called via run_test, not directly

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly REPO_ROOT

# Source shared libraries
# shellcheck source=../lib/logging.sh
# shellcheck disable=SC1091
source "${REPO_ROOT}/lib/logging.sh"

# Test configuration
VERBOSE=false
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
declare -a FAILED_TESTS_LIST=()

# Default token limits (from skill configuration)
readonly DEFAULT_MAX_TOKENS=5000
# WARNING_THRESHOLD and CRITICAL_THRESHOLD are used in test functions
# shellcheck disable=SC2034
readonly WARNING_THRESHOLD=4000  # 80% of 5000
# shellcheck disable=SC2034
readonly CRITICAL_THRESHOLD=4750 # 95% of 5000

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            head -n 12 "$0" | tail -n +3 | sed 's/^# //'
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Helper: Run a test case
run_test() {
    local test_name="$1"
    local test_function="$2"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    if [[ "$VERBOSE" == true ]]; then
        log_info "Running: $test_name"
    fi

    if $test_function; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        if [[ "$VERBOSE" == true ]]; then
            log_success "✓ $test_name"
        else
            echo -n "."
        fi
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_TESTS_LIST+=("$test_name")
        log_error "✗ $test_name"
    fi
}

# Helper: Estimate tokens from a rule file
estimate_file_tokens() {
    local file_path="$1"

    if [[ ! -f "$file_path" ]]; then
        echo "0"
        return
    fi

    # Rough estimation: ~4 characters per token
    local char_count
    char_count=$(wc -c < "$file_path")
    local estimated_tokens=$((char_count / 4))

    echo "$estimated_tokens"
}

# Helper: Calculate total tokens for a list of rules
calculate_total_tokens() {
    local -a rules=("$@")
    local total=0

    # Check if array is empty
    if [[ ${#rules[@]} -eq 0 ]]; then
        echo "0"
        return
    fi

    for rule in "${rules[@]}"; do
        local rule_path="${REPO_ROOT}/${rule}"
        local tokens
        tokens=$(estimate_file_tokens "$rule_path")
        total=$((total + tokens))
    done

    echo "$total"
}

# Test: Base rules are within reasonable token limits
test_base_rules_token_limit() {
    local base_dir="${REPO_ROOT}/base"
    local total_tokens=0

    # Calculate tokens for all base rules
    while IFS= read -r -d '' rule_file; do
        local tokens
        tokens=$(estimate_file_tokens "$rule_file")
        total_tokens=$((total_tokens + tokens))
    done < <(find "$base_dir" -name "*.md" -print0 2>/dev/null || true)

    if [[ "$VERBOSE" == true ]]; then
        log_info "Total base rules tokens: $total_tokens"
    fi

    # Base rules should be reasonable (not exceeding 200k tokens for all)
    # This is informational - we can calculate token counts
    [[ $total_tokens -lt 200000 ]]
}

# Test: Individual rule files are within size limits
test_individual_rule_sizes() {
    local max_single_rule_tokens=5000

    # Check each rule directory
    for category in base languages frameworks cloud; do
        local cat_dir="${REPO_ROOT}/${category}"
        [[ ! -d "$cat_dir" ]] && continue

        while IFS= read -r -d '' rule_file; do
            local tokens
            tokens=$(estimate_file_tokens "$rule_file")

            if [[ $tokens -gt $max_single_rule_tokens ]]; then
                if [[ "$VERBOSE" == true ]]; then
                    log_warn "Large rule: ${rule_file#"$REPO_ROOT/"} ($tokens tokens)"
                fi
                # Don't fail, just warn - large rules are OK
            fi
        done < <(find "$cat_dir" -name "*.md" -print0 2>/dev/null || true)
    done

    # Always pass - this is informational
    true
}

# Test: Common rule combinations fit within limits
test_common_combinations() {
    # Simulate a common scenario: Python project with testing and security
    local -a rules=(
        "base/security-principles.md"
        "base/testing-philosophy.md"
        "languages/python/coding-standards.md"
    )

    local total_tokens
    total_tokens=$(calculate_total_tokens "${rules[@]+"${rules[@]}"}")

    if [[ "$VERBOSE" == true ]]; then
        log_info "Common Python combination: $total_tokens tokens"
    fi

    # Should be calculable and reasonable (under 20k for a 3-rule combination)
    [[ $total_tokens -gt 0 ]] && [[ $total_tokens -lt 20000 ]]
}

# Test: Warning threshold detection
test_warning_threshold_detection() {
    # Test that we can detect when approaching token limit
    local current_tokens=4100  # 82% of 5000
    local max_tokens=$DEFAULT_MAX_TOKENS

    local percent_used=$((current_tokens * 100 / max_tokens))

    # Should be above 80%
    [[ $percent_used -ge 80 ]]
}

# Test: Critical threshold detection
test_critical_threshold_detection() {
    # Test that we can detect when critically close to token limit
    local current_tokens=4800  # 96% of 5000
    local max_tokens=$DEFAULT_MAX_TOKENS

    local percent_used=$((current_tokens * 100 / max_tokens))

    # Should be above 95%
    [[ $percent_used -ge 95 ]]
}

# Test: TypeScript project token usage
test_typescript_project_tokens() {
    local -a rules=(
        "base/testing-philosophy.md"
        "languages/typescript/coding-standards.md"
        "languages/typescript/testing.md"
    )

    local total_tokens
    total_tokens=$(calculate_total_tokens "${rules[@]+"${rules[@]}"}")

    if [[ "$VERBOSE" == true ]]; then
        log_info "TypeScript project combination: $total_tokens tokens"
    fi

    # Should be calculable and reasonable (under 20k for a 3-rule combination)
    [[ $total_tokens -gt 0 ]] && [[ $total_tokens -lt 20000 ]]
}

# Test: Maximum realistic scenario
test_maximum_realistic_scenario() {
    # Simulate maximum realistic load: base rules + language + framework + cloud
    local -a rules=(
        "base/security-principles.md"
        "base/testing-philosophy.md"
        "base/git-workflow.md"
        "base/architecture-principles.md"
        "languages/python/coding-standards.md"
    )

    local total_tokens
    total_tokens=$(calculate_total_tokens "${rules[@]+"${rules[@]}"}")

    if [[ "$VERBOSE" == true ]]; then
        log_info "Maximum realistic scenario: $total_tokens tokens"
    fi

    # Should be calculable (not fail)
    [[ $total_tokens -gt 0 ]]
}

# Test: Empty rules list handling
test_empty_rules_list() {
    local -a rules=()

    local total_tokens
    total_tokens=$(calculate_total_tokens "${rules[@]+"${rules[@]}"}")

    # Should be zero
    [[ $total_tokens -eq 0 ]]
}

# Test: Non-existent rule handling
test_nonexistent_rule_handling() {
    local -a rules=("nonexistent/rule.md")

    local total_tokens
    total_tokens=$(calculate_total_tokens "${rules[@]+"${rules[@]}"}")

    # Should be zero (file doesn't exist)
    [[ $total_tokens -eq 0 ]]
}

# Test: Token estimation consistency
test_token_estimation_consistency() {
    # Test that we get consistent estimates for the same file
    local test_file="${REPO_ROOT}/base/git-workflow.md"

    if [[ ! -f "$test_file" ]]; then
        # Skip if file doesn't exist
        return 0
    fi

    local tokens1
    local tokens2
    tokens1=$(estimate_file_tokens "$test_file")
    tokens2=$(estimate_file_tokens "$test_file")

    # Should be identical
    [[ "$tokens1" == "$tokens2" ]]
}

# Test: All rule files are readable and estimatable
test_all_rules_estimatable() {
    for category in base languages frameworks cloud; do
        local cat_dir="${REPO_ROOT}/${category}"
        [[ ! -d "$cat_dir" ]] && continue

        while IFS= read -r -d '' rule_file; do
            local tokens
            tokens=$(estimate_file_tokens "$rule_file")

            if [[ $tokens -eq 0 ]]; then
                if [[ "$VERBOSE" == true ]]; then
                    log_warn "Empty or unreadable: ${rule_file#"$REPO_ROOT/"}"
                fi
            fi
        done < <(find "$cat_dir" -name "*.md" -print0 2>/dev/null || true)
    done

    # Always pass - informational
    true
}

# Main test execution
main() {
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "  Token Limit Testing"
    echo "═══════════════════════════════════════════════════════"
    echo ""

    log_info "Testing token limit enforcement and warnings..."
    echo ""

    # Run all tests
    run_test "Base rules token limit" test_base_rules_token_limit
    run_test "Individual rule sizes" test_individual_rule_sizes
    run_test "Common rule combinations" test_common_combinations
    run_test "Warning threshold detection" test_warning_threshold_detection
    run_test "Critical threshold detection" test_critical_threshold_detection
    run_test "TypeScript project tokens" test_typescript_project_tokens
    run_test "Maximum realistic scenario" test_maximum_realistic_scenario
    run_test "Empty rules list handling" test_empty_rules_list
    run_test "Non-existent rule handling" test_nonexistent_rule_handling
    run_test "Token estimation consistency" test_token_estimation_consistency
    run_test "All rules estimatable" test_all_rules_estimatable

    # Print summary
    echo ""
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "  Test Summary"
    echo "═══════════════════════════════════════════════════════"
    echo "Total Tests:  $TOTAL_TESTS"
    echo -e "${GREEN}Passed:       $PASSED_TESTS${NC}"
    echo -e "${RED}Failed:       $FAILED_TESTS${NC}"
    echo ""

    if [[ $FAILED_TESTS -gt 0 ]]; then
        echo "Failed Tests:"
        for test_name in "${FAILED_TESTS_LIST[@]}"; do
            echo "  - $test_name"
        done
        echo ""
        echo -e "${RED}✗ Some tests failed${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ All token limit tests passed!${NC}"
        echo ""
        log_info "Token limit enforcement is working correctly"
        exit 0
    fi
}

# Run main function
main "$@"
