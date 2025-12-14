#!/bin/bash
# Setup script for Python Debugging & Testing test project

cat > pyproject.toml <<'EOF'
[project]
name = "buggy-app"
dependencies = ["pytest", "pytest-cov", "pdb"]
EOF

mkdir -p src tests

cat > src/calculator.py <<'EOF'
# Buggy calculator needing debugging
def divide(a, b):
    return a / b  # Bug: No zero division check
EOF

cat > tests/test_calculator.py <<'EOF'
import pytest
from src.calculator import divide

def test_divide_by_zero():
    # This test should help identify the bug
    with pytest.raises(ZeroDivisionError):
        divide(10, 0)
EOF
