#!/bin/bash
# Description: Setup script for TypeScript + React test project
# Usage: ./typescript-react.sh
set -euo pipefail

cat > package.json <<'EOF'
{
  "name": "test-project",
  "version": "1.0.0",
  "dependencies": {
    "react": "^18.0.0",
    "typescript": "^5.0.0"
  }
}
EOF

mkdir -p src
echo 'import React from "react";' > src/App.tsx
