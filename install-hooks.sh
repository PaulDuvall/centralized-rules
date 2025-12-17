#!/usr/bin/env bash
#
# Centralized Rules - Automated Hook Installation
#
# This script automatically installs and configures the UserPromptSubmit hook
# for Claude Code CLI. It handles all setup automatically with zero manual steps.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/main/install-hooks.sh | bash
#
# Or locally:
#   cd centralized-rules
#   ./install-hooks.sh [--global|--local]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
info() { echo -e "${BLUE}ℹ${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warning() { echo -e "${YELLOW}⚠${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*"; }

# Detect installation mode
INSTALL_MODE="local"  # Default to local project installation
if [[ "$1" == "--global" ]]; then
    INSTALL_MODE="global"
elif [[ "$1" == "--local" ]]; then
    INSTALL_MODE="local"
fi

# Detect environment
detect_environment() {
    info "Detecting environment..."

    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        if [[ "$INSTALL_MODE" == "local" ]]; then
            error "Not in a git repository. Use --global for global installation."
            exit 1
        fi
    fi

    # Detect Claude Code CLI vs Desktop (for future use)
    if command -v claude-code >/dev/null 2>&1; then
        success "Detected: Claude Code CLI"
    elif [[ -d "/Applications/Claude.app" ]] || [[ -d "$HOME/Applications/Claude.app" ]]; then
        success "Detected: Claude Desktop"
        warning "Note: This hook system is designed for Claude Code CLI"
    else
        warning "Could not detect Claude installation type (assuming CLI)"
    fi
}

# Find the centralized-rules repository
find_rules_repo() {
    # If we're already in the centralized-rules repo
    if [[ -f ".claude/hooks/activate-rules.sh" ]]; then
        RULES_REPO_PATH="$(pwd)"
        success "Using current directory: $RULES_REPO_PATH"
        return 0
    fi

    # Common locations
    for path in \
        "$HOME/Code/centralized-rules" \
        "$HOME/centralized-rules" \
        "$HOME/src/centralized-rules" \
        "$HOME/projects/centralized-rules"; do
        if [[ -d "$path/.claude/hooks" ]]; then
            RULES_REPO_PATH="$path"
            success "Found centralized-rules at: $RULES_REPO_PATH"
            return 0
        fi
    done

    error "Could not find centralized-rules repository"
    error "Please run this script from the centralized-rules directory"
    error "Or install it first: git clone https://github.com/paulduvall/centralized-rules"
    exit 1
}

# Install hooks for local project
install_local() {
    info "Installing hooks for current project..."

    # Create .claude directories
    mkdir -p .claude/hooks
    mkdir -p .claude/skills

    # Copy hook script
    cp "$RULES_REPO_PATH/.claude/hooks/activate-rules.sh" .claude/hooks/
    chmod +x .claude/hooks/activate-rules.sh
    success "Copied hook script"

    # Copy skill rules mapping
    cp "$RULES_REPO_PATH/.claude/skills/skill-rules.json" .claude/skills/
    success "Copied skill rules mapping"

    # Create settings.json if it doesn't exist, or merge if it does
    if [[ -f .claude/settings.json ]]; then
        info "Merging with existing .claude/settings.json"
        # Backup existing settings
        cp .claude/settings.json .claude/settings.json.backup
        # Use jq to merge if available, otherwise warn
        if command -v jq >/dev/null 2>&1; then
            jq -s '.[0] * .[1]' .claude/settings.json.backup - > .claude/settings.json <<'EOF'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/activate-rules.sh",
            "description": "Activate centralized-rules skill"
          }
        ]
      }
    ]
  }
}
EOF
            success "Merged hook configuration"
        else
            warning "jq not found - please manually add hook configuration"
            cat <<'EOF'
Add this to your .claude/settings.json:

{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/activate-rules.sh",
            "description": "Activate centralized-rules skill"
          }
        ]
      }
    ]
  }
}
EOF
        fi
    else
        cat > .claude/settings.json <<'EOF'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/activate-rules.sh",
            "description": "Activate centralized-rules skill"
          }
        ]
      }
    ]
  }
}
EOF
        success "Created .claude/settings.json"
    fi

    success "Local installation complete!"
    echo ""
    info "Next steps:"
    echo "  1. Restart Claude Code in this directory"
    echo "  2. Run: /hooks"
    echo "  3. Verify the UserPromptSubmit hook is listed"
    echo "  4. Test with: 'Write a function to process data'"
}

