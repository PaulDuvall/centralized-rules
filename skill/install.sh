#!/usr/bin/env bash
set -e

# Centralized Rules Skill Installer
# Installs the Claude skill via git clone + build

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/paulduvall/centralized-rules.git"
INSTALL_DIR="${HOME}/centralized-rules"
SKILL_DIR="${INSTALL_DIR}/skill"

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check for git
    if ! command -v git &> /dev/null; then
        log_error "git is not installed. Please install git first."
        exit 1
    fi

    # Check for node/npm
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed. Please install Node.js 18+ first."
        log_info "Visit: https://nodejs.org/"
        exit 1
    fi

    if ! command -v npm &> /dev/null; then
        log_error "npm is not installed. Please install npm first."
        exit 1
    fi

    # Check Node version
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        log_error "Node.js 18+ required. Current version: $(node -v)"
        exit 1
    fi

    log_success "Prerequisites OK"
}

# Clone or update repository
install_repo() {
    log_info "Installing centralized-rules repository..."

    if [ -d "$INSTALL_DIR" ]; then
        log_warn "Directory $INSTALL_DIR already exists"
        read -p "Update existing installation? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Updating repository..."
            cd "$INSTALL_DIR"
            git pull || {
                log_error "Failed to update repository"
                exit 1
            }
            log_success "Repository updated"
        else
            log_info "Using existing installation"
        fi
    else
        log_info "Cloning repository..."
        git clone "$REPO_URL" "$INSTALL_DIR" || {
            log_error "Failed to clone repository"
            exit 1
        }
        log_success "Repository cloned to $INSTALL_DIR"
    fi
}

# Build skill
build_skill() {
    log_info "Building skill..."

    if [ ! -d "$SKILL_DIR" ]; then
        log_error "Skill directory not found: $SKILL_DIR"
        exit 1
    fi

    cd "$SKILL_DIR"

    # Install dependencies
    log_info "Installing dependencies..."
    npm install || {
        log_error "Failed to install dependencies"
        exit 1
    }

    # Build
    log_info "Compiling TypeScript..."
    npm run build || {
        log_error "Failed to build skill"
        exit 1
    }

    log_success "Skill built successfully"
}

# Show configuration instructions
show_config_instructions() {
    echo ""
    echo "═══════════════════════════════════════════════════════"
    log_success "Installation complete!"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    log_info "Next steps:"
    echo ""
    echo "1. Add the skill to your Claude configuration:"
    echo ""
    echo "   File: ~/.config/claude/claude_desktop_config.json"
    echo ""
    echo "   Add this to the 'skills' array:"
    echo ""
    echo "   {"
    echo "     \"skills\": ["
    echo "       {"
    echo "         \"name\": \"centralized-rules\","
    echo "         \"path\": \"${SKILL_DIR}\""
    echo "       }"
    echo "     ]"
    echo "   }"
    echo ""
    echo "2. Restart Claude Desktop/Claude Code"
    echo ""
    echo "3. The skill will automatically load relevant rules!"
    echo ""
    log_info "Installation directory: $INSTALL_DIR"
    log_info "Skill directory: $SKILL_DIR"
    echo ""
    log_info "To update later, run this script again or:"
    echo "   cd $INSTALL_DIR && git pull && cd skill && npm run build"
    echo ""
}

# Main installation flow
main() {
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "  Centralized Rules Skill Installer"
    echo "═══════════════════════════════════════════════════════"
    echo ""

    check_prerequisites
    install_repo
    build_skill
    show_config_instructions
}

# Run main
main
