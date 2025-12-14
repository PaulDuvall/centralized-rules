#!/bin/bash
# Setup script for Go + Microservices + Docker + K8s test project

cat > go.mod <<'EOF'
module example.com/microservices
go 1.21
require (
  github.com/gin-gonic/gin v1.9.0
  github.com/prometheus/client_golang v1.17.0
)
EOF

cat > Dockerfile <<'EOF'
FROM golang:1.21-alpine
WORKDIR /app
COPY . .
RUN go build -o service
CMD ["./service"]
EOF

mkdir -p k8s services/api

cat > k8s/deployment.yml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-service
EOF

echo 'package main' > services/api/main.go
