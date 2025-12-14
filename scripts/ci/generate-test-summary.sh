#!/bin/bash
# Generate GitHub Actions step summary for test results
# Usage: generate-test-summary.sh --name=NAME --scenario=SCENARIO --expected-rules=RULES --status=STATUS

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --name=*)
      NAME="${1#*=}"
      shift
      ;;
    --scenario=*)
      SCENARIO="${1#*=}"
      shift
      ;;
    --expected-rules=*)
      EXPECTED_RULES="${1#*=}"
      shift
      ;;
    --status=*)
      STATUS="${1#*=}"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate required parameters
if [ -z "$NAME" ] || [ -z "$SCENARIO" ] || [ -z "$STATUS" ]; then
  echo "Usage: $0 --name=NAME --scenario=SCENARIO --status=STATUS [--expected-rules=RULES]"
  exit 1
fi

# Generate summary
echo "## 🧪 Sync Script Test: $NAME" >> "$GITHUB_STEP_SUMMARY"
echo "" >> "$GITHUB_STEP_SUMMARY"

if [ "$STATUS" == "success" ]; then
  echo "✅ **Status:** PASSED" >> "$GITHUB_STEP_SUMMARY"
else
  echo "❌ **Status:** FAILED" >> "$GITHUB_STEP_SUMMARY"
fi

echo "" >> "$GITHUB_STEP_SUMMARY"
echo "### Test Details" >> "$GITHUB_STEP_SUMMARY"
echo "- **Project Type:** $NAME" >> "$GITHUB_STEP_SUMMARY"
echo "- **Scenario:** \`$SCENARIO\`" >> "$GITHUB_STEP_SUMMARY"
if [ -n "$EXPECTED_RULES" ]; then
  echo "- **Expected Rules:** $EXPECTED_RULES" >> "$GITHUB_STEP_SUMMARY"
fi
echo "" >> "$GITHUB_STEP_SUMMARY"
echo "### Validations Performed" >> "$GITHUB_STEP_SUMMARY"
echo "- ✓ AGENTS.md generation" >> "$GITHUB_STEP_SUMMARY"
echo "- ✓ Progressive disclosure warnings" >> "$GITHUB_STEP_SUMMARY"
echo "- ✓ Rules directory structure" >> "$GITHUB_STEP_SUMMARY"
echo "- ✓ Language/framework detection" >> "$GITHUB_STEP_SUMMARY"
echo "- ✓ Scenario-specific rules validation" >> "$GITHUB_STEP_SUMMARY"
echo "- ✓ Cloud platform rules (if applicable)" >> "$GITHUB_STEP_SUMMARY"
echo "- ✓ Context-appropriate rule application" >> "$GITHUB_STEP_SUMMARY"

echo "✅ Summary generated for $NAME"
