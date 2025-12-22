#!/bin/bash
# CI Summary Utilities
# Shared functions for generating GitHub Actions job summaries

set -euo pipefail

# Generate standardized summary header
# Usage: summary_header "Title" "success|failure"
summary_header() {
  local title="$1"
  local status="$2"

  cat >> "$GITHUB_STEP_SUMMARY" << EOF
## $title

EOF

  if [ "$status" == "success" ]; then
    echo "✅ **Status:** PASSED" >> "$GITHUB_STEP_SUMMARY"
  else
    echo "❌ **Status:** FAILED" >> "$GITHUB_STEP_SUMMARY"
  fi

  echo "" >> "$GITHUB_STEP_SUMMARY"
}

# Add configuration section to summary
# Usage: summary_config "Key: Value" "Key2: Value2" ...
summary_config() {
  echo "### Configuration" >> "$GITHUB_STEP_SUMMARY"
  for config in "$@"; do
    echo "- **${config%%:*}:** ${config#*: }" >> "$GITHUB_STEP_SUMMARY"
  done
  echo "" >> "$GITHUB_STEP_SUMMARY"
}

# Add collapsible details section
# Usage: summary_details "Summary Title" "content" [language]
summary_details() {
  local title="$1"
  local content="$2"
  local language="${3:-}"

  cat >> "$GITHUB_STEP_SUMMARY" << EOF
<details>
<summary>$title</summary>

\`\`\`${language}
$content
\`\`\`
</details>

EOF
}

# Add a simple list section
# Usage: summary_list "Section Title" "item1" "item2" ...
summary_list() {
  local title="$1"
  shift

  echo "### $title" >> "$GITHUB_STEP_SUMMARY"
  for item in "$@"; do
    echo "- $item" >> "$GITHUB_STEP_SUMMARY"
  done
  echo "" >> "$GITHUB_STEP_SUMMARY"
}

# Add a table section
# Usage: summary_table "Header1|Header2|Header3" "Row1Col1|Row1Col2|Row1Col3" "Row2Col1|Row2Col2|Row2Col3"
summary_table() {
  if [ $# -lt 1 ]; then
    echo "Error: summary_table requires at least a header" >&2
    return 1
  fi

  local header="$1"
  shift

  # Print header
  echo "| ${header//|/ | } |" >> "$GITHUB_STEP_SUMMARY"

  # Print separator
  local separator=""
  local col_count
  col_count=$(echo "$header" | tr -cd '|' | wc -c)
  col_count=$((col_count + 1))
  for ((i=0; i<col_count; i++)); do
    separator="${separator}|---"
  done
  echo "${separator}|" >> "$GITHUB_STEP_SUMMARY"

  # Print rows
  for row in "$@"; do
    echo "| ${row//|/ | } |" >> "$GITHUB_STEP_SUMMARY"
  done

  echo "" >> "$GITHUB_STEP_SUMMARY"
}

# Add a divider
summary_divider() {
  echo "---" >> "$GITHUB_STEP_SUMMARY"
  echo "" >> "$GITHUB_STEP_SUMMARY"
}

# Add workflow metadata footer
# Usage: summary_footer
summary_footer() {
  summary_divider
  echo "**Workflow URL:** ${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}" >> "$GITHUB_STEP_SUMMARY"
}

# Format test results in a standard way
# Usage: summary_test_results total passed failed
summary_test_results() {
  local total="$1"
  local passed="$2"
  local failed="$3"

  {
    echo "### Test Results"
    echo "- **Total Tests:** $total"
    echo "- **Passed:** ✅ $passed"
    echo "- **Failed:** ❌ $failed"
    echo ""
  } >> "$GITHUB_STEP_SUMMARY"
}
