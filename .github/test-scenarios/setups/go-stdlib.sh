#!/bin/bash
# Description: Setup script for Go + Standard Library test project
# Usage: ./go-stdlib.sh
set -euo pipefail

cat > go.mod <<'EOF'
module example.com/test
go 1.21
EOF

mkdir -p cmd
echo 'package main' > cmd/main.go
