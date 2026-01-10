#!/usr/bin/env bash
#
# Integration tests for language detection requiring both keywords AND definitive files
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

# Create temporary test directory
TEST_DIR=$(mktemp -d)
readonly TEST_DIR
trap 'rm -rf "$TEST_DIR"' EXIT

# Helper function to test hook output
test_language_detection() {
    local test_name="$1"
    local prompt="$2"
    local should_load_lang="$3"  # "true" or "false"
    shift 3
    local files=("$@")

    TESTS_RUN=$((TESTS_RUN + 1))

    echo -e "\n${YELLOW}Test ${TESTS_RUN}: ${test_name}${NC}"
    echo "Prompt: \"${prompt}\""
    echo "Should load language rules: ${should_load_lang}"
    echo "Files: ${files[*]:-none}"

    # Clean test directory
    rm -rf "${TEST_DIR:?}"/*

    # Create files
    for file in "${files[@]}"; do
        if [[ "$file" == *"/"* ]]; then
            mkdir -p "${TEST_DIR}/$(dirname "$file")"
        fi
        touch "${TEST_DIR}/${file}"
    done

    # Create JSON input for hook
    local input_json
    input_json=$(jq -n --arg prompt "$prompt" '{prompt: $prompt}')

    # Run hook in test directory
    local output
    cd "$TEST_DIR"

    # Set VERBOSE to see debug messages about skipped languages
    # Set CLAUDE_PROJECT_DIR to PROJECT_ROOT so the hook finds skill-rules.json
    if ! output=$(echo "$input_json" | VERBOSE=true CLAUDE_PROJECT_DIR="$PROJECT_ROOT" "$HOOK_SCRIPT" 2>&1); then
        echo -e "${RED}✗ FAILED: Hook execution failed${NC}"
        echo "Output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        cd "$PROJECT_ROOT"
        return 1
    fi

    cd "$PROJECT_ROOT"

    # Check if language rules were loaded or skipped
    local lang_loaded="false"

    # Check for language rules in output - look in both JSON fields and debug output
    if echo "$output" | grep -qE '🔍 Rules:.*languages/(rust|python|go|java|javascript|typescript)'; then
        lang_loaded="true"
    elif echo "$output" | grep -qE 'Matched rules:.*languages/(rust|python|go|java|javascript|typescript)'; then
        lang_loaded="true"
    fi

    # Check result
    if [[ "$lang_loaded" == "$should_load_lang" ]]; then
        echo -e "${GREEN}✓ PASSED - Language rules loaded: ${lang_loaded}${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAILED: Expected ${should_load_lang}, got ${lang_loaded}${NC}"
        echo "Output snippet: $(echo "$output" | head -20)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

echo "=== Testing False Positive Prevention ==="
echo "Keywords match but no definitive files - should NOT load language rules"

# Test Rust false positives
test_language_detection "Rust keyword 'trust' without Cargo.toml" \
    "I need to build trust with the API" \
    "false" \
    "README.md"

test_language_detection "Rust keyword 'rust' without Cargo.toml" \
    "I want to learn rust programming" \
    "false" \
    "README.md"

# Test Go false positives
test_language_detection "Go keyword without go.mod" \
    "Let's go ahead and implement this" \
    "false" \
    "README.md"

# Test Python false positives
test_language_detection "Python keyword without definitive files" \
    "The python snake is dangerous" \
    "false" \
    "README.md"

echo -e "\n=== Testing Correct Detection ==="
echo "Keywords match AND definitive files exist - should load language rules"

# Test Rust correct detection
test_language_detection "Rust keyword with Cargo.toml" \
    "I want to write rust code" \
    "true" \
    "Cargo.toml" "src/main.rs"

test_language_detection "Rust in prompt with project files" \
    "Help me with this rust function" \
    "true" \
    "Cargo.toml"

# Test Python correct detection
test_language_detection "Python keyword with pyproject.toml" \
    "I need help with python code" \
    "true" \
    "pyproject.toml" "main.py"

test_language_detection "Python with requirements.txt" \
    "Fix this python bug" \
    "true" \
    "requirements.txt"

# Test Go correct detection
test_language_detection "Go keyword with go.mod" \
    "Help me write go code" \
    "true" \
    "go.mod" "main.go"

# Test JavaScript/TypeScript correct detection
test_language_detection "JavaScript with package.json" \
    "I need to fix this javascript function" \
    "true" \
    "package.json" "index.js"

test_language_detection "TypeScript with package.json" \
    "Help with typescript code" \
    "true" \
    "package.json" "index.ts"

# Test Java correct detection
test_language_detection "Java with pom.xml" \
    "Fix this java class" \
    "true" \
    "pom.xml" "Main.java"

echo -e "\n=== Testing Edge Cases ==="

# Test no language keywords at all
test_language_detection "No language keywords" \
    "How do I commit my changes?" \
    "false" \
    "README.md"

# Test language file exists but no keyword
test_language_detection "Cargo.toml exists but no rust keyword" \
    "How do I structure this project?" \
    "false" \
    "Cargo.toml"

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
