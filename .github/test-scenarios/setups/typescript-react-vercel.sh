#!/bin/bash
# Description: Setup script for TypeScript + React + Vercel test project
# Usage: ./typescript-react-vercel.sh
set -euo pipefail

cat > package.json <<'EOF'
{
  "name": "frontend",
  "dependencies": {
    "react": "^18.0.0",
    "typescript": "^5.0.0"
  }
}
EOF

cat > vercel.json <<'EOF'
{
  "version": 2,
  "builds": [{"src": "src/**", "use": "@vercel/static"}]
}
EOF

mkdir -p src
echo 'import React from "react";' > src/App.tsx
