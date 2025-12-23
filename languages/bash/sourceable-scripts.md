# Bash Sourceable Scripts Best Practices

> **Language:** Bash 4.0+ / Zsh 5.0+
> **Applies to:** Scripts designed to be both executed and sourced

## Critical Rule: Sourcing Changes Everything

When a script is **sourced** (`source script.sh` or `. script.sh`), it runs in the **current shell**, not a subprocess. This fundamentally changes how errors, exits, and variables behave.

## Detect Execution Mode

**Rule:** Every sourceable script MUST detect whether it's sourced or executed.

```bash
#!/usr/bin/env bash

# Detect if sourced (Bash + Zsh compatible)
IS_SOURCED=false
if [[ -n "${BASH_SOURCE:-}" && "${BASH_SOURCE[0]}" != "${0}" ]]; then
    IS_SOURCED=true  # Bash
elif [[ -n "${ZSH_VERSION:-}" && "${(%):-%x}" != "${0}" ]]; then
    IS_SOURCED=true  # Zsh
fi
```

## Strict Mode in Sourceable Scripts

**NEVER use unconditional `set -e` or `set -u` in sourceable scripts.**

### Why?

- `set -e` in sourced script = **closes caller's shell** on error
- `set -u` in sourced script = **breaks caller's shell** on unset variables
- User loses their terminal session

### Solution: Conditional Strict Mode

```bash
#!/usr/bin/env bash

# ✅ SAFE - Only enable strict mode when executed
if [[ -n "${BASH_SOURCE:-}" && "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Executed directly
    set -euo pipefail
fi

# Script continues...
```

```bash
# ❌ DANGEROUS - Breaks parent shell when sourced
set -euo pipefail

# ❌ DANGEROUS - Alternative that's still wrong
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && set -euo pipefail  # Sets in parent!
```

## Exit vs Return in Functions

**Rule:** Functions in sourceable scripts MUST use `return`, never `exit`.

### Why?

- `exit` in sourced function = **closes user's terminal**
- `return` in sourced function = **returns to caller safely**

### Solution: Conditional Exit/Return

```bash
# ✅ SAFE - Detects mode and exits appropriately
error() {
    echo "ERROR: $*" >&2

    if [[ "${IS_SOURCED}" == "true" ]]; then
        return 1  # Safe for sourced mode
    else
        exit 1    # Proper exit for executed mode
    fi
}

# Alternative: use return everywhere if script is designed to be sourced
error() {
    echo "ERROR: $*" >&2
    return 1  # Works in both modes
}
```

```bash
# ❌ DANGEROUS - Closes terminal when sourced
error() {
    echo "ERROR: $*" >&2
    exit 1
}
```

## Argument Parsing with Defaults

**Rule:** Use explicit state tracking, never compare values to defaults.

### Why?

When the user passes the default value as an argument, comparison-based logic fails.

```bash
# ❌ BROKEN - Fails when $1 equals default
DEFAULT_PROFILE="default"
profile="${DEFAULT_PROFILE}"

if [[ "${profile}" == "${DEFAULT_PROFILE}" ]]; then
    profile="$1"  # BUG: Always executes when $1 == "default"
fi
```

### Solution: Explicit State Flags

```bash
# ✅ CORRECT - Use explicit tracking
DEFAULT_PROFILE="default"
profile="${DEFAULT_PROFILE}"
profile_set=false

if [[ $# -gt 0 ]] && [[ "${profile_set}" == "false" ]]; then
    profile="$1"
    profile_set=true
fi

# Or use getopts for robust parsing
while getopts "p:" opt; do
    case $opt in
        p) profile="${OPTARG}"; profile_set=true ;;
        *) return 1 ;;
    esac
done
```

## Environment Variables and Sourcing

**Rule:** Document that sourced variables only persist in the current shell.

### Why?

