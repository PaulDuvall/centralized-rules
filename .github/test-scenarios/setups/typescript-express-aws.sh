#!/bin/bash
# Description: Setup script for TypeScript + Express + AWS test project
# Usage: ./typescript-express-aws.sh
set -euo pipefail

cat > package.json <<'EOF'
{
  "name": "api",
  "dependencies": {
    "express": "^4.18.0",
    "typescript": "^5.0.0",
    "aws-sdk": "^2.0.0"
  }
}
EOF

mkdir -p src
echo 'import express from "express";' > src/server.ts
echo 'import AWS from "aws-sdk";' > src/aws.ts
