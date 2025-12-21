#!/bin/bash
# Centralized Rules Installation Verification Script
# Verifies that centralized-rules is correctly installed and configured

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASS=0
FAIL=0
WARN=0

echo "═══════════════════════════════════════════════════════"
echo "🔍 Centralized Rules Installation Verification"
echo "═══════════════════════════════════════════════════════"
echo ""

# Function to print status
print_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASS++))
}

print_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAIL++))
}

print_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARN++))
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check 1: Global Installation
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Checking Global Installation (~/.claude/)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

GLOBAL_HOOK_SCRIPT="$HOME/.claude/hooks/activate-rules.sh"
GLOBAL_SETTINGS="$HOME/.claude/settings.json"

if [ -f "$GLOBAL_HOOK_SCRIPT" ]; then
    print_pass "Global hook script exists: $GLOBAL_HOOK_SCRIPT"

    # Check if it's executable
    if [ -x "$GLOBAL_HOOK_SCRIPT" ]; then
        print_pass "Hook script is executable"
    else
        print_fail "Hook script is not executable"
        print_info "Fix with: chmod +x $GLOBAL_HOOK_SCRIPT"
    fi
else
    print_fail "Global hook script not found"
    print_info "Run: curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/main/install-hooks.sh | bash -s -- --global"
fi

if [ -f "$GLOBAL_SETTINGS" ]; then
    print_pass "Global settings file exists: $GLOBAL_SETTINGS"

    # Check if hook is registered
    if grep -q "UserPromptSubmit" "$GLOBAL_SETTINGS" 2>/dev/null; then
        print_pass "UserPromptSubmit hook is registered"

        # Extract and display the hook command
        HOOK_CMD=$(jq -r '.hooks.UserPromptSubmit[0]' "$GLOBAL_SETTINGS" 2>/dev/null || echo "")
        if [ -n "$HOOK_CMD" ] && [ "$HOOK_CMD" != "null" ]; then
            print_info "Hook command: $HOOK_CMD"
        fi
    else
        print_fail "UserPromptSubmit hook not registered in settings.json"
    fi
else
    print_warn "Global settings file not found (may not be an issue)"
fi

echo ""

# Check 2: Local Installation
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Checking Local Installation (.claude/)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

LOCAL_HOOK_SCRIPT=".claude/hooks/activate-rules.sh"
LOCAL_SETTINGS=".claude/settings.json"

if [ -f "$LOCAL_HOOK_SCRIPT" ]; then
    print_pass "Local hook script exists: $LOCAL_HOOK_SCRIPT"

    if [ -x "$LOCAL_HOOK_SCRIPT" ]; then
        print_pass "Hook script is executable"
    else
        print_fail "Hook script is not executable"
        print_info "Fix with: chmod +x $LOCAL_HOOK_SCRIPT"
    fi
else
    print_info "No local hook script (using global is fine)"
fi

if [ -f "$LOCAL_SETTINGS" ]; then
    print_pass "Local settings file exists: $LOCAL_SETTINGS"

    if grep -q "UserPromptSubmit" "$LOCAL_SETTINGS" 2>/dev/null; then
        print_pass "UserPromptSubmit hook is registered locally"
    fi
else
    print_info "No local settings file (using global is fine)"
fi

echo ""

# Check 3: Verify Hook Script Contents
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Analyzing Hook Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Find which hook script to analyze
HOOK_SCRIPT=""
if [ -f "$LOCAL_HOOK_SCRIPT" ]; then
    HOOK_SCRIPT="$LOCAL_HOOK_SCRIPT"
elif [ -f "$GLOBAL_HOOK_SCRIPT" ]; then
    HOOK_SCRIPT="$GLOBAL_HOOK_SCRIPT"
fi

if [ -n "$HOOK_SCRIPT" ]; then
    # Extract repository URL
    REPO_URL=$(grep -o 'RULES_REPO="[^"]*"' "$HOOK_SCRIPT" | cut -d'"' -f2 || echo "")
    if [ -n "$REPO_URL" ]; then
        print_pass "Repository URL: $REPO_URL"
    else
        print_fail "Could not find RULES_REPO in hook script"
    fi

    # Extract commit ID
    COMMIT_ID=$(grep -o 'COMMIT="[^"]*"' "$HOOK_SCRIPT" | cut -d'"' -f2 || echo "")
    if [ -n "$COMMIT_ID" ]; then
        print_pass "Commit ID: $COMMIT_ID"

        # Verify commit exists in repository
        print_info "Verifying commit exists in repository..."
        if curl -fsSL "https://api.github.com/repos/paulduvall/centralized-rules/commits/$COMMIT_ID" >/dev/null 2>&1; then
            print_pass "Commit $COMMIT_ID exists in repository"
        else
            print_fail "Commit $COMMIT_ID NOT FOUND in repository!"
            print_info "Latest commit: https://github.com/paulduvall/centralized-rules/commits/main"
        fi
    else
        print_fail "Could not find COMMIT in hook script"
    fi

    # Check for skill-rules.json reference
    if grep -q "skill-rules.json" "$HOOK_SCRIPT"; then
        print_pass "References skill-rules.json for keyword detection"
    else
        print_warn "Does not reference skill-rules.json (may be older version)"
    fi
