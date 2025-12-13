#!/usr/bin/env bash

# validate-mece.sh - MECE (Mutually Exclusive, Collectively Exhaustive) Compliance Checker
#
# This script validates that the centralized rules repository follows MECE principles:
# - Mutually Exclusive: No duplication across dimensions (base/languages/frameworks/cloud)
# - Collectively Exhaustive: Complete coverage of common development scenarios
#
# Usage:
#   ./scripts/validate-mece.sh [--verbose]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Flags
VERBOSE=false

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0

# Logging
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED_CHECKS++))
}

log_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED_CHECKS++))
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "  $1"
    fi
}

# Check if a pattern appears in multiple files (duplication check)
check_duplication() {
    local pattern="$1"
    local description="$2"
    local exclude_pattern="${3:-}"

    ((TOTAL_CHECKS++))

    local files
    if [[ -n "$exclude_pattern" ]]; then
        files=$(grep -rl "$pattern" "$REPO_ROOT" --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.cache --exclude="*.sh" | grep -v "$exclude_pattern" || true)
    else
        files=$(grep -rl "$pattern" "$REPO_ROOT" --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.cache --exclude="*.sh" || true)
    fi

    local file_count=$(echo "$files" | grep -c . || echo "0")

    if [[ $file_count -le 1 ]]; then
        log_success "$description: No duplication found"
        return 0
    else
        log_warn "$description: Found in $file_count files (potential duplication)"
        log_verbose "Files: $files"
        return 1
    fi
}

# Check dimension separation (mutually exclusive)
check_dimension_separation() {
    log_info "Checking dimension separation (Mutually Exclusive)..."
    echo ""

    # Base rules should not contain language-specific content
    ((TOTAL_CHECKS++))
    if ! grep -rq "TypeScript\|Python\|Java\|C#\|Rust\|Go" "$REPO_ROOT/base/" --exclude="*.md"; then
        log_success "Base rules: No language-specific content"
    else
        log_warn "Base rules: Contains language-specific references (should be language-agnostic)"
    fi

    # Base rules should not contain framework-specific content
    ((TOTAL_CHECKS++))
    if ! grep -rq "React\|Django\|FastAPI\|Express\|Spring Boot\|Next.js" "$REPO_ROOT/base/" --exclude="*.md"; then
        log_success "Base rules: No framework-specific content"
    else
        log_warn "Base rules: Contains framework-specific references (should be framework-agnostic)"
    fi

    # Language files should not duplicate base content
    ((TOTAL_CHECKS++))
    local lang_files=$(find "$REPO_ROOT/languages" -name "*.md" 2>/dev/null || true)
    if [[ -n "$lang_files" ]]; then
        # Check if language files reference base principles instead of duplicating
        if grep -rq "See.*base/" "$REPO_ROOT/languages/"; then
            log_success "Language rules: Reference base rules instead of duplicating"
        else
            log_warn "Language rules: Should reference base rules more explicitly"
        fi
    fi

    # Framework files should not duplicate language content
    ((TOTAL_CHECKS++))
    local framework_files=$(find "$REPO_ROOT/frameworks" -name "*.md" 2>/dev/null || true)
    if [[ -n "$framework_files" ]]; then
        if grep -rq "See.*languages/" "$REPO_ROOT/frameworks/"; then
            log_success "Framework rules: Reference language rules instead of duplicating"
        else
            log_warn "Framework rules: Should reference language rules more explicitly"
        fi
    fi

    echo ""
}

