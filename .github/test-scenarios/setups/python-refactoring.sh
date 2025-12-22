#!/bin/bash
# Description: Setup script for Python Refactoring Scenario test project
# Usage: ./python-refactoring.sh
set -euo pipefail

cat > pyproject.toml <<'EOF'
[project]
name = "legacy-app"
dependencies = ["pytest", "pylint", "black"]
EOF

mkdir -p src tests

cat > src/legacy_code.py <<'EOF'
# Legacy code needing refactoring
def process_data(data):
    # TODO: Refactor this complex function
    result = []
    for item in data:
        if item > 0:
            result.append(item * 2)
    return result
EOF

echo '# Tests for refactored code' > tests/test_legacy.py
