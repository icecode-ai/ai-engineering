#!/usr/bin/env bash
# Sync one spec capability to a module's ai/output/specs/.
# Usage: sync-spec.sh <capability> <module>
set -euo pipefail
capability="${1:-}"
module="${2:-}"
[ -z "$capability" ] || [ -z "$module" ] && { echo "Usage: sync-spec.sh <capability> <module>"; exit 1; }

PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."

target="${PROJECT_ROOT}/modules/$module/ai/output/specs/$capability"
mkdir -p "$target"
cp -r "${PROJECT_ROOT}/ai/output/specs/$capability/." "$target/" 2>/dev/null || true
echo "Synced spec '$capability' to module '$module'"
