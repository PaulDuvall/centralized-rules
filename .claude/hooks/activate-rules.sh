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

    # Test-related keywords (including slash commands)
    if echo "${prompt_lower}" | grep -qE '(test|pytest|unittest|spec|tdd|coverage|mock)'; then
        matched_rules+=("base/testing-philosophy")
    # Detect test-related slash commands (e.g., /xtest, /test)
    elif echo "${prompt_lower}" | grep -qE '/(x?test|x?tdd)(\s|$)'; then
        matched_rules+=("base/testing-philosophy")
    fi

    # Security keywords (including slash commands)
    if echo "${prompt_lower}" | grep -qE '(auth|security|password|token|jwt|oauth|permission|encrypt|hash|sanitize|validate|injection)'; then
        matched_rules+=("base/security-principles")
    # Detect security-related slash commands (e.g., /xsecurity, /security)
    elif echo "${prompt_lower}" | grep -qE '/(x?security|x?audit)(\s|$)'; then
        matched_rules+=("base/security-principles")
    fi

    # Git/commit keywords (including slash commands)
    # Detect both explicit keywords and slash commands that imply git operations
    if echo "${prompt_lower}" | grep -qE '(commit|pull request|pr|merge|branch|push|rebase|cherry-pick)'; then
        matched_rules+=("base/git-workflow")
    # Detect git-related slash commands (e.g., /xgit, /commit, /xcommit, /git)
    elif echo "${prompt_lower}" | grep -qE '/(x?git|x?commit|push)(\s|$)'; then
        matched_rules+=("base/git-workflow")
    fi

    # Refactoring keywords (including slash commands)
    if echo "${prompt_lower}" | grep -qE '(refactor|clean|improve|optimize|simplify|restructure)'; then
        matched_rules+=("base/refactoring-patterns")
    # Detect refactoring-related slash commands (e.g., /xrefactor, /xquality)
    elif echo "${prompt_lower}" | grep -qE '/(x?refactor|x?quality|x?optimize)(\s|$)'; then
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

    # Beads/issue tracking keywords
    if echo "${prompt_lower}" | grep -qE '(beads|beas|bd-[0-9]+|\bbd\b|issue.track|session (start|end)|create.*(issue|task)|close.*(issue|task))'; then
        matched_rules+=("tools/beads/issue-tracking")
    fi

    log_debug "Matched rules: ${matched_rules[*]:-none}"

    # Return unique rules (handle empty array)
    if [[ ${#matched_rules[@]} -gt 0 ]]; then
        printf '%s\n' "${matched_rules[@]}" | sort -u
    fi
}

# Check if prompt indicates git operation (commit/push intent)
is_git_operation() {
    local prompt_lower="$1"

    # Check for git keywords
    if echo "${prompt_lower}" | grep -qE '(commit|push|pull request|pr|merge|branch|rebase|cherry-pick|git add)'; then
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

    # Get current commit hash for version tracking
    local commit_hash
    commit_hash=$(git -C "${CLAUDE_PROJECT_DIR:-.}" rev-parse --short HEAD 2>/dev/null || echo "unknown")

    local repo_name="paulduvall/centralized-rules"
    local repo_url="https://github.com/${repo_name}"

    # Build the activation instruction
    cat <<EOF
═══════════════════════════════════════════════════════
🎯 SKILL ACTIVATION - Centralized Rules Loaded
═══════════════════════════════════════════════════════
📦 Source: ${repo_name}
🔗 Repo: ${repo_url}
📌 Commit: ${commit_hash}
───────────────────────────────────────────────────────
EOF

    # Add pre-commit quality gates if this is a git operation
    if [[ "${is_git_op}" == "true" ]]; then
        cat <<'EOF'

🚦 PRE-COMMIT QUALITY GATES DETECTED
───────────────────────────────────────────────────────
⚠️  IMPORTANT: Before committing/pushing, run these checks:

REQUIRED CHECKS (run in this order):
  1️⃣  Run tests        - Ensure all tests pass
  2️⃣  Security scan    - Check for vulnerabilities
  3️⃣  Code quality     - Verify code meets standards
  4️⃣  Refactoring      - Check for code smells

💡 Workflow:
   • Announce: "Running pre-commit checks..."
   • Execute each check and report results
   • Only proceed with commit/push if ALL checks pass
   • If any check fails, fix issues before committing

───────────────────────────────────────────────────────
EOF
    fi

    cat <<'EOF'

📚 Before implementing, follow this 3-step process:

STEP 1: 🔍 EVALUATE which rules apply
EOF

    # List detected context
    if [[ -n "${languages}" ]]; then
        echo "   🔹 Detected Languages: ${languages// /, }"
    fi
    if [[ -n "${frameworks}" ]]; then
        echo "   🔹 Detected Frameworks: ${frameworks// /, }"
    fi

    cat <<EOF

   📋 Matched Rule Categories:
EOF

    # List matched rules with checkbox format
    while IFS= read -r rule; do
        [[ -n "${rule}" ]] && echo "     ☐ ${rule}"
    done <<< "${matched_rules}"

    cat <<'EOF'

STEP 2: 🔧 APPLY relevant coding standards

   Based on the evaluation above, apply these coding principles:
   ✓ Code Quality: Write clean, maintainable code
   ✓ Testing: Include comprehensive tests where appropriate
   ✓ Security: Follow security best practices
   ✓ Language Standards: Follow best practices for the detected languages

STEP 3: ⚡ IMPLEMENT the task following the identified standards

💡 REMINDER:
   • Follow the coding standards for the detected languages/frameworks
   • Include tests where appropriate
   • Consider security implications
   • Write clear, well-documented code

🎯 Why this matters:
   • Consistent code quality across the project
   • Security best practices from the start
   • Maintainable, testable code
   • Prevents common anti-patterns

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
