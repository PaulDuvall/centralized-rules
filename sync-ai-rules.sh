#!/usr/bin/env bash

# sync-ai-rules.sh - Progressive Disclosure AI Rules Synchronization
#
# This script detects your project's language and framework, then dynamically
# loads only the relevant rules from a centralized rules repository.
#
# Usage:
#   ./sync-ai-rules.sh [--tool claude|cursor|copilot]
#
# Examples:
#   ./sync-ai-rules.sh                    # Auto-detect and sync for all tools
#   ./sync-ai-rules.sh --tool claude      # Sync only for Claude
#   ./sync-ai-rules.sh --tool cursor      # Sync only for Cursor

set -euo pipefail

# Configuration
RULES_REPO_URL="${AI_RULES_REPO:-https://raw.githubusercontent.com/yourusername/centralized-rules/main}"
RULES_DIR=".ai-rules"
CACHE_DIR="${RULES_DIR}/.cache"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

# Detect project language
detect_language() {
    local languages=()

    # Python
    if [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || [[ -f "requirements.txt" ]]; then
        languages+=("python")
    fi

    # TypeScript/JavaScript
    if [[ -f "package.json" ]]; then
        if grep -q '"typescript"' package.json 2>/dev/null; then
            languages+=("typescript")
        else
            languages+=("javascript")
        fi
    fi

    # Go
    if [[ -f "go.mod" ]]; then
        languages+=("go")
    fi

    # Java
    if [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
        languages+=("java")
    fi

    # Ruby
    if [[ -f "Gemfile" ]]; then
        languages+=("ruby")
    fi

    # Rust
    if [[ -f "Cargo.toml" ]]; then
        languages+=("rust")
    fi

    echo "${languages[@]}"
}

# Detect frameworks
detect_frameworks() {
    local frameworks=()

    # Python frameworks
    if [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
        grep -qi "django" requirements.txt pyproject.toml 2>/dev/null && frameworks+=("django")
        grep -qi "fastapi" requirements.txt pyproject.toml 2>/dev/null && frameworks+=("fastapi")
        grep -qi "flask" requirements.txt pyproject.toml 2>/dev/null && frameworks+=("flask")
    fi

    # JavaScript/TypeScript frameworks
    if [[ -f "package.json" ]]; then
        grep -q '"react"' package.json 2>/dev/null && frameworks+=("react")
        grep -q '"next"' package.json 2>/dev/null && frameworks+=("nextjs")
        grep -q '"vue"' package.json 2>/dev/null && frameworks+=("vue")
        grep -q '"express"' package.json 2>/dev/null && frameworks+=("express")
        grep -q '"nestjs"' package.json 2>/dev/null && frameworks+=("nestjs")
    fi

    # Go frameworks
    if [[ -f "go.mod" ]]; then
        grep -q "gin-gonic/gin" go.mod 2>/dev/null && frameworks+=("gin")
        grep -q "gofiber/fiber" go.mod 2>/dev/null && frameworks+=("fiber")
    fi

    # Java frameworks
    if [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]]; then
        grep -q "spring-boot" pom.xml build.gradle 2>/dev/null && frameworks+=("springboot")
    fi

    echo "${frameworks[@]}"
}

# Download rule file from repository
download_rule() {
    local rule_path="$1"
    local output_path="$2"

    mkdir -p "$(dirname "$output_path")"

    if command -v curl &> /dev/null; then
        curl -fsSL "${RULES_REPO_URL}/${rule_path}" -o "$output_path" 2>/dev/null
    elif command -v wget &> /dev/null; then
        wget -q "${RULES_REPO_URL}/${rule_path}" -O "$output_path" 2>/dev/null
    else
        log_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
}

# Load base rules (always loaded)
load_base_rules() {
    log_info "Loading base universal rules..."

    local base_rules=(
        "base/git-workflow.md"
        "base/code-quality.md"
        "base/testing-philosophy.md"
        "base/security-principles.md"
        "base/development-workflow.md"
    )

    for rule in "${base_rules[@]}"; do
        local output="${CACHE_DIR}/${rule}"
        if download_rule "$rule" "$output"; then
            log_success "Loaded $(basename "$rule")"
        else
            log_warn "Failed to load $(basename "$rule")"
        fi
    done
}

# Load language-specific rules
load_language_rules() {
    local language="$1"
    log_info "Loading $language rules..."

    local lang_rules=(
        "languages/${language}/coding-standards.md"
        "languages/${language}/testing.md"
    )

    for rule in "${lang_rules[@]}"; do
        local output="${CACHE_DIR}/${rule}"
        if download_rule "$rule" "$output"; then
            log_success "Loaded $(basename "$rule")"
        else
            log_warn "No $(basename "$rule") for $language"
        fi
    done
}

# Load framework-specific rules
load_framework_rules() {
    local framework="$1"
    log_info "Loading $framework framework rules..."

    local fw_rule="frameworks/${framework}/best-practices.md"
    local output="${CACHE_DIR}/${fw_rule}"

    if download_rule "$fw_rule" "$output"; then
        log_success "Loaded ${framework} best practices"
    else
        log_warn "No framework rules for $framework"
    fi
}

# Generate tool-specific output files
generate_claude_rules() {
    log_info "Generating Claude Code rules..."

    local output=".claude/RULES.md"
    mkdir -p .claude

    {
        echo "# AI Development Rules"
        echo ""
        echo "This file is automatically generated from centralized rules."
        echo "Last updated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
        echo ""
        echo "---"
        echo ""

        # Combine all cached rules
        find "${CACHE_DIR}" -name "*.md" -type f | sort | while read -r file; do
            echo "## $(basename "$file" .md | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')"
            echo ""
            cat "$file"
            echo ""
            echo "---"
            echo ""
        done
    } > "$output"

    log_success "Generated $output"
}

generate_cursor_rules() {
    log_info "Generating Cursor rules..."

    local output=".cursorrules"

    {
        echo "# AI Development Rules (Cursor)"
        echo "# Last updated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
        echo ""

        # Combine all cached rules
        find "${CACHE_DIR}" -name "*.md" -type f | sort | while read -r file; do
            cat "$file"
            echo ""
        done
    } > "$output"

    log_success "Generated $output"
}

generate_copilot_rules() {
    log_info "Generating GitHub Copilot rules..."

    local output=".github/copilot-instructions.md"
    mkdir -p .github

    {
        echo "# GitHub Copilot Instructions"
        echo ""
        echo "Last updated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
        echo ""

        # Combine all cached rules
        find "${CACHE_DIR}" -name "*.md" -type f | sort | while read -r file; do
            cat "$file"
            echo ""
        done
    } > "$output"

    log_success "Generated $output"
}

# Main sync function
sync_rules() {
    local tool="${1:-all}"

    log_info "Starting AI rules synchronization..."
    echo ""

    # Create cache directory
    mkdir -p "$CACHE_DIR"

    # Detect project configuration
    local languages=($(detect_language))
    local frameworks=($(detect_frameworks))

    if [[ ${#languages[@]} -eq 0 ]]; then
        log_warn "No recognized language detected. Loading base rules only."
    else
        log_info "Detected languages: ${languages[*]}"
    fi

    if [[ ${#frameworks[@]} -gt 0 ]]; then
        log_info "Detected frameworks: ${frameworks[*]}"
    fi
    echo ""

    # Load base rules (always)
    load_base_rules
    echo ""

    # Load language-specific rules
    for lang in "${languages[@]}"; do
        load_language_rules "$lang"
        echo ""
    done

    # Load framework-specific rules
    for fw in "${frameworks[@]}"; do
        load_framework_rules "$fw"
        echo ""
    done

    # Generate tool-specific outputs
    case "$tool" in
        claude)
            generate_claude_rules
            ;;
        cursor)
            generate_cursor_rules
            ;;
        copilot)
            generate_copilot_rules
            ;;
        all)
            generate_claude_rules
            generate_cursor_rules
            generate_copilot_rules
            ;;
        *)
            log_error "Unknown tool: $tool"
            log_error "Supported tools: claude, cursor, copilot, all"
            exit 1
            ;;
    esac

    echo ""
    log_success "Synchronization complete!"
    log_info "Rules cached in: $CACHE_DIR"
}

# Parse command-line arguments
tool="all"
while [[ $# -gt 0 ]]; do
    case $1 in
        --tool)
            tool="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--tool claude|cursor|copilot|all]"
            echo ""
            echo "Options:"
            echo "  --tool TOOL    Generate rules for specific tool (default: all)"
            echo "  --help, -h     Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Run sync
sync_rules "$tool"
