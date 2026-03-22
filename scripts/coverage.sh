#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

if [ ! -f "$ROOT_DIR/dist/openapi.json" ]; then
  echo "dist/openapi.json not found. Run ./scripts/bundle.sh first."
  exit 1
fi

echo "=== Routes in spec ==="
node -e "
const spec = require('$ROOT_DIR/dist/openapi.json');
const paths = Object.keys(spec.paths).sort();
let total = 0;
for (const path of paths) {
  const methods = Object.keys(spec.paths[path]).filter(m => ['get','post','put','patch','delete'].includes(m));
  for (const method of methods) {
    const op = spec.paths[path][method];
    console.log(method.toUpperCase().padEnd(8) + path.padEnd(55) + (op.operationId || 'NO-ID'));
    total++;
  }
}
console.log('');
console.log('Total operations: ' + total);
console.log('Total paths: ' + paths.length);
"
