#!/usr/bin/env bash
# Sync one memory file to a module's ai/output/memories/.
# Usage: sync-memory.sh <memory_name> <module>
set -euo pipefail
memory_name="${1:-}"
module="${2:-}"
[ -z "$memory_name" ] || [ -z "$module" ] && { echo "Usage: sync-memory.sh <memory_name> <module>"; exit 1; }

PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."

target="${PROJECT_ROOT}/modules/$module/ai/output/memories"
mkdir -p "$target"
cp "${PROJECT_ROOT}/ai/output/memories/$memory_name" "$target/" 2>/dev/null || true
echo "Synced memory '$memory_name' to module '$module'"
