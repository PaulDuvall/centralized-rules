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

# Token usage display configuration
# Security: Validate SHOW_TOKEN_USAGE is one of the allowed values
SHOW_TOKEN_USAGE_RAW="${SHOW_TOKEN_USAGE:-auto}"
if [[ ! "$SHOW_TOKEN_USAGE_RAW" =~ ^(true|false|auto)$ ]]; then
    log_warn "Invalid SHOW_TOKEN_USAGE value: $SHOW_TOKEN_USAGE_RAW (using 'auto')"
    SHOW_TOKEN_USAGE_RAW="auto"
fi
readonly SHOW_TOKEN_USAGE="$SHOW_TOKEN_USAGE_RAW"

# Security: Validate TOKEN_WARNING_THRESHOLD is a positive integer
TOKEN_WARNING_THRESHOLD_RAW="${TOKEN_WARNING_THRESHOLD:-4000}"
if ! [[ "$TOKEN_WARNING_THRESHOLD_RAW" =~ ^[0-9]+$ ]] || [[ "$TOKEN_WARNING_THRESHOLD_RAW" -lt 1 ]]; then
    log_warn "Invalid TOKEN_WARNING_THRESHOLD: $TOKEN_WARNING_THRESHOLD_RAW (using 4000)"
    TOKEN_WARNING_THRESHOLD_RAW=4000
fi
readonly TOKEN_WARNING_THRESHOLD="$TOKEN_WARNING_THRESHOLD_RAW"

# Security: Validate TOKEN_CONTEXT_BUDGET is a positive integer
TOKEN_CONTEXT_BUDGET_RAW="${TOKEN_CONTEXT_BUDGET:-200000}"
if ! [[ "$TOKEN_CONTEXT_BUDGET_RAW" =~ ^[0-9]+$ ]] || [[ "$TOKEN_CONTEXT_BUDGET_RAW" -lt 1000 ]]; then
    log_warn "Invalid TOKEN_CONTEXT_BUDGET: $TOKEN_CONTEXT_BUDGET_RAW (using 200000)"
    TOKEN_CONTEXT_BUDGET_RAW=200000
fi
readonly TOKEN_CONTEXT_BUDGET="$TOKEN_CONTEXT_BUDGET_RAW"

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

