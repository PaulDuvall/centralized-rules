#!/bin/bash
# Description: Setup script for Python + FastAPI + AWS test project
# Usage: ./python-fastapi-aws.sh
set -euo pipefail

cat > pyproject.toml <<'EOF'
[project]
name = "api"
dependencies = ["fastapi", "boto3", "pytest"]
EOF

mkdir -p src
echo 'from fastapi import FastAPI' > src/main.py
echo 'import boto3' > src/aws_client.py

cat > aws-config.yml <<'EOF'
region: us-east-1
services: [s3, dynamodb]
EOF
