#!/bin/bash
# Setup script for Go Security Hardening test project

cat > go.mod <<'EOF'
module example.com/secure-app
go 1.21
require (
  golang.org/x/crypto v0.17.0
)
EOF

mkdir -p cmd internal

cat > cmd/main.go <<'EOF'
package main
import "crypto/rand"
// Security-sensitive application
func main() {
  // TODO: Implement secure token generation
}
EOF
