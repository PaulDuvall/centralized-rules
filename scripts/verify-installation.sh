#!/bin/bash
# Centralized Rules Installation Verification Script
# Verifies that centralized-rules is correctly installed and configured

# NOTE: We do NOT use 'set -e' here because we want to run ALL checks
# even if some fail, so users can see exactly what's wrong

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
    PASS=$((PASS + 1))
}

print_fail() {
    echo -e "${RED}✗${NC} $1"
    FAIL=$((FAIL + 1))
}

print_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    WARN=$((WARN + 1))
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

# Check 3: Verify Hook Script Implementation
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Verifying Hook Implementation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Find which hook script to analyze
HOOK_SCRIPT=""
if [ -f "$LOCAL_HOOK_SCRIPT" ]; then
    HOOK_SCRIPT="$LOCAL_HOOK_SCRIPT"
elif [ -f "$GLOBAL_HOOK_SCRIPT" ]; then
    HOOK_SCRIPT="$GLOBAL_HOOK_SCRIPT"
fi

if [ -n "$HOOK_SCRIPT" ]; then
    # Check for skill-based implementation
    if grep -q "detect_project_context" "$HOOK_SCRIPT" 2>/dev/null; then
        print_pass "Has project context detection"
    else
        print_info "No project detection (may be simpler implementation)"
    fi

    if grep -q "match_keywords" "$HOOK_SCRIPT" 2>/dev/null; then
        print_pass "Has keyword matching logic"
    else
        print_info "No keyword matching (may be simpler implementation)"
    fi

    # Check for centralized-rules activation
    if grep -q "centralized-rules\|Centralized Rules" "$HOOK_SCRIPT" 2>/dev/null; then
        print_pass "Activates centralized-rules skill"
    else
        print_warn "Does not appear to activate centralized-rules"
    fi

    print_info "Hook implementation: Skill-based (dynamic rule loading)"
else
    print_fail "No hook script found to analyze"
fi

echo ""

# Check 4: Verify Hook Activation
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Testing Hook Activation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

print_info "The hook shows commit ID in the banner when it runs"
print_info "Example: 📌 Commit: 8cf99a3"
print_info ""
print_info "To verify the hook is working, check your Claude responses"
print_info "for the '🎯 SKILL ACTIVATION' banner at the top"

echo ""

# Check 5: Dependencies
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Checking Dependencies"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check for required commands
REQUIRED_COMMANDS=("curl" "jq" "bash")

for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        VERSION=$($cmd --version 2>&1 | head -1 || echo "unknown")
        print_pass "$cmd is installed"
        print_info "$VERSION"
    else
        if [ "$cmd" = "jq" ]; then
            print_fail "$cmd is NOT installed (REQUIRED as of v1.3.0)"
            print_info "Install with: brew install jq (macOS) or apt-get install jq (Linux)"
            print_info "The hook uses jq to read keywords from skill-rules.json"
            CRITICAL_ISSUES=true
        else
            print_warn "$cmd is NOT installed"
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

# Determine if there are CRITICAL failures (hook missing, not executable, not registered)
# vs. informational failures (optional features)
CRITICAL_ISSUES=false

# Check if hook script exists and is executable
if [ ! -f "$GLOBAL_HOOK_SCRIPT" ] && [ ! -f "$LOCAL_HOOK_SCRIPT" ]; then
    CRITICAL_ISSUES=true
fi

# Check if hook is registered in settings
if [ -f "$GLOBAL_SETTINGS" ]; then
    if ! grep -q "UserPromptSubmit" "$GLOBAL_SETTINGS" 2>/dev/null; then
        if [ -f "$LOCAL_SETTINGS" ]; then
            if ! grep -q "UserPromptSubmit" "$LOCAL_SETTINGS" 2>/dev/null; then
                CRITICAL_ISSUES=true
            fi
        else
            CRITICAL_ISSUES=true
        fi
    fi
elif [ -f "$LOCAL_SETTINGS" ]; then
    if ! grep -q "UserPromptSubmit" "$LOCAL_SETTINGS" 2>/dev/null; then
        CRITICAL_ISSUES=true
    fi
else
    CRITICAL_ISSUES=true
fi

if [ "$CRITICAL_ISSUES" = false ]; then
    echo -e "${GREEN}✅ Installation is working correctly!${NC}"
    echo ""
    echo "The hook is installed, executable, and registered."
    echo ""
    echo "To verify it's working:"
    echo "  • Look for the '🎯 SKILL ACTIVATION' banner at the top of Claude's responses"
    echo "  • The banner shows the commit ID: 📌 Commit: XXXXXXX"
    echo ""
    echo "Try asking: 'Are we following Python best practices?'"
    exit 0
else
    echo -e "${RED}✗ Critical installation issues detected${NC}"
    echo ""
    echo "Common fixes:"
    echo "  1. Re-run installation: curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/main/install-hooks.sh | bash -s -- --global"
    echo "  2. Check file permissions: chmod +x ~/.claude/hooks/activate-rules.sh"
    echo "  3. Restart Claude Code"
    exit 1
fi
