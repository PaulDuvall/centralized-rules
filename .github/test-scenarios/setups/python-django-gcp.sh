#!/bin/bash
# Setup script for Python + Django + GCP test project

cat > pyproject.toml <<'EOF'
[project]
name = "app"
dependencies = ["django", "google-cloud-storage", "pytest"]
EOF

cat > app.yaml <<'EOF'
runtime: python39
env: standard
EOF

mkdir -p src
echo 'from django.conf import settings' > src/settings.py
