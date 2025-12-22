#!/usr/bin/env bash
#
# Test script to verify slash command detection in activate-rules.sh hook
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly PROJECT_ROOT
readonly HOOK_SCRIPT="${PROJECT_ROOT}/.claude/hooks/activate-rules.sh"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to run a test
run_test() {
    local test_name="$1"
    local prompt="$2"
    local expected_rule="$3"

    TESTS_RUN=$((TESTS_RUN + 1))

    echo -e "\n${YELLOW}Test ${TESTS_RUN}: ${test_name}${NC}"
    echo "Prompt: \"${prompt}\""
    echo "Expected: ${expected_rule}"

    # Create JSON input
    local input_json
    input_json=$(jq -n --arg prompt "$prompt" '{prompt: $prompt}')

    # Run the hook
    local output
    if output=$(cd "$PROJECT_ROOT" && echo "$input_json" | "$HOOK_SCRIPT" 2>&1); then
        # Check if expected rule is in the output
        if echo "$output" | grep -q "$expected_rule"; then
            echo -e "${GREEN}✓ PASSED${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        else
            echo -e "${RED}✗ FAILED: Expected rule '${expected_rule}' not found in output${NC}"
            echo "Output: ${output}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    else
        echo -e "${RED}✗ FAILED: Hook execution failed${NC}"
        echo "Output: ${output}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Main test execution
main() {
    echo "=================================="
    echo "Slash Command Detection Tests"
    echo "=================================="

    # Check if hook exists
    if [[ ! -f "$HOOK_SCRIPT" ]]; then
        echo -e "${RED}Error: Hook script not found at ${HOOK_SCRIPT}${NC}"
        exit 1
    fi

    # Check if hook is executable
    if [[ ! -x "$HOOK_SCRIPT" ]]; then
        echo -e "${RED}Error: Hook script is not executable${NC}"
        exit 1
    fi

    # Git-related slash commands
    run_test "Detect /xgit command" "/xgit" "base/git-workflow"
    run_test "Detect /git command" "/git push" "base/git-workflow"
    run_test "Detect /xcommit command" "/xcommit" "base/git-workflow"
    run_test "Detect /commit command" "/commit changes" "base/git-workflow"
    run_test "Detect /push command" "/push to origin" "base/git-workflow"

    # Traditional git keywords (should still work)
    run_test "Detect 'commit' keyword" "commit these changes" "base/git-workflow"
    run_test "Detect 'pull request' keyword" "create a pull request" "base/git-workflow"

    # Test-related slash commands
    run_test "Detect /xtest command" "/xtest" "base/testing-philosophy"
    run_test "Detect /test command" "/test all units" "base/testing-philosophy"
    run_test "Detect /xtdd command" "/xtdd cycle" "base/testing-philosophy"

    # Security-related slash commands
    run_test "Detect /xsecurity command" "/xsecurity scan" "base/security-principles"
    run_test "Detect /security command" "/security audit" "base/security-principles"
    run_test "Detect /xaudit command" "/xaudit" "base/security-principles"

    # Refactoring-related slash commands
    run_test "Detect /xrefactor command" "/xrefactor code" "base/refactoring-patterns"
    run_test "Detect /xquality command" "/xquality check" "base/refactoring-patterns"
    run_test "Detect /xoptimize command" "/xoptimize performance" "base/refactoring-patterns"

    # Print summary
    echo ""
    echo "=================================="
    echo "Test Summary"
    echo "=================================="
    echo "Total tests run: ${TESTS_RUN}"
    echo -e "${GREEN}Passed: ${TESTS_PASSED}${NC}"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "${RED}Failed: ${TESTS_FAILED}${NC}"
        exit 1
    else
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    fi
}

# Run main function
main "$@"
