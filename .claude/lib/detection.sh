#!/usr/bin/env bash

# lib/detection.sh - Shared project detection logic library
#
# Provides standardized functions for detecting project languages,
# frameworks, cloud providers, and other configuration.
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/../lib/detection.sh"
#   langs=$(detect_language)
#   frameworks=$(detect_frameworks)

# Prevent multiple sourcing
[[ -n "${_LIB_DETECTION_LOADED:-}" ]] && return 0
readonly _LIB_DETECTION_LOADED=1

# Detect project language based on common config files
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

    # C#
    if compgen -G "*.csproj" > /dev/null 2>&1 || compgen -G "*.sln" > /dev/null 2>&1; then
        languages+=("csharp")
    fi

    # Ruby
    if [[ -f "Gemfile" ]]; then
        languages+=("ruby")
    fi

    # Rust
    if [[ -f "Cargo.toml" ]]; then
        languages+=("rust")
    fi

    echo "${languages[@]:-}"
}

# Detect frameworks based on dependencies
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

    echo "${frameworks[@]:-}"
}

# Detect cloud providers
detect_cloud_providers() {
    local providers=()

    # Vercel
    if [[ -f "vercel.json" ]] || [[ -d ".vercel" ]]; then
        providers+=("vercel")
    fi

    # AWS
    if [[ -f ".aws-sam" ]] || [[ -d "cdk.out" ]] || [[ -f "serverless.yml" ]]; then
        providers+=("aws")
    fi

    # Azure
    if [[ -f "azure-pipelines.yml" ]] || [[ -d ".azure" ]]; then
        providers+=("azure")
    fi

    # GCP
    if [[ -f "app.yaml" ]] || [[ -f "cloudbuild.yaml" ]]; then
        providers+=("gcp")
    fi

    echo "${providers[@]:-}"
}

# Detect development tools
detect_tools() {
    local tools=()

    # Beads issue tracker
    if [[ -d ".beads" ]]; then
        tools+=("beads")
    fi

    # Docker
    if [[ -f "Dockerfile" ]] || [[ -f "docker-compose.yml" ]]; then
        tools+=("docker")
    fi

    # GitHub Actions
    if [[ -d ".github/workflows" ]]; then
        tools+=("github-actions")
    fi

    echo "${tools[@]:-}"
}

# Detect AI tools (Claude, Cursor, Copilot, etc.)
detect_ai_tools() {
    local ai_tools=()

    # Claude
    if [[ -d ".claude" ]] || [[ -f ".claude/CLAUDE.md" ]]; then
        ai_tools+=("claude")
    fi

    # Cursor
    if [[ -d ".cursorrules" ]] || [[ -f ".cursorrules" ]]; then
        ai_tools+=("cursor")
    fi

    # GitHub Copilot
    if [[ -f ".github/copilot-instructions.md" ]]; then
        ai_tools+=("copilot")
    fi

    # Gemini/Codegemma
    if [[ -f ".gemini/config.json" ]]; then
        ai_tools+=("gemini")
    fi

    echo "${ai_tools[@]:-}"
}

# Check if file exists and contains pattern
file_contains() {
    local file="$1"
    local pattern="$2"

    [[ -f "$file" ]] && grep -q "$pattern" "$file" 2>/dev/null
}

# Check if any file in list exists
any_file_exists() {
    local file
    for file in "$@"; do
        [[ -f "$file" ]] && return 0
    done
    return 1
}

# Check if directory exists
dir_exists() {
    [[ -d "$1" ]]
}

# Check if language-specific definitive files exist
# Args: language name (e.g., "rust", "python", "javascript")
# Returns: 0 if definitive files exist, 1 otherwise
has_definitive_files() {
    local lang="$1"

    case "$lang" in
        rust)
            [[ -f "Cargo.toml" ]]
            ;;
        python)
            [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || [[ -f "requirements.txt" ]]
            ;;
        javascript|js)
            [[ -f "package.json" ]]
            ;;
        typescript|ts)
            [[ -f "package.json" ]]
            ;;
        go)
            [[ -f "go.mod" ]]
            ;;
        java)
            [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]
            ;;
        csharp|cs)
            compgen -G "*.csproj" > /dev/null 2>&1 || compgen -G "*.sln" > /dev/null 2>&1
            ;;
        ruby)
            [[ -f "Gemfile" ]]
            ;;
        *)
            return 1
            ;;
    esac
}

# Export functions for subshells
export -f detect_language detect_frameworks detect_cloud_providers
export -f detect_tools detect_ai_tools
export -f file_contains any_file_exists dir_exists has_definitive_files