# Install hooks globally
install_global() {
    info "Installing hooks globally for all projects..."

    # Create global .claude directory
    mkdir -p "$HOME/.claude/hooks"
    mkdir -p "$HOME/.claude/skills"

    # Copy hook script
    cp "$RULES_REPO_PATH/.claude/hooks/activate-rules.sh" "$HOME/.claude/hooks/"
    chmod +x "$HOME/.claude/hooks/activate-rules.sh"
    success "Copied hook script to ~/.claude/hooks/"

    # Copy skill rules mapping
    cp "$RULES_REPO_PATH/.claude/skills/skill-rules.json" "$HOME/.claude/skills/"
    success "Copied skill rules mapping to ~/.claude/skills/"

    # Update global settings
    local settings_file="$HOME/.claude/settings.json"

    if [[ -f "$settings_file" ]]; then
        info "Merging with existing ~/.claude/settings.json"
        cp "$settings_file" "$settings_file.backup"

        if command -v jq >/dev/null 2>&1; then
            jq -s '.[0] * .[1]' "$settings_file.backup" - > "$settings_file" <<'EOF'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/activate-rules.sh",
            "description": "Activate centralized-rules skill"
          }
        ]
      }
    ]
  }
}
EOF
            success "Merged hook configuration"
        else
            warning "jq not found - please manually add hook configuration"
        fi
    else
        cat > "$settings_file" <<'EOF'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/activate-rules.sh",
            "description": "Activate centralized-rules skill"
          }
        ]
      }
    ]
  }
}
EOF
        success "Created ~/.claude/settings.json"
    fi

    success "Global installation complete!"
    echo ""
    info "Next steps:"
    echo "  1. Restart Claude Code"
    echo "  2. Run: /hooks"
    echo "  3. Verify the UserPromptSubmit hook is listed"
    echo "  4. The hook will work in ALL your projects"
}

# Test the installation
test_installation() {
    info "Testing installation..."

    local hook_script
    if [[ "$INSTALL_MODE" == "global" ]]; then
        hook_script="$HOME/.claude/hooks/activate-rules.sh"
    else
        hook_script=".claude/hooks/activate-rules.sh"
    fi

    if [[ ! -f "$hook_script" ]]; then
        error "Hook script not found: $hook_script"
        return 1
    fi

    if [[ ! -x "$hook_script" ]]; then
        error "Hook script is not executable"
        return 1
    fi

    # Test the hook with a sample prompt
    local test_output
    test_output=$(echo '{"prompt":"Write a test function"}' | "$hook_script" 2>&1)

    if echo "$test_output" | grep -q "STEP 1:.*EVALUATE"; then
        success "Hook test passed!"
        return 0
    else
        error "Hook test failed"
        echo "$test_output"
        return 1
    fi
}

# Main installation flow
main() {
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "  Centralized Rules - Hook Installation"
    echo "═══════════════════════════════════════════════════════"
    echo ""

    detect_environment
    find_rules_repo

    echo ""
    if [[ "$INSTALL_MODE" == "global" ]]; then
        info "Installing globally (all projects)"
        install_global
    else
        info "Installing locally (current project only)"
        install_local
    fi

    echo ""
    if test_installation; then
        echo ""
        success "Installation successful! 🎉"
        echo ""
        echo "═══════════════════════════════════════════════════════"
        echo "  What happens now:"
        echo "═══════════════════════════════════════════════════════"
        echo ""
        echo "When you ask Claude to write code, the hook will:"
        echo "  1. Detect your project's languages/frameworks"
        echo "  2. Match keywords in your prompt"
        echo "  3. Suggest relevant coding standards"
        echo "  4. Remind Claude to follow best practices"
        echo ""
        echo "Example prompts to try:"
        echo "  • 'Write a Python function with tests'"
        echo "  • 'Create a React component'"
        echo "  • 'Add authentication to my API'"
        echo ""
        echo "═══════════════════════════════════════════════════════"
    else
        echo ""
        error "Installation completed with errors"
        echo ""
        echo "Please check the output above and try again."
        echo "If problems persist, please file an issue:"
        echo "https://github.com/paulduvall/centralized-rules/issues"
    fi
}

# Run main installation
main "$@"
