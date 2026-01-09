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
SHOW_TOKEN_USAGE_RAW="${SHOW_TOKEN_USAGE:-true}"
if [[ ! "$SHOW_TOKEN_USAGE_RAW" =~ ^(true|false|auto)$ ]]; then
    log_warn "Invalid SHOW_TOKEN_USAGE value: $SHOW_TOKEN_USAGE_RAW (using 'true')"
    SHOW_TOKEN_USAGE_RAW="true"
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

# Token estimation constants (shared across all token calculation functions)
# Simplicity: Centralized constants eliminate duplication and ensure consistency
readonly TOKEN_BANNER_BASE=500           # Banner display overhead
readonly TOKEN_METADATA=850              # skill-rules.json (~3400 chars ÷ 4)
readonly TOKEN_RULES_EXPECTED=3000       # ~60% of default maxTokens (5000)

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

# Add word boundaries to short keywords (<=4 chars) to prevent substring matches
# Args: keyword string (already escaped)
# Returns: keyword with word boundaries if short, otherwise unchanged
add_word_boundaries() {
    local keyword="$1"

    # Count actual characters (excluding escape sequences)
    # Remove backslashes used for escaping to get true length
    local unescaped="${keyword//\\/}"
    local length=${#unescaped}

    # Add word boundaries for short keywords (4 chars or less)
    if [[ $length -le 4 ]]; then
        printf '\\b%s\\b' "$keyword"
    else
        printf '%s' "$keyword"
    fi
}

# Check if prompt is asking ABOUT a topic rather than working WITH it
# Returns 0 if it's a meta-question (should filter), 1 if it's actionable work
is_meta_question() {
    local prompt_lower="$1"
    local keyword="$2"

    # Patterns that indicate asking about something, not working with it
    # Example: "why is django loading", "what is react", "how does pytest work"
    local meta_patterns=(
        "why (is|does|are) ${keyword}"
        "what is ${keyword}"
        "what('s| is) ${keyword}"
        "how does ${keyword}"
        "tell me about ${keyword}"
        "explain ${keyword}"
        "loading.*${keyword}"
        "${keyword}.*loading"
        "i('m| am) not using ${keyword}"
        "not using ${keyword}"
        "don('t|t) use ${keyword}"
    )

    for pattern in "${meta_patterns[@]}"; do
        if echo "${prompt_lower}" | grep -qE "${pattern}"; then
            log_debug "Meta-question detected for '${keyword}': matches pattern '${pattern}'"
            return 0
        fi
    done

    return 1
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
            keywords=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.base.${category}.keywords[]?" 2>/dev/null | while IFS= read -r kw; do add_word_boundaries "$(escape_regex "$kw")"; echo "|"; done | tr -d '\n' | sed 's/|$//')

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
            lang_keywords=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.languages.${lang}.keywords[]?" 2>/dev/null | while IFS= read -r kw; do add_word_boundaries "$(escape_regex "$kw")"; echo "|"; done | tr -d '\n' | sed 's/|$//')

            # Get rules for this language
            local lang_rules
            lang_rules=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.languages.${lang}.rules[]?" 2>/dev/null)

            # Get testing rules for this language
            local lang_testing_rules
            lang_testing_rules=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.languages.${lang}.testing_rules[]?" 2>/dev/null)

            # Match language keywords
            if [[ -n "$lang_keywords" ]] && echo "${prompt_lower}" | grep -qE "(${lang_keywords})"; then
                # Filter out meta-questions (asking ABOUT the language, not using it)
                if ! is_meta_question "${prompt_lower}" "${lang}"; then
                    # Require BOTH keyword match AND definitive files to prevent false positives
                    if has_definitive_files "${lang}"; then
                        while IFS= read -r rule; do
                            [[ -n "$rule" ]] && matched_rules+=("$rule")
                        done <<< "$lang_rules"

                        # Add testing rules if testing keywords also matched
                        if echo "${prompt_lower}" | grep -qE '(test|pytest|jest|mocha|unittest|spec|tdd|coverage|mock)'; then
                            while IFS= read -r rule; do
                                [[ -n "$rule" ]] && matched_rules+=("$rule")
                            done <<< "$lang_testing_rules"
                        fi
                    else
                        log_debug "Skipping language rules for '${lang}': keyword matched but no definitive files found"
                    fi
                fi
            fi

            # Check framework-specific keywords within this language
            local frameworks
            frameworks=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.languages.${lang}.frameworks | keys[]?" 2>/dev/null)

            while IFS= read -r framework; do
                [[ -z "$framework" ]] && continue

                local framework_keywords
                framework_keywords=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.languages.${lang}.frameworks.${framework}.keywords[]?" 2>/dev/null | while IFS= read -r kw; do add_word_boundaries "$(escape_regex "$kw")"; echo "|"; done | tr -d '\n' | sed 's/|$//')

                local framework_rules
                framework_rules=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.languages.${lang}.frameworks.${framework}.rules[]?" 2>/dev/null)

                if [[ -n "$framework_keywords" ]] && echo "${prompt_lower}" | grep -qE "(${framework_keywords})"; then
                    # Filter out meta-questions (asking ABOUT the framework, not using it)
                    if ! is_meta_question "${prompt_lower}" "${framework}"; then
                        while IFS= read -r rule; do
                            [[ -n "$rule" ]] && matched_rules+=("$rule")
                        done <<< "$framework_rules"
                    fi
                fi
            done <<< "$frameworks"
        done <<< "$languages"

        # Extract cloud provider keywords and rules
        local cloud_providers
        cloud_providers=$(echo "$SKILL_RULES_JSON" | jq -r '.keywordMappings.cloud | keys[]' 2>/dev/null)

        while IFS= read -r provider; do
            [[ -z "$provider" ]] && continue

            local provider_keywords
            provider_keywords=$(echo "$SKILL_RULES_JSON" | jq -r ".keywordMappings.cloud.${provider}.keywords[]?" 2>/dev/null | while IFS= read -r kw; do add_word_boundaries "$(escape_regex "$kw")"; echo "|"; done | tr -d '\n' | sed 's/|$//')

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

        # Language-specific rules (require BOTH keyword match AND definitive files)
        if echo "${prompt_lower}" | grep -qE '(\bpython\b|\.py\b|pip|pyproject|django|flask|fastapi)'; then
            if has_definitive_files "python"; then
                matched_rules+=("languages/python")
                if echo "${prompt_lower}" | grep -qE '(test|pytest|unittest|spec|tdd|coverage|mock)'; then
                    matched_rules+=("languages/python/testing")
                fi
            else
                log_debug "Skipping Python rules: keyword matched but no definitive files found"
            fi
        fi

        if echo "${prompt_lower}" | grep -qE '(typescript|javascript|\.ts\b|\.js\b|npm|node)'; then
            if has_definitive_files "javascript"; then
                matched_rules+=("languages/typescript")
                if echo "${prompt_lower}" | grep -qE '(test|jest|vitest|spec|tdd|coverage|mock)'; then
                    matched_rules+=("languages/typescript/testing")
                fi
            else
                log_debug "Skipping JavaScript/TypeScript rules: keyword matched but no definitive files found"
            fi
        fi

        # Rust detection
        if echo "${prompt_lower}" | grep -qE '\brust\b'; then
            if has_definitive_files "rust"; then
                matched_rules+=("languages/rust")
            else
                log_debug "Skipping Rust rules: keyword matched but no definitive files found"
            fi
        fi

        # Go detection
        if echo "${prompt_lower}" | grep -qE '\bgo\b'; then
            if has_definitive_files "go"; then
                matched_rules+=("languages/go")
            else
                log_debug "Skipping Go rules: keyword matched but no definitive files found"
            fi
        fi

        # Java detection
        if echo "${prompt_lower}" | grep -qE '\bjava\b'; then
            if has_definitive_files "java"; then
                matched_rules+=("languages/java")
            else
                log_debug "Skipping Java rules: keyword matched but no definitive files found"
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

# Calculate actual token cost by reading matched rule files
# Args: Space-separated list of rule paths (e.g., "base/security-principles base/code-quality")
# Returns: Estimated total tokens (integer)
# Security: Validates file paths, handles missing files gracefully
calculate_token_cost() {
    # shellcheck disable=SC2178,SC2128  # matched_rules is a string, not an array
    local matched_rules="$1"
    local rules_tokens=0

    # Calculate actual size of matched rule files
    # shellcheck disable=SC2128  # matched_rules is a string, not an array
    if [[ -n "$matched_rules" ]]; then
        # Convert newline-separated to space-separated for iteration
        local rules_list
        rules_list=$(echo "$matched_rules" | tr '\n' ' ')

        for rule_path in $rules_list; do
            # Security: Validate rule path contains only safe characters
            if ! [[ "$rule_path" =~ ^[a-zA-Z0-9/_-]+$ ]]; then
                log_debug "Skipping invalid rule path: $rule_path"
                continue
            fi

            # Construct full path to rule file
            local rule_file="${rule_path}.md"

            # Try to find the rule file (could be in current dir or absolute path)
            local found_file=""
            if [[ -f "$rule_file" ]]; then
                # Direct file match (e.g., base/security-principles.md)
                found_file="$rule_file"
            elif [[ -f "./${rule_file}" ]]; then
                found_file="./${rule_file}"
            else
                # Look for common subdirectory patterns (languages/LANG/*, frameworks/FRAMEWORK/*)
                if [[ -d "$rule_path" ]]; then
                    # Prioritize primary files: coding-standards.md, best-practices.md
                    if [[ -f "$rule_path/coding-standards.md" ]]; then
                        found_file="$rule_path/coding-standards.md"
                    elif [[ -f "$rule_path/best-practices.md" ]]; then
                        found_file="$rule_path/best-practices.md"
                    else
                        # Fallback: find first .md file
                        while IFS= read -r subfile; do
                            [[ -f "$subfile" ]] && found_file="$subfile" && break
                        done < <(find "$rule_path" -maxdepth 1 -name "*.md" 2>/dev/null)
                    fi
                fi
            fi

            # Count characters and estimate tokens (÷4)
            if [[ -n "$found_file" ]]; then
                local char_count
                char_count=$(wc -c < "$found_file" 2>/dev/null || echo "0")
                local file_tokens=$((char_count / 4))
                rules_tokens=$((rules_tokens + file_tokens))
                log_debug "Rule $rule_path: $char_count chars → ~$file_tokens tokens"
            else
                log_debug "Rule file not found: $rule_file"
            fi
        done
    fi

    # If no rules were found/calculated, use the expected estimate as fallback
    if [[ $rules_tokens -eq 0 ]]; then
        rules_tokens=$TOKEN_RULES_EXPECTED
        log_debug "No rule files found, using fallback estimate: $rules_tokens"
    fi

    # Security: Simple integer addition using validated readonly constants
    local total=$((TOKEN_BANNER_BASE + TOKEN_METADATA + rules_tokens))
    echo "$total"
}

# Generate verbose token breakdown for detailed analysis
# Args: Matched rules (newline-separated)
# Returns: Multi-line breakdown of token costs (empty if disabled/conditions not met)
# Security: Uses validated readonly constants, guards against division by zero
generate_verbose_token_breakdown() {
    local matched_rules="$1"

    # Only show if verbose mode is enabled and token display is not disabled
    [[ "$VERBOSE" != "true" ]] && return
    [[ "$SHOW_TOKEN_USAGE" == "false" ]] && return

    # Security: Prevent division by zero (same validation as calculate_token_cost_display)
    if [[ "$TOKEN_CONTEXT_BUDGET" -lt 1 ]]; then
        log_debug "Invalid TOKEN_CONTEXT_BUDGET: $TOKEN_CONTEXT_BUDGET (skipping breakdown)"
        return
    fi

    # Calculate actual token cost based on matched rules
    local -r total=$(calculate_token_cost "$matched_rules")
    local rules_tokens=$((total - TOKEN_BANNER_BASE - TOKEN_METADATA))
    local percent=$((total * 100 / TOKEN_CONTEXT_BUDGET))

    # Output verbose breakdown
    cat <<EOF
───────────────────────────────────────────────────────
📊 TOKEN USAGE BREAKDOWN (Verbose Mode)
   Banner overhead:    ~${TOKEN_BANNER_BASE} tokens
   Metadata (JSON):    ~${TOKEN_METADATA} tokens
   Rule content:       ~${rules_tokens} tokens
   ─────────────────────────────────────
   Total estimated:    ~${total} tokens (~${percent}% of ${TOKEN_CONTEXT_BUDGET})

   Note: Estimates based on ~4 chars per token formula
EOF
}

# Format token cost for inline display with security-conscious output
# Args: Matched rules (newline-separated)
# Returns: Formatted string for banner display (e.g., " | 📊 Rules: ~4.2K tokens (~2.1%)")
# Security: Input validation, integer-only math, no command injection risks
# shellcheck disable=SC2317  # Function defined for future use in token display feature
calculate_token_cost_display() {
    local matched_rules="$1"

    # Constants for display logic
    # Simplicity: Named thresholds make behavior explicit
    local -r AUTO_MODE_THRESHOLD_PERCENT=2    # Show in auto mode if >2%
    local -r KILOBYTE_THRESHOLD=1000          # Display as K if >=1000 tokens

    # Check if disabled
    [[ "$SHOW_TOKEN_USAGE" == "false" ]] && return

    # Get token estimate based on actual matched rules (safe: function output is integer)
    local total_tokens
    total_tokens=$(calculate_token_cost "$matched_rules")

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

# Test function: Verify token calculation correctness
# Returns: 0 if tests pass, 1 if tests fail
# Testing: Can be invoked with RUN_TESTS=true environment variable
# Security: Uses subshells to avoid modifying readonly variables
test_token_calculations() {
    local failures=0

    # Test 1: calculate_token_cost with empty rules uses fallback
    local expected=$((TOKEN_BANNER_BASE + TOKEN_METADATA + TOKEN_RULES_EXPECTED))
    local actual
    actual=$(calculate_token_cost "")
    if [[ "$actual" != "$expected" ]]; then
        echo "FAIL: calculate_token_cost with empty rules returned $actual, expected $expected" >&2
        ((failures++))
    else
        echo "PASS: calculate_token_cost with empty rules uses fallback ($actual)" >&2
    fi

    # Test 2: Token cost is positive integer
    if ! [[ "$actual" =~ ^[0-9]+$ ]] || [[ "$actual" -lt 1 ]]; then
        echo "FAIL: calculate_token_cost returned non-positive integer: $actual" >&2
        ((failures++))
    else
        echo "PASS: calculate_token_cost returns positive integer" >&2
    fi

    # Test 3: Token constants are readonly and positive
    if [[ $TOKEN_BANNER_BASE -gt 0 ]] && [[ $TOKEN_METADATA -gt 0 ]] && [[ $TOKEN_RULES_EXPECTED -gt 0 ]]; then
        echo "PASS: Token constants are positive" >&2
    else
        echo "FAIL: Token constants must be positive" >&2
        ((failures++))
    fi

    # Test 4: calculate_token_cost with actual rule file (if available)
    if [[ -f "base/code-quality.md" ]]; then
        local with_rule
        with_rule=$(calculate_token_cost "base/code-quality")
        local min_expected=$((TOKEN_BANNER_BASE + TOKEN_METADATA))
        # Should be at least banner+metadata (rule file must have some content)
        if [[ "$with_rule" -gt "$min_expected" ]]; then
            echo "PASS: calculate_token_cost with actual rule returns valid value ($with_rule > $min_expected)" >&2
        else
            echo "FAIL: calculate_token_cost with rule returned unexpected value: $with_rule (expected > $min_expected)" >&2
            ((failures++))
        fi
    fi

    if [[ $failures -eq 0 ]]; then
        echo "✓ All token calculation tests passed" >&2
        return 0
    else
        echo "✗ $failures test(s) failed" >&2
        return 1
    fi
}

# Select context-based tip from skill-rules.json
select_contextual_tip() {
    local matched_rules="$1"

    # Find JSON file
    local json_file="${CLAUDE_PROJECT_DIR:-.}/.claude/skills/skill-rules.json"
    [[ ! -f "$json_file" ]] && json_file="$HOME/.claude/skills/skill-rules.json"

    # Fallback if jq not available
    if ! command -v jq &> /dev/null || [[ ! -f "$json_file" ]]; then
        echo "Follow standards • Write tests • Ensure security • Refactor"
        return
    fi

    # Try each matched rule until we find a tip
    while IFS= read -r rule; do
        [[ -z "$rule" ]] && continue

        # Check base categories
        local tip
        tip=$(jq -r ".keywordMappings.base | to_entries[] | select(.value.rules[]? == \"$rule\") | .value.tip // empty" "$json_file" 2>/dev/null | head -1)
        [[ -n "$tip" ]] && echo "$tip" && return

        # Check language categories
        tip=$(jq -r ".keywordMappings.languages | to_entries[] | select(.value.rules[]? == \"$rule\") | .value.tip // empty" "$json_file" 2>/dev/null | head -1)
        [[ -n "$tip" ]] && echo "$tip" && return

        # Check framework categories
        tip=$(jq -r ".keywordMappings.languages | to_entries[] | .value.frameworks | to_entries[]? | select(.value.rules[]? == \"$rule\") | .value.tip // empty" "$json_file" 2>/dev/null | head -1)
        [[ -n "$tip" ]] && echo "$tip" && return

        # Check cloud categories
        tip=$(jq -r ".keywordMappings.cloud | to_entries[] | select(.value.rules[]? == \"$rule\") | .value.tip // empty" "$json_file" 2>/dev/null | head -1)
        [[ -n "$tip" ]] && echo "$tip" && return
    done <<< "$matched_rules"

    # Fallback
    echo "Follow standards • Write tests • Ensure security • Refactor"
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
    local installed_commit="16c0aa5"

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

    # Get context-based tip (dynamic based on matched rules)
    local contextual_tip
    contextual_tip=$(select_contextual_tip "${matched_rules}")

    # Get token usage display (may be empty if disabled or below threshold)
    local token_display
    token_display=$(calculate_token_cost_display "${matched_rules}")

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
    generate_verbose_token_breakdown "${matched_rules}"

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

    # Output footer with context-based tip
    cat <<EOF
💡 ${contextual_tip}
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

# Run tests if requested (for development/CI)
if [[ "${RUN_TESTS:-false}" == "true" ]]; then
    test_token_calculations
    exit $?
fi

# Run main function
main "$@"
