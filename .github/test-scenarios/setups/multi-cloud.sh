#!/bin/bash
# Setup script for Multi-Cloud (AWS + GCP) test project

cat > pyproject.toml <<'EOF'
[project]
name = "multi-cloud-app"
dependencies = ["boto3", "google-cloud-storage", "pytest"]
EOF

mkdir -p src/aws src/gcp
echo 'import boto3' > src/aws/s3_client.py
echo 'from google.cloud import storage' > src/gcp/gcs_client.py

cat > cloud-config.yml <<'EOF'
providers:
  - aws
  - gcp
EOF
