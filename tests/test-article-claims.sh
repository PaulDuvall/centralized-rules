#!/usr/bin/env bash
#
# test-article-claims.sh - Verify all claims made in the blog article
# "Sharing AI Development Rules Across Your Organization"
#
# This test reads the article and verifies that all documented features work.
# Article location: docs/articles/sharing-ai-development-rules-across-your-organization.md
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ARTICLE_PATH="$PROJECT_ROOT/docs/articles/sharing-ai-development-rules-across-your-organization.md"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Verify article exists before running tests
if [[ ! -f "$ARTICLE_PATH" ]]; then
    echo "ERROR: Article not found at: $ARTICLE_PATH"
    echo "Tests verify claims from this article. Please ensure it exists."
    exit 1
fi

# Helper to check if article contains a claim
article_claims() {
    local pattern="$1"
    grep -q "$pattern" "$ARTICLE_PATH"
}

pass() {
    echo "✓ $1"
    ((TESTS_PASSED++)) || true
}

fail() {
    echo "✗ $1"
    ((TESTS_FAILED++)) || true
}

# Run a test in a temporary directory
# Usage: run_test "description" <<'TEST'
#   commands here
# TEST
run_test() {
    local desc="$1"
    local test_script
    test_script=$(cat)

    local tmp_dir
    tmp_dir=$(mktemp -d)

    if (
        cd "$tmp_dir"
        # Source libs fresh
        _LIB_DETECTION_LOADED=""
        _LIB_OVERRIDE_LOADED=""
        source "$PROJECT_ROOT/lib/detection.sh"
        source "$PROJECT_ROOT/lib/override.sh"
        eval "$test_script"
    ); then
        pass "$desc"
    else
        fail "$desc"
    fi

    rm -rf "$tmp_dir"
}

echo ""
echo "=== Verifying Article Claims ==="
echo ""
echo "Article: $ARTICLE_PATH"
echo ""

# Verify article documents the features we're testing
if article_claims "pyproject.toml"; then
    pass "Article documents pyproject.toml detection"
else
    fail "Article should document pyproject.toml detection"
fi

if article_claims "package.json"; then
    pass "Article documents package.json detection"
else
    fail "Article should document package.json detection"
fi

if article_claims "go.mod"; then
    pass "Article documents go.mod detection"
else
    fail "Article should document go.mod detection"
fi

if article_claims "vercel.json"; then
    pass "Article documents vercel.json detection"
else
    fail "Article should document vercel.json detection"
fi

if article_claims '\.claude/rules-local'; then
    pass "Article documents local override directory"
else
    fail "Article should document .claude/rules-local"
fi

if article_claims "merge_strategy"; then
    pass "Article documents merge strategies"
else
    fail "Article should document merge strategies"
fi

if article_claims '"extend"'; then
    pass "Article documents extend strategy"
else
    fail "Article should document extend strategy"
fi

if article_claims '"replace"'; then
    pass "Article documents replace strategy"
else
    fail "Article should document replace strategy"
fi

if article_claims '"exclude"'; then
    pass "Article documents exclude functionality"
else
    fail "Article should document exclude functionality"
fi

if article_claims '\-\-local'; then
    pass "Article documents --local flag"
else
    fail "Article should document --local flag"
fi

if article_claims '\-\-edge'; then
    pass "Article documents --edge flag"
else
    fail "Article should document --edge flag"
fi

if article_claims '\-\-version'; then
    pass "Article documents --version flag"
else
    fail "Article should document --version flag"
fi

if article_claims '\-\-dry-run'; then
    pass "Article documents --dry-run flag"
else
    fail "Article should document --dry-run flag"
fi

if article_claims 'skill-rules.json'; then
    pass "Article documents skill-rules.json customization"
else
    fail "Article should document skill-rules.json"
fi

if article_claims 'RULES_REPO'; then
    pass "Article documents RULES_REPO env var"
else
    fail "Article should document RULES_REPO env var"
fi

echo ""
echo "=== Language Detection ==="
echo "(Verifying: pyproject.toml → Python, package.json → JS/TS, go.mod → Go)"
echo ""

run_test "pyproject.toml → Python detected" <<'TEST'
touch pyproject.toml
[[ "$(detect_language)" == *python* ]]
TEST

run_test "setup.py → Python detected" <<'TEST'
touch setup.py
[[ "$(detect_language)" == *python* ]]
TEST

run_test "requirements.txt → Python detected" <<'TEST'
touch requirements.txt
[[ "$(detect_language)" == *python* ]]
TEST