- `source script.sh` exports vars to **current terminal only**
- `./script.sh` exports vars to **subprocess only** (caller can't see them)
- Users must run in **each terminal** where vars are needed

### Documentation Template

```bash
#!/usr/bin/env bash
#
# Usage:
#   ./script.sh [args]       # Execute (vars exported to subprocess only)
#   source script.sh [args]  # Source (vars exported to current shell)
#
# When sourced, environment variables only affect this terminal.
# Run 'source script.sh' in each terminal session where vars are needed.
#
```

## Shell RC Files

**Rule:** NEVER source heavy scripts in `.bashrc` or `.zshrc`.

### Why?

- Sourcing in RC files runs on **every shell startup**
- Slows terminal launch (users hate slow terminals)
- Login flows, API calls, etc. should be **on-demand**

```bash
# ❌ BAD - Runs AWS SSO login on every terminal
# In ~/.zshrc:
source ~/scripts/aws-sso-login.sh
```

### Solution: Define Wrapper Functions

```bash
# ✅ GOOD - User calls function when needed
# In ~/.zshrc:
aws-sso() {
    source ~/scripts/aws-sso-login.sh "$@"
}

# User runs: aws-sso
```

## Cross-Shell Compatibility

**Rule:** Support both Bash and Zsh when possible.

```bash
# ✅ Get script name (Bash + Zsh compatible)
if [[ -n "${BASH_SOURCE:-}" ]]; then
    SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [[ -n "${ZSH_VERSION:-}" ]]; then
    SCRIPT_NAME="$(basename "${(%):-%x}")"
    SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
else
    SCRIPT_NAME="unknown"
    SCRIPT_DIR="$(pwd)"
fi
```

## Input Validation

**Rule:** Always validate before processing (same for sourced and executed).

```bash
# ✅ Guard clauses with helpful errors
validate_profile() {
    local profile="$1"

    if [[ -z "${profile}" ]]; then
        error "Profile name required"
    fi

    if ! aws configure list-profiles | grep -q "^${profile}$"; then
        error "Profile '${profile}' not found in AWS config"
    fi
}
```

## Testing Requirements

### Test Both Modes

```bash
# Execute mode
./script.sh valid-arg
./script.sh invalid-arg  # Should exit with error

# Source mode
source script.sh valid-arg
source script.sh invalid-arg  # Should return error, NOT close shell
echo $?  # Verify error code
```

### Test Shell RC Integration

```bash
# Should not break shell startup
source ~/.zshrc
echo $?  # Should be 0

# Should not close shell on error
source script.sh bad-arg
echo "Still here"  # Should print
```

### Test Environment Variable Persistence

```bash
# Executed - vars NOT in parent
./script.sh
echo "${VAR_FROM_SCRIPT}"  # Empty

# Sourced - vars IN parent
source script.sh
echo "${VAR_FROM_SCRIPT}"  # Set
```

## Complete Example

```bash
#!/usr/bin/env bash
#
# Description: Configure AWS SSO session
# Usage:
#   ./aws-sso.sh [profile]   # Execute (vars not exported to caller)
#   source aws-sso.sh [profile]  # Source (vars exported to current shell)
#

# Detect if sourced
IS_SOURCED=false
if [[ -n "${BASH_SOURCE:-}" && "${BASH_SOURCE[0]}" != "${0}" ]]; then
    IS_SOURCED=true
elif [[ -n "${ZSH_VERSION:-}" && "${(%):-%x}" != "${0}" ]]; then
    IS_SOURCED=true
fi

# Conditional strict mode (only when executed)
if [[ "${IS_SOURCED}" == "false" ]]; then
    set -euo pipefail
fi

# Error handler
error() {
    echo "ERROR: $*" >&2
    if [[ "${IS_SOURCED}" == "true" ]]; then
        return 1
    else
        exit 1
    fi
}

# Validate profile
validate_profile() {
    local profile="$1"

    if [[ -z "${profile}" ]]; then
        error "Profile name required"
    fi

    if ! aws configure list-profiles | grep -q "^${profile}$"; then
        error "Profile '${profile}' not found"
    fi
}

# Main logic
main() {
    local profile="${AWS_PROFILE:-default}"
    local profile_set=false

    # Parse arguments with explicit state tracking
    if [[ $# -gt 0 ]] && [[ "${profile_set}" == "false" ]]; then
        profile="$1"
        profile_set=true
    fi

    # Validate
    validate_profile "${profile}"

    # Execute AWS SSO login
    aws sso login --profile "${profile}" || error "SSO login failed"

    # Export credentials
    export AWS_PROFILE="${profile}"
    echo "AWS_PROFILE set to: ${profile}"

    return 0
}

# Run main
main "$@"
```

## Testing Checklist

Before shipping a sourceable script:

- [ ] Script works when executed: `./script.sh`
- [ ] Script works when sourced: `source script.sh`
- [ ] Errors don't close parent shell when sourced
- [ ] Works in both Bash and Zsh
- [ ] No unconditional `set -e` or `set -u`
- [ ] Functions use `return` (not `exit`) or conditional exit/return
- [ ] Argument parsing uses explicit state tracking (not value comparison)
- [ ] Usage documentation clearly explains sourcing behavior
- [ ] Environment variable persistence is documented

## Quick Reference

| Scenario | Executed (`./script.sh`) | Sourced (`source script.sh`) |
|----------|-------------------------|------------------------------|
| **Runs in** | Subprocess | Current shell |
| **`set -e` effect** | Exits subprocess | **Closes your terminal** |
| **`exit` effect** | Exits subprocess | **Closes your terminal** |
| **`return` effect** | Returns from function | Returns from function |
| **Exported vars** | Not visible to caller | Visible in current shell |
| **Use case** | Standard script execution | Export vars/functions to shell |

## Common Mistakes Summary

1. ❌ Unconditional `set -e` or `set -u` in sourceable scripts
2. ❌ Using `exit` in functions (use `return` or conditional exit/return)
3. ❌ Comparing variables to defaults in argument parsing
4. ❌ Sourcing heavy scripts in `.bashrc` or `.zshrc`
5. ❌ Assuming environment variables persist across shells
6. ❌ Not testing both sourced and executed modes
7. ❌ Not handling both Bash and Zsh
8. ❌ Not documenting sourcing requirements

## References

- [Bash Reference Manual - Shell Builtin Commands](https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html)
- [Zsh Documentation - Shell Grammar](https://zsh.sourceforge.io/Doc/Release/Shell-Grammar.html)
