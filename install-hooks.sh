#!/usr/bin/env bash
#
# Centralized Rules - Automated Hook Installation
#
# This script automatically installs and configures the UserPromptSubmit hook
# for Claude Code CLI. Idempotent - safe to run multiple times.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/releases/latest/download/install-hooks.sh | bash
#
# Behavior:
#   - Downloads from latest GitHub release (stable)
#   - If you already have an installation → updates it in place (idempotent)
#   - If it's a new installation → installs globally by default
#
# Options:
#   --local   Install for current project only (instead of globally)
#   --edge    Install from main branch (developers/testing)
#   --version VERSION  Install specific version (e.g., v0.1.0)
#
# Notes:
#   - Running the same command twice safely updates the existing installation
#   - Use --local for project-specific rules, omit for all projects
#   - Falls back to main branch if no releases exist

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
info() { echo -e "${BLUE}ℹ${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warning() { echo -e "${YELLOW}⚠${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*"; }

# Configuration
INSTALL_MODE="global"  # Default to global installation
USE_EDGE="false"       # Default to release version
SPECIFIC_VERSION=""    # Empty means use latest release
GITHUB_REPO="paulduvall/centralized-rules"
GITHUB_API="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --local)
            INSTALL_MODE="local"
            shift
            ;;
        --edge)
            USE_EDGE="true"
            shift
            ;;
        --version)
            SPECIFIC_VERSION="$2"
            shift 2
            ;;
        *)
            # Ignore unknown arguments for forward compatibility
            shift
            ;;
    esac
done

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

