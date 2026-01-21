#!/usr/bin/env bash

# lib/override.sh - Local override support for centralized rules
#
# Provides functions for project-level rule customization:
# - Local override detection (.claude/rules-local/)
# - Configuration loading (rules-config.local.json)
# - Merge strategies (extend, replace, prepend)
# - Rule exclusion via patterns
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/../lib/override.sh"
#   process_overrides "$CLAUDE_DIR"

# Prevent multiple sourcing
[[ -n "${_LIB_OVERRIDE_LOADED:-}" ]] && return 0
readonly _LIB_OVERRIDE_LOADED=1

# Valid merge strategies
readonly VALID_STRATEGIES="extend replace prepend"
readonly DEFAULT_STRATEGY="extend"

# Detect if local overrides directory exists
# Args: $1 = claude directory path (e.g., .claude)
# Returns: "true" or "false"
detect_local_overrides() {
    local claude_dir="$1"
    local override_dir="${claude_dir}/rules-local"

    if [[ -d "$override_dir" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Load override configuration from JSON file
# Args: $1 = claude directory path
# Returns: JSON content or empty string
load_override_config() {
    local claude_dir="$1"
    local config_file="${claude_dir}/rules-config.local.json"

    if [[ -f "$config_file" ]]; then
        cat "$config_file"
    else
        echo ""
    fi
}

# Validate override configuration
# Args: $1 = config JSON string
# Returns: 0 if valid, 1 if invalid
validate_override_config() {
    local config="$1"

    # Empty config is valid (uses defaults)
    [[ -z "$config" ]] && return 0

    # Check if valid JSON using Python (available on most systems)
    if ! echo "$config" | python3 -c "import sys, json; json.load(sys.stdin)" 2>/dev/null; then
        return 1
    fi

    # Extract and validate merge_strategy if present
    local strategy
    strategy=$(extract_json_string "$config" "merge_strategy")
    if [[ -n "$strategy" ]] && ! is_valid_strategy "$strategy"; then
        return 1
    fi

    return 0
}

# Check if strategy is valid
# Args: $1 = strategy name
is_valid_strategy() {
    local strategy="$1"
    [[ " $VALID_STRATEGIES " == *" $strategy "* ]]
}

# Extract a string value from JSON (simple extraction)
# Args: $1 = JSON string, $2 = key name
extract_json_string() {
    local json="$1"
    local key="$2"

    echo "$json" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('$key', ''))
except:
    pass
" 2>/dev/null
}

# Extract array from JSON
# Args: $1 = JSON string, $2 = key name
extract_json_array() {
    local json="$1"
    local key="$2"

    echo "$json" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    arr = data.get('$key', [])
    for item in arr:
        print(item)
except:
    pass
" 2>/dev/null
}

# Get merge strategy for a rule path
# Args: $1 = rule path (e.g., base/testing.md), $2 = config JSON
# Returns: strategy name
get_merge_strategy() {
    local rule_path="$1"
    local config="$2"

    # Default strategy if no config
    if [[ -z "$config" ]]; then
        echo "$DEFAULT_STRATEGY"
        return
    fi

    # Check for specific override matching this path
    local override_strategy
    override_strategy=$(get_override_for_path "$rule_path" "$config")

    if [[ -n "$override_strategy" ]]; then
        echo "$override_strategy"
        return
    fi

    # Fall back to default strategy from config or global default
    local default
    default=$(extract_json_string "$config" "merge_strategy")
    echo "${default:-$DEFAULT_STRATEGY}"
}

# Get override strategy for a specific path (supports globs)
# Args: $1 = rule path, $2 = config JSON
get_override_for_path() {
    local rule_path="$1"
    local config="$2"

    echo "$config" | python3 -c "
import sys, json, fnmatch
try:
    data = json.load(sys.stdin)
    overrides = data.get('overrides', {})
    rule_path = '$rule_path'

    # Check exact match first
    if rule_path in overrides:
        print(overrides[rule_path])
        sys.exit(0)

    # Check glob patterns
    for pattern, strategy in overrides.items():
        if fnmatch.fnmatch(rule_path, pattern):
            print(strategy)
            sys.exit(0)
except SystemExit:
    raise
except Exception:
    pass
" 2>/dev/null
}

# Check if a rule should be excluded
# Args: $1 = rule path, $2 = config JSON
# Returns: "true" or "false"
should_exclude_rule() {
    local rule_path="$1"
    local config="$2"

    # No config means no exclusions
    [[ -z "$config" ]] && echo "false" && return

    local result
    result=$(echo "$config" | python3 -c "
import sys, json, fnmatch
try:
    data = json.load(sys.stdin)
    excludes = data.get('exclude', [])
    rule_path = '$rule_path'

    for pattern in excludes:
        if fnmatch.fnmatch(rule_path, pattern):
            print('true')
            sys.exit(0)
    print('false')
except SystemExit:
    raise
except Exception:
    print('false')
" 2>/dev/null)

    echo "${result:-false}"
}

# Merge rule content using specified strategy
# Args: $1 = central content, $2 = local content, $3 = strategy
# Returns: merged content
merge_rule_content() {
    local central="$1"
    local local_content="$2"
    local strategy="$3"

    case "$strategy" in
        replace)
            echo "$local_content"
            ;;
        prepend)
            echo "$local_content"
            echo ""
            echo "$central"
            ;;
        extend|*)
            echo "$central"
            echo ""
            echo "$local_content"
            ;;
    esac
}

