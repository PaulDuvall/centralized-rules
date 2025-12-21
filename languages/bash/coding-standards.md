# Bash/Shell Scripting Coding Standards

> **Language:** Bash 4.0+ (POSIX-compatible where possible)
> **Applies to:** All shell scripts (.sh, .bash)

## Shell-Specific Standards

### Script Header and Shebang

- **Always use explicit shebang** - Never rely on default shell
- **Use `#!/usr/bin/env bash`** for portability (finds bash in PATH)
- **Include script documentation** at the top of every script
- **Set strict error handling** with `set -euo pipefail`

**Example:**
```bash
#!/usr/bin/env bash
#
# Script Name: process-data.sh
# Description: Process input data files and generate reports
# Usage: ./process-data.sh <input_dir> <output_dir>
# Author: Your Name
# Version: 1.0.0
#

set -euo pipefail  # Exit on error, undefined vars, pipe failures
```

### Error Handling

- **ALWAYS use `set -euo pipefail`** at the start of scripts
  - `-e`: Exit immediately if a command exits with non-zero status
  - `-u`: Treat unset variables as an error
  - `-o pipefail`: Return exit status of the last command in a pipe that failed
- **Check command exit status** for critical operations
- **Provide descriptive error messages** with remediation guidance
- **Use trap for cleanup** on script exit

**Example:**
```bash
#!/usr/bin/env bash
set -euo pipefail

# Logging functions
log_error() { echo "[ERROR] $*" >&2; }
log_info() { echo "[INFO] $*"; }

# Cleanup function
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Script failed with exit code: $exit_code"
    fi
    # Clean up temp files
    [[ -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
    exit "$exit_code"
}

# Register cleanup on exit
trap cleanup EXIT INT TERM

# Check if required command exists
if ! command -v jq &> /dev/null; then
    log_error "jq is not installed"
    log_error "Remediation: Install with 'brew install jq' (macOS) or 'apt-get install jq' (Linux)"
    exit 1
fi

# Validate required arguments
if [[ $# -lt 2 ]]; then
    log_error "Missing required arguments"
    echo "Usage: $0 <input_dir> <output_dir>" >&2
    exit 1
fi
```

### Variable Handling

- **Always quote variables** to prevent word splitting: `"$var"`
- **Use braces for clarity** when needed: `"${var}"`
- **Declare variables with proper scope**:
  - `local` for function variables
  - `readonly` for constants
  - `export` only when needed by child processes
- **Initialize variables** explicitly - never rely on defaults
- **Use meaningful variable names** in `UPPER_CASE` for constants, `lower_case` for variables

**Example:**
```bash
# ❌ Unquoted variables (word splitting risk!)
for file in $FILES; do
    process $file
done

# ✅ Properly quoted
for file in "$FILES"; do
    process "$file"
done

# ✅ Constants
readonly MAX_RETRIES=3
readonly CONFIG_DIR="/etc/myapp"

# ✅ Local variables in functions
process_file() {
    local file_path="$1"
    local file_name
    file_name=$(basename "$file_path")

    echo "Processing: $file_name"
}
```

### Quoting Rules

- **Double quotes `""`**: Use for variables and command substitution
- **Single quotes `''`**: Use for literal strings (no expansion)
- **No quotes**: Only for arithmetic expressions and specific builtins
- **Array expansion**: Use `"${array[@]}"` to preserve elements

**Example:**
```bash
# ✅ Variable substitution with double quotes
message="Hello, $name"
output="$(date +%Y-%m-%d)"

# ✅ Literal strings with single quotes
pattern='[0-9]+'
sql='SELECT * FROM users WHERE id = $1'

# ✅ Array handling
files=("file1.txt" "file with spaces.txt" "file3.txt")
for file in "${files[@]}"; do
    echo "$file"
done

# ❌ WRONG - Will break on spaces
for file in ${files[@]}; do  # Missing quotes!
    echo $file
done
```

## Code Structure

### Function Design

- **Maximum 50 lines per function** (severity: warning)
- **Single Responsibility Principle** - Each function does one thing
- **Always use `local` for function variables**
- **Document functions** with description, parameters, and return values
- **Return meaningful exit codes** (0=success, non-zero=failure)

**Example:**
```bash
# ✅ Well-structured function
validate_file() {
    # Description: Validate that file exists and is readable
    # Arguments:
    #   $1 - File path to validate
    # Returns:
    #   0 if file is valid
    #   1 if file doesn't exist or isn't readable
    # Outputs:
    #   Error message to stderr if validation fails

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

# Usage
if validate_file "/path/to/file.txt"; then
    echo "File is valid"
else
    echo "File validation failed"
    exit 1
fi
```

### Script Organization