else
    print_fail "No hook script found to analyze"
fi

echo ""

# Check 4: Test Network Access
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Testing Network Access to Rules Repository"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -n "$REPO_URL" ] && [ -n "$COMMIT_ID" ]; then
    # Test fetching skill-rules.json
    SKILL_RULES_URL="${REPO_URL}/raw/${COMMIT_ID}/.claude/skills/skill-rules.json"
    print_info "Testing: $SKILL_RULES_URL"

    if SKILL_RULES_CONTENT=$(curl -fsSL "$SKILL_RULES_URL" 2>/dev/null); then
        print_pass "Successfully fetched skill-rules.json"

        # Validate JSON
        if echo "$SKILL_RULES_CONTENT" | jq empty 2>/dev/null; then
            print_pass "skill-rules.json is valid JSON"

            # Extract version
            VERSION=$(echo "$SKILL_RULES_CONTENT" | jq -r '.version' 2>/dev/null)
            if [ -n "$VERSION" ] && [ "$VERSION" != "null" ]; then
                print_pass "Version: $VERSION"
            fi

            # Count available rules
            RULE_COUNT=$(echo "$SKILL_RULES_CONTENT" | jq '[.. | .rules? // empty] | add | unique | length' 2>/dev/null || echo "0")
            if [ "$RULE_COUNT" -gt 0 ]; then
                print_pass "Available rule categories: $RULE_COUNT"
            fi
        else
            print_fail "skill-rules.json is not valid JSON"
        fi
    else
        print_fail "Could not fetch skill-rules.json from repository"
        print_info "Check your internet connection and repository URL"
    fi

    # Test fetching a sample rule
    SAMPLE_RULE_URL="${REPO_URL}/raw/${COMMIT_ID}/base/code-quality.md"
    print_info "Testing sample rule: base/code-quality.md"

    if curl -fsSL "$SAMPLE_RULE_URL" >/dev/null 2>&1; then
        print_pass "Successfully fetched sample rule file"
    else
        print_fail "Could not fetch sample rule file"
    fi
else
    print_warn "Skipping network tests (repository URL or commit ID not found)"
fi

echo ""

# Check 5: Keyword Detection Examples
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Keyword Detection Examples"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -n "$SKILL_RULES_CONTENT" ]; then
    print_info "Checking configured keywords..."
    echo ""

    # Show some example keywords
    echo "  📌 Testing Keywords:"
    KEYWORDS=("vercel" "react" "python" "security" "test")

    for keyword in "${KEYWORDS[@]}"; do
        # Check if keyword exists in skill-rules.json
        if echo "$SKILL_RULES_CONTENT" | jq -e --arg kw "$keyword" '[.. | .keywords? // empty] | flatten | any(. == $kw)' >/dev/null 2>&1; then
            echo -e "     ${GREEN}✓${NC} '$keyword' - will trigger rules"
        else
            echo -e "     ${YELLOW}○${NC} '$keyword' - not configured"
        fi
    done
else
    print_warn "Cannot test keywords (skill-rules.json not loaded)"
fi

echo ""

# Check 6: Dependencies
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. Checking Dependencies"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check for required commands
REQUIRED_COMMANDS=("curl" "jq" "bash")

for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        VERSION=$($cmd --version 2>&1 | head -1 || echo "unknown")
        print_pass "$cmd is installed"
        print_info "$VERSION"
    else
        print_fail "$cmd is NOT installed (required)"

        if [ "$cmd" = "jq" ]; then
            print_info "Install with: brew install jq (macOS) or apt-get install jq (Linux)"
        fi
    fi
done

echo ""

# Final Summary
echo "═══════════════════════════════════════════════════════"
echo "📊 Verification Summary"
echo "═══════════════════════════════════════════════════════"
echo -e "${GREEN}✓ Passed:${NC} $PASS"
echo -e "${YELLOW}⚠ Warnings:${NC} $WARN"
echo -e "${RED}✗ Failed:${NC} $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ Installation appears to be working correctly!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Restart Claude Code"
    echo "  2. Try asking: 'Are we following Python best practices?'"
    echo "  3. Look for the hook banner in the response"
    exit 0
else
    echo -e "${RED}✗ Installation has issues that need to be fixed${NC}"
    echo ""
    echo "Common fixes:"
    echo "  1. Re-run installation: curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/main/install-hooks.sh | bash -s -- --global"
    echo "  2. Check file permissions: chmod +x ~/.claude/hooks/activate-rules.sh"
    echo "  3. Restart Claude Code"
    exit 1
fi
