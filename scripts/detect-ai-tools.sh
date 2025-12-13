#!/usr/bin/env bash

# detect-ai-tools.sh - Auto-detect which AI coding assistants are configured in the project
#
# Returns space-separated list of detected tools: claude, cursor, copilot, gemini
#
# Usage:
#   tools=$(./detect-ai-tools.sh)
#   echo "Detected tools: $tools"

set -euo pipefail

# Detect AI tools based on configuration files and directories
detect_ai_tools() {
    local detected_tools=()

    # Claude Code - check for .claude directory or RULES.md
    if [[ -d ".claude" ]] || [[ -f ".claude/RULES.md" ]] || [[ -f ".claude/AGENTS.md" ]]; then
        detected_tools+=("claude")
    fi

    # Cursor - check for .cursorrules file
    if [[ -f ".cursorrules" ]]; then
        detected_tools+=("cursor")
    fi

    # GitHub Copilot - check for copilot instructions
    if [[ -f ".github/copilot-instructions.md" ]]; then
        detected_tools+=("copilot")
    fi

    # Google Gemini/Codegemma - check for .gemini directory
    if [[ -d ".gemini" ]] || [[ -f ".gemini/rules.md" ]]; then
        detected_tools+=("gemini")
    fi

    # Return detected tools or "all" if none detected
    if [[ ${#detected_tools[@]} -eq 0 ]]; then
        echo "all"
    else
        echo "${detected_tools[@]}"
    fi
}

# Main execution
detect_ai_tools