```bash
#!/usr/bin/env bash
set -euo pipefail

#
# Script description and usage
#

# ===== CONFIGURATION =====
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_FILE="${SCRIPT_DIR}/config.conf"

# ===== CONSTANTS =====
readonly MAX_RETRIES=3
readonly TIMEOUT=30

# ===== GLOBAL VARIABLES =====
VERBOSE=false
DRY_RUN=false

# ===== UTILITY FUNCTIONS =====
log_info() { echo "[INFO] $*"; }
log_error() { echo "[ERROR] $*" >&2; }

# ===== CORE FUNCTIONS =====
process_data() {
    local input="$1"
    # Implementation
}

# ===== MAIN EXECUTION =====
main() {
    # Parse arguments
    # Validate inputs
    # Execute core logic
    # Handle cleanup
}

# Run main function with all arguments
main "$@"
```

## Bash Style Guidelines

### Naming Conventions

- **Scripts:** `kebab-case.sh` (e.g., `process-data.sh`)
- **Functions:** `snake_case` (e.g., `process_file`)
- **Variables:** `snake_case` (e.g., `file_path`)
- **Constants:** `UPPER_SNAKE_CASE` (e.g., `MAX_RETRIES`)
- **Environment variables:** `UPPER_SNAKE_CASE` (e.g., `PATH`, `HOME`)

**Example:**
```bash
# Constants
readonly DEFAULT_TIMEOUT=30
readonly CONFIG_DIR="/etc/myapp"

# Function
process_user_data() {
    local user_name="$1"
    local output_file="$2"
    # Implementation
}
```

### Conditional Expressions

- **Use `[[ ]]` (bash builtin) instead of `[ ]`** (more features, safer)
- **Use `(( ))` for arithmetic** comparisons
- **Put `then` on the same line as `if`** for consistency

**Example:**
```bash
# ✅ Modern bash conditionals
if [[ -f "$file" ]]; then
    echo "File exists"
fi

if [[ "$string" == "value" ]]; then
    echo "Match found"
fi

# ✅ Pattern matching
if [[ "$filename" == *.txt ]]; then
    echo "Text file"
fi

# ✅ Arithmetic comparison
if (( count > 10 )); then
    echo "Count is greater than 10"
fi

# ❌ Old POSIX style (less safe)
if [ -f "$file" ]; then  # Works, but [[ ]] is better
    echo "File exists"
fi
```

### Command Substitution

- **Use `$(command)` instead of backticks**
- **Quote command substitution** unless you specifically want word splitting

**Example:**
```bash
# ✅ Modern command substitution
current_date=$(date +%Y-%m-%d)
file_count=$(find . -name "*.txt" | wc -l)

# ❌ Old backtick syntax (harder to nest)
current_date=`date +%Y-%m-%d`
```

## Bash Security

### Input Validation

- **Always validate user input** before use
- **Sanitize file paths** to prevent directory traversal
- **Validate expected patterns** using regex
- **Never trust external input**

**Example:**
```bash
validate_username() {
    local username="$1"

    # Check length
    if [[ ${#username} -lt 3 || ${#username} -gt 32 ]]; then
        echo "Error: Username must be 3-32 characters" >&2
        return 1
    fi

    # Check pattern (alphanumeric and underscore only)
    if [[ ! "$username" =~ ^[a-zA-Z0-9_]+$ ]]; then
        echo "Error: Username can only contain letters, numbers, and underscores" >&2
        return 1
    fi

    return 0
}

# Validate file path
validate_file_path() {
    local file_path="$1"
    local base_dir="$2"

    # Get absolute path
    local absolute_path
    absolute_path=$(realpath "$file_path" 2>/dev/null) || {
        echo "Error: Invalid file path" >&2
        return 1
    }

    # Ensure it's within base directory (prevent directory traversal)
    if [[ ! "$absolute_path" =~ ^"$base_dir" ]]; then
        echo "Error: File path outside allowed directory" >&2
        return 1
    fi

    return 0
}
```

### Avoiding Command Injection

- **NEVER use `eval`** - It executes arbitrary code
- **NEVER pass user input directly to shell** commands
- **Use arrays for command arguments** instead of string concatenation
- **Quote all variables** in commands

**Example:**
```bash
# ❌ DANGEROUS - Command injection risk!
user_input="$1"
eval "ls -la $user_input"  # User could input "; rm -rf /"

# ❌ DANGEROUS - Still vulnerable
ls -la $user_input  # Unquoted variable

# ✅ SAFE - Properly quoted
ls -la "$user_input"

# ✅ SAFE - Using array for complex commands
files=("file1.txt" "file2.txt" "file with spaces.txt")
tar_cmd=(tar czf backup.tar.gz "${files[@]}")
"${tar_cmd[@]}"
```

### Never Hardcode Secrets

```bash
# ❌ Hardcoded secret
API_KEY="sk-1234567890abcdef"

# ✅ Environment variable with validation
API_KEY="${API_KEY:-}"
if [[ -z "$API_KEY" ]]; then
    log_error "API_KEY environment variable not set"
    log_error "Remediation: export API_KEY=<your-key> or add to .env file"
    exit 1
fi

# ✅ Read from secure file with proper permissions
if [[ -f "/etc/secrets/api_key" ]]; then
    API_KEY=$(cat /etc/secrets/api_key)
    # Verify file permissions are secure (600 or 400)
    perms=$(stat -c %a "/etc/secrets/api_key" 2>/dev/null || stat -f %Lp "/etc/secrets/api_key")
    if [[ "$perms" != "600" && "$perms" != "400" ]]; then
        log_error "Insecure permissions on /etc/secrets/api_key (should be 600 or 400)"
        exit 1
    fi
fi
```

