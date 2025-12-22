#!/bin/bash
# Format keyword validation errors for CI output
# Usage: format-keyword-errors.sh
#
# Expected files in current directory:
#   failed-keywords.txt - list of failed keywords (optional)
#   test-output.log - full test output log (optional)

set -euo pipefail

echo "::error::Keyword validation tests failed!"
echo ""

if [ -f failed-keywords.txt ] && [ -s failed-keywords.txt ]; then
  echo "❌ FAILED KEYWORDS:"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Show failed keywords in output
  while IFS= read -r keyword; do
    echo "  ✗ $keyword"
    # Create individual error annotations for GitHub Actions
    echo "::error file=.claude/skills/skill-rules.json::Keyword '$keyword' failed validation - not triggering expected rules"
  done < failed-keywords.txt

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "These keywords in skill-rules.json are not correctly triggering their expected rules."
  echo ""

  # Show excerpt from test log with failures
  if [ -f test-output.log ]; then
    echo "Test failure details:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    grep -A 3 "✗.*failed to trigger" test-output.log || true
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  fi
else
  echo "⚠️  Test failed but could not extract failed keywords from output."
  echo "Full test log available in artifacts."
fi

echo ""
echo "🔧 To debug locally, run:"
echo "   ./scripts/test-keyword-validation.sh --verbose"
echo ""
echo "📊 See the job summary tab above for detailed test results."
echo "📦 Download test-output.log artifact for full details."

exit 1