# Escape special regex characters for use in grep -E patterns
escape_regex() {
    local input="$1"
    # Escape all special regex characters: . * + ? [ ] ( ) { } ^ $ | \
    printf '%s' "$input" | sed 's/[.*+?\[\](){}^$|\\]/\\&/g'
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
            keywords=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.base.${category}.keywords[]?" 2>/dev/null | while IFS= read -r kw; do escape_regex "$kw"; echo "|"; done | tr -d '\n' | sed 's/|$//')

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
            lang_keywords=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.languages.${lang}.keywords[]?" 2>/dev/null | while IFS= read -r kw; do escape_regex "$kw"; echo "|"; done | tr -d '\n' | sed 's/|$//')

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
                framework_keywords=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.languages.${lang}.frameworks.${framework}.keywords[]?" 2>/dev/null | while IFS= read -r kw; do escape_regex "$kw"; echo "|"; done | tr -d '\n' | sed 's/|$//')

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
            provider_keywords=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.cloud.${provider}.keywords[]?" 2>/dev/null | while IFS= read -r kw; do escape_regex "$kw"; echo "|"; done | tr -d '\n' | sed 's/|$//')

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

# Calculate estimated token cost for banner + rules
# Returns: Estimated total tokens (integer)
# Simplicity: Uses fixed overhead estimates to avoid complex runtime calculation
# shellcheck disable=SC2317  # Function defined for future use in token display feature
calculate_token_cost() {
    # Constants for token estimation (based on empirical measurements)
    # Simplicity: Named constants make the calculation transparent
    local -r BANNER_BASE_TOKENS=500           # Banner display overhead
    local -r METADATA_TOKENS=850              # skill-rules.json (~3400 chars ÷ 4)
    local -r EXPECTED_RULES_TOKENS=3000       # ~60% of default maxTokens (5000)

    # Security: Simple integer addition, no external input
    local total=$((BANNER_BASE_TOKENS + METADATA_TOKENS + EXPECTED_RULES_TOKENS))

    echo "$total"
}

# Generate verbose token breakdown for detailed analysis
# Returns: Multi-line breakdown of token costs (empty if disabled/conditions not met)
# Security: Uses same validated constants as calculate_token_cost()
generate_verbose_token_breakdown() {
    # Only show if verbose mode is enabled and token display is not disabled
    [[ "$VERBOSE" != "true" ]] && return
    [[ "$SHOW_TOKEN_USAGE" == "false" ]] && return

    # Use same constants as calculate_token_cost() for consistency
    local -r BANNER_BASE_TOKENS=500           # Banner display overhead
    local -r METADATA_TOKENS=850              # skill-rules.json (~3400 chars ÷ 4)
    local -r EXPECTED_RULES_TOKENS=3000       # ~60% of default maxTokens (5000)
    local -r total=$((BANNER_BASE_TOKENS + METADATA_TOKENS + EXPECTED_RULES_TOKENS))

    # Calculate percentage
    local percent=$((total * 100 / TOKEN_CONTEXT_BUDGET))

    # Output verbose breakdown
    cat <<EOF
───────────────────────────────────────────────────────
📊 TOKEN USAGE BREAKDOWN (Verbose Mode)
   Banner overhead:    ~${BANNER_BASE_TOKENS} tokens
   Metadata (JSON):    ~${METADATA_TOKENS} tokens
   Rule content:       ~${EXPECTED_RULES_TOKENS} tokens
   ─────────────────────────────────────
   Total estimated:    ~${total} tokens (~${percent}% of ${TOKEN_CONTEXT_BUDGET})

   Note: Estimates based on ~4 chars per token formula
EOF
}

# Format token cost for inline display with security-conscious output
# Returns: Formatted string for banner display (e.g., " | 📊 Rules: ~4.2K tokens (~2.1%)")
# Security: Input validation, integer-only math, no command injection risks
# shellcheck disable=SC2317  # Function defined for future use in token display feature
calculate_token_cost_display() {
    # Constants for display logic
    # Simplicity: Named thresholds make behavior explicit
    local -r AUTO_MODE_THRESHOLD_PERCENT=2    # Show in auto mode if >2%
    local -r KILOBYTE_THRESHOLD=1000          # Display as K if >=1000 tokens

    # Check if disabled
    [[ "$SHOW_TOKEN_USAGE" == "false" ]] && return

    # Get token estimate (safe: function output is integer)
    local total_tokens
    total_tokens=$(calculate_token_cost)

    # Security: Validate total_tokens is a positive integer (prevent injection)
    if ! [[ "$total_tokens" =~ ^[0-9]+$ ]] || [[ "$total_tokens" -lt 0 ]]; then
        log_debug "Invalid token count: $total_tokens (skipping display)"
        return
    fi

    # Security: Prevent division by zero (defensive programming)
    if [[ "$TOKEN_CONTEXT_BUDGET" -lt 1 ]]; then
        log_debug "Invalid TOKEN_CONTEXT_BUDGET: $TOKEN_CONTEXT_BUDGET (skipping display)"
        return
    fi

    # Calculate percentage (safe: all inputs are validated integers)
    local percent=$((total_tokens * 100 / TOKEN_CONTEXT_BUDGET))

    # Auto mode: only show if exceeds threshold
    # Simplicity: Clear threshold comparison
    if [[ "$SHOW_TOKEN_USAGE" == "auto" ]] && [[ $percent -le $AUTO_MODE_THRESHOLD_PERCENT ]]; then
        return
    fi

    # Format display value
    # Simplicity: Integer math only, no floating point complexity
    local display
    if [[ $total_tokens -ge $KILOBYTE_THRESHOLD ]]; then
        local thousands=$((total_tokens / 1000))
        local hundreds=$(((total_tokens % 1000) / 100))
        display="${thousands}.${hundreds}K"
    else
        display="$total_tokens"
    fi

    # Select warning indicator based on threshold
    # Simplicity: Clear conditional, explicit indicators
    local indicator="📊"
    if [[ $total_tokens -ge $TOKEN_WARNING_THRESHOLD ]]; then
        indicator="⚠️"
    fi

    # Security: Safe string construction (no eval, no command substitution)
    # Format: " | 📊 Rules: ~4.3K tokens (~2%)"
    echo " | ${indicator} Rules: ~${display} tokens (~${percent}%)"
}

# Generate activation instruction with forced evaluation pattern
generate_activation_instruction() {
    local prompt="$1"
    # Note: context parameter (languages|frameworks) is kept for backward compatibility
    # but no longer used since Languages/Frameworks display was removed in banner simplification

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

    # Banner component constants (security: no variable interpolation in static text)
    local -r SEPARATOR="═══════════════════════════════════════════════════════"
    local -r PRE_COMMIT_MSG="⚠️ PRE-COMMIT: Tests → Security → Quality → Refactor"
    local -r QUICK_REF="💡 Follow language/framework standards • Include tests • Consider security"

    # Get token usage display (may be empty if disabled or below threshold)
    local token_display
    token_display=$(calculate_token_cost_display)

    # Build the activation instruction
    # Security: Quote all variable interpolations to prevent word splitting
    cat <<EOF
${SEPARATOR}
🎯 Centralized Rules Active | Source: ${repo_name}@${installed_commit}${token_display}
EOF

    # Add condensed pre-commit quality gates if this is a git operation
    # Simplicity: Direct function call instead of boolean variable
    if is_git_operation "${prompt_lower}"; then
        echo "${PRE_COMMIT_MSG}"
    fi

    # Add verbose token breakdown if enabled (after pre-commit gates)
    generate_verbose_token_breakdown

    # Format rules list (comma-separated, no separate Languages/Frameworks display)
    if [[ -n "${matched_rules}" ]]; then
        # Security: Validate matched_rules contains only safe characters (alphanumeric, /, -, _)
        # Each line should match the pattern for valid rule paths
        # This prevents potential injection attacks from malicious rule names
        if echo "${matched_rules}" | grep -vqE '^[a-zA-Z0-9/_-]+$'; then
            log_debug "Skipping rules display: contains unsafe characters"
        else
            # Simplicity: Portable approach compatible with both GNU and BSD sed
            local rules_inline
            rules_inline=$(echo "${matched_rules}" | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')
            echo "🔍 Rules: ${rules_inline}"
        fi
    fi

    # Output footer
    cat <<EOF
${QUICK_REF}
${SEPARATOR}
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
    elif command -v python3 &> /dev/null; then
        # Fallback: Use Python for proper JSON escaping
        python3 -c "import json, sys; output = sys.stdin.read(); print(json.dumps({'systemMessage': output, 'hookSpecificOutput': {'hookEventName': 'UserPromptSubmit', 'additionalContext': output}}))" <<< "${output}"
    elif command -v python &> /dev/null; then
        # Fallback: Use Python 2 for proper JSON escaping
        python -c "import json, sys; output = sys.stdin.read(); print json.dumps({'systemMessage': output, 'hookSpecificOutput': {'hookEventName': 'UserPromptSubmit', 'additionalContext': output}})" <<< "${output}"
    else
        # Last resort: Manual JSON escaping with improved edge case handling
        local escaped_output
        # Escape backslashes first, then quotes, then control characters
        escaped_output=$(printf '%s' "${output}" | \
            sed 's/\\/\\\\/g' | \
            sed 's/"/\\"/g' | \
            sed 's/\t/\\t/g' | \
            sed 's/\r/\\r/g' | \
            awk '{printf "%s\\n", $0}' | \
            sed '$ s/\\n$//')

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