### Safe Temporary Files

```bash
# ✅ Create secure temporary file
temp_file=$(mktemp) || {
    log_error "Failed to create temporary file"
    exit 1
}

# Always cleanup temp files
trap 'rm -f "$temp_file"' EXIT

# ✅ Create secure temporary directory
temp_dir=$(mktemp -d) || {
    log_error "Failed to create temporary directory"
    exit 1
}

trap 'rm -rf "$temp_dir"' EXIT
```

## Bash Linting and Formatting

### Required Tools

- **ShellCheck** - Static analysis tool for shell scripts
  - Detects common mistakes and anti-patterns
  - Provides actionable warnings and suggestions
  - Supports Bash, sh, ksh

### ShellCheck Integration

```bash
# Install ShellCheck
# macOS:
brew install shellcheck

# Linux:
apt-get install shellcheck  # Debian/Ubuntu
yum install ShellCheck      # RHEL/CentOS

# Run ShellCheck on script
shellcheck script.sh

# Run with specific shell dialect
shellcheck --shell=bash script.sh

# Exclude specific warnings (use sparingly)
shellcheck --exclude=SC2034,SC2086 script.sh

# CI/CD integration
find . -name "*.sh" -type f -exec shellcheck {} +
```

### ShellCheck Configuration

Create `.shellcheckrc` in project root:

```bash
# Specify shell dialect
shell=bash

# Exclude specific checks (document why!)
# SC2034 = unused variable (sometimes needed for sourced scripts)
# disable=SC2034

# Source additional files for analysis
# source-path=SCRIPTDIR
```

### Disabling ShellCheck Warnings

Only disable warnings when you understand them and have a valid reason:

```bash
# Disable for specific line
# shellcheck disable=SC2086
var=$input  # Intentionally unquoted for word splitting

# Disable for block
# shellcheck disable=SC2155
export var=$(get_value)

# Document why you're disabling
# shellcheck disable=SC2046  # Word splitting intentional here
for file in $(cat file_list.txt); do
    process "$file"
done
```

## Bash Best Practices

### Use Modern Bash Features

```bash
# ✅ Parameter expansion for default values
output_dir="${OUTPUT_DIR:-/tmp/output}"

# ✅ String manipulation
filename="example.txt"
name="${filename%.txt}"      # Remove extension: "example"
extension="${filename##*.}"  # Get extension: "txt"

# ✅ Substring operations
string="Hello World"
echo "${string:0:5}"  # "Hello"
echo "${string:6}"    # "World"

# ✅ Case conversion (Bash 4.0+)
upper="${string^^}"   # "HELLO WORLD"
lower="${string,,}"   # "hello world"
```

### Prefer Built-ins Over External Commands

```bash
# ❌ Using external command
length=$(echo "$string" | wc -c)

# ✅ Using parameter expansion
length="${#string}"

# ❌ Using grep
if echo "$string" | grep -q "pattern"; then
    echo "Match found"
fi

# ✅ Using pattern matching
if [[ "$string" == *pattern* ]]; then
    echo "Match found"
fi
```

### Portable Script Writing

```bash
# Detect the script's directory reliably
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    echo "Running on macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    echo "Running on Linux"
fi

# Check for command availability
if command -v git &> /dev/null; then
    echo "git is available"
fi
```

### Array Usage

```bash
# ✅ Declare and use arrays
files=("file1.txt" "file2.txt" "file with spaces.txt")

# Iterate over array
for file in "${files[@]}"; do
    echo "Processing: $file"
done

# Array length
echo "Number of files: ${#files[@]}"

# Add to array
files+=("file4.txt")

# Associative arrays (Bash 4.0+)
declare -A config
config[host]="localhost"
config[port]="8080"

echo "${config[host]}:${config[port]}"
```

### Argument Parsing

```bash
#!/usr/bin/env bash
set -euo pipefail

# Default values
VERBOSE=false
OUTPUT_DIR="./output"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [-v|--verbose] [-o|--output DIR]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ ! -d "$OUTPUT_DIR" ]]; then
    echo "Error: Output directory does not exist: $OUTPUT_DIR" >&2
    exit 1
fi
```

## Bash Testing

See [testing.md](./testing.md) for detailed Bash testing guidelines using bats-core and other testing frameworks.

## References

- **ShellCheck** - https://www.shellcheck.net/
- **Google Shell Style Guide** - https://google.github.io/styleguide/shellguide.html
- **Bash Reference Manual** - https://www.gnu.org/software/bash/manual/
- **Advanced Bash-Scripting Guide** - https://tldp.org/LDP/abs/html/
