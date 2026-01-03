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

# Read file directly (bash 3.2 compatible - no caching)
# Usage: read_file_cached "package.json"
# Note: Function name kept for backward compatibility, but caching removed
# for bash 3.2 compatibility (no associative arrays)
read_file_cached() {
    local file="$1"

    # Return empty if file doesn't exist
    [[ ! -f "$file" ]] && return 1

    # Read file content directly
    cat "$file" 2>/dev/null
    return 0
}

# Check if file content contains pattern
# Usage: cached_file_contains "package.json" '"react"'
# Note: Function name kept for backward compatibility, but no longer uses caching
cached_file_contains() {
    local file="$1"
    local pattern="$2"
    local content

    content=$(read_file_cached "$file") || return 1
    echo "$content" | grep -q "$pattern" 2>/dev/null
}

# Detect project language based on common config files
detect_language() {
    local languages=()

    # Python
    if [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || [[ -f "requirements.txt" ]]; then
        languages+=("python")
    fi

    # TypeScript/JavaScript
    if [[ -f "package.json" ]]; then
        if cached_file_contains "package.json" '"typescript"'; then
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
    if [[ -f "requirements.txt" ]]; then
        cached_file_contains "requirements.txt" "django" && frameworks+=("django")
        cached_file_contains "requirements.txt" "fastapi" && frameworks+=("fastapi")
        cached_file_contains "requirements.txt" "flask" && frameworks+=("flask")
    fi
    if [[ -f "pyproject.toml" ]]; then
        cached_file_contains "pyproject.toml" "django" && frameworks+=("django")
        cached_file_contains "pyproject.toml" "fastapi" && frameworks+=("fastapi")
        cached_file_contains "pyproject.toml" "flask" && frameworks+=("flask")
    fi

    # JavaScript/TypeScript frameworks
    if [[ -f "package.json" ]]; then
        cached_file_contains "package.json" '"react"' && frameworks+=("react")
        cached_file_contains "package.json" '"next"' && frameworks+=("nextjs")
        cached_file_contains "package.json" '"vue"' && frameworks+=("vue")
        cached_file_contains "package.json" '"express"' && frameworks+=("express")
        cached_file_contains "package.json" '"nestjs"' && frameworks+=("nestjs")
    fi

    # Go frameworks
    if [[ -f "go.mod" ]]; then
        cached_file_contains "go.mod" "gin-gonic/gin" && frameworks+=("gin")
        cached_file_contains "go.mod" "gofiber/fiber" && frameworks+=("fiber")
    fi

    # Java frameworks
    if [[ -f "pom.xml" ]]; then
        cached_file_contains "pom.xml" "spring-boot" && frameworks+=("springboot")
    fi
    if [[ -f "build.gradle" ]]; then
        cached_file_contains "build.gradle" "spring-boot" && frameworks+=("springboot")
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

# Export functions for subshells
export -f read_file_cached cached_file_contains
export -f detect_language detect_frameworks detect_cloud_providers
export -f detect_tools detect_ai_tools
export -f file_contains any_file_exists dir_exists
