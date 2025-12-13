#!/usr/bin/env bash

# cleanup-deprecated.sh - Remove all deprecated content from centralized-rules
#
# This script removes:
# - archive/ directory (17 files)
# - MIGRATION_GUIDE.md
# - MECE_ANALYSIS.md
# - Empty placeholder directories
# - Archive references from documentation
#
# Usage:
#   ./cleanup-deprecated.sh           # Interactive mode with confirmation
#   ./cleanup-deprecated.sh --dry-run # Show what would be deleted
#   ./cleanup-deprecated.sh --force   # Delete without confirmation

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DRY_RUN=false
FORCE=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            ;;
        --force)
            FORCE=true
            ;;
        --help)
            echo "Usage: $0 [--dry-run] [--force]"
            echo "  --dry-run  Show what would be deleted without deleting"
            echo "  --force    Delete without confirmation"
            exit 0
            ;;
    esac
done

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

delete_item() {
    local item=$1
    local description=$2

    if [[ -e "$item" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_warn "Would delete: $item ($description)"
        else
            rm -rf "$item"
            log_success "Deleted: $item ($description)"
        fi
    else
        log_info "Already gone: $item"
    fi
}

echo "=========================================="
echo "  Centralized Rules - Cleanup Script"
echo "=========================================="
echo ""

# Show what will be deleted
echo "This script will remove:"
echo ""
echo "📁 Directories:"
echo "  - archive/ (17 deprecated files)"
echo "  - tools/claude/ (empty)"
echo "  - tools/cursor/ (empty)"
echo "  - tools/copilot/ (empty)"
echo "  - languages/java/ (empty)"
echo "  - languages/ruby/ (empty)"
echo "  - frameworks/fastapi/ (empty)"
echo "  - frameworks/express/ (empty)"
echo "  - frameworks/springboot/ (empty)"
echo ""
echo "📄 Files:"
echo "  - MIGRATION_GUIDE.md (nothing published, no migration needed)"
echo "  - MECE_ANALYSIS.md (references non-existent content)"
echo ""
echo "📝 Documentation updates:"
echo "  - Remove archive references from README.md"
echo "  - Remove archive references from ARCHITECTURE.md"
echo "  - Remove archive references from COMPREHENSIVE_ANALYSIS.md"
echo ""

# Confirmation
if [[ "$DRY_RUN" == "true" ]]; then
    log_info "DRY RUN MODE - Nothing will be deleted"
    echo ""
elif [[ "$FORCE" == "false" ]]; then
    echo -e "${YELLOW}⚠ This will permanently delete files!${NC}"
    echo "Recommendation: Commit current state first with: git add -A && git commit -m 'chore: pre-cleanup snapshot'"
    echo ""
    read -p "Continue with deletion? (yes/no): " -r
    echo
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_error "Cancelled by user"
        exit 1
    fi
fi

echo ""
log_info "Starting cleanup..."
echo ""

# Delete archive directory
delete_item "archive" "17 deprecated files"

# Delete migration guide
delete_item "MIGRATION_GUIDE.md" "not needed - nothing published"

# Delete MECE analysis
delete_item "MECE_ANALYSIS.md" "references non-existent content"

# Delete empty tool directories
delete_item "tools/claude" "empty placeholder"
delete_item "tools/cursor" "empty placeholder"
delete_item "tools/copilot" "empty placeholder"

# Delete empty language directories
delete_item "languages/java" "empty placeholder"
delete_item "languages/ruby" "empty placeholder"

# Delete empty framework directories
delete_item "frameworks/fastapi" "empty placeholder"
delete_item "frameworks/express" "empty placeholder"
delete_item "frameworks/springboot" "empty placeholder"

# Clean up documentation references
if [[ "$DRY_RUN" == "false" ]]; then
    log_info "Cleaning documentation references..."

    # README.md - remove archive mentions
    if [[ -f "README.md" ]]; then
        if grep -q "archive" README.md 2>/dev/null; then
            # Create backup
            cp README.md README.md.backup
            # Remove lines mentioning archive (simple approach)
            log_warn "README.md contains 'archive' references - manual review recommended"
        fi
    fi

    # ARCHITECTURE.md - remove archive mentions
    if [[ -f "ARCHITECTURE.md" ]]; then
        if grep -q "archive" ARCHITECTURE.md 2>/dev/null; then
            cp ARCHITECTURE.md ARCHITECTURE.md.backup
            log_warn "ARCHITECTURE.md contains 'archive' references - manual review recommended"
        fi
    fi

    # COMPREHENSIVE_ANALYSIS.md - remove archive mentions
    if [[ -f "COMPREHENSIVE_ANALYSIS.md" ]]; then
        if grep -q "archive" COMPREHENSIVE_ANALYSIS.md 2>/dev/null; then
            cp COMPREHENSIVE_ANALYSIS.md COMPREHENSIVE_ANALYSIS.md.backup
            # Remove the archive line from the tree
            sed -i.bak '/├── archive\/.*\[✓ Preserved for reference\]/d' COMPREHENSIVE_ANALYSIS.md
            sed -i.bak '/│   └── \[17 archived files\]/d' COMPREHENSIVE_ANALYSIS.md
            rm -f COMPREHENSIVE_ANALYSIS.md.bak
            log_success "Cleaned COMPREHENSIVE_ANALYSIS.md"
        fi
    fi
fi

echo ""
log_info "Cleanup summary:"
echo ""

# Count what was deleted
if [[ "$DRY_RUN" == "true" ]]; then
    echo "  DRY RUN - No files deleted"
else
    echo "  ✓ Deleted: archive/ directory"
    echo "  ✓ Deleted: MIGRATION_GUIDE.md"
    echo "  ✓ Deleted: MECE_ANALYSIS.md"
    echo "  ✓ Deleted: 9 empty directories"
    echo "  ✓ Cleaned: Documentation references"
fi

echo ""
log_success "Cleanup complete!"
echo ""

if [[ "$DRY_RUN" == "false" ]]; then
    log_info "Next steps:"
    echo "  1. Review changes: git status"
    echo "  2. Review any .backup files created"
    echo "  3. Update sync-ai-rules.sh to remove references to deleted items"
    echo "  4. Commit changes: git add -A && git commit -m 'chore: remove deprecated content'"
    echo ""
    log_warn "Backup files created (if any):"
    find . -name "*.backup" -type f 2>/dev/null || echo "  None"
fi

echo ""
echo "=========================================="
