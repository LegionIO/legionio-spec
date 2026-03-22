#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

mkdir -p "$ROOT_DIR/dist"
npx @redocly/cli bundle "$ROOT_DIR/api/openapi.yaml" -o "$ROOT_DIR/dist/openapi.json"
echo "Bundled to dist/openapi.json ($(wc -c < "$ROOT_DIR/dist/openapi.json") bytes)"
