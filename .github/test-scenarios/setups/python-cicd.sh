#!/bin/bash
# Setup script for Python + CI/CD Pipeline test project

cat > pyproject.toml <<'EOF'
[project]
name = "api"
dependencies = ["fastapi", "pytest", "pytest-cov"]
EOF

mkdir -p .github/workflows src tests

cat > .github/workflows/ci.yml <<'EOF'
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pytest
EOF

echo 'from fastapi import FastAPI' > src/main.py
echo 'import pytest' > tests/test_main.py
