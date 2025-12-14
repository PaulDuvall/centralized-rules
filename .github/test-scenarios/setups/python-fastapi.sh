#!/bin/bash
# Setup script for Python + FastAPI test project

cat > pyproject.toml <<'EOF'
[project]
name = "test-project"
version = "0.1.0"
dependencies = ["fastapi", "pytest"]
EOF

mkdir -p src
echo 'from fastapi import FastAPI' > src/main.py