# Check coverage completeness (collectively exhaustive)
check_coverage_completeness() {
    log_info "Checking coverage completeness (Collectively Exhaustive)..."
    echo ""

    # Required base rules
    local required_base=(
        "git-workflow.md"
        "code-quality.md"
        "testing-philosophy.md"
        "security-principles.md"
        "architecture-principles.md"
        "cicd-comprehensive.md"
        "project-maturity-levels.md"
    )

    for rule in "${required_base[@]}"; do
        ((TOTAL_CHECKS++))
        if [[ -f "$REPO_ROOT/base/$rule" ]]; then
            log_success "Required base rule exists: $rule"
        else
            log_fail "Missing required base rule: $rule"
        fi
    done

    # Common languages coverage
    local common_languages=("python" "typescript" "java" "go")
    for lang in "${common_languages[@]}"; do
        ((TOTAL_CHECKS++))
        if [[ -d "$REPO_ROOT/languages/$lang" ]]; then
            log_success "Common language supported: $lang"

            # Check for required language files
            ((TOTAL_CHECKS++))
            if [[ -f "$REPO_ROOT/languages/$lang/coding-standards.md" ]]; then
                log_success "  ↳ coding-standards.md exists"
            else
                log_warn "  ↳ Missing coding-standards.md for $lang"
            fi

            ((TOTAL_CHECKS++))
            if [[ -f "$REPO_ROOT/languages/$lang/testing.md" ]]; then
                log_success "  ↳ testing.md exists"
            else
                log_warn "  ↳ Missing testing.md for $lang"
            fi
        else
            log_warn "Common language not yet supported: $lang"
        fi
    done

    # Common frameworks coverage
    local common_frameworks=("react" "fastapi" "django" "express" "springboot")
    for fw in "${common_frameworks[@]}"; do
        ((TOTAL_CHECKS++))
        if [[ -d "$REPO_ROOT/frameworks/$fw" ]]; then
            log_success "Common framework supported: $fw"

            ((TOTAL_CHECKS++))
            if [[ -f "$REPO_ROOT/frameworks/$fw/best-practices.md" ]]; then
                log_success "  ↳ best-practices.md exists"
            else
                log_fail "  ↳ Missing best-practices.md for $fw"
            fi
        else
            log_warn "Common framework not yet supported: $fw"
        fi
    done

    echo ""
}

# Check documentation completeness
check_documentation() {
    log_info "Checking documentation completeness..."
    echo ""

    local required_docs=(
        "README.md"
        "ARCHITECTURE.md"
        "PRACTICE_CROSSREFERENCE.md"
        "ANTI_PATTERNS.md"
        "IMPLEMENTATION_GUIDE.md"
        "SUCCESS_METRICS.md"
    )

    for doc in "${required_docs[@]}"; do
        ((TOTAL_CHECKS++))
        if [[ -f "$REPO_ROOT/$doc" ]]; then
            log_success "Documentation exists: $doc"
        else
            log_fail "Missing documentation: $doc"
        fi
    done

    echo ""
}

