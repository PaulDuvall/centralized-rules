#!/bin/bash
# Description: Setup script for Rust + High Performance Computing test project
# Usage: ./rust-hpc.sh
set -euo pipefail

cat > Cargo.toml <<'EOF'
[package]
name = "hpc-app"
version = "0.1.0"
edition = "2021"

[dependencies]
rayon = "1.8"

[dev-dependencies]
criterion = "0.5"
EOF

mkdir -p src benches
echo 'fn main() {}' > src/main.rs
echo 'use criterion::Criterion;' > benches/benchmark.rs
