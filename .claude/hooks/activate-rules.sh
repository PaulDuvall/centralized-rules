#!/usr/bin/env bash
#
# UserPromptSubmit Hook: Activate Centralized Rules Skill
#
# This hook intercepts user prompts and injects a mandatory activation instruction
# for the centralized-rules skill, ensuring Claude loads relevant coding rules
# via progressive disclosure before implementing any code changes.
#
# Exit codes:
#   0 = Success (output injected into Claude's context)
#   2 = Block prompt (prevent Claude from processing)
#   1 = Error (logged but doesn't block)

set -euo pipefail

# Get .claude directory (parent of hooks/)
CLAUDE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly CLAUDE_DIR

# Source shared libraries from .claude/lib/
# shellcheck source=../lib/logging.sh
# shellcheck disable=SC1091
source "${CLAUDE_DIR}/lib/logging.sh"
# shellcheck source=../lib/detection.sh
# shellcheck disable=SC1091
source "${CLAUDE_DIR}/lib/detection.sh"

# Configuration
readonly VERBOSE=${VERBOSE:-false}

# Custom debug logging (extends lib/logging.sh)
log_debug() {
    if [[ "${VERBOSE}" == "true" ]]; then
        echo "[DEBUG] $*" >&2
    fi
}

# Read JSON input from stdin
read_input() {
    local input
    input=$(cat)
    log_debug "Received input: ${input}"
    echo "${input}"
}

# Extract prompt from JSON using basic parsing (avoid jq dependency for portability)
extract_prompt() {
    local json="$1"
    # Simple extraction: look for "prompt":"..." pattern
    # This is basic but works for our use case
    echo "${json}" | sed -n 's/.*"prompt"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'
}

# Detect project context by checking for language/framework marker files
# NOTE: Uses shared detection functions from lib/detection.sh
detect_project_context() {
    local languages
    local frameworks

    # Use shared detection functions
    languages=$(detect_language)
    frameworks=$(detect_frameworks)

    log_debug "Detected languages: ${languages:-none}"
    log_debug "Detected frameworks: ${frameworks:-none}"

    # Return as pipe-separated strings
    echo "${languages:-}|${frameworks:-}"
}

# Load keyword mappings from skill-rules.json
load_keyword_mappings() {
    local json_file="$1"

    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        log_debug "jq not available, using fallback keyword matching"
        return 1
    fi

    # Check if JSON file exists
    if [[ ! -f "$json_file" ]]; then
        log_debug "skill-rules.json not found at $json_file"
        return 1
    fi

    # Export the JSON content as a variable
    SKILL_RULES_JSON=$(cat "$json_file")
    export SKILL_RULES_JSON

    return 0
}

