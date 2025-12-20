#!/bin/bash
# Check for broken file references in JSON configuration files
set -e

ERROR_FILE=$(mktemp)
echo "0" > "$ERROR_FILE"
WARN_FILE=$(mktemp)
echo "0" > "$WARN_FILE"

trap 'rm -f "$ERROR_FILE" "$WARN_FILE"' EXIT

echo "🔍 Checking JSON file references..."
echo "=========================================="

# Function to increment error count
increment_errors() {
    local current
    current=$(cat "$ERROR_FILE")
    echo $((current + 1)) > "$ERROR_FILE"
}

# Function to increment warning count
increment_warnings() {
    local current
    current=$(cat "$WARN_FILE")
    echo $((current + 1)) > "$WARN_FILE"
}

# Function to check if a path exists (file or directory)
check_path() {
    local path=$1
    local source=$2
    if [ ! -e "$path" ]; then
        echo "❌ BROKEN: $path (referenced in $source)"
        increment_errors
        return 1
    else
        echo "✓ $path"
        return 0
    fi
}

# Check .claude/rules/index.json
if [ -f ".claude/rules/index.json" ]; then
    echo ""
    echo "Checking .claude/rules/index.json..."
    echo "----------------------------------------"

    # Extract all "file" values and check they exist
    jq -r '.rules.base[]?.file // empty' .claude/rules/index.json 2>/dev/null | while read -r path; do
        if [ -n "$path" ]; then
            check_path "$path" ".claude/rules/index.json" || true
        fi
    done

    # Also check languages and frameworks if they exist
    jq -r '.rules.languages[][]?.file // empty' .claude/rules/index.json 2>/dev/null | while read -r path; do
        if [ -n "$path" ]; then
            check_path "$path" ".claude/rules/index.json" || true
        fi
    done

    jq -r '.rules.frameworks[][]?.file // empty' .claude/rules/index.json 2>/dev/null | while read -r path; do
        if [ -n "$path" ]; then
            check_path "$path" ".claude/rules/index.json" || true
        fi
    done
else
    echo "⚠️  WARNING: .claude/rules/index.json not found"
    increment_warnings
fi

# Check .claude/skills/skill-rules.json
if [ -f ".claude/skills/skill-rules.json" ]; then
    echo ""
    echo "Checking .claude/skills/skill-rules.json..."
    echo "----------------------------------------"

    # Extract unique rule paths (these can be files or directories)
    jq -r '.. | select(type=="object") | .rules[]? // empty' .claude/skills/skill-rules.json 2>/dev/null | sort -u | while read -r rule_path; do
        if [ -n "$rule_path" ]; then
            # Check if the path exists as-is (could be directory or file)
            if [ -e "$rule_path" ] || [ -e "${rule_path}.md" ]; then
                if [ -e "$rule_path" ]; then
                    echo "✓ $rule_path"
                else
                    echo "✓ ${rule_path}.md"
                fi
            else
                echo "❌ BROKEN: $rule_path (or ${rule_path}.md) not found (referenced in skill-rules.json)"
                increment_errors
            fi
        fi
    done
else
    echo "⚠️  WARNING: .claude/skills/skill-rules.json not found"
    increment_warnings
fi

# Get final counts
errors=$(cat "$ERROR_FILE")
warnings=$(cat "$WARN_FILE")

echo ""
echo "=========================================="
echo "Summary:"
echo "  Errors: $errors"
echo "  Warnings: $warnings"
echo "=========================================="

if [ "$errors" -gt 0 ]; then
    echo "❌ Found $errors broken file reference(s)"
    exit 1
else
    echo "✅ All file references are valid"
    exit 0
fi