run_test "package.json (no TS) → JavaScript detected" <<'TEST'
echo '{"name": "test"}' > package.json
[[ "$(detect_language)" == *javascript* ]]
TEST

run_test "package.json with typescript → TypeScript detected" <<'TEST'
echo '{"devDependencies": {"typescript": "^5.0.0"}}' > package.json
[[ "$(detect_language)" == *typescript* ]]
TEST

run_test "go.mod → Go detected" <<'TEST'
echo 'module test' > go.mod
[[ "$(detect_language)" == *go* ]]
TEST

run_test "pom.xml → Java detected" <<'TEST'
touch pom.xml
[[ "$(detect_language)" == *java* ]]
TEST

run_test "build.gradle → Java detected" <<'TEST'
touch build.gradle
[[ "$(detect_language)" == *java* ]]
TEST

run_test "*.csproj → C# detected" <<'TEST'
touch test.csproj
[[ "$(detect_language)" == *csharp* ]]
TEST

run_test "Gemfile → Ruby detected" <<'TEST'
touch Gemfile
[[ "$(detect_language)" == *ruby* ]]
TEST

run_test "Cargo.toml → Rust detected" <<'TEST'
touch Cargo.toml
[[ "$(detect_language)" == *rust* ]]
TEST

echo ""
echo "=== Framework Detection ==="
echo "(Verifying: fastapi/react in dependencies → Framework detected)"
echo ""

run_test "fastapi in requirements.txt → FastAPI detected" <<'TEST'
echo "fastapi==0.100.0" > requirements.txt
[[ "$(detect_frameworks)" == *fastapi* ]]
TEST

run_test "django in requirements.txt → Django detected" <<'TEST'
echo "Django==4.2" > requirements.txt
[[ "$(detect_frameworks)" == *django* ]]
TEST

run_test "flask in requirements.txt → Flask detected" <<'TEST'
echo "flask==2.3.0" > requirements.txt
[[ "$(detect_frameworks)" == *flask* ]]
TEST

run_test "react in package.json → React detected" <<'TEST'
echo '{"dependencies": {"react": "^18.0.0"}}' > package.json
[[ "$(detect_frameworks)" == *react* ]]
TEST

run_test "next in package.json → Next.js detected" <<'TEST'
echo '{"dependencies": {"next": "^14.0.0"}}' > package.json
[[ "$(detect_frameworks)" == *nextjs* ]]
TEST

run_test "vue in package.json → Vue detected" <<'TEST'
echo '{"dependencies": {"vue": "^3.0.0"}}' > package.json
[[ "$(detect_frameworks)" == *vue* ]]
TEST

run_test "express in package.json → Express detected" <<'TEST'
echo '{"dependencies": {"express": "^4.18.0"}}' > package.json
[[ "$(detect_frameworks)" == *express* ]]
TEST

run_test "gin-gonic/gin in go.mod → Gin detected" <<'TEST'
cat > go.mod <<EOF
module test
require github.com/gin-gonic/gin v1.9.0
EOF
[[ "$(detect_frameworks)" == *gin* ]]
TEST

run_test "gofiber/fiber in go.mod → Fiber detected" <<'TEST'
cat > go.mod <<EOF
module test
require github.com/gofiber/fiber/v2 v2.50.0
EOF
[[ "$(detect_frameworks)" == *fiber* ]]
TEST

echo ""
echo "=== Cloud Provider Detection ==="
echo "(Verifying: vercel.json → Vercel detected)"
echo ""

run_test "vercel.json → Vercel detected" <<'TEST'
echo '{}' > vercel.json
[[ "$(detect_cloud_providers)" == *vercel* ]]
TEST

run_test ".vercel/ → Vercel detected" <<'TEST'
mkdir .vercel
[[ "$(detect_cloud_providers)" == *vercel* ]]
TEST

run_test "serverless.yml → AWS detected" <<'TEST'
touch serverless.yml
[[ "$(detect_cloud_providers)" == *aws* ]]
TEST

run_test "azure-pipelines.yml → Azure detected" <<'TEST'
touch azure-pipelines.yml
[[ "$(detect_cloud_providers)" == *azure* ]]
TEST

run_test "app.yaml → GCP detected" <<'TEST'
touch app.yaml
[[ "$(detect_cloud_providers)" == *gcp* ]]
TEST

echo ""
echo "=== Local Override Detection ==="
echo ""

run_test "Detects .claude/rules-local/ directory" <<'TEST'
mkdir -p .claude/rules-local/base
[[ "$(detect_local_overrides ".claude")" == "true" ]]
TEST

run_test "Returns false when rules-local missing" <<'TEST'
mkdir -p .claude
[[ "$(detect_local_overrides ".claude")" == "false" ]]
TEST

