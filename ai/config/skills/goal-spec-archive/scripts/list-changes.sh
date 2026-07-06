#!/usr/bin/env bash
# List active (non-archived) spec changes.
set -euo pipefail
PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."

echo "Active changes:"
ls -1 "${PROJECT_ROOT}/ai/output/changes/" 2>/dev/null | grep -v '^archive$' || echo "  (no active changes)"
