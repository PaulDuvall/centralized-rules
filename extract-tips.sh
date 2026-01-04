#!/usr/bin/env bash
# Extract tips from rule markdown files and update skill-rules.json

set -euo pipefail

# Extract tip from a markdown file
extract_tip() {
    local file="$1"
    grep -oP '<!-- TIP: \K[^-]+(?= -->)' "$file" 2>/dev/null | head -1 || echo ""
}

# Update skill-rules.json with extracted tips
update_json() {
    local json_file=".claude/skills/skill-rules.json"

    if [[ ! -f "$json_file" ]]; then
        echo "Error: $json_file not found"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        echo "Error: jq is required but not installed"
        exit 1
    fi

    echo "Extracting tips from rule files..."

    # Base rules
    for category in testing security git refactoring architecture metrics cicd development; do
        local file=""
        case "$category" in
            testing) file="base/testing-philosophy.md" ;;
            security) file="base/security-principles.md" ;;
            git) file="base/git-workflow.md" ;;
            refactoring) file="base/refactoring-patterns.md" ;;
            architecture) file="base/architecture-principles.md" ;;
            metrics) file="base/metrics-standards.md" ;;
            cicd) file="base/cicd-comprehensive.md" ;;
            development) file="base/development-workflow.md" ;;
        esac

        if [[ -f "$file" ]]; then
            local tip
            tip=$(extract_tip "$file")
            if [[ -n "$tip" ]]; then
                echo "  $category: $tip"
                jq ".keywordMappings.base.$category.tip = \"$tip\"" "$json_file" > "$json_file.tmp" && mv "$json_file.tmp" "$json_file"
            fi
        fi
    done

    # Language rules
    for lang in python typescript bash rust go java; do
        local file="languages/$lang/coding-standards.md"
        if [[ -f "$file" ]]; then
            local tip
            tip=$(extract_tip "$file")
            if [[ -n "$tip" ]]; then
                echo "  languages/$lang: $tip"
                jq ".keywordMappings.languages.$lang.tip = \"$tip\"" "$json_file" > "$json_file.tmp" && mv "$json_file.tmp" "$json_file"
            fi
        fi
    done

    # Framework rules
    for framework in react fastapi django express; do
        local file="frameworks/$framework/best-practices.md"
        local parent_lang=""

        case "$framework" in
            react|express) parent_lang="typescript" ;;
            fastapi|django) parent_lang="python" ;;
        esac

        if [[ -f "$file" && -n "$parent_lang" ]]; then
            local tip
            tip=$(extract_tip "$file")
            if [[ -n "$tip" ]]; then
                echo "  frameworks/$framework: $tip"
                jq ".keywordMappings.languages.$parent_lang.frameworks.$framework.tip = \"$tip\"" "$json_file" > "$json_file.tmp" && mv "$json_file.tmp" "$json_file"
            fi
        fi
    done

    echo "✓ Tips extracted and updated in $json_file"
}

update_json
