#!/usr/bin/env bash

# validate-progressive-disclosure.sh - Validate Progressive Disclosure Architecture
#
# This script validates that the repository correctly implements progressive disclosure:
# - Hierarchical rule organization (base → language → framework → cloud)
# - Task-level rule loading instructions
# - Proper separation of concerns across dimensions
# - AGENTS.md configuration for on-demand loading
# - Tests against a temporary project to ensure sync works end-to-end

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0
CHECKS=0

# Test mode flag
RUN_PROJECT_TEST="${RUN_PROJECT_TEST:-true}"

# Helper functions
error() {
    echo -e "${RED}✗ ERROR:${NC} $1"
    ERRORS=$((ERRORS + 1))
}

warning() {
    echo -e "${YELLOW}⚠ WARNING:${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

check_pass() {
    CHECKS=$((CHECKS + 1))
}

# ============================================================================
# TEST 1: Directory Structure Validation
# ============================================================================

test_directory_structure() {
    info "Testing directory structure..."

    # Check required directories
    for dir in "base" "languages" "frameworks" "cloud"; do
        check_pass
        if [ -d "$dir" ]; then
            success "Directory exists: $dir/"
        else
            error "Missing required directory: $dir/"
        fi
    done

    # Check .claude/rules directory (generated)
    check_pass
    if [ -d ".claude/rules" ]; then
        success "Generated rules directory exists: .claude/rules/"
    else
        warning "Generated rules directory not found (run sync-ai-rules.sh): .claude/rules/"
    fi

    echo ""
}

# ============================================================================
# TEST 2: AGENTS.md Configuration Validation
# ============================================================================

test_agents_md() {
    info "Testing AGENTS.md configuration..."

    local agents_file=".claude/AGENTS.md"

    check_pass
    if [ ! -f "$agents_file" ]; then
        error "Missing $agents_file (run sync-ai-rules.sh to generate)"
        echo ""
        return
    fi

    success "AGENTS.md exists"

    # Check for required sections
    local sections=("Progressive Disclosure Rule System" "Directory Structure" "Discovery Process" "Load Relevant Rules" "Rule Index")

    for section in "${sections[@]}"; do
        check_pass
        if grep -q "$section" "$agents_file" 2>/dev/null; then
            success "Section found: $section"
        else
            error "Missing section in AGENTS.md: $section"
        fi
    done

    # Check for progressive disclosure instructions
    check_pass
    if grep -q "DO NOT load all rule files at once" "$agents_file" 2>/dev/null; then
        success "Contains progressive disclosure warning"
    else
        error "Missing progressive disclosure warning in AGENTS.md"
    fi

    # Check for task-level loading examples
    check_pass
    if grep -q "Step 2: Load Relevant Rules" "$agents_file" 2>/dev/null; then
        success "Contains task-level loading instructions"
    else
        warning "Missing clear task-level loading examples"
    fi

    echo ""
}

# ============================================================================
# TEST 3: Base Rules Validation (Language-Agnostic)
# ============================================================================

test_base_rules() {
    info "Testing base rules are language-agnostic..."

    if [ ! -d "base" ]; then
        error "base/ directory not found"
        echo ""
        return
    fi

    # Language-specific terms that should NOT appear prescriptively in base rules
    local violations=0

    for file in base/*.md; do
        [ -e "$file" ] || continue

        # Check if file contains prescriptive language-specific content
        # (allowing examples is OK)
        for term in "pytest" "Jest" "Vitest"; do
            if grep -i "use $term\|install $term" "$file" 2>/dev/null | grep -qv "example:\|e\.g\."; then
                violations=$((violations + 1))
            fi
        done
    done

    check_pass
    if [ "$violations" -eq 0 ]; then
        success "Base rules are language-agnostic"
    else
        warning "Base rules may contain language-specific content ($violations potential issues)"
        echo "  (This is OK if used as examples, not prescriptive)"
    fi

    echo ""
}

# ============================================================================
# TEST 4: Progressive Disclosure in Generated RULES.md
# ============================================================================

test_generated_rules() {
    info "Testing generated RULES.md for progressive disclosure..."

    local rules_file=".claude/RULES.md"

    check_pass
    if [ ! -f "$rules_file" ]; then
        warning "Generated RULES.md not found (run sync-ai-rules.sh)"
        echo ""
        return
    fi

    success "RULES.md exists"

    # Check for progressive disclosure instructions
    check_pass
    if grep -q "PROGRESSIVE DISCLOSURE" "$rules_file" 2>/dev/null; then
        success "Contains progressive disclosure header"
    else
        error "Missing progressive disclosure instructions in RULES.md"
    fi

    # Check for task categorization
    check_pass
    if grep -q "DO NOT apply all rules to every task" "$rules_file" 2>/dev/null; then
        success "Contains task-specific application warning"
    else
        error "Missing task-specific application guidance"
    fi

    # Check for rule organization by category
    check_pass
    if grep -qE "## Base Rules|## Language Rules|## Framework Rules" "$rules_file" 2>/dev/null; then
        success "Rules organized by category"
    else
        warning "Rules may not be clearly categorized"
    fi

    echo ""
}

# ============================================================================
# TEST 5: Sync Script Validation
# ============================================================================

test_sync_script() {
    info "Testing sync-ai-rules.sh for progressive disclosure support..."

    local sync_script="sync-ai-rules.sh"

    check_pass
    if [ ! -f "$sync_script" ]; then
        error "Sync script not found: $sync_script"
        echo ""
        return
    fi

    success "Sync script exists"

    # Check that sync script generates AGENTS.md
    check_pass
    if grep -q "AGENTS.md" "$sync_script" 2>/dev/null; then
        success "Sync script generates AGENTS.md"
    else
        error "Sync script doesn't generate AGENTS.md"
    fi

    # Check for progressive disclosure messaging
    check_pass
    if grep -qi "progressive disclosure" "$sync_script" 2>/dev/null; then
        success "Sync script includes progressive disclosure messaging"
    else
        warning "Sync script may not include progressive disclosure instructions"
    fi

    # Check for hierarchical directory structure generation
    check_pass
    if grep -qE "base/|languages/|frameworks/" "$sync_script" 2>/dev/null; then
        success "Sync script handles hierarchical structure"
    else
        error "Sync script may not handle hierarchical directory structure"
    fi

    echo ""
}

# ============================================================================
# TEST 6: Documentation Validation
# ============================================================================

test_documentation() {
    info "Testing progressive disclosure documentation..."

    # Check README mentions progressive disclosure
    check_pass
    if [ -f "README.md" ]; then
        if grep -qi "progressive disclosure" "README.md" 2>/dev/null; then
            success "README.md documents progressive disclosure"
        else
            error "README.md doesn't mention progressive disclosure"
        fi
    else
        error "README.md not found"
    fi

    # Check ARCHITECTURE.md explains progressive disclosure
    check_pass
    if [ -f "ARCHITECTURE.md" ]; then
        if grep -qi "progressive disclosure" "ARCHITECTURE.md" 2>/dev/null; then
            success "ARCHITECTURE.md explains progressive disclosure"

            # Check for key concepts
            if grep -qiE "on-demand|hierarchical|task-level" "ARCHITECTURE.md" 2>/dev/null; then
                success "ARCHITECTURE.md covers key progressive disclosure concepts"
            else
                warning "ARCHITECTURE.md may not fully explain progressive disclosure design"
            fi
        else
            error "ARCHITECTURE.md doesn't explain progressive disclosure"
        fi
    else
        warning "ARCHITECTURE.md not found"
    fi

    echo ""
}

# ============================================================================
# TEST 7: Real Project Integration Test
# ============================================================================

test_real_project() {
    if [ "$RUN_PROJECT_TEST" != "true" ]; then
        info "Skipping real project test (RUN_PROJECT_TEST=false)"
        echo ""
        return
    fi

    info "Testing against a real project..."

    # Create temporary test project
    test_dir=$(mktemp -d -t progressive-disclosure-test-XXXXXX)

    cleanup_test_dir() {
        if [ -n "${test_dir:-}" ] && [ -d "$test_dir" ]; then
            rm -rf "$test_dir"
        fi
    }

    trap cleanup_test_dir EXIT

    info "Created test project: $test_dir"

    # Create a Python + FastAPI project (local keyword removed)
    mkdir -p "$test_dir/src"
    cat > "$test_dir/pyproject.toml" <<'EOF'
[project]
name = "test-project"
version = "0.1.0"
dependencies = [
    "fastapi",
    "pytest",
]
EOF

    cat > "$test_dir/src/main.py" <<'EOF'
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"Hello": "World"}
EOF

    # Copy sync script to test project
    check_pass
    if cp "sync-ai-rules.sh" "$test_dir/" 2>/dev/null; then
        success "Copied sync script to test project"
    else
        error "Failed to copy sync script"
        echo ""
        return
    fi

    # Run sync script in test project (generates for all tools by default)
    check_pass
    cd "$test_dir"
    if bash ./sync-ai-rules.sh > /dev/null 2>&1; then
        success "Sync script executed successfully (all tools)"
    else
        error "Sync script failed to execute"
        cd - > /dev/null
        echo ""
        return
    fi

    # ========================================================================
    # Validate Claude configuration
    # ========================================================================
    info "Validating Claude configuration..."

    check_pass
    if [ -f ".claude/AGENTS.md" ]; then
        success "Generated .claude/AGENTS.md (Claude entry point)"
    else
        error "Failed to generate .claude/AGENTS.md"
    fi

    check_pass
    # In hierarchical mode (default), RULES.md is not generated
    # AGENTS.md is the entry point instead
    if [ -f ".claude/AGENTS.md" ]; then
        success "Hierarchical mode active (AGENTS.md is entry point)"
    elif [ -f ".claude/RULES.md" ]; then
        success "Monolithic mode active (RULES.md generated)"
    else
        error "Neither AGENTS.md nor RULES.md generated"
    fi

    # Check that Python and FastAPI rules were detected
    check_pass
    if [ -d ".claude/rules/languages/python" ]; then
        success "Python rules detected and copied"
    else
        error "Python rules not detected"
    fi

    check_pass
    if [ -d ".claude/rules/frameworks/fastapi" ]; then
        success "FastAPI rules detected and copied"
    else
        error "FastAPI rules not detected"
    fi

    # Check that AGENTS.md mentions Python
    check_pass
    if grep -q "python" ".claude/AGENTS.md" 2>/dev/null; then
        success "AGENTS.md references Python"
    else
        warning "AGENTS.md doesn't mention detected Python language"
    fi

    # Verify progressive disclosure instructions are present
    check_pass
    if grep -q "DO NOT load all rule files at once" ".claude/AGENTS.md" 2>/dev/null; then
        success "Progressive disclosure warning present in test project"
    else
        error "Progressive disclosure warning missing in test project"
    fi

    # Check entry point has progressive disclosure instructions
    check_pass
    if [ -f ".claude/AGENTS.md" ]; then
        if grep -q "Progressive Disclosure" ".claude/AGENTS.md" 2>/dev/null; then
            success "AGENTS.md has progressive disclosure instructions"
        else
            error "AGENTS.md missing progressive disclosure instructions"
        fi
    elif [ -f ".claude/RULES.md" ]; then
        if grep -q "PROGRESSIVE DISCLOSURE" ".claude/RULES.md" 2>/dev/null; then
            success "RULES.md has progressive disclosure header"
        else
            error "RULES.md missing progressive disclosure header"
        fi
    fi

    # ========================================================================
    # Validate Cursor configuration
    # ========================================================================
    info "Validating Cursor configuration..."

    check_pass
    if [ -f ".cursorrules" ]; then
        success "Generated .cursorrules (Cursor configuration)"
    else
        error "Failed to generate .cursorrules"
    fi

    check_pass
    if [ -f ".cursorrules" ] && grep -q "AI Development Rules (Cursor)" ".cursorrules" 2>/dev/null; then
        success "Cursor rules file has correct header"
    else
        warning "Cursor rules file missing expected header"
    fi

    check_pass
    if [ -f ".cursorrules" ] && [ -s ".cursorrules" ]; then
        # Check file is not empty and has substantial content
        line_count=$(wc -l < ".cursorrules")
        if [ "$line_count" -gt 10 ]; then
            success "Cursor rules file has content ($line_count lines)"
        else
            warning "Cursor rules file seems too small ($line_count lines)"
        fi
    else
        error "Cursor rules file is empty or missing"
    fi

    # ========================================================================
    # Validate Copilot configuration
    # ========================================================================
    info "Validating GitHub Copilot configuration..."

    check_pass
    if [ -f ".github/copilot-instructions.md" ]; then
        success "Generated .github/copilot-instructions.md (Copilot configuration)"
    else
        error "Failed to generate .github/copilot-instructions.md"
    fi

    check_pass
    if [ -f ".github/copilot-instructions.md" ] && grep -q "GitHub Copilot Instructions" ".github/copilot-instructions.md" 2>/dev/null; then
        success "Copilot instructions file has correct header"
    else
        warning "Copilot instructions file missing expected header"
    fi

    check_pass
    if [ -f ".github/copilot-instructions.md" ] && [ -s ".github/copilot-instructions.md" ]; then
        # Check file is not empty and has substantial content
        line_count=$(wc -l < ".github/copilot-instructions.md")
        if [ "$line_count" -gt 10 ]; then
            success "Copilot instructions file has content ($line_count lines)"
        else
            warning "Copilot instructions file seems too small ($line_count lines)"
        fi
    else
        error "Copilot instructions file is empty or missing"
    fi

    cd - > /dev/null
    info "Test project validation complete (Claude + Cursor + Copilot)"
    echo ""
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    echo ""
    echo "======================================================================"
    echo "  Progressive Disclosure Validation"
    echo "======================================================================"
    echo ""

    # Run all tests
    test_directory_structure
    test_agents_md
    test_base_rules
    test_generated_rules
    test_sync_script
    test_documentation
    test_real_project

    # Summary
    echo "======================================================================"
    echo "  Summary"
    echo "======================================================================"
    echo ""
    echo "Total checks: $CHECKS"
    echo -e "${GREEN}Passed: $((CHECKS - ERRORS - WARNINGS))${NC}"

    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
    fi

    if [ $ERRORS -gt 0 ]; then
        echo -e "${RED}Errors: $ERRORS${NC}"
        echo ""
        echo "❌ Progressive disclosure validation FAILED"
        exit 1
    else
        echo ""
        echo "✅ Progressive disclosure validation PASSED"

        if [ $WARNINGS -gt 0 ]; then
            echo ""
            echo "Note: There are $WARNINGS warning(s) that should be reviewed."
        fi

        exit 0
    fi
}

# Run main function
main "$@"