echo ""
echo "=== Merge Strategies ==="
echo ""

run_test "extend: central content first, local appended" <<'TEST'
result=$(merge_rule_content "# Central" "# Local" "extend")
first_line=$(echo "$result" | head -1)
[[ "$first_line" == "# Central" ]] && [[ "$result" == *"# Local"* ]]
TEST

run_test "replace: only local content" <<'TEST'
result=$(merge_rule_content "# Central" "# Local" "replace")
[[ "$result" == "# Local" ]]
TEST

run_test "prepend: local content first" <<'TEST'
result=$(merge_rule_content "# Central" "# Local" "prepend")
first_line=$(echo "$result" | head -1)
[[ "$first_line" == "# Local" ]] && [[ "$result" == *"# Central"* ]]
TEST

run_test "Default strategy is extend" <<'TEST'
[[ "$(get_merge_strategy "base/test.md" "")" == "extend" ]]
TEST

echo ""
echo "=== Config-Based Strategy Overrides ==="
echo ""

run_test "Specific override: base/security.md → replace" <<'TEST'
config='{"merge_strategy": "extend", "overrides": {"base/security.md": "replace"}}'
[[ "$(get_merge_strategy "base/security.md" "$config")" == "replace" ]]
TEST

run_test "Glob override: base/* → prepend" <<'TEST'
config='{"merge_strategy": "extend", "overrides": {"base/*": "prepend"}}'
[[ "$(get_merge_strategy "base/testing.md" "$config")" == "prepend" ]]
TEST

echo ""
echo "=== Exclude Functionality ==="
echo ""

run_test "Exact exclusion matches" <<'TEST'
config='{"exclude": ["base/chaos-engineering.md"]}'
[[ "$(should_exclude_rule "base/chaos-engineering.md" "$config")" == "true" ]]
TEST

run_test "Glob exclusion matches" <<'TEST'
config='{"exclude": ["base/ai-*"]}'
[[ "$(should_exclude_rule "base/ai-ethics.md" "$config")" == "true" ]]
TEST

run_test "Non-matching files not excluded" <<'TEST'
config='{"exclude": ["base/chaos-engineering.md"]}'
[[ "$(should_exclude_rule "base/security.md" "$config")" == "false" ]]
TEST

echo ""
echo "=== Config Validation ==="
echo ""

run_test "Valid config passes validation" <<'TEST'
config='{"merge_strategy": "extend", "exclude": []}'
validate_override_config "$config"
TEST

run_test "Invalid strategy fails validation" <<'TEST'
config='{"merge_strategy": "invalid_strategy"}'
! validate_override_config "$config"
TEST

run_test "Invalid JSON fails validation" <<'TEST'
config='not valid json'
! validate_override_config "$config"
TEST

echo ""
echo "=== Script Files Exist and Have Required Options ==="
echo ""

if [[ -f "$PROJECT_ROOT/install-hooks.sh" ]]; then
    pass "install-hooks.sh exists"
else
    fail "install-hooks.sh exists"
fi

if grep -q "\-\-local" "$PROJECT_ROOT/install-hooks.sh"; then
    pass "install-hooks.sh supports --local"
else
    fail "install-hooks.sh supports --local"
fi

if grep -q "\-\-edge" "$PROJECT_ROOT/install-hooks.sh"; then
    pass "install-hooks.sh supports --edge"
else
    fail "install-hooks.sh supports --edge"
fi

if grep -q "\-\-version" "$PROJECT_ROOT/install-hooks.sh"; then
    pass "install-hooks.sh supports --version"
else
    fail "install-hooks.sh supports --version"
fi

if [[ -f "$PROJECT_ROOT/sync-ai-rules.sh" ]]; then
    pass "sync-ai-rules.sh exists"
else
    fail "sync-ai-rules.sh exists"
fi

if grep -q "\-\-tool" "$PROJECT_ROOT/sync-ai-rules.sh"; then
    pass "sync-ai-rules.sh supports --tool"
else
    fail "sync-ai-rules.sh supports --tool"
fi

if grep -q "\-\-dry-run" "$PROJECT_ROOT/sync-ai-rules.sh"; then
    pass "sync-ai-rules.sh supports --dry-run"
else
    fail "sync-ai-rules.sh supports --dry-run"
fi

if grep -q "\-\-verbose" "$PROJECT_ROOT/sync-ai-rules.sh"; then
    pass "sync-ai-rules.sh supports --verbose"
else
    fail "sync-ai-rules.sh supports --verbose"
fi

echo ""
echo "=== Environment Variable Support ==="
echo ""