# Determine which version to install
# Sets INSTALL_VERSION global variable
determine_version() {
    # If --edge flag, use main branch
    if [[ "$USE_EDGE" == "true" ]]; then
        INSTALL_VERSION="edge"
        warning "Using edge version (main branch) - may be unstable"
        return 0
    fi

    # If specific version requested, use that
    if [[ -n "$SPECIFIC_VERSION" ]]; then
        INSTALL_VERSION="$SPECIFIC_VERSION"
        info "Using specified version: $INSTALL_VERSION"
        return 0
    fi

    # Try to fetch latest release from GitHub API
    info "Checking for latest release..."

    local release_info
    if command -v curl >/dev/null 2>&1; then
        release_info=$(curl -sfL "$GITHUB_API" 2>/dev/null) || release_info=""
    elif command -v wget >/dev/null 2>&1; then
        release_info=$(wget -qO- "$GITHUB_API" 2>/dev/null) || release_info=""
    else
        warning "Neither curl nor wget available - using main branch"
        INSTALL_VERSION="edge"
        return 0
    fi

    # Parse version from response
    if [[ -n "$release_info" ]] && command -v jq >/dev/null 2>&1; then
        local tag_name
        tag_name=$(echo "$release_info" | jq -r '.tag_name // empty')
        if [[ -n "$tag_name" ]]; then
            INSTALL_VERSION="$tag_name"
            success "Latest release: $INSTALL_VERSION"
            return 0
        fi
    elif [[ -n "$release_info" ]]; then
        # Fallback: parse tag_name without jq
        local tag_name
        tag_name=$(echo "$release_info" | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
        if [[ -n "$tag_name" ]]; then
            INSTALL_VERSION="$tag_name"
            success "Latest release: $INSTALL_VERSION"
            return 0
        fi
    fi

    # No releases found - fall back to main with warning
    warning "No releases found - using main branch"
    warning "Note: Install from releases for stable versions"
    INSTALL_VERSION="edge"
}

# Remove hook from global settings
remove_global_hook() {
    local settings_file="$HOME/.claude/settings.json"

    if [[ ! -f "$settings_file" ]]; then
        return 0
    fi

    info "Removing global hook from $settings_file"

    if command -v jq >/dev/null 2>&1; then
        # Use jq to remove the UserPromptSubmit hook
        local temp_file
        temp_file=$(mktemp)
        jq 'del(.hooks.UserPromptSubmit[] | select(.hooks[]?.command | contains("activate-rules.sh")))' \
            "$settings_file" > "$temp_file"
        mv "$temp_file" "$settings_file"
        success "Removed global hook"
    else
        warning "jq not found - please manually remove the hook from $settings_file"
        echo "Look for the UserPromptSubmit hook with activate-rules.sh"
    fi
}

# Remove hook from local settings
remove_local_hook() {
    local settings_file=".claude/settings.json"

    if [[ ! -f "$settings_file" ]]; then
        return 0
    fi

    info "Removing local hook from $settings_file"

    if command -v jq >/dev/null 2>&1; then
        # Use jq to remove the UserPromptSubmit hook
        local temp_file
        temp_file=$(mktemp)
        jq 'del(.hooks.UserPromptSubmit[] | select(.hooks[]?.command | contains("activate-rules.sh")))' \
            "$settings_file" > "$temp_file"
        mv "$temp_file" "$settings_file"
        success "Removed local hook"
    else
        warning "jq not found - please manually remove the hook from $settings_file"
        echo "Look for the UserPromptSubmit hook with activate-rules.sh"
    fi
}

# Detect existing installations and handle mode selection
detect_existing_installation() {
    local has_global=false
    local has_local=false

    # Check for global installation
    if [[ -f "$HOME/.claude/settings.json" ]] && grep -q "activate-rules.sh" "$HOME/.claude/settings.json" 2>/dev/null; then
        has_global=true
    fi

    # Check for local installation
    if [[ -f ".claude/settings.json" ]] && grep -q "activate-rules.sh" ".claude/settings.json" 2>/dev/null; then
        has_local=true
    fi

    # Simple idempotent behavior: update existing installation in place
    if [[ "$has_global" == "true" ]] && [[ "$has_local" == "false" ]]; then
        info "Existing global installation detected - updating in place"
        INSTALL_MODE="global"
        return 0
    fi

    if [[ "$has_local" == "true" ]] && [[ "$has_global" == "false" ]]; then
        info "Existing local installation detected - updating in place"
        INSTALL_MODE="local"
        return 0
    fi

    # Both exist - this is a problem
    if [[ "$has_global" == "true" ]] && [[ "$has_local" == "true" ]]; then
        echo ""
        error "⚠️  DUPLICATE INSTALLATION DETECTED"
        warning "Both global AND local installations exist"
        warning "The hook will run TWICE (duplicate banners)"
        echo ""
        echo "Fix this by running ONE of these commands:"
        echo ""
        echo "  # Keep global only (recommended for all projects):"
        echo "  rm .claude/settings.json"
        echo "  curl -fsSL ... | bash"
        echo ""
        echo "  # Keep local only (for this project):"
        echo "  rm ~/.claude/settings.json"
        echo "  curl -fsSL ... | bash -s -- --local"
        echo ""
        exit 1
    fi

    # No existing installation - use specified mode (global is default)
    if [[ "$INSTALL_MODE" == "global" ]]; then
        info "New global installation (applies to all projects)"
    else
        info "New local installation (applies to this project only)"
    fi
}

# Find the centralized-rules repository
find_rules_repo() {
    local path

    # If we're already in the centralized-rules repo
    if [[ -f ".claude/hooks/activate-rules.sh" ]]; then
        RULES_REPO_PATH="$(pwd)"
        success "Using current directory: $RULES_REPO_PATH"

        # Get commit ID and remote URL
        if git rev-parse --git-dir > /dev/null 2>&1; then
            COMMIT_ID=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
            REPO_URL=$(git config --get remote.origin.url 2>/dev/null || echo "unknown")
            success "Commit: $COMMIT_ID"
            success "Repository: $REPO_URL"
        fi
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

            # Get commit ID and remote URL
            if [[ -d "$path/.git" ]]; then
                COMMIT_ID=$(cd "$path" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
                REPO_URL=$(cd "$path" && git config --get remote.origin.url 2>/dev/null || echo "unknown")
                success "Commit: $COMMIT_ID"
                success "Repository: $REPO_URL"
            fi
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
    mkdir -p .claude/lib

    # Copy hook script and embed commit hash
    cp "$RULES_REPO_PATH/.claude/hooks/activate-rules.sh" .claude/hooks/activate-rules.sh.tmp
    # Inject the actual commit hash (escape special sed characters for security)
    local commit_id_escaped
    commit_id_escaped=$(printf '%s\n' "$COMMIT_ID" | sed 's/[&/\]/\\&/g')
    sed "s/__CENTRALIZED_RULES_COMMIT__/${commit_id_escaped}/g" \
        .claude/hooks/activate-rules.sh.tmp > .claude/hooks/activate-rules.sh
    rm .claude/hooks/activate-rules.sh.tmp
    chmod 700 .claude/hooks/activate-rules.sh
    success "Copied hook script (commit: ${COMMIT_ID})"

    # Copy shared libraries
    cp -r "$RULES_REPO_PATH/lib/"* .claude/lib/
    success "Copied shared libraries"

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

    # Copy hook script and embed commit hash
    cp "$RULES_REPO_PATH/.claude/hooks/activate-rules.sh" "$HOME/.claude/hooks/activate-rules.sh.tmp"
    # Inject the actual commit hash (escape special sed characters for security)
    local commit_id_escaped
    commit_id_escaped=$(printf '%s\n' "$COMMIT_ID" | sed 's/[&/\]/\\&/g')
    sed "s/__CENTRALIZED_RULES_COMMIT__/${commit_id_escaped}/g" \
        "$HOME/.claude/hooks/activate-rules.sh.tmp" > "$HOME/.claude/hooks/activate-rules.sh"
    rm "$HOME/.claude/hooks/activate-rules.sh.tmp"
    chmod 700 "$HOME/.claude/hooks/activate-rules.sh"
    success "Copied hook script to ~/.claude/hooks/ (commit: ${COMMIT_ID})"

    # Copy shared libraries
    mkdir -p "$HOME/.claude/lib"
    cp -r "$RULES_REPO_PATH/lib/"* "$HOME/.claude/lib/"
    success "Copied shared libraries to ~/.claude/lib/"

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
    test_output=$(echo '{"prompt":"Write a test function"}' | "$hook_script" 2>&1) || true

    # Check for the simplified banner components
    if echo "$test_output" | grep -q "Centralized Rules Active" && \
       echo "$test_output" | grep -q "systemMessage"; then
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
    determine_version
    find_rules_repo
    detect_existing_installation

    # Extract tips from rule files
    echo ""
    info "Extracting tips from rule files..."
    if [[ -x "$RULES_REPO_PATH/extract-tips.sh" ]]; then
        (cd "$RULES_REPO_PATH" && ./extract-tips.sh) || warning "Tip extraction failed (continuing anyway)"
    else
        warning "extract-tips.sh not found or not executable (skipping tip extraction)"
    fi

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
        echo "  Installation Details"
        echo "═══════════════════════════════════════════════════════"
        echo ""
        echo "📦 Repository: ${REPO_URL:-paulduvall/centralized-rules}"
        echo "🏷️  Version: ${INSTALL_VERSION:-unknown}"
        echo "📌 Commit: ${COMMIT_ID:-unknown}"
        echo "🔗 Verify: https://github.com/paulduvall/centralized-rules/commit/${COMMIT_ID:-main}"
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
        echo "  • 'Are we using Vercel best practices?'"
        echo ""
        echo "To verify your installation anytime, check the hook banner"
        echo "which shows the commit ID when triggered."
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
