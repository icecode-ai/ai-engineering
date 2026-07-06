#!/usr/bin/env bash
# Check/show artifact status for a spec change.
# Usage: check-artifacts.sh <change-name>
set -euo pipefail
name="${1:-}"
[ -z "$name" ] && { echo "Usage: check-artifacts.sh <change-name>"; exit 1; }

PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."

change_dir="${PROJECT_ROOT}/ai/output/changes/$name"
[ -d "$change_dir" ] || { echo "Change '$name' not found at $change_dir"; exit 1; }

echo "=== Change: $name ==="
for artifact in proposal.md design.md tasks.md; do
  if [ -f "$change_dir/$artifact" ]; then
    echo "✓ $artifact"
  else
    echo "✗ $artifact (missing)"
  fi
done
specs_dir="$change_dir/specs"
if [ -d "$specs_dir" ] && [ "$(ls -A "$specs_dir" 2>/dev/null)" ]; then
  echo "✓ specs/"
else
  echo "○ specs/ (pending)"
fi
