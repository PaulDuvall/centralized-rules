#!/usr/bin/env bash
#
# Test script to verify pre-commit quality gates trigger correctly
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

# Helper function to test if quality gates appear
test_quality_gates_present() {
    local test_name="$1"
    local prompt="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    echo -e "\n${YELLOW}Test ${TESTS_RUN}: ${test_name}${NC}"
    echo "Prompt: \"${prompt}\""
    echo "Expected: Quality gates should appear"

    # Create JSON input
    local input_json
    input_json=$(jq -n --arg prompt "$prompt" '{prompt: $prompt}')

    # Run the hook
    local output
    if output=$(cd "$PROJECT_ROOT" && echo "$input_json" | "$HOOK_SCRIPT" 2>&1); then
        # Check if quality gates appear in output
        if echo "$output" | grep -q "PRE-COMMIT QUALITY GATES DETECTED"; then
            echo -e "${GREEN}✓ PASSED - Quality gates triggered${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        else
            echo -e "${RED}✗ FAILED: Quality gates not found${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    else
        echo -e "${RED}✗ FAILED: Hook execution failed${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Helper function to test if quality gates are absent
test_quality_gates_absent() {
    local test_name="$1"
    local prompt="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    echo -e "\n${YELLOW}Test ${TESTS_RUN}: ${test_name}${NC}"
    echo "Prompt: \"${prompt}\""
    echo "Expected: No quality gates"

    # Create JSON input
    local input_json
    input_json=$(jq -n --arg prompt "$prompt" '{prompt: $prompt}')

    # Run the hook
    local output
    if output=$(cd "$PROJECT_ROOT" && echo "$input_json" | "$HOOK_SCRIPT" 2>&1); then
        # Check if quality gates are absent
        if ! echo "$output" | grep -q "PRE-COMMIT QUALITY GATES DETECTED"; then
            echo -e "${GREEN}✓ PASSED - No quality gates (expected)${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        else
            echo -e "${RED}✗ FAILED: Quality gates appeared when they shouldn't${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    else
        echo -e "${RED}✗ FAILED: Hook execution failed${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Main test execution
main() {
    echo "=========================================="
    echo "Pre-Commit Quality Gates Detection Tests"
    echo "=========================================="

    # Check if hook exists and is executable
    if [[ ! -f "$HOOK_SCRIPT" ]]; then
        echo -e "${RED}Error: Hook script not found at ${HOOK_SCRIPT}${NC}"
        exit 1
    fi

    if [[ ! -x "$HOOK_SCRIPT" ]]; then
        echo -e "${RED}Error: Hook script is not executable${NC}"
        exit 1
    fi

    echo ""
    echo "Testing Git Keywords (should trigger quality gates):"
    echo "─────────────────────────────────────────"

    # Git operation keywords
    test_quality_gates_present "commit keyword" "commit these changes"
    test_quality_gates_present "push keyword" "push to remote"
    test_quality_gates_present "git add keyword" "git add all files"
    test_quality_gates_present "pull request keyword" "create a pull request"
    test_quality_gates_present "merge keyword" "merge this branch"
    test_quality_gates_present "branch keyword" "create a new branch"
    test_quality_gates_present "rebase keyword" "rebase onto main"

    echo ""
    echo "Testing Git Slash Commands (should trigger quality gates):"
    echo "────────────────────────────────────────────────────"

    # Git slash commands
    test_quality_gates_present "/xgit command" "/xgit"
    test_quality_gates_present "/git command" "/git push origin main"
    test_quality_gates_present "/xcommit command" "/xcommit -m 'test'"
    test_quality_gates_present "/commit command" "/commit all changes"
    test_quality_gates_present "/push command" "/push to origin"

    echo ""
    echo "Testing Non-Git Operations (should NOT trigger quality gates):"
    echo "───────────────────────────────────────────────────────────"

    # Non-git operations
    test_quality_gates_absent "feature implementation" "add a new feature"
    test_quality_gates_absent "bug fix" "fix the login bug"
    test_quality_gates_absent "refactoring" "refactor the auth module"
    test_quality_gates_absent "testing" "write tests for the API"
    test_quality_gates_absent "documentation" "update the README"

    # Print summary
    echo ""
    echo "=========================================="
    echo "Test Summary"
    echo "=========================================="
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
