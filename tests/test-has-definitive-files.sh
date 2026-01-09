#!/usr/bin/env bash
#
# Unit tests for has_definitive_files() function in lib/detection.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly PROJECT_ROOT

# Source the detection library
# shellcheck source=../.claude/lib/detection.sh
source "${PROJECT_ROOT}/.claude/lib/detection.sh"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Create temporary test directory
TEST_DIR=$(mktemp -d)
readonly TEST_DIR
trap 'rm -rf "$TEST_DIR"' EXIT

# Helper function to run a test
run_test() {
    local test_name="$1"
    local expected_result="$2"  # "true" or "false"
    local lang="$3"
    shift 3
    local files=("$@")

    TESTS_RUN=$((TESTS_RUN + 1))

    echo -e "\n${YELLOW}Test ${TESTS_RUN}: ${test_name}${NC}"

    # Clean test directory
    rm -rf "${TEST_DIR:?}"/*

    # Create files
    for file in "${files[@]}"; do
        if [[ "$file" == *"/"* ]]; then
            mkdir -p "${TEST_DIR}/$(dirname "$file")"
        fi
        touch "${TEST_DIR}/${file}"
    done

    # Run test in test directory
    cd "$TEST_DIR"

    local result
    if has_definitive_files "$lang"; then
        result="true"
    else
        result="false"
    fi

    # Check result
    if [[ "$result" == "$expected_result" ]]; then
        echo -e "${GREEN}✓ PASSED - has_definitive_files('$lang') returned $result${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAILED: Expected $expected_result, got $result${NC}"
        echo "  Files created: ${files[*]}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test Rust detection
echo "=== Testing Rust Detection ==="
run_test "Rust with Cargo.toml" "true" "rust" "Cargo.toml"
run_test "Rust without Cargo.toml" "false" "rust" "main.rs"

# Test Python detection
echo -e "\n=== Testing Python Detection ==="
run_test "Python with pyproject.toml" "true" "python" "pyproject.toml"
run_test "Python with setup.py" "true" "python" "setup.py"
run_test "Python with requirements.txt" "true" "python" "requirements.txt"
run_test "Python with all files" "true" "python" "pyproject.toml" "setup.py" "requirements.txt"
run_test "Python without definitive files" "false" "python" "main.py"

# Test JavaScript detection
echo -e "\n=== Testing JavaScript Detection ==="
run_test "JavaScript with package.json" "true" "javascript" "package.json"
run_test "JS shorthand with package.json" "true" "js" "package.json"
run_test "JavaScript without package.json" "false" "javascript" "index.js"

# Test TypeScript detection
echo -e "\n=== Testing TypeScript Detection ==="
run_test "TypeScript with package.json" "true" "typescript" "package.json"
run_test "TS shorthand with package.json" "true" "ts" "package.json"
run_test "TypeScript without package.json" "false" "typescript" "index.ts"

# Test Go detection
echo -e "\n=== Testing Go Detection ==="
run_test "Go with go.mod" "true" "go" "go.mod"
run_test "Go without go.mod" "false" "go" "main.go"

# Test Java detection
echo -e "\n=== Testing Java Detection ==="
run_test "Java with pom.xml" "true" "java" "pom.xml"
run_test "Java with build.gradle" "true" "java" "build.gradle"
run_test "Java with build.gradle.kts" "true" "java" "build.gradle.kts"
run_test "Java without definitive files" "false" "java" "Main.java"

# Test Ruby detection
echo -e "\n=== Testing Ruby Detection ==="
run_test "Ruby with Gemfile" "true" "ruby" "Gemfile"
run_test "Ruby without Gemfile" "false" "ruby" "app.rb"

# Test unknown language
echo -e "\n=== Testing Unknown Language ==="
run_test "Unknown language" "false" "unknown-lang" "file.txt"

# Test edge cases
echo -e "\n=== Testing Edge Cases ==="
run_test "Empty language string" "false" "" "package.json"
run_test "Rust false positive - trust keyword" "false" "rust" "trust.txt" "README.md"

# Print summary
echo -e "\n${YELLOW}======================================${NC}"
echo -e "${YELLOW}Test Summary${NC}"
echo -e "${YELLOW}======================================${NC}"
echo "Tests run:    ${TESTS_RUN}"
echo -e "${GREEN}Tests passed: ${TESTS_PASSED}${NC}"
if [[ ${TESTS_FAILED} -gt 0 ]]; then
    echo -e "${RED}Tests failed: ${TESTS_FAILED}${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi
