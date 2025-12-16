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

# Configuration
VERBOSE=${VERBOSE:-false}

# Logging helper
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
detect_project_context() {
    local -a languages=()
    local -a frameworks=()

    # Language detection
    [[ -f "pyproject.toml" ]] || [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]] && languages+=("python")
    [[ -f "package.json" ]] && {
        if grep -q '"typescript"' package.json 2>/dev/null; then
            languages+=("typescript")
        else
            languages+=("javascript")
        fi
    }
    [[ -f "go.mod" ]] && languages+=("go")
    [[ -f "Cargo.toml" ]] && languages+=("rust")
    [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]] && languages+=("java")
    [[ -f "*.csproj" ]] && languages+=("csharp")

    # Framework detection
    [[ -f "package.json" ]] && {
        grep -q '"react"' package.json 2>/dev/null && frameworks+=("react")
        grep -q '"next"' package.json 2>/dev/null && frameworks+=("nextjs")
        grep -q '"@nestjs/core"' package.json 2>/dev/null && frameworks+=("nestjs")
        grep -q '"express"' package.json 2>/dev/null && frameworks+=("express")
    }
    [[ -f "pyproject.toml" ]] && {
        grep -q 'fastapi' pyproject.toml 2>/dev/null && frameworks+=("fastapi")
        grep -q 'django' pyproject.toml 2>/dev/null && frameworks+=("django")
        grep -q 'flask' pyproject.toml 2>/dev/null && frameworks+=("flask")
    }
    [[ -f "requirements.txt" ]] && {
        grep -q 'fastapi' requirements.txt 2>/dev/null && frameworks+=("fastapi")
        grep -q 'django' requirements.txt 2>/dev/null && frameworks+=("django")
        grep -q 'flask' requirements.txt 2>/dev/null && frameworks+=("flask")
    }

    log_debug "Detected languages: ${languages[*]:-none}"
    log_debug "Detected frameworks: ${frameworks[*]:-none}"

    # Return as comma-separated strings
    echo "${languages[*]:-}|${frameworks[*]:-}"
}

# Match keywords in prompt against rule categories
match_keywords() {
    local prompt="$1"
    local -a matched_rules=()

    # Convert prompt to lowercase for case-insensitive matching
    local prompt_lower
    prompt_lower=$(echo "${prompt}" | tr '[:upper:]' '[:lower:]')

    # Test-related keywords
    if echo "${prompt_lower}" | grep -qE '(test|pytest|unittest|spec|tdd|coverage|mock)'; then
        matched_rules+=("base/testing-philosophy")
    fi

    # Security keywords
    if echo "${prompt_lower}" | grep -qE '(auth|security|password|token|jwt|oauth|permission|encrypt|hash|sanitize|validate|injection)'; then
        matched_rules+=("base/security-principles")
    fi

    # Git/commit keywords
    if echo "${prompt_lower}" | grep -qE '(commit|pull request|pr|merge|branch|git)'; then
        matched_rules+=("base/git-workflow")
    fi

    # Refactoring keywords
    if echo "${prompt_lower}" | grep -qE '(refactor|clean|improve|optimize|simplify|restructure)'; then
        matched_rules+=("base/refactoring-patterns")
    fi

    # Architecture keywords
    if echo "${prompt_lower}" | grep -qE '(architect|design|pattern|structure|12-factor|scalab|deployment)'; then
        matched_rules+=("base/architecture-principles")
    fi

    # Language-specific rules (add when available in your repo)
    if echo "${prompt_lower}" | grep -qE '(python|\.py|pip|pyproject|django|flask|fastapi)'; then
        matched_rules+=("languages/python")
        # Add testing rules if testing keywords were also matched
        if echo "${prompt_lower}" | grep -qE '(test|pytest|unittest|spec|tdd|coverage|mock)'; then
            matched_rules+=("languages/python/testing")
        fi
    fi

    if echo "${prompt_lower}" | grep -qE '(typescript|javascript|\.ts|\.js|npm|node)'; then
        matched_rules+=("languages/typescript")
        # Add testing rules if testing keywords were also matched
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

    if echo "${prompt_lower}" | grep -qE '(next\.js|nextjs|getserversideprops)'; then
        matched_rules+=("frameworks/nextjs")
    fi

    # Cloud/infrastructure keywords
    if echo "${prompt_lower}" | grep -qE '(aws|lambda|s3|dynamodb|cloudformation|terraform)'; then
        matched_rules+=("cloud/aws")
    fi

    log_debug "Matched rules: ${matched_rules[*]:-none}"

    # Return unique rules
    printf '%s\n' "${matched_rules[@]}" | sort -u
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

    # Build the activation instruction
    cat <<'EOF'
═══════════════════════════════════════════════════════
🎯 MANDATORY SKILL ACTIVATION - DO NOT SKIP
═══════════════════════════════════════════════════════

CRITICAL: Before implementing ANY code, you MUST follow this 3-step process:

STEP 1: EVALUATE which rules apply (list YES/NO for each category):
EOF

    # List detected context
    if [[ -n "${languages}" ]]; then
        echo "   - Detected Languages: ${languages// /, }"
    fi
    if [[ -n "${frameworks}" ]]; then
        echo "   - Detected Frameworks: ${frameworks// /, }"
    fi

    cat <<EOF

   - Matched Rule Categories:
EOF

    # List matched rules with checkbox format
    while IFS= read -r rule; do
        [[ -n "${rule}" ]] && echo "     [ ] ${rule}"
    done <<< "${matched_rules}"

    cat <<'EOF'

STEP 2: APPLY relevant coding standards

   Based on the evaluation above, apply these coding principles:
   - Code Quality: Write clean, maintainable code
   - Testing: Include comprehensive tests where appropriate
   - Security: Follow security best practices
   - Language Standards: Follow best practices for the detected languages

STEP 3: IMPLEMENT the task following the identified standards

📋 REMINDER:
   - Follow the coding standards for the detected languages/frameworks
   - Include tests where appropriate
   - Consider security implications
   - Write clear, well-documented code

Why this matters:
   - Consistent code quality across the project
   - Security best practices from the start
   - Maintainable, testable code
   - Prevents common anti-patterns

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
    generate_activation_instruction "${prompt}" "${context}"

    log_debug "Activation instruction generated successfully"
    exit 0
}

# Run main function
main "$@"
