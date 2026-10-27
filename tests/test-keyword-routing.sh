#!/usr/bin/env bash
#
# Regression tests for prompt-to-rule routing in activate-rules.sh
#
# Unlike scripts/test-keyword-validation.sh, which wraps each keyword in a
# synthetic prompt, these cases use natural phrasing (plurals, gerunds,
# tool names) to catch keywords that never fire in real prompts. Language
# cases run inside minimal fixture projects.
#
# Usage:
#   ./tests/test-keyword-routing.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly REPO_ROOT
readonly HOOK_SCRIPT="${REPO_ROOT}/.claude/hooks/activate-rules.sh"

if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required (apt-get install jq / brew install jq)"
    exit 1
fi

TESTS_PASSED=0
TESTS_FAILED=0

# Fixture projects. Language rules need definitive files (has_definitive_files
# in .claude/lib/detection.sh); "empty" leaves only keyword routing.
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT
mkdir -p "$WORK_DIR/empty" "$WORK_DIR/python" "$WORK_DIR/typescript"
touch "$WORK_DIR/python/requirements.txt"
echo '{}' > "$WORK_DIR/typescript/package.json"

RUN_DIR="$WORK_DIR/empty"

# use_project empty|python|typescript
use_project() {
    RUN_DIR="$WORK_DIR/$1"
}

# Print the rules the hook matched for a prompt, one per line
matched_rules() {
    local prompt="$1"
    local input
    input=$(jq -cn --arg p "$prompt" '{prompt: $p}')

    (cd "$RUN_DIR" && CLAUDE_PROJECT_DIR="$REPO_ROOT" "$HOOK_SCRIPT" <<< "$input" 2>/dev/null) |
        jq -r '.systemMessage // empty' |
        grep "^🔍 Rules:" |
        sed 's/^🔍 Rules: //' |
        tr ',' '\n' |
        sed 's/^ *//; s/ *$//' || true
}

# expect_rule PROMPT RULE yes|no
expect_rule() {
    local prompt="$1"
    local rule="$2"
    local should_match="$3"
    local rules
    rules=$(matched_rules "$prompt")

    local found=no
    if grep -qx "$rule" <<< "$rules"; then
        found=yes
    fi

    if [[ "$found" == "$should_match" ]]; then
        echo "✓ '$prompt' -> $rule ($should_match)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ '$prompt' -> $rule (expected $should_match, got: ${rules//$'\n'/, })"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

echo "Testing natural-language prompt routing..."
echo

echo "Plural and gerund forms"
expect_rule "write tests for the parser" "base/testing-philosophy" yes
expect_rule "improve testing in the api layer" "base/testing-philosophy" yes
echo

echo "Mutation testing"
expect_rule "add mutation testing to this project" "base/testing-philosophy" yes
expect_rule "our mutation score dropped after the refactor" "base/testing-philosophy" yes
expect_rule "kill the surviving mutants in the billing module" "base/testing-philosophy" yes
expect_rule "configure stryker for the frontend" "base/testing-philosophy" yes
expect_rule "run mutmut against the billing module" "base/testing-philosophy" yes
expect_rule "add pitest to the maven build" "base/testing-philosophy" yes
echo

echo "Property-based testing"
expect_rule "write property-based tests for the parser" "base/testing-philosophy" yes
expect_rule "add property based checks to the encoder" "base/testing-philosophy" yes
expect_rule "use hypothesis to fuzz the date parser" "base/testing-philosophy" yes
expect_rule "add fast-check arbitraries for the reducer" "base/testing-philosophy" yes
expect_rule "add proptest strategies for the tokenizer" "base/testing-philosophy" yes
echo

echo "Architecture decision records"
expect_rule "write an ADR for choosing postgres" "base/knowledge-management" yes
expect_rule "review the ADRs in docs/architecture/adr" "base/knowledge-management" yes
expect_rule "add a decision record for the queue choice" "base/knowledge-management" yes
expect_rule "create an architecture decision record" "base/knowledge-management" yes
expect_rule "create an architecture decision record" "base/architecture-principles" yes
echo

echo "Language testing rules (follow the base testing keywords)"
use_project python
expect_rule "add hypothesis checks to the python parser" "languages/python/testing" yes
expect_rule "run mutmut on the python billing module" "languages/python/testing" yes
expect_rule "write tests for the python parser" "languages/python/testing" yes
expect_rule "/xtest the python parser" "languages/python/testing" yes
expect_rule "inspect the python logging setup" "languages/python" yes
expect_rule "inspect the python logging setup" "languages/python/testing" no
expect_rule "upgrade to the latest python release" "languages/python" yes
expect_rule "upgrade to the latest python release" "languages/python/testing" no
use_project typescript
expect_rule "configure stryker for the typescript frontend" "languages/typescript/testing" yes
expect_rule "add fast-check arbitraries to the typescript reducer" "languages/typescript/testing" yes
use_project empty
echo

echo "False-positive guards"
expect_rule "add a useMutation hook for the signup form" "base/testing-philosophy" no
expect_rule "write a graphql mutation for createUser" "base/testing-philosophy" no
expect_rule "render the quadrant chart on the dashboard" "base/knowledge-management" no

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
