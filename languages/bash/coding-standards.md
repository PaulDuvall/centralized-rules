# Bash Coding Standards

> **Language:** Bash 4.0+
> **Applies to:** `.sh`, `.bash` files

## Script Header

**Required:**
- Use `#!/usr/bin/env bash`
- Add documentation block (description, usage)
- Set `set -euo pipefail` (exception: sourceable scripts - see [sourceable-scripts.md](./sourceable-scripts.md))

```bash
#!/usr/bin/env bash
# Description: Process input data and generate reports
# Usage: ./process-data.sh <input_dir> <output_dir>

set -euo pipefail
```

## Error Handling

**Required:**
- Use `trap` for cleanup on exit
- Write errors to stderr with descriptive messages
- Check command availability with `command -v`

```bash
log_error() { echo "[ERROR] $*" >&2; }

cleanup() {
    [[ -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
}
trap cleanup EXIT INT TERM

if ! command -v jq &> /dev/null; then
    log_error "jq not installed. Install: brew install jq"
    exit 1
fi
```

## Variables

**Required:**
- Quote all variables: `"$var"` or `"${var}"`
- Use `local` for function variables
- Use `readonly` for constants
- Use `export` only for child processes
- Naming: `UPPER_SNAKE_CASE` constants, `snake_case` variables/functions

**Double quotes**: variables and command substitution
**Single quotes**: literal strings (no expansion)
**Array expansion**: always use `"${array[@]}"`

```bash
readonly MAX_RETRIES=3
readonly CONFIG_DIR="/etc/myapp"

process_file() {
    local file_path="$1"
    local output_file="$2"

    message="Hello, $name"
    output="$(date +%Y-%m-%d)"
    pattern='[0-9]+'

    files=("file1.txt" "file with spaces.txt")
    for file in "${files[@]}"; do
        echo "$file"
    done
}
```

## Code Structure

### Function Design

- Maximum 50 lines per function (warning)
- Single Responsibility Principle - one task per function
- Use `local` for all function variables
- Document: description, parameters, return values
- Return meaningful exit codes (0=success, non-zero=failure)

```bash
validate_file() {
    # Args: $1 - file path
    # Returns: 0 if valid, 1 if invalid
    local file_path="$1"

    if [[ ! -f "$file_path" ]]; then
        echo "Error: File not found: $file_path" >&2
        return 1
    fi
    if [[ ! -r "$file_path" ]]; then
        echo "Error: File not readable: $file_path" >&2
        return 1
    fi
    return 0
}
```

### Script Organization

```bash
#!/usr/bin/env bash
set -euo pipefail
# Script description and usage

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_FILE="${SCRIPT_DIR}/config.conf"
readonly MAX_RETRIES=3
readonly TIMEOUT=30

VERBOSE=false
DRY_RUN=false

log_info() { echo "[INFO] $*"; }
log_error() { echo "[ERROR] $*" >&2; }

process_data() {
    local input="$1"
    # Implementation
}

main() {
    # Parse arguments, validate inputs, execute logic
}

main "$@"
```

## Bash Style

### Naming
- Scripts: `kebab-case.sh`
- Functions/variables: `snake_case`
- Constants: `UPPER_SNAKE_CASE`

### Conditionals
- Use `[[ ]]` (not `[ ]`)
- Use `(( ))` for arithmetic
- Place `then` on same line as `if`

```bash
if [[ -f "$file" ]]; then echo "exists"; fi
if [[ "$string" == "value" ]]; then echo "match"; fi
if [[ "$filename" == *.txt ]]; then echo "text"; fi
if (( count > 10 )); then echo "big"; fi
```

### Command Substitution
- Use `$(command)` not backticks
- Quote substitution: `"$(command)"`

```bash
current_date="$(date +%Y-%m-%d)"
file_count="$(find . -name '*.txt' | wc -l)"
```

## Bash Security

### Input Validation
- Always validate user input before use
- Sanitize file paths to prevent directory traversal
- Validate patterns with regex

```bash
validate_username() {
    local username="$1"
    # Length: 3-32 chars, pattern: alphanumeric + underscore
    if [[ ${#username} -lt 3 || ${#username} -gt 32 ]]; then
        echo "Error: Username must be 3-32 characters" >&2; return 1
    fi
    if [[ ! "$username" =~ ^[a-zA-Z0-9_]+$ ]]; then
        echo "Error: Username can only contain letters, numbers, underscores" >&2; return 1
    fi
    return 0
}

validate_file_path() {
    local file_path="$1" base_dir="$2"
    local absolute_path
    absolute_path=$(realpath "$file_path" 2>/dev/null) || { echo "Error: Invalid path" >&2; return 1; }
    # Prevent directory traversal
    if [[ ! "$absolute_path" =~ ^"$base_dir" ]]; then
        echo "Error: File outside allowed directory" >&2; return 1
    fi
    return 0
}
```

