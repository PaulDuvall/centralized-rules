#!/bin/bash
# Setup script for Python + Django + PostgreSQL test project

cat > pyproject.toml <<'EOF'
[project]
name = "app"
dependencies = ["django", "psycopg2-binary", "pytest"]
EOF

cat > requirements.txt <<'EOF'
Django>=4.2
psycopg2-binary>=2.9
EOF
