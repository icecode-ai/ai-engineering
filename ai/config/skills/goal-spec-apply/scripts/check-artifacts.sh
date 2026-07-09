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
[ -d "$change_dir" ] || { echo "Change '$name' not found."; exit 1; }

echo "=== Change: $name ==="
all_done=true
for artifact in proposal.md design.md tasks.md; do
  if [ -f "$change_dir/$artifact" ]; then
    echo "✓ $artifact"
  else
    echo "✗ $artifact (missing)"
    all_done=false
  fi
done
specs_dir="$change_dir/specs"
if [ -d "$specs_dir" ] && [ "$(ls -A "$specs_dir" 2>/dev/null)" ]; then
  echo "✓ specs/"
else
  echo "○ specs/ (empty — may need creation)"
fi
if [ "$all_done" = false ]; then
  echo "Some artifacts are missing. Suggest running /ai-spec-propose $name first."
fi
