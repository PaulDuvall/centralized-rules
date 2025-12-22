#!/usr/bin/env bash

# demo-auto-detect.sh - Demonstration of AI tool auto-detection
#
# This script demonstrates how the enhanced sync-ai-rules.sh would work
# with automatic AI tool detection, without requiring manual --tool flags

set -euo pipefail

# Colors for output
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

echo -e "${BLUE}=== AI Tool Auto-Detection Demo ===${NC}\n"

# Detect AI tools based on project configuration
detect_ai_tools() {
    local detected_tools=()

    echo -e "${BLUE}Scanning project for AI tool configurations...${NC}\n"

    # Claude Code
    if [[ -d ".claude" ]] || [[ -f ".claude/RULES.md" ]] || [[ -f ".claude/AGENTS.md" ]]; then
        detected_tools+=("claude")
        echo -e "${GREEN}✓${NC} Found Claude Code configuration (.claude/)"
    fi

    # Cursor
    if [[ -f ".cursorrules" ]]; then
        detected_tools+=("cursor")
        echo -e "${GREEN}✓${NC} Found Cursor configuration (.cursorrules)"
    fi

    # GitHub Copilot
    if [[ -f ".github/copilot-instructions.md" ]]; then
        detected_tools+=("copilot")
        echo -e "${GREEN}✓${NC} Found GitHub Copilot configuration (.github/copilot-instructions.md)"
    fi

    # Google Gemini
    if [[ -d ".gemini" ]] || [[ -f ".gemini/rules.md" ]]; then
        detected_tools+=("gemini")
        echo -e "${GREEN}✓${NC} Found Google Gemini configuration (.gemini/)"
    fi

    echo ""
    echo "${detected_tools[@]:-}"
}

# Detect project characteristics
detect_project_info() {
    echo -e "${BLUE}Detecting project characteristics...${NC}\n"

    # Language detection
    local languages=()
    [[ -f "package.json" ]] && languages+=("TypeScript/JavaScript") && echo -e "${GREEN}✓${NC} TypeScript/JavaScript (package.json)"
    [[ -f "pyproject.toml" ]] || [[ -f "requirements.txt" ]] && languages+=("Python") && echo -e "${GREEN}✓${NC} Python (pyproject.toml/requirements.txt)"
    [[ -f "go.mod" ]] && languages+=("Go") && echo -e "${GREEN}✓${NC} Go (go.mod)"
    [[ -f "Cargo.toml" ]] && languages+=("Rust") && echo -e "${GREEN}✓${NC} Rust (Cargo.toml)"

    # Framework detection
    local frameworks=()
    if [[ -f "package.json" ]]; then
        grep -q '"react"' package.json 2>/dev/null && frameworks+=("React") && echo -e "${GREEN}✓${NC} React framework"
        grep -q '"next"' package.json 2>/dev/null && frameworks+=("Next.js") && echo -e "${GREEN}✓${NC} Next.js framework"
    fi

    if [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
        grep -qi "django" requirements.txt pyproject.toml 2>/dev/null && frameworks+=("Django") && echo -e "${GREEN}✓${NC} Django framework"
        grep -qi "fastapi" requirements.txt pyproject.toml 2>/dev/null && frameworks+=("FastAPI") && echo -e "${GREEN}✓${NC} FastAPI framework"
    fi

    echo ""
}

# Main demonstration
main() {
    # Detect AI tools
    local detected_tools
    detected_tools=$(detect_ai_tools)

    # Detect project info
    detect_project_info

    # Show summary
    echo -e "${BLUE}=== Detection Summary ===${NC}\n"

    if [[ -n "$detected_tools" ]]; then
        echo -e "${GREEN}AI Tools Detected:${NC} $detected_tools"
        echo ""
        echo -e "${YELLOW}Action:${NC} Will sync rules for detected tools only"
        echo -e "${YELLOW}Command equivalent:${NC} ./sync-ai-rules.sh (auto-mode)"
    else
        echo -e "${YELLOW}No AI tool configurations detected${NC}"
        echo ""
        echo -e "${YELLOW}Action:${NC} Will sync rules for all supported tools (fallback)"
        echo -e "${YELLOW}Command equivalent:${NC} ./sync-ai-rules.sh --tool all"
    fi

    echo ""
    echo -e "${BLUE}=== Benefits of Auto-Detection ===${NC}\n"
    echo "✓ No need to specify --tool flag"
    echo "✓ Works automatically in any development environment"
    echo "✓ Only generates rules for tools you're actually using"
    echo "✓ Reduces sync time and file clutter"
    echo "✓ Still supports manual override with --tool flag"
    echo ""

    echo -e "${BLUE}=== Usage Examples ===${NC}\n"
    echo "# Auto-detect and sync (recommended)"
    echo "./sync-ai-rules.sh"
    echo ""
    echo "# Sync for all tools (override auto-detection)"
    echo "./sync-ai-rules.sh --tool all"
    echo ""
    echo "# Sync for specific tool (override auto-detection)"
    echo "./sync-ai-rules.sh --tool claude"
    echo ""
}

main
