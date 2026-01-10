#!/usr/bin/env bash
#
# Centralized Rules - Keyword Validation Testing
#
# This script tests that keywords in skill-rules.json correctly trigger
# the appropriate rule categories in the hook script.
#
# Usage:
#   ./scripts/test-keyword-validation.sh [--num-tests N] [--verbose]
#
# Options:
#   --num-tests N    Number of random keywords to test (default: 10)
#   --verbose        Show detailed output for each test
#   --all            Test ALL keywords (ignores --num-tests)
#   --category CAT   Test only specific category (base|languages|cloud)
#

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
readonly SKILL_RULES_JSON="${REPO_ROOT}/.claude/skills/skill-rules.json"
readonly HOOK_SCRIPT="${REPO_ROOT}/.claude/hooks/activate-rules.sh"

# Default options
NUM_TESTS=10
VERBOSE=false
TEST_ALL=false
CATEGORY_FILTER=""

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
declare -a FAILED_KEYWORDS=()

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --num-tests)
            NUM_TESTS="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --all)
            TEST_ALL=true
            shift
            ;;
        --category)
            CATEGORY_FILTER="$2"
            shift 2
            ;;
        --help)
            head -n 15 "$0" | tail -n +3 | sed 's/^# //'
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# NOTE: Logging functions provided by lib/logging.sh

# Check dependencies
check_dependencies() {
    if ! command -v jq >/dev/null 2>&1; then
        log_error "Missing required dependency: jq"
        log_info "Install with: brew install jq (macOS) or apt-get install jq (Linux)"
        exit 1
    fi
}

# Check required files exist
check_files() {
    if [[ ! -f "$SKILL_RULES_JSON" ]]; then
        log_error "skill-rules.json not found at: $SKILL_RULES_JSON"
        exit 1
    fi

    if [[ ! -f "$HOOK_SCRIPT" ]]; then
        log_error "Hook script not found at: $HOOK_SCRIPT"
        exit 1
    fi

    if [[ ! -x "$HOOK_SCRIPT" ]]; then
        log_error "Hook script is not executable: $HOOK_SCRIPT"
        log_info "Fix with: chmod +x $HOOK_SCRIPT"
        exit 1
    fi
}

# Extract all keywords from skill-rules.json
extract_keywords() {
    local category="$1"
    local keywords_json

    case "$category" in
        base)
            # Extract keywords from base categories
            keywords_json=$(jq -r '
                .keywordMappings.base |
                to_entries[] |
                {
                    category: ("base/" + .key),
                    keywords: .value.keywords,
                    rules: .value.rules
                }
            ' "$SKILL_RULES_JSON")
            ;;
        languages)
            # Extract keywords from languages
            keywords_json=$(jq -r '
                .keywordMappings.languages |
                to_entries[] |
                {
                    category: ("languages/" + .key),
                    keywords: .value.keywords,
                    rules: .value.rules
                }
            ' "$SKILL_RULES_JSON")
            ;;
        cloud)
            # Extract keywords from cloud providers
            keywords_json=$(jq -r '
                .keywordMappings.cloud |
                to_entries[] |
                {
                    category: ("cloud/" + .key),
                    keywords: .value.keywords,
                    rules: .value.rules
                }
            ' "$SKILL_RULES_JSON")
            ;;
        *)
            log_error "Unknown category: $category"
            return 1
            ;;
    esac

    echo "$keywords_json"
}

# Create definitive files for language testing
create_language_files() {
    local category="$1"
    local test_dir="$2"

    case "$category" in
        languages/python)
            touch "$test_dir/requirements.txt"
            ;;
        languages/javascript)
            touch "$test_dir/package.json"
            ;;
        languages/typescript)
            touch "$test_dir/package.json"
            ;;
        languages/go)
            touch "$test_dir/go.mod"
            ;;
        languages/rust)
            touch "$test_dir/Cargo.toml"
            ;;
        languages/java)
            touch "$test_dir/pom.xml"
            ;;
        languages/ruby)
            touch "$test_dir/Gemfile"
            ;;
        languages/bash)
            touch "$test_dir/script.sh"
            ;;
    esac
}