### Command Injection Prevention
- NEVER use `eval`
- NEVER pass unquoted user input to commands
- Use arrays for complex commands

```bash
# SAFE - Properly quoted
ls -la "$user_input"

# SAFE - Array for commands
files=("file1.txt" "file with spaces.txt")
tar_cmd=(tar czf backup.tar.gz "${files[@]}")
"${tar_cmd[@]}"
```

### Secrets Management
- Never hardcode secrets
- Load from environment with validation
- Verify file permissions (600 or 400)

```bash
API_KEY="${API_KEY:-}"
if [[ -z "$API_KEY" ]]; then
    log_error "API_KEY environment variable not set"
    exit 1
fi

# From secure file with permission check
if [[ -f "/etc/secrets/api_key" ]]; then
    API_KEY=$(cat /etc/secrets/api_key)
    perms=$(stat -c %a "/etc/secrets/api_key" 2>/dev/null || stat -f %Lp "/etc/secrets/api_key")
    if [[ "$perms" != "600" && "$perms" != "400" ]]; then
        log_error "Insecure permissions: /etc/secrets/api_key (should be 600 or 400)"
        exit 1
    fi
fi
```

### Temporary Files
- Use `mktemp` for secure file creation
- Always cleanup with trap

```bash
temp_file=$(mktemp) || { log_error "Failed to create temp file"; exit 1; }
trap 'rm -f "$temp_file"' EXIT

temp_dir=$(mktemp -d) || { log_error "Failed to create temp dir"; exit 1; }
trap 'rm -rf "$temp_dir"' EXIT
```

## Linting and Formatting

### ShellCheck
- Required static analysis tool for shell scripts
- Install: `brew install shellcheck` (macOS) or `apt-get install shellcheck` (Linux)

```bash
shellcheck script.sh
shellcheck --shell=bash script.sh
# CI/CD: find . -name "*.sh" -type f -exec shellcheck {} +
```

Configure `.shellcheckrc`:
```bash
shell=bash
# disable=SC2034  # Document why disabling
```

Disable warnings only with documented reason:
```bash
# shellcheck disable=SC2086  # Word splitting intentional here
var=$input
```

## Best Practices

### Parameter Expansion
- Default values: `${var:-default}`
- Remove suffix: `${var%.suffix}`
- Remove prefix: `${var#prefix}`
- Substring: `${var:0:5}`
- Case conversion: `${var^^}` (upper), `${var,,}` (lower)

```bash
output_dir="${OUTPUT_DIR:-/tmp/output}"
name="${filename%.txt}"
extension="${filename##*.}"
upper="${string^^}"
lower="${string,,}"
```

### Prefer Built-ins Over External Commands
- Use parameter expansion instead of pipes
- Use pattern matching instead of grep

```bash
length="${#string}"           # Not: $(echo "$string" | wc -c)
if [[ "$string" == *pattern* ]]; then echo "match"; fi  # Not: grep
```

### Portability
- Detect script directory: `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`
- Detect OS: `[[ "$OSTYPE" == "darwin"* ]]` (macOS) or `[[ "$OSTYPE" == "linux-gnu"* ]]` (Linux)
- Check command availability: `command -v git &> /dev/null`

### Arrays
- Iterate: `for item in "${array[@]}"; do done`
- Length: `${#array[@]}`
- Append: `array+=("new_item")`
- Associative arrays: `declare -A map; map[key]="value"`

```bash
files=("file1" "file2")
for file in "${files[@]}"; do echo "$file"; done
declare -A config
config[host]="localhost"
config[port]="8080"
```

### Argument Parsing
```bash
VERBOSE=false
OUTPUT_DIR="./output"

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose) VERBOSE=true; shift ;;
        -o|--output) OUTPUT_DIR="$2"; shift 2 ;;
        -h|--help) echo "Usage: $0 [-v] [-o DIR]"; exit 0 ;;
        *) echo "Unknown: $1" >&2; exit 1 ;;
    esac
done

[[ ! -d "$OUTPUT_DIR" ]] && { echo "Error: Output dir missing" >&2; exit 1; }
```

## Testing

See [testing.md](./testing.md) for Bash testing guidelines using bats-core.

## References

- [ShellCheck](https://www.shellcheck.net/)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [Bash Reference Manual](https://www.gnu.org/software/bash/manual/bash.html)
