# Bash Sourceable Scripts Best Practices

> **Language:** Bash 4.0+ / Zsh 5.0+
> **Scope:** Scripts designed to work both executed and sourced

## Detect Execution Mode

Every sourceable script MUST detect whether it's sourced or executed. Sourced scripts run in the current shell; executed scripts run in a subprocess.

```bash
#!/usr/bin/env bash
IS_SOURCED=false
if [[ -n "${BASH_SOURCE:-}" && "${BASH_SOURCE[0]}" != "${0}" ]]; then
    IS_SOURCED=true  # Bash
elif [[ -n "${ZSH_VERSION:-}" && "${(%):-%x}" != "${0}" ]]; then
    IS_SOURCED=true  # Zsh
fi
```

## Strict Mode: Conditional Only

NEVER use unconditional `set -e` or `set -u` in sourceable scripts. Both close the caller's shell when sourced.

```bash
# CORRECT: Only enable when executed
if [[ "${IS_SOURCED}" == "false" ]]; then
    set -euo pipefail
fi
```

```bash
# WRONG: Dangerous in sourced mode
set -euo pipefail

# WRONG: Still sets in parent shell
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && set -euo pipefail
```

## Exit vs Return: Conditional Pattern

Functions in sourceable scripts MUST use `return`, never `exit`. Use the conditional pattern for error handlers.

```bash
# CORRECT: Safe in both modes
error() {
    echo "ERROR: $*" >&2
    if [[ "${IS_SOURCED}" == "true" ]]; then
        return 1  # Safe for sourced
    else
        exit 1    # Proper exit for executed
    fi
}
```

```bash
# WRONG: Closes terminal when sourced
error() {
    echo "ERROR: $*" >&2
    exit 1
}
```

## Argument Parsing: Explicit State Tracking

Never compare variables to defaults. Use explicit state flags.

```bash
# WRONG: Fails when $1 equals default
profile="${DEFAULT_PROFILE:-default}"
if [[ "${profile}" == "default" ]] && [[ -n "$1" ]]; then
    profile="$1"  # BUG: Ambiguous logic
fi
```

```bash
# CORRECT: Explicit state tracking
profile_set=false
if [[ $# -gt 0 ]] && [[ "${profile_set}" == "false" ]]; then
    profile="$1"
    profile_set=true
fi
```

## Environment Variable Persistence

Document that sourced variables only persist in the current shell. Executed scripts cannot export to the caller.

```bash
#!/usr/bin/env bash
#
# Usage:
#   ./script.sh [args]       # Execute (vars not visible to caller)
#   source script.sh [args]  # Source (vars visible in current shell)
#
# When sourced, run in each terminal session where vars are needed.
```

## Shell RC Files: Lazy Loading Pattern

Never source heavy scripts in `.bashrc` or `.zshrc`. Define wrapper functions instead.

```bash
# WRONG: Runs on every shell startup
# ~/.zshrc
source ~/scripts/aws-sso-login.sh

# CORRECT: On-demand via wrapper
# ~/.zshrc
aws-sso() { source ~/scripts/aws-sso-login.sh "$@"; }
```

## Cross-Shell Compatibility

Get script paths in both Bash and Zsh:

```bash
if [[ -n "${BASH_SOURCE:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [[ -n "${ZSH_VERSION:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
fi
```

## Input Validation

Always validate inputs before processing:

```bash
validate_profile() {
    local profile="$1"
    [[ -n "${profile}" ]] || error "Profile required"
    aws configure list-profiles | grep -q "^${profile}$" || error "Profile not found"
}
```

## Complete Example

```bash
#!/usr/bin/env bash
# Description: Configure AWS SSO session
# Usage: ./aws-sso.sh [profile] OR source aws-sso.sh [profile]

IS_SOURCED=false
if [[ -n "${BASH_SOURCE:-}" && "${BASH_SOURCE[0]}" != "${0}" ]]; then
    IS_SOURCED=true
elif [[ -n "${ZSH_VERSION:-}" && "${(%):-%x}" != "${0}" ]]; then
    IS_SOURCED=true
fi

[[ "${IS_SOURCED}" == "false" ]] && set -euo pipefail

error() {
    echo "ERROR: $*" >&2
    [[ "${IS_SOURCED}" == "true" ]] && return 1 || exit 1
}

validate_profile() {
    [[ -n "$1" ]] || error "Profile required"
    aws configure list-profiles | grep -q "^$1$" || error "Profile '$1' not found"
}

main() {
    local profile="${1:-${AWS_PROFILE:-default}}"
    validate_profile "${profile}"
    aws sso login --profile "${profile}" || error "SSO login failed"
    export AWS_PROFILE="${profile}"
    echo "AWS_PROFILE=${profile}"
}

main "$@"
```

## Testing Checklist

- [ ] Execute mode: `./script.sh arg` succeeds and `./script.sh bad-arg` exits
- [ ] Source mode: `source script.sh arg` succeeds and `source script.sh bad-arg` returns error without closing shell
- [ ] Verify sourced error: `source script.sh bad-arg; echo "Still here"` prints
- [ ] Both Bash and Zsh compatible
- [ ] No unconditional `set -e` or `set -u`
- [ ] Functions use conditional `return`/`exit` or always `return`
- [ ] Argument parsing uses explicit state flags
- [ ] Usage documentation describes sourcing behavior
- [ ] Environment variable persistence documented

## Quick Reference

| Feature | Executed | Sourced |
|---------|----------|---------|
| Runs in | Subprocess | Current shell |
| `set -e` closes | Subprocess | Parent shell (BAD) |
| `exit` closes | Subprocess | Parent shell (BAD) |
| `return` returns | Function | Function |
| Exported vars | Not visible | Visible |

## References

- [Bash Reference Manual - Shell Builtin Commands](https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html)
- [Zsh Documentation - Shell Grammar](https://zsh.sourceforge.io/Doc/Release/Shell-Grammar.html)
