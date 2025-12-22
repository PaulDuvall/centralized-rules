#!/usr/bin/env bash

# lib/logging.sh - Shared logging and error handling library
#
# Provides standardized logging functions with consistent formatting
# and error handling utilities for all bash scripts.
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/../lib/logging.sh"
#   log_info "Starting process..."
#   log_success "Process completed"
#   log_error "Process failed"
#   die "Fatal error occurred"

# Prevent multiple sourcing
[[ -n "${_LIB_LOGGING_LOADED:-}" ]] && return 0
readonly _LIB_LOGGING_LOADED=1

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions with consistent formatting
log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*" >&2
}

log_debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $*" >&2
    fi
}

# Error handling utilities
die() {
    log_error "$*"
    exit 1
}

# Validate required commands exist
require_command() {
    local cmd="$1"
    local install_hint="${2:-}"

    if ! command -v "$cmd" &>/dev/null; then
        if [[ -n "$install_hint" ]]; then
            die "Required command '$cmd' not found. $install_hint"
        else
            die "Required command '$cmd' not found. Please install it and try again."
        fi
    fi
}

# Validate file exists
require_file() {
    local file="$1"
    local error_msg="${2:-File \"$file\" not found}"

    if [[ ! -f "$file" ]]; then
        die "$error_msg"
    fi
}

# Validate directory exists
require_directory() {
    local dir="$1"
    local error_msg="${2:-Directory \"$dir\" not found}"

    if [[ ! -d "$dir" ]]; then
        die "$error_msg"
    fi
}

# Safe directory creation with error handling
safe_mkdir() {
    local dir="$1"

    if ! mkdir -p "$dir" 2>/dev/null; then
        die "Failed to create directory: $dir"
    fi
}

# Safe file write with error handling
safe_write() {
    local file="$1"
    local content="$2"

    if ! echo "$content" > "$file" 2>/dev/null; then
        die "Failed to write to file: $file"
    fi
}

# Execute command with error handling
safe_exec() {
    local error_msg="${1:-Command failed}"
    shift

    if ! "$@"; then
        die "$error_msg"
    fi
}

# Cleanup handler registration
_cleanup_handlers=()

register_cleanup() {
    _cleanup_handlers+=("$1")
}

_run_cleanup_handlers() {
    local handler
    for handler in "${_cleanup_handlers[@]}"; do
        eval "$handler" 2>/dev/null || true
    done
}

# Set up cleanup trap
trap '_run_cleanup_handlers' EXIT

# Export functions for subshells
export -f log_info log_success log_warn log_error log_debug
export -f die require_command require_file require_directory
export -f safe_mkdir safe_write safe_exec
export -f register_cleanup
