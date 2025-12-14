#!/bin/bash
# Setup script for Go + Standard Library test project

cat > go.mod <<'EOF'
module example.com/test
go 1.21
EOF

mkdir -p cmd
echo 'package main' > cmd/main.go
