#!/bin/bash
# Generate comprehensive CI test report
# Usage: generate-test-report.sh
#
# Expected environment variables:
#   PROGRESSIVE_DISCLOSURE_STATUS - status of progressive disclosure tests
#   QUALITY_STATUS - status of quality tests
#   SYNC_SCRIPT_STATUS - status of sync script tests
#   SKILL_STATUS - status of skill tests
#   KEYWORD_VALIDATION_STATUS - status of keyword validation tests
#   TOKEN_LIMITS_STATUS - status of token limit tests
#   GITHUB_RUN_NUMBER - workflow run number
#   GITHUB_SHA - commit SHA
#   GITHUB_REF_NAME - branch name
#   GITHUB_EVENT_NAME - event that triggered workflow
#   GITHUB_SERVER_URL - GitHub server URL
#   GITHUB_REPOSITORY - repository name
#   GITHUB_RUN_ID - workflow run ID

set -euo pipefail

# Source summary utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/ci/summary-utils.sh
source "${SCRIPT_DIR}/summary-utils.sh"

# Create report file
REPORT_FILE="test-report.md"

cat > "$REPORT_FILE" << EOF
# 🚀 CI Test Report

**Workflow Run:** ${GITHUB_RUN_NUMBER}
**Commit:** \`${GITHUB_SHA}\`
**Branch:** \`${GITHUB_REF_NAME}\`
**Triggered by:** ${GITHUB_EVENT_NAME}
**Run Date:** $(date -u '+%Y-%m-%d %H:%M:%S UTC')

---

## 📊 Test Results Summary

| Test Suite | Status | Details |
|-----------|---------|---------|
EOF

# Add test results to table
{
  echo "| 📋 Progressive Disclosure Validation | $([ "$PROGRESSIVE_DISCLOSURE_STATUS" == "success" ] && echo "✅ PASSED" || echo "❌ FAILED") | Claude + Cursor + Copilot configs validated |"
  echo "| 🔍 Code Quality | $([ "$QUALITY_STATUS" == "success" ] && echo "✅ PASSED" || echo "❌ FAILED") | ShellCheck + Documentation verification |"
  echo "| 🧪 Sync Script Testing | $([ "$SYNC_SCRIPT_STATUS" == "success" ] && echo "✅ PASSED" || echo "❌ FAILED") | **20+ comprehensive scenarios** |"
  echo "| ⚡ Claude Skill Tests | $([ "$SKILL_STATUS" == "success" ] && echo "✅ PASSED" || echo "❌ FAILED") | TypeScript compilation, tests, 85% coverage |"
  echo "| 🔑 Keyword Validation | $([ "$KEYWORD_VALIDATION_STATUS" == "success" ] && echo "✅ PASSED" || echo "❌ FAILED") | Validates all keywords trigger correct rules |"
  echo "| 🔢 Token Limit Tests | $([ "$TOKEN_LIMITS_STATUS" == "success" ] && echo "✅ PASSED" || echo "❌ FAILED") | Validates token budgets and warnings |"
} >> "$REPORT_FILE"

cat >> "$REPORT_FILE" << EOF

---

## 🎯 Overall Status

EOF

# Determine overall status
overall_status="success"
if [ "$PROGRESSIVE_DISCLOSURE_STATUS" != "success" ] || \
   [ "$QUALITY_STATUS" != "success" ] || \
   [ "$SYNC_SCRIPT_STATUS" != "success" ] || \
   [ "$SKILL_STATUS" != "success" ] || \
   [ "$KEYWORD_VALIDATION_STATUS" != "success" ] || \
   [ "$TOKEN_LIMITS_STATUS" != "success" ]; then
  overall_status="failure"
fi

if [ "$overall_status" == "success" ]; then
  cat >> "$REPORT_FILE" << EOF
### ✅ ALL TESTS PASSED

All test suites completed successfully. The progressive disclosure architecture is validated and working correctly across all scenarios.
EOF
else
  cat >> "$REPORT_FILE" << EOF
### ❌ TESTS FAILED

One or more test suites failed. Please review the individual test results above and check the workflow logs for details.

#### Failed Tests:
EOF

  # List failed tests
  [ "$PROGRESSIVE_DISCLOSURE_STATUS" != "success" ] && echo "- Progressive Disclosure Validation" >> "$REPORT_FILE"
  [ "$QUALITY_STATUS" != "success" ] && echo "- Code Quality" >> "$REPORT_FILE"
  [ "$SYNC_SCRIPT_STATUS" != "success" ] && echo "- Sync Script Testing" >> "$REPORT_FILE"
  [ "$SKILL_STATUS" != "success" ] && echo "- Claude Skill Tests" >> "$REPORT_FILE"
  [ "$KEYWORD_VALIDATION_STATUS" != "success" ] && echo "- Keyword Validation" >> "$REPORT_FILE"
  [ "$TOKEN_LIMITS_STATUS" != "success" ] && echo "- Token Limit Tests" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << EOF

---

**Workflow URL:** ${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}
EOF

# Output to job summary
cat "$REPORT_FILE" >> "$GITHUB_STEP_SUMMARY"

# Output status for next step
echo "status=$overall_status"