# Match keywords in prompt against rule categories (reading from skill-rules.json)
match_keywords() {
    local prompt="$1"
    local -a matched_rules=()

    # Convert prompt to lowercase for case-insensitive matching
    local prompt_lower
    prompt_lower=$(echo "${prompt}" | tr '[:upper:]' '[:lower:]')

    # Try to load keywords from JSON file first
    local json_file="${CLAUDE_PROJECT_DIR:-.}/.claude/skills/skill-rules.json"
    if [[ ! -f "$json_file" ]]; then
        # Try global location
        json_file="$HOME/.claude/skills/skill-rules.json"
    fi

    if load_keyword_mappings "$json_file"; then
        log_debug "Using skill-rules.json for keyword matching"

        # Extract all base category keywords and rules
        local base_categories
        base_categories=$(echo "$SKILL_RULES_JSON" | jq -r '.keywordMappings.base | keys[]' 2>/dev/null)

        while IFS= read -r category; do
            [[ -z "$category" ]] && continue

            # Get keywords for this category and escape special characters
            local keywords
            keywords=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.base.${category}.keywords[]?" 2>/dev/null | sed 's/\./\\./g' | tr '\n' '|' | sed 's/|$//')

            # Get slash commands for this category
            local slash_cmds
            slash_cmds=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.base.${category}.slashCommands[]?" 2>/dev/null | tr '\n' '|' | sed 's/|$//' | sed 's|/||g')

            # Get rules for this category
            local category_rules
            category_rules=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.base.${category}.rules[]?" 2>/dev/null)

            # Match keywords
            if [[ -n "$keywords" ]] && echo "${prompt_lower}" | grep -qE "(${keywords})"; then
                while IFS= read -r rule; do
                    [[ -n "$rule" ]] && matched_rules+=("$rule")
                done <<< "$category_rules"
            fi

            # Match slash commands
            if [[ -n "$slash_cmds" ]] && echo "${prompt_lower}" | grep -qE "/(${slash_cmds})(\s|$)"; then
                while IFS= read -r rule; do
                    [[ -n "$rule" ]] && matched_rules+=("$rule")
                done <<< "$category_rules"
            fi
        done <<< "$base_categories"

        # Extract language-specific keywords and rules
        local languages
        languages=$(echo "$SKILL_RULES_JSON" | jq -r '.keywordMappings.languages | keys[]' 2>/dev/null)

        while IFS= read -r lang; do
            [[ -z "$lang" ]] && continue

            # Get keywords for this language
            local lang_keywords
            lang_keywords=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.languages.${lang}.keywords[]?" 2>/dev/null | tr '\n' '|' | sed 's/|$//')

            # Get rules for this language
            local lang_rules
            lang_rules=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.languages.${lang}.rules[]?" 2>/dev/null)

            # Get testing rules for this language
            local lang_testing_rules
            lang_testing_rules=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.languages.${lang}.testing_rules[]?" 2>/dev/null)

            # Match language keywords
            if [[ -n "$lang_keywords" ]] && echo "${prompt_lower}" | grep -qE "(${lang_keywords})"; then
                while IFS= read -r rule; do
                    [[ -n "$rule" ]] && matched_rules+=("$rule")
                done <<< "$lang_rules"

                # Add testing rules if testing keywords also matched
                if echo "${prompt_lower}" | grep -qE '(test|pytest|jest|mocha|unittest|spec|tdd|coverage|mock)'; then
                    while IFS= read -r rule; do
                        [[ -n "$rule" ]] && matched_rules+=("$rule")
                    done <<< "$lang_testing_rules"
                fi
            fi

            # Check framework-specific keywords within this language
            local frameworks
            frameworks=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.languages.${lang}.frameworks | keys[]?" 2>/dev/null)

            while IFS= read -r framework; do
                [[ -z "$framework" ]] && continue

                local framework_keywords
                framework_keywords=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.languages.${lang}.frameworks.${framework}.keywords[]?" 2>/dev/null | tr '\n' '|' | sed 's/|$//')

                local framework_rules
                framework_rules=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.languages.${lang}.frameworks.${framework}.rules[]?" 2>/dev/null)

                if [[ -n "$framework_keywords" ]] && echo "${prompt_lower}" | grep -qE "(${framework_keywords})"; then
                    while IFS= read -r rule; do
                        [[ -n "$rule" ]] && matched_rules+=("$rule")
                    done <<< "$framework_rules"
                fi
            done <<< "$frameworks"
        done <<< "$languages"

        # Extract cloud provider keywords and rules
        local cloud_providers
        cloud_providers=$(echo "$SKILL_RULES_JSON" | jq -r '.keywordMappings.cloud | keys[]' 2>/dev/null)

        while IFS= read -r provider; do
            [[ -z "$provider" ]] && continue

            local provider_keywords
            provider_keywords=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.cloud.${provider}.keywords[]?" 2>/dev/null | tr '\n' '|' | sed 's/|$//')

            local provider_rules
            provider_rules=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.cloud.${provider}.rules[]?" 2>/dev/null)

            if [[ -n "$provider_keywords" ]] && echo "${prompt_lower}" | grep -qE "(${provider_keywords})"; then
                while IFS= read -r rule; do
                    [[ -n "$rule" ]] && matched_rules+=("$rule")
                done <<< "$provider_rules"
            fi
        done <<< "$cloud_providers"

    else
        # Fallback: Use hardcoded patterns if JSON not available
        log_debug "Falling back to hardcoded keyword patterns"

        # Test-related keywords
        if echo "${prompt_lower}" | grep -qE '(test|pytest|unittest|spec|tdd|coverage|mock)'; then
            matched_rules+=("base/testing-philosophy")
        elif echo "${prompt_lower}" | grep -qE '/(x?test|x?tdd)(\s|$)'; then
            matched_rules+=("base/testing-philosophy")
        fi

        # Security keywords
        if echo "${prompt_lower}" | grep -qE '(auth|security|password|token|jwt|oauth|permission|encrypt|hash|sanitize|validate|injection)'; then
            matched_rules+=("base/security-principles")
        elif echo "${prompt_lower}" | grep -qE '/(x?security|x?audit)(\s|$)'; then
            matched_rules+=("base/security-principles")
        fi

        # Git/commit/tagging keywords
        if echo "${prompt_lower}" | grep -qE '(commit|pull request|pr|merge|branch|push|rebase|cherry-pick|tag|tagging|release|version|semver)'; then
            matched_rules+=("base/git-workflow")
            # Add git-tagging for tagging/versioning related keywords
            if echo "${prompt_lower}" | grep -qE '(tag|tagging|release|version|semver)'; then
                matched_rules+=("base/git-tagging")
            fi
        elif echo "${prompt_lower}" | grep -qE '/(x?git|x?commit|push)(\s|$)'; then
            matched_rules+=("base/git-workflow")
        fi

        # Refactoring keywords
        if echo "${prompt_lower}" | grep -qE '(refactor|clean|improve|optimize|simplify|restructure)'; then
            matched_rules+=("base/refactoring-patterns")
        elif echo "${prompt_lower}" | grep -qE '/(x?refactor|x?quality|x?optimize)(\s|$)'; then
            matched_rules+=("base/refactoring-patterns")
        fi

        # Language-specific rules
        if echo "${prompt_lower}" | grep -qE '(python|\.py|pip|pyproject|django|flask|fastapi)'; then
            matched_rules+=("languages/python")
            if echo "${prompt_lower}" | grep -qE '(test|pytest|unittest|spec|tdd|coverage|mock)'; then
                matched_rules+=("languages/python/testing")
            fi
        fi

        if echo "${prompt_lower}" | grep -qE '(typescript|javascript|\.ts|\.js|npm|node)'; then
            matched_rules+=("languages/typescript")
            if echo "${prompt_lower}" | grep -qE '(test|jest|vitest|spec|tdd|coverage|mock)'; then
                matched_rules+=("languages/typescript/testing")
            fi
        fi

        # Framework-specific rules
        if echo "${prompt_lower}" | grep -qE '(react|jsx|tsx|component|hook|usestate)'; then
            matched_rules+=("frameworks/react")
        fi

        if echo "${prompt_lower}" | grep -qE '(fastapi|starlette|pydantic)'; then
            matched_rules+=("frameworks/fastapi")
        fi

        # Cloud providers
        if echo "${prompt_lower}" | grep -qE '(aws|lambda|s3|dynamodb|cloudformation|terraform)'; then
            matched_rules+=("cloud/aws")
        fi

        if echo "${prompt_lower}" | grep -qE '(vercel|edge function|serverless)'; then
            matched_rules+=("cloud/vercel")
        fi
    fi

    log_debug "Matched rules: ${matched_rules[*]:-none}"

    # Return unique rules (handle empty array)
    if [[ ${#matched_rules[@]} -gt 0 ]]; then
        printf '%s\n' "${matched_rules[@]}" | sort -u
    fi
}

# Check if prompt indicates git operation (commit/push/tag intent)
is_git_operation() {
    local prompt_lower="$1"

    # Check for git keywords
    if echo "${prompt_lower}" | grep -qE '(commit|push|pull request|pr|merge|branch|rebase|cherry-pick|git add|tag|tagging|release)'; then
        return 0
    fi

    # Check for git-related slash commands
    if echo "${prompt_lower}" | grep -qE '/(x?git|x?commit|push)(\s|$)'; then
        return 0
    fi

    return 1
}

# Generate activation instruction with forced evaluation pattern
generate_activation_instruction() {
    local prompt="$1"
    local context="$2"

    IFS='|' read -r languages frameworks <<< "${context}"

    # Match keywords to rule categories
    local matched_rules
    matched_rules=$(match_keywords "${prompt}")

    # If no specific rules matched, use base rules only
    if [[ -z "${matched_rules}" ]]; then
        matched_rules="base/code-quality"
    fi

    # Convert prompt to lowercase for git operation detection
    local prompt_lower
    prompt_lower=$(echo "${prompt}" | tr '[:upper:]' '[:lower:]')

    # Check if this is a git operation
    local is_git_op=false
    if is_git_operation "${prompt_lower}"; then
        is_git_op=true
    fi

    # Commit hash embedded at installation time (replaced by install script)
    local installed_commit="__CENTRALIZED_RULES_COMMIT__"

    # If placeholder wasn't replaced (e.g., in CI/dev), try to get commit from git
    # Note: Using a pattern that won't be replaced by sed during installation
    local placeholder="__CENTRALIZED_RULES_""COMMIT__"
    if [[ "$installed_commit" == "$placeholder" ]]; then
        # Try multiple methods to find the centralized-rules repo
        local repo_dir=""

        # Method 1: Use BASH_SOURCE if available
        if [[ -n "${BASH_SOURCE[0]}" ]]; then
            local script_dir
            script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
            if [[ -d "$script_dir/.git" ]]; then
                repo_dir="$script_dir"
            fi
        fi

        # Method 2: Check current working directory
        if [[ -z "$repo_dir" ]] && [[ -f ".claude/hooks/activate-rules.sh" ]]; then
            repo_dir="$(pwd)"
        fi

        # Method 3: Check if we're in the .claude/hooks directory
        if [[ -z "$repo_dir" ]] && [[ "$(basename "$(pwd)")" == "hooks" ]] && [[ -d "../../.git" ]]; then
            repo_dir="$(cd ../.. 2>/dev/null && pwd)"
        fi

        # Get commit hash if we found the repo
        if [[ -n "$repo_dir" ]] && [[ -d "$repo_dir/.git" ]]; then
            installed_commit=$(cd "$repo_dir" && git rev-parse --short HEAD 2>/dev/null || echo "dev")
            log_debug "Found repo at: $repo_dir, commit: $installed_commit"
        else
            installed_commit="dev"
            log_debug "Could not find centralized-rules repo, using 'dev'"
        fi
    fi

    local repo_name="paulduvall/centralized-rules"

    # Build the activation instruction
    cat <<EOF
═══════════════════════════════════════════════════════
🎯 Centralized Rules Active | Source: ${repo_name}@${installed_commit}
═══════════════════════════════════════════════════════
EOF

    # Add pre-commit quality gates if this is a git operation
    if [[ "${is_git_op}" == "true" ]]; then
        cat <<'EOF'
🚦 PRE-COMMIT GATES: Run tests → Security scan → Code quality → Refactoring
   ⚠️  ALL checks must pass before committing/pushing
───────────────────────────────────────────────────────
EOF
    fi

    cat <<'EOF'
🔍 DETECTED CONTEXT
EOF

    # Build single-line context with pipe separator
    local context_line=""
    if [[ -n "${languages}" ]]; then
        context_line="   Languages: ${languages// /, }"
    fi
    if [[ -n "${frameworks}" ]]; then
        if [[ -n "${context_line}" ]]; then
            context_line="${context_line} | Frameworks: ${frameworks// /, }"
        else
            context_line="   Frameworks: ${frameworks// /, }"
        fi
    fi
    [[ -n "${context_line}" ]] && echo "${context_line}"

    # Inline rules list (comma-separated)
    local rules_inline
    rules_inline=$(echo "${matched_rules}" | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')
    if [[ -n "${rules_inline}" ]]; then
        echo "   Rules: ${rules_inline}"
    fi

    cat <<'EOF'
───────────────────────────────────────────────────────
EOF

    cat <<'EOF'
📚 IMPLEMENTATION WORKFLOW

1. EVALUATE: Review matched rules above for your task context
2. IMPLEMENT: Apply relevant standards from matched rule categories
3. VERIFY: Ensure code meets quality, testing, and security standards

💡 Quick Reference: Follow detected language/framework standards • Include tests • Consider security
═══════════════════════════════════════════════════════
EOF
}

# Main execution
main() {
    log_debug "Hook activated: activate-rules.sh"

    # Read input JSON
    local input
    input=$(read_input)

    # Extract prompt from JSON
    local prompt
    prompt=$(extract_prompt "${input}")

    if [[ -z "${prompt}" ]]; then
        log_debug "No prompt found in input, skipping activation"
        exit 0
    fi

    log_debug "User prompt: ${prompt}"

    # Detect project context
    local context
    context=$(detect_project_context)

    # Generate and output activation instruction
    # Use JSON format with systemMessage (visible to user) and additionalContext (for Claude)
    local output
    output=$(generate_activation_instruction "${prompt}" "${context}")

    # Check if jq is available for safe JSON escaping
    if command -v jq &> /dev/null; then
        # Use jq for proper JSON escaping
        echo "${output}" | jq -Rs . | jq -s -c "{
            systemMessage: .[0],
            hookSpecificOutput: {
                hookEventName: \"UserPromptSubmit\",
                additionalContext: .[0]
            }
        }"
    else
        # Fallback: Manual JSON escaping (basic but functional)
        local escaped_output
        escaped_output=$(printf '%s' "${output}" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed '$ s/\\n$//')

        cat <<EOF
{
    "systemMessage": "${escaped_output}",
    "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "${escaped_output}"
    }
}
EOF
    fi

    log_debug "Activation instruction generated successfully"
    exit 0
}

# Run main function
main "$@"
