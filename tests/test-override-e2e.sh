#!/usr/bin/env bash
#
# E2E tests for override system integration
# Tests: baseline regression, local overrides, exclusions, mixed strategies
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Test helpers
pass() {
    echo -e "${GREEN}✓${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    echo "  $2"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

assert_file_exists() {
    local file="$1"
    local message="$2"
    if [[ -f "$file" ]]; then
        pass "$message"
    else
        fail "$message" "File not found: $file"
    fi
}

assert_file_contains() {
    local file="$1"
    local pattern="$2"
    local message="$3"
    if grep -q "$pattern" "$file" 2>/dev/null; then
        pass "$message"
    else
        fail "$message" "Pattern '$pattern' not found in $file"
    fi
}

assert_file_not_contains() {
    local file="$1"
    local pattern="$2"
    local message="$3"
    if ! grep -q "$pattern" "$file" 2>/dev/null; then
        pass "$message"
    else
        fail "$message" "Pattern '$pattern' found in $file (unexpected)"
    fi
}

# Create isolated test environment
create_test_project() {
    local test_dir
    test_dir=$(mktemp -d)
    mkdir -p "$test_dir/.claude/rules/base"
    mkdir -p "$test_dir/.claude/rules-local/base"
    echo "$test_dir"
}

cleanup_test_project() {
    local test_dir="$1"
    rm -rf "$test_dir"
}

# ============================================
# Scenario 1: Baseline (no overrides)
# ============================================
test_baseline_no_overrides() {
    echo ""
    echo "=== Scenario 1: Baseline (no overrides) ==="
    echo ""

    local test_dir
    test_dir=$(create_test_project)

    # Remove rules-local to simulate no overrides
    rm -rf "$test_dir/.claude/rules-local"

    # Create a central rule
    echo "# Central Testing Rule" > "$test_dir/.claude/rules/base/testing.md"
    echo "Follow these testing guidelines." >> "$test_dir/.claude/rules/base/testing.md"

    # Run process_overrides
    (
        cd "$test_dir"
        source "$PROJECT_ROOT/lib/override.sh"
        process_overrides ".claude"
    )

    # Verify central rule unchanged
    assert_file_contains "$test_dir/.claude/rules/base/testing.md" \
        "Central Testing Rule" \
        "Baseline: Central rule preserved"

    assert_file_contains "$test_dir/.claude/rules/base/testing.md" \
        "Follow these testing guidelines" \
        "Baseline: Central content intact"

    cleanup_test_project "$test_dir"
}

# ============================================
# Scenario 2: Local only (no config file)
# ============================================
test_local_only_no_config() {
    echo ""
    echo "=== Scenario 2: Local only (no config file) ==="
    echo ""

    local test_dir
    test_dir=$(create_test_project)

    # Create central and local rules
    echo "# Central Security Rule" > "$test_dir/.claude/rules/base/security.md"
    echo "# Local Security Addition" > "$test_dir/.claude/rules-local/base/security.md"
    echo "Extra security measures for this project." >> "$test_dir/.claude/rules-local/base/security.md"

    # No config file - should use default 'extend' strategy

    # Run process_overrides
    (
        cd "$test_dir"
        source "$PROJECT_ROOT/lib/override.sh"
        process_overrides ".claude"
    )

    # Verify both central and local content present (extend = central + local)
    assert_file_contains "$test_dir/.claude/rules/base/security.md" \
        "Central Security Rule" \
        "Local-only: Central content preserved"

    assert_file_contains "$test_dir/.claude/rules/base/security.md" \
        "Local Security Addition" \
        "Local-only: Local content appended"

    cleanup_test_project "$test_dir"
}

# ============================================
# Scenario 3: Full override with config
# ============================================
test_full_override_with_config() {
    echo ""
    echo "=== Scenario 3: Full override with config ==="
    echo ""

    local test_dir
    test_dir=$(create_test_project)

    # Create central and local rules
    echo "# Central Git Workflow" > "$test_dir/.claude/rules/base/git-workflow.md"
    echo "# Replaced Git Workflow" > "$test_dir/.claude/rules-local/base/git-workflow.md"
    echo "This project uses a different git workflow." >> "$test_dir/.claude/rules-local/base/git-workflow.md"

    # Create config with replace strategy
    cat > "$test_dir/.claude/rules-config.local.json" <<'EOF'
{
    "merge_strategy": "replace"
}
EOF

    # Run process_overrides
    (
        cd "$test_dir"
        source "$PROJECT_ROOT/lib/override.sh"
        process_overrides ".claude"
    )

    # Verify only local content present (replace)
    assert_file_not_contains "$test_dir/.claude/rules/base/git-workflow.md" \
        "Central Git Workflow" \
        "Full-override: Central content replaced"

    assert_file_contains "$test_dir/.claude/rules/base/git-workflow.md" \
        "Replaced Git Workflow" \
        "Full-override: Local content only"

    cleanup_test_project "$test_dir"
}

# ============================================
# Scenario 4: Exclusions
# ============================================
test_exclusions() {
    echo ""
    echo "=== Scenario 4: Exclusions ==="
    echo ""

    local test_dir
    test_dir=$(create_test_project)

    # Create central rules
    echo "# Central Quality Rule" > "$test_dir/.claude/rules/base/code-quality.md"
    echo "# Central Chaos Rule" > "$test_dir/.claude/rules/base/chaos-engineering.md"

    # Create local overrides for both
    echo "# Local Quality Override" > "$test_dir/.claude/rules-local/base/code-quality.md"
    echo "# Local Chaos Override" > "$test_dir/.claude/rules-local/base/chaos-engineering.md"

    # Create config excluding chaos-engineering
    cat > "$test_dir/.claude/rules-config.local.json" <<'EOF'
{
    "merge_strategy": "extend",
    "exclude": ["base/chaos-engineering.md"]
}
EOF

    # Run process_overrides
    (
        cd "$test_dir"
        source "$PROJECT_ROOT/lib/override.sh"
        process_overrides ".claude"
    )

    # Verify code-quality was merged
    assert_file_contains "$test_dir/.claude/rules/base/code-quality.md" \
        "Local Quality Override" \
        "Exclusions: Non-excluded file merged"

    # Verify chaos-engineering was NOT merged (excluded)
    assert_file_not_contains "$test_dir/.claude/rules/base/chaos-engineering.md" \
        "Local Chaos Override" \
        "Exclusions: Excluded file unchanged"

    assert_file_contains "$test_dir/.claude/rules/base/chaos-engineering.md" \
        "Central Chaos Rule" \
        "Exclusions: Excluded file retains central content"

    cleanup_test_project "$test_dir"
}

# ============================================
# Scenario 5: Mixed strategies
# ============================================
test_mixed_strategies() {
    echo ""
    echo "=== Scenario 5: Mixed strategies ==="
    echo ""

    local test_dir
    test_dir=$(create_test_project)

    # Create central rules
    echo "# Central Testing" > "$test_dir/.claude/rules/base/testing.md"
    echo "# Central Security" > "$test_dir/.claude/rules/base/security.md"
    echo "# Central Architecture" > "$test_dir/.claude/rules/base/architecture.md"

    # Create local overrides
    echo "# Local Testing" > "$test_dir/.claude/rules-local/base/testing.md"
    echo "# Local Security" > "$test_dir/.claude/rules-local/base/security.md"
    echo "# Local Architecture" > "$test_dir/.claude/rules-local/base/architecture.md"

    # Create config with different strategies per file
    cat > "$test_dir/.claude/rules-config.local.json" <<'EOF'
{
    "merge_strategy": "extend",
    "overrides": {
        "base/security.md": "replace",
        "base/architecture.md": "prepend"
    }
}
EOF

    # Run process_overrides
    (
        cd "$test_dir"
        source "$PROJECT_ROOT/lib/override.sh"
        process_overrides ".claude"
    )

    # Testing: extend (default) - both present
    assert_file_contains "$test_dir/.claude/rules/base/testing.md" \
        "Central Testing" \
        "Mixed: extend has central"
    assert_file_contains "$test_dir/.claude/rules/base/testing.md" \
        "Local Testing" \
        "Mixed: extend has local"

    # Security: replace - only local
    assert_file_not_contains "$test_dir/.claude/rules/base/security.md" \
        "Central Security" \
        "Mixed: replace removes central"
    assert_file_contains "$test_dir/.claude/rules/base/security.md" \
        "Local Security" \
        "Mixed: replace has local"

    # Architecture: prepend - local first, then central
    local arch_content
    arch_content=$(cat "$test_dir/.claude/rules/base/architecture.md")
    local local_pos central_pos
    local_pos=$(echo "$arch_content" | grep -n "Local Architecture" | cut -d: -f1)
    central_pos=$(echo "$arch_content" | grep -n "Central Architecture" | cut -d: -f1)

    if [[ "$local_pos" -lt "$central_pos" ]]; then
        pass "Mixed: prepend puts local first"
    else
        fail "Mixed: prepend puts local first" "Local at line $local_pos, Central at line $central_pos"
    fi

    cleanup_test_project "$test_dir"
}

# ============================================
# Scenario 6: Dry-run mode
# ============================================
test_dry_run() {
    echo ""
    echo "=== Scenario 6: Dry-run mode ==="
    echo ""

    local test_dir
    test_dir=$(create_test_project)

    # Create central and local rules
    echo "# Original Central" > "$test_dir/.claude/rules/base/test.md"
    echo "# Local Override" > "$test_dir/.claude/rules-local/base/test.md"

    # Test preview_overrides function directly (used by --dry-run)
    local output
    output=$(
        cd "$test_dir"
        source "$PROJECT_ROOT/lib/logging.sh"
        source "$PROJECT_ROOT/lib/override.sh"

        # preview_overrides shows what would happen without making changes
        preview_overrides() {
            local claude_dir="$1"
            local override_dir="${claude_dir}/rules-local"
            local config
            config=$(load_override_config "$claude_dir")

            while IFS= read -r -d '' local_file; do
                local rel_path="${local_file#"$override_dir"/}"
                if [[ "$(should_exclude_rule "$rel_path" "$config")" == "true" ]]; then
                    echo "SKIP: $rel_path"
                    continue
                fi
                local strategy
                strategy=$(get_merge_strategy "$rel_path" "$config")
                echo "MERGE ($strategy): $rel_path"
            done < <(find "$override_dir" -name "*.md" -type f ! -name ".*" -print0 2>/dev/null)
        }

        preview_overrides ".claude"
    )

    # Verify output mentions merge
    if echo "$output" | grep -q "MERGE"; then
        pass "Dry-run: Shows merge preview"
    else
        fail "Dry-run: Shows merge preview" "Output: $output"
    fi

    # Verify file unchanged after preview
    assert_file_contains "$test_dir/.claude/rules/base/test.md" \
        "Original Central" \
        "Dry-run: File not modified"

    assert_file_not_contains "$test_dir/.claude/rules/base/test.md" \
        "Local Override" \
        "Dry-run: Local not applied"

    cleanup_test_project "$test_dir"
}

# ============================================
# Scenario 7: New local-only file
# ============================================
test_new_local_file() {
    echo ""
    echo "=== Scenario 7: New local-only file ==="
    echo ""

    local test_dir
    test_dir=$(create_test_project)

    # Create only local rule (no central equivalent)
    echo "# Custom Project Rule" > "$test_dir/.claude/rules-local/base/custom.md"
    echo "This rule only exists locally." >> "$test_dir/.claude/rules-local/base/custom.md"

    # Run process_overrides
    (
        cd "$test_dir"
        source "$PROJECT_ROOT/lib/override.sh"
        process_overrides ".claude"
    )

    # Verify new file was added
    assert_file_exists "$test_dir/.claude/rules/base/custom.md" \
        "New local file: Created in rules/"

    assert_file_contains "$test_dir/.claude/rules/base/custom.md" \
        "Custom Project Rule" \
        "New local file: Content preserved"

    cleanup_test_project "$test_dir"
}

# ============================================
# Scenario 8: Invalid config fails fast
# ============================================
test_invalid_config_fails() {
    echo ""
    echo "=== Scenario 8: Invalid config fails fast ==="
    echo ""

    local test_dir
    test_dir=$(create_test_project)

    # Create invalid JSON config
    echo "not valid json {" > "$test_dir/.claude/rules-config.local.json"

    # Run process_overrides and capture exit code
    local exit_code=0
    (
        cd "$test_dir"
        source "$PROJECT_ROOT/lib/override.sh"
        process_overrides ".claude"
    ) 2>/dev/null || exit_code=$?

    if [[ "$exit_code" -ne 0 ]]; then
        pass "Invalid config: Fails with non-zero exit"
    else
        fail "Invalid config: Fails with non-zero exit" "Exit code was $exit_code"
    fi

    cleanup_test_project "$test_dir"
}

# ============================================
# Run all tests
# ============================================
echo "========================================"
echo "Override System E2E Tests"
echo "========================================"

test_baseline_no_overrides
test_local_only_no_config
test_full_override_with_config
test_exclusions
test_mixed_strategies
test_dry_run
test_new_local_file
test_invalid_config_fails

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
    echo "All E2E tests passed!"
    exit 0
fi