if grep -q "AI_RULES_REPO\|RULES_REPO" "$PROJECT_ROOT/sync-ai-rules.sh"; then
    pass "sync-ai-rules.sh supports RULES_REPO env var"
else
    fail "sync-ai-rules.sh supports RULES_REPO env var"
fi

echo ""
echo "=== Keyword Customization ==="
echo ""

if [[ -f "$PROJECT_ROOT/.claude/skills/skill-rules.json" ]]; then
    pass "skill-rules.json exists"
else
    fail "skill-rules.json exists"
fi

if grep -q "keywordMappings" "$PROJECT_ROOT/.claude/skills/skill-rules.json"; then
    pass "skill-rules.json has keywordMappings"
else
    fail "skill-rules.json has keywordMappings"
fi

if grep -q "languages" "$PROJECT_ROOT/.claude/skills/skill-rules.json"; then
    pass "skill-rules.json has languages section"
else
    fail "skill-rules.json has languages section"
fi

echo ""
echo "=== End-to-End Override Processing ==="
echo ""

run_test "E2E extend: central preserved, local added" <<'TEST'
mkdir -p .claude/rules/base .claude/rules-local/base
echo "# Central Security Rule" > .claude/rules/base/security.md
echo "# Additional Security" > .claude/rules-local/base/security.md
process_overrides ".claude"
result=$(cat .claude/rules/base/security.md)
[[ "$result" == *"# Central Security Rule"* ]] && [[ "$result" == *"# Additional Security"* ]]
TEST

run_test "E2E replace: local replaces central" <<'TEST'
mkdir -p .claude/rules/base .claude/rules-local/base
echo "# Central" > .claude/rules/base/security.md
echo "# Replacement" > .claude/rules-local/base/security.md
echo '{"merge_strategy": "replace"}' > .claude/rules-config.local.json
process_overrides ".claude"
result=$(cat .claude/rules/base/security.md)
[[ "$result" == "# Replacement" ]]
TEST

run_test "E2E exclusion: excluded file unchanged" <<'TEST'
mkdir -p .claude/rules/base .claude/rules-local/base
echo "# Central Chaos" > .claude/rules/base/chaos.md
echo "# Central Security" > .claude/rules/base/security.md
echo "# Local Chaos" > .claude/rules-local/base/chaos.md
echo "# Local Security" > .claude/rules-local/base/security.md
echo '{"exclude": ["base/chaos.md"]}' > .claude/rules-config.local.json
process_overrides ".claude"
chaos=$(cat .claude/rules/base/chaos.md)
security=$(cat .claude/rules/base/security.md)
[[ "$chaos" == "# Central Chaos" ]] && [[ "$security" == *"# Local Security"* ]]
TEST

run_test "E2E specific file override with different strategy" <<'TEST'
mkdir -p .claude/rules/base .claude/rules-local/base
echo "# Central Security" > .claude/rules/base/security.md
echo "# Central Testing" > .claude/rules/base/testing.md
echo "# Local Security" > .claude/rules-local/base/security.md
echo "# Local Testing" > .claude/rules-local/base/testing.md
cat > .claude/rules-config.local.json <<EOF
{"merge_strategy": "extend", "overrides": {"base/security.md": "replace"}}
EOF
process_overrides ".claude"
security=$(cat .claude/rules/base/security.md)
testing=$(cat .claude/rules/base/testing.md)
[[ "$security" == "# Local Security" ]] && [[ "$testing" == *"# Central Testing"* ]] && [[ "$testing" == *"# Local Testing"* ]]
TEST

echo ""
echo "=== Multi-language Project Detection ==="
echo ""

run_test "Multi-language: Python + TypeScript detected" <<'TEST'
echo '{"devDependencies": {"typescript": "^5.0.0"}}' > package.json
echo "fastapi==0.100.0" > requirements.txt
langs=$(detect_language)
frameworks=$(detect_frameworks)
[[ "$langs" == *typescript* ]] && [[ "$langs" == *python* ]] && [[ "$frameworks" == *fastapi* ]]
TEST

echo ""
echo "========================================"
echo "Article Claims Verification Results"
echo "========================================"
echo "Article: docs/articles/sharing-ai-development-rules-across-your-organization.md"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo "========================================"

if [[ $TESTS_FAILED -gt 0 ]]; then
    echo ""
    echo "Some article claims could not be verified!"
    echo "Either the implementation is broken, or the article"
    echo "documents features that don't exist yet."
    exit 1
else
    echo ""
    echo "All article claims verified successfully!"
    echo "The article accurately documents working features."
    exit 0
fi