# Test a single keyword
test_keyword() {
    local keyword="$1"
    local expected_rules="$2"
    local category_name="$3"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    # Create test prompt with the keyword
    local test_prompt="Test with keyword: $keyword"
    local test_input="{\"prompt\":\"$test_prompt\"}"

    # For language categories, create a temp directory with definitive files
    local test_dir=""
    local original_dir=""
    if [[ "$category_name" == languages/* ]]; then
        test_dir=$(mktemp -d)
        original_dir=$(pwd)
        create_language_files "$category_name" "$test_dir"
        cd "$test_dir"
    fi

    # Run the hook script and capture output
    # IMPORTANT: Export CLAUDE_PROJECT_DIR so the hook can find skill-rules.json
    # when running from temp directories (otherwise it falls back to hardcoded patterns)
    local hook_output
    hook_output=$(export CLAUDE_PROJECT_DIR="${REPO_ROOT}"; echo "$test_input" | "$HOOK_SCRIPT" 2>&1 || true)

    # Clean up temp directory if created
    if [[ -n "$test_dir" ]]; then
        cd "$original_dir"
        rm -rf "$test_dir"
    fi

    # Extract matched rules from JSON output (hook returns JSON with systemMessage)
    local matched_rules
    if echo "$hook_output" | jq -e . >/dev/null 2>&1; then
        # JSON output - extract from systemMessage
        local system_message
        system_message=$(echo "$hook_output" | jq -r '.systemMessage // empty')

        # Parse banner format: "🔍 Rules: rule1, rule2, rule3"
        # Extract the rules line, split by comma, and trim whitespace
        matched_rules=$(echo "$system_message" | \
            grep "^🔍 Rules:" | \
            sed 's/^🔍 Rules: //' | \
            tr ',' '\n' | \
            sed 's/^ *//' | \
            sed 's/ *$//' || echo "")
    else
        # Plain text output (fallback for testing)
        # Try banner format first
        matched_rules=$(echo "$hook_output" | \
            grep "^🔍 Rules:" | \
            sed 's/^🔍 Rules: //' | \
            tr ',' '\n' | \
            sed 's/^ *//' | \
            sed 's/ *$//' || echo "")

        # Fallback to old format if new format not found
        if [[ -z "$matched_rules" ]]; then
            matched_rules=$(echo "$hook_output" | grep -A 100 "Matched Rule Categories:" | grep "☐" | sed 's/.*☐ //' || echo "")
        fi
    fi

    # Check if expected rules are present
    local all_found=true
    local missing_rules=()

    while IFS= read -r expected_rule; do
        [[ -z "$expected_rule" ]] && continue

        if ! echo "$matched_rules" | grep -q "^${expected_rule}$"; then
            all_found=false
            missing_rules+=("$expected_rule")
        fi
    done <<< "$expected_rules"

    # Report results
    if [[ "$all_found" == true ]]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        if [[ "$VERBOSE" == true ]]; then
            log_success "[$category_name] Keyword '$keyword' correctly triggered rules"
            if [[ -n "$matched_rules" ]]; then
                echo "$matched_rules" | while read -r rule; do
                    echo "  - $rule"
                done
            fi
        else
            echo -n "."
        fi
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_KEYWORDS+=("$keyword")
        log_error "[$category_name] Keyword '$keyword' failed to trigger expected rules"
        log_warn "Expected rules: $expected_rules"
        log_warn "Missing: ${missing_rules[*]}"
        if [[ -n "$matched_rules" ]]; then
            log_info "Matched rules:"
            echo "$matched_rules" | while read -r rule; do
                echo "  - $rule"
            done
        else
            log_warn "No rules were matched!"
        fi
    fi
}

# Test keywords from a category
test_category() {
    local category="$1"
    local keywords_data

    keywords_data=$(extract_keywords "$category")

    if [[ -z "$keywords_data" ]]; then
        log_warn "No keywords found for category: $category"
        return
    fi

    # Parse each category entry
    local entries_count
    entries_count=$(echo "$keywords_data" | jq -s 'length')

    for ((i=0; i<entries_count; i++)); do
        local entry
        entry=$(echo "$keywords_data" | jq -s ".[$i]")

        local category_name
        category_name=$(echo "$entry" | jq -r '.category')

        local keywords
        keywords=$(echo "$entry" | jq -r '.keywords[]?' || echo "")

        local rules
        rules=$(echo "$entry" | jq -r '.rules[]?' || echo "")

        [[ -z "$keywords" ]] && continue
        [[ -z "$rules" ]] && continue

        # Convert keywords to array
        local keywords_array=()
        while IFS= read -r kw; do
            [[ -n "$kw" ]] && keywords_array+=("$kw")
        done <<< "$keywords"

        # Test keywords
        if [[ "$TEST_ALL" == true ]]; then
            # Test all keywords
            for keyword in "${keywords_array[@]}"; do
                test_keyword "$keyword" "$rules" "$category_name"
            done
        else
            # Test a random sample
            local num_to_test=$((NUM_TESTS < ${#keywords_array[@]} ? NUM_TESTS : ${#keywords_array[@]}))
            local tested=0

            # Shuffle and take first N (preserve multi-word keywords)
            while IFS= read -r keyword; do
                [[ -n "$keyword" ]] || continue
                test_keyword "$keyword" "$rules" "$category_name"
                tested=$((tested + 1))
            done < <(printf '%s\n' "${keywords_array[@]}" | shuf | head -n "$num_to_test")
        fi
    done
}

# Main test execution
main() {
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "  Centralized Rules - Keyword Validation Testing"
    echo "═══════════════════════════════════════════════════════"
    echo ""

    log_info "Checking dependencies..."
    check_dependencies

    log_info "Checking required files..."
    check_files

    log_success "Environment checks passed"
    echo ""

    # Determine which categories to test
    local categories_to_test=()
    if [[ -n "$CATEGORY_FILTER" ]]; then
        categories_to_test=("$CATEGORY_FILTER")
    else
        categories_to_test=("base" "languages" "cloud")
    fi

    log_info "Testing categories: ${categories_to_test[*]}"
    if [[ "$TEST_ALL" == true ]]; then
        log_info "Mode: Testing ALL keywords"
    else
        log_info "Mode: Testing $NUM_TESTS random keywords per category"
    fi
    echo ""

    # Run tests
    for category in "${categories_to_test[@]}"; do
        log_info "Testing category: $category"
        test_category "$category"
        echo ""
    done

    # Print summary
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "  Test Summary"
    echo "═══════════════════════════════════════════════════════"
    echo -e "Total Tests:  ${TOTAL_TESTS}"
    echo -e "${GREEN}Passed:       ${PASSED_TESTS}${NC}"
    echo -e "${RED}Failed:       ${FAILED_TESTS}${NC}"
    echo ""

    if [[ ${FAILED_TESTS} -gt 0 ]]; then
        echo "Failed Keywords:"
        for keyword in "${FAILED_KEYWORDS[@]}"; do
            echo "  - $keyword"
        done
        echo ""
        echo -e "${RED}✗ Some tests failed${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ All tests passed!${NC}"
        exit 0
    fi
}

# Run main function
main "$@"