# Process all overrides in a claude directory
# Args: $1 = claude directory path
process_overrides() {
    local claude_dir="$1"
    local override_dir="${claude_dir}/rules-local"
    local rules_dir="${claude_dir}/rules"

    # Guard: skip if no overrides directory
    if [[ "$(detect_local_overrides "$claude_dir")" != "true" ]]; then
        return 0
    fi

    # Load and validate config
    local config
    config=$(load_override_config "$claude_dir")
    if ! validate_override_config "$config"; then
        echo "ERROR: Invalid rules-config.local.json" >&2
        return 1
    fi

    # Process each local override file
    process_override_files "$override_dir" "$rules_dir" "$config"
}

# Process override files recursively
# Args: $1 = override dir, $2 = rules dir, $3 = config
process_override_files() {
    local override_dir="$1"
    local rules_dir="$2"
    local config="$3"

    # Find all .md files, excluding hidden files
    while IFS= read -r -d '' local_file; do
        process_single_override "$local_file" "$override_dir" "$rules_dir" "$config"
    done < <(find "$override_dir" -name "*.md" -type f ! -name ".*" -print0 2>/dev/null)
}

# Process a single override file
# Args: $1 = local file, $2 = override dir, $3 = rules dir, $4 = config
process_single_override() {
    local local_file="$1"
    local override_dir="$2"
    local rules_dir="$3"
    local config="$4"

    # Get relative path from override dir
    local rel_path="${local_file#"$override_dir"/}"

    # Skip if excluded
    if [[ "$(should_exclude_rule "$rel_path" "$config")" == "true" ]]; then
        return 0
    fi

    local central_file="${rules_dir}/${rel_path}"
    local strategy
    strategy=$(get_merge_strategy "$rel_path" "$config")

    # Ensure target directory exists
    mkdir -p "$(dirname "$central_file")"

    # Get content
    local local_content central_content
    local_content=$(cat "$local_file")

    if [[ -f "$central_file" ]]; then
        central_content=$(cat "$central_file")
        local merged
        merged=$(merge_rule_content "$central_content" "$local_content" "$strategy")
        echo "$merged" > "$central_file"
    else
        # No central file - just copy local
        echo "$local_content" > "$central_file"
    fi
}

# Export functions
export -f detect_local_overrides load_override_config validate_override_config
export -f get_merge_strategy should_exclude_rule merge_rule_content
export -f process_overrides
