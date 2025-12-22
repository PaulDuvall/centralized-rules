#!/bin/bash
# Description: Setup script for TypeScript Performance Optimization test project
# Usage: ./typescript-performance.sh
set -euo pipefail

cat > package.json <<'EOF'
{
  "name": "app",
  "dependencies": {
    "typescript": "^5.0.0"
  },
  "devDependencies": {
    "benchmark": "^2.1.4"
  }
}
EOF

mkdir -p src benchmarks

cat > src/slow-algorithm.ts <<'EOF'
// Performance optimization needed
export function slowSort(arr: number[]): number[] {
  // Bubble sort - needs optimization
  return arr.sort((a, b) => a - b);
}
EOF

echo 'import Benchmark from "benchmark";' > benchmarks/perf.ts
