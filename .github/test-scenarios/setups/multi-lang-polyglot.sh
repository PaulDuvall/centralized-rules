#!/bin/bash
# Setup script for Multi-language (Python + TypeScript + Rust) test project

cat > pyproject.toml <<'EOF'
[project]
name = "backend"
dependencies = ["fastapi"]
EOF

cat > package.json <<'EOF'
{
  "name": "frontend",
  "dependencies": {"react": "18.0.0", "typescript": "5.0.0"}
}
EOF

cat > Cargo.toml <<'EOF'
[package]
name = "compute-engine"
version = "0.1.0"
edition = "2021"
EOF

mkdir -p backend frontend compute/src
echo 'from fastapi import FastAPI' > backend/main.py
echo 'import React from "react";' > frontend/App.tsx
echo 'fn main() {}' > compute/src/main.rs
