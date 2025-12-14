#!/bin/bash
# Setup script for TypeScript + Next.js + Vercel (Full Stack) test project

cat > package.json <<'EOF'
{
  "name": "fullstack-app",
  "dependencies": {
    "next": "14.0.0",
    "react": "18.0.0",
    "typescript": "5.0.0"
  }
}
EOF

cat > vercel.json <<'EOF'
{
  "version": 2,
  "framework": "nextjs"
}
EOF

mkdir -p pages api
echo 'import React from "react";' > pages/index.tsx
echo 'export default function handler(req, res) {}' > api/hello.ts