# Check file structure consistency
check_file_structure() {
    log_info "Checking file structure consistency..."
    echo ""

    # All base rules should have "When to apply" header
    ((TOTAL_CHECKS++))
    local base_without_when=$(grep -L "When to apply:" "$REPO_ROOT/base/"*.md 2>/dev/null || true)
    if [[ -z "$base_without_when" ]]; then
        log_success "All base rules have 'When to apply' header"
    else
        log_warn "Some base rules missing 'When to apply' header"
        log_verbose "$base_without_when"
    fi

    # Check for maturity indicators in key base files
    ((TOTAL_CHECKS++))
    local key_files=("git-workflow.md" "code-quality.md" "testing-philosophy.md" "security-principles.md" "cicd-comprehensive.md")
    local files_with_maturity=0
    for file in "${key_files[@]}"; do
        if [[ -f "$REPO_ROOT/base/$file" ]] && grep -q "Maturity Level Indicators" "$REPO_ROOT/base/$file"; then
            ((files_with_maturity++))
        fi
    done

    if [[ $files_with_maturity -ge 3 ]]; then
        log_success "Key base files have maturity indicators ($files_with_maturity/${#key_files[@]})"
    else
        log_warn "Few base files have maturity indicators ($files_with_maturity/${#key_files[@]})"
    fi

    # All language directories should have consistent structure
    ((TOTAL_CHECKS++))
    local inconsistent_langs=()
    for lang_dir in "$REPO_ROOT/languages"/*; do
        if [[ -d "$lang_dir" ]]; then
            local lang=$(basename "$lang_dir")
            if [[ ! -f "$lang_dir/coding-standards.md" ]] || [[ ! -f "$lang_dir/testing.md" ]]; then
                inconsistent_langs+=("$lang")
            fi
        fi
    done

    if [[ ${#inconsistent_langs[@]} -eq 0 ]]; then
        log_success "All language directories have consistent structure"
    else
        log_warn "Inconsistent structure in: ${inconsistent_langs[*]}"
    fi

    echo ""
}

# Check for content duplication across files
check_content_duplication() {
    log_info "Checking for content duplication..."
    echo ""

    # Check for duplicated code examples (>10 lines identical)
    # This is a simplified check - in practice, use tools like jscpd
    ((TOTAL_CHECKS++))
    log_verbose "Checking for duplicated code blocks (>10 lines)..."

    # For now, just warn that manual review is recommended
    log_warn "Manual review recommended: Check for duplicated examples across files"
    log_verbose "Consider using tools like jscpd or dupfinder"

    echo ""
}

# Check cross-references
check_cross_references() {
    log_info "Checking cross-references..."
    echo ""

    # Check that cross-references point to existing files
    ((TOTAL_CHECKS++))
    local broken_refs=()

    while IFS= read -r file; do
        # Extract markdown links
        while IFS= read -r link; do
            # Extract the file path (remove anchor)
            local ref_file=$(echo "$link" | sed 's/#.*//')

            # Check if file exists (relative to the file containing the reference)
            local file_dir=$(dirname "$file")
            if [[ -n "$ref_file" ]] && [[ "$ref_file" == *.md ]]; then
                if [[ ! -f "$file_dir/$ref_file" ]] && [[ ! -f "$REPO_ROOT/$ref_file" ]]; then
                    broken_refs+=("$file -> $ref_file")
                    log_verbose "Broken reference: $file -> $ref_file"
                fi
            fi
        done < <(grep -o '\[.*\](.*.md[^)]*)' "$file" | sed 's/\[.*\](\(.*\))/\1/' || true)
    done < <(find "$REPO_ROOT" -name "*.md" -type f ! -path "*/node_modules/*" ! -path "*/.git/*")

    if [[ ${#broken_refs[@]} -eq 0 ]]; then
        log_success "No broken cross-references found"
    else
        log_warn "Found ${#broken_refs[@]} potentially broken cross-references"
        if [[ "$VERBOSE" == "true" ]]; then
            for ref in "${broken_refs[@]}"; do
                log_verbose "  $ref"
            done
        fi
    fi

    echo ""
}

# Main validation
main() {
    echo "═══════════════════════════════════════════════════════"
    echo "   MECE Compliance Validation"
    echo "   Mutually Exclusive, Collectively Exhaustive"
    echo "═══════════════════════════════════════════════════════"
    echo ""

    cd "$REPO_ROOT"

    # Run checks
    check_dimension_separation
    check_coverage_completeness
    check_documentation
    check_file_structure
    check_content_duplication
    check_cross_references

    # Summary
    echo "═══════════════════════════════════════════════════════"
    echo "   Validation Summary"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    echo -e "${BLUE}Total checks:${NC}    $TOTAL_CHECKS"
    echo -e "${GREEN}Passed:${NC}          $PASSED_CHECKS"
    echo -e "${RED}Failed:${NC}          $FAILED_CHECKS"
    echo -e "${YELLOW}Warnings:${NC}        $WARNINGS"
    echo ""

    if [[ $FAILED_CHECKS -eq 0 ]]; then
        echo -e "${GREEN}✓ MECE compliance validation PASSED${NC}"
        echo ""
        if [[ $WARNINGS -gt 0 ]]; then
            echo -e "${YELLOW}Note: $WARNINGS warnings found. Review recommended.${NC}"
        fi
        exit 0
    else
        echo -e "${RED}✗ MECE compliance validation FAILED${NC}"
        echo ""
        echo "Please address the $FAILED_CHECKS failed checks above."
        exit 1
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--verbose]"
            echo ""
            echo "Validates MECE compliance of the centralized rules repository."
            echo ""
            echo "Options:"
            echo "  --verbose, -v    Show detailed output"
            echo "  --help, -h       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Run validation
main
